from pathlib import Path
p=Path('flutter_app/lib/main.dart')
s=p.read_text(encoding='utf-8')
def replace(a,b):
    global s
    n=s.count(a)
    if n!=1:raise RuntimeError(f"Expected one source occurrence, got {n}: {a[:90]}")
    s=s.replace(a,b,1)
def splice(a,b,out):
    global s
    i=s.find(a);j=s.find(b,i+len(a))
    if i<0 or j<0:raise RuntimeError("Missing Flutter source boundary: "+a)
    s=s[:i]+out+s[j:]

replace("title:'VERGE · Trading Academy'","title:'Paper Trading'")
replace("runApp(const VergeApp());","runApp(const VergeApp());")
# No built-in lessons, demo portfolio or synthetic price engine.
splice('const localLessons=[','\nclass AcademyShell', '\n')
replace("String symbol='AAPL',interval='1min',side='buy',feedMode='demo';double qty=2,cash=100000;",
        "String symbol='AAPL',interval='1min',side='buy',feedMode='unavailable';double qty=2,cash=0;")
replace("List<Lesson> lessons=localLessons;","List<Lesson> lessons=[];")
# No default local portfolio or sample prices; authentic data comes from Supabase.
splice('  Future<void> _boot() async {','\n  void _setupRealtime(){',"""  Future<void> _boot() async {
    dbConnected=sbUrl.isNotEmpty&&sbKey.isNotEmpty;
    try{
      final responses=await Future.wait([
        http.get(Uri.parse('$apiBase/v1/quotes')).timeout(const Duration(seconds:12)),
        http.get(Uri.parse('$tradeApiBase/v1/lessons')).timeout(const Duration(seconds:12))
      ]);
      if(responses[0].statusCode==200){
        final body=jsonDecode(responses[0].body);
        for(final row in (body['quotes'] as List? ?? [])){
          if(row is Map)_tick(Map<String,dynamic>.from(row));
        }
      }
      if(responses[1].statusCode==200){
        final body=jsonDecode(responses[1].body);
        final loaded=(body['lessons'] as List? ?? [])
          .map((e)=>Lesson.fromJson(Map<String,dynamic>.from(e))).toList();
        loaded.sort((a,b)=>a.id.compareTo(b.id));
        lessons=loaded;
      }
    }catch(_){_show('Some market or education data could not be loaded.');}
    if(dbConnected){
      _startMarketPolling();
      if(accessToken!=null){
        try{await _loadRealPortfolio();await _loadLessonProgress();_setupRealtime();}
        catch(_){_show('Student data unavailable.');}
      }
    }
    if(mounted)setState(()=>loading=false);
    await _loadCandles();
  }
  Future<void> _loadLessonProgress() async{
    if(accessToken==null||!dbConnected)return;
    final rows=await Supabase.instance.client.from('pt_lesson_progress').select('lesson_id');
    if(mounted)setState(()=>completed=rows.map<int>((row)=>(row['lesson_id'] as num).toInt()).toSet());
  }
""")
splice('  void _startDemo(){','\n  void _connect(){',"""  void _startDemo(){
    // Never generate quotes or synthetic market movements.
    feedMode='unavailable';
  }
""")
# local persistence must not silently override Supabase portfolios.
splice('  Future<void> _save() async {','\n  void _show(', """  Future<void> _save() async { /* Account data lives in Supabase only. */ }
""")
splice('  Future<void> _markDone(Lesson lesson) async {','\n  void _selectSymbol(', """  Future<void> _markDone(Lesson lesson) async {
    if(!dbConnected||accessToken==null){_show('Sign in to record lesson progress in Supabase.');return;}
    try{
      final r=await http.post(Uri.parse('$tradeApiBase/v1/progress'),
        headers:{'Authorization':'Bearer $accessToken','Content-Type':'application/json'},
        body:jsonEncode({'lesson_id':lesson.id})).timeout(const Duration(seconds:12));
      if(r.statusCode!=200)throw Exception('Progress was not saved');
      await _loadLessonProgress();
      if(mounted)Navigator.pop(context);
      _show('Lesson progress saved to Supabase.');
    }catch(e){_show('Could not save lesson: $e');}
  }
""")
# Remove placeholder leaderboard and local account reset.
splice('  Widget _leaderboard()=>','\n  Widget _profile()=>',"""  Widget _leaderboard()=>Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
    _intro('STUDENT COMMUNITY','Class leaderboard','Only actual classroom results from Supabase will be displayed.'),
    _card(Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      _heading('No published classroom results yet'),
      const SizedBox(height:12),
      _small('No sample students, scores or rankings. Publishing requires actual enrolled users and classroom privacy rules.')
    ]))
  ]);
""")
splice('  Widget _profile()=>','\n  Future<void> _authDialog()',"""  Widget _profile()=>Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
    _intro('STUDENT SETTINGS','Your account','Paper Trading uses your real Supabase student record.'),
    _card(Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      const CircleAvatar(radius:34,backgroundColor:stroke,child:Icon(Icons.trending_up,color:lime,size:33)),
      const SizedBox(height:19),
      _heading(accessToken==null?'Not signed in':'Connected student'),
      const SizedBox(height:18),
      _sumRow('Market feed',feedMode=='live'?'Twelve Data provider quotes':'Quotes unavailable'),
      _sumRow('Student database',dbConnected?'Supabase':'Unavailable'),
      _sumRow('Completed lessons','${completed.length} / ${lessons.length}'),
      _sumRow('Portfolio',accessToken==null?'Sign in for your virtual balance':dollar(equity)),
      const SizedBox(height:24),
      SizedBox(width:double.infinity,child:FilledButton(onPressed:_authDialog,child:Text(accessToken==null?'Sign in / Sign up':'Switch account'))),
      const SizedBox(height:12),
      if(accessToken!=null)TextButton(onPressed:()async{
        await Supabase.instance.client.auth.signOut();
        if(mounted)setState((){cash=0;positions={};orders=[];completed={};});
        _show('Signed out');
      },child:const Text('Sign out'))
    ]))
  ]);
""")
# Distinguish 1D (last market session), 1W and 1M.
replace("i=='1min'?'1M':i=='1h'?'1H':'1D'","i=='1min'?'1D':i=='1h'?'1W':'1M'")
replace("_small('TradingView Lightweight Charts™')","_small('Verified historical OHLC')")
replace("_small('Charts by TradingView · Lightweight Charts™ © TradingView, Inc. · https://www.tradingview.com/')","_small('Historical market data supplied by Twelve Data.')")
replace("const Text('VERGE.',style:TextStyle(fontSize:19,fontWeight:FontWeight.w900))","const Text('Paper Trading',style:TextStyle(fontSize:18,fontWeight:FontWeight.w900))")
replace("if(wide)const Text('TRADING ACADEMY',style:TextStyle(color:faint,fontSize:10,letterSpacing:1.2))","if(wide)const Text('STUDENT SIMULATOR',style:TextStyle(color:faint,fontSize:10,letterSpacing:1.2))")
replace("child:const Text('V',style:TextStyle(color:dark,fontWeight:FontWeight.w900))","child:const Icon(Icons.trending_up,color:Colors.white,size:20)")
# Native chart webview error message and header must not claim vendor branding.
chart=Path('flutter_app/assets/chart.html')
if chart.exists():
    data=chart.read_text(encoding='utf-8')
    data=data.replace('Chart requires an internet connection to load TradingView.','Historical chart component could not be loaded.')
    chart.write_text(data,encoding='utf-8')
# The last 1D view for US equities uses a single recorded trading session.
needle="clean.sort((a,b)=>(a['time'] as num).compareTo(b['time'] as num));"
if needle not in s:raise RuntimeError('Historical OHLC sorting marker missing')
filter_code="""clean.sort((a,b)=>(a['time'] as num).compareTo(b['time'] as num));
      final newest=clean.isNotEmpty?(clean.last['time'] as num).toInt():0;
      final newestUtc=DateTime.fromMillisecondsSinceEpoch(newest*1000,isUtc:true);
      final verified=clean.where((row){
        final t=(row['time'] as num).toInt();
        if(currentInterval=='1min' && chosen!='BTC/USD' && chosen!='EUR/USD'){
          final utc=DateTime.fromMillisecondsSinceEpoch(t*1000,isUtc:true);
          return utc.year==newestUtc.year&&utc.month==newestUtc.month&&utc.day==newestUtc.day;
        }
        final horizon=currentInterval=='1min'?86400:currentInterval=='1h'?604800:2592000;
        return t>=newest-horizon;
      }).toList();"""
s=s.replace(needle,filter_code,1)
replace("candles=clean;candleReal=clean.isNotEmpty;","candles=verified;candleReal=verified.isNotEmpty;")
# Avoid displaying a simulated starting balance to anonymous visitors.
s=s.replace("String lastPrice(String s){final n=prices[s]??0;return n<10?n.toStringAsFixed(5):dollar(n);}",
            "String lastPrice(String s){final n=prices[s]??0;if(n<=0)return '—';return n<10?n.toStringAsFixed(5):dollar(n);}")
# Fix visual labels and stale demo phrases (no fake data may be reintroduced).
s=s.replace("'● TWELVE DATA + DEMO':'● DEMO DATA'","'● TWELVE DATA FEED':'● WAITING FOR DATA'")
s=s.replace('SIMULATOR · EDUCATIONAL USE','PAPER TRADING · EDUCATION')
s=s.replace('Generated practice candles','Historical OHLC unavailable')
s=s.replace('Relative to demo opening','Comparative reference')
if 'SAMPLE STUDENTS' in s or 'const localLessons=' in s or 'Charts by TradingView' in s:
    raise RuntimeError('Legacy sample content still present in Flutter UI')
p.write_text(s,encoding='utf-8')
print('Paper Trading production-source pass complete; size',len(s))
