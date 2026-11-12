import http from 'node:http';
import {WebSocket,WebSocketServer} from 'ws';

const port=Number(process.env.PORT||8080);
const supabase=process.env.SUPABASE_URL||'';
const publicKey=process.env.SUPABASE_PUBLISHABLE_KEY||'';
const twelveKey=process.env.TWELVE_DATA_API_KEY||'';
const ingestUrl=process.env.MARKET_INGEST_URL||'';
const ingestSecret=process.env.MARKET_INGEST_SECRET||'';
const allSymbols=(process.env.MARKET_SYMBOLS||'AAPL,MSFT,NVDA,TSLA,BTC/USD,EUR/USD').split(',').map(s=>s.trim().toUpperCase());
const subscriptions=(process.env.MARKET_SUBSCRIPTIONS||'AAPL,BTC/USD,EUR/USD').split(',').map(s=>s.trim().toUpperCase()).filter(s=>allSymbols.includes(s));
const demoPrices={AAPL:263.52,MSFT:487.94,NVDA:196.2,TSLA:438.42,'BTC/USD':99720,'EUR/USD':1.1587};
const quoteMap=new Map(allSymbols.map(symbol=>[symbol,{symbol,price:demoPrices[symbol]??100,timestamp:Math.floor(Date.now()/1000),source:'DEMO'}]));
let state=twelveKey?'connecting':'no-key',upstream=null,lastPriceAt=null,lastPersistAt=null,lastStatus=null;
let active=[],failed=[],retries=0;
const lastWrite=new Map();
const cors={'access-control-allow-origin':'*','access-control-allow-methods':'GET,POST,OPTIONS','access-control-allow-headers':'authorization,apikey,content-type','cache-control':'no-store'};
const resJson=(res,data,status=200)=>{res.writeHead(status,{'content-type':'application/json; charset=utf-8',...cors});res.end(JSON.stringify(data));};
const routeInfo=()=>({ok:true,market:state,provider:'Twelve Data',websocketConfigured:!!twelveKey,subscribeRequested:subscriptions,subscribed:active,rejected:failed,lastUpstreamTick:lastPriceAt,lastPersistedTick:lastPersistAt,mode:[...quoteMap.values()].some(q=>q.source==='TWELVE_DATA')?'MIXED_LIVE':'DEMO',supabaseIngestConfigured:!!(ingestSecret&&ingestUrl)});
async function jsonBody(req){let s='';for await(const chunk of req){s+=String(chunk);if(s.length>16000)throw Error('Request too large');}return JSON.parse(s||'{}');}
function sendToClients(event,data){const msg=JSON.stringify({event,data});for(const ws of clients.clients)if(ws.readyState===WebSocket.OPEN)ws.send(msg);}
async function persist(q){
 if(!ingestUrl||!ingestSecret)return;
 if(Date.now()-(lastWrite.get(q.symbol)||0)<6000)return;
 lastWrite.set(q.symbol,Date.now());
 try{
  const r=await fetch(ingestUrl,{method:'POST',headers:{'content-type':'application/json','x-verge-ingest-secret':ingestSecret},body:JSON.stringify(q),signal:AbortSignal.timeout(7000)});
  if(r.ok)lastPersistAt=new Date().toISOString();else console.warn('Market ingest status',r.status);
 }catch(e){console.warn('Market ingest unavailable',e?.message??String(e));}
}
function consume(message){
 let v;try{v=JSON.parse(String(message));}catch{return;}
 if(v.event==='subscribe-status'||v.event==='status'){
  lastStatus={event:v.event,status:v.status,message:typeof v.message==='string'?v.message.slice(0,140):null};
  active=Array.isArray(v.success)?v.success.map(x=>x.symbol).filter(Boolean):active;
  failed=Array.isArray(v.fails)?v.fails.map(x=>({symbol:x.symbol??'',reason:String(x.message??x.error??'Not included in plan').slice(0,120)})):failed;
  if(v.status==='error'||v.status==='failed')state='subscription-rejected';else if(v.event==='subscribe-status')state='subscribed';
  return;
 }
 if(v.event!=='price')return;
 const symbol=String(v.symbol||'').toUpperCase(),price=Number(v.price),timestamp=Number(v.timestamp)||Math.floor(Date.now()/1000);
 if(!allSymbols.includes(symbol)||!Number.isFinite(price)||price<=0||!Number.isFinite(timestamp))return;
 if(Math.abs(Date.now()/1000-timestamp)>300)return;
 const q={symbol,price,timestamp,source:'TWELVE_DATA'};
 quoteMap.set(symbol,q);lastPriceAt=new Date(timestamp*1000).toISOString();
 state='receiving';sendToClients('tick',q);void persist(q);
}
let beat=null,reconnect=null;
function connect(){
 if(!twelveKey){state='no-key';return;}
 state='connecting';active=[];failed=[];
 // Header authentication prevents the key appearing in URL paths and access logs.
 const ws=new WebSocket('wss://ws.twelvedata.com/v1/quotes/price',{headers:{'X-TD-APIKEY':twelveKey}});
 upstream=ws;
 ws.on('open',()=>{
  state='connected';retries=0;
  ws.send(JSON.stringify({action:'subscribe',params:{symbols:subscriptions.join(',')}}));
  clearInterval(beat);beat=setInterval(()=>{if(ws.readyState===WebSocket.OPEN)ws.send(JSON.stringify({action:'heartbeat'}));},10000);
 });
 ws.on('message',consume);
 ws.on('error',e=>{state='connection-error';console.warn('Twelve Data websocket error',e?.message??'Unknown');});
 ws.on('close',()=>{clearInterval(beat);state='disconnected';clearTimeout(reconnect);reconnect=setTimeout(connect,Math.min(30000,1000*2**Math.min(5,++retries)));});
}
const clients=new WebSocketServer({noServer:true});
clients.on('connection',ws=>ws.send(JSON.stringify({event:'snapshot',data:[...quoteMap.values()]})));
async function supa(path,{jwt,method='GET',body}={}){
 const headers={apikey:publicKey,authorization:jwt?'Bearer '+jwt:'Bearer '+publicKey};
 if(body!==undefined)headers['content-type']='application/json';
 const response=await fetch(supabase+'/rest/v1/'+path,{method,headers,body:body===undefined?undefined:JSON.stringify(body),signal:AbortSignal.timeout(8000)});
 const text=await response.text();let data;try{data=text?JSON.parse(text):null;}catch{data={error:'Invalid response'};}
 return {status:response.status,ok:response.ok,data};
}
async function requireUser(req){
 const jwt=String(req.headers.authorization||'').replace(/^Bearer\s+/i,'');if(!jwt||!publicKey)return null;
 const res=await fetch(supabase+'/auth/v1/user',{headers:{apikey:publicKey,authorization:'Bearer '+jwt},signal:AbortSignal.timeout(8000)});
 if(!res.ok)return null;const user=await res.json();return user?.id?{id:user.id,jwt}:null;
}
function demoCandles(symbol,interval){
 const seconds=interval==='1day'?86400:interval==='1h'?3600:60;
 const now=Math.floor(Date.now()/1000/seconds)*seconds;
 const base=quoteMap.get(symbol)?.price??100;
 return Array.from({length:80},(_,i)=>{const time=now-(79-i)*seconds;const v=base*(1+Math.sin(i*.29+symbol.length)*.005);return {time,open:v,close:v+Math.sin(i*.7)*base*.001,high:v+base*.003,low:v-base*.003};});
}
const server=http.createServer(async(req,res)=>{
 if(req.method==='OPTIONS'){res.writeHead(204,cors);res.end();return;}
 const u=new URL(req.url,'http://localhost'),p=u.pathname;
 try{
  if(req.method==='GET'&&(p==='/'||p==='/health'))return resJson(res,routeInfo());
  if(req.method==='GET'&&p==='/v1/config')return resJson(res,{database:!!supabase,supabaseUrl:supabase,supabasePublishableKey:publicKey});
  if(req.method==='GET'&&p==='/v1/quotes')return resJson(res,{quotes:[...quoteMap.values()],mode:routeInfo().mode,rejected:failed});
  if(req.method==='GET'&&p.startsWith('/v1/candles/')){
   const symbol=decodeURIComponent(p.slice('/v1/candles/'.length)).toUpperCase(),interval=['1min','1h','1day'].includes(u.searchParams.get('interval'))?u.searchParams.get('interval'):'1min';
   if(!allSymbols.includes(symbol))return resJson(res,{error:'Unknown symbol'},404);
   if(twelveKey){
    try{
     const url=new URL('https://api.twelvedata.com/time_series');
     for(const [k,v] of Object.entries({symbol,interval,outputsize:'80',timezone:'UTC',apikey:twelveKey}))url.searchParams.set(k,v);
     const response=await fetch(url,{signal:AbortSignal.timeout(9000)});
     const data=await response.json();
     if(response.ok&&data.status!=='error'&&Array.isArray(data.values)){
      const candles=data.values.map(x=>({time:Math.floor(Date.parse(x.datetime.replace(' ','T')+'Z')/1000),open:+x.open,high:+x.high,low:+x.low,close:+x.close})).filter(x=>Number.isFinite(x.time)&&Number.isFinite(x.close)).sort((a,b)=>a.time-b.time);
      if(candles.length)return resJson(res,{symbol,interval,mode:'historical',source:'TWELVE_DATA',candles});
     }
    }catch(e){console.warn('History fetch unavailable',e?.message??'Unknown');}
   }
   return resJson(res,{symbol,interval,mode:'demo',source:'DEMO',candles:demoCandles(symbol,interval)});
  }
  if(req.method==='GET'&&p==='/v1/lessons'){
    const r=await supa('pt_lessons?select=id,title,category,description,content,duration_minutes,level&order=sort_order.asc');
    return resJson(res,r.ok?{lessons:r.data}:{error:r.data?.message??'Lessons unavailable'},r.ok?200:502);
  }
  if(p==='/v1/portfolio'&&req.method==='GET'){
   const a=await requireUser(req);if(!a)return resJson(res,{error:'Authentication required'},401);
   const [w,pos,o]=await Promise.all([supa('pt_wallets?select=*&user_id=eq.'+a.id,{jwt:a.jwt}),supa('pt_positions?select=*&user_id=eq.'+a.id,{jwt:a.jwt}),supa('pt_orders?select=*&user_id=eq.'+a.id+'&order=created_at.desc&limit=30',{jwt:a.jwt})]);
   if(!w.ok||!pos.ok||!o.ok)return resJson(res,{error:'Portfolio unavailable'},502);
   return resJson(res,{wallet:w.data?.[0]??null,positions:pos.data,orders:o.data});
  }
  if(p==='/v1/orders'&&req.method==='POST'){
   const a=await requireUser(req);if(!a)return resJson(res,{error:'Authentication required'},401);
   const b=await jsonBody(req),qty=Number(b.quantity);
   if(!allSymbols.includes(b.symbol)||!['buy','sell'].includes(b.side)||!Number.isFinite(qty)||qty<=0||qty>1e6||Math.round(qty*1e6)!==qty*1e6)return resJson(res,{error:'Invalid order'},400);
   const r=await supa('rpc/pt_place_order',{jwt:a.jwt,method:'POST',body:{p_symbol:b.symbol,p_side:b.side,p_quantity:qty,p_client_order_id:typeof b.client_order_id==='string'?b.client_order_id:null}});
   return resJson(res,r.ok?{order:r.data}:{error:r.data?.message??'Order rejected'},r.ok?200:400);
  }
  if(p==='/v1/progress'&&req.method==='POST'){
   const a=await requireUser(req);if(!a)return resJson(res,{error:'Authentication required'},401);
   const b=await jsonBody(req),lessonId=Number(b.lesson_id);if(!Number.isInteger(lessonId)||lessonId<1)return resJson(res,{error:'Invalid lesson'},400);
   const r=await supa('pt_lesson_progress?on_conflict=user_id,lesson_id',{jwt:a.jwt,method:'POST',body:{user_id:a.id,lesson_id:lessonId,completed_at:new Date().toISOString()}});
   return resJson(res,r.ok?{ok:true}:{error:r.data?.message??'Progress unavailable'},r.ok?200:502);
  }
  return resJson(res,{error:'Not found'},404);
 }catch(e){console.error('Request failed',e?.message??String(e));return resJson(res,{error:'Backend temporarily unavailable'},503);}
});
server.on('upgrade',(req,socket,head)=>{
 if(req.url?.split('?')[0]!=='/ws/quotes'){socket.destroy();return;}
 clients.handleUpgrade(req,socket,head,ws=>clients.emit('connection',ws,req));
});
server.listen(port,'0.0.0.0',()=>{console.log('VERGE live market gateway listening',port);connect();});
process.on('SIGTERM',()=>{clearInterval(beat);clearTimeout(reconnect);upstream?.removeAllListeners('close');upstream?.close();clients.close();server.close();});