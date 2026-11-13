from pathlib import Path
p=Path('flutter_app/lib/main.dart')
s=p.read_text(encoding='utf-8')
def one(a,b):
 global s
 n=s.count(a)
 if n!=1:raise RuntimeError('Expected one Flutter source occurrence, got '+str(n)+': '+a[:85])
 s=s.replace(a,b,1)
one("import 'package:flutter/material.dart';","import 'package:flutter/material.dart';\nimport 'paper_student_extras.dart';")
one('  Widget _home()=>',"""  Widget _home()=>Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
    _homeOriginal(),const SizedBox(height:16),
    PaperFavorites(onSignIn:_authDialog,onSelect:(s){_selectSymbol(s);_go(1);})
  ]);
  Widget _homeOriginal()=>""")
one('  Widget _portfolio()=>',"""  Widget _portfolio()=>accessToken==null?_signedOutPrompt():_portfolioOriginal();
  Widget _portfolioOriginal()=>""")
one('  Widget _profile()=>',"""  Widget _profile()=>Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
    _profileOriginal(),const SizedBox(height:16),PaperAccountExtras(onSignIn:_authDialog)
  ]);
  Widget _profileOriginal()=>""")
begin=s.index('  Widget _leaderboard()=>');end=s.index('\n  Widget _profile()=>',begin)
s=s[:begin]+'  Widget _leaderboard()=>PaperClassrooms(onSignIn:_authDialog);\n'+s[end:]
one('  Widget _home()=>',"""  Widget _signedOutPrompt()=>_card(Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
    _heading('Sign in to open your Supabase portfolio'),const SizedBox(height:12),
    _small('Positions, funds, trades and lesson history are private to your authenticated student account.'),
    const SizedBox(height:14),FilledButton(onPressed:_authDialog,child:const Text('Student sign in'))
  ]));
  Widget _home()=>""")
start=s.index('  Widget _homeOriginal()=>');end=s.index('  Widget _trade()=>',start)
home=s[start:end].replace('_stats(),','(accessToken==null?_signedOutPrompt():_stats()),',1)
s=s[:start]+home+s[end:]
s=s.replace("_sumRow('Cash available',dollar(cash))","_sumRow('Cash available',accessToken==null?'Sign in':dollar(cash))")
s=s.replace("_sumRow('Owned units',(positions[symbol]?['qty']??0).toStringAsFixed(4))","_sumRow('Owned units',accessToken==null?'Sign in':(positions[symbol]?['qty']??0).toStringAsFixed(4))")
s=s.replace('auth.signUp(email:email.text.trim(),password:password.text)',"auth.signUp(email:email.text.trim(),password:password.text,emailRedirectTo:'https://quizlab-responsive-web.onrender.com/paper-trading/')")
target="TextButton(onPressed:()=>update(()=>signup=!signup),child:Text(signup?'Have an account? Sign in':'New student? Sign up'))"
if target in s:
 s=s.replace(target,target+",TextButton(onPressed:()async{final emailAddr=email.text.trim();if(!emailAddr.contains('@')){_show('Enter email before requesting a reset.');return;}try{await Supabase.instance.client.auth.resetPasswordForEmail(emailAddr,redirectTo:'https://quizlab-responsive-web.onrender.com/paper-trading/');_show('Check your email for recovery.');}catch(e){_show(e.toString());}},child:const Text('Forgot password?'))",1)
p.write_text(s,encoding='utf-8')
print('Paper Trading mobile native Supabase extras integrated',len(s))
