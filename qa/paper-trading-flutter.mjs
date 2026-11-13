import {chromium} from 'playwright';
import fs from 'node:fs';
const browser=await chromium.launch({headless:true,args:['--no-sandbox','--disable-dev-shm-usage']});
const report={app:'Paper Trading (Flutter Web build of Android codebase)',screens:[],issues:[]};
fs.mkdirSync('flutter-qa/screenshots',{recursive:true});
for(const screen of [{tag:'mobile',width:390,height:844},{tag:'desktop',width:1280,height:800}]){
 const context=await browser.newContext({viewport:{width:screen.width,height:screen.height},deviceScaleFactor:1,locale:'en-US',extraHTTPHeaders:{'Accept-Language':'en-US,en;q=0.9'},recordVideo:{dir:'flutter-qa/videos',size:{width:screen.width,height:screen.height}}});
 const page=await context.newPage();
 const errors=[];let quoteCalls=0,lessonsCalls=0;
 page.on('pageerror',err=>errors.push(err.message));
 page.on('response',r=>{const url=r.url();if(url.includes('verge-market-api/v1/quotes'))quoteCalls++;if(url.includes('verge-api/v1/lessons'))lessonsCalls++});
 try{
  await page.goto('http://127.0.0.1:8765/',{waitUntil:'domcontentloaded',timeout:30000});
  await page.waitForFunction(()=>!!document.querySelector('flutter-view'),{timeout:30000});
  await page.waitForTimeout(9500);
  const chartResource=await page.request.get('http://127.0.0.1:8765/chart.html');
  const chartHtml=await chartResource.text();
  const chartCorrect=chartHtml.includes('echarts@5.6.0')&&!chartHtml.includes('TradingView')&&!chartHtml.includes('lightweight-charts');
  if(!chartCorrect)report.issues.push(screen.tag+' chart still contains old branded engine');

  await page.screenshot({path:'flutter-qa/screenshots/'+screen.tag+'-home.png',fullPage:true});
  const booted=await page.evaluate(()=>document.querySelector('flutter-view')?.getBoundingClientRect()?.height>200);
  report.screens.push({tag:screen.tag,booted,marketRequests:quoteCalls,lessonRequests:lessonsCalls,browserErrors:errors});
  if(!booted||errors.length)report.issues.push(screen.tag+' UI startup: '+errors.join('; '));
  // Exercise actual CanvasKit touch coordinates on the mobile auth-first screen.
  if(screen.tag==='mobile'){
    let loginStatus='unverified';
    try{
      const responsePromise=page.waitForResponse(r=>r.url().includes('/auth/v1/token?grant_type=password'),{timeout:20000});
      await page.mouse.click(195,490);
      const response=await responsePromise;
      loginStatus=response.ok()?'authenticated':'auth-http-'+response.status();
      await page.waitForTimeout(5000);
      await page.screenshot({path:'flutter-qa/screenshots/mobile-after-login.png',fullPage:true});
      if(!response.ok())report.issues.push('Actual mobile Flutter login returned '+response.status());
      else{
        const tabs=[['home',.1],['trade',.3],['portfolio',.5],['learn',.7],['ranks',.9]];
        for(const [label,x] of tabs){
          await page.mouse.click(Math.round(screen.width*x),screen.height-33);
          await page.waitForTimeout(1100);
          await page.screenshot({path:'flutter-qa/screenshots/mobile-'+label+'-authenticated.png',fullPage:true});
        }
        await page.mouse.click(screen.width-39,28);
        await page.waitForTimeout(900);
        await page.screenshot({path:'flutter-qa/screenshots/mobile-account-authenticated.png',fullPage:true});
      }
    }catch(e){report.issues.push('Flutter mobile sign-in UI: '+String(e).slice(0,250));}
    report.screens[report.screens.length-1].demoLogin=loginStatus;
  }
 }catch(e){report.issues.push(screen.tag+' failed: '+String(e).slice(0,300));}
 await page.close();await context.close();
}
await browser.close();
fs.writeFileSync('flutter-qa/report.json',JSON.stringify(report,null,2));
console.log(JSON.stringify(report,null,2));
if(report.issues.length)process.exitCode=1;
