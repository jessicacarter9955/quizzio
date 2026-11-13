import {createServer} from 'node:http';
import {createClient} from 'redis';
import {WebSocketServer, WebSocket} from 'ws';

const port=Number(process.env.PORT||8080);
const redisUrl=process.env.REDIS_URL||'';
const feedUrl=process.env.QUOTE_SOURCE_URL||
 'https://fcypamejorxoxvtcqubs.supabase.co/functions/v1/verge-market-api/v1/quotes';
const siteOrigin=process.env.ALLOWED_ORIGIN||'https://quizlab-responsive-web.onrender.com';
const channel='verge:market:quotes';
const heartbeatMs=30000;
const pollMs=Math.max(12000,Number(process.env.POLL_INTERVAL_MS)||15000);
let producer=null,subscriber=null,lastPublished='',lastFingerprint='',lastFetchAt=null,upstreamError=null;
const sockets=new Set();
let connected=false,subscribed=false;
const now=()=>new Date().toISOString();
function writeJson(res,code,body){
 res.writeHead(code,{'Content-Type':'application/json','Cache-Control':'no-store','Access-Control-Allow-Origin':siteOrigin,'X-Content-Type-Options':'nosniff'});
 res.end(JSON.stringify(body));
}
const server=createServer(async(req,res)=>{
 if(req.url==='/health'){
   return writeJson(res,connected&&subscribed?200:503,{
    ok:connected&&subscribed,transport:'redis-pubsub',
    configured:!!redisUrl,redis_connected:connected,redis_subscribed:subscribed,
    connected_clients:sockets.size,last_fetch_at:lastFetchAt,last_upstream_error:upstreamError
   });
 }
 if(req.url==='/'){return writeJson(res,200,{service:'VERGE market Redis pub/sub bridge',ws:'/ws/quotes'});}
 return writeJson(res,404,{error:'Route not found'});
});
const wss=new WebSocketServer({noServer:true,maxPayload:32*1024});
server.on('upgrade',(req,socket,head)=>{
 const origin=req.headers.origin;
 if(req.url!=='/ws/quotes'||(origin&&origin!==siteOrigin)||!connected||!subscribed){
  socket.write('HTTP/1.1 503 Service Unavailable\r\nConnection: close\r\n\r\n');socket.destroy();return;
 }
 wss.handleUpgrade(req,socket,head,ws=>wss.emit('connection',ws,req));
});
wss.on('connection',ws=>{
 ws.alive=true; sockets.add(ws);
 ws.on('pong',()=>{ws.alive=true});
 ws.on('close',()=>sockets.delete(ws));
 ws.on('error',()=>sockets.delete(ws));
 if(lastPublished)ws.send(lastPublished);
});
setInterval(()=>{
 for(const ws of sockets){
  if(!ws.alive){ws.terminate();sockets.delete(ws);continue;}
  ws.alive=false;
  try{ws.ping()}catch{ws.terminate();sockets.delete(ws)}
 }
},heartbeatMs).unref();

async function pull(){
 if(!connected||!producer?.isReady)return;
 const controller=new AbortController(),timeout=setTimeout(()=>controller.abort(),9000);
 try{
  const response=await fetch(feedUrl,{signal:controller.signal,headers:{Accept:'application/json'}});
  if(!response.ok)throw new Error('market feed HTTP '+response.status);
  const body=await response.json();
  if(!Array.isArray(body.quotes))throw new Error('missing market quotes');
  const records=body.quotes.filter(q=>typeof q.symbol==='string'&&
    /^[A-Z0-9./:_-]{1,20}$/.test(q.symbol)&&
    Number.isFinite(Number(q.price))&&Number(q.price)>0&&
    typeof q.quoted_at==='string').map(q=>({
    symbol:q.symbol,price:Number(q.price),quoted_at:q.quoted_at,
    source:q.source,transport:q.transport,
    delayed:Date.now()-Date.parse(q.quoted_at)>120000,
  })).sort((a,b)=>a.symbol.localeCompare(b.symbol));
  const state=JSON.stringify(records);
  lastFetchAt=now();upstreamError=null;
  if(state!==lastFingerprint){
   lastFingerprint=state;
   lastPublished=JSON.stringify({event:'snapshot',data:records,as_of:lastFetchAt});
   await producer.publish(channel,lastPublished);
  }
 }catch(error){upstreamError=String(error?.message||error).slice(0,130)}
 finally{clearTimeout(timeout)}
}
async function startRedis(){
 if(!redisUrl){
  console.error('REDIS_URL is not set; REST and WebSocket market bridge remain disabled.');
  return;
 }
 producer=createClient({url:redisUrl,socket:{reconnectStrategy:retries=>Math.min(1000*2**Math.min(retries,5),30000)}});
 subscriber=producer.duplicate();
 for(const client of [producer,subscriber]){
  client.on('error',error=>{connected=false;console.error('Redis connection error',error.message)});
  client.on('ready',()=>{connected=Boolean(producer?.isReady&&subscriber?.isReady)});
 }
 try{
  await Promise.all([producer.connect(),subscriber.connect()]);
  connected=true;
  await subscriber.subscribe(channel,message=>{
   for(const ws of sockets)if(ws.readyState===WebSocket.OPEN){
    try{ws.send(message)}catch{ws.terminate()}
   }
  });
  subscribed=true;
  await pull();
  setInterval(pull,pollMs).unref();
 }catch(error){
  console.error('Redis setup failed',error.message);
  connected=false;subscribed=false;
 }
}
server.listen(port,'0.0.0.0',()=>{
 console.log('VERGE redis bridge listening on '+port);
 void startRedis();
});
async function shutdown(){
 server.close();
 for(const ws of sockets)ws.close(1001,'server stopping');
 try{if(subscriber?.isOpen)await subscriber.quit()}catch{}
 try{if(producer?.isOpen)await producer.quit()}catch{}
}
process.once('SIGTERM',()=>void shutdown());
process.once('SIGINT',()=>void shutdown());
