import {chromium} from 'playwright-core';
import fs from 'node:fs';
const url='https://quizlab-responsive-web.onrender.com/paper-trading/';
const chrome=process.env.CHROME_PATH||'/usr/bin/google-chrome';
const browser=await chromium.launch({executablePath:chrome,headless:true,args:['--no-sandbox','--disable-dev-shm-usage']});
const results={url,checks:[],errors:[],frames:[]};
fs.mkdirSync('paper-trading-qa/screenshots',{recursive:true});
function check(name,condition,details=''){results.checks.push({name,pass:!!condition,details});if(!condition)results.errors.push(name+': '+details);}
async function exercise(width,height,tag){
  const context=await browser.newContext({viewport:{width,height},deviceScaleFactor:1,recordVideo:{dir:'paper-trading-qa/videos',size:{width,height}}});
  const page=await context.newPage();
  page.on('pageerror',e=>results.errors.push('Browser '+tag+': '+e.message));
  try{
    await page.goto(url,{waitUntil:'domcontentloaded',timeout:65000});
    await page.waitForFunction(()=>document.querySelectorAll('.lesson-row').length>0,{timeout:40000});
    await page.waitForFunction(()=>[...document.querySelectorAll('.asset-price b')].some(x=>Number(x.textContent.replace(/[$,]/g,''))>100),{timeout:45000});
    check(tag+' correct title',(await page.title()).startsWith('Paper Trading'),await page.title());
    const pageText=await page.locator('body').innerText();
    check(tag+' no fictional traders',!pageText.includes('Olivia K.')&&!pageText.includes('James R.'));
    check(tag+' real market quote available',pageText.includes('Twelve Data'));
    check(tag+' period controls',await page.locator('.timeframes .pill').first().count()===1);
    const buttons=await page.locator('.timeframes .pill').first().allInnerTexts();
    check(tag+' 1D default',buttons.join('').includes('1D'));
    await page.screenshot({path:'paper-trading-qa/screenshots/'+tag+'-overview.png',fullPage:true});
    const nav=(label)=>page.locator(width<700?'#nav-mobile button':'#nav-left button').filter({hasText:label}).first();
    await nav('Learn').click();
    await page.waitForTimeout(900);
    const lessons=await page.locator('.lesson-card').count();
    check(tag+' six real lessons',lessons===6,'count='+lessons);
    const first=lessons?await page.locator('.lesson-card').first().innerText():'';
    check(tag+' course order first',first.includes('Welcome to the Markets'),first.slice(0,100));
    await page.screenshot({path:'paper-trading-qa/screenshots/'+tag+'-learn.png',fullPage:true});
    await nav('Community').click();
    await page.waitForTimeout(400);
    check(tag+' no invented leaderboard',(await page.locator('#content').innerText()).includes('No published rankings'));
    await nav('Trade').click();
    await page.waitForTimeout(1600);
    const b=page.locator('.timeframes .pill');
    check(tag+' chart interval buttons',await b.count()===3);
    for(const [i,name] of ['1D','1W','1M'].entries()){
       await b.nth(i).click();await page.waitForTimeout(2200);
       check(tag+' '+name+' interval activated',(await b.nth(i).getAttribute('class')||'').includes('active'));
    }
    await page.screenshot({path:'paper-trading-qa/screenshots/'+tag+'-trade.png',fullPage:true});
    await nav('Portfolio').click();await page.waitForTimeout(700);
    await page.screenshot({path:'paper-trading-qa/screenshots/'+tag+'-portfolio.png',fullPage:true});
    await nav('Account').click();await page.waitForTimeout(500);
    check(tag+' real auth entry',await page.getByText('Student sign in').count()>0);
    await page.screenshot({path:'paper-trading-qa/screenshots/'+tag+'-account.png',fullPage:true});
    const before=await page.locator('html').getAttribute('data-theme');
    await page.locator('#theme-toggle').click();await page.waitForTimeout(450);
    const after=await page.locator('html').getAttribute('data-theme');
    check(tag+' dark light changes',before!==after,before+' -> '+after);
    check(tag+' horizontal overflow absent',await page.evaluate(()=>document.documentElement.scrollWidth<=innerWidth));
  }catch(e){results.errors.push(tag+': '+String(e.message).slice(0,400));await page.screenshot({path:'paper-trading-qa/screenshots/'+tag+'-error.png',fullPage:true}).catch(()=>{});}
  finally{await page.close();await context.close();}
}
await exercise(390,844,'mobile-responsive');
await exercise(1365,768,'desktop');
await browser.close();
fs.writeFileSync('paper-trading-qa/report.json',JSON.stringify(results,null,2));
console.log(JSON.stringify(results,null,2));
if(results.errors.length)process.exitCode=1;
