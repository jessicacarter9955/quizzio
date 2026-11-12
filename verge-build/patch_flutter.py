from pathlib import Path
p=Path("flutter_app/lib/main.dart")
source=p.read_text(encoding="utf-8")
def change(old,new):
    global source
    if old not in source:
        raise RuntimeError("Flutter source mismatch for: "+old[:100])
    source=source.replace(old,new,1)
change("bool dbConnected=false,loading=true;Map<String,double> prices=Map.of(demoOpening);",
       "bool dbConnected=false,loading=true,candleReal=false;Set<String> liveSymbols={};Map<String,String> liveTransports={};Map<String,double> prices=Map.of(demoOpening);")
change("final quoteRows = await client.from('pt_quotes').select('symbol,price,source');",
       "final quoteRows = await client.from('pt_quotes').select('symbol,price,source,transport');")
change("if (item['source'] == 'TWELVE_DATA') feedMode = 'live';",
       "if (item['source'] == 'TWELVE_DATA' && sym != null) {feedMode = 'live'; liveSymbols.add(sym); liveTransports[sym] = item['transport']?.toString()??'REST';}")
change("marketChannel=Supabase.instance.client.channel('market:quotes',opts:const RealtimeChannelConfig(private:true));\n    marketChannel!.onBroadcast(event:'tick',callback:(payload){_tick(payload);}).subscribe();",
       "marketChannel=Supabase.instance.client.channel('verge-pt-quotes');\n    marketChannel!.onPostgresChanges(event:PostgresChangeEvent.all,schema:'public',table:'pt_quotes',callback:(payload){_tick(Map<String,dynamic>.from(payload.newRecord));}).subscribe();")
change("if(mounted)setState((){prices[s]=p;if(q['source']=='TWELVE_DATA')feedMode='live';});",
       "if(mounted)setState((){prices[s]=p;if(q['source']=='TWELVE_DATA'){feedMode='live';liveSymbols.add(s);liveTransports[s]=q['transport']?.toString()??'REST';}});")
change("if(sbUrl.isNotEmpty)throw const FormatException('Supabase demo candles');final response=await http.get(Uri.parse('$apiBase/v1/candles/${Uri.encodeComponent(chosen)}?interval=$currentInterval')).timeout(const Duration(seconds:8));",
       "final response=await http.get(Uri.parse('$apiBase/v1/candles/${Uri.encodeComponent(chosen)}?interval=$currentInterval'),headers:accessToken!=null?{'Authorization':'Bearer $accessToken'}:{}).timeout(const Duration(seconds:12));")
change("setState(()=>candles=data);return;","setState((){candles=data;candleReal=body['mode']=='historical'&&body['source']=='TWELVE_DATA';});return;")
change("if(mounted&&chosen==symbol)setState(()=>candles=synthetic);",
       "if(mounted&&chosen==symbol)setState((){candles=synthetic;candleReal=false;});")
change("_small(feedMode=='live'?'Twelve Data quotes · Exchange hours apply':'Generated practice candles — not actual market prices')",
       "_small(candleReal?'Historical candles from Twelve Data · market hours apply':'Generated practice candles — not actual market prices')")
change("_small(instrumentNames[symList.indexOf(s)])",
       "_small(liveSymbols.contains(s)?'Twelve Data · ${liveTransports[s]??'REST'}':instrumentNames[symList.indexOf(s)])")
change("Text(feedMode=='live'?'● LIVE QUOTES':'● DEMO DATA'",
       "Text(liveSymbols.isNotEmpty?'● TWELVE DATA + DEMO':'● DEMO DATA'")
p.write_text(source,encoding="utf-8")
print("Applied authenticated Twelve Data + Supabase Realtime source patch")
