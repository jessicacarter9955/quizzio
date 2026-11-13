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
let group='All',term='',active='advanced-chart',selected=new Set(),loaded=false,loading=false,loadedFor='',previewSerial=0;
const groups=['All',...new Set(WIDGETS.map(x=>x.group))];
const escapeValue=s=>escapeHtml(String(s??''));
const current=()=>WIDGETS.find(x=>x.id===active)||WIDGETS[0];
const count=()=>selected.size;
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
 '<button class="pt-widget-tile" type="button" onclick="tradingWidgetsShow(\''+w.id+'\')" aria-label="Preview '+escapeValue(w.title)+'">'+
 '<span class="pt-widget-tile-name">'+escapeValue(w.title)+'</span><span class="pt-widget-tile-desc">'+escapeValue(w.description)+'</span>'+
 '<small>'+escapeValue(w.group)+'</small></button>'+
 '<label class="pt-widget-check"><input type="checkbox" aria-label="Include '+escapeValue(w.title)+' in client shortlist"'+(selected.has(w.id)?' checked':'')+
 ' onchange="tradingWidgetsToggle(\''+w.id+'\',this.checked)"><span>Select</span></label></article>').join(''):
 '<p class="pt-gallery-empty">No matching widgets. Change the filter.</p>';
}
function renderGallery(){
 const widget=current();
 return '<section class="pt-widget-gallery">'+
 '<div class="pt-gallery-header"><div><h1>TradingView widgets</h1><p>'+WIDGETS.length+' widgets · preview and select for the client</p></div>'+
 '<button class="pt-gallery-copy" onclick="tradingWidgetsCopy()" type="button">Copy shortlist ('+count()+')</button></div>'+
 '<div class="pt-gallery-groups">'+groups.map(x=>'<button type="button" class="'+(group===x?'active':'')+'" onclick="tradingWidgetsGroup(\''+x+'\')">'+escapeValue(x)+'</button>').join('')+'</div>'+
 '<div class="pt-gallery-filter"><label for="pt-gallery-search">Filter widgets</label><input id="pt-gallery-search" type="search" oninput="tradingWidgetsFilter(this.value)" value="'+escapeValue(term)+'" placeholder="Search widgets…"></div>'+
 '<div class="pt-gallery-layout"><div id="pt-gallery-list" class="pt-gallery-list">'+renderCards()+'</div>'+
 '<div class="pt-gallery-preview-column"><div class="pt-gallery-preview-head">'+
 '<div><h2>'+escapeValue(widget.title)+'</h2><p>'+escapeValue(widget.description)+'</p></div>'+
 '<a href="'+widget.doc+'" target="_blank" rel="noopener noreferrer">Official TradingView setup ↗</a></div>'+
 '<div id="pt-gallery-widget" class="pt-gallery-widget"><span>Loading '+escapeValue(widget.title)+'…</span></div>'+
 (widget.kind==='broker'?'<p class="pt-widget-notice">A broker ID approved by TradingView is required for a specific client broker preview.</p>':
 '<p class="pt-widget-notice">Live third-party widget preview; data and features may depend on market permissions.</p>')+
 '</div></div></section>';
}
window.tradingWidgetGalleryPage=renderGallery;
function mountPreview(){
 const host=document.getElementById('pt-gallery-widget');
 if(!host||state.page!=='widgets')return;
 const item=current(),serial=++previewSerial;
 host.textContent='';
 if(!canShow(item)){
  host.innerHTML='<p class="pt-widget-notice">Choose the client’s broker ID to preview the live broker widget. <a href="'+item.doc+
   '" target="_blank" rel="noopener noreferrer">Open the official demo ↗</a></p>';
  return;
 }
 if(item.kind==='web'){
   const tag='tv-'+item.script;
   const element=document.createElement(tag);
   element.className='pt-tv-web-component';
   element.setAttribute('theme',theme());
   element.setAttribute('lang','en');
   if(item.id==='ticker-tag'||item.id==='mini-chart')element.setAttribute('symbol',symbol());
   if(item.id==='market-summary'||item.id==='market-overview'||item.id==='market-data')element.setAttribute('symbols','NASDAQ:AAPL,NASDAQ:NVDA,NASDAQ:MSFT,NASDAQ:TSLA');
   if(item.id==='seasonal-chart')element.setAttribute('symbol',symbol());
   if(item.id==='forex-table')element.setAttribute('currencies','USD,EUR,GBP,JPY,CHF,AUD,CAD,NZD');
   host.appendChild(element);
   const script=document.createElement('script');script.type='module';
   script.src='https://www.tradingview-widget.com/w/en/'+tag+'.js';
   script.onerror=()=>{if(serial===previewSerial&&element.isConnected)
       host.insertAdjacentHTML('beforeend','<p class="pt-widget-notice">This component cannot load here. <a href="'+item.doc+'" target="_blank" rel="noopener noreferrer">View live official widget ↗</a></p>')};
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
 const script=document.createElement('script');script.async=true;script.type='text/javascript';
 script.src='https://s3.tradingview.com/external-embedding/embed-widget-'+item.script+'.js';
 script.textContent=JSON.stringify(settings(item));
 script.onerror=()=>{if(serial===previewSerial&&container.isConnected)
    host.insertAdjacentHTML('beforeend','<p class="pt-widget-notice">Preview unavailable. <a href="'+item.doc+'" target="_blank" rel="noopener noreferrer">Open TradingView demo ↗</a></p>')};
 container.appendChild(script);
}
window.tradingWidgetsShow=id=>{
 if(!WIDGETS.some(x=>x.id===id))return;
 active=id;window.render();
};
window.tradingWidgetsGroup=g=>{if(!groups.includes(g))return;group=g;window.render()};
window.tradingWidgetsFilter=value=>{
 term=String(value||'');
 const target=document.getElementById('pt-gallery-list');
 if(target)target.innerHTML=renderCards();
};
function selectedList(){
 return WIDGETS.filter(w=>selected.has(w.id)).map(w=>w.title+' — '+w.doc);
}
window.tradingWidgetsCopy=async()=>{
 const note=selectedList().length?'Selected TradingView widgets:\n\n'+selectedList().join('\n'):'No widgets selected yet.';
 try{await navigator.clipboard.writeText(note);toast('Client shortlist copied')}catch{
  const area=document.createElement('textarea');area.value=note;area.style.position='fixed';area.style.left='-9999px';
  document.body.appendChild(area);area.select();
  const ok=document.execCommand('copy');area.remove();
  toast(ok?'Client shortlist copied':'Copy not available');
 }
};
window.tradingWidgetsToggle=async(id,checked)=>{
 if(!WIDGETS.some(x=>x.id===id))return;
 const before=new Set(selected);
 if(checked)selected.add(id);else selected.delete(id);
 const button=document.querySelector('.pt-gallery-copy');if(button)button.textContent='Copy shortlist ('+count()+')';
 if(!state.token||!state.db||!state.supabaseKey||!state.account?.id){
  selected=before;toast('Sign in to save widget preferences');return;
 }
 const headers={apikey:state.supabaseKey,Authorization:'Bearer '+state.token,'Content-Type':'application/json'};
 try{
  const path=state.supabaseUrl+'/rest/v1/pt_widget_preferences';
  const r=checked?await fetch(path,{method:'POST',headers:{...headers,Prefer:'resolution=merge-duplicates,return=minimal'},
   body:JSON.stringify({user_id:state.account.id,widget_key:id,selected:true})}):
   await fetch(path+'?widget_key=eq.'+encodeURIComponent(id),{method:'DELETE',headers});
  if(!r.ok)throw Error('Save failed ('+r.status+')');
  toast('Widget choices saved to Supabase');
 }catch(e){
  selected=before;toast('Not saved: '+e.message);const box=document.querySelector('[data-widget-id="'+id+'"] input');
  if(box)box.checked=before.has(id);
 }
};
async function loadChoices(){
 if(!state.token||!state.db||!state.supabaseKey||loading)return;
 loading=true;
 try{
  const r=await fetch(state.supabaseUrl+'/rest/v1/pt_widget_preferences?select=widget_key&selected=eq.true',{headers:{
   apikey:state.supabaseKey,Authorization:'Bearer '+state.token},cache:'no-store'});
  if(!r.ok)throw Error('Could not load widget choices');
  selected=new Set((await r.json()).map(x=>x.widget_key).filter(k=>WIDGETS.some(w=>w.id===k)));
  loaded=true;loadedFor=state.token;
  if(state.page==='widgets')window.render();
 }catch(e){loaded=false;loadedFor='';toast(e.message)}
 finally{loading=false}
}
const earlier=window.paperTradingAfterRender;
window.paperTradingAfterRender=()=>{
 earlier?.();
 if(state.page!=='widgets')return;
 mountPreview();
 if(!loading&&(!loaded||loadedFor!==state.token))loadChoices();
};
window.tradingWidgetCatalog=WIDGETS.map(({id,title,group,doc,kind})=>({id,title,group,doc,kind}));
})();