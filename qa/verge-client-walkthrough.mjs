import {chromium} from 'playwright';
import {mkdirSync,writeFileSync} from 'node:fs';

const url='https://quizlab-responsive-web.onrender.com/paper-trading/';
const out='verge-walkthrough';
mkdirSync(out+'/screenshots',{recursive:true});
mkdirSync(out+'/videos',{recursive:true});
const browser=await chromium.launch({
 executablePath:process.env.CHROME_PATH||'/usr/bin/google-chrome',
 headless:true,args:['--no-sandbox','--disable-dev-shm-usage']
});
const report={createdAt:new Date().toISOString(),shots:[],checks:[],issues:[]};
const check=(name,ok,note='')=>{report.checks.push({name,ok:!!ok,note});if(!ok)report.issues.push(name+': '+note)};
async function scene(page,name,hold=950){
 await page.waitForTimeout(hold);
 await page.screenshot({path:out+'/screenshots/'+name+'.png',fullPage:true});
 report.shots.push(name);
}
async function login(page,user){
 await page.locator('#pt-auth-gate #email').waitFor({timeout:35000});
 const email='demo'+user+'@example.com';
 await page.locator('#pt-auth-gate #email').fill(email);
 await page.locator('#pt-auth-gate #pw').fill('demo1234');
 await page.locator('#pt-auth-gate button[type=submit]').click();
 await page.waitForFunction(expected=>state.account?.email===expected&&!!state.token,email,{timeout:30000});
 await page.waitForFunction(()=>!document.querySelector('#pt-auth-gate'),{timeout:10000});
 check('Student '+user+' authenticated',true,email);
}
async function walkthrough(viewport,tag){
 const ctx=await browser.newContext({viewport,locale:'en-GB',deviceScaleFactor:1,
 recordVideo:{dir:out+'/videos',size:viewport}});
 const page=await ctx.newPage();
 page.on('pageerror',e=>report.issues.push(tag+' JS '+e.message));
 try{
  await page.goto(url,{waitUntil:'domcontentloaded',timeout:45000});
  await scene(page,tag+'-00-sign-in');
  await login(page,1);
  await scene(page,tag+'-01-home');
  await page.locator(tag==='mobile'?'#nav-mobile':'#nav-left').getByRole('button',{name:'Trade'}).click();
  await page.locator('#pt-trade-quantity').waitFor({timeout:12000});
  await scene(page,tag+'-02-trade-ticket');
  check(tag+' single app ticker search',await page.locator('#pt-market-search').count()===1);
  check(tag+' two protective fields',await page.locator('#pt-stop-loss').count()===1&&await page.locator('#pt-take-profit').count()===1);
  await page.locator('.pt-advanced-expand').click();
  await page.locator('#pt-advanced-overlay').waitFor({timeout:10000});
  await scene(page,tag+'-03-advanced-chart',2100);
  await page.locator('#pt-advanced-close').click();
  check(tag+' Advanced Chart closes',await page.locator('#pt-advanced-overlay').count()===0);
  await page.locator(tag==='mobile'?'#nav-mobile':'#nav-left').getByRole('button',{name:'Portfolio'}).click();
  await scene(page,tag+'-04-portfolio');
  await page.locator(tag==='mobile'?'#nav-mobile':'#nav-left').getByRole('button',{name:'Learn'}).click();
  await scene(page,tag+'-05-lessons');
  await page.locator('.pt-course-tile').first().click();
  await scene(page,tag+'-06-lesson');
  await page.locator('.pt-learning-close').click();
  await page.locator(tag==='mobile'?'#nav-mobile':'#nav-left').getByRole('button',{name:'Ranks'}).click();
  await scene(page,tag+'-07-classroom-teacher');
  check(tag+' classroom invite form',await page.getByRole('button',{name:'Join classroom'}).count()===1);
  check(tag+' seeded class visible',await page.getByText('VERGE Demo Classroom').count()>0);
  await page.locator(tag==='mobile'?'#nav-mobile':'#nav-left').getByRole('button',{name:'Widgets'}).click();
  await page.locator('.pt-widget-tile').first().waitFor({timeout:10000});
  await scene(page,tag+'-08-widget-gallery');
  await page.getByRole('button',{name:/Preview Ticker Tape/}).click();
  await scene(page,tag+'-09-ticker-widget',1800);
  check(tag+' 28 client widget choices',await page.locator('.pt-widget-tile').count()===28);
  await page.locator('#account-avatar').click();
  await scene(page,tag+'-10-account');
  // Log out through the public UI before switching student identity.
  const outBtn=page.getByRole('button',{name:/Log out|Sign out/i}).first();
  if(await outBtn.count()===0)throw Error('Account log out not visible');
  await outBtn.click();
  await page.locator('#pt-auth-gate').waitFor({timeout:10000});
  await scene(page,tag+'-11-switch-student');
  await login(page,2);
  await page.locator(tag==='mobile'?'#nav-mobile':'#nav-left').getByRole('button',{name:'Ranks'}).click();
  await scene(page,tag+'-12-classroom-student');
  check(tag+' joined student sees class',await page.getByText('VERGE Demo Classroom').count()>0);
 }catch(e){
  report.issues.push(tag+' flow '+String(e.message).slice(0,420));
  await page.screenshot({path:out+'/screenshots/'+tag+'-ERROR.png',fullPage:true}).catch(()=>{});
 }finally{
  await page.close();await ctx.close();
 }
}
await walkthrough({width:390,height:844},'mobile');
await walkthrough({width:1365,height:768},'desktop');
await browser.close();
writeFileSync(out+'/report.json',JSON.stringify(report,null,2));
console.log(JSON.stringify(report,null,2));
if(report.issues.length)process.exitCode=1;
