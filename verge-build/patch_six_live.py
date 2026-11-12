from pathlib import Path
p=Path("flutter_app/lib/main.dart")
s=p.read_text(encoding="utf-8")
def swap(old,new,expected=1):
    global s
    count=s.count(old)
    if count!=expected:
        raise RuntimeError(f"Expected {expected} matches for {old[:72]!r}, found {count}")
    s=s.replace(old,new,expected)

swap("const apiBase=String.fromEnvironment('API_BASE_URL',defaultValue:'http://localhost:8080');",
"""const apiBase=String.fromEnvironment('API_BASE_URL',defaultValue:'http://localhost:8080');
// Market quotes/charts use verge-market-api; student paper orders/progress use verge-api.
// This is a public endpoint identifier, NOT a secret.
const tradeApiBase=String.fromEnvironment('TRADE_API_BASE_URL',defaultValue:'https://fcypamejorxoxvtcqubs.supabase.co/functions/v1/verge-api');""")
swap("dbConnected=data['database']=='configured';","dbConnected=sbUrl.isNotEmpty&&sbKey.isNotEmpty;")
swap("Timer? demoTimer;","Timer? demoTimer;Timer? marketPollTimer;")
swap("demoTimer?.cancel();super.dispose();","demoTimer?.cancel();marketPollTimer?.cancel();super.dispose();")
swap("_connect();","if(sbUrl.isNotEmpty&&sbKey.isNotEmpty){_startMarketPolling();}else{_connect();}")
swap("}catch(_){_startDemo();}\n    if(mounted)setState(()=>loading=false)","}catch(_){if(sbUrl.isNotEmpty&&sbKey.isNotEmpty){_startMarketPolling();}else{_startDemo();}}\n    if(mounted)setState(()=>loading=false)")
hook="""  Future<void> _refreshMarketQuotes() async {
    try {
      final response=await http.get(Uri.parse('$apiBase/v1/quotes')).timeout(const Duration(seconds:10));
      if(response.statusCode!=200) return;
      final body=jsonDecode(response.body);
      if(body is! Map || body['quotes'] is! List) return;
      for(final item in (body['quotes'] as List)) {
        if(item is Map) _tick(Map<String,dynamic>.from(item));
      }
    } catch (_) {
      // Keep the last known quote; never fabricate new prices during a network outage.
    }
  }
  void _startMarketPolling() {
    marketPollTimer?.cancel();
    demoTimer?.cancel();
    demoTimer=null;
    _refreshMarketQuotes();
    marketPollTimer=Timer.periodic(const Duration(seconds:12),(_)=>_refreshMarketQuotes());
  }
"""
swap("  void _setupRealtime(){",hook+"  void _setupRealtime(){")
# Use the authenticated, transactional backend for student-specific operations.
for route in ("portfolio","orders","progress"):
    swap("'$apiBase/v1/"+route+"'","'$tradeApiBase/v1/"+route+"'")
# The starting-price comparisons are illustrative, not exchange-day performance.
swap("* Relative to demo opening references, not market daily change.","* Illustrative reference comparison, not official market daily change.")
swap("Educational use only. Fees and slippage are simplified; demo prices are synthetic.","Educational paper trading only. Quotes marked Twelve Data are real provider data; fills and fees are simulated.")
p.write_text(s,encoding="utf-8")
print("VERGE six real quotes: market polling, secure paper trading, explicit source labels; source length:",len(s))
