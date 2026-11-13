import {chromium} from 'playwright';
import fs from 'node:fs';
const browser=await chromium.launch({headless:true,args:['--no-sandbox','--disable-dev-shm-usage']});
const report={app:'Paper Trading (Flutter Web build of Android codebase)',screens:[],issues:[]};
fs.mkdirSync('flutter-qa/screenshots',{recursive:true});
for(const screen of [{tag:'mobile',width:390,height:844},{tag:'desktop',width:1280,height:800}]){
 const context=await browser.newContext({viewport:{width:screen.width,height:screen.height},deviceScaleFactor:1,recordVideo:{dir:'flutter-qa/videos',size:{width:screen.width,height:screen.height}}});
 const page=await context.newPage();
 const errors=[];let quoteCalls=0,lessonsCalls=0;
 page.on('pageerror',err=>errors.push(err.message));
 page.on('response',r=>{const url=r.url();if(url.includes('verge-market-api/v1/quotes'))quoteCalls++;if(url.includes('verge-api/v1/lessons'))lessonsCalls++});
 try{
  await page.goto('http://127.0.0.1:8765/',{waitUntil:'domcontentloaded',timeout:30000});
  await page.waitForFunction(()=>!!document.querySelector('flutter-view'),{timeout:30000});
  await page.waitForTimeout(9500);
  await page.screenshot({path:'flutter-qa/screenshots/'+screen.tag+'-home.png',fullPage:true});
  const booted=await page.evaluate(()=>document.querySelector('flutter-view')?.getBoundingClientRect()?.height>200);
  report.screens.push({tag:screen.tag,booted,marketRequests:quoteCalls,lessonRequests:lessonsCalls,browserErrors:errors});
  if(!booted||errors.length)report.issues.push(screen.tag+' UI startup: '+errors.join('; '));
  // Flutter renders onto CanvasKit. Capture real clicks without claiming semantic test success.
  if(screen.tag==='mobile'){
    const taps=[['trade',.26],['portfolio',.43],['learn',.61],['leaderboard',.78],['account',.94]];
    for(const [label,x] of taps){
      await page.mouse.click(Math.round(screen.width*x),screen.height-37);
      await page.waitForTimeout(1000);
      await page.screenshot({path:'flutter-qa/screenshots/mobile-'+label+'.png',fullPage:true});
    }
  }
 }catch(e){report.issues.push(screen.tag+' failed: '+String(e).slice(0,300));}
 await page.close();await context.close();
}
await browser.close();
fs.writeFileSync('flutter-qa/report.json',JSON.stringify(report,null,2));
console.log(JSON.stringify(report,null,2));
if(report.issues.length)process.exitCode=1;
