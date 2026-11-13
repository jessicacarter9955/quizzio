/* VERGE Trade Studio: live market search, protected virtual orders, time-accurate TradingView Lightweight Charts. */
(function(){
'use strict';
const MARKET='https://fcypamejorxoxvtcqubs.supabase.co/functions/v1/verge-market-api/v1';
const TRADE='https://fcypamejorxoxvtcqubs.supabase.co/functions/v1/verge-api/v1';
const searchState={term:'',items:[],busy:false,error:''};
let searchTimer=null,activeQuoteRequest=0,risks=[],riskLoadedFor='',chartRefreshId=null;
const baseHome=window.paperUIHomePage;
const esc=x=>escapeHtml(x??'');
const fmtTime=x=>x?new Date(x).toLocaleString(undefined,{day:'2-digit',month:'short',hour:'2-digit',minute:'2-digit'}):'Unavailable';
const quoteAge=q=>q?.quoted_at?Math.max(0,Date.now()-Date.parse(q.quoted_at)):Infinity;
const prettyAge=ms=>!Number.isFinite(ms)?'time unavailable':ms<60000?'under 1 min':ms<3600000?Math.round(ms/60000)+' min':ms<86400000?Math.round(ms/3600000)+' h':Math.round(ms/86400000)+' d';
const isCore=s=>['AAPL','MSFT','NVDA','TSLA','BTC/USD','EUR/USD'].includes(s);
const urlpath=(route)=>MARKET+'/'+route;
function marketLabel(symbol){
 const q=state.prices[symbol],age=quoteAge(q),isCrypto=/\//.test(symbol);
 if(!q||!Number(q.price))return 'Price unavailable';
 if(age<120000)return (q.transport==='WS'?'Streaming':'Recently quoted')+' · '+fmtTime(q.quoted_at);
 if(age<900000)return 'Last market update '+prettyAge(age)+' ago';
 return (isCrypto?'Last available quote':'Last session / delayed')+' · '+fmtTime(q.quoted_at);
}
window.tradingMarketLabel=marketLabel;
function searchBox(){
 return '<div class="pt-search-wrap"><label class="pt-sr-only" for="pt-market-search">Find stocks and ETFs</label>'+
 '<input id="pt-market-search" type="search" value="'+esc(searchState.term)+'" placeholder="⌕  Search companies or tickers (AAPL, AMD, SPY…)" autocomplete="off" oninput="tradingSearch(this.value)" />'+
 (searchState.term?'<button type="button" aria-label="Clear search" class="pt-search-clear" onclick="tradingClearSearch()">×</button>':'')+
 '<div id="pt-search-results" class="pt-search-results" role="listbox">'+searchResultsMarkup()+'</div></div>';
}
function searchResultsMarkup(){
 if(!searchState.term||searchState.term.trim().length<2)return '';
 if(searchState.busy)return '<div class="pt-search-info">Searching supported instruments…</div>';
 if(searchState.error)return '<div class="pt-search-info">'+esc(searchState.error)+'</div>';
 if(!searchState.items.length)return '<div class="pt-search-info">No matching supported instruments. Try a ticker.</div>';
 return searchState.items.map((item,i)=>'<button type="button" role="option" class="pt-search-result" onclick="tradingPick('+i+')">'+
 '<span class="pt-search-symbol">'+esc(item.symbol)+'</span><span class="pt-search-description">'+esc(item.name)+'<small>'+esc(item.exchange)+' · '+esc(item.type)+'</small></span>'+
 '<span class="pt-search-arrow">↗</span></button>').join('');
}
window.tradingClearSearch=()=>{searchState.term='';searchState.items=[];searchState.error='';window.render();document.getElementById('pt-market-search')?.focus()};
window.tradingSearch=term=>{
 searchState.term=String(term||'');searchState.busy=false;searchState.error='';searchState.items=[];
 const results=document.getElementById('pt-search-results');
 if(results)results.innerHTML='';
 clearTimeout(searchTimer);
 if(searchState.term.trim().length<2)return;
 searchState.busy=true;if(results)results.innerHTML=searchResultsMarkup();
 const termAtStart=searchState.term.trim();
 searchTimer=setTimeout(async()=>{
  try{
   if(!state.token)throw Error('Sign in to search');
   const r=await fetch(urlpath('search?q='+encodeURIComponent(termAtStart)),{headers:{Authorization:'Bearer '+state.token},cache:'no-store'});
   const d=await r.json();if(!r.ok)throw Error(d.error||'Search unavailable');
   if(searchState.term.trim()!==termAtStart)return;
   searchState.items=Array.isArray(d.results)?d.results:[];searchState.error='';
  }catch(e){if(searchState.term.trim()!==termAtStart)return;searchState.error=e.message||'Search unavailable';}
  finally{if(searchState.term.trim()===termAtStart){searchState.busy=false;const node=document.getElementById('pt-search-results');if(node)node.innerHTML=searchResultsMarkup();}}
 },500);
};
window.tradingPick=async i=>{
 const item=searchState.items[Number(i)];if(!item)return;
 searchState.term='';searchState.items=[];searchState.busy=false;
 const symbol=String(item.symbol).toUpperCase();
 if(!/^[A-Z0-9./:_-]{1,20}$/.test(symbol))return;
 if(!assets.some(x=>x[0]===symbol))assets.push([symbol,String(item.name||symbol),symbol.slice(0,1),'0']);
 names[symbol]=String(item.name||symbol);
 if(!state.prices[symbol])state.prices[symbol]={symbol,price:0,source:'UNAVAILABLE',quoted_at:null};
 state.symbol=symbol;state.page='trade';state.qty=1;window.render();
 await loadInstrument(symbol);
};
async function loadInstrument(symbol){
 if(!state.token||!state.db)return;
 const serial=++activeQuoteRequest;
 try{
  const r=await fetch(urlpath('instrument?symbol='+encodeURIComponent(symbol)),{headers:{Authorization:'Bearer '+state.token},cache:'no-store'});
  const d=await r.json();if(!r.ok)throw Error(d.error||'Quote unavailable');
  if(d.quote&&d.quote.symbol===symbol){state.prices[symbol]={...d.quote,price:Number(d.quote.price)};if(d.name)names[symbol]=d.name;}
  if(serial===activeQuoteRequest&&state.symbol===symbol)window.render();
 }catch(e){if(serial===activeQuoteRequest)toast('Quote: '+e.message)}
}
window.tradingRefreshInstrument=()=>{if(!isCore(state.symbol))return loadInstrument(state.symbol)};
function chartMeta(){
 const quote=state.prices[state.symbol];
 return '<div class="pt-chart-meta"><span>'+esc(marketLabel(state.symbol))+'</span>'+
 '<span>'+({ '1min':'1D = last 24 hours · 1-minute bars', '1h':'1W = last 7 calendar days · hourly bars', '1day':'1M = last 30 calendar days · daily bars' }[state.interval]||'')+'</span>'+
 '<span>Gaps = no trades or closed market</span></div>';
}
function holding(){
 return state.portfolio.holdings[state.symbol]||{qty:0,avg:0};
}
function riskFor(symbol){return risks.find(x=>x.symbol===symbol&&x.status==='active')||null}
function riskFields(){
 const owned=Number(holding().qty||0),rule=riskFor(state.symbol);
 return '<div class="pt-protect"><div class="pt-protect-heading"><h3>Stop loss & take profit</h3><small>Virtual protective sell · only for owned units</small></div>'+
 '<div class="pt-risk-grid"><label>Stop loss<input id="pt-stop-loss" type="number" min="0.000001" step="any" placeholder="Below market price" value="'+(rule?.stop_loss||'')+'"></label>'+
 '<label>Take profit<input id="pt-take-profit" type="number" min="0.000001" step="any" placeholder="Above market price" value="'+(rule?.take_profit||'')+'"></label></div>'+
 '<div class="pt-risk-actions"><button class="secondary-button" type="button" onclick="tradingSaveRisk()" '+(!owned?'disabled':'')+'>'+(rule?'Update protection':'Protect position')+'</button>'+
 (rule?'<button class="pt-cancel-risk" onclick="tradingCancelRisk()">Cancel</button>':'')+'</div>'+
 '<p class="pt-risk-note">Trigger checks use fresh provider quotes (up to ~1 min between cycles). Not an exchange order; price gaps can change the fill.</p></div>';
}
function tradeCard(){
 const owned=Number(holding().qty||0),avg=Number(holding().avg||0),last=priceOf(state.symbol),sell=state.side==='sell',quote=state.prices[state.symbol];
 const valid=quote?.source==='TWELVE_DATA'&&quoteAge(quote)<300000;
 return '<div class="pt-order-title"><h2>Order ticket</h2><span class="pt-chip">'+(valid?'Quote available':'Market closed / stale quote')+'</span></div>'+
 '<div class="pt-order-toggle"><button class="'+(!sell?'active buy':'')+'" onclick="tradingChangeSide(\'buy\')">Buy</button>'+
 '<button class="'+(sell?'active sell':'')+'" onclick="tradingChangeSide(\'sell\')">Sell</button></div>'+
 '<div class="pt-order-own"><span>Your position</span><strong>'+fmt(owned)+' '+esc(symDisplay(state.symbol))+'</strong></div>'+
 (owned?'<div class="pt-order-own"><span>Average cost</span><strong>'+fmtPrice(avg)+'</strong></div>':'')+
 '<label class="pt-qty-label" for="pt-trade-quantity">Quantity</label><div class="pt-qty-row">'+
 '<input id="pt-trade-quantity" type="number" min="0.000001" step="any" value="'+Number(state.qty||1)+'" oninput="tradingQty(this.value)" aria-label="Order quantity"/>'+
 '<button type="button" onclick="tradingMax()" '+(!sell||!owned?'disabled':'')+'>Sell max</button></div>'+
 '<div class="pt-order-own"><span>Reference price</span><strong>'+fmtPrice(last)+'</strong></div>'+
 '<div class="pt-order-own"><span>Estimated '+(sell?'sale':'cost')+'</span><strong id="pt-order-estimate">'+money(Math.max(0,state.qty||0)*last)+'</strong></div>'+
 '<div class="pt-order-own"><span>Available cash</span><strong>'+money(state.portfolio.cash)+'</strong></div>'+
 (sell&&owned?'<div class="pt-order-own"><span>Estimated P&L</span><strong>'+money((last-avg)*Math.min(state.qty,owned))+'</strong></div>':'')+
 '<button class="primary-button pt-submit" '+(!valid||sell&&!owned?'disabled':'')+' onclick="tradingSubmitOrder()">'+
 (sell?'Sell':'Buy')+' '+esc(symDisplay(state.symbol))+' · Paper order</button>'+
 '<p class="pt-risk-note">Market orders execute only with a recent exchange quote. No real money.</p>'+
 riskFields();
}
window.paperUITradePage=()=>{
 const chips=assets.slice(0,6).map(a=>'<button class="symbol-selector '+(state.symbol===a[0]?'active':'')+'" onclick="selectSymbol(\''+a[0]+'\')">'+esc(symDisplay(a[0]))+'</button>').join('');
 const custom=!isCore(state.symbol)?'<button class="symbol-selector active">'+esc(state.symbol)+'</button>':'';
 return '<div class="pt-trade-toolbar"><h1>Trade</h1>'+searchBox()+'</div>'+
 '<div class="market-tabs">'+chips+custom+'</div>'+
 '<section class="trade-layout pt-trade-layout"><div class="card chart-panel pt-trade-chart"><div class="pt-card-head"><h2>'+esc(names[state.symbol]||state.symbol)+'</h2><div class="timeframes">'+intervalButtons()+'</div></div>'+
 selectedAsset()+'<div id="trade-chart" class="chart"></div>'+chartMeta()+'</div>'+
 '<aside class="card order-panel pt-ticket">'+tradeCard()+'</aside></section>';
};
window.paperUIHomePage=()=>{
 const original=baseHome?baseHome():'';
 return '<div class="pt-trade-toolbar"><h1>Home</h1>'+searchBox()+'</div>'+
 original.replace('<section class="page-intro"><h1>Home</h1></section>','')+
 '<div class="pt-chart-footnote">The 1D chart covers the last 24 hours, including market closures. Prices update when the provider publishes trades.</div>';
};
window.tradingChangeSide=side=>{state.side=side==='sell'?'sell':'buy';window.render()};
window.tradingQty=value=>{
 state.qty=Number(value)||0;const e=document.getElementById('pt-order-estimate');
 if(e)e.textContent=money(priceOf(state.symbol)*Math.max(0,state.qty));
};
window.tradingMax=()=>{state.qty=Number(holding().qty)||0;window.render()};
async function tradeRest(path,payload){
 if(!state.token)throw Error('Sign in required');
 const r=await fetch(state.supabaseUrl+'/rest/v1/rpc/'+path,{method:'POST',headers:{apikey:state.supabaseKey,Authorization:'Bearer '+state.token,'Content-Type':'application/json'},body:JSON.stringify(payload)});
 const d=await r.json().catch(()=>({}));if(!r.ok)throw Error(d.message||d.error||'Request failed');return d;
}
async function loadRisks(){
 if(!state.token||!state.supabaseKey){risks=[];return}
 const r=await fetch(state.supabaseUrl+'/rest/v1/pt_risk_orders?select=symbol,quantity,stop_loss,take_profit,status,triggered_price,triggered_reason,triggered_at&order=updated_at.desc',{headers:{apikey:state.supabaseKey,Authorization:'Bearer '+state.token}});
 if(!r.ok)throw Error('Protection history unavailable');
 risks=await r.json();
 drawRiskHistory();
}
function readRiskValues(){
 const stop=document.getElementById('pt-stop-loss')?.value||'';
 const take=document.getElementById('pt-take-profit')?.value||'';
 if(!stop&&!take)throw Error('Enter a stop loss and/or take profit');
 return {p_stop_loss:stop?Number(stop):null,p_take_profit:take?Number(take):null};
}
window.tradingSaveRisk=async()=>{
 try{
  const owned=Number(holding().qty||0);if(!owned)throw Error('Buy units before protecting a position');
  const values=readRiskValues();
  await tradeRest('pt_set_risk_order',{p_symbol:state.symbol,p_quantity:owned,...values});
  await loadRisks();toast('Protection saved to Supabase');window.render();
 }catch(e){toast('Protection: '+e.message)}
};
window.tradingCancelRisk=async()=>{
 try{await tradeRest('pt_cancel_risk_order',{p_symbol:state.symbol});await loadRisks();toast('Protection cancelled');window.render()}
 catch(e){toast('Cancellation: '+e.message)}
};
window.tradingSubmitOrder=async()=>{
 const symbol=state.symbol,side=state.side,qty=Number(state.qty),price=priceOf(symbol),quote=state.prices[symbol];
 if(!state.token)return window.loginModal();
 if(!Number.isFinite(qty)||qty<=0||qty>1000000)return toast('Enter a valid quantity');
 if(!Number.isFinite(price)||price<=0||quote?.source!=='TWELVE_DATA'||quoteAge(quote)>=300000)return toast('Market closed or provider quote is too old');
 if(side==='sell'&&qty>Number(holding().qty||0))return toast('You can only sell owned units. Use Sell max.');
 if(side==='buy'&&price*qty>state.portfolio.cash)return toast('Insufficient virtual buying power');
 let values=null;try{values=readRiskValues()}catch{}
 const btn=document.querySelector('.pt-submit');if(btn)btn.disabled=true;
 try{
  const response=await fetch(TRADE+'/orders',{method:'POST',headers:{'Content-Type':'application/json',Authorization:'Bearer '+state.token},body:JSON.stringify({symbol,side,quantity:qty,client_order_id:uid()})});
  const result=await response.json();if(!response.ok)throw Error(result.error||'Order rejected');
  await loadPortfolio();let protectionError='';
  if(side==='buy'&&values){
   try{const nowOwned=Number(holding().qty||0);await tradeRest('pt_set_risk_order',{p_symbol:symbol,p_quantity:nowOwned,...values});}
   catch(e){protectionError='Protection not set: '+e.message;}
  }
  await loadRisks();window.render();
  toast(protectionError?'Order filled. '+protectionError:'Virtual '+side+' recorded in Supabase');
 }catch(e){toast('Paper order: '+e.message)}finally{if(btn)btn.disabled=false}
};
function drawRiskHistory(){
 const holder=document.getElementById('pt-risk-history');if(!holder)return;
 const rows=risks.filter(x=>x.status==='active'||x.status==='triggered');
 holder.innerHTML=rows.length?'<div class="pt-risk-table">'+rows.map(x=>
 '<div class="pt-risk-item"><b>'+esc(x.symbol)+'</b><span>'+fmt(x.quantity)+' units</span><span>SL '+(x.stop_loss?fmtPrice(x.stop_loss):'—')+'</span><span>TP '+(x.take_profit?fmtPrice(x.take_profit):'—')+'</span>'+
 '<small>'+esc(x.status==='triggered'?'Filled '+fmtPrice(x.triggered_price):'Active')+'</small></div>').join('')+'</div>':'<p class="pt-muted">No active protective orders. Open Trade and select a position.</p>';
}
const previousAfterRender=window.paperTradingAfterRender;
window.paperTradingAfterRender=()=>{
 previousAfterRender?.();
 if(state.page==='portfolio'){
  const holder=document.getElementById('content');
  if(holder&&!document.getElementById('pt-risk-history'))holder.insertAdjacentHTML('beforeend','<section class="card pt-protection-history"><h2>Stops & targets</h2><div id="pt-risk-history"></div></section>');
  drawRiskHistory();
 }
 if(state.token!==riskLoadedFor){
  riskLoadedFor=state.token;
  if(state.token)loadRisks().catch(()=>{riskLoadedFor=''});
  else risks=[];
 }
};
async function chartPage(){
 const holder=document.getElementById('trade-chart');if(!holder||!window.LightweightCharts)return;
 const symbol=state.symbol,interval=state.interval,secs=interval==='1min'?86400:interval==='1h'?604800:2592000;
 holder.textContent='Loading price history…';
 const query=urlpath('candles/'+encodeURIComponent(symbol)+'?interval='+encodeURIComponent(interval));
 let parsed;
 try{
  const r=await fetch(query,{headers:state.token?{Authorization:'Bearer '+state.token}:{},cache:'no-store'});
  parsed=await r.json();if(!r.ok)throw Error(parsed.error||'OHLC unavailable');
 }catch(e){if(document.getElementById('trade-chart')===holder)holder.textContent='Provider history unavailable: '+e.message;return}
 if(document.getElementById('trade-chart')!==holder||state.symbol!==symbol||state.interval!==interval)return;
 const raw=Array.isArray(parsed.candles)?parsed.candles:[];
 // Rolling calendar windows from wall-clock now: 24h / 7d / 30d, not last close or N trading sessions.
 const now=Math.floor(Date.now()/1000),start=now-secs;
 const candles=raw.filter(v=>Number(v.time)>=start&&Number(v.time)<=now&&Number(v.open)>0&&Number(v.high)>=Number(v.low))
   .map(v=>({time:Number(v.time),open:Number(v.open),high:Number(v.high),low:Number(v.low),close:Number(v.close)})).sort((a,b)=>a.time-b.time);
 if(!candles.length){holder.textContent='No market candles in the selected calendar window. Try a longer timeframe.';return;}
 state.candles=candles;
 if(state.chart){state.chart.dispose?.();state.chart=null}
 holder.textContent='';
 const light=window.LightweightCharts;
 const lightTheme=document.documentElement.dataset.theme==='light';
 const color=key=>getComputedStyle(document.documentElement).getPropertyValue(key).trim();
 const chart=light.createChart(holder,{width:holder.clientWidth||660,height:holder.clientHeight||300,
  layout:{background:{type:light.ColorType.Solid,color:color('--panel')||'#1e222d'},textColor:color('--muted')||'#999',attributionLogo:true},
  grid:{vertLines:{color:color('--chart-grid')||'#303543'},horzLines:{color:color('--chart-grid')||'#303543'}},
  timeScale:{timeVisible:interval!=='1day',secondsVisible:false,rightOffset:0,fixLeftEdge:false,fixRightEdge:false},
  crosshair:{mode:light.CrosshairMode.Normal},
  rightPriceScale:{borderColor:color('--border')||'#333'},
  localization:{locale:navigator.language||'en-US'},
 });
 const series=chart.addSeries(light.CandlestickSeries,{upColor:'#15a790',downColor:'#ee6b72',borderUpColor:'#15a790',borderDownColor:'#ee6b72',wickUpColor:'#15a790',wickDownColor:'#ee6b72',
  priceFormat:{type:'price',precision:priceOf(symbol)<10?5:2,minMove:priceOf(symbol)<10?0.00001:0.01}});
 // Whitespace bars extend the calendar axis after the closing bell; no fabricated OHLC prices.
 const latest=candles[candles.length-1].time;
 const frame=Math.floor(now/(interval==='1min'?60:interval==='1h'?3600:86400))*(interval==='1min'?60:interval==='1h'?3600:86400);
 const data=frame>latest?[...candles,{time:frame}]:candles;
 series.setData(data);
 const rule=riskFor(symbol);
 if(rule?.stop_loss)series.createPriceLine({price:Number(rule.stop_loss),color:'#ee6b72',lineWidth:2,lineStyle:light.LineStyle.Dashed,axisLabelVisible:true,title:'Stop'});
 if(rule?.take_profit)series.createPriceLine({price:Number(rule.take_profit),color:'#15a790',lineWidth:2,lineStyle:light.LineStyle.Dashed,axisLabelVisible:true,title:'Target'});
 try{chart.timeScale().setVisibleRange({from:start,to:Math.max(now,frame)});}catch{chart.timeScale().fitContent()}
 state.chart={dispose:()=>chart.remove()};state.series=series;
 if(state.resizeObserver)state.resizeObserver.disconnect();
 state.resizeObserver=new ResizeObserver(()=>{if(state.chart?.dispose)chart.resize(Math.max(1,holder.clientWidth),Math.max(1,holder.clientHeight))});
 state.resizeObserver.observe(holder);
 const panel=holder.closest('.chart-panel');
 const legend=panel?.querySelector('.chart-legend span:first-child');
 if(legend)legend.textContent='Provider candles · last '+fmtTime(new Date(latest*1000).toISOString())+(parsed.stale?' · cached history':'');
 const note=panel?.querySelector('.pt-chart-meta');
 if(note)note.innerHTML='<span>'+esc(marketLabel(symbol))+'</span><span>Latest candle '+fmtTime(new Date(latest*1000).toISOString())+'</span>'+
  '<span>'+(interval==='1min'?'Past 24 hours':interval==='1h'?'Past 7 days':'Past 30 days')+' · closed hours contain no price bars</span>';
}
window.tradingDrawChart=chartPage;
const priorRender=window.paperUIAfterRender;
window.paperUIAfterRender=()=>{priorRender?.();if(state.page==='home'||state.page==='trade'){
 const labels=document.querySelectorAll('.asset-price span');labels.forEach(x=>x.textContent=marketLabel(state.symbol));
 }};
setInterval(async()=>{
 if(state.token&&!isCore(state.symbol))await loadInstrument(state.symbol);
},90000);
setInterval(()=>{
 if((state.page==='home'||state.page==='trade')&&state.token&&window.LightweightCharts)window.tradingDrawChart();
},110000);
})();
