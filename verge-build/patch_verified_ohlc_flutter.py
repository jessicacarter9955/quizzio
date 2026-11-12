from pathlib import Path
p=Path('flutter_app/lib/main.dart')
s=p.read_text(encoding='utf-8')
def splice(a,b,replacement):
 global s
 i=s.find(a);j=s.find(b,i)
 if i<0 or j<0:raise RuntimeError('Cannot locate mobile patch boundary '+a)
 s=s[:i]+replacement+s[j:]
s=s.replace("final demoOpening={'AAPL':263.52,'MSFT':487.94,'NVDA':196.20,'TSLA':438.42,'BTC/USD':99720.0,'EUR/USD':1.1587};",
"final demoOpening={'AAPL':0.0,'MSFT':0.0,'NVDA':0.0,'TSLA':0.0,'BTC/USD':0.0,'EUR/USD':0.0};")
splice('  Future<void> _loadCandles() async {','\n  Future<void> _save() async',"""  Future<void> _loadCandles() async {
    final chosen=symbol,currentInterval=interval;
    try{
      final uri=Uri.parse('$apiBase/v1/candles/'+Uri.encodeComponent(chosen)+'?interval=$currentInterval');
      final headers=accessToken!=null?{'Authorization':'Bearer $accessToken'}:<String,String>{};
      final response=await http.get(uri,headers:headers).timeout(const Duration(seconds:14));
      if(response.statusCode!=200)throw Exception('Provider unavailable');
      final body=jsonDecode(response.body);
      if(body is! Map||body['source']!='TWELVE_DATA'||body['mode']!='historical'||body['candles'] is! List)throw Exception('Unverified OHLC data');
      final clean=<Map<String,dynamic>>[];
      for(final item in body['candles'] as List){
        if(item is! Map)continue;
        final row=Map<String,dynamic>.from(item);
        final v=['time','open','high','low','close'].map((k)=>(row[k] as num?)?.toDouble()).toList();
        if(v.any((n)=>n==null||!n.isFinite||n<=0))continue;
        if(v[2]!<math.max(v[1]!,v[4]!)||v[3]!>math.min(v[1]!,v[4]!))continue;
        clean.add(row);
      }
      clean.sort((a,b)=>(a['time'] as num).compareTo(b['time'] as num));
      if(mounted&&chosen==symbol&&currentInterval==interval)setState((){candles=clean;candleReal=clean.isNotEmpty;});
    }catch(_){if(mounted&&chosen==symbol&&currentInterval==interval)setState((){candles=[];candleReal=false;});}
  }""")
splice('  Widget _watchlist()=>','\n  Widget _home()=>',"""  Widget _watchlist()=>_card(Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
    _heading('Market watchlist'),const SizedBox(height:14),
    ...symList.map((asset){
      final isReal=liveSymbols.contains(asset),transport=liveTransports[asset]??'REST';
      return InkWell(onTap:(){_selectSymbol(asset);_go(1);},child:Padding(
        padding:const EdgeInsets.symmetric(vertical:12),
        child:Row(children:[
          CircleAvatar(radius:17,backgroundColor:accentSoft,child:Text(asset[0],style:TextStyle(color:lime,fontWeight:FontWeight.bold))),
          const SizedBox(width:12),
          Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(asset,style:TextStyle(fontWeight:FontWeight.w700)),_small(instrumentNames[symList.indexOf(asset)])])),
          Column(crossAxisAlignment:CrossAxisAlignment.end,children:[
            Text((prices[asset]??0)>0?lastPrice(asset):'—',style:TextStyle(fontWeight:FontWeight.w700)),
            _small(isReal?'Twelve Data · $transport':'Waiting for provider',color:isReal?rise:faint)])
        ]))));
    }),const SizedBox(height:9),_small('Verified provider quotes; outside exchange hours prices may be delayed.')
  ]));""")
needle="SizedBox(height:large?360:265,child:ChartView(key:ValueKey('chart-$symbol-$interval'),symbol:symbol,candles:candles,light:vergeLight))"
if needle not in s:raise RuntimeError('Expected themed mobile chart widget missing')
s=s.replace(needle,"SizedBox(height:large?360:265,child:candles.isEmpty?Center(child:_small('Verified historical OHLC unavailable. No simulated chart.')):ChartView(key:ValueKey('chart-$symbol-$interval'),symbol:symbol,candles:candles,light:vergeLight))",1)
splice('  Future<void> _placeOrder() async {','\n  Future<void> _markDone(', """  Future<void> _placeOrder() async {
    if(!qty.isFinite||qty<=0||qty>1000000){_show('Enter a valid quantity.');return;}
    if(!liveSymbols.contains(symbol)||(prices[symbol]??0)<=0){_show('Verified Twelve Data quote required for paper orders.');return;}
    if(!dbConnected||accessToken==null){_show('Sign in to save paper orders on Supabase.');return;}
    try{
      final r=await http.post(Uri.parse('$tradeApiBase/v1/orders'),
        headers:{'Authorization':'Bearer $accessToken','Content-Type':'application/json'},
        body:jsonEncode({'symbol':symbol,'side':side,'quantity':qty,'client_order_id':const Uuid().v4()})).timeout(const Duration(seconds:14));
      if(r.statusCode!=200){
        final b=jsonDecode(r.body);
        throw Exception(b is Map?b['error']??'Order rejected':'Order rejected');
      }
      await _loadRealPortfolio();_show('Paper order filled; no real money involved.');
    }catch(e){_show('Order rejected: $e');}
  }""")
s=s.replace('$apiBase/v1/progress','$tradeApiBase/v1/progress')
s=s.replace('Generated practice candles — not actual market prices','Verified historical data unavailable; no generated candles')
s=s.replace("String lastPrice(String s){final n=prices[s]??0;return n<10?n.toStringAsFixed(5):dollar(n);}",
"String lastPrice(String s){final n=prices[s]??0;if(n<=0)return '—';return n<10?n.toStringAsFixed(5):dollar(n);}")
p.write_text(s,encoding='utf-8')
print('Verified real OHLC and authenticated paper trading patch applied')
