// Fast, network-only production verification. No browser, no simulated market data.
// Each check calls the real Render/Supabase deployment (Deno API + Auth).
import { mkdirSync, writeFileSync } from 'node:fs';
const web='https://quizlab-responsive-web.onrender.com/paper-trading/';
const db='https://fcypamejorxoxvtcqubs.supabase.co';
const checks=[],startedAt=new Date().toISOString();
const add=(name,pass,details='')=>{checks.push({name,pass:!!pass,details:String(details).slice(0,150)});console.log((pass?'PASS':'FAIL')+' '+name+(details?' — '+String(details).slice(0,110):''));};
async function get(url){
  const response=await fetch(url,{headers:{'cache-control':'no-cache'},signal:AbortSignal.timeout(15000)});
  const body=await response.text();
  let json=null;try{json=JSON.parse(body)}catch{}
  return {status:response.status,headers:response.headers,body,json,finalUrl:response.url};
}
async function main(){
  const [site,js,styles,icon,config,quotes,lessons,chart1d,chart1m,guest]=await Promise.all([
    get(web),get(web+'student-features.js'),get(web+'student-features.css'),get(web+'paper-trading-icon.svg'),
    get(db+'/functions/v1/verge-api/v1/config'),
    get(db+'/functions/v1/verge-market-api/v1/quotes'),
    get(db+'/functions/v1/verge-api/v1/lessons'),
    get(db+'/functions/v1/verge-market-api/v1/candles/AAPL?interval=1min'),
    get(db+'/functions/v1/verge-market-api/v1/candles/AAPL?interval=1day'),
    get(db+'/functions/v1/verge-api/v1/portfolio')
  ]);
  add('Render page HTTP 200',site.status===200,site.status);
  add('Correct canonical page title',site.body.includes('<title>Paper Trading'),site.finalUrl);
  add('Page loads student-features module',site.body.includes('/paper-trading/student-features.js'));
  add('Student JavaScript and CSS deployed',js.status===200&&styles.status===200);
  add('White-and-blue icon deployed',icon.status===200&&icon.body.includes('#2962FF')&&icon.body.includes('#fff'));
  add('No sample traders or synthetic market generator',!site.body.includes('syntheticCandles')&&!site.body.includes('Olivia K.')&&!site.body.includes('James R.'));
  add('No TradingView vendor label',!site.body.includes('TradingView')&&!js.body.includes('TradingView'));
  add('ECharts engine linked',site.body.includes('echarts@5.6.0'));
  add('Active UI render invokes student hooks',site.body.includes('window.paperTradingAfterRender?.()'));
  add('Active auth submits through real student login',site.body.includes('window.paperTradingLogin(event,signup)')&&js.body.includes('window.paperTradingLogin=async'));
  add('Active logout invokes authenticated module',site.body.includes('window.paperTradingLogout()')&&js.body.includes('window.paperTradingLogout=async'));
  add('Classroom screen calls real module',site.body.includes('window.paperTradingLeaderPage?.()')&&js.body.includes('window.paperTradingLeaderPage='));
  add('Real account updates fetch extra Supabase data',site.body.includes('await window.paperTradingLoadExtras?.()')&&js.body.includes('window.paperTradingLoadExtras='));
  add('Password recovery attached to login modal',site.body.includes('window.paperTradingAfterLoginModal?.()')&&js.body.includes('window.paperTradingAfterLoginModal='));
  add('Expired sessions refresh through Supabase',site.body.includes('window.paperTradingRestoreSession?.()')&&js.body.includes('window.paperTradingRestoreSession=async'));
  add('No legacy localhost signup URL',!site.body.includes('localhost:3000'));
  add('Signup email redirect to canonical route',js.body.includes("encodeURIComponent(LANDING)")&&js.body.includes('/signup?redirect_to='));
  add('Watchlist writes authenticated owner user_id',js.body.includes('JSON.stringify({symbol,user_id:state.studentId})'));
  add('Classroom CRUD code available', ['pt_classroom_create','pt_classroom_join','pt_classroom_rename','pt_classroom_delete','pt_classroom_leave'].every(x=>js.body.includes(x)));
  add('Student profile and password update available',js.body.includes('pt_student_profiles')&&js.body.includes("authBase()+'/user'"));
  add('1D/1W/1M correctly labeled',site.body.includes("'1min':'1D'")&&site.body.includes("'1h':'1W'")&&site.body.includes("'1day':'1M'"));
  add('Supabase Auth config live',config.status===200&&config.json?.database==='configured'&&config.json?.supabaseUrl===db);
  add('All six real market quotes',quotes.status===200&&quotes.json?.quotes?.length===6&&quotes.json.quotes.every(x=>x.source==='TWELVE_DATA'&&Number(x.price)>0),quotes.json?.quotes?.map(x=>x.symbol).join(','));
  add('Six real lessons',lessons.status===200&&lessons.json?.lessons?.length===6);
  const candles1d=chart1d.json?.candles??[],candles1m=chart1m.json?.candles??[];
  const valid=arr=>arr.length>0&&arr.every(c=>c.time>1500000000&&c.low>0&&c.high>=Math.max(c.open,c.close)&&c.low<=Math.min(c.open,c.close));
  add('Real Twelve Data intraday OHLC',chart1d.status===200&&chart1d.json?.source==='TWELVE_DATA'&&valid(candles1d),candles1d.length+' bars');
  add('Real Twelve Data daily OHLC',chart1m.status===200&&chart1m.json?.source==='TWELVE_DATA'&&valid(candles1m),candles1m.length+' bars');
  add('Anonymous cannot read private portfolio',guest.status===401,guest.status);
  add('Supabase CORS allows Render site',config.headers.get('access-control-allow-origin')==='*'&&quotes.headers.get('access-control-allow-origin')==='*');
  const negative=await fetch(db+'/auth/v1/token?grant_type=password',{method:'POST',headers:{'content-type':'application/json','apikey':config.json?.supabasePublishableKey??''},body:JSON.stringify({email:'nonexistent-web-qa@example.invalid',password:'wrong-password'}),signal:AbortSignal.timeout(12000)});
  add('Authentication rejects wrong credentials',negative.status>=400&&negative.status<500,negative.status);
}
try{await main()}catch(e){add('Test runner completed',false,e.message)}
const failed=checks.filter(x=>!x.pass),report={startedAt,finishedAt:new Date().toISOString(),kind:'live_http_no_browser',total:checks.length,passed:checks.length-failed.length,failed:failed.length,checks};
mkdirSync('paper-trading-http-qa',{recursive:true});
writeFileSync('paper-trading-http-qa/report.json',JSON.stringify(report,null,2));
console.log('RESULT '+report.passed+'/'+report.total+' passed');
if(failed.length)process.exitCode=1;
