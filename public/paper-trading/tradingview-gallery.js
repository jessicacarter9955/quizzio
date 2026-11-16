/* VERGE official TradingView Widget Gallery, preview one widget at a time. */
(function(){
'use strict';
const ROOT='https://www.tradingview.com/widget-docs/widgets/';
const WIDGETS=[
 ['advanced-chart','Advanced Chart','Charts','charts/advanced-chart','advanced-chart','iframe','Candles, indicators, drawings, analysis'],
 ['symbol-overview','Symbol Overview','Charts','charts/symbol-overview','symbol-overview','iframe','One symbol with multiple timeframes'],
 ['mini-chart','Mini Chart','Charts','charts/mini-chart','mini-symbol-overview','iframe','Small symbol chart'],
 ['seasonal-chart','Seasonal Chart','Charts','charts/seasonal-chart','seasonal-chart','web','Seasonality across calendar years'],
 ['market-summary','Market Summary','Watchlists','watchlists/market-summary','market-summary','web','Watchlist with multi-symbol chart'],
 ['market-overview','Market Overview','Watchlists','watchlists/market-overview','market-overview','iframe','Quick market indices and movers'],
 ['market-data','Market Data','Watchlists','watchlists/market-data','market-quotes','iframe','Tables of live market metrics'],
 ['ticker-tape','Ticker Tape','Tickers','tickers/ticker-tape','ticker-tape','iframe','Scrolling multi-symbol prices'],
 ['ticker-tag','Ticker Tag','Tickers','tickers/ticker-tag','ticker-tag','web','Compact interactive inline price'],
 ['single-ticker','Single Ticker','Tickers','tickers/single-ticker','single-quote','iframe','Price of one instrument'],
 ['tickers','Tickers','Tickers','tickers/tickers','ticker','iframe','Non-scrolling multi-symbol strip'],
 ['stock-heatmap','Stock Heatmap','Heatmaps','heatmaps/stock-heatmap','stock-heatmap','iframe','Sectors and market-cap heatmap'],
 ['crypto-heatmap','Crypto Coins Heatmap','Heatmaps','heatmaps/crypto-coins-heatmap','crypto-coins-heatmap','iframe','Crypto market heatmap'],
 ['etf-heatmap','ETF Heatmap','Heatmaps','heatmaps/etf-heatmap','etf-heatmap','iframe','ETF comparison heatmap'],
 ['forex-table','Forex Table','Heatmaps','heatmaps/forex-table','forex-table','web','Forex cross-pair table'],
 ['forex-cross-rates','Forex Cross Rates','Heatmaps','heatmaps/forex-cross-rates','forex-cross-rates','iframe','Foreign-exchange cross rates'],
 ['forex-heatmap','Forex Heatmap','Heatmaps','heatmaps/forex-heatmap','forex-heat-map','iframe','Currency strength heatmap'],
 ['screener','Screener','Screeners','screeners/screener','screener','iframe','Filter stocks and technicals'],
 ['crypto-market','Cryptocurrency Market','Screeners','screeners/cryptocurrency-market','crypto-mkt-screener','iframe','Market cap ranked crypto'],
 ['symbol-info','Symbol Info','Symbol Details','symbol-details/symbol-info','symbol-info','iframe','Company snapshot and price'],
 ['technical-analysis','Technical Analysis','Symbol Details','symbol-details/technical-analysis','technical-analysis','iframe','Technical rating across indicators'],
 ['fundamental-data','Fundamental Data','Symbol Details','symbol-details/fundamental-data','financials','iframe','Fundamental financial ratios'],
 ['company-profile','Company Profile','Symbol Details','symbol-details/company-profile','symbol-profile','iframe','Company description and sector'],
 ['top-stories','Top Stories','News','news/top-stories','timeline','iframe','News about stocks and markets'],
 ['economic-calendar','Economic Calendar','Calendars','calendars/economic-calendar','events','iframe','Important economic releases'],
 ['broker-rating','Broker Rating','Brokers','brokers/rating','broker-rating','broker','Broker review scores'],
 ['broker-reviews','Broker Reviews','Brokers','brokers/reviews','broker-reviews','broker','Recent verified broker reviews'],
 ['economic-map','Economic Map','Economics','economics/economic-map','economic-map','web','World economic indicators']
].map(v=>({id:v[0],title:v[1],group:v[2],doc:ROOT+v[3]+'/',script:v[4],kind:v[5],description:v[6]}));
let group='All',term='',active='advanced-chart',previewSerial=0;
const groups=['All',...new Set(WIDGETS.map(x=>x.group))];
const escapeValue=s=>escapeHtml(String(s??''));
const current=()=>WIDGETS.find(x=>x.id===active)||WIDGETS[0];
const symbol=()=>window.tradingViewSymbol?window.tradingViewSymbol(state.symbol):'NASDAQ:AAPL';
const theme=()=>document.documentElement.dataset.theme==='light'?'light':'dark';
function settings(item){
 const sym=symbol(),symbols=['NASDAQ:AAPL','NASDAQ:NVDA','NASDAQ:MSFT','NASDAQ:TSLA','COINBASE:BTCUSD','FOREXCOM:EURUSD'];
 const base={autosize:true,colorTheme:theme(),theme:theme(),isTransparent:true,locale:'en'};
 switch(item.id){
  case 'advanced-chart':return {autosize:true,symbol:sym,interval:'D',timezone:'exchange',theme:theme(),style:'1',locale:'en',
    hide_side_toolbar:false,hide_top_toolbar:false,hide_legend:false,withdateranges:true,allow_symbol_change:true,details:true,save_image:true};
  case 'symbol-overview':return {...base,symbols:[[sym+'|1D']],chartOnly:false,width:'100%',height:'100%',chartType:'area',lineWidth:2,scalePosition:'right',gridLineColor:'rgba(42,46,57,.2)'};
  case 'mini-chart':return {...base,symbol:sym,width:'100%',height:'100%',dateRange:'12M',largeChartUrl:'',noTimeScale:false};
  case 'market-overview':return {...base,tabs:[{title:'US stocks',symbols:symbols.slice(0,4).map(s=>({s}))},{title:'Crypto & FX',symbols:symbols.slice(4).map(s=>({s}))}]};
  case 'market-data':return {...base,symbolsGroups:[{name:'US markets',symbols:symbols.slice(0,4).map(s=>({name:s,displayName:s.split(':')[1]}))}]};
  case 'ticker-tape':return {symbols:symbols.map(s=>({proName:s,title:s.split(':')[1]})),showSymbolLogo:true,isTransparent:true,displayMode:'adaptive',colorTheme:theme(),locale:'en'};
  case 'single-ticker':return {...base,symbol:sym,width:'100%'};
  case 'tickers':return {...base,symbols:symbols.map(s=>({proName:s,title:s.split(':')[1]})),showSymbolLogo:true,width:'100%'};
  case 'stock-heatmap':return {...base,dataSource:'SPX500',blockSize:'market_cap_basic',blockColor:'change',grouping:'sector',hasTopBar:true};
  case 'crypto-heatmap':return {...base,dataSource:'Crypto',blockSize:'market_cap_calc',blockColor:'24h_close_change|5',hasTopBar:true};
  case 'etf-heatmap':return {...base,dataSource:'AllUSEtf',blockSize:'aum',blockColor:'change',hasTopBar:true};
  case 'forex-cross-rates':return {...base,currencies:['EUR','USD','GBP','JPY','CHF','CAD','AUD','NZD']};
  case 'forex-heatmap':return {...base,currencies:['EUR','USD','GBP','JPY','CHF','CAD','AUD','NZD']};
  case 'screener':return {width:'100%',height:'100%',defaultColumn:'overview',defaultScreen:'most_capitalized',market:'america',showToolbar:true,colorTheme:theme(),locale:'en',isTransparent:true};
  case 'crypto-market':return {...base,width:'100%',height:'100%',defaultColumn:'overview'};
  case 'symbol-info':return {...base,symbol:sym,width:'100%'};
  case 'technical-analysis':return {...base,interval:'1D',width:'100%',height:'100%',symbol:sym};
  case 'fundamental-data':return {...base,symbol:sym,width:'100%',height:'100%'};
  case 'company-profile':return {...base,symbol:sym,width:'100%',height:'100%'};
  case 'top-stories':return {...base,feedMode:'symbol',symbol:sym,width:'100%',height:'100%',displayMode:'regular'};
  case 'economic-calendar':return {...base,width:'100%',height:'100%',importanceFilter:'0,1',countryFilter:'us,eu,gb,jp'};
  default:return {...base};
 }
}
function canShow(item){return item.kind!=='broker'}
function itemList(){
 const q=term.toLowerCase().trim();
 return WIDGETS.filter(x=>(group==='All'||x.group===group)&&(!q||[x.title,x.group,x.description].join(' ').toLowerCase().includes(q)));
}
function renderCards(){
 const list=itemList();
 return list.length?list.map(w=>'<article class="pt-gallery-item'+(w.id===active?' active':'')+'" data-widget-id="'+w.id+'">'+
 '<button class="pt-widget-tile" type="button" onclick="tradingWidgetsShow(\''+w.id+'\')" aria-label="Show live preview of '+escapeValue(w.title)+'">'+
 '<span class="pt-widget-tile-name">'+escapeValue(w.title)+'</span><span class="pt-widget-tile-desc">'+escapeValue(w.description)+'</span>'+
 '<small>'+escapeValue(w.group)+(w.id===active?' · Previewing':'')+'</small></button></article>').join(''):
 '<p class="pt-gallery-empty">No matching widgets. Change the filter.</p>';
}
function renderGallery(){
 const widget=current();
 return '<section class="pt-widget-gallery">'+
 '<div class="pt-gallery-header"><div><h1>Market widgets</h1><p>'+WIDGETS.length+' widgets · select any tile to see its live preview</p></div></div>'+
 '<div class="pt-gallery-groups">'+groups.map(x=>'<button type="button" class="'+(group===x?'active':'')+'" onclick="tradingWidgetsGroup(\''+x+'\')">'+escapeValue(x)+'</button>').join('')+'</div>'+
 '<div class="pt-gallery-filter"><label for="pt-gallery-search">Filter widgets</label><input id="pt-gallery-search" type="search" oninput="tradingWidgetsFilter(this.value)" value="'+escapeValue(term)+'" placeholder="Search widgets…"></div>'+
 '<div class="pt-gallery-layout"><div id="pt-gallery-list" class="pt-gallery-list">'+renderCards()+'</div>'+
 '<div class="pt-gallery-preview-column"><div class="pt-gallery-preview-head">'+
 '<div><h2>'+escapeValue(widget.title)+'</h2><p>'+escapeValue(widget.description)+'</p></div>'+
 '</div>'+
 '<div id="pt-gallery-widget" class="pt-gallery-widget" aria-live="polite"><div class="pt-widget-loader" role="status"><span class="pt-loading-spinner" aria-hidden="true"></span><span>Loading '+escapeValue(widget.title)+'…</span></div></div>'+
 '<div class="pt-gallery-preview-actions"><button type="button" class="secondary-button" onclick="tradingWidgetsRetry()">↻ Reload preview</button></div>'+
 (widget.kind==='broker'?'<p class="pt-widget-notice">Broker previews require an authorized provider account and cannot display live broker data without it.</p>':
 '<p class="pt-widget-notice">Live market content may depend on data access, network conditions or device compatibility.</p>')+
 '</div></div></section>';
}
window.tradingWidgetGalleryPage=renderGallery;
function mountPreview(){
 const host=document.getElementById('pt-gallery-widget');
 if(!host||state.page!=='widgets')return;
 const item=current(),serial=++previewSerial;
 const fallback=(why)=>{
  if(serial!==previewSerial||!host.isConnected)return;
  host.innerHTML='<div class="pt-widget-unavailable" role="status"><strong>Preview unavailable</strong><p>'+escapeValue(why)+'</p><button type="button" class="secondary-button" onclick="tradingWidgetsRetry()">Retry loading</button></div>';
 };
 host.innerHTML='<div class="pt-widget-loader" role="status"><span class="pt-loading-spinner" aria-hidden="true"></span><span>Loading '+escapeValue(item.title)+'…</span></div>';
 const done=()=>{if(serial===previewSerial&&host.isConnected)host.querySelector('.pt-widget-loader')?.remove()};
 const loadingText=(message)=>{if(serial===previewSerial){const node=host.querySelector('.pt-widget-loader span:last-child');if(node)node.textContent=message;}};
 setTimeout(()=>loadingText('Still loading '+item.title+'…'),6500);
 // Never leave a blank rectangle: if a third-party embed cannot initialize, show a retry and its official preview.
 const timeout=setTimeout(()=>{
  if(serial!==previewSerial)return;
  if(host.querySelector('.pt-widget-loader'))fallback('The external widget did not initialize within 22 seconds. It may be blocked by the Android WebView, a network filter, or provider permissions.');
 },22000);
 const finish=()=>{if(serial!==previewSerial)return;clearTimeout(timeout);done()};
 if(item.kind==='broker'){
  clearTimeout(timeout);
  fallback('This broker preview requires an authorized broker ID. Other widgets remain available.');
  return;
 }
 if(item.kind==='web'||item.id==='forex-cross-rates'||item.id==='forex-heatmap'){
   const componentName=({'mini-chart':'mini-chart','forex-cross-rates':'forex-table','forex-heatmap':'forex-table'})[item.id]||item.script;
   const tag='tv-'+componentName;
   const element=document.createElement(tag);
   element.className='pt-tv-web-component';
   element.setAttribute('theme',theme());
   element.setAttribute('lang','en');
   if(['mini-chart','ticker-tag','seasonal-chart'].includes(item.id))element.setAttribute('symbol',symbol());
   if(['market-summary','market-overview','market-data'].includes(item.id))element.setAttribute('symbols','NASDAQ:AAPL,NASDAQ:NVDA,NASDAQ:MSFT,NASDAQ:TSLA');
   if(['forex-table','forex-cross-rates','forex-heatmap'].includes(item.id))element.setAttribute('currencies','USD,EUR,GBP,JPY,CHF,AUD,CAD,NZD');
   host.appendChild(element);
   const script=document.createElement('script');script.type='module';
   script.src='https://widgets.tradingview-widget.com/w/en/'+tag+'.js';
   script.onerror=()=>fallback('The external market component could not load on this device or network.');
   script.onload=()=>{
    if(typeof customElements!=='undefined'&&customElements.whenDefined){
      customElements.whenDefined(tag).then(()=>setTimeout(finish,400)).catch(()=>fallback('This market widget could not initialize.'));
    }else setTimeout(finish,1000);
   };
   host.appendChild(script);
   return;
 }
 const container=document.createElement('div');container.className='tradingview-widget-container pt-gallery-tv-container';
 const body=document.createElement('div');body.className='tradingview-widget-container__widget';
 container.appendChild(body);
 const footer=document.createElement('div');footer.className='tradingview-widget-copyright pt-gallery-tv-credit';
 const anchor=document.createElement('a');anchor.href=item.doc;anchor.target='_blank';anchor.rel='noopener nofollow';
 anchor.textContent=item.title+' by TradingView';footer.appendChild(anchor);container.appendChild(footer);
 host.appendChild(container);
 const observer=new MutationObserver(()=>{
  if(serial!==previewSerial){observer.disconnect();return;}
  const frame=host.querySelector('iframe');
  if(frame){observer.disconnect();frame.addEventListener('load',finish,{once:true});setTimeout(finish,3500);}
 });
 observer.observe(host,{childList:true,subtree:true});
 const script=document.createElement('script');script.async=true;script.type='text/javascript';
 script.src='https://s3.tradingview.com/external-embedding/embed-widget-'+item.script+'.js';
 script.textContent=JSON.stringify(settings(item));
 script.onerror=()=>{observer.disconnect();fallback('The market widget failed to load. Please retry when a network connection is available.')};
 container.appendChild(script);
}
window.tradingWidgetsRetry=()=>mountPreview();
window.tradingWidgetsShow=id=>{
 if(!WIDGETS.some(x=>x.id===id))return;
 active=id;window.render();
 if(window.matchMedia('(max-width:760px)').matches){requestAnimationFrame(()=>{const list=document.getElementById('pt-gallery-list'),tile=list?.querySelector('.pt-gallery-item.active');if(list&&tile){list.scrollTo({left:Math.max(0,tile.offsetLeft-list.offsetLeft-(list.clientWidth-tile.clientWidth)/2),behavior:'smooth'});const top=window.scrollY+list.getBoundingClientRect().top-10;window.scrollTo({top:Math.max(0,top),behavior:'smooth'});}});}
};
window.tradingWidgetsGroup=g=>{if(!groups.includes(g))return;group=g;const matches=itemList();if(!matches.some(w=>w.id===active))active=matches[0]?.id||'';window.render()};
window.tradingWidgetsFilter=value=>{
 term=String(value||'');const matches=itemList();if(matches.length&&!matches.some(w=>w.id===active)){active=matches[0].id;window.render();return;}
 const target=document.getElementById('pt-gallery-list');
 if(target)target.innerHTML=renderCards();
};
const earlier=window.paperTradingAfterRender;
window.paperTradingAfterRender=()=>{
 earlier?.();
 if(state.page!=='widgets')return;
 mountPreview();
};
window.tradingWidgetCatalog=WIDGETS.map(({id,title,group,doc,kind})=>({id,title,group,doc,kind}));
})();