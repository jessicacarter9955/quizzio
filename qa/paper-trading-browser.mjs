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
    await page.waitForFunction(()=>state.lessonData.length===6&&Object.values(state.prices).filter(x=>x.source==='TWELVE_DATA').length===6,{timeout:30000});
    check(tag+' six provider quotes from Supabase',await page.evaluate(()=>Object.values(state.prices).length===6&&Object.values(state.prices).every(q=>q.source==='TWELVE_DATA'&&Number(q.price)>0)));
    check(tag+' Supabase authentication config connected',await page.evaluate(()=>state.db===true&&state.supabaseUrl.includes('.supabase.co')&&state.supabaseKey.startsWith('sb_publishable_')));
    check(tag+' active student feature hooks',await page.evaluate(()=>['paperTradingAfterRender','paperTradingLeaderPage','paperTradingLoadExtras','paperTradingLogin','paperTradingLogout','paperTradingAfterLoginModal','paperTradingRestoreSession'].every(k=>typeof window[k]==='function')));
    await page.waitForFunction(()=>state.candles.length>0&&state.chart!==null,{timeout:40000});
    await page.waitForSelector('#trade-chart canvas',{timeout:20000});
    check(tag+' real OHLC chart rendered',await page.evaluate(()=>state.candles.length>0&&state.chart!==null&&document.querySelector('#trade-chart canvas')!==null));
    check(tag+' OHLC internally consistent',await page.evaluate(()=>state.candles.every(c=>c.high>=Math.max(c.open,c.close)&&c.low<=Math.min(c.open,c.close)&&c.time>1500000000)));
    check(tag+' correct title',(await page.title()).startsWith('Paper Trading'),await page.title());
    const pageText=await page.locator('body').innerText();
    check(tag+' no fictional traders',!pageText.includes('Olivia K.')&&!pageText.includes('James R.'));
    check(tag+' real market quote available',pageText.includes('Twelve Data'));
    check(tag+' period controls',await page.locator('.timeframes .pill').first().count()===1);
    const buttons=await page.locator('.timeframes .pill').first().allInnerTexts();
    check(tag+' 1D default',buttons.join('').includes('1D'));
    await page.screenshot({path:'paper-trading-qa/screenshots/'+tag+'-overview.png',fullPage:true});
    const nav=(label)=>page.locator(width<700?'#nav-mobile button':'#nav-left button').filter({hasText:label}).first();
    check(tag+' real personal watchlist controls',await page.locator('.pt-fav').count()===6);
    await page.locator('.pt-fav').first().click();
    check(tag+' guest watchlist requires login',await page.locator('#overlay input[type=email]').count()===1);
    await page.locator('#overlay button.close').click();
    const rows=await page.locator('.market-table tbody tr').count();
    check(tag+' six watchlist instruments',rows===6,'rows='+rows);
    await page.locator('.market-table tbody tr').filter({hasText:'MSFT'}).first().click();
    check(tag+' watchlist opens correct selected asset',await page.evaluate(()=>state.page==='trade'&&state.symbol==='MSFT'));
    await nav('Overview').click();
    await nav('Learn').click();
    await page.waitForTimeout(900);
    const lessons=await page.locator('.lesson-card').count();
    check(tag+' six real lessons',lessons===6,'count='+lessons);
    const first=lessons?await page.locator('.lesson-card').first().innerText():'';
    check(tag+' course order first',first.includes('Welcome to the Markets'),first.slice(0,100));
    const sequence=await page.locator('.lesson-card h3').allInnerTexts();
    check(tag+' all six lessons ordered',sequence.length===6&&sequence[0]==='Welcome to the Markets'&&sequence[1]==='Understanding Candlesticks'&&sequence[5]==='Reviewing Performance');
    await page.locator('.lesson-card').first().click();
    check(tag+' lesson details open from Supabase',await page.locator('#overlay').getByText('Welcome to the Markets').count()===1);
    const beforeDone=await page.evaluate(()=>state.portfolio.done.length);
    await page.locator('#overlay').getByText('Mark as complete').click();
    check(tag+' guest completion requires auth',await page.locator('#overlay input[type=email]').count()===1&&await page.evaluate(()=>state.portfolio.done.length)===beforeDone);
    await page.locator('#overlay button.close').click();
    await page.screenshot({path:'paper-trading-qa/screenshots/'+tag+'-learn.png',fullPage:true});
    await nav('Leaderboard').click();
    await page.waitForTimeout(400);
    check(tag+' classroom UI mounted',await page.locator('#pt-classrooms').count()===1);
    check(tag+' guest classroom explanation mounted',(await page.locator('#pt-classrooms').innerText()).includes('Your classroom rankings'));

    check(tag+' guest classroom requires login',(await page.locator('#pt-classrooms').innerText()).includes('Sign in'));
    check(tag+' no invented leaderboard',!(await page.locator('#pt-classrooms').innerText()).includes('Olivia K.'));

    await nav('Trade').click();
    await page.waitForTimeout(1600);
    const b=page.locator('.timeframes .pill');
    check(tag+' chart interval buttons',await b.count()===3);
    check(tag+' six selectable symbols',await page.locator('.symbol-selector').count()===6);
    await page.locator('.segmented').getByText('Sell').click();
    check(tag+' sell selection changes order side',await page.evaluate(()=>state.side==='sell'));
    await page.locator('.segmented').getByText('Buy').click();
    check(tag+' buy selection changes order side',await page.evaluate(()=>state.side==='buy'));
    await page.locator('#quantity').fill('3');
    const notional=await page.locator('#order-notional').innerText();
    check(tag+' quantity updates estimated notional',await page.evaluate(()=>state.qty===3),notional);
    await page.locator('.order-panel .primary-button').click();
    check(tag+' buying when logged out opens real auth',await page.locator('#overlay input[type=email]').count()===1);
    await page.locator('#overlay button.close').click();
    check(tag+' no fabricated cash for guest',(/Available cash\s+Sign in/).test(await page.locator('.order-panel').innerText()));
    
    for(const [i,name] of ['1D','1W','1M'].entries()){
       await b.nth(i).click();await page.waitForTimeout(2200);
       check(tag+' '+name+' interval activated',(await b.nth(i).getAttribute('class')||'').includes('active'));
       await page.waitForFunction(label=>state.chart&&state.candles.length>0&&(document.querySelector('.chart-legend span')?.textContent||'').includes(label),name,{timeout:30000});
       const chartDetails=await page.evaluate(()=>({n:state.candles.length,range:state.candles.length?state.candles.at(-1).time-state.candles[0].time:Infinity,chart:!!state.chart}));
       const maxSeconds=[86400,7*86400,30*86400][i];
       check(tag+' '+name+' real candles within actual period',chartDetails.n>0&&chartDetails.range<=maxSeconds,'count='+chartDetails.n+', spanSec='+chartDetails.range);
       check(tag+' '+name+' chart mounted',chartDetails.chart);
    }
    await page.screenshot({path:'paper-trading-qa/screenshots/'+tag+'-trade.png',fullPage:true});
    await nav('Portfolio').click();await page.waitForTimeout(700);
    await page.screenshot({path:'paper-trading-qa/screenshots/'+tag+'-portfolio.png',fullPage:true});
    await nav('Account').click();await page.waitForTimeout(500);
    await page.locator('#content button').filter({hasText:'Student sign in'}).first().click();
    const signinModal=page.locator('#overlay');
    check(tag+' login form opens',await signinModal.locator('input[type=email]').count()===1&&await signinModal.locator('input[type=password]').count()===1);
    check(tag+' signup form reachable',await signinModal.getByText('Create a student account').count()===1);
    check(tag+' password recovery available',await signinModal.getByText('Forgot password?').count()===1);
    await signinModal.locator('input[type=email]').fill('invalid-account-no-user@invalid.example');
    await signinModal.locator('input[type=password]').fill('WrongPass123');
    await signinModal.locator('button[type=submit]').click();
    await page.waitForTimeout(1700);
    const invalidMessage=await page.locator('#toast').innerText();
    check(tag+' invalid password rejected',invalidMessage.length>0&&!page.url().includes('localhost'),invalidMessage.slice(0,140));
    await page.locator('#overlay button.close').click();

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
