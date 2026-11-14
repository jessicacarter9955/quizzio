/* Compact Paper Trading web, real Supabase lessons & server-graded quizzes. */
(function(){
'use strict';
const DEMOS=[
 {email:'demo1@example.com',password:'demo1234',name:'Student 1'},
 {email:'demo2@example.com',password:'demo1234',name:'Student 2'}
];
const SYMBOLS={AAPL:['apple','A'],MSFT:['microsoft','M'],NVDA:['nvidia','N'],TSLA:['tesla','T'],'BTC/USD':['bitcoin','₿'],'EUR/USD':[null,'€']};
const materials=new Map(),activities=new Map();
window.paperUIStockLogo=logo;
let active=null,answerChoices=[],step=0,lastResult=null,quizBusy=false,authMode='login',authReady=false;
const safe=s=>escapeHtml(s??'');
function logo(symbol){
 const [iconName,fallback]=SYMBOLS[symbol]||[null,'•'];
 if(!iconName)return '<span class="pt-logo"><em>'+fallback+'</em></span>';
 return '<span class="pt-logo"><img src="https://cdn.jsdelivr.net/npm/simple-icons@v15/icons/'+iconName+'.svg" alt="" loading="lazy" onerror="this.style.display=\'none\';this.nextElementSibling.style.display=\'block\'"/><em style="display:none">'+fallback+'</em></span>';
}
const api=async(path,method='GET',payload)=>{
 if(!state.db||!state.token)throw Error('Sign in first');
 const response=await fetch(state.supabaseUrl+'/rest/v1/'+path,{method,headers:{
  apikey:state.supabaseKey,Authorization:'Bearer '+state.token,'Content-Type':'application/json'
 },body:payload===undefined?undefined:JSON.stringify(payload)});
 let result=null;try{result=await response.json()}catch{}
 if(!response.ok)throw Error(result?.message||result?.hint||result?.error||'Request failed ('+response.status+')');
 return result;
};
const authGate=()=>document.getElementById('pt-auth-gate');
function courseData(id){return materials.get(Number(id))}
function progress(id){
 const m=courseData(id),a=activities.get(Number(id)),done=state.portfolio.done.includes(Number(id));
 if(done)return 100;
 if(!m)return 0;
 const steps=m.slides.length+1;
 return Math.max(0,Math.min(90,Math.round(Number(a?.slide_index||0)/steps*100)));
}
window.paperUILoadLearning=async()=>{
 if(!state.token||!state.db){materials.clear();activities.clear();return}
 const [lessons,progressRows]=await Promise.all([
  api('pt_lesson_material?select=lesson_id,slides,questions&order=lesson_id.asc'),
  api('pt_lesson_activity?select=lesson_id,slide_index,best_score,quiz_attempts')
 ]);
 materials.clear();activities.clear();
 for(const l of lessons||[])materials.set(Number(l.lesson_id),l);
 for(const row of progressRows||[])activities.set(Number(row.lesson_id),row);
};
function stats(){
 const done=state.portfolio.done.length,total=state.lessonData.length;
 return '<section class="stats-grid">'+
  stat('Equity',money(equity()),'','◇')+
  stat('Cash',money(state.portfolio.cash),'','↗')+
  stat('Open P&L',money(pnl()),'','⌁')+
  stat('Lessons',done+' / '+total,'','✓')+
  '</section>';
}
function marketRows(){
 return assets.map(([symbol,name])=>{
  const q=state.prices[symbol],updated=q?.quoted_at?new Date(q.quoted_at).toLocaleString('en-GB',{day:'2-digit',month:'short',hour:'2-digit',minute:'2-digit',timeZoneName:'short'}):'—';
  return '<tr onclick="selectSymbol(\''+symbol+'\',true)"><td class="symbol"><div class="pt-ticker">'+logo(symbol)+
   '<div><b>'+safe(symDisplay(symbol))+'</b><small>'+safe(name)+'</small></div></div></td>'+
   '<td>'+fmtPrice(priceOf(symbol))+'</td><td>'+updated+'</td>'+
   '<td><button class="pt-fav" type="button" aria-label="Toggle '+safe(symbol)+' favorite" onclick="event.stopPropagation();window.toggleWatchFavorite(\''+symbol+'\')">'+
   (state.watchlist?.includes(symbol)?'★':'☆')+'</button></td></tr>';
 }).join('');
}
window.paperUIHomePage=()=>{
 const count=state.portfolio.done.length,total=state.lessonData.length;
 const ongoing=state.lessonData.find(l=>!state.portfolio.done.includes(l.id)&&(Number(activities.get(Number(l.id))?.slide_index||0)>0||Number(activities.get(Number(l.id))?.quiz_attempts||0)>0));
 const next=ongoing||state.lessonData.find(l=>!state.portfolio.done.includes(l.id))||state.lessonData[0];
 const activity=next?activities.get(Number(next.id)):null,material=next?materials.get(Number(next.id)):null;
 const isQuiz=!!(activity&&material&&Number(activity.slide_index)>=material.slides.length),nextType=isQuiz?'Quiz':'Lesson';
 return '<section class="pt-modern-home"><section class="page-intro"><h1>Home</h1></section>'+stats()+
 '<section class="pt-home-grid"><div class="card pt-home-charts chart-panel">'+
 '<div class="pt-card-head"><h2>Chart</h2><div class="timeframes">'+intervalButtons()+'</div></div>'+
 selectedAsset()+'<div class="chart" id="trade-chart"></div><div class="chart-legend"><span>Price history</span></div></div>'+
 '<aside class="card pt-home-side"><div class="pt-card-head"><h2>Learning</h2><button onclick="navigate(\'learn\')">View all</button></div>'+
 '<div class="pt-lesson-progress"><b>'+count+' / '+total+' complete</b><span>'+Math.round(count/Math.max(total,1)*100)+'%</span></div>'+
 '<div class="pt-progress-track"><span style="width:'+Math.round(count/Math.max(total,1)*100)+'%"></span></div>'+
 (next?'<div class="pt-next-lesson-meta"><span>'+(ongoing?'Continue':'Start')+'</span><small>'+nextType+'</small></div><button class="pt-start-button" onclick="showLesson('+Number(next.id)+')">'+safe(next.title)+' <span style="float:right">→</span></button>':'')+
 '<button class="pt-start-button" onclick="navigate(\'portfolio\')">View portfolio <span style="float:right">→</span></button></aside></section>'+
 '<section class="card pt-home-market" style="margin-top:15px"><div class="pt-card-head"><h2>Markets</h2><button onclick="navigate(\'trade\')">Trade →</button></div>'+
 '<div style="overflow-x:auto"><table class="market-table"><thead><tr><th>Asset</th><th>Price</th><th>Updated</th><th></th></tr></thead>'+
 '<tbody>'+marketRows()+'</tbody></table></div></section></section>';
};
window.paperUILearnPage=()=>{
 const total=state.lessonData.length,completed=state.portfolio.done.length;
 return '<div class="pt-course-summary"><h1>Learn</h1><small>'+completed+' of '+total+' lessons completed</small></div>'+
 '<div class="pt-progress-track"><span style="width:'+Math.round(completed/Math.max(total,1)*100)+'%"></span></div>'+
 '<section class="pt-course-grid">'+state.lessonData.map((l,i)=>{
  const value=progress(l.id),completed=state.portfolio.done.includes(l.id),activity=activities.get(Number(l.id));
  const quizDetail=activity?.quiz_attempts ? ('Best '+Number(activity.best_score||0)+'% · '+Number(activity.quiz_attempts)+' tries') : 'Quick quiz';
  return '<button class="pt-course-tile '+(completed?'completed':'')+'" onclick="showLesson('+Number(l.id)+')">'+'<span class="pt-course-type">'+(completed?'Completed':value>0||activity?.quiz_attempts?'Continue':'Start')+' · '+(activity&&materials.get(Number(l.id))&&Number(activity.slide_index)>=materials.get(Number(l.id)).slides.length?'Quiz':'Lesson')+'</span>'+
    '<div class="pt-course-number">'+String(i+1).padStart(2,'0')+' / '+String(total).padStart(2,'0')+'</div>'+
    '<div class="pt-course-title">'+safe(l.title)+'</div>'+
    '<div class="pt-course-meta"><span>'+Number(l.duration_minutes||10)+' min · '+quizDetail+'</span><span>'+(completed?'✓ Done':value+'%')+'</span></div>'+
    '<div class="pt-course-progress"><span style="width:'+value+'%"></span></div></button>';
 }).join('')+'</section>';
};
function exitLesson(){
 document.getElementById('pt-learning-shell')?.remove();active=null;lastResult=null;
 if(state.page==='learn'||state.page==='home')window.render();
}
window.paperUIExitLesson=exitLesson;
function panelHead(count,total){
 return '<div class="pt-learning-top"><button class="pt-learning-close" type="button" onclick="paperUIExitLesson()" aria-label="Close lesson">✕</button>'+
 '<div class="pt-learning-stepper"><span style="width:'+Math.round((count+1)/total*100)+'%"></span></div>'+
 '<div class="pt-learning-counter">'+Math.min(count+1,total)+' / '+total+'</div></div>';
}
function drawLesson(){
 if(!active)return;
 const m=courseData(active),l=state.lessonData.find(x=>Number(x.id)===active);
 if(!m||!l)return;
 const total=m.slides.length+m.questions.length;
 let body='',foot='';
 if(lastResult){
  const r=lastResult;
  body='<div class="pt-quiz-results"><div class="pt-learning-eyebrow">QUIZ RESULT</div><h2>'+(r.passed?'Lesson complete':'Try again')+'</h2>'+
       '<strong class="'+(r.passed?'positive':'')+'">'+r.score+'%</strong><p>'+r.correct+' of '+r.total+' correct</p></div>'+
       (r.review||[]).map((x,i)=>'<div class="pt-review"><b>'+(x.correct?'✓':'✕')+' Question '+(i+1)+'</b><p>'+safe(x.explanation)+'</p></div>').join('');
  foot='<button class="secondary-button" onclick="paperUIExitLesson()">Close</button>'+
       '<button class="primary-button" onclick="'+(r.passed?'paperUIExitLesson()':'paperUIRetryQuiz()')+'">'+(r.passed?'Finish':'Retry quiz')+'</button>';
 }else if(step<m.slides.length){
  const slide=m.slides[step];
  body='<div class="pt-learning-eyebrow">'+safe(slide.tag||'LESSON')+'</div><h2>'+safe(slide.title)+'</h2>'+
    '<p>'+safe(slide.body)+'</p><div class="pt-learning-points">'+(slide.points||[]).map(x=>'<div>'+safe(x)+'</div>').join('')+'</div>'+
    '<div class="pt-learning-example">'+safe(slide.example||'')+'</div>';
  foot='<button class="secondary-button" '+(step===0?'disabled':'')+' onclick="paperUIBack()">Back</button>'+
       '<button class="primary-button" onclick="paperUINext()">'+(step===m.slides.length-1?'Quick quiz':'Continue')+' →</button>';
 }else{
  const qi=step-m.slides.length,q=m.questions[qi];
  body='<div class="pt-learning-eyebrow">QUICK QUIZ · '+(qi+1)+' OF '+m.questions.length+'</div>'+
    '<h2>'+safe(q.q)+'</h2><div class="pt-answers">'+q.options.map((value,i)=>
    '<button class="pt-answer '+(answerChoices[qi]===i?'selected':'')+'" onclick="paperUIChooseAnswer('+i+')">'+
    '<span>'+String.fromCharCode(65+i)+'</span>'+safe(value)+'</button>').join('')+'</div>';
  foot='<button class="secondary-button" onclick="paperUIBack()">Back</button>'+
       '<button class="primary-button" '+(quizBusy||answerChoices[qi]==null?'disabled':'')+
       ' onclick="paperUINext()">'+(qi===m.questions.length-1?'Submit quiz':'Next question')+'</button>';
 }
 let node=document.getElementById('pt-learning-shell');
 if(!node){node=document.createElement('section');node.id='pt-learning-shell';node.className='pt-learning-shell';document.body.appendChild(node)}
 node.innerHTML=panelHead(lastResult?total-1:step,total)+
  '<main class="pt-learning-screen">'+body+'</main><footer class="pt-learning-bottom">'+foot+'</footer>';
 node.querySelector('.pt-learning-screen')?.scrollTo(0,0);
}
window.paperUIShowLesson=async id=>{
 if(!state.token)return window.paperUILoginModal();
 if(!courseData(id))try{await window.paperUILoadLearning()}catch(e){toast('Lessons unavailable: '+e.message);return}
 const m=courseData(id);if(!m||!Array.isArray(m.slides)||!m.slides.length)return toast('Lesson content unavailable');
 active=Number(id);step=state.portfolio.done.includes(active)?0:Math.min(Number(activities.get(active)?.slide_index||0),m.slides.length);
 answerChoices=Array(m.questions.length).fill(null);lastResult=null;drawLesson();
};
window.paperUIBack=()=>{if(step>0){step--;drawLesson()}};
window.paperUIChooseAnswer=i=>{if(!active||lastResult)return;answerChoices[step-courseData(active).slides.length]=i;drawLesson()};
window.paperUIRetryQuiz=()=>{if(!active)return;step=courseData(active).slides.length;answerChoices=Array(courseData(active).questions.length).fill(null);lastResult=null;drawLesson()};
window.paperUINext=async()=>{
 if(active==null||quizBusy)return;
 const m=courseData(active),max=m.slides.length+m.questions.length;
 if(step<m.slides.length){
  try{const row=await api('rpc/pt_save_slide','POST',{p_lesson_id:active,p_slide_index:Math.min(step+1,m.slides.length)});
      activities.set(active,{...(activities.get(active)||{}),slide_index:row.slide_index});
  }catch(e){toast('Progress not saved: '+e.message);return}
  step++;drawLesson();return;
 }
 if(answerChoices[step-m.slides.length]==null)return;
 if(step<max-1){step++;drawLesson();return}
 quizBusy=true;drawLesson();
 try{
  const result=await api('rpc/pt_grade_quiz','POST',{p_lesson_id:active,p_answers:answerChoices});
  lastResult=result;
  await loadPortfolio();
  if(result.passed){state.portfolio.done=Array.from(new Set([...state.portfolio.done,active]));toast('Lesson completed')}
 }catch(e){toast('Quiz not saved: '+e.message)}
 finally{quizBusy=false;drawLesson()}
};
function demoButtons(){
 return '<div class="pt-auth-demo">'+DEMOS.map((d,i)=>
 '<button type="button" class="'+(document.getElementById('email')?.value===d.email?'active':'')+'" onclick="paperUIUseDemo('+i+')">'+d.name+'</button>').join('')+'</div>';
}
window.paperUIUseDemo=i=>{
 const d=DEMOS[i],email=document.getElementById('email'),pw=document.getElementById('pw');
 if(email)email.value=d.email;if(pw)pw.value=d.password;
 document.querySelectorAll('.pt-auth-demo button').forEach((b,k)=>b.classList.toggle('active',k===i));
};
function authFields(){
 const isLogin=authMode==='login',reset=authMode==='reset';
 const preset=DEMOS[0];
 return '<div class="pt-auth-card"><div class="pt-auth-symbol"><img src="/paper-trading/paper-trading-icon.svg" alt=""/></div>'+
 '<h1>'+(isLogin?'Student sign in':reset?'Reset password':'Create account')+'</h1>'+
 '<p>'+(isLogin?'':reset?'Enter your email to request a recovery link.':'Create your account.')+'</p>'+
 '<form onsubmit="paperUIAuthSubmit(event)"><label for="email">Email</label><input id="email" name="email" type="email" autocomplete="email" required value="'+
   (isLogin?preset.email:'')+'" placeholder="you@example.com"/>'+
 (!reset?'<label for="pw">Password</label><input id="pw" name="pw" type="password" autocomplete="'+(isLogin?'current-password':'new-password')+
    '" required minlength="8" value="'+(isLogin?preset.password:'')+'" placeholder="8+ characters"/>':'')+
 '<button type="submit" class="primary-button">'+(isLogin?'Sign in':reset?'Send reset link':'Sign up')+'</button>'+
 '</form><div class="pt-auth-message" id="pt-auth-message" role="status"></div>'+
 '<div class="pt-auth-links">'+(isLogin?'<button type="button" onclick="paperUIAuthMode(\'signup\')">New student? Sign up</button><button type="button" onclick="paperUIAuthMode(\'reset\')">Forgot password?</button>':
  '<button type="button" onclick="paperUIAuthMode(\'login\')">Back to sign in</button>')+'</div>'+
 (isLogin?demoButtons():'')+'</div>';
}
function renderAuth(){
 if(state.token){authGate()?.remove();return}
 let node=authGate();
 if(!node){node=document.createElement('section');node.id='pt-auth-gate';node.className='pt-auth-gate';document.body.appendChild(node)}
 node.innerHTML=authFields();
 authReady=true;
}
window.paperUIAuthMode=mode=>{authMode=mode;renderAuth()};
window.paperUILoginModal=()=>{authMode='login';renderAuth()};
window.paperUIAuthSubmit=async ev=>{
 ev?.preventDefault();
 const status=document.getElementById('pt-auth-message'),button=document.querySelector('#pt-auth-gate button[type=submit]');
 if(!state.db){if(status)status.textContent='Connecting to authentication…';return}
 if(button)button.disabled=true;
 try{
  if(authMode==='reset'){
   const email=document.getElementById('email')?.value?.trim();
   if(!email)throw Error('Enter an email');
   const r=await fetch(state.supabaseUrl+'/auth/v1/recover?redirect_to='+encodeURIComponent('https://quizlab-responsive-web.onrender.com/paper-trading/'),
    {method:'POST',headers:{apikey:state.supabaseKey,'Content-Type':'application/json'},body:JSON.stringify({email})});
   if(!r.ok){const d=await r.json().catch(()=>({}));throw Error(d.msg||d.error_description||'Recovery unavailable')}
   if(status)status.textContent='If this address has an inbox, check it for your recovery link.';
   return;
  }
  await window.paperTradingLogin(ev,authMode==='signup');
  if(state.token){authGate()?.remove();window.render()}
  else if(authMode==='signup'&&status)status.textContent='Check your email to confirm registration.';
 }catch(e){if(status)status.textContent=e.message||'Sign in failed'}
 finally{if(button)button.disabled=false}
};
window.paperUIAuthError=message=>{const e=document.getElementById('pt-auth-message');if(e)e.textContent=message};
window.paperUIBooted=()=>{if(!state.token)renderAuth();else authGate()?.remove()};
window.paperUIAfterSignedIn=()=>{authGate()?.remove();authReady=false};
window.paperUIAfterSignOut=()=>{authMode='login';renderAuth()};
window.paperUIAfterRender=()=>{
 const avatar=document.getElementById('account-avatar');
 if(avatar){
  const val=state.studentAlias||state.account?.email||'Student';
  avatar.textContent=val.split(/[\s.@]+/).map(v=>v[0]||'').slice(0,2).join('').toUpperCase()||'ST';
  avatar.title=state.account?.email||'Account';
 }
};
document.addEventListener('keydown',e=>{if(e.key==='Escape'&&active!=null)exitLesson()});
if(!state.token)renderAuth();
})();