/* VERGE narrow-screen and portfolio transactions (backend-executed, not simulated locally). */
(function(){
 'use strict';
 const safe=x=>escapeHtml(x==null?'':String(x));
 const sideLabel=side=>side==='sell'?'Sell':'Buy';
 const fmtQty=x=>Number(x||0).toLocaleString('en-US',{maximumFractionDigits:6});
 const owned=s=>Number(state.portfolio.holdings[s]?.qty||0);
 const lastPrice=s=>Number(priceOf(s)||0);
 const recent=s=>{
  const q=state.prices[s];
  return q?.source==='TWELVE_DATA'&&Number(q.price)>0&&q.quoted_at&&Date.now()-Date.parse(q.quoted_at)<300000;
 };
 const canTrade=s=>recent(s)&&!!window.tradingRegularSessionOpen?.(s);
 const issue=s=>{
  if(!window.tradingRegularSessionOpen?.(s))return 'US stocks trade Mon–Fri, 09:30–16:00 New York time (excluding exchange holidays). Your holdings are safe in the virtual portfolio, but market buys and sells are paused outside that session.';
  if(!recent(s))return 'The last Twelve Data quote is more than five minutes old or unavailable. The simulator blocks market orders until a sufficiently fresh quote is received.';
  return '';
 };
 const actionButtons=(s,withSell=true)=>'<div class="pt-position-actions"><button type="button" data-symbol="'+safe(s)+'" onclick="portfolioOpenOrder(this.dataset.symbol,\'buy\')">Buy</button>'+
  (withSell&&owned(s)>0?'<button class="pt-card-sell" type="button" data-symbol="'+safe(s)+'" onclick="portfolioOpenOrder(this.dataset.symbol,\'sell\')">Sell</button>':'<button type="button" data-symbol="'+safe(s)+'" onclick="portfolioOpenOrder(this.dataset.symbol,\'buy\')">Buy more</button>')+'</div>';
 const positionCard=([s,p])=>{
  const price=lastPrice(s),gain=(price-Number(p.avg||0))*Number(p.qty||0),movement=gain>=0?'positive':'negative';
  return '<article class="pt-position-card"><div class="pt-position-top"><div><b>'+safe(s)+'</b><small>'+fmtQty(p.qty)+' units owned</small></div><strong class="'+movement+'">'+money(gain)+'</strong></div>'+
   '<div class="pt-position-data"><div><span>Average cost</span><strong>'+money(p.avg)+'</strong></div><div><span>Market value</span><strong>'+money(price*p.qty)+'</strong></div></div>'+
   actionButtons(s)+'</article>';
 };
 const historyCard=o=>{
  const s=String(o.symbol||''),side=String(o.side||'').toLowerCase();
  const when=o.created_at?new Date(o.created_at).toLocaleString():'Unknown';
  return '<article class="pt-history-card"><div class="pt-position-top"><div><b>'+safe(s)+'</b><small>'+safe(when)+'</small></div><strong class="'+(side==='buy'?'positive':'negative')+'">'+safe(side.toUpperCase())+'</strong></div>'+
   '<div class="pt-position-data"><div><span>Units</span><strong>'+fmtQty(o.quantity)+'</strong></div><div><span>Execution price</span><strong>'+money(o.fill_price)+'</strong></div></div>'+
   actionButtons(s)+'</article>';
 };
 // This global function is used by the existing route renderer.
 window.portfolioPage=function(){
  const rows=Object.entries(state.portfolio.holdings).filter(([,p])=>Number(p.qty)>0);
  return intro('YOUR VIRTUAL CAPITAL','Paper portfolio','Review positions, trades, and your simulated results.','<button class="primary-button" onclick="navigate(\'trade\')">+ New Trade</button>')+
  summaryCards()+
  '<section class="card table-card" style="margin-bottom:16px"><h2>Open positions</h2>'+
  (rows.length?'<div class="pt-portfolio-cards">'+rows.map(positionCard).join('')+'</div>':'<p class="pt-portfolio-empty">'+(state.token?'No open positions yet.':'Sign in to view your Supabase positions.')+'</p>')+'</section>'+
  '<section class="card table-card"><h2>Trade history</h2>'+
  (state.portfolio.orders.length?'<div class="pt-history-cards">'+state.portfolio.orders.slice(0,30).map(historyCard).join('')+'</div>':'<p class="pt-portfolio-empty">'+(state.token?'No paper trades recorded.':'Sign in to view your order history.')+'</p>')+'</section>';
 };
 window.portfolioOpenOrder=(symbol,side)=>{
  if(!state.token)return window.loginModal();
  if(!state.db)return toast('Student portfolio backend unavailable');
  if(!symbol)return toast('Select a valid asset');
  state.symbol=symbol;state.side=side==='sell'?'sell':'buy';state.qty=state.side==='sell'?owned(symbol):1;
  const allow=canTrade(symbol),reason=issue(symbol),price=lastPrice(symbol);
  const container=document.getElementById('overlay');if(!container)return;
  container.innerHTML='<div class="modal-root" onclick="closeModal(event)"><div class="modal pt-confirm-order" role="dialog" aria-modal="true" aria-labelledby="pt-order-dialog-title" onclick="event.stopPropagation()">'+
  '<div class="modal-header"><h2 id="pt-order-dialog-title">'+sideLabel(state.side)+' '+safe(symbol)+'</h2><button class="close" aria-label="Close trade dialog" type="button" onclick="closeModal()">×</button></div>'+
  '<p>You own <strong>'+fmtQty(owned(symbol))+'</strong> units. Reference price: <strong>'+money(price)+'</strong>. This is a paper trade with no real money.</p>'+
  '<label class="pt-qty-label" for="pt-confirm-quantity">Quantity</label><input id="pt-confirm-quantity" type="number" step="any" min="0.000001" value="'+fmtQty(state.qty)+'" aria-label="Quantity to '+state.side+'"/>'+
  '<div class="pt-order-own"><span>Estimated '+(state.side==='sell'?'proceeds':'cost')+'</span><strong id="pt-confirm-total">'+money(price*state.qty)+'</strong></div>'+
  (!allow?'<p class="pt-trade-unavailable" role="status">'+safe(reason)+'</p>':'')+
  '<div class="pt-confirm-actions"><button class="secondary-button" onclick="closeModal();navigate(\'trade\')" type="button">Review Trade</button><button class="primary-button" id="pt-confirm-submit" type="button" onclick="portfolioConfirmOrder()" '+(!allow?'disabled':'')+'>Confirm '+sideLabel(state.side)+'</button></div>'+
  '</div></div>';
  const field=document.getElementById('pt-confirm-quantity');
  field.addEventListener('input',()=>{
   const n=Number(field.value||0);document.getElementById('pt-confirm-total').textContent=money(price*Math.max(0,n));
  });
  document.querySelector('.pt-confirm-order .close')?.focus();
 };
 window.portfolioConfirmOrder=async()=>{
  const qty=Number(document.getElementById('pt-confirm-quantity')?.value||0),symbol=state.symbol;
  if(!Number.isFinite(qty)||qty<=0||qty>1000000)return toast('Enter a valid quantity');
  if(state.side==='sell'&&qty>owned(symbol))return toast('You own '+fmtQty(owned(symbol))+' units. Reduce the sell quantity.');
  if(!canTrade(symbol))return toast(issue(symbol));
  if(state.side==='buy'&&qty*lastPrice(symbol)>state.portfolio.cash)return toast('Insufficient virtual buying power');
  state.qty=qty;
  window.closeModal();
  if(typeof window.tradingSubmitOrder==='function')await window.tradingSubmitOrder();
  else await window.placeOrder();
 };
 function measureNavigation(){
  const bar=document.getElementById('nav-mobile');
  if(!bar)return;
  const update=()=>{
   const isMobile=window.matchMedia('(max-width:720px)').matches;
   document.documentElement.style.setProperty('--pt-nav-height',isMobile?Math.ceil(bar.getBoundingClientRect().height)+'px':'0px');
  };
  update();
  if(typeof ResizeObserver!=='undefined')new ResizeObserver(update).observe(bar);
  window.addEventListener('resize',update,{passive:true});
 }
 if(document.readyState==='loading')document.addEventListener('DOMContentLoaded',measureNavigation,{once:true});
 else measureNavigation();
})();