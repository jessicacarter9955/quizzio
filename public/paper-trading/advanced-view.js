/* VERGE Advanced Chart: full-height TradingView embed with genuine drawing tools. */
(function(){
'use strict';
let overlay=null,lastFocused=null;
const icon='<svg viewBox="0 0 24 24" width="18" height="18" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M8 3H3v5M16 3h5v5M3 16v5h5M21 16v5h-5"/></svg>';
function tvSymbol(s){
 const symbol=String(s||'AAPL').trim().toUpperCase();
 if(symbol.indexOf(':')>=0)return symbol;
 if(symbol==='BTC/USD'||symbol==='BTCUSD')return 'COINBASE:BTCUSD';
 if(symbol==='ETH/USD'||symbol==='ETHUSD')return 'COINBASE:ETHUSD';
 if(symbol==='EUR/USD'||symbol==='EURUSD')return 'FX:EURUSD';
 if(symbol==='GBP/USD'||symbol==='GBPUSD')return 'FX:GBPUSD';
 if(['AAPL','NVDA','MSFT','TSLA','AMD','META','AMZN','GOOGL','GOOG','SPY','QQQ','NFLX','AVGO','INTC'].includes(symbol))return 'NASDAQ:'+symbol;
 // Use an unqualified ticker when no reliable TradingView exchange mapping is known.
 return symbol.replace('/','');
}
window.tradingViewSymbol=tvSymbol;
function mountWidget(host,symbol){
 host.innerHTML='<div class="pt-widget-loader" role="status"><span class="pt-loading-spinner" aria-hidden="true"></span><span>Loading advanced market chart…</span></div>';
 const hide=()=>host.querySelector('.pt-widget-loader')?.remove();
 let observed=false;const observer=new MutationObserver(()=>{const frame=host.querySelector('iframe');if(frame&&!observed){observed=true;frame.addEventListener('load',()=>{hide();observer.disconnect()},{once:true});setTimeout(hide,6500)}});observer.observe(host,{childList:true,subtree:true});
 setTimeout(()=>{const text=host.querySelector('.pt-widget-loader span:last-child');if(text){text.textContent='Advanced chart is taking longer than expected. Check network access or use the regular chart.';}observer.disconnect()},17000);
 const wrapper=document.createElement('div');
 wrapper.className='tradingview-widget-container pt-tv-embed';
 const body=document.createElement('div');
 body.className='tradingview-widget-container__widget';
 wrapper.appendChild(body);
 const attribution=document.createElement('div');
 attribution.className='tradingview-widget-copyright pt-tv-credit';
 const link=document.createElement('a');
 link.href='https://www.tradingview.com/symbols/'+encodeURIComponent(symbol.replace(':','-'))+'/';
 link.target='_blank';link.rel='noopener nofollow';
 link.textContent=symbol+' chart by TradingView';
 attribution.appendChild(link);
 wrapper.appendChild(attribution);
 host.appendChild(wrapper);
 const settings={
  autosize:true,
  symbol,interval:'60',timezone:'exchange',theme:document.documentElement.dataset.theme==='light'?'light':'dark',
  style:'1',locale:'en',
  hide_side_toolbar:false,hide_top_toolbar:false,hide_legend:false,
  hide_volume:false,allow_symbol_change:true,withdateranges:true,
  details:true,hotlist:true,calendar:true,save_image:true,
  support_host:'https://www.tradingview.com',
  watchlist:['NASDAQ:AAPL','NASDAQ:MSFT','NASDAQ:NVDA','NASDAQ:TSLA','NASDAQ:AMD','NYSE:KO','COINBASE:BTCUSD'],
  studies:[],compareSymbols:[]
 };
 const script=document.createElement('script');
 script.type='text/javascript';
 script.async=true;
 script.src='https://s3.tradingview.com/external-embedding/embed-widget-advanced-chart.js';
 script.textContent=JSON.stringify(settings);
 script.onerror=()=>{
  hide();observer.disconnect();if(host.isConnected)host.insertAdjacentHTML('beforeend','<p class="pt-tv-error">Advanced chart could not load. Check your connection or content blocker.</p>');
 };
 wrapper.appendChild(script);
}
window.tradingOpenAdvanced=()=>{
 if(overlay)return;
 lastFocused=document.activeElement;
 const symbol=tvSymbol(state.symbol);
 overlay=document.createElement('section');
 overlay.id='pt-advanced-overlay';overlay.className='pt-advanced-overlay';
 overlay.setAttribute('role','dialog');overlay.setAttribute('aria-modal','true');
 overlay.setAttribute('aria-label','Advanced market chart');
 overlay.innerHTML='<header class="pt-advanced-header"><div class="pt-advanced-label"><strong>Advanced Chart</strong><span id="pt-tv-selected-symbol"></span></div>'+
 '<span class="pt-advanced-note">Chart symbol may differ from the paper-order ticker. Data availability varies by market.</span>'+
 '<button type="button" class="pt-advanced-close" id="pt-advanced-close" aria-label="Close advanced chart" title="Close advanced chart"><span>Close</span><svg viewBox="0 0 24 24" width="19" height="19" fill="none" stroke="currentColor" stroke-width="2"><path d="M18 6 6 18M6 6l12 12"/></svg></button></header>'+
 '<div class="pt-advanced-frame" id="pt-advanced-frame"><p class="pt-tv-loading">Loading advanced market chart…</p></div>';
 document.body.appendChild(overlay);
 document.body.classList.add('pt-advanced-open');
 overlay.querySelector('#pt-tv-selected-symbol').textContent=symbol;
 overlay.querySelector('#pt-advanced-close').addEventListener('click',window.tradingCloseAdvanced);
 overlay.querySelector('#pt-advanced-close').focus();
 mountWidget(overlay.querySelector('#pt-advanced-frame'),symbol);
};
window.tradingCloseAdvanced=()=>{
 if(!overlay)return;
 overlay.remove();overlay=null;
 document.body.classList.remove('pt-advanced-open');
 if(lastFocused&&lastFocused.isConnected)lastFocused.focus();
 lastFocused=null;
};
document.addEventListener('keydown',(event)=>{
 if(!overlay)return;
 if(event.key==='Escape'){event.preventDefault();window.tradingCloseAdvanced();return}
 if(event.key==='Tab'){
  // The TradingView iframe handles its own tab sequence; keep our Close button available.
  if(!overlay.contains(document.activeElement))overlay.querySelector('#pt-advanced-close')?.focus();
 }
});
const existing=window.paperUIAfterRender;
window.paperUIAfterRender=function(){
 existing?.();
 const chart=document.getElementById('trade-chart');
 if(!chart)return;
 const card=chart.closest('.chart-panel');
 const bar=card?.querySelector('.pt-card-head');
 if(!bar||bar.querySelector('.pt-advanced-expand'))return;
 const button=document.createElement('button');
 button.type='button';button.className='pt-advanced-expand';
 button.innerHTML=icon+'<span>Advanced chart</span>';
 button.setAttribute('title','Expand chart with advanced drawing tools');
 button.setAttribute('aria-label','Expand to advanced chart');
 button.addEventListener('click',window.tradingOpenAdvanced);
 bar.appendChild(button);
};
})();