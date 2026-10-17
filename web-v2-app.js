(() => {
'use strict';
const LANGUAGE_NAMES={en:'English',es:'Español',fr:'Français',de:'Deutsch',it:'Italiano',pt:'Português',ru:'Русский',ru_it:'Russian Latin',zh:'中文',zh_it:'Pinyin',ko:'한국어',ko_it:'Korean Latin',ja:'日本語',ja_it:'Romaji'};
const KEY='quizlab.mobile.preview.v3';const DATA_KEY='quizlab.mobile.custom.v1';
const safeParse=(s,def)=>{try{return JSON.parse(s)||def}catch{return def}};
const initial={tab:'home',src:'en',dst:'es',instruction:'en',kind:'word',gameMode:'choice',quizLimit:10,showArticles:false,requireAccents:false,similarity:{},typingHistory:[],reviewMode:'automatic',showMastered:false,excluded:[],progress:{},attempts:[],selectedOnly:true,patternSort:'alphabetical',patternSortDefaultVersion:11};
const stored=safeParse(localStorage.getItem(KEY),{});const state={...initial,...stored};if(!['word','phrase'].includes(state.kind))state.kind='word';if(state.kind==='phrase'&&state.gameMode==='color')state.gameMode='choice';if(stored.patternSortDefaultVersion!==11){state.patternSort='alphabetical';state.patternSortDefaultVersion=11;}if(!['most','least','alphabetical'].includes(state.patternSort))state.patternSort='alphabetical';if(state.src===state.dst)state.dst=Object.keys(LANGUAGE_NAMES).find(k=>k!==state.src);
const ui={setupStep:1,expandedCats:new Set(),expandedSubs:new Set(),wordFilter:'',flash:null,toast:'',chosenDay:0,question:null,revealed:false,answer:-1,options:[],qIndex:0,search:'',bankFilter:'all',importStatus:'',session:null,typedHint:false,typedRevealed:false,typedEntry:'',typedSubmitted:false,patternMode:'prefix',patternSource:state.src,patternTarget:state.dst,patternKind:'word',patternFromNav:false,patternStudyBefore:null,patternFocus:'',patternSearch:'',patternCollapsed:new Set(),patternShowAll:'',patternPools:new Map()};
const terms=[...(window.QUIZLAB_DATA||[]),...safeParse(localStorage.getItem(DATA_KEY),[])];
const ids=new Set(terms.map(t=>t.id));
const langNames=LANGUAGE_NAMES;const byId=new Map(terms.map(t=>[t.id,t]));
const view=document.getElementById('view'),nav=document.getElementById('bottomNav');
const encode=s=>String(s).replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
// Display preferences never change stable IDs or the original translations.
const ARTICLES={
 es:/^(?:el|la|los|las|un|una|unos|unas)\s+/iu,
 it:/^(?:il|lo|la|i|gli|le|un|uno|una)\s+|^(?:l'|l’|un'|un’)\s*/iu,
 fr:/^(?:le|la|les|un|une|des|du)\s+|^(?:l'|l’|d'|d’)\s*/iu,
 de:/^(?:der|die|das|den|dem|des|ein|eine|einen|einem|einer|eines)\s+/iu,
 pt:/^(?:o|a|os|as|um|uma|uns|umas)\s+/iu,
 en:/^(?:the|a|an)\s+/iu
};
function shownWord(raw,lang,kind='word'){
 const value=String(raw||'');if(state.showArticles||kind==='phrase')return value;
 return value.replace(ARTICLES[lang]||/^$/u,'').trim();
}
function shown(t,lang){return shownWord(t.t[lang],lang,t.k)}
function splitGraphemes(value){return typeof Intl.Segmenter==='function'?[...new Intl.Segmenter(undefined,{granularity:'grapheme'}).segment(String(value))].map(x=>x.segment):Array.from(String(value))}
function typedLetters(value){return splitGraphemes(value).filter(x=>/[\p{L}\p{N}]/u.test(x))}
function matchingForm(value){
 let result=String(value||'').normalize('NFC').toLocaleLowerCase();
 if(!state.requireAccents)result=result.normalize('NFD').replace(/(\p{Script=Latin})\p{M}+/gu,'$1').normalize('NFC');
 return result.replace(/[\p{P}\p{S}\s]/gu,'');
}
function typingMatches(entry,t){return matchingForm(entry)===matchingForm(shown(t,state.dst))}
const dateKey=d=>{const x=new Date(d);return `${x.getFullYear()}-${String(x.getMonth()+1).padStart(2,'0')}-${String(x.getDate()).padStart(2,'0')}`};
const utcDay=d=>{const x=new Date(d);return Date.UTC(x.getFullYear(),x.getMonth(),x.getDate())/864e5};
function persist(){localStorage.setItem(KEY,JSON.stringify({...state,tab:'home'}))}
function excluded(){return new Set(state.excluded)}
function eligible(t){return Boolean(t.t[state.src]?.trim()&&t.t[state.dst]?.trim()&&state.src!==state.dst)&&((state.kind==='word'?t.k!=='phrase':t.k==='phrase'))}
function selected(t){return !state.excluded.includes(t.id)}
function key(t){return `language:${t.id}:${state.src}>${state.dst}`}
function prog(t){return state.progress[key(t)]||{w1:0,w2:0,w3:0,c:0,w:0,streak:0,mastered:false,start:null,next:null}}
function traffic(p){if(p.mastered)return 'green';if(p.streak>0||(p.w>0&&p.w>=p.c))return 'red';return 'yellow'}
function isDue(p){return !p.mastered&&(!p.next||Date.parse(p.next)<=Date.now())}
function stats(list){let selectedNum=0,available=0,mastered=0,wrong=0,correct=0,due=0,attempted=0;const typed=new Set((state.typingHistory||[]).filter(x=>x.src===state.src&&x.dst===state.dst&&x.kind===state.kind).map(x=>x.id));for(let t of list){if(selected(t))selectedNum++;if(eligible(t)){available++;const p=prog(t);mastered+=p.mastered?1:0;correct+=p.c;wrong+=p.w;due+=isDue(p)?1:0;attempted+=(p.c+p.w>0||typed.has(t.id))?1:0}}return {total:list.length,selected:selectedNum,available,mastered,wrong,correct,due,attempted,accuracy:correct+wrong?Math.round(100*correct/(correct+wrong)):null}}
function savedAttemptCount(){return state.attempts.filter(a=>a.src===state.src&&a.dst===state.dst).length}
function daysAgo(d){return Math.floor(utcDay(new Date())-utcDay(d))}
const orderPriority=(a,b)=>{const x=prog(a),y=prog(b);return Number(x.mastered)-Number(y.mastered)||y.w-x.w||y.streak-x.streak||Number(isDue(y))-Number(isDue(x))||a.id.localeCompare(b.id)};
function totalActive(){return terms.filter(t=>eligible(t)&&selected(t))}
function allSelected(a){return a.length>0&&a.every(t=>selected(t))}
function someSelected(a){return a.some(t=>selected(t))}
function toggleSelection(a,force){const ex=excluded();const turnOn=force===undefined?!allSelected(a):force;for(const t of a){if(turnOn)ex.delete(t.id);else ex.add(t.id)}state.excluded=[...ex];persist();render()}
function toggleGroup(kind,id){const set=kind==='cat'?ui.expandedCats:ui.expandedSubs;set.has(id)?set.delete(id):set.add(id);render()}
function unique(a){return [...new Set(a)]}
const attr=s=>encode(s).replace(/`/g,'&#96;');
function badge(t,p){let c=traffic(p);return `<span class="tag ${c}">${c==='green'?'Mastered':c==='red'?'Needs review':'Learning'}</span>`}
function greenBar(p){return `<div class="progressbar"><div class="progressfill" style="width:${Math.min(100,Math.round(100*p))}%"></div></div>`}
function languageControls(compact=false){const opts=(sel)=>Object.entries(langNames).filter(([code])=>sel!=='dst'||code!==state.src).map(([code,name])=>`<option value="${code}" ${code===state[sel]?'selected':''}>${encode(name)}</option>`).join('');return `<div class="card flat"><div class="eyebrow">Language direction</div><div class="two"><label><span class="form-label">From · source</span><select class="field" data-setting="src">${opts('src')}</select></label><label><span class="form-label">To · answers</span><select class="field" data-setting="dst">${opts('dst')}</select></label></div>${compact?'':`<label style="display:block;margin-top:12px"><span class="form-label">Question instructions</span><select class="field" data-setting="instruction">${opts('instruction')}</select></label>`}</div>`}
const I18N={en: {ask:'How do you say',in:'in'},it:{ask:'Come si dice',in:'in'},es:{ask:'¿Cómo se dice',in:'en'},fr:{ask:'Comment dit-on',in:'en'},de:{ask:'Wie sagt man',in:'auf'},pt:{ask:'Como se diz',in:'em'}};
function questionPrompt(t){const tr=I18N[state.instruction]||I18N.en;return `${tr.ask} “${shown(t,state.src)}” ${tr.in} ${langNames[state.dst]||state.dst}?`}
function heading(title){return `<h1 class="h1">${title}</h1>`}
function homeView(){
 const scope=totalActive(),st=stats(scope),kind=state.kind==='word'?'Words':'Phrases';
 const topical=unique(scope.map(t=>t.c)).slice(0,6);
 return `<div class="page-heading"><div><div class="eyebrow">${encode(langNames[state.src])} → ${encode(langNames[state.dst])}</div><h1 class="h1">Ready to practice?</h1></div><button class="icon-link" data-nav="settings" aria-label="Settings">⚙</button></div>
 <div class="home-hero compact-hero"><div class="home-micro">YOUR PROGRESS</div><div class="home-feature"><strong>${st.attempted}</strong><span>practiced</span><i></i><strong>${st.mastered}</strong><span>mastered</span></div><div class="home-pair">${encode(kind)} · ${scope.length} selected</div></div>
 <div class="section section-tight">Play</div><div class="launch-grid">
 <button class="launch-card" data-quickmode="choice"><span class="launch-symbol">▦</span><strong>Quiz</strong><span>Multiple choice <b>↗</b></span></button>
 <button class="launch-card" data-quickmode="typing"><span class="launch-symbol">⌨</span><strong>Write</strong><span>Recall <b>↗</b></span></button>
 <button class="launch-card" data-quickmode="color"><span class="launch-symbol">◉</span><strong>Similarity</strong><span>4 labels <b>↗</b></span></button>
 </div><div class="home-selection"><span>${scope.length} ${state.kind==='word'?'words':'phrases'} selected</span><button class="text-button" data-step="2">Choose topics →</button></div><button class="home-pattern-link" data-nav="patterns">Browse words by pattern →</button>`;
}
function topicsView(){
 const eligibleAll=terms.filter(eligible),q=ui.wordFilter.trim().toLocaleLowerCase();
 const visible=eligibleAll.filter(t=>!q||[t.c,t.s,shown(t,state.src),shown(t,state.dst)].join(' ').toLocaleLowerCase().includes(q));
 const selectedCount=eligibleAll.filter(selected).length,cats=unique(visible.map(t=>t.c)).sort();
 let html=`<div class="page-heading"><h1 class="h1">Choose topics</h1><span class="tiny-count">${selectedCount} / ${eligibleAll.length}</span></div>
 <input aria-label="Search topics and words" class="field search-field" id="vocabSearch" type="search" placeholder="Search words or topics" value="${attr(ui.wordFilter)}" autocomplete="off">
 <div class="row spread compact-tools"><span class="small">${visible.length} entries</span><div class="row"><button class="text-button" data-action="all-select">Select all</button><button class="text-button" data-action="all-clear">Clear</button></div></div><div class="category-grid">`;
 for(const cat of cats){
  const list=visible.filter(t=>t.c===cat),open=ui.expandedCats.has(cat),ss=unique(list.map(t=>t.s)).sort();
  html+=`<div class="category"><div class="category-head"><input aria-label="Select ${attr(cat)}" type="checkbox" class="checkbox" data-cat-select="${attr(cat)}" ${allSelected(list)?'checked':''} ${someSelected(list)&&!allSelected(list)?'data-indeterminate="1"':''}><span class="label-ellipsis" data-toggle-cat="${attr(cat)}">${encode(cat)}</span><span class="count">${list.filter(selected).length}/${list.length}</span><button class="chevron" aria-label="Toggle ${attr(cat)}" data-toggle-cat="${attr(cat)}">${open?'−':'+'}</button></div>`;
  if(open){html+='<div class="sub-wrap">';for(const sub of ss){const items=list.filter(t=>t.s===sub),open2=ui.expandedSubs.has(cat+'|'+sub);html+=`<div class="sub-head"><input aria-label="Select ${attr(sub)}" type="checkbox" class="checkbox" data-sub-select="${attr(cat)}|${attr(sub)}" ${allSelected(items)?'checked':''} ${someSelected(items)&&!allSelected(items)?'data-indeterminate="1"':''}><span class="label-ellipsis" data-toggle-sub="${attr(cat)}|${attr(sub)}">${encode(sub)}</span><span class="count">${items.filter(selected).length}/${items.length}</span><button class="chevron" data-toggle-sub="${attr(cat)}|${attr(sub)}">${open2?'−':'+'}</button></div>`;
   if(open2){html+='<div class="word-wrap">';for(const t of items){html+=`<div class="word-head"><input aria-label="Select ${attr(shown(t,state.src))}" type="checkbox" class="checkbox" data-word-select="${attr(t.id)}" ${selected(t)?'checked':''}><span class="label-ellipsis">${encode(shown(t,state.src))} <span class="muted">· ${encode(shown(t,state.dst))}</span></span></div>`}html+='</div>'}
  }html+='</div>'}html+='</div>'}
 return html+'</div>'+(cats.length?'':'<div class="listempty">No matching terms.</div>');
}
// Patterns is an independent language-wide browser, never limited by Study topic selection.
// Strip initial articles for analyzing patterns, regardless of the Study display setting.
function patternLexemeForLang(t,lang){
 const value=String(t.t[lang]||'').trim();
 // A phrase remains a phrase: only isolated vocabulary entries lose their articles.
 return t.k==='phrase'?value:value.replace(ARTICLES[lang]||/^$/u,'').trim();
}
function patternLexeme(t){return patternLexemeForLang(t,ui.patternSource)}
// Deduplicate a *translation pair*, not just a spelling: homographs with
// different meanings stay distinct. Accents remain significant for identity.
function patternIdentity(value){return String(value||'').normalize('NFC').toLocaleLowerCase().replace(/\s+/gu,' ').trim()}

function patternNormalized(value){return String(value||'').normalize('NFD').replace(/\p{M}/gu,'').toLocaleLowerCase().trim()}
function patternLetters(t){return patternNormalized(patternLexeme(t)).replace(/[^\p{L}\p{N}]/gu,'')}
function patternWordCount(t){return (patternNormalized(patternLexeme(t)).match(/[\p{L}\p{N}]+(?:['’][\p{L}\p{N}]+)*/gu)||[]).length}
function patternReset(){ui.patternFocus='';ui.patternSearch='';ui.patternCollapsed.clear();ui.patternShowAll='';ui.patternPools=new Map()}
function patternPool(){
 const pool=terms.filter(t=>Boolean(t.t[ui.patternSource]?.trim()&&t.t[ui.patternTarget]?.trim()&&ui.patternSource!==ui.patternTarget)&&
 (ui.patternKind==='phrase'?t.k==='phrase':t.k!=='phrase'));
 const seen=new Map();
 for(const t of pool){
  const source=patternIdentity(patternLexemeForLang(t,ui.patternSource));
  const target=patternIdentity(patternLexemeForLang(t,ui.patternTarget));
  const dedupKey=JSON.stringify([ui.patternKind,source,target]);
  const location=`${t.c} / ${t.s}`;
  if(!seen.has(dedupKey))seen.set(dedupKey,{...t,patternLocations:[location]});
  else{
   const existing=seen.get(dedupKey);
   if(!existing.patternLocations.includes(location))existing.patternLocations.push(location);
  }
 }
 return [...seen.values()];
}
function patternView(){
 const pool=patternPool(),mode=ui.patternMode,nested=mode==='prefix'||mode==='suffix';
 const normalizedQuery=patternNormalized(ui.patternSearch).replace(/^[-\s]+|[-\s]+$/g,'').replace(/[^\p{L}\p{N}]/gu,'');
 const langOptions=Object.entries(langNames).map(([code,name])=>`<option value="${code}" ${ui.patternSource===code?'selected':''}>${encode(name)}</option>`).join('');
 const targetOptions=Object.entries(langNames).filter(([code])=>code!==ui.patternSource).map(([code,name])=>`<option value="${code}" ${ui.patternTarget===code?'selected':''}>${encode(name)}</option>`).join('');
 let relevant=pool;
 if(nested){
  if(ui.patternFocus)relevant=relevant.filter(t=>mode==='prefix'?patternLetters(t).startsWith(ui.patternFocus):patternLetters(t).endsWith(ui.patternFocus));
  if(normalizedQuery)relevant=relevant.filter(t=>mode==='prefix'?patternLetters(t).startsWith(normalizedQuery):patternLetters(t).endsWith(normalizedQuery));
 }
 const catCount=unique(pool.map(t=>t.c)).length;
 let html=`<div class="page-heading"><h1 class="h1">Patterns</h1><span class="tiny-count">${pool.length} ${ui.patternKind==='phrase'?'phrases':'words'}</span></div>
 <div class="pattern-filters">
  <div class="two"><label><span class="form-label">Language</span><select aria-label="Pattern language" class="field" data-pattern-setting="source">${langOptions}</select></label>
  <label><span class="form-label">Translate to</span><select aria-label="Translation language" class="field" data-pattern-setting="target">${targetOptions}</select></label></div>
  <div class="pillset pattern-kind">${[['word','Words'],['phrase','Phrases']].map(([id,name])=>`<button class="pill ${ui.patternKind===id?'active':''}" data-pattern-kind="${id}">${name}</button>`).join('')}</div>
  <div class="small pattern-corpus-info">All ${catCount} categories · no topic filters</div>
  <div class="pattern-modes" role="group" aria-label="Grouping method">${[['prefix','Starts with'],['suffix','Ends with'],['length','Letters'],['words','Word count']].map(([k,l])=>`<button class="pill ${mode===k?'active':''}" data-pattern-mode="${k}">${l}</button>`).join('')}</div>`;
 if(nested){
  html+=`<div class="pattern-query"><label><span class="form-label">${mode==='prefix'?'Starts with':'Ends with'}</span><input type="search" class="field" id="patternSearch" value="${attr(ui.patternSearch)}" placeholder="${mode==='prefix'?'e.g. ab':'e.g. ente'}" autocomplete="off" spellcheck="false"></label>${ui.patternFocus?`<button class="ghost" data-pattern-back="1">← Back</button>`:''}</div>`;
 }
 const groupMap=new Map();
 if(nested&&normalizedQuery){groupMap.set(normalizedQuery,relevant)}
 else if(nested){
  const depth=Array.from(ui.patternFocus).length+1;
  for(const t of relevant){const word=patternLetters(t);if(!word)continue;const letters=Array.from(word);const key=letters.length<depth?word:mode==='prefix'?letters.slice(0,depth).join(''):letters.slice(-depth).join('');
   if(!groupMap.has(key))groupMap.set(key,[]);groupMap.get(key).push(t)}
 }else{for(const t of relevant){const k=String(mode==='length'?Array.from(patternLetters(t)).length:patternWordCount(t));if(!groupMap.has(k))groupMap.set(k,[]);groupMap.get(k).push(t)}}
 // Count distinct vocabulary entries in each group (across every category).
 // Keep alphabetical/numerical tie-breaking stable so the same pattern is easy to locate.
 const baseCompare=(a,b)=>nested?a[0].localeCompare(b[0],ui.patternSource,{sensitivity:'base'}):Number(a[0])-Number(b[0]);
 // Rows within every group are alphabetic in the analyzed language, regardless of how groups are sorted.
 for(const members of groupMap.values())members.sort((a,b)=>patternLexeme(a).localeCompare(patternLexeme(b),ui.patternSource,{sensitivity:'base'})||String(a.id).localeCompare(String(b.id)));
 const groups=[...groupMap.entries()].filter(([,arr])=>arr.length).sort((a,b)=>
  state.patternSort==='most'?b[1].length-a[1].length||baseCompare(a,b):
  state.patternSort==='least'?a[1].length-b[1].length||baseCompare(a,b):baseCompare(a,b));
 ui.patternPools=new Map(groups.map(([,arr],i)=>[String(i),arr]));
 html+=`</div><div class="pattern-game-settings"><div class="section">Quiz mode</div><div class="pillset">${[['choice','Quiz'],['typing','Write'],['color','Similarity']].filter(([key])=>ui.patternKind==='word'||key!=='color').map(([key,name])=>`<button class="pill ${state.gameMode===key?'active':''}" data-pattern-game="${key}">${name}</button>`).join('')}</div><div class="section">Questions per quiz</div><div class="pillset">${[5,10,15,20,30,50].map(n=>`<button class="pill ${state.quizLimit===n?'active':''}" data-pattern-limit="${n}">${n}</button>`).join('')}</div></div><div class="pattern-results-header"><div class="pattern-results-label"><strong>${relevant.length} matching ${ui.patternKind==='phrase'?'phrases':'words'}</strong><span class="small">${groups.length} groups</span></div><label class="pattern-sort-label"><span class="form-label">Sort pattern groups</span><select class="field pattern-sort-select" aria-label="Sort pattern groups by occurrences" data-pattern-sort="1"><option value="most" ${state.patternSort==='most'?'selected':''}>Most recurring ↓</option><option value="least" ${state.patternSort==='least'?'selected':''}>Least recurring ↑</option><option value="alphabetical" ${state.patternSort==='alphabetical'?'selected':''}>A–Z / Number ↑</option></select></label></div>`;
 if(nested&&ui.patternFocus)html+=`<button class="text-button pattern-path" data-pattern-back="1">← ${encode(ui.patternFocus)} · Back one letter</button>`;
 if(!groups.length)return html+'<div class="listempty">No matches for this language pair. Try another translation language or pattern.</div>';
 html+='<div class="pattern-groups">';
 for(let i=0;i<groups.length;i++){
  const [g,list]=groups[i],id=String(i),open=!ui.patternCollapsed.has(g);
  const label=mode==='suffix'?'-'+g:mode==='prefix'?g:mode==='length'?`${g} ${g==='1'?'letter':'letters'}`:`${g} ${g==='1'?'word':'words'}`;
  const canDrill=nested&&!normalizedQuery&&list.some(t=>Array.from(patternLetters(t)).length>Array.from(g).length);
  const preview=list.slice(0,open?(ui.patternShowAll===g?list.length:60):3);
  html+=`<article class="pattern-group"><div class="pattern-group-head"><button class="pattern-group-name" data-pattern-expand="${attr(g)}" aria-expanded="${open}" aria-label="Show words for ${attr(label)}"><strong>${encode(label)}</strong><span>${list.length} ${ui.patternKind==='phrase'?'phrases':'words'}</span><span class="pattern-arrow">${open?'−':'+'}</span></button><button class="pattern-play" data-pattern-play="${id}" aria-label="Start quiz for ${attr(label)}">Play ↗</button></div>`;
  if(open){html+='<div class="pattern-words">';for(const t of preview){html+=`<div class="pattern-word"><span><strong>${encode(patternLexeme(t))}</strong><small>${encode((t.patternLocations||[`${t.c} / ${t.s}`]).join(' · '))}</small></span><span>${encode(shownWord(t.t[ui.patternTarget],ui.patternTarget,t.k))}</span></div>`}if(list.length>60&&ui.patternShowAll!==g)html+=`<button class="pattern-deeper" data-pattern-all="${attr(g)}">Show all ${list.length} ${ui.patternKind==='phrase'?'phrases':'words'} ↓</button>`;
   if(canDrill)html+=`<button class="pattern-deeper" data-pattern-drill="${attr(g)}">${mode==='prefix'?'Next letter →':'Previous letter →'}</button>`;
   html+='</div>';
  }else html+=`<div class="pattern-preview">${preview.map(t=>encode(patternLexeme(t))).join(' · ')}</div>`;
  html+='</article>';
 }
 html+='</div>';
 return html;
}
function setupHeader(){
 const steps=[['Languages',1],['Topics',2]];
 return `<div class="study-progress" aria-label="Study setup steps">${steps.map(([label,num])=>`<button class="study-step ${ui.setupStep===num?'current':''} ${ui.setupStep>num?'done':''}" data-step="${num}"><span>${num}</span>${label}</button>`).join('')}</div>`;
}
function settingsView(){
 const selectedTerms=totalActive(), count=selectedTerms.length;
 if(ui.setupStep===1)return `${heading('Languages')}${setupHeader()}${languageControls(true)}
 <div class="section">Study material</div><div class="pillset">${[['word','Words'],['phrase','Phrases']].map(([k,v])=>`<button class="pill ${state.kind===k?'active':''}" data-kind="${k}">${v}</button>`).join('')}</div>
 <div class="preferences-box"><label class="pref-toggle"><span><strong>Show articles</strong><small>el índice / índice</small></span><input aria-label="Show articles" type="checkbox" data-setting-check="showArticles" ${state.showArticles?'checked':''}></label><label class="pref-toggle"><span><strong>Require accents</strong><small>Check accents in written answers</small></span><input aria-label="Require accents" type="checkbox" data-setting-check="requireAccents" ${state.requireAccents?'checked':''}></label></div>
 <div class="study-foot"><button class="primary full" data-step="2">Choose topics <span>→</span></button></div>`;
 return `${setupHeader()}<div class="section">Game mode</div><div class="game-modes minimal-modes">${[['choice','▦','Quiz'],['typing','⌨','Write'],['color','◉','Similarity']].filter(([m])=>state.kind==='word'||m!=='color').map(([m,i,label])=>`<button class="game-card ${state.gameMode===m?'active':''}" data-game="${m}"><span class="game-icon">${i}</span><strong>${label}</strong></button>`).join('')}</div>
 <div class="section">Questions</div><div class="pillset">${[5,10,15,20,30,50].map(n=>`<button class="pill ${state.quizLimit===n?'active':''}" data-limit="${n}">${n}</button>`).join('')}</div>
 <div class="study-foot"><div class="row spread study-foot-count"><span>${count} ${state.kind==='word'?'words':'phrases'} selected</span><button class="text-button" data-step="1">← Languages</button></div><button class="primary full" data-action="start" ${count===0?'disabled':''}>Start ${state.gameMode==='choice'?'quiz':state.gameMode==='typing'?'writing':'similarity'} <span>→</span></button></div>
 ${topicsView()}
 <details class="advanced-details"><summary>More options</summary>
 <div class="section">Review · Quiz only</div><div class="seg"><button data-mode="automatic" class="${state.reviewMode==='automatic'?'on':''}">Automatic</button><button data-mode="anki" class="${state.reviewMode==='anki'?'on':''}">Anki</button></div>
 <div class="row spread" style="margin:18px 0"><span class="small">Include mastered terms</span><input class="checkbox" type="checkbox" data-setting-check="showMastered" ${state.showMastered?'checked':''}></div>
 <div class="section">Data</div><label class="filefake"><input type="file" accept=".json,application/json" id="importJson" style="display:none">Import JSON</label>
 <div class="row" style="margin-top:10px"><button class="secondary" style="flex:1" data-action="export">Export</button><button class="secondary" style="flex:1" data-action="reset">Reset</button></div>
 ${ui.importStatus?`<div class="flash">${encode(ui.importStatus)}</div>`:''}</details>
`;
}
function statsView(){
 const active=totalActive(),st=stats(active),cats=unique(active.map(t=>t.c)).sort();
 const typing=state.typingHistory.filter(x=>x.src===state.src&&x.dst===state.dst&&active.some(t=>t.id===x.id));
 const rank=[...active].filter(t=>prog(t).w).sort(orderPriority).slice(0,8);
 return `${heading('Progress')}
 <div class="pillset">${[['word','Words'],['phrase','Phrases']].map(([k,v])=>`<button class="pill ${state.kind===k?'active':''}" data-kind="${k}">${v}</button>`).join('')}</div>
 <div class="kpis progress-kpis"><div class="kpi"><strong>${st.attempted}</strong><span>Practiced</span></div><div class="kpi"><strong>${st.mastered}</strong><span>Mastered</span></div><div class="kpi"><strong>${st.available-st.attempted}</strong><span>Not practiced</span></div></div>
 <div class="section">By category</div><div class="category-stats-grid">${cats.map(c=>{const x=stats(active.filter(t=>t.c===c));return `<div class="card flat statsitem"><div class="row spread"><strong>${encode(c)}</strong><span class="tiny-count">${x.attempted}/${x.total}</span></div><div class="small">${x.mastered} mastered</div>${greenBar(x.total?x.attempted/x.total:0)}<details><summary>Subcategories</summary>${unique(active.filter(t=>t.c===c).map(t=>t.s)).sort().map(sub=>{const y=stats(active.filter(t=>t.c===c&&t.s===sub));return `<div class="row spread stat-sub"><span>${encode(sub)}</span><span>${y.attempted}/${y.total} · ${y.mastered} mastered</span></div>`}).join('')}</details></div>`}).join('')||'<div class="small">Nothing selected yet.</div>'}</div>
 <div class="section">Performance</div><div class="stats-sections">
 <details class="card detail-card"><summary>Quiz accuracy <strong>${st.accuracy===null?'Not tested':st.accuracy+'%'}</strong></summary><div class="small">${st.correct} correct · ${st.wrong} wrong</div>${cats.map(c=>{const x=stats(active.filter(t=>t.c===c));return `<div class="row spread stat-sub"><span>${encode(c)}</span><span>${x.accuracy===null?'—':x.accuracy+'%'} · ${x.correct+x.wrong} answers</span></div>`}).join('')}</details>
 <details class="card detail-card"><summary>Written recall <strong>${typing.length} attempts</strong></summary><div class="small">${typing.filter(x=>x.correct).length} correct · ${typing.filter(x=>!x.correct&&!x.shown).length} wrong · ${typing.filter(x=>x.shown).length} revealed</div></details>
 <details class="card detail-card"><summary>Similarity <strong>${active.filter(t=>state.similarity[similarityKey(t)]).length} rated</strong></summary>${[['green','Very similar'],['yellow','Similar'],['red','Different'],['neutral','Neutral']].map(([k,v])=>`<div class="row spread stat-sub"><span>${v}</span><strong>${active.filter(t=>state.similarity[similarityKey(t)]===k).length}</strong></div>`).join('')}</details>
 <details class="card detail-card"><summary>Most missed <strong>${rank.length}</strong></summary>${rank.map(t=>`<div class="stat-sub"><strong>${encode(shown(t,state.src))} → ${encode(shown(t,state.dst))}</strong><span class="small"> · ${prog(t).w} wrong</span></div>`).join('')||'<div class="small">None yet</div>'}</details>
 </div>`;
}
function howManyOptions(t,pool){const right=shown(t,state.dst),a=pool.filter(x=>x.id!==t.id&&shown(x,state.dst)!==right).sort((x,y)=>Number(x.c!==t.c)-Number(y.c!==t.c));const opts=[right];let candidates=shuffle(a);candidates.sort((x,y)=>Number(x.c!==t.c)-Number(y.c!==t.c));for(const c of candidates){if(opts.length>=4)break;const v=shown(c,state.dst);if(v&&!opts.includes(v))opts.push(v)}return shuffle(opts)}
function shuffle(a){a=[...a];for(let i=a.length-1;i>0;i--){const j=Math.floor(Math.random()*(i+1));[a[i],a[j]]=[a[j],a[i]]}return a}
function startGame(explicitPool=null,fromPatterns=false){ui.patternFromNav=fromPatterns;const source=Array.isArray(explicitPool)?explicitPool:totalActive();if(!source.length){ui.setupStep=2;setTab('settings');return;}const candidates=source.filter(t=>Array.isArray(explicitPool)||state.gameMode==='color'||state.showMastered||!prog(t).mastered);const picks=shuffle([...candidates].sort(orderPriority).slice(0,Math.max(100,state.quizLimit*5))).slice(0,state.quizLimit);ui.session={items:picks,index:0,correct:0,wrong:0,skipped:0,mode:state.gameMode,kind:state.kind,originIds:Array.isArray(explicitPool)?source.map(t=>t.id):null};ui.question=null;ui.qIndex=0;newQuestion();setTab('quiz')}
function newQuestion(){if(!ui.session){ui.question=null;return}const sess=ui.session;if(sess.index>=sess.items.length){ui.question=null;return}const candidate=sess.items[sess.index];ui.question=candidate;ui.options=howManyOptions(candidate,terms.filter(eligible));ui.revealed=false;ui.answer=-1;ui.typedHint=false;ui.typedRevealed=false;ui.typedEntry='';ui.typedSubmitted=false;ui.qIndex=sess.index+1}
function advance(){if(!ui.session)return;ui.session.index++;newQuestion();render()}
function normalized(s){return matchingForm(s)}
function markTyping(correct,shown,entry){if(ui.typedSubmitted)return;const t=ui.question;state.typingHistory.push({id:t.id,src:state.src,dst:state.dst,kind:t.k,correct,shown,typed:entry||'',at:new Date().toISOString()});if(state.typingHistory.length>30000)state.typingHistory=state.typingHistory.slice(-30000);ui.typedSubmitted=true;ui.typedRevealed=shown;if(correct)ui.session.correct++;else if(shown)ui.session.skipped++;else ui.session.wrong++;persist();render()}
function similarityKey(t){return `${t.id}:${state.src}>${state.dst}`}
function setSimilarity(val){state.similarity[similarityKey(ui.question)]=val;ui.session.correct++;persist();advance()}
function gameSummary(){const s=ui.session;return `<div class="game-stage"><div class="page-heading"><h1 class="h1">Done!</h1></div><div class="card emphasis center-finish"><div class="big-number">${s.items.length}</div><span>items completed</span></div><div class="kpis"><div class="kpi"><strong>${s.correct}</strong><span>${s.mode==='color'?'Rated':'Correct'}</span></div><div class="kpi"><strong>${s.skipped+s.wrong}</strong><span>${s.mode==='color'?'Skipped':'Wrong / skipped'}</span></div></div><button class="primary full" data-action="repeat">Play again →</button><button class="secondary full" style="margin-top:10px" data-nav="${ui.patternFromNav?'patterns':'home'}">${ui.patternFromNav?'Back to Patterns':'Home'}</button></div>`}
function renderLetterSlots(answer,entry,hint=false){
 const graphemes=splitGraphemes(answer),typed=typedLetters(entry);
 let pos=0,html='';const count=graphemes.filter(x=>/[\p{L}\p{N}]/u.test(x)).length;
 for(let i=0;i<graphemes.length;i++){
  const char=graphemes[i];if(!/[\p{L}\p{N}]/u.test(char)){
   html+=`<span aria-hidden="true" class="slot-separator">${char===' '?'&nbsp;':encode(char)}</span>`;continue;
  }
  const filled=pos<typed.length,atCursor=pos===typed.length;
  const value=filled?typed[pos]:(hint&&(pos===0||pos===count-1)?char:'');
  const cls=filled?'filled':value?'hinted':atCursor?'current':'';
  html+=`<span aria-hidden="true" class="letter-slot ${cls}">${value?encode(value):'&nbsp;'}</span>`;pos++;
 }
 const remaining=Math.max(0,typed.length-count),same=typed.length===count;
 return {html,count,entered:typed.length,remaining,same};
}
function updateTypingSlots(){
 const t=ui.question;if(!t||!ui.session||ui.session.mode!=='typing'||ui.typedSubmitted)return;
 const slots=renderLetterSlots(shown(t,state.dst),ui.typedEntry,ui.typedHint);
 const el=document.getElementById('letterSlots'),status=document.getElementById('letterCount');
 if(el){el.innerHTML=slots.html;el.classList.toggle('length-matched',slots.same);el.classList.toggle('length-exceeded',slots.remaining>0)}
 if(status){status.textContent=slots.remaining?`${slots.remaining} extra ${slots.remaining===1?'letter':'letters'}`:`${slots.entered} / ${slots.count} letters${slots.same?' · length matches':''}`;status.className=`slot-count ${slots.same?'matched':slots.remaining?'exceeded':''}`}
}
function typingQuestion(t){
 const answer=shown(t,state.dst),slots=renderLetterSlots(answer,ui.typedEntry,ui.typedHint);
 return `<div class="game-focus"><div class="word-context">${encode(t.c)} / ${encode(t.s)}</div><h2 class="prompt-word">${encode(shown(t,state.src))}</h2><div class="pair-sub">${encode(langNames[state.src])} → ${encode(langNames[state.dst])}</div>
 ${ui.typedSubmitted?`<div class="nextbox"><strong>${encode(answer)}</strong><div class="small">${ui.typedRevealed?'Revealed':typingMatches(ui.typedEntry,t)?'Correct':'Your answer: '+encode(ui.typedEntry)}</div></div><button class="primary full" data-action="next">Next →</button>`:
 `<form id="typingForm"><label class="typing-slots-label" for="typingAnswer"><span class="typing-slots ${slots.same?'length-matched':''} ${slots.remaining?'length-exceeded':''}" id="letterSlots">${slots.html}</span><input aria-label="Type the answer in the letter slots" id="typingAnswer" type="text" autocomplete="off" autocapitalize="off" spellcheck="false" inputmode="text" value="${attr(ui.typedEntry)}"></label><div id="letterCount" class="slot-count ${slots.same?'matched':slots.remaining?'exceeded':''}">${slots.remaining?slots.remaining+' extra letters':`${slots.entered} / ${slots.count} letters${slots.same?' · length matches':''}`}</div><button class="primary full" type="submit">Check →</button></form>
 <div class="two hint-actions"><button class="secondary" data-action="hint">${ui.typedHint?'Hint shown ✓':'Hint'}</button><button class="secondary" data-action="reveal">Reveal / skip</button></div>`}</div>`
}
function colorQuestion(t){const current=state.similarity[similarityKey(t)]||'';return `<div class="game-focus similarity-focus"><div class="word-context">${encode(t.c)} · ${encode(t.s)}</div><div class="compare-words"><div>${encode(shown(t,state.src))}<small>${encode(langNames[state.src])}</small></div><span class="compare-mark">↕</span><div>${encode(shown(t,state.dst))}<small>${encode(langNames[state.dst])}</small></div></div><div class="color-grid">${[['red','🔴','Different'],['yellow','🟡','Similar'],['green','🟢','Very similar'],['neutral','⚪','Neutral']].map(([id,ic,name])=>`<button class="color-choice ${current===id?'on':''}" data-color="${id}" aria-label="${name}"><span>${ic}</span><strong>${name}</strong></button>`).join('')}</div></div>`}
function getWeekly(p){if(!p.start)return {week:0,done:0,quota:3};const diff=Math.floor(utcDay(new Date())-utcDay(p.start));const idx=Math.floor(diff/7);return {week:idx,done:[p.w1,p.w2,p.w3][idx]||0,quota:[3,2,1][idx]||3}}
function quizView(){
 if(!ui.session)return `<div class="game-stage">${heading('Play')}<button class="primary full" data-nav="settings">Choose a mode →</button></div>`;
 if(!ui.question)return gameSummary();
 const t=ui.question,p=prog(t),ss=ui.session;
 const header=`<div class="game-top"><button class="back-game" data-nav="${ui.patternFromNav?'patterns':'home'}" aria-label="Exit game">←</button><span>${ss.mode==='typing'?'Write':ss.mode==='color'?'Similarity':'Quiz'}</span><span>${ui.qIndex} / ${ss.items.length}</span></div>${greenBar((ui.qIndex-1)/ss.items.length)}`;
 if(ss.mode==='typing')return `<div class="game-stage">${header}${typingQuestion(t)}</div>`;
 if(ss.mode==='color')return `<div class="game-stage">${header}${colorQuestion(t)}</div>`;
 const keycode=ui.options.findIndex(x=>x===shown(t,state.dst));
 const opts=ui.options.map((opt,i)=>`<button class="option ${ui.revealed?(i===keycode?'correct':i===ui.answer?'wrong':''):''}" data-option="${i}" ${ui.revealed?'disabled':''}><span class="letter">${'ABCD'[i]}</span>${encode(opt)}</button>`).join('');
 let feedback='';
 if(ui.revealed){
   const result=ui.answer===keycode?'✓ Correct':'Answer: '+encode(shown(t,state.dst));
   const next=state.reviewMode==='anki'?`<div class="two">${[['again','Again'],['hard','Hard'],['good','Good'],['easy','Easy']].map(([v,l])=>`<button class="secondary" data-rate="${v}">${l}</button>`).join('')}</div>`:`<button class="primary full next-btn" data-action="next">Next →</button>`;
   feedback=`<div class="nextbox"><strong>${result}</strong></div>${next}`;
 }
 return `<div class="game-stage">${header}<div class="game-focus"><div class="word-context">${encode(t.c)} · ${encode(t.s)}</div><div class="pair-sub">${encode(langNames[state.src])} → ${encode(langNames[state.dst])}</div><h2 class="prompt-word">${encode(shown(t,state.src))}</h2><div class="game-options">${opts}</div>${feedback}</div></div>`;
}
function record(t,correct,rating){const x=prog(t),p={...x};let now=new Date();let start=p.start?new Date(p.start):new Date(now.getFullYear(),now.getMonth(),now.getDate());let w=Math.floor((utcDay(now)-utcDay(start))/7);if(p.mastered&&!correct){start=new Date(now.getFullYear(),now.getMonth(),now.getDate());p.w1=p.w2=p.w3=0;p.mastered=false;w=0}const missed=(w<0||w>2||(w>=1&&p.w1<3)||(w>=2&&p.w2<2));if(!p.mastered&&missed){start=new Date(now.getFullYear(),now.getMonth(),now.getDate());p.w1=p.w2=p.w3=0;w=0}p.start=start.toISOString();if(correct&&!p.mastered){if(w===0)p.w1++;else if(w===1)p.w2++;else if(w===2)p.w3++;p.mastered=p.w1>=3&&p.w2>=2&&p.w3>=1}p.c+=(correct?1:0);p.w+=(!correct?1:0);p.streak=correct?0:p.streak+1;let next=null;if(!p.mastered){const min=(!correct||rating==='again')?5:rating==='hard'?360:rating==='easy'?4320:1440;next=new Date(now.getTime()+min*60000);const count=[p.w1,p.w2,p.w3][w],quota=[3,2,1][w];const endWindow=new Date(start.getFullYear(),start.getMonth(),start.getDate()+(w+1)*7);if(count>=quota)next=endWindow;else if(next>endWindow)next=new Date(endWindow.getTime()-60000)}p.next=next?.toISOString()||null;state.progress[key(t)]=p;state.attempts.push({at:now.toISOString(),id:t.id,src:state.src,dst:state.dst,c:correct,kind:t.k,category:t.c,sub:t.s,rating});if(state.attempts.length>30000)state.attempts=state.attempts.slice(-30000);persist()}
function navBar(){nav.innerHTML=[['home','⌂','Home'],['settings','◎','Study'],['patterns','⋈','Patterns'],['stats','▥','Stats']].map(([key,ico,title])=>`<button class="nav ${state.tab===key?'active':''}" data-nav="${key}"><span class="sym">${ico}</span>${title}</button>`).join('')}
function render(){navBar();view.closest('.app').classList.toggle('in-game',state.tab==='quiz'&&Boolean(ui.question));switch(state.tab){case 'home':view.innerHTML=homeView();break;case 'quiz':view.innerHTML=quizView();break;case 'stats':view.innerHTML=statsView();break;case 'patterns':view.innerHTML=patternView();break;case 'settings':view.innerHTML=settingsView();break;}for(const el of view.querySelectorAll('[data-indeterminate]'))el.indeterminate=true;}
function goStep(n){ui.setupStep=Math.min(2,Math.max(1,Number(n)));setTab('settings')}
function setTab(v){if(state.tab==='quiz'&&v!=='quiz'&&ui.patternStudyBefore){Object.assign(state,ui.patternStudyBefore);ui.patternStudyBefore=null;}state.tab=v;persist();render();view.closest('.app').scrollTo({top:0,behavior:'instant'});window.scrollTo(0,0)}
function setSetting(name,value){if(['src','dst','kind'].includes(name))patternReset();state[name]=value;if(name==='kind'&&value==='phrase'&&state.gameMode==='color')state.gameMode='choice';if(name==='gameMode'&&value==='color')state.kind='word';ui.session=null;ui.question=null;persist();render()}
function exportProgress(){const output=JSON.stringify({version:3,app:'Quiz Lab browser',exportedAt:new Date().toISOString(),progress:state.progress,attempts:state.attempts,excluded:state.excluded,typingHistory:state.typingHistory,similarity:state.similarity},null,2);const url=URL.createObjectURL(new Blob([output],{type:'application/json'}));const a=document.createElement('a');a.href=url;a.download='quizlab-browser-progress.json';a.click();URL.revokeObjectURL(url)}
function onFile(f){if(!f)return;const reader=new FileReader();reader.onload=()=>{try{const data=JSON.parse(reader.result);let a=[];if(Array.isArray(data.terms)){a=data.terms.map((t,i)=>{const path=(t.topic||'General / General').split(' / ');return {id:'user:'+ (data.id||'pack') + ':'+t.id,c:t.category||path[0],s:t.subtopic||path[1]||'General',k:t.kind||'word',t:Object.fromEntries(Object.entries(t.translations||{}).map(([k,v])=>[k.toLowerCase(),String(v)]))}})}else if(Array.isArray(data.entries)){a=data.entries.map((t,i)=>({id:'user:'+t.id,c:t.category||'General',s:t.subtopic||'General',k:t.type||'word',t:Object.fromEntries(Object.entries(t.words||{}).map(([k,v])=>[k.toLowerCase(),String(v)]))}))}else throw Error('Expected a JSON object containing terms[] or entries[].');a=a.filter(t=>t.id&&Object.keys(t.t).length>=2);let added=0;for(const t of a){if(!ids.has(t.id)){terms.push(t);ids.add(t.id);added++}}byId.clear();for(const t of terms)byId.set(t.id,t);localStorage.setItem(DATA_KEY,JSON.stringify(terms.slice(window.QUIZLAB_DATA.length)));ui.importStatus=`Imported ${added} new vocabulary items (${a.length} valid records).`;ui.question=null;setTab('settings')}catch(e){ui.importStatus='Import error: '+e.message;render()}};reader.readAsText(f,'utf-8')}
nav.addEventListener('click',e=>{const b=e.target.closest('[data-nav]');if(b){if(b.dataset.nav==='settings')ui.setupStep=1;setTab(b.dataset.nav)}});
view.addEventListener('click',e=>{const b=e.target.closest('button,[data-toggle-cat],[data-toggle-sub]');if(!b)return;const d=b.dataset;if(d.nav){if(d.nav==='settings')ui.setupStep=1;return setTab(d.nav)}if(d.step)return goStep(d.step);if(d.kind)return setSetting('kind',d.kind);if(d.mode)return setSetting('reviewMode',d.mode);if(d.quickmode){state.gameMode=d.quickmode;if(d.quickmode==='color')state.kind='word';persist();return goStep(1)}if(d.game)return setSetting('gameMode',d.game);if(d.limit)return setSetting('quizLimit',Number(d.limit));if(d.color)return setSimilarity(d.color);if(d.toggleCat!==undefined)return toggleGroup('cat',d.toggleCat);if(d.toggleSub!==undefined)return toggleGroup('sub',d.toggleSub);if(d.option!==undefined){if(ui.revealed)return;ui.answer=Number(d.option);ui.revealed=true;if(state.reviewMode==='automatic'){const good=ui.options[ui.answer]===shown(ui.question,state.dst);record(ui.question,good,good?'good':'again');ui.session[good?'correct':'wrong']++}render();return}if(d.rate){const good=ui.options[ui.answer]===shown(ui.question,state.dst)&&d.rate!=='again';record(ui.question,good,d.rate);ui.session[good?'correct':'wrong']++;advance();return}if(d.patternKind){ui.patternKind=d.patternKind;if(d.patternKind==='phrase'&&state.gameMode==='color')state.gameMode='choice';patternReset();persist();return render()}
 if(d.patternGame){state.gameMode=d.patternGame;persist();return render()}
 if(d.patternLimit){state.quizLimit=Number(d.patternLimit);persist();return render()}
 if(d.patternMode){ui.patternMode=d.patternMode;patternReset();return render()}
 if(d.patternBack!==undefined){ui.patternFocus=ui.patternFocus.slice(0,-1);ui.patternCollapsed.clear();return render()}
 if(d.patternExpand!==undefined){ui.patternCollapsed.has(d.patternExpand)?ui.patternCollapsed.delete(d.patternExpand):ui.patternCollapsed.add(d.patternExpand);return render()}
 if(d.patternAll!==undefined){ui.patternShowAll=d.patternAll;return render()}
 if(d.patternDrill!==undefined){ui.patternFocus=d.patternDrill;ui.patternCollapsed.clear();ui.patternSearch='';return render()}
 if(d.patternPlay!==undefined){const pool=ui.patternPools.get(d.patternPlay);if(pool?.length){ui.patternStudyBefore={src:state.src,dst:state.dst,kind:state.kind};state.src=ui.patternSource;state.dst=ui.patternTarget;state.kind=ui.patternKind;persist();return startGame(pool,true)}return}
 if(d.action==='repeat')return startGame(ui.session?.originIds?.map(id=>byId.get(id)).filter(Boolean)||null,ui.patternFromNav);
 if(d.action==='start')return startGame();if(d.action==='next')return advance();if(d.action==='hint'){ui.typedHint=true;render();document.getElementById('typingAnswer')?.focus();return}if(d.action==='reveal')return markTyping(false,true,'');if(d.action==='all-select'||d.action==='all-clear'){const q=ui.wordFilter.trim().toLowerCase(),a=terms.filter(t=>eligible(t)&&(!q||[t.c,t.s,shown(t,state.src),shown(t,state.dst)].join(' ').toLowerCase().includes(q)));return toggleSelection(a,d.action==='all-select')}if(d.action==='export')return exportProgress();if(d.action==='reset'){if(confirm('Delete all browser quiz progress? Vocabulary content will remain.')){state.progress={};state.attempts=[];state.typingHistory=[];state.similarity={};persist();render()}}});
view.addEventListener('submit',e=>{if(e.target.id!=='typingForm')return;e.preventDefault();if(ui.typedSubmitted||!ui.question)return;const input=document.getElementById('typingAnswer').value;ui.typedEntry=input;markTyping(typingMatches(input,ui.question),false,input)});
view.addEventListener('change',e=>{const d=e.target.dataset;if(d.patternSort){state.patternSort=e.target.value;ui.patternShowAll='';persist();return render()}if(d.patternSetting){if(d.patternSetting==='source'){ui.patternSource=e.target.value;if(ui.patternTarget===ui.patternSource)ui.patternTarget=Object.keys(langNames).find(k=>k!==ui.patternSource)}else if(d.patternSetting==='target'&&e.target.value!==ui.patternSource)ui.patternTarget=e.target.value;patternReset();return render()}if(d.setting){if(d.setting==='src'&&e.target.value===state.dst)state.dst=Object.keys(langNames).find(k=>k!==e.target.value);return setSetting(d.setting,e.target.value)}if(d.settingCheck)return setSetting(d.settingCheck,e.target.checked);if(d.catSelect!==undefined)return toggleSelection(terms.filter(t=>eligible(t)&&t.c===d.catSelect),e.target.checked);if(d.subSelect!==undefined){const [cat,sub]=d.subSelect.split('|');return toggleSelection(terms.filter(t=>eligible(t)&&t.c===cat&&t.s===sub),e.target.checked)}if(d.wordSelect!==undefined){const t=byId.get(d.wordSelect);if(t)return toggleSelection([t],e.target.checked)}if(e.target.id==='importJson')return onFile(e.target.files?.[0]);});
view.addEventListener('input',e=>{if(e.target.id==='typingAnswer'){ui.typedEntry=e.target.value;updateTypingSlots();return}if(e.target.id==='patternSearch'){const a=e.target.selectionStart;ui.patternSearch=e.target.value;ui.patternFocus='';ui.patternCollapsed.clear();render();const n=document.getElementById('patternSearch');if(n){n.focus();n.setSelectionRange(a,a)}return}if(e.target.id==='vocabSearch'){const a=e.target.selectionStart;ui.wordFilter=e.target.value;render();const n=document.getElementById('vocabSearch');n.focus();n.setSelectionRange(a,a)}});
document.getElementById('topInfo')?.addEventListener('click',()=>{alert(`Quiz Lab mobile web preview\n${terms.length} learning items (1,804 original + 67 reference)\nStorage: your browser only\nCloud: not connected\nBuild: 2026-10-13`)});
render();
})();