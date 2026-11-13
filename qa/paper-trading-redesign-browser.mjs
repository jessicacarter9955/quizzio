import { chromium } from 'playwright-core';
import { mkdirSync, writeFileSync } from 'node:fs';
const URL='https://quizlab-responsive-web.onrender.com/paper-trading/';
const browser=await chromium.launch({executablePath:process.env.CHROME_PATH||'/usr/bin/google-chrome',headless:true,args:['--no-sandbox','--disable-dev-shm-usage']});
mkdirSync('paper-trading-qa/screenshots',{recursive:true});
const checks=[],errors=[];
function mark(title,pass,detail=''){checks.push({title,pass:!!pass,detail:String(detail).slice(0,230)});if(!pass)errors.push(title+': '+detail)}
async function attempt(viewport,tag){
 const ctx=await browser.newContext({viewport,locale:'en-US',recordVideo:{dir:'paper-trading-qa/videos',size:viewport}});
 const page=await ctx.newPage();
 page.on('pageerror',e=>errors.push(tag+' browser JS: '+e.message));
 try{
  await page.goto(URL,{waitUntil:'domcontentloaded',timeout:45000});
  await page.locator('#pt-auth-gate #email').waitFor({timeout:30000});
  mark(tag+' full-screen sign-in on entry',await page.locator('#pt-auth-gate').isVisible());
  mark(tag+' Demo 1 prefilled',await page.locator('#email').inputValue()==='demo1@example.com'&&await page.locator('#pw').inputValue()==='demo1234');
  mark(tag+' Sign up and reset links',await page.getByRole('button',{name:'New student? Sign up'}).count()===1&&await page.getByRole('button',{name:'Forgot password?'}).count()===1);
  await page.getByRole('button',{name:'Student 2'}).click();
  mark(tag+' second demo prefill',await page.locator('#email').inputValue()==='demo2@example.com'&&await page.locator('#pw').inputValue()==='demo1234');
  await page.getByRole('button',{name:'Student 1'}).click();
  await page.locator('#pt-auth-gate button[type=submit]').click();
  await page.waitForFunction(()=>!!state.token&&Number(state.portfolio.cash)>=0,{timeout:30000});
  await page.waitForFunction(()=>!document.querySelector('#pt-auth-gate'),{timeout:10000});
  mark(tag+' Supabase demo login',await page.evaluate(()=>state.account?.email==='demo1@example.com'&&!!state.token));
  mark(tag+' real starting balance',await page.evaluate(()=>Number(state.portfolio.cash)===100000));
  mark(tag+' Inter font',await page.evaluate(()=>getComputedStyle(document.body).fontFamily.includes('Inter')));
  const nav=page.locator(viewport.width<=720?'#nav-mobile .nav-item':'#nav-left .nav-item');
  const navLabels=await nav.allInnerTexts();
  mark(tag+' six tabs including Widgets, no Account',navLabels.length===6&&navLabels.join(' ').includes('Home')&&navLabels.join(' ').includes('Widgets')&&!navLabels.join(' ').includes('Account'),navLabels.join(','));
  mark(tag+' avatar top-right',await page.locator('#account-avatar').count()===1);
  mark(tag+' no old top header',await page.locator('#market-status').count()===0&&await page.locator('.breadcrumbs').count()===0);
  await page.waitForFunction(()=>Object.values(state.prices).filter(q=>q.source==='TWELVE_DATA').length===6&&state.lessonData.length===6,{timeout:30000});
  mark(tag+' six quotes and lessons',await page.evaluate(()=>state.lessonData.length===6&&Object.values(state.prices).filter(q=>q.source==='TWELVE_DATA').length===6));
  await page.screenshot({path:'paper-trading-qa/screenshots/'+tag+'-home.png',fullPage:true});
  await nav.filter({hasText:'Learn'}).click();
  await page.locator('.pt-course-tile').first().waitFor({timeout:10000});
  mark(tag+' six lesson cards',await page.locator('.pt-course-tile').count()===6);
  await page.locator('.pt-course-tile').first().click();
  await page.locator('#pt-learning-shell').waitFor({timeout:10000});
  mark(tag+' first lesson screen',await page.locator('#pt-learning-shell h2').first().innerText()==='What you own');
  for(let i=0;i<6;i++){
    await page.locator('#pt-learning-shell .primary-button').last().click();
    await page.waitForFunction(next=>document.querySelector('.pt-learning-counter')?.textContent?.startsWith(String(next)),i+2,{timeout:12000});
  }
  mark(tag+' six lesson screens persisted',await page.evaluate(()=>Number(document.querySelector('#pt-learning-shell .pt-learning-counter')?.textContent?.split('/')[0].trim())===7));
  const answers=[1,0,1];
  for(let i=0;i<3;i++){
    await page.locator('#pt-learning-shell .pt-answer').nth(answers[i]).click();
    await page.locator('#pt-learning-shell .primary-button').last().click();
    if(i<2)await page.waitForFunction(n=>document.querySelector('.pt-learning-counter')?.textContent?.startsWith(String(n)),i+8,{timeout:15000});
  }
  await page.locator('#pt-learning-shell .pt-quiz-results').waitFor({timeout:20000});
  mark(tag+' server graded quiz',await page.locator('.pt-quiz-results strong').innerText()==='100%');
  mark(tag+' lesson progress persisted',await page.evaluate(()=>state.portfolio.done.includes(1)));
  await page.screenshot({path:'paper-trading-qa/screenshots/'+tag+'-quiz.png',fullPage:true});
  await page.getByRole('button',{name:'Finish',exact:true}).click();
  await nav.filter({hasText:'Ranks'}).click();
  await page.locator('#pt-classrooms').waitFor({timeout:10000});
  mark(tag+' actual classroom forms',await page.getByRole('button',{name:'Create classroom'}).count()===1&&await page.getByRole('button',{name:'Join classroom'}).count()===1);
  await page.screenshot({path:'paper-trading-qa/screenshots/'+tag+'-ranks.png',fullPage:true});
  await nav.filter({hasText:'Trade'}).click();
  await page.waitForSelector('#pt-trade-quantity',{timeout:10000});
  mark(tag+' buy and sell ticket',await page.locator('.pt-order-toggle button').count()===2);
  mark(tag+' single ticker search',await page.locator('#pt-market-search').count()===1);
  mark(tag+' selected AAPL shown in search',await page.locator('#pt-market-search').inputValue()==='AAPL');
  mark(tag+' protective orders present',await page.locator('#pt-stop-loss').count()===1&&await page.locator('#pt-take-profit').count()===1);
  await page.screenshot({path:'paper-trading-qa/screenshots/'+tag+'-trade.png',fullPage:true});
  await page.locator('.pt-advanced-expand').click();
  await page.locator('#pt-advanced-overlay').waitFor({timeout:10000});
  mark(tag+' advanced chart full screen',await page.locator('#pt-advanced-overlay').isVisible());
  mark(tag+' closing action visible',await page.locator('#pt-advanced-close').isVisible());
  await page.screenshot({path:'paper-trading-qa/screenshots/'+tag+'-advanced-chart.png',fullPage:true});
  await page.locator('#pt-advanced-close').click();
  mark(tag+' advanced chart closes',await page.locator('#pt-advanced-overlay').count()===0);
  await nav.filter({hasText:'Widgets'}).click();
  await page.locator('.pt-widget-tile').first().waitFor({timeout:10000});
  mark(tag+' widget showroom contains 28 choices',await page.locator('.pt-widget-tile').count()===28);
  await page.screenshot({path:'paper-trading-qa/screenshots/'+tag+'-widget-gallery.png',fullPage:true});
  await page.getByRole('button',{name:/Preview Ticker Tape/}).click();
  mark(tag+' widget preview selected',await page.locator('.pt-gallery-preview-head h2').innerText()==='Ticker Tape');
  await page.screenshot({path:'paper-trading-qa/screenshots/'+tag+'-ticker-preview.png',fullPage:true});
  await page.locator('#account-avatar').click();
  await page.getByText('Student profile',{exact:true}).waitFor({timeout:10000});
  mark(tag+' account from avatar',await page.getByText('Student profile',{exact:true}).count()===1);
  await page.screenshot({path:'paper-trading-qa/screenshots/'+tag+'-account.png',fullPage:true});
  mark(tag+' no horizontal overflow',await page.evaluate(()=>document.documentElement.scrollWidth<=innerWidth));
 }catch(e){errors.push(tag+' flow: '+String(e.message).slice(0,420));await page.screenshot({path:'paper-trading-qa/screenshots/'+tag+'-ERROR.png',fullPage:true}).catch(()=>{});}
 await ctx.close();
}
await attempt({width:390,height:844},'mobile');
await attempt({width:1365,height:768},'desktop');
await browser.close();
const report={passed:checks.filter(x=>x.pass).length,total:checks.length,checks,errors,ok:errors.length===0};
writeFileSync('paper-trading-qa/report.json',JSON.stringify(report,null,2));
console.log(JSON.stringify(report,null,2));
if(!report.ok)process.exitCode=1;