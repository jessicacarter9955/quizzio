/* Paper Trading: student account, personal watchlist, real classrooms. */
(function(){
'use strict';
const LANDING='https://quizlab-responsive-web.onrender.com/paper-trading/';
const ACC='pt_auth_refresh';
state.watchlist=[];state.watchOnly=false;state.classrooms=[];state.studentAlias='';state.studentId=null;state.extraStatus='';
const authBase=()=>state.supabaseUrl+'/auth/v1';
const headers=()=>({'apikey':state.supabaseKey,'Authorization':'Bearer '+state.token,'Content-Type':'application/json'});
const error=async r=>{const d=await r.json().catch(()=>({}));return d.message||d.msg||d.error_description||d.error||'HTTP '+r.status};
const toast=s=>window.toast(String(s));
async function api(path,options={}){
 if(!state.token)throw Error('Sign in required');
 const r=await fetch(state.supabaseUrl+path,{...options,headers:{...headers(),...(options.headers||{})}});
 if(!r.ok)throw Error(await error(r));
 if(r.status===204)return null;
 const t=await r.text();return t?JSON.parse(t):null;
}
const rpc=(name,args={})=>api('/rest/v1/rpc/'+name,{method:'POST',body:JSON.stringify(args)});
async function loadExtras(){
 if(!state.token||!state.db)return;
 const responses=await Promise.allSettled([
  api('/rest/v1/pt_watchlist?select=symbol&order=created_at.asc'),
  api('/rest/v1/pt_student_profiles?select=user_id,display_name&limit=1'),
  rpc('pt_classroom_dashboard')
 ]);
 if(responses[0].status==='fulfilled')state.watchlist=responses[0].value.map(x=>x.symbol);
 if(responses[1].status==='fulfilled'){const p=responses[1].value[0];state.studentAlias=p?.display_name||'';state.studentId=p?.user_id||null}
 if(responses[2].status==='fulfilled')state.classrooms=Array.isArray(responses[2].value)?responses[2].value:[];
 state.extraStatus=responses.filter(x=>x.status==='rejected').map(x=>String(x.reason)).join(' · ');
}
window.paperTradingLoadExtras=loadExtras;
async function favorite(symbol){
 if(!state.token)return window.loginModal();
 if(!['AAPL','MSFT','NVDA','TSLA','BTC/USD','EUR/USD'].includes(symbol))return;
 try{
  if(state.watchlist.includes(symbol))await api('/rest/v1/pt_watchlist?symbol=eq.'+encodeURIComponent(symbol),{method:'DELETE'});
  else {if(!state.studentId)throw Error('Student profile unavailable');await api('/rest/v1/pt_watchlist',{method:'POST',headers:{Prefer:'return=minimal'},body:JSON.stringify({symbol,user_id:state.studentId})});}
  await loadExtras();window.render();toast('Watchlist saved to Supabase');
 }catch(e){toast('Watchlist not saved: '+e.message)}
}
window.toggleWatchFavorite=favorite;
function button(title,cb,style='secondary-button'){const b=document.createElement('button');b.type='button';b.textContent=title;b.className=style;b.addEventListener('click',cb);return b}
function input(label,placeholder='',type='text'){
 const box=document.createElement('label');box.className='pt-label';box.textContent=label;
 const control=document.createElement('input');control.type=type;control.className='form-input';control.placeholder=placeholder;control.autocomplete='off';box.append(control);return{box,control};
}
function card(title){const d=document.createElement('div');d.className='card pt-extension';const h=document.createElement('h2');h.textContent=title;d.append(h);return d}
function paintWatch(){
 if(state.page==='home'){
  const table=document.querySelector('.market-table');if(!table)return;
  const heading=table.closest('.table-card')?.querySelector('h2');
  if(heading){
   heading.firstChild.textContent=state.token?'Your watchlist ':'Market overview ';
   if(state.token)heading.append(button(state.watchOnly?'All markets':'Favorites only',()=>{state.watchOnly=!state.watchOnly;window.render()},'pt-inline-control'));
  }
  for(const tr of table.querySelectorAll('tbody tr')){
   const t=tr.querySelector('td.symbol')?.childNodes[0]?.textContent?.trim();const symbol=t==='BTC'?'BTC/USD':t==='EUR'?'EUR/USD':t;
   if(!symbol)continue;
   const td=document.createElement('td');td.className='pt-fav-cell';
   const b=button(state.watchlist.includes(symbol)?'★':'☆',e=>{e.stopPropagation();favorite(symbol)},'pt-fav');td.append(b);
   tr.insertBefore(td,tr.firstChild);tr.hidden=!!(state.token&&state.watchOnly&&!state.watchlist.includes(symbol));
  }
  const tr=table.querySelector('thead tr');if(tr){const th=document.createElement('th');th.textContent='Save';tr.insertBefore(th,tr.firstChild)}
  if(state.token&&state.watchOnly&&state.watchlist.length===0){const p=document.createElement('p');p.textContent='No favorites yet. Show all markets and tap ☆ to add one.';table.after(p)}
 }
 if(state.page==='trade'){
  const tabs=document.querySelector('.market-tabs');if(tabs)tabs.after(button(state.watchlist.includes(state.symbol)?'★ Saved':'☆ Save to watchlist',()=>favorite(state.symbol),'pt-save-market'))
 }
}
async function reload(){await loadExtras();window.render()}
function classForm(label,buttonText,action){
 const form=document.createElement('form');form.className='pt-flex-form';
 const f=input(label);f.control.required=true;f.control.minLength=3;form.append(f.box);
 const sub=document.createElement('button');sub.className='primary-button';sub.type='submit';sub.textContent=buttonText;form.append(sub);
 form.addEventListener('submit',async e=>{e.preventDefault();sub.disabled=true;try{await action(f.control.value.trim());f.control.value='';await reload()}catch(x){toast(x.message)}finally{sub.disabled=false}});
 return form;
}
function paintClasses(){
 const root=document.querySelector('#pt-classrooms');if(!root)return;root.replaceChildren();
 if(!state.token){const c=card('Your classroom rankings');const p=document.createElement('p');p.textContent='Sign in to create a classroom, join a teacher and see real results.';c.append(p,button('Student sign in',()=>window.loginModal(),'primary-button'));root.append(c);return}
 const manage=card('Classroom management');
 manage.append(classForm('Classroom name','Create classroom',p_title=>rpc('pt_classroom_create',{p_title})));
 manage.append(classForm('Invite code','Join classroom',p_code=>rpc('pt_classroom_join',{p_code})));
 root.append(manage);
 if(state.extraStatus){const e=document.createElement('p');e.className='pt-warning';e.textContent='Error loading student data: '+state.extraStatus;root.append(e)}
 if(!state.classrooms.length){root.append(card('No classes yet'));return}
 for(const c of state.classrooms){
  const box=card(c.title||'Classroom');const summary=document.createElement('p');summary.textContent=(c.member_count||0)+' enrolled · '+(c.teacher?'Teacher':'Student');box.append(summary);
  if(c.teacher&&c.invite_code){const div=document.createElement('div');div.className='pt-invite';const code=document.createElement('code');code.textContent=c.invite_code;div.append(code,button('Copy invite',async()=>{try{await navigator.clipboard.writeText(c.invite_code);toast('Copied')}catch{toast('Code: '+c.invite_code)}}));box.append(div)}
  const scroll=document.createElement('div');scroll.className='pt-scroll';const table=document.createElement('table');table.className='record-table pt-ranking';
  const head=document.createElement('thead');head.innerHTML='<tr><th>#</th><th>Student</th><th>Return</th><th>Virtual P&amp;L</th><th>Lessons</th></tr>';table.append(head);
  const body=document.createElement('tbody');
  for(const rank of c.leaderboard||[]){const tr=document.createElement('tr');const arr=[rank.rank,rank.name+(rank.is_me?' (you)':''),Number(rank.return_pct||0).toFixed(2)+'%',Number(rank.virtual_pnl||0).toLocaleString('en-US',{style:'currency',currency:'USD'}),rank.lessons_completed];
   for(const value of arr){const td=document.createElement('td');td.textContent=String(value);tr.append(td)}
   if(rank.is_me)tr.className='pt-own-rank';body.append(tr)
  }
  table.append(body);scroll.append(table);box.append(scroll);
  const actions=document.createElement('div');actions.className='pt-actions';
  if(c.teacher){
   actions.append(button('Rename',async()=>{const n=prompt('New classroom name',c.title);if(!n)return;try{await rpc('pt_classroom_rename',{p_class_id:c.id,p_title:n});await reload()}catch(e){toast(e.message)}}));
   actions.append(button('Delete',async()=>{if(!confirm('Delete classroom and its memberships?'))return;try{await rpc('pt_classroom_delete',{p_class_id:c.id});await reload()}catch(e){toast(e.message)}}));
  }else actions.append(button('Leave',async()=>{if(!confirm('Leave this classroom?'))return;try{await rpc('pt_classroom_leave',{p_class_id:c.id});await reload()}catch(e){toast(e.message)}}));
  box.append(actions);root.append(box);
 }
}
window.paperTradingLeaderPage=()=>intro('STUDENT PERFORMANCE','Classroom leaderboard','Real classroom members, virtual returns and completed lessons from Supabase.')+'<section id="pt-classrooms"></section>';
function paintProfile(){
 if(state.page!=='profile'||!state.token)return;
 const root=document.querySelector('#content');if(!root)return;
 const c=card('Student profile');const nickname=input('Display name (visible to your class)');nickname.control.value=state.studentAlias;c.append(nickname.box);
 c.append(button('Save display name',async()=>{const n=nickname.control.value.trim();if(n.length<2||n.length>36)return toast('Name must contain 2–36 characters');try{await api('/rest/v1/pt_student_profiles?user_id=eq.'+encodeURIComponent(state.studentId),{method:'PATCH',body:JSON.stringify({display_name:n})});await reload();toast('Profile saved')}catch(e){toast(e.message)}},'primary-button'));
 const sec=card('Account security');const pass=input('New password','8 or more characters','password');pass.control.minLength=8;pass.control.autocomplete='new-password';sec.append(pass.box);
 sec.append(button('Update password',async()=>{if(pass.control.value.length<8)return toast('Enter at least 8 characters');try{const r=await fetch(authBase()+'/user',{method:'PUT',headers:headers(),body:JSON.stringify({password:pass.control.value})});if(!r.ok)throw Error(await error(r));pass.control.value='';toast('Password changed in Supabase')}catch(e){toast(e.message)}},'primary-button'));
 root.append(c,sec);
}
window.paperTradingAfterRender=()=>{paintWatch();paintClasses();paintProfile()};
window.paperTradingAfterLoginModal=()=>{const modal=document.querySelector('#overlay .modal');if(modal&&!modal.querySelector('.pt-recovery')){const recover=button('Forgot password?',()=>window.requestPasswordReset(),'text-link pt-recovery');recover.style.marginTop='12px';modal.append(recover)}};
window.requestPasswordReset=async()=>{
 const email=document.querySelector('#email')?.value?.trim()||prompt('Email address for password recovery:');if(!email)return;
 try{const url=authBase()+'/recover?redirect_to='+encodeURIComponent(LANDING);const r=await fetch(url,{method:'POST',headers:{apikey:state.supabaseKey,'Content-Type':'application/json'},body:JSON.stringify({email})});if(!r.ok)throw Error(await error(r));toast('If an account exists, a recovery email was requested.')}catch(e){toast('Reset failed: '+e.message)}
};
function setSession(d){state.token=d.access_token;state.account=d.user||null;safeSession.setItem('verge_token',d.access_token);if(d.refresh_token)safeSession.setItem(ACC,d.refresh_token);if(d.expires_at)safeSession.setItem('pt_auth_expires',String(d.expires_at))}
window.paperTradingLogin=async function(ev,signup=false){
 ev?.preventDefault();const email=document.querySelector('#email')?.value?.trim(),password=document.querySelector('#pw')?.value;
 if(!email||!password)return toast('Email and password required');const btn=document.querySelector('#overlay button[type=submit]');if(btn)btn.disabled=true;
 try{
  const endpoint=signup?'/signup?redirect_to='+encodeURIComponent(LANDING):'/token?grant_type=password';
  const r=await fetch(authBase()+endpoint,{method:'POST',headers:{apikey:state.supabaseKey,'Content-Type':'application/json'},body:JSON.stringify({email,password})});
  const d=await r.json().catch(()=>({}));if(!r.ok)throw Error(d.msg||d.error_description||d.error||'Authentication failed');
  if(d.access_token){setSession(d);await loadPortfolio();window.closeModal();window.render();toast('Signed in — your Supabase account is connected')}
  else if(signup){window.closeModal();toast('Confirm your email to activate your account. Supabase must allow the app redirect URL.')}
  else throw Error('No session was returned');
 }catch(e){toast(e.message)}finally{if(btn)btn.disabled=false}
};
window.paperTradingLogout=async function(){
 try{if(state.token){const r=await fetch(authBase()+'/logout',{method:'POST',headers:headers()});if(!r.ok&&r.status!==401)toast('Remote sign-out failed; local session cleared')}}catch{}
 state.token='';state.account=null;state.portfolio={cash:0,holdings:{},orders:[],done:[]};state.watchlist=[];state.classrooms=[];state.studentAlias='';state.studentId=null;
 for(const key of ['verge_token',ACC,'pt_auth_expires'])safeSession.removeItem(key);
 window.render();toast('Signed out');
};
window.paperTradingRestoreSession=async()=>{
 const refresh=safeSession.getItem(ACC),expiry=Number(safeSession.getItem('pt_auth_expires')||0);
 if(!refresh||!state.db||!state.supabaseKey)return;
 if(state.token&&expiry>Date.now()/1000+120)return;
 try{
   const r=await fetch(authBase()+'/token?grant_type=refresh_token',{method:'POST',headers:{apikey:state.supabaseKey,'Content-Type':'application/json'},body:JSON.stringify({refresh_token:refresh})});
   if(!r.ok)throw Error(await error(r));
   const d=await r.json();if(!d.access_token)throw Error('Missing refreshed session');
   setSession(d);
 }catch(e){state.token='';state.account=null;for(const key of ['verge_token',ACC,'pt_auth_expires'])safeSession.removeItem(key);console.warn('Supabase session refresh was not possible:',e.message)}
};
(async()=>{try{if(state.token&&state.db)await loadExtras();window.render()}catch(e){console.warn('Student features:',e)}})();
})();