from pathlib import Path
p=Path('flutter_app/assets/chart.html')
html='''<!doctype html>
<html><head><meta charset="utf-8"/><meta name="viewport" content="width=device-width,initial-scale=1,maximum-scale=1"/>
<style>html,body,#chart{height:100%;width:100%;margin:0;padding:0;background:#1e222d;overflow:hidden;font-family:Arial,sans-serif}.notice{color:#9598a1;display:grid;place-items:center;height:100%;text-align:center;font-size:12px}</style></head>
<body><div id="chart"></div>
<script src="https://cdn.jsdelivr.net/npm/echarts@5.6.0/dist/echarts.min.js"></script>
<script>
let chart=null,candles=[],light=false;
const el=document.getElementById('chart');
function colors(){return light?{bg:'#ffffff',text:'#626773',grid:'#edf0f5'}:{bg:'#1e222d',text:'#9598a1',grid:'#2a2e39'}}
function render(){
  const c=colors();document.body.style.background=c.bg;el.style.background=c.bg;
  if(!window.echarts){el.innerHTML='<div class="notice">Chart unavailable; verified market history requires the chart library.</div>';return;}
  if(!chart)chart=echarts.init(el,null,{renderer:'canvas'});
  const ordered=Array.isArray(candles)?candles.filter(x=>[x.time,x.open,x.high,x.low,x.close].every(v=>Number.isFinite(Number(v))&&Number(v)>0)).sort((a,b)=>a.time-b.time):[];
  if(!ordered.length){chart.clear();return;}
  const labels=ordered.map(x=>new Date(x.time*1000).toLocaleString('en-GB',{day:'2-digit',month:'short',hour:'2-digit',minute:'2-digit'}));
  chart.setOption({
    animation:false,backgroundColor:'transparent',
    grid:{left:10,right:62,top:14,bottom:30},
    tooltip:{trigger:'axis',axisPointer:{type:'cross'},backgroundColor:c.bg,borderColor:c.grid,textStyle:{color:c.text}},
    xAxis:{type:'category',data:labels,boundaryGap:true,axisLine:{lineStyle:{color:c.grid}},axisLabel:{color:c.text,fontSize:10,hideOverlap:true},splitLine:{show:true,lineStyle:{color:c.grid}}},
    yAxis:{scale:true,position:'right',axisLine:{lineStyle:{color:c.grid}},axisLabel:{color:c.text,fontSize:10},splitLine:{show:true,lineStyle:{color:c.grid}}},
    dataZoom:[{type:'inside',xAxisIndex:0,filterMode:'none'}],
    series:[{type:'candlestick',data:ordered.map(x=>[Number(x.open),Number(x.close),Number(x.low),Number(x.high)]),itemStyle:{color:'#089981',color0:'#f23645',borderColor:'#089981',borderColor0:'#f23645'}}]
  },true);
  chart.resize();
}
window.chartSetTheme=function(next){light=!!next;render()};
window.chartSetData=function(data){candles=Array.isArray(data)?data:[];render()};
window.addEventListener('message',event=>{if(event.data?.type==='chartData'){light=!!event.data.light;candles=Array.isArray(event.data.candles)?event.data.candles:[];render()}});
window.addEventListener('resize',()=>chart?.resize());
render();
</script></body></html>'''
p.write_text(html,encoding='utf-8')
print('Paper Trading charts now use ECharts 5.6.0, not the previous chart vendor')
