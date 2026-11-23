(() => {
'use strict';
const LANGUAGE_NAMES={en:'English',es:'Español',fr:'Français',de:'Deutsch',it:'Italiano',pt:'Português',ru:'Русский',ru_it:'Russian Latin',zh:'中文',zh_it:'Pinyin',ko:'한국어',ko_it:'Korean Latin',ja:'日本語',ja_it:'Romaji'};
const KEY='quizlab.mobile.preview.v3';const DATA_KEY='quizlab.mobile.custom.v1';const PREFERRED_KEY='quizlab.preferred.words.v1';
const safeParse=(s,def)=>{try{return JSON.parse(s)||def}catch{return def}};let preferredWords=safeParse(localStorage.getItem(PREFERRED_KEY),[]);if(!Array.isArray(preferredWords))preferredWords=[];else preferredWords=preferredWords.filter(p=>p&&p.id&&p.src&&p.dst&&p.sourceText&&p.targetText);
const initial={tab:'home',src:'en',dst:'es',instruction:'en',kind:'word',gameMode:'choice',quizLimit:10,showArticles:false,requireAccents:false,similarity:{},typingHistory:[],patternAttempts:[],writingStyle:'recall',patternReview:'mnemonic',reviewMode:'automatic',showMastered:false,excluded:[],progress:{},attempts:[],selectedOnly:true,patternSort:'alphabetical',patternSortDefaultVersion:11};
const stored=safeParse(localStorage.getItem(KEY),{});const state={...initial,...stored};if(!Array.isArray(state.patternAttempts))state.patternAttempts=[];if(!['recall','copy'].includes(state.writingStyle))state.writingStyle='recall';if(!['mnemonic','all'].includes(state.patternReview))state.patternReview='mnemonic';if(!['word','phrase'].includes(state.kind))state.kind='word';if(state.kind==='phrase'&&state.gameMode==='color')state.gameMode='choice';if(stored.patternSortDefaultVersion!==11){state.patternSort='alphabetical';state.patternSortDefaultVersion=11;}if(!['most','least','alphabetical'].includes(state.patternSort))state.patternSort='alphabetical';if(state.src===state.dst)state.dst=Object.keys(LANGUAGE_NAMES).find(k=>k!==state.src);
const ui={setupStep:1,expandedCats:new Set(),expandedSubs:new Set(),wordFilter:'',flash:null,toast:'',chosenDay:0,question:null,revealed:false,answer:-1,options:[],qIndex:0,search:'',bankFilter:'all',importStatus:'',session:null,typedHint:false,typedRevealed:false,typedEntry:'',typedSubmitted:false,patternMode:'prefix',patternSource:state.src,patternTarget:state.dst,patternKind:'word',patternFromNav:false,patternStudyBefore:null,patternFocus:'',patternSearch:'',patternCollapsed:new Set(),patternShowAll:'',patternPools:new Map(),patternBranchRoot:null,patternBranchTrail:[],patternBranchShowAll:new Set(),patternBranchPools:new Map(),patternChecked:new Map(),patternCheckPools:new Map(),wordCloudEntries:[],wordCloudSelectedKeys:new Set(),wordCloudFilter:'',wordCloudFilterMode:'prefix',wordCloudOcclusion:true,wordCloudSelectionLabels:[],wordCloudPageSize:100,wordCloudPageIndex:0,wordCloudAwaitingLibrary:false,wordCloudSpeechWanted:false,wordCloudSpeechStatus:'idle',wordCloudSpeechError:'',wordCloudSpeechRecognizer:null,wordCloudCompletedKeys:new Set(),wordCloudRemovingKeys:new Set(),wordCloudOriginalCount:0,wordCloudLastHeard:'',preferredSearch:'',preferredFilter:'all',phraseSearch:'',savedPair:'',collectionFilters:{word:{difficulties:['difficult','medium','easy','unrated'],categories:null,categorySort:'desc'},phrase:{difficulties:['difficult','medium','easy','unrated'],categories:null,categorySort:'desc'}},quizReturnTab:'home',collectionStudyBefore:null};
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
function persist(){localStorage.setItem(KEY,JSON.stringify({...state,tab:'home'}));window.dispatchEvent(new Event('quizlab:changed'))}
function excluded(){return new Set(state.excluded)}
function eligible(t){return Boolean(t.t[state.src]?.trim()&&t.t[state.dst]?.trim()&&state.src!==state.dst)&&((state.kind==='word'?t.k!=='phrase':t.k==='phrase'))}
function selected(t){return !state.excluded.includes(t.id)}
function key(t){return `language:${t.id}:${state.src}>${state.dst}`}
function prog(t){return state.progress[key(t)]||{w1:0,w2:0,w3:0,c:0,w:0,streak:0,mastered:false,start:null,next:null}}
function traffic(p){if(p.mastered)return 'green';if(p.streak>0||(p.w>0&&p.w>=p.c))return 'red';return 'yellow'}
function isDue(p){return !p.mastered&&(!p.next||Date.parse(p.next)<=Date.now())}
function stats(list){let selectedNum=0,available=0,mastered=0,wrong=0,correct=0,due=0,attempted=0;const typed=new Set((state.typingHistory||[]).filter(x=>x.mode!=='copy'&&x.src===state.src&&x.dst===state.dst&&x.kind===state.kind).map(x=>x.id));for(let t of list){if(selected(t))selectedNum++;if(eligible(t)){available++;const p=prog(t);mastered+=p.mastered?1:0;correct+=p.c;wrong+=p.w;due+=isDue(p)?1:0;attempted+=(p.c+p.w>0||typed.has(t.id))?1:0}}return {total:list.length,selected:selectedNum,available,mastered,wrong,correct,due,attempted,accuracy:correct+wrong?Math.round(100*correct/(correct+wrong)):null}}
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
function patternReset(){ui.patternFocus='';ui.patternSearch='';ui.patternCollapsed.clear();ui.patternShowAll='';ui.patternPools=new Map();ui.patternBranchRoot=null;ui.patternBranchTrail=[];ui.patternBranchShowAll.clear();ui.patternBranchPools=new Map();ui.patternChecked.clear();ui.patternCheckPools.clear()}
function patternUniqueChecked(){return [...new Map([...ui.patternChecked.values()].flat().map(t=>[t.id,t])).values()]}
function patternCheck(key,label,items){ui.patternCheckPools.set(key,items);return `<label class="pattern-selection-check" title="Add ${attr(label)} to combined quiz"><input type="checkbox" data-pattern-check="${attr(key)}" aria-label="Select ${attr(label)} for combined quiz" ${ui.patternChecked.has(key)?'checked':''}><span class="sr-only">Select ${encode(label)}</span></label>`}
function patternSelectedBar(){const count=patternUniqueChecked().length;return '<div class="pattern-selected-bar" role="region" aria-label="Combined pattern study"><span><strong>'+ui.patternChecked.size+'</strong> groups selected · <strong>'+count+'</strong> unique '+(ui.patternKind==='phrase'?'phrases':'words')+'</span><div class="pattern-selected-actions"><button class="secondary" data-pattern-selected-cloud="1" '+(count?'':'disabled')+'>Word cloud ↗</button><button class="primary" data-pattern-selected-play="1" '+(count?'':'disabled')+'>Quiz selected ↗</button><button class="secondary" data-pattern-selected-clear="1" '+(count?'':'disabled')+'>Clear</button></div></div>'}
function patternLaunch(pool){if(!pool?.length)return;ui.patternStudyBefore={src:state.src,dst:state.dst,kind:state.kind};state.src=ui.patternSource;state.dst=ui.patternTarget;state.kind=ui.patternKind;persist();startGame(pool,true)}
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
// An inline prefix/suffix trie. One selected branch table per depth keeps the
// interface compact, while every sibling node displays a distinct count.
const PATTERN_END='__pattern_end__';
function patternNextLevel(members,current,mode){
 const children=new Map(),len=Array.from(current).length;
 for(const t of members){
  const chars=Array.from(patternLetters(t));
  const next=mode==='prefix'?chars[len]:chars[chars.length-len-1];
  const child=!next?PATTERN_END:(mode==='prefix'?current+next:next+current);
  if(!children.has(child))children.set(child,[]);
  children.get(child).push(t);
 }
 // The focused graph always runs A–Z, regardless of the main-group recurrence sort.
 const compare=(a,b)=>a[0]===PATTERN_END?1:b[0]===PATTERN_END?-1:a[0].localeCompare(b[0],ui.patternSource,{sensitivity:'base'});
 return [...children].sort(compare);
}
function alphabeticPatternKey(t){
 // Ignore accents and sentence punctuation for lexical order: ¿Cómo before ¿Con and Creo before ¿Cuál.
 return patternNormalized(patternLexeme(t)).replace(/[^\p{L}\p{N}]+/gu,' ').trim();
}
function comparePatternAlphabetically(a,b){
 return alphabeticPatternKey(a).localeCompare(alphabeticPatternKey(b),ui.patternSource,{sensitivity:'base'})||
   patternNormalized(String(a.t[ui.patternTarget]||'')).localeCompare(patternNormalized(String(b.t[ui.patternTarget]||'')),ui.patternTarget,{sensitivity:'base'})||String(a.id).localeCompare(String(b.id));
}
function alphabeticPatternItems(items){return [...items].sort(comparePatternAlphabetically)}
function patternTrainingStats(items){
 const uniqueItems=new Map(items.map(t=>[t.id,t]));const ids=new Set(uniqueItems.keys());
 let practiced=0,mastered=0,due=0,stage1=0,stage2=0,stage3=0;
 for(const t of uniqueItems.values()){
  const p=state.progress[`language:${t.id}:${ui.patternSource}>${ui.patternTarget}`]||{};
  if((p.c||0)+(p.w||0)>0)practiced++;
  if(p.mastered)mastered++;
  if(p.start&&!p.mastered&&(!p.next||Date.parse(p.next)<=Date.now()))due++;
  if((p.w1||0)>=3)stage1++;
  if((p.w1||0)>=3&&(p.w2||0)>=2)stage2++;
  if(p.mastered)stage3++;
 }
 const entries=state.patternAttempts.filter(a=>ids.has(a.id)&&a.src===ui.patternSource&&a.dst===ui.patternTarget&&a.kind===ui.patternKind);
 const choice=entries.filter(a=>a.mode==='choice'),recall=entries.filter(a=>a.mode==='recall'),copy=entries.filter(a=>a.mode==='copy'),similar=entries.filter(a=>a.mode==='color');
 return {total:ids.size,practiced,mastered,due,stage1,stage2,stage3,choice,recall,copy,similar};
}
function patternStatsPanel(items){
 const x=patternTrainingStats(items),percent=x.total?100*x.mastered/x.total:0;
 const tally=a=>`${a.filter(e=>e.correct).length}/${a.length}`;
 return `<details class="pattern-memory"><summary>Mnemonic progress <strong>${x.practiced}/${x.total} practiced · ${x.mastered} mastered · ${x.due} due</strong></summary><div class="pattern-memory-content">${greenBar(percent/100)}<div class="pattern-memory-row"><span>3–2–1 milestones</span><strong>Week 1: ${x.stage1} · Week 2: ${x.stage2} · Mastered: ${x.stage3}</strong></div><div class="pattern-memory-row"><span>Pattern quiz</span><strong>${tally(x.choice)} correct</strong></div><div class="pattern-memory-row"><span>Write from memory</span><strong>${tally(x.recall)} correct</strong></div><div class="pattern-memory-row"><span>Copy spelling (model visible)</span><strong>${tally(x.copy)} completed correctly</strong></div><div class="pattern-memory-row"><span>Similarity</span><strong>${x.similar.length} ratings</strong></div><small>Copying never increases mastery. 3–2–1 is shared with your regular multiple-choice quizzes for this language direction.</small></div></details>`;
}
function writeStyleControls(){return state.gameMode!=='typing'?'':`<div class="writing-style"><span class="form-label">Writing style</span><button data-writing-style="recall" class="branch-mode ${state.writingStyle==='recall'?'selected':''}">Recall · hide answer</button><button data-writing-style="copy" class="branch-mode ${state.writingStyle==='copy'?'selected':''}">Copy · show word</button></div>`}
function mnemonicControls(){return `<div class="mnemonic-controls"><span class="form-label">Pattern review</span><button class="branch-mode ${state.patternReview==='mnemonic'?'selected':''}" data-pattern-review="mnemonic">Mnemonic · due first</button><button class="branch-mode ${state.patternReview==='all'?'selected':''}" data-pattern-review="all">All words</button><span class="form-label">Quiz rating</span><button class="branch-mode ${state.reviewMode==='automatic'?'selected':''}" data-pattern-rating="automatic">Auto</button><button class="branch-mode ${state.reviewMode==='anki'?'selected':''}" data-pattern-rating="anki">Anki</button></div>`}
function logPatternAnswer(t,mode,correct,shownAnswer=false){
 if(!ui.patternFromNav)return;
 state.patternAttempts.push({at:new Date().toISOString(),id:t.id,src:state.src,dst:state.dst,kind:t.k,mode,correct:!!correct,shown:!!shownAnswer,group:ui.session?.patternLabel||'',groupMode:ui.session?.patternMode||'',copyLang:mode==='copy'?(ui.session?.copyLang||state.dst):null});
 if(state.patternAttempts.length>30000)state.patternAttempts=state.patternAttempts.slice(-30000);
}
function copyTarget(t){return ui.session?.mode==='typing'&&ui.session?.writingStyle==='copy'&&ui.patternFromNav?shownWord(t.t[ui.session.copyLang],ui.session.copyLang,t.k):shown(t,state.dst)}
function quizLimitControl(maxCount){
 const shown=state.quizLimit===0?Math.max(1,maxCount):state.quizLimit;
 return '<div class="quiz-limit-control"><label><span class="form-label">Questions per quiz</span><input class="field quiz-limit-input" type="number" min="1" max="999999" value="'+shown+'" data-quiz-limit-input="1" aria-label="Number of questions per quiz"></label><button class="pill quiz-limit-max '+(state.quizLimit===0?'active':'')+'" data-quiz-limit-max="1">Max ('+maxCount+')</button></div>'
}
const PREFERRED_RATINGS=[{id:'difficult',label:'Hard',emoji:'🔴',className:'difficult'},{id:'medium',label:'Medium',emoji:'🟡',className:'medium'},{id:'easy',label:'Easy',emoji:'🟢',className:'easy'}];
function preferredKey(id,src,dst,kind){return JSON.stringify([String(id),String(src),String(dst),String(kind||'word')])}
function preferredFor(id,src,dst,kind){const k=preferredKey(id,src,dst,kind);return preferredWords.find(p=>preferredKey(p.id,p.src,p.dst,p.kind)===k)||null}
function preferredPersist(){localStorage.setItem(PREFERRED_KEY,JSON.stringify(preferredWords))}
function preferredButton(t,src,dst){const item=preferredFor(t.id,src,dst,t.k);return '<button type="button" class="preferred-save '+(item?'saved':'')+'" data-preferred-save="'+attr(t.id)+'" data-preferred-src="'+attr(src)+'" data-preferred-dst="'+attr(dst)+'" data-preferred-kind="'+attr(t.k)+'" aria-pressed="'+(item?'true':'false')+'" title="'+(item?'Remove from saved words':'Save word for later')+'">'+(item?'★ Saved':'☆ Save')+'</button>'}
function preferredRecord(t,src,dst,kind){return {id:String(t.id),src:src,dst:dst,kind:kind||t.k,sourceText:shown(t,src),targetText:shown(t,dst),category:t.c||'',subcategory:t.s||'',rating:null,savedAt:new Date().toISOString()}}
function togglePreferredWord(id,src,dst,kind){const k=preferredKey(id,src,dst,kind),idx=preferredWords.findIndex(p=>preferredKey(p.id,p.src,p.dst,p.kind)===k);if(idx>=0)preferredWords.splice(idx,1);else{const t=byId.get(id);if(t)preferredWords.push(preferredRecord(t,src,dst,kind));}preferredPersist()}
function setPreferredRatingForQuiz(id,src,dst,kind,rating){const k=preferredKey(id,src,dst,kind);let item=preferredWords.find(p=>preferredKey(p.id,p.src,p.dst,p.kind)===k);if(!item){const t=byId.get(id);if(!t)return;item=preferredRecord(t,src,dst,kind);preferredWords.push(item);}item.rating=rating;item.updatedAt=new Date().toISOString();preferredPersist()}
function setPreferredRatingByKey(k,rating){const item=preferredWords.find(p=>preferredKey(p.id,p.src,p.dst,p.kind)===k);if(item){item.rating=rating;item.updatedAt=new Date().toISOString();preferredPersist()}}
function preferredSavedRatingButtons(item){const k=preferredKey(item.id,item.src,item.dst,item.kind);return '<div class="preferred-rating-buttons">'+PREFERRED_RATINGS.map(r=>'<button type="button" class="preferred-rating '+r.className+' '+(item.rating===r.id?'selected':'')+'" data-preferred-rating="'+r.id+'" data-preferred-key="'+attr(k)+'" aria-pressed="'+(item.rating===r.id?'true':'false')+'" title="'+r.label+'"><span class="rating-dot"></span>'+r.label+'</button>').join('')+'</div>'}
function preferredQuizRatingButtons(t,current){return '<div class="preferred-rating-buttons">'+PREFERRED_RATINGS.map(r=>'<button type="button" class="preferred-rating '+r.className+' '+(current===r.id?'selected':'')+'" data-preferred-rate="'+r.id+'" data-preferred-id="'+attr(t.id)+'" data-preferred-src="'+attr(state.src)+'" data-preferred-dst="'+attr(state.dst)+'" data-preferred-kind="'+attr(t.k)+'" aria-pressed="'+(current===r.id?'true':'false')+'" title="Rate '+r.label+'"><span class="rating-dot"></span>'+r.label+'</button>').join('')+'</div>'}
function preferredQuizPanel(t){const item=preferredFor(t.id,state.src,state.dst,t.k),current=item?item.rating:null;return '<section class="preferred-quiz-panel"><div class="preferred-quiz-save">'+preferredButton(t,state.src,state.dst)+'<small>Saved locally in this browser</small></div><div class="preferred-quiz-rate"><span class="preferred-rate-label">Hardy</span>'+preferredQuizRatingButtons(t,current)+'</div></section>'}
const COLLECTION_DIFFICULTIES=[{id:'difficult',label:'Hard',emoji:'🔴',className:'difficult'},{id:'medium',label:'Medium',emoji:'🟡',className:'medium'},{id:'easy',label:'Easy',emoji:'🟢',className:'easy'},{id:'unrated',label:'Not rated',emoji:'⚪',className:'unrated'}];
function collectionKind(p){const t=byId.get(String(p.id));return p.kind||t?.k||'word'}
function collectionFilterState(kind){if(!ui.collectionFilters[kind])ui.collectionFilters[kind]={difficulties:COLLECTION_DIFFICULTIES.map(x=>x.id),categories:null,categorySort:'desc'};const f=ui.collectionFilters[kind];if(!Array.isArray(f.difficulties))f.difficulties=COLLECTION_DIFFICULTIES.map(x=>x.id);if(!['desc','asc'].includes(f.categorySort))f.categorySort='desc';return f}
function collectionRecords(kind){
 if(kind==='phrase')return terms.filter(t=>t.k==='phrase'&&t.t[state.src]?.trim()&&t.t[state.dst]?.trim()&&state.src!==state.dst).map(t=>{const saved=preferredFor(t.id,state.src,state.dst,'phrase');return {...preferredRecord(t,state.src,state.dst,'phrase'),...(saved||{}),id:String(t.id),src:state.src,dst:state.dst,kind:'phrase',sourceText:shown(t,state.src),targetText:shown(t,state.dst),category:t.c||'General',subcategory:t.s||'General',rating:saved?.rating||null,term:t}});
 const words=preferredWords.filter(p=>collectionKind(p)!=='phrase');
 const pairs=unique(words.map(p=>String(p.src||'')+'>'+String(p.dst||'')).filter(p=>p!=='>' )).sort();
 const preferredPair=state.src+'>'+state.dst;
 if(!ui.savedPair||!pairs.includes(ui.savedPair))ui.savedPair=pairs.includes(preferredPair)?preferredPair:(pairs[0]||'');
 const pair=ui.savedPair.split('>'),src=pair[0]||state.src,dst=pair[1]||state.dst;
 return words.filter(p=>p.src===src&&p.dst===dst).map(p=>{const t=byId.get(String(p.id));return {...p,kind:'word',term:t,category:t?.c||p.category||'General',subcategory:t?.s||p.subcategory||'General',sourceText:t?.t?.[src]?shown(t,src):p.sourceText||'',targetText:t?.t?.[dst]?shown(t,dst):p.targetText||''}});
}
function collectionApplyFilters(kind,records,search){
 const f=collectionFilterState(kind),categories=f.categories===null?null:new Set(f.categories),q=String(search||'').trim().toLocaleLowerCase();
 return records.filter(p=>f.difficulties.includes(p.rating||'unrated')&&(!categories||categories.has(p.category))&&(!q||[p.sourceText,p.targetText,langNames[p.src],langNames[p.dst],p.category,p.subcategory].join(' ').toLocaleLowerCase().includes(q)));
}
function collectionDistribution(kind,records){
 const f=collectionFilterState(kind),total=records.length,counts={};for(const r of COLLECTION_DIFFICULTIES)counts[r.id]=records.filter(p=>(p.rating||'unrated')===r.id).length;
 const percent=id=>total?100*counts[id]/total:0;
 const bars=COLLECTION_DIFFICULTIES.filter(r=>counts[r.id]>0).map(r=>'<span class="collection-bar-segment '+r.className+'" style="width:'+percent(r.id).toFixed(3)+'%"></span>').join('');
 const checks=COLLECTION_DIFFICULTIES.map(r=>'<label class="collection-difficulty-option"><input type="checkbox" data-collection-difficulty-kind="'+kind+'" data-collection-difficulty="'+r.id+'" '+(f.difficulties.includes(r.id)?'checked':'')+'><span class="collection-check-copy"><strong>'+r.emoji+' '+r.label+'</strong><small>'+counts[r.id]+' · '+percent(r.id).toFixed(2)+'%</small></span></label>').join('');
 return '<section class="collection-panel"><div class="collection-panel-head"><strong>Difficulty distribution</strong><span>'+total+' total</span></div><div class="collection-bar" role="img" aria-label="Difficulty distribution">'+bars+'</div><div class="collection-difficulty-grid">'+checks+'</div><div class="collection-filter-actions"><button type="button" class="text-button" data-collection-difficulty-all="'+kind+'">Select all</button><button type="button" class="text-button" data-collection-difficulty-clear="'+kind+'">Clear</button></div></section>';
}
function collectionCategoryFilters(kind,records,categories){
 const f=collectionFilterState(kind),counts={};for(const c of categories)counts[c]=records.filter(p=>p.category===c).length;
 const ranked=[...categories].sort((a,b)=>{const delta=counts[b]-counts[a];return (f.categorySort==='asc'?-delta:delta)||a.localeCompare(b)});
 const checks=ranked.map(c=>'<label class="collection-category-option"><input type="checkbox" data-collection-category-kind="'+kind+'" data-collection-category="'+attr(c)+'" '+(f.categories===null||f.categories.includes(c)?'checked':'')+'><span>'+encode(c)+'<small>'+counts[c]+'</small></span></label>').join('');
 const sort='<div class="collection-category-sort" role="group" aria-label="Sort categories by count"><span>Sort by count</span><button type="button" data-collection-category-sort="'+kind+'" data-collection-category-order="desc" aria-pressed="'+(f.categorySort==='desc')+'" class="'+(f.categorySort==='desc'?'active':'')+'">High → low</button><button type="button" data-collection-category-sort="'+kind+'" data-collection-category-order="asc" aria-pressed="'+(f.categorySort==='asc')+'" class="'+(f.categorySort==='asc'?'active':'')+'">Low → high</button></div>';
 return '<section class="collection-panel"><div class="collection-panel-head"><strong>Categories</strong><span>'+categories.length+' categories</span></div>'+sort+'<div class="collection-category-grid">'+(checks||'<span class="small">No categories available.</span>')+'</div><div class="collection-filter-actions"><button type="button" class="text-button" data-collection-category-all="'+kind+'">Select all</button><button type="button" class="text-button" data-collection-category-clear="'+kind+'">Clear</button></div></section>';
}
function collectionView(kind){
 const isPhrase=kind==='phrase',records=collectionRecords(kind),categories=unique(records.map(p=>p.category||'General')).sort(),search=isPhrase?ui.phraseSearch:ui.preferredSearch,filtered=collectionApplyFilters(kind,records,search),pairs=isPhrase?[]:unique(preferredWords.filter(p=>collectionKind(p)!=='phrase').map(p=>String(p.src||'')+'>'+String(p.dst||''))).sort(),pair= isPhrase?state.src+'>'+state.dst:ui.savedPair,pairParts=pair.split('>'),pairLabel=(langNames[pairParts[0]]||pairParts[0]||'—')+' → '+(langNames[pairParts[1]]||pairParts[1]||'—');
 const pairControl=isPhrase?'<div class="collection-pair-note">Language pair: <strong>'+encode(pairLabel)+'</strong> · Change it in Study</div>':pairs.length>1?'<label class="collection-pair-control"><span class="form-label">Language pair</span><select class="field" data-collection-pair="1">'+pairs.map(p=>{const x=p.split('>');return '<option value="'+attr(p)+'" '+(p===ui.savedPair?'selected':'')+'>'+encode((langNames[x[0]]||x[0])+' → '+(langNames[x[1]]||x[1]))+'</option>'}).join('')+'</select></label>':pairs.length===1?'<div class="collection-pair-note">Language pair: <strong>'+encode(pairLabel)+'</strong></div>':'<div class="collection-pair-note">No saved words yet.</div>';
 const pool=filtered.map(p=>p.term||byId.get(String(p.id))).filter(t=>t&&t.k===(isPhrase?'phrase':'word')&&t.t?.[pairParts[0]]?.trim()&&t.t?.[pairParts[1]]?.trim());
 const cards=filtered.map(item=>{const t=item.term||byId.get(String(item.id)),source=item.sourceText||(t?.t?.[item.src]?shown(t,item.src):''),target=item.targetText||(t?.t?.[item.dst]?shown(t,item.dst):''),rating=isPhrase&&t?preferredQuizRatingButtons(t,item.rating):preferredSavedRatingButtons(item),remove=isPhrase?'':'<button type="button" class="saved-word-remove" data-preferred-remove-key="'+attr(preferredKey(item.id,item.src,item.dst,item.kind))+'">Remove</button>';return '<article class="saved-word-card collection-item-card"><div class="saved-word-pair"><strong>'+encode(source)+'</strong><span>'+encode(target)+'</span></div><div class="saved-word-languages">'+encode(langNames[item.src]||item.src)+' → '+encode(langNames[item.dst]||item.dst)+'</div><div class="saved-word-context">'+encode(item.category||'General')+' / '+encode(item.subcategory||'General')+'</div><div class="collection-rating-row"><span>Difficulty</span>'+rating+'</div>'+remove+'</article>'}).join('');
 const title=isPhrase?'Phrases':'Saved words',note=isPhrase?records.length+' phrases in the phrase bank · Ratings saved in this browser':records.length+' saved words · Private to this browser',searchId=isPhrase?'phraseSearch':'preferredSearch',searchLabel=isPhrase?'Search phrases':'Search saved words',empty=records.length?'No items match the selected filters.':isPhrase?'No phrases are available for this language pair.':'Save words during a quiz or from Patterns to collect them here.';
 return heading(title)+'<p class="saved-note">'+note+'</p>'+pairControl+collectionDistribution(kind,records)+collectionCategoryFilters(kind,records,categories)+'<div class="collection-quiz-action"><button type="button" class="primary full" data-collection-start="'+kind+'" '+(pool.length?'':'disabled')+'>Start quiz · '+pool.length+'</button><span class="collection-pool-count">'+filtered.length+' selected by filters · '+pool.length+' quiz-ready</span></div><label class="saved-search"><span class="form-label">'+searchLabel+'</span><input class="field" type="search" id="'+searchId+'" value="'+attr(search)+'" placeholder="Phrase, translation or category" autocomplete="off"></label><div class="saved-word-list">'+(cards||'<div class="listempty">'+empty+'</div>')+'</div>';
}
function savedView(){return collectionView('word')}
function phrasesView(){return collectionView('phrase')}
function startCollectionQuiz(kind){
 const records=collectionRecords(kind),search=kind==='phrase'?ui.phraseSearch:ui.preferredSearch,filtered=collectionApplyFilters(kind,records,search),pair=(kind==='phrase'?state.src+'>'+state.dst:ui.savedPair).split('>'),src=pair[0]||state.src,dst=pair[1]||state.dst,pool=filtered.map(p=>p.term||byId.get(String(p.id))).filter(t=>t&&t.k===kind&&t.t?.[src]?.trim()&&t.t?.[dst]?.trim()&&src!==dst);
 if(!pool.length){alert('No '+(kind==='phrase'?'phrases':'saved words')+' match the selected difficulty, categories and language pair.');return}
 ui.collectionStudyBefore={src:state.src,dst:state.dst,kind:state.kind,gameMode:state.gameMode};
 state.src=src;state.dst=dst;state.kind=kind;if(kind==='phrase'&&state.gameMode==='color')state.gameMode='choice';
 startGame(pool,false,kind==='phrase'?'phrases':'saved');
}
function patternBranchRows(members){
 const rows=alphabeticPatternItems(members).map(t=>'<div class="pattern-word"><span><strong>'+encode(patternLexeme(t))+'</strong><small>'+encode((t.patternLocations||[t.c+' / '+t.s]).join(' · '))+'</small></span><span class="pattern-target-cell"><span>'+encode(shownWord(t.t[ui.patternTarget],ui.patternTarget,t.k))+'</span>'+preferredButton(t,ui.patternSource,ui.patternTarget)+'</span></div>');
 return rows;
}
// Focused drill-down: exactly ONE list on the left and ONE next-letter tree on the right.
// We never render ancestor/child tables simultaneously; a click replaces the focused subset.
function patternBranchView(root,members,mode){
 const kind=ui.patternKind==='phrase'?'phrases':'words';
 let path=root,items=members;
 const validTrail=[];
 for(const choice of ui.patternBranchTrail){
  if(path===PATTERN_END)break;
  const next=patternNextLevel(items,path,mode).find(([key])=>key===choice);
  if(!next)break;
  validTrail.push(choice);
  path=choice;items=next[1];
 }
 const displayLabel=k=>k===PATTERN_END?'Exact match':mode==='suffix'?'-'+k:k+'…';
 const currentLabel=path===PATTERN_END?'Exact match':displayLabel(path);
 const children=path===PATTERN_END?[]:patternNextLevel(items,path,mode);
 const listId='focused';
 ui.patternBranchPools.set(listId,items);
 const rows=patternBranchRows(items);
 const countToShow=ui.patternBranchShowAll.has(listId)?rows.length:60;
 const crumbs=[root,...validTrail].map((segment,i)=>`<button class="branch-crumb ${i===validTrail.length?'current':''}" data-pattern-branch-jump="${i}" ${i===validTrail.length?'aria-current="step"':''}>${encode(displayLabel(segment))}</button>`).join('<span class="branch-crumb-sep" aria-hidden="true">›</span>');
 const controls='<div class="branch-quick-settings" aria-label="Quiz settings"><span class="branch-controls-label">Mode</span>'+[['choice','Quiz'],['typing','Write'],['color','Similarity']].filter(([key])=>ui.patternKind==='word'||key!=='color').map(([key,name])=>'<button class="branch-mode '+(state.gameMode===key?'selected':'')+'" data-pattern-game="'+key+'">'+name+'</button>').join('')+quizLimitControl(items.length)+'</div>';
 let html=`<div class="branch-focused" aria-label="Focused pattern drill-down"><div class="branch-heading"><button class="branch-back" data-pattern-branch-up="1">← ${validTrail.length?'Back one letter':'All groups'}</button><nav class="branch-breadcrumb" aria-label="Prefix path">${crumbs}</nav></div>${controls}${writeStyleControls()}${mnemonicControls()}${patternStatsPanel(items)}<div class="branch-workspace">`;
 html+=`<section class="branch-table" aria-label="${attr(currentLabel)} vocabulary table"><div class="branch-table-head">${patternCheck('focus:'+path,currentLabel,items)}<span><strong>${encode(currentLabel)}</strong><small>${items.length} ${kind}</small></span><button class="pattern-play" data-pattern-branch-play="${listId}" aria-label="Quiz only ${attr(currentLabel)}">Play ↗</button></div>`;
 html+=`<div class="branch-table-rows">${rows.slice(0,countToShow).join('')}</div>`;
 if(rows.length>countToShow)html+=`<button class="branch-more" data-pattern-branch-all="${listId}">Show all ${rows.length} ↓</button>`;
 html+='</section>';
 html+=`<aside class="branch-graph" aria-label="Next prefix branches"><div class="branch-graph-kicker">${mode==='prefix'?'Next letter':'Previous letter'}</div><div class="branch-graph-current"><strong>${encode(currentLabel)}</strong><span>${items.length}</span></div>`;
 if(children.length){
  html+='<div class="branch-graph-nodes">';
  for(const [child,subset] of children){
   const letter=child===PATTERN_END?'■':mode==='prefix'?Array.from(child).at(-1):Array.from(child)[0];
   // Show both analyzed-language entries and selected target-language translations
   // directly under each next-letter branch. Same pairing and sorting as the left table.
   const names=alphabeticPatternItems(subset).map(t=>'<li class="branch-node-word"><span class="branch-node-source">'+encode(patternLexeme(t))+'</span><span class="branch-node-target">'+encode(shownWord(t.t[ui.patternTarget],ui.patternTarget,t.k))+'</span>'+preferredButton(t,ui.patternSource,ui.patternTarget)+'</li>').join('');
   html+=`<div class="branch-node-card"><div class="branch-node-head">${patternCheck('branch:'+path+':'+child,displayLabel(child),subset)}<button class="branch-node" data-pattern-branch-choice="${attr(child)}" aria-label="Focus ${attr(displayLabel(child))}, ${subset.length} ${kind}"><span class="branch-node-letter">${encode(letter)}</span><strong>${encode(displayLabel(child))}</strong><span class="branch-node-count">${subset.length}</span><span class="branch-node-arrow" aria-hidden="true">›</span></button></div><ul class="branch-node-words" aria-label="${attr(displayLabel(child))}: ${subset.length} alphabetical ${kind}">${names}</ul></div>`;
  }
  html+='</div>';
 }else html+='<div class="branch-terminal">No more letters to split</div>';
 html+='</aside></div></div>';
 return html;
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
 for(const members of groupMap.values())members.sort(comparePatternAlphabetically);
 const groups=[...groupMap.entries()].filter(([,arr])=>arr.length).sort((a,b)=>
  state.patternSort==='most'?b[1].length-a[1].length||baseCompare(a,b):
  state.patternSort==='least'?a[1].length-b[1].length||baseCompare(a,b):baseCompare(a,b));
 ui.patternPools=new Map(groups.map(([,arr],i)=>[String(i),arr]));ui.patternBranchPools=new Map();ui.patternCheckPools=new Map();
 if(nested&&ui.patternBranchRoot!==null){
  const focused=groups.find(([key])=>key===ui.patternBranchRoot);
  if(focused)return html+'</div>'+patternSelectedBar()+patternBranchView(focused[0],focused[1],mode);
  ui.patternBranchRoot=null;ui.patternBranchTrail=[];
 }
 html+=`</div>${patternSelectedBar()}<div class="pattern-game-settings"><div class="section">Quiz mode</div><div class="pillset">${[['choice','Quiz'],['typing','Write'],['color','Similarity']].filter(([key])=>ui.patternKind==='word'||key!=='color').map(([key,name])=>`<button class="pill ${state.gameMode===key?'active':''}" data-pattern-game="${key}">${name}</button>`).join('')}</div>${quizLimitControl(relevant.length)}${writeStyleControls()}${mnemonicControls()}${patternStatsPanel(relevant)}</div><div class="pattern-results-header"><div class="pattern-results-label"><strong>${relevant.length} matching ${ui.patternKind==='phrase'?'phrases':'words'}</strong><span class="small">${groups.length} groups</span></div><label class="pattern-sort-label"><span class="form-label">Sort pattern groups</span><select class="field pattern-sort-select" aria-label="Sort pattern groups by occurrences" data-pattern-sort="1"><option value="most" ${state.patternSort==='most'?'selected':''}>Most recurring ↓</option><option value="least" ${state.patternSort==='least'?'selected':''}>Least recurring ↑</option><option value="alphabetical" ${state.patternSort==='alphabetical'?'selected':''}>A–Z / Number ↑</option></select></label></div>`;
 if(nested&&ui.patternFocus)html+=`<button class="text-button pattern-path" data-pattern-back="1">← ${encode(ui.patternFocus)} · Back one letter</button>`;
 if(!groups.length)return html+'<div class="listempty">No matches for this language pair. Try another translation language or pattern.</div>';
 html+='<div class="pattern-groups">';
 for(let i=0;i<groups.length;i++){
  const [g,list]=groups[i],id=String(i),open=!ui.patternCollapsed.has(g);
  const label=mode==='suffix'?'-'+g:mode==='prefix'?g:mode==='length'?`${g} ${g==='1'?'letter':'letters'}`:`${g} ${g==='1'?'word':'words'}`;
  const canDrill=nested&&list.some(t=>Array.from(patternLetters(t)).length>Array.from(g).length);
  const preview=list.slice(0,open?(ui.patternShowAll===g?list.length:60):3);
  const branchActive=ui.patternBranchRoot===g;
  html+=`<article class="pattern-group"><div class="pattern-group-head">${patternCheck('root:'+g,label,list)}<button class="pattern-group-name" ${canDrill?`data-pattern-split="${attr(g)}" aria-label="Explore next letters for ${attr(label)}"`:`data-pattern-expand="${attr(g)}" aria-expanded="${open}" aria-label="Show words for ${attr(label)}"` }><strong>${encode(label)}</strong><span>${list.length} ${ui.patternKind==='phrase'?'phrases':'words'}</span><span class="pattern-arrow">${open?'−':'+'}</span></button>${canDrill?`<button class="pattern-split ${branchActive?'active':''}" data-pattern-split="${attr(g)}" aria-label="Branch ${attr(label)} by next letter" aria-expanded="${branchActive&&open}">↳ Split</button>`:''}<button class="pattern-play" data-pattern-play="${id}" aria-label="Start quiz for ${attr(label)}">Play ↗</button></div>`;
  if(open){html+='<div class="pattern-words">';for(const t of preview){html+=`<div class="pattern-word"><span><strong>${encode(patternLexeme(t))}</strong><small>${encode((t.patternLocations||[`${t.c} / ${t.s}`]).join(' · '))}</small></span><span class="pattern-target-cell"><span>${encode(shownWord(t.t[ui.patternTarget],ui.patternTarget,t.k))}</span>${preferredButton(t,ui.patternSource,ui.patternTarget)}</span></div>`}if(list.length>60&&ui.patternShowAll!==g)html+=`<button class="pattern-deeper" data-pattern-all="${attr(g)}">Show all ${list.length} ${ui.patternKind==='phrase'?'phrases':'words'} ↓</button>`;
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
 ${writeStyleControls()}${quizLimitControl(count)}
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
 const pastPatterns=state.patternAttempts||[];
 const byPatternMode=(m)=>pastPatterns.filter(x=>x.mode===m);
 const patternDirection=[...new Set(pastPatterns.map(x=>`${x.src}→${x.dst}`))].sort();
 const copying=typing.filter(x=>x.mode==='copy');const recallTyping=typing.filter(x=>x.mode!=='copy');const savedHardy={difficult:preferredWords.filter(p=>p.rating==='difficult').length,medium:preferredWords.filter(p=>p.rating==='medium').length,easy:preferredWords.filter(p=>p.rating==='easy').length};
 return `${heading('Progress')}
 <div class="pillset">${[['word','Words'],['phrase','Phrases']].map(([k,v])=>`<button class="pill ${state.kind===k?'active':''}" data-kind="${k}">${v}</button>`).join('')}</div>
 <div class="kpis progress-kpis"><div class="kpi"><strong>${st.attempted}</strong><span>Practiced</span></div><div class="kpi"><strong>${st.mastered}</strong><span>Mastered</span></div><div class="kpi"><strong>${st.available-st.attempted}</strong><span>Not practiced</span></div></div>
 <div class="section">By category</div><div class="category-stats-grid">${cats.map(c=>{const x=stats(active.filter(t=>t.c===c));return `<div class="card flat statsitem"><div class="row spread"><strong>${encode(c)}</strong><span class="tiny-count">${x.attempted}/${x.total}</span></div><div class="small">${x.mastered} mastered</div>${greenBar(x.total?x.attempted/x.total:0)}<details><summary>Subcategories</summary>${unique(active.filter(t=>t.c===c).map(t=>t.s)).sort().map(sub=>{const y=stats(active.filter(t=>t.c===c&&t.s===sub));return `<div class="row spread stat-sub"><span>${encode(sub)}</span><span>${y.attempted}/${y.total} · ${y.mastered} mastered</span></div>`}).join('')}</details></div>`}).join('')||'<div class="small">Nothing selected yet.</div>'}</div>
 <div class="section">Performance</div><div class="stats-sections">
 <details class="card detail-card"><summary>Quiz accuracy <strong>${st.accuracy===null?'Not tested':st.accuracy+'%'}</strong></summary><div class="small">${st.correct} correct · ${st.wrong} wrong</div>${cats.map(c=>{const x=stats(active.filter(t=>t.c===c));return `<div class="row spread stat-sub"><span>${encode(c)}</span><span>${x.accuracy===null?'—':x.accuracy+'%'} · ${x.correct+x.wrong} answers</span></div>`}).join('')}</details>
 <details class="card detail-card"><summary>Written recall <strong>${recallTyping.length} attempts</strong></summary><div class="small">${recallTyping.filter(x=>x.correct).length} correct · ${recallTyping.filter(x=>!x.correct&&!x.shown).length} wrong · ${recallTyping.filter(x=>x.shown).length} revealed</div></details>
 <details class="card detail-card"><summary>Copy spelling <strong>${copying.length} attempts</strong></summary><div class="small">${copying.filter(x=>x.correct).length} accurate copies · ${copying.filter(x=>!x.correct&&!x.shown).length} spelling errors · ${copying.filter(x=>x.shown).length} skipped. Not counted toward mastery.</div></details>
 <details class="card detail-card"><summary>Patterns training <strong>${pastPatterns.length} interactions</strong></summary><div class="small">Quiz: ${byPatternMode('choice').length} · Recall: ${byPatternMode('recall').length} · Copy: ${byPatternMode('copy').length} · Similarity: ${byPatternMode('color').length}</div>${patternDirection.map(d=>`<div class="row spread stat-sub"><span>${encode(d)}</span><strong>${pastPatterns.filter(x=>`${x.src}→${x.dst}`===d).length} interactions</strong></div>`).join('')}</details>
 <details class="card detail-card"><summary>Saved words <strong>${preferredWords.length}</strong></summary><div class="small">Stored only in this browser · 🔴 ${savedHardy.difficult} hard · 🟡 ${savedHardy.medium} medium · 🟢 ${savedHardy.easy} easy</div></details>
 <details class="card detail-card"><summary>Similarity <strong>${active.filter(t=>state.similarity[similarityKey(t)]).length} rated</strong></summary>${[['green','Very similar'],['yellow','Similar'],['red','Different'],['neutral','Neutral']].map(([k,v])=>`<div class="row spread stat-sub"><span>${v}</span><strong>${active.filter(t=>state.similarity[similarityKey(t)]===k).length}</strong></div>`).join('')}</details>
 <details class="card detail-card"><summary>Most missed <strong>${rank.length}</strong></summary>${rank.map(t=>`<div class="stat-sub"><strong>${encode(shown(t,state.src))} → ${encode(shown(t,state.dst))}</strong><span class="small"> · ${prog(t).w} wrong</span></div>`).join('')||'<div class="small">None yet</div>'}</details>
 </div>`;
}
function howManyOptions(t,pool){const right=shown(t,state.dst),a=pool.filter(x=>x.id!==t.id&&shown(x,state.dst)!==right).sort((x,y)=>Number(x.c!==t.c)-Number(y.c!==t.c));const opts=[right];let candidates=shuffle(a);candidates.sort((x,y)=>Number(x.c!==t.c)-Number(y.c!==t.c));for(const c of candidates){if(opts.length>=4)break;const v=shown(c,state.dst);if(v&&!opts.includes(v))opts.push(v)}return shuffle(opts)}
function shuffle(a){a=[...a];for(let i=a.length-1;i>0;i--){const j=Math.floor(Math.random()*(i+1));[a[i],a[j]]=[a[j],a[i]]}return a}

function openPatternWordCloud(selectedPool){
 stopWordCloudSpeech();
 const all=patternPool(),chosen=Array.isArray(selectedPool)?selectedPool:[];
 if(!all.length||!chosen.length)return;
 const grouped=new Map();
 for(const t of all){
  const source=String(patternLexemeForLang(t,ui.patternSource)||'').trim();
  const key=patternIdentity(source);
  if(!key)continue;
  if(!grouped.has(key))grouped.set(key,{key,text:source,ids:[],translations:[],speechTranslations:[],locations:[]});
  const entry=grouped.get(key);
  if(!entry.ids.includes(t.id))entry.ids.push(t.id);
  const target=String(t.t[ui.patternTarget]||'').trim();
  if(target&&!entry.translations.some(x=>patternIdentity(x)===patternIdentity(target)))entry.translations.push(target);
  const speechTarget=shownWord(t.t[ui.patternTarget],ui.patternTarget,t.k);
  if(speechTarget&&!entry.speechTranslations.some(x=>matchingForm(x)===matchingForm(speechTarget)))entry.speechTranslations.push(speechTarget);
  const nativeTargetLang=ui.patternTarget.endsWith('_it')?ui.patternTarget.slice(0,-3):'';
  if(nativeTargetLang){
   const nativeTarget=shownWord(t.t[nativeTargetLang],nativeTargetLang,t.k);
   if(nativeTarget&&!entry.speechTranslations.some(x=>matchingForm(x)===matchingForm(nativeTarget)))entry.speechTranslations.push(nativeTarget);
  }
  for(const location of (t.patternLocations||[t.c+' / '+t.s]))if(!entry.locations.includes(location))entry.locations.push(location);
 }
 ui.wordCloudEntries=[...grouped.values()].sort((a,b)=>a.text.localeCompare(b.text,ui.patternSource,{sensitivity:'base'}));
 ui.wordCloudEntries.forEach((entry,index)=>entry.index=index);
 ui.wordCloudSelectedKeys=new Set(chosen.map(t=>patternIdentity(patternLexemeForLang(t,ui.patternSource))).filter(Boolean));
 ui.wordCloudFilter='';
 ui.wordCloudFilterMode=ui.patternMode;
 ui.wordCloudOcclusion=true;
 ui.wordCloudSelectionLabels=[...ui.patternChecked.keys()].map(k=>k.replace(/^(root:|focus:|branch:)/,'').replace(/:/g,' → ')).filter(Boolean);
 ui.wordCloudPageSize=ui.patternKind==='phrase'?50:100;
 ui.wordCloudPageIndex=0;
 ui.wordCloudCompletedKeys=new Set();
 ui.wordCloudRemovingKeys=new Set();
 ui.wordCloudOriginalCount=ui.wordCloudEntries.length;
 ui.wordCloudLastHeard='';
 ui.wordCloudSpeechError='';
 ui.wordCloudSpeechStatus='idle';
 ui.wordCloudSpeechWanted=false;
 ui.wordCloudSpeechRecognizer=null;
 state.tab='wordcloud';
 render();
 window.scrollTo({top:0,behavior:'instant'});
 view.scrollTop=0;
}
function wordCloudFilterLabel(){
 return ({prefix:'Starts with',suffix:'Ends with',length:'Letters',words:'Word count'})[ui.wordCloudFilterMode]||'Starts with';
}
function wordCloudActiveKeys(){
 const remaining=new Set(ui.wordCloudEntries.map(entry=>entry.key));
 const raw=String(ui.wordCloudFilter||'').trim();
 if(!raw)return new Set([...ui.wordCloudSelectedKeys].filter(key=>remaining.has(key)));
 const mode=ui.wordCloudFilterMode||'prefix';
 const q=patternNormalized(raw);
 if(!q)return new Set([...ui.wordCloudSelectedKeys].filter(key=>remaining.has(key)));
 return new Set(ui.wordCloudEntries.filter(entry=>{
  const letters=patternNormalized(entry.text).replace(/[^\p{L}\p{N}]/gu,'');
  if(mode==='prefix')return letters.startsWith(q.replace(/[^\p{L}\p{N}]/gu,''));
  if(mode==='suffix')return letters.endsWith(q.replace(/[^\p{L}\p{N}]/gu,''));
  if(mode==='length')return letters.length===Number(q);
  const count=(entry.text.match(/[\p{L}\p{N}]+(?:['’][\p{L}\p{N}]+)*/gu)||[]).length;
  return count===Number(q);
 }).map(entry=>entry.key));
}
function wordCloudPageCount(){
 return Math.ceil((ui.wordCloudEntries||[]).length/(ui.wordCloudPageSize||100));
}
function wordCloudCurrentPageEntries(){
 const start=(ui.wordCloudPageIndex||0)*(ui.wordCloudPageSize||100);
 return (ui.wordCloudEntries||[]).slice(start,start+(ui.wordCloudPageSize||100));
}
function updateWordCloudPager(){
 const pages=wordCloudPageCount();
 ui.wordCloudPageIndex=Math.max(0,Math.min(ui.wordCloudPageIndex||0,Math.max(0,pages-1)));
 view.querySelectorAll('[data-wordcloud-sheet]').forEach((sheet,index)=>sheet.classList.toggle('active',index===ui.wordCloudPageIndex));
 const info=document.getElementById('wordCloudPageInfo');
 if(info){
  const start=pages?ui.wordCloudPageIndex*(ui.wordCloudPageSize||100)+1:0;
  const end=Math.min((ui.wordCloudPageIndex+1)*(ui.wordCloudPageSize||100),ui.wordCloudEntries.length);
  info.textContent=pages?'Page '+(ui.wordCloudPageIndex+1)+' of '+pages+' · '+start+'–'+end+' of '+ui.wordCloudEntries.length:'No pages';
 }
 const prev=view.querySelector('[data-wordcloud-page="prev"]');
 const next=view.querySelector('[data-wordcloud-page="next"]');
 if(prev)prev.disabled=ui.wordCloudPageIndex<=0;
 if(next)next.disabled=ui.wordCloudPageIndex>=pages-1;
}

function applyWordCloudOcclusion(){
 if(state.tab!=='wordcloud')return;
 const active=wordCloudActiveKeys();
 view.querySelectorAll('[data-cloud-key]').forEach(node=>{
  const revealed=active.has(node.getAttribute('data-cloud-key'));
  node.classList.toggle('revealed',revealed);
  node.classList.toggle('occluded',ui.wordCloudOcclusion&&!revealed);
  node.setAttribute('aria-pressed',revealed?'true':'false');
 });
 const stats=document.getElementById('wordCloudStats');
 if(stats)stats.textContent=active.size+' highlighted · '+Math.max(0,ui.wordCloudEntries.length-active.size)+' occluded · '+ui.wordCloudEntries.length+' remaining · '+(ui.wordCloudCompletedKeys?.size||0)+' spoken';
}
function updateWordCloudControls(){
 view.querySelectorAll('[data-wordcloud-mode]').forEach(button=>button.classList.toggle('active',button.dataset.wordcloudMode===ui.wordCloudFilterMode));
 const label=document.getElementById('wordCloudFilterLabel');
 if(label)label.textContent=wordCloudFilterLabel();
 const input=document.getElementById('wordCloudFilter');
 if(input)input.placeholder=ui.wordCloudFilterMode==='prefix'?'e.g. ab':ui.wordCloudFilterMode==='suffix'?'e.g. ente':'e.g. 2';
}
function wordCloudView(){
 const entries=ui.wordCloudEntries||[];
 const pageSize=ui.wordCloudPageSize||100;
 const pageCount=Math.ceil(entries.length/pageSize);
 const pageIndex=Math.max(0,Math.min(ui.wordCloudPageIndex||0,Math.max(0,pageCount-1)));
 const pair=(langNames[ui.patternSource]||ui.patternSource)+' → '+(langNames[ui.patternTarget]||ui.patternTarget);
 const kind=ui.patternKind==='phrase'?'phrases':'words';
 const modes=[['prefix','Starts with'],['suffix','Ends with'],['length','Letters'],['words','Word count']];
 const modeButtons=modes.map(([key,label])=>'<button type="button" class="pill '+(ui.wordCloudFilterMode===key?'active':'')+'" data-wordcloud-mode="'+key+'">'+label+'</button>').join('');
 const labels=ui.wordCloudSelectionLabels.length?ui.wordCloudSelectionLabels.join(' · '):'Selected pattern groups';
 const pages=[];
 for(let i=0;i<pageCount;i++){
  pages.push('<section class="wordcloud-sheet '+(i===pageIndex?'active':'')+'" data-wordcloud-sheet="'+i+'"><header class="wordcloud-sheet-header"><span>'+encode(pair)+'</span><small>'+encode(labels)+' · Page '+(i+1)+' / '+pageCount+'</small></header><svg class="wordcloud-svg" data-wordcloud-svg="'+i+'" viewBox="0 0 1180 700" role="img" aria-label="Word cloud page '+(i+1)+'"></svg><div class="wordcloud-fallback" data-wordcloud-fallback="'+i+'" aria-label="Word cloud words"></div><div class="wordcloud-overflow" data-wordcloud-overflow="'+i+'"></div><footer class="wordcloud-sheet-footer">Quiz Lab · '+encode(kind)+' · '+entries.length+' unique source terms</footer></section>');
 }
 const placeholder=ui.wordCloudFilterMode==='prefix'?'e.g. ab':ui.wordCloudFilterMode==='suffix'?'e.g. ente':'e.g. 2';
 const speechSupported=wordCloudSpeechSupported();
 const speechButton=ui.wordCloudSpeechWanted?'■ Stop listening':'🎙 Start speaking';
 const noWords=ui.wordCloudCompletedKeys.size
  ?'<div class="listempty">All done — '+ui.wordCloudCompletedKeys.size+' words recognized. You can go back to Patterns or start another cloud.</div>'
  :'<div class="listempty">No words are available for this language pair.</div>';
 return '<div class="wordcloud-view wordcloud-fullscreen" id="wordCloudFullscreen">'+
  '<header class="wordcloud-toolbar no-print">'+
   '<div class="wordcloud-title-group"><button type="button" class="ghost" data-wordcloud-back="1">← Patterns</button><div><div class="eyebrow wordcloud-eyebrow">PATTERN STUDY MODE</div><h1 class="h1">Word cloud</h1><small>'+encode(pair)+'</small></div></div>'+
   '<div class="wordcloud-top-actions"><div class="wordcloud-speech-copy"><strong>Speak in '+encode(langNames[ui.patternTarget]||ui.patternTarget)+'</strong><small>Say a visible word’s translation. It turns green, then disappears.</small></div><button type="button" class="primary wordcloud-speech-button" data-wordcloud-speech-toggle="1" aria-pressed="'+(ui.wordCloudSpeechWanted?'true':'false')+'" '+(!speechSupported?'disabled':'')+'>'+speechButton+'</button><button type="button" class="primary wordcloud-print" data-wordcloud-print="1">Print A4 ↗</button></div>'+
  '</header>'+
  '<div class="wordcloud-speech-status no-print" id="wordCloudSpeechStatus" role="status" aria-live="polite">'+encode(wordCloudSpeechMessage())+'</div>'+
  '<section class="wordcloud-filter-panel no-print"><div class="wordcloud-mode-buttons" role="group" aria-label="Word cloud filter mode">'+modeButtons+'</div><label class="wordcloud-query-label"><span id="wordCloudFilterLabel">'+wordCloudFilterLabel()+'</span><input id="wordCloudFilter" class="field" type="search" value="'+attr(ui.wordCloudFilter)+'" placeholder="'+placeholder+'" autocomplete="off" spellcheck="false"></label><div class="wordcloud-filter-actions"><label class="wordcloud-occlusion-toggle"><input type="checkbox" data-wordcloud-occlusion="1" '+(ui.wordCloudOcclusion?'checked':'')+'> Dim words outside the filter</label><button type="button" class="text-button" data-wordcloud-clear="1">Reset to selected patterns</button></div></section>'+
  '<div class="wordcloud-info-row no-print"><div class="wordcloud-stats" id="wordCloudStats"></div><div class="wordcloud-detail" id="wordCloudDetail" aria-live="polite"><span>Click a word to reveal its translation.</span></div>'+
  (entries.length?'<div class="wordcloud-pager"><button type="button" class="secondary" data-wordcloud-page="prev" '+(pageIndex===0?'disabled':'')+'>← Previous</button><strong id="wordCloudPageInfo">Page '+(pageIndex+1)+' of '+pageCount+'</strong><button type="button" class="secondary" data-wordcloud-page="next" '+(pageIndex>=pageCount-1?'disabled':'')+'>Next →</button></div>':'')+
  '</div>'+
  (entries.length?'<main class="wordcloud-stage"><div class="wordcloud-pages" id="wordCloudPages">'+pages.join('')+'</div></main>':'<main class="wordcloud-stage">'+noWords+'</main>')+
 '</div>';
}
function wordCloudShowDetail(index){
 const entry=ui.wordCloudEntries[index],detail=document.getElementById('wordCloudDetail');
 if(!entry||!detail)return;
 const translations=entry.translations.length?entry.translations.join(' · '):'No translation available';
 const locations=entry.locations.slice(0,5).join(' · ')+(entry.locations.length>5?' · +'+(entry.locations.length-5)+' more':'');
 detail.innerHTML='<strong>'+encode(entry.text)+'</strong><span>'+encode(translations)+'</span><small>'+encode(locations)+'</small>';
}

function wordCloudSpeechSupported(){
 return typeof window.SpeechRecognition==='function'||typeof window.webkitSpeechRecognition==='function';
}
function wordCloudSpeechLocale(){
 const code=String(ui.patternTarget||'en').replace(/_it$/,'');
 const locales={en:'en-US',es:'es-ES',fr:'fr-FR',de:'de-DE',it:'it-IT',pt:'pt-PT',ru:'ru-RU',zh:'zh-CN',ko:'ko-KR',ja:'ja-JP'};
 return locales[code]||code;
}
function wordCloudSpeechMessage(){
 if(ui.wordCloudSpeechError)return ui.wordCloudSpeechError;
 if(!wordCloudSpeechSupported())return 'Speech recognition is not available in this browser. Try Chrome or Edge.';
 const language=langNames[ui.patternTarget]||ui.patternTarget;
 if(ui.wordCloudSpeechWanted)return 'Listening in '+language+'… say a translation. '+(ui.wordCloudLastHeard?'Last: '+ui.wordCloudLastHeard:'');
 return ui.wordCloudLastHeard||'Microphone off. Start speaking to practise '+language+'.';
}
function updateWordCloudSpeechControls(){
 const button=view.querySelector('[data-wordcloud-speech-toggle]');
 if(button){
  button.disabled=!wordCloudSpeechSupported()&&!ui.wordCloudSpeechWanted;
  button.textContent=ui.wordCloudSpeechWanted?'■ Stop listening':'🎙 Start speaking';
  button.classList.toggle('listening',ui.wordCloudSpeechWanted);
  button.setAttribute('aria-pressed',ui.wordCloudSpeechWanted?'true':'false');
 }
 const status=document.getElementById('wordCloudSpeechStatus');
 if(status)status.textContent=wordCloudSpeechMessage();
}
function wordCloudSpeechTokens(value){
 return (String(value||'').normalize('NFC').toLocaleLowerCase().match(/[\p{L}\p{N}]+(?:['’][\p{L}\p{N}]+)*/gu)||[]).map(matchingForm).filter(Boolean);
}
function speechTranscriptMatches(transcript,translation){
 const targetText=String(translation||'').trim();
 const targetTokens=wordCloudSpeechTokens(targetText);
 if(!targetTokens.length)return false;
 const hasCompactScript=/[\p{Script=Han}\p{Script=Hiragana}\p{Script=Katakana}\p{Script=Hangul}]/u.test(targetText);
 if(hasCompactScript){
  const heard=matchingForm(transcript),target=matchingForm(targetText);
  return target.length>1?heard.includes(target):heard===target;
 }
 const heardTokens=wordCloudSpeechTokens(transcript);
 if(targetTokens.length>heardTokens.length)return false;
 for(let i=0;i<=heardTokens.length-targetTokens.length;i++){
  let matches=true;
  for(let j=0;j<targetTokens.length;j++)if(heardTokens[i+j]!==targetTokens[j]){matches=false;break;}
  if(matches)return true;
 }
 return false;
}
function findWordCloudSpeechMatch(transcript){
 const matches=[];
 for(const entry of wordCloudCurrentPageEntries()){
  if(ui.wordCloudCompletedKeys.has(entry.key)||ui.wordCloudRemovingKeys.has(entry.key))continue;
  const translations=entry.speechTranslations?.length?entry.speechTranslations:entry.translations;
  for(const translation of translations){
   if(speechTranscriptMatches(transcript,translation)){
    matches.push({entry,translation,wordCount:wordCloudSpeechTokens(translation).length});
    break;
   }
  }
 }
 if(!matches.length)return null;
 matches.sort((a,b)=>Number(ui.wordCloudSelectedKeys.has(b.entry.key))-Number(ui.wordCloudSelectedKeys.has(a.entry.key))||b.wordCount-a.wordCount||a.entry.index-b.entry.index);
 return matches[0];
}
function markWordCloudSpoken(match,transcript){
 const {entry,translation}=match||{};
 if(!entry||ui.wordCloudRemovingKeys.has(entry.key)||ui.wordCloudCompletedKeys.has(entry.key))return;
 ui.wordCloudRemovingKeys.add(entry.key);
 ui.wordCloudLastHeard='✓ '+translation+' → '+entry.text;
 const detail=document.getElementById('wordCloudDetail');
 if(detail)detail.innerHTML='<strong>✓ '+encode(entry.text)+'</strong><span>'+encode(translation)+'</span><small>Recognized: '+encode(transcript)+'</small>';
 view.querySelectorAll('[data-cloud-key]').forEach(node=>{
  if(node.getAttribute('data-cloud-key')!==entry.key)return;
  node.classList.remove('revealed','occluded');
  node.classList.add('spoken');
  node.setAttribute('aria-pressed','true');
 });
 updateWordCloudSpeechControls();
 window.setTimeout(()=>{
  if(!ui.wordCloudRemovingKeys.has(entry.key))return;
  ui.wordCloudCompletedKeys.add(entry.key);
  ui.wordCloudRemovingKeys.delete(entry.key);
  ui.wordCloudSelectedKeys.delete(entry.key);
  ui.wordCloudEntries=ui.wordCloudEntries.filter(item=>item.key!==entry.key);
  ui.wordCloudEntries.forEach((item,index)=>item.index=index);
  ui.wordCloudPageIndex=Math.min(ui.wordCloudPageIndex,Math.max(0,wordCloudPageCount()-1));
  if(!ui.wordCloudEntries.length)stopWordCloudSpeech();
  if(state.tab==='wordcloud')render();
 },700);
}
function startWordCloudSpeech(){
 const Recognition=window.SpeechRecognition||window.webkitSpeechRecognition;
 if(!Recognition){
  ui.wordCloudSpeechError='Speech recognition is not available in this browser. Try Chrome or Edge.';
  ui.wordCloudSpeechStatus='error';
  updateWordCloudSpeechControls();
  return;
 }
 if(ui.wordCloudSpeechWanted)return;
 const recognition=new Recognition();
 recognition.lang=wordCloudSpeechLocale();
 recognition.continuous=true;
 recognition.interimResults=false;
 recognition.maxAlternatives=4;
 ui.wordCloudSpeechRecognizer=recognition;
 ui.wordCloudSpeechWanted=true;
 ui.wordCloudSpeechStatus='listening';
 ui.wordCloudSpeechError='';
 ui.wordCloudLastHeard='';
 recognition.onstart=()=>{
  if(ui.wordCloudSpeechRecognizer===recognition&&ui.wordCloudSpeechWanted){
   ui.wordCloudSpeechStatus='listening';
   updateWordCloudSpeechControls();
  }
 };
 recognition.onresult=e=>{
  if(!ui.wordCloudSpeechWanted||state.tab!=='wordcloud')return;
  for(let i=e.resultIndex||0;i<e.results.length;i++){
   const result=e.results[i];
   if(!result.isFinal)continue;
   let match=null,transcript='';
   for(let j=0;j<result.length;j++){
    const heard=result[j].transcript||'';
    const found=findWordCloudSpeechMatch(heard);
    if(found){match=found;transcript=heard;break;}
   }
   if(match)markWordCloudSpoken(match,transcript);
   else{
    transcript=result[0]?.transcript||'';
    if(transcript.trim())ui.wordCloudLastHeard='Heard: '+transcript.trim()+' · no matching word yet';
    updateWordCloudSpeechControls();
   }
  }
 };
 recognition.onerror=e=>{
  if(ui.wordCloudSpeechRecognizer!==recognition)return;
  const messages={
   'not-allowed':'Microphone access was denied. Allow microphone access for this site and try again.',
   'service-not-allowed':'The browser blocked its speech-recognition service.',
   'audio-capture':'No microphone was found. Check your audio input.',
   'network':'Speech recognition failed to connect. Check your internet connection.',
   'language-not-supported':'Speech recognition is unavailable for this target language in this browser.'
  };
  if(e.error==='no-speech'){
   ui.wordCloudLastHeard='No speech detected yet — keep speaking.';
   updateWordCloudSpeechControls();
   return;
  }
  ui.wordCloudSpeechError=messages[e.error]||'Speech recognition error: '+(e.error||'unknown');
  ui.wordCloudSpeechStatus='error';
  ui.wordCloudSpeechWanted=false;
  updateWordCloudSpeechControls();
 };
 recognition.onend=()=>{
  if(ui.wordCloudSpeechRecognizer!==recognition||!ui.wordCloudSpeechWanted||state.tab!=='wordcloud')return;
  ui.wordCloudSpeechStatus='listening';
  updateWordCloudSpeechControls();
  window.setTimeout(()=>{
   if(ui.wordCloudSpeechRecognizer!==recognition||!ui.wordCloudSpeechWanted||state.tab!=='wordcloud')return;
   try{recognition.start();}
   catch(error){
    ui.wordCloudSpeechError='Could not restart listening. Press Start speaking again.';
    ui.wordCloudSpeechStatus='error';
    ui.wordCloudSpeechWanted=false;
    ui.wordCloudSpeechRecognizer=null;
    updateWordCloudSpeechControls();
   }
  },350);
 };
 try{
  recognition.start();
  updateWordCloudSpeechControls();
 }catch(error){
  ui.wordCloudSpeechWanted=false;
  ui.wordCloudSpeechRecognizer=null;
  ui.wordCloudSpeechStatus='error';
  ui.wordCloudSpeechError='Could not start the microphone. Check browser permissions and try again.';
  updateWordCloudSpeechControls();
 }
}
function stopWordCloudSpeech(){
 ui.wordCloudSpeechWanted=false;
 const recognition=ui.wordCloudSpeechRecognizer;
 ui.wordCloudSpeechRecognizer=null;
 if(recognition){
  recognition.onend=null;
  try{recognition.stop();}catch(error){}
 }
 ui.wordCloudSpeechStatus='idle';
 ui.wordCloudSpeechError='';
 updateWordCloudSpeechControls();
}

// Uses the same d3-cloud@1 layout API as the Observable D3 word-cloud notebook.
function renderWordCloudFallback(sheet,words,active,onlyMissing=false){
 const fallback=sheet.querySelector('.wordcloud-fallback');
 const overflow=sheet.querySelector('.wordcloud-overflow');
 const target=onlyMissing?overflow:fallback;
 if(!target)return;
 if(!onlyMissing){
  sheet.classList.add('use-fallback');
  const svg=sheet.querySelector('svg');
  if(svg)svg.style.display='none';
 }
 target.innerHTML='';
 for(const word of words){
  const entry=word.entry;
  const revealed=active.has(entry.key);
  const node=document.createElement('span');
  node.className='cloud-word-fallback'+(revealed?' revealed':(ui.wordCloudOcclusion?' occluded':''));
  node.dataset.cloudKey=entry.key;
  node.dataset.cloudIndex=entry.index;
  node.setAttribute('role','button');
  node.setAttribute('tabindex','0');
  const length=Array.from(entry.text).length;
  const base=ui.patternKind==='phrase'?23:29;
  const size=Math.max(11,Math.min(31,base-Math.max(0,length-7)*.48));
  node.style.fontSize=size+'px';
  node.style.fontWeight=revealed?'800':'600';
  node.textContent=entry.text;
  target.appendChild(node);
 }
 if(onlyMissing&&words.length)sheet.classList.add('has-overflow');
}
function renderWordCloudLayouts(){
 const host=document.getElementById('wordCloudPages');
 if(!host||state.tab!=='wordcloud'){if(wordCloudLayoutResolve){wordCloudLayoutResolve();wordCloudLayoutResolve=null;}return;}
 if(wordCloudLayoutResolve){wordCloudLayoutResolve();wordCloudLayoutResolve=null;}
 const run=++wordCloudLayoutRun;
 wordCloudLayoutPromise=new Promise(resolve=>{wordCloudLayoutResolve=resolve;});
 const finishLayout=()=>{if(run===wordCloudLayoutRun&&wordCloudLayoutResolve){wordCloudLayoutResolve();wordCloudLayoutResolve=null;}};
 const cloudFactory=window.d3Cloud;
 const sheets=[...host.querySelectorAll('[data-wordcloud-sheet]')];
 const pageSize=ui.wordCloudPageSize||100,svgNS='http://www.w3.org/2000/svg';
 const active=wordCloudActiveKeys();
 const visibleSheet=sheets.find(sheet=>sheet.classList.contains('active'))||sheets[0];
 const visibleSvg=visibleSheet?.querySelector('[data-wordcloud-svg]');
 const stage=host.closest('.wordcloud-stage');
 const stageRect=stage?.getBoundingClientRect()||host.getBoundingClientRect();
 const visibleRect=visibleSvg?.getBoundingClientRect()||stageRect;
 const W=Math.max(240,Math.floor(visibleRect.width||stageRect.width||window.innerWidth-36||1180));
 const H=Math.max(180,Math.floor(visibleRect.height||stageRect.height||window.innerHeight-240||700));
 let page=0;
 function nextPage(){
  if(run!==wordCloudLayoutRun||state.tab!=='wordcloud')return;
  if(page>=sheets.length){applyWordCloudOcclusion();updateWordCloudPager();finishLayout();return}
  const sheet=sheets[page],svg=sheet.querySelector('[data-wordcloud-svg]');
  const fallback=sheet.querySelector('.wordcloud-fallback');
  const overflow=sheet.querySelector('.wordcloud-overflow');
  const chunk=ui.wordCloudEntries.slice(page*pageSize,(page+1)*pageSize);
  const words=chunk.map(entry=>{
   const length=Array.from(entry.text).length;
   const base=ui.patternKind==='phrase'?25:32;
   const reduction=ui.patternKind==='phrase'?.62:.48;
   return {text:entry.text,entry,size:Math.max(9,Math.min(34,base-Math.max(0,length-7)*reduction))};
  });
  if(fallback)fallback.innerHTML='';
  if(overflow){overflow.innerHTML='';sheet.classList.remove('has-overflow')}
  sheet.classList.remove('use-fallback');
  if(svg)svg.style.display='block';
  if(typeof cloudFactory!=='function'||!svg){
   renderWordCloudFallback(sheet,words,active,false);
   page++;
   requestAnimationFrame(nextPage);
   return;
  }
  let attempt=0;
  const scales=[1,.86,.74,.62,.52,.44];
  function draw(){
   if(run!==wordCloudLayoutRun||state.tab!=='wordcloud')return;
   while(svg.firstChild)svg.removeChild(svg.firstChild);
   svg.setAttribute('viewBox','0 0 '+W+' '+H);
   const group=document.createElementNS(svgNS,'g');
   svg.appendChild(group);
   const factor=scales[attempt];
   const layoutWords=words.map(word=>({...word,size:Math.max(8,word.size*factor)}));
   cloudFactory().size([W,H]).words(layoutWords).padding(2).rotate(()=>0).font('Arial').fontSize(d=>d.size).timeInterval(40)
    .on('word',word=>{
     if(run!==wordCloudLayoutRun)return;
     const revealed=active.has(word.entry.key);
     const node=document.createElementNS(svgNS,'text');
     node.setAttribute('class','cloud-word'+(revealed?' revealed':(ui.wordCloudOcclusion?' occluded':'')));
     node.setAttribute('data-cloud-key',word.entry.key);
     node.setAttribute('data-cloud-index',word.entry.index);
     node.setAttribute('text-anchor','middle');
     node.setAttribute('font-size',word.size);
     node.setAttribute('font-family','Arial, sans-serif');
     node.setAttribute('font-weight',revealed?'700':'500');
     node.setAttribute('transform','translate('+word.x+','+word.y+') rotate('+word.rotate+')');
     node.setAttribute('tabindex','0');
     node.setAttribute('role','button');
     node.textContent=word.text;
     const title=document.createElementNS(svgNS,'title');
     title.textContent=word.entry.text+' — '+word.entry.translations.join(' / ');
     node.appendChild(title);
     group.appendChild(node);
    })
    .on('end',placed=>{
     if(run!==wordCloudLayoutRun||state.tab!=='wordcloud')return;
     const placedKeys=new Set(placed.map(word=>word.entry.key));
     const missing=words.filter(word=>!placedKeys.has(word.entry.key));
     const required=words.length;
     if(placed.length<required&&attempt<scales.length-1){attempt++;draw();return}
     if(placed.length<required){
      renderWordCloudFallback(sheet,words,active,false);
     }else{
      // d3-cloud already places every word inside the requested [W,H] viewport.
      // Applying a second bounding-box transform moved the cluster off-canvas on some builds.
      group.removeAttribute('transform');
     }
     page++;
     requestAnimationFrame(nextPage);
    }).start();
  }
  try{draw()}catch(error){renderWordCloudFallback(sheet,words,active,false);page++;requestAnimationFrame(nextPage)}
 }
 nextPage();
}
function startGame(explicitPool=null,fromPatterns=false,returnTab=null){ui.patternFromNav=fromPatterns;ui.quizReturnTab=returnTab||(fromPatterns?'patterns':'home');const source=Array.isArray(explicitPool)?explicitPool:totalActive();if(!source.length){ui.setupStep=2;setTab('settings');return;}const candidates=source.filter(t=>Array.isArray(explicitPool)||state.gameMode==='color'||state.showMastered||!prog(t).mastered);const limit=state.quizLimit===0?candidates.length:Math.min(Math.max(1,Math.floor(Number(state.quizLimit)||1)),candidates.length);let picks;
 if(fromPatterns&&state.patternReview==='mnemonic'&&!(state.gameMode==='typing'&&state.writingStyle==='copy')){
  const byReview=[...candidates].sort((a,b)=>{const pa=prog(a),pb=prog(b);
   const score=p=>p.mastered?3:(p.c+p.w===0?1:(!p.next||Date.parse(p.next)<=Date.now())?0:2);
   return score(pa)-score(pb)||pb.w-pa.w||a.id.localeCompare(b.id)});
  picks=byReview.slice(0,limit);
 }else picks=shuffle([...candidates].sort(orderPriority).slice(0,Math.max(100,limit*5))).slice(0,limit);
 ui.session={items:picks,index:0,correct:0,wrong:0,skipped:0,mode:state.gameMode,kind:state.kind,writingStyle:state.writingStyle,copyLang:fromPatterns?ui.patternSource:state.dst,patternLabel:fromPatterns?(ui.patternBranchTrail.at(-1)||ui.patternBranchRoot||ui.patternFocus||'All patterns'):'',patternMode:fromPatterns?ui.patternMode:null,originIds:Array.isArray(explicitPool)?source.map(t=>t.id):null};ui.question=null;ui.qIndex=0;newQuestion();setTab('quiz')}
function newQuestion(){if(!ui.session){ui.question=null;return}const sess=ui.session;if(sess.index>=sess.items.length){ui.question=null;return}const candidate=sess.items[sess.index];ui.question=candidate;ui.options=howManyOptions(candidate,terms.filter(eligible));ui.revealed=false;ui.answer=-1;ui.typedHint=false;ui.typedRevealed=false;ui.typedEntry='';ui.typedSubmitted=false;ui.qIndex=sess.index+1}
function advance(){if(!ui.session)return;ui.session.index++;newQuestion();render()}
function normalized(s){return matchingForm(s)}
function markTyping(correct,shown,entry){if(ui.typedSubmitted)return;const t=ui.question;const mode=ui.session?.writingStyle==='copy'?'copy':'recall';state.typingHistory.push({id:t.id,src:state.src,dst:state.dst,kind:t.k,mode,copyLang:mode==='copy'?ui.session.copyLang:null,fromPatterns:!!ui.patternFromNav,correct,shown,typed:entry||'',at:new Date().toISOString()});logPatternAnswer(t,mode,correct,shown);if(state.typingHistory.length>30000)state.typingHistory=state.typingHistory.slice(-30000);ui.typedSubmitted=true;ui.typedRevealed=shown;if(correct)ui.session.correct++;else if(shown)ui.session.skipped++;else ui.session.wrong++;persist();render()}
function similarityKey(t){return `${t.id}:${state.src}>${state.dst}`}
function setSimilarity(val){state.similarity[similarityKey(ui.question)]=val;logPatternAnswer(ui.question,'color',true);ui.session.correct++;persist();advance()}
function quizReturnTarget(){return ui.quizReturnTab||(ui.patternFromNav?'patterns':'home')}
function quizReturnLabel(){return quizReturnTarget()==='saved'?'Back to Saved':quizReturnTarget()==='phrases'?'Back to Phrases':quizReturnTarget()==='patterns'?'Back to Patterns':'Home'}
function gameSummary(){const s=ui.session;return `<div class="game-stage"><div class="page-heading"><h1 class="h1">Done!</h1></div><div class="card emphasis center-finish"><div class="big-number">${s.items.length}</div><span>items completed</span></div><div class="kpis"><div class="kpi"><strong>${s.correct}</strong><span>${s.mode==='color'?'Rated':s.mode==='typing'&&s.writingStyle==='copy'?'Copied correctly':'Correct'}</span></div><div class="kpi"><strong>${s.skipped+s.wrong}</strong><span>${s.mode==='color'?'Skipped':'Wrong / skipped'}</span></div></div><button class="primary full" data-action="repeat">Play again →</button><button class="secondary full" style="margin-top:10px" data-nav="${quizReturnTarget()}">${quizReturnLabel()}</button></div>`}
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
 const slots=renderLetterSlots(copyTarget(t),ui.typedEntry,ui.typedHint);
 const el=document.getElementById('letterSlots'),status=document.getElementById('letterCount');
 if(el){el.innerHTML=slots.html;el.classList.toggle('length-matched',slots.same);el.classList.toggle('length-exceeded',slots.remaining>0)}
 if(status){status.textContent=slots.remaining?`${slots.remaining} extra ${slots.remaining===1?'letter':'letters'}`:`${slots.entered} / ${slots.count} letters${slots.same?' · length matches':''}`;status.className=`slot-count ${slots.same?'matched':slots.remaining?'exceeded':''}`}
}
function typingQuestion(t){
 const isCopy=ui.session.writingStyle==='copy';
 const answer=copyTarget(t),slots=renderLetterSlots(answer,ui.typedEntry,ui.typedHint);
 const origin=isCopy?(ui.patternFromNav?state.dst:state.src):state.src;
 const target=isCopy?ui.session.copyLang:state.dst;
 const prompt=isCopy?`<div class="copy-model"><span class="form-label">Copy this word · ${encode(langNames[target]||target)}</span><strong>${encode(answer)}</strong><span class="copy-translation">${encode(langNames[origin]||origin)} · ${encode(shown(t,origin))}</span></div>`:`<h2 class="prompt-word">${encode(shown(t,state.src))}</h2><div class="pair-sub">${encode(langNames[state.src])} → ${encode(langNames[state.dst])}</div>`;
 const bottom=ui.typedSubmitted?`<div class="nextbox"><strong>${encode(answer)}</strong><div class="small">${ui.typedRevealed?'Revealed / skipped':matchingForm(ui.typedEntry)===matchingForm(answer)?(isCopy?'Copied correctly':'Correct'):'Your answer: '+encode(ui.typedEntry)}</div></div><button class="primary full" data-action="next">Next →</button>`:
 `<form id="typingForm"><label class="typing-slots-label" for="typingAnswer"><span class="typing-slots ${slots.same?'length-matched':''} ${slots.remaining?'length-exceeded':''}" id="letterSlots">${slots.html}</span><input aria-label="Type the ${isCopy?'shown word':'answer'} in the letter slots" id="typingAnswer" type="text" autocomplete="off" autocapitalize="off" spellcheck="false" inputmode="text" value="${attr(ui.typedEntry)}"></label><div id="letterCount" class="slot-count ${slots.same?'matched':slots.remaining?'exceeded':''}">${slots.remaining?slots.remaining+' extra letters':`${slots.entered} / ${slots.count} letters${slots.same?' · length matches':''}`}</div><button class="primary full" type="submit">${isCopy?'Check spelling':'Check'} →</button></form><div class="two hint-actions">${isCopy?'':`<button class="secondary" data-action="hint">${ui.typedHint?'Hint shown ✓':'Hint'}</button>`}<button class="secondary" data-action="reveal">Skip / next</button></div>`;
 return `<div class="game-focus"><div class="word-context">${encode(t.c)} / ${encode(t.s)}</div>${prompt}${bottom}</div>`;
}
function colorQuestion(t){const current=state.similarity[similarityKey(t)]||'';return `<div class="game-focus similarity-focus"><div class="word-context">${encode(t.c)} · ${encode(t.s)}</div><div class="compare-words"><div>${encode(shown(t,state.src))}<small>${encode(langNames[state.src])}</small></div><span class="compare-mark">↕</span><div>${encode(shown(t,state.dst))}<small>${encode(langNames[state.dst])}</small></div></div><div class="color-grid">${[['red','🔴','Different'],['yellow','🟡','Similar'],['green','🟢','Very similar'],['neutral','⚪','Neutral']].map(([id,ic,name])=>`<button class="color-choice ${current===id?'on':''}" data-color="${id}" aria-label="${name}"><span>${ic}</span><strong>${name}</strong></button>`).join('')}</div></div>`}
function getWeekly(p){if(!p.start)return {week:0,done:0,quota:3};const diff=Math.floor(utcDay(new Date())-utcDay(p.start));const idx=Math.floor(diff/7);return {week:idx,done:[p.w1,p.w2,p.w3][idx]||0,quota:[3,2,1][idx]||3}}
function quizView(){
 if(!ui.session)return '<div class="game-stage">'+heading('Play')+'<button class="primary full" data-nav="settings">Choose a mode →</button></div>';
 if(!ui.question)return gameSummary();
 const t=ui.question,ss=ui.session;
 const header='<div class="game-top"><button class="back-game" data-nav="'+quizReturnTarget()+'" aria-label="Exit game">←</button><span>'+(ss.mode==='typing'?'Write':ss.mode==='color'?'Similarity':'Quiz')+'</span><span>'+ui.qIndex+' / '+ss.items.length+'</span></div>'+greenBar((ui.qIndex-1)/ss.items.length);
 const savedPanel=preferredQuizPanel(t);
 if(ss.mode==='typing')return '<div class="game-stage">'+header+typingQuestion(t)+savedPanel+'</div>';
 if(ss.mode==='color')return '<div class="game-stage">'+header+colorQuestion(t)+savedPanel+'</div>';
 const keycode=ui.options.findIndex(x=>x===shown(t,state.dst));
 const opts=ui.options.map((opt,i)=>{const cls=ui.revealed?(i===keycode?'correct':i===ui.answer?'wrong':''):'';return '<button class="option '+cls+'" data-option="'+i+'" '+(ui.revealed?'disabled':'')+'><span class="letter">'+('ABCD'[i])+'</span>'+encode(opt)+'</button>'}).join('');
 let feedback='';
 if(ui.revealed){
  const result=ui.answer===keycode?'✓ Correct':'Answer: '+encode(shown(t,state.dst));
  const next=state.reviewMode==='anki'?'<div class="two">'+[['again','Again'],['hard','Hard'],['good','Good'],['easy','Easy']].map(([v,l])=>'<button class="secondary" data-rate="'+v+'">'+l+'</button>').join('')+'</div>':'<button class="primary full next-btn" data-action="next">Next →</button>';
  feedback='<div class="nextbox"><strong>'+result+'</strong></div>'+next;
 }
 return '<div class="game-stage">'+header+'<div class="game-focus"><div class="word-context">'+encode(t.c)+' · '+encode(t.s)+'</div><div class="pair-sub">'+encode(langNames[state.src])+' → '+encode(langNames[state.dst])+'</div><h2 class="prompt-word">'+encode(shown(t,state.src))+'</h2><div class="game-options">'+opts+'</div>'+feedback+'</div>'+savedPanel+'</div>';
}
function record(t,correct,rating){const x=prog(t),p={...x};let now=new Date();let start=p.start?new Date(p.start):new Date(now.getFullYear(),now.getMonth(),now.getDate());let w=Math.floor((utcDay(now)-utcDay(start))/7);if(p.mastered&&!correct){start=new Date(now.getFullYear(),now.getMonth(),now.getDate());p.w1=p.w2=p.w3=0;p.mastered=false;w=0}const missed=(w<0||w>2||(w>=1&&p.w1<3)||(w>=2&&p.w2<2));if(!p.mastered&&missed){start=new Date(now.getFullYear(),now.getMonth(),now.getDate());p.w1=p.w2=p.w3=0;w=0}p.start=start.toISOString();if(correct&&!p.mastered){if(w===0)p.w1++;else if(w===1)p.w2++;else if(w===2)p.w3++;p.mastered=p.w1>=3&&p.w2>=2&&p.w3>=1}p.c+=(correct?1:0);p.w+=(!correct?1:0);p.streak=correct?0:p.streak+1;let next=null;if(!p.mastered){const min=(!correct||rating==='again')?5:rating==='hard'?360:rating==='easy'?4320:1440;next=new Date(now.getTime()+min*60000);const count=[p.w1,p.w2,p.w3][w],quota=[3,2,1][w];const endWindow=new Date(start.getFullYear(),start.getMonth(),start.getDate()+(w+1)*7);if(count>=quota)next=endWindow;else if(next>endWindow)next=new Date(endWindow.getTime()-60000)}p.next=next?.toISOString()||null;state.progress[key(t)]=p;logPatternAnswer(t,'choice',correct);state.attempts.push({at:now.toISOString(),id:t.id,src:state.src,dst:state.dst,c:correct,kind:t.k,category:t.c,sub:t.s,rating});if(state.attempts.length>30000)state.attempts=state.attempts.slice(-30000);persist()}
function navBar(){const active=state.tab==='wordcloud'?'patterns':state.tab;nav.innerHTML=[['home','⌂','Home'],['settings','◎','Study'],['patterns','⋈','Patterns'],['saved','☆','Saved'],['phrases','▤','Phrases'],['stats','▥','Stats']].map(([key,ico,title])=>`<button class="nav ${active===key?'active':''}" data-nav="${key}"><span class="sym">${ico}</span>${title}</button>`).join('')}
function render(){
 navBar();
 const app=document.querySelector('.app');
 const cloudPortal=state.tab==='wordcloud';
 if(cloudPortal){
  document.body.appendChild(view);
  view.classList.add('wordcloud-portal');
 }else{
  if(view.parentElement!==app)app.insertBefore(view,nav);
  view.classList.remove('wordcloud-portal');
 }
 app.classList.toggle('in-game',state.tab==='quiz'&&Boolean(ui.question));
 app.classList.toggle('wordcloud-mode',cloudPortal);
 document.body.classList.toggle('wordcloud-active',cloudPortal);
 nav.hidden=cloudPortal;
 switch(state.tab){
  case 'home':view.innerHTML=homeView();break;
  case 'quiz':view.innerHTML=quizView();break;
  case 'wordcloud':view.innerHTML=wordCloudView();break;
  case 'stats':view.innerHTML=statsView();break;
  case 'patterns':view.innerHTML=patternView();break;
  case 'saved':view.innerHTML=savedView();break;
  case 'phrases':view.innerHTML=phrasesView();break;
  case 'settings':view.innerHTML=settingsView();break;
 }
 for(const el of view.querySelectorAll('[data-indeterminate]'))el.indeterminate=true;
 window.dispatchEvent(new Event('quizlab:rendered'));
 if(cloudPortal){updateWordCloudSpeechControls();requestAnimationFrame(renderWordCloudLayouts);}
}
let wordCloudLayoutRun=0,wordCloudResizeFrame=0,wordCloudLayoutPromise=Promise.resolve(),wordCloudLayoutResolve=null;
async function printWordCloudAfterReady(button){
 if(!button||button.disabled)return;
 const oldLabel=button.textContent;
 button.disabled=true;
 button.textContent='Preparing all pages…';
 try{
  await new Promise(resolve=>requestAnimationFrame(()=>requestAnimationFrame(resolve)));
  let current;
  do{current=wordCloudLayoutPromise;await current;}while(current!==wordCloudLayoutPromise);
  if(state.tab==='wordcloud')window.print();
 }finally{
  if(button.isConnected){button.disabled=false;button.textContent=oldLabel;}
 }
}
document.addEventListener('keydown',e=>{
 if(state.tab!=='wordcloud'||!(e.ctrlKey||e.metaKey)||e.key.toLowerCase()!=='p')return;
 e.preventDefault();
 const button=document.querySelector('[data-wordcloud-print]');
 if(button)printWordCloudAfterReady(button);
});
window.addEventListener('resize',()=>{
 if(state.tab!=='wordcloud')return;
 if(wordCloudResizeFrame)window.cancelAnimationFrame(wordCloudResizeFrame);
 wordCloudResizeFrame=window.requestAnimationFrame(()=>{wordCloudResizeFrame=0;renderWordCloudLayouts();});
});
function goStep(n){ui.setupStep=Math.min(2,Math.max(1,Number(n)));setTab('settings')}
function setTab(v){if(state.tab==='wordcloud'&&v!=='wordcloud'){stopWordCloudSpeech();if(wordCloudLayoutResolve){wordCloudLayoutResolve();wordCloudLayoutResolve=null;}}if(state.tab==='quiz'&&v!=='quiz'){if(ui.patternStudyBefore){Object.assign(state,ui.patternStudyBefore);ui.patternStudyBefore=null;}if(ui.collectionStudyBefore){Object.assign(state,ui.collectionStudyBefore);ui.collectionStudyBefore=null;}}state.tab=v;persist();render();document.querySelector('.app')?.scrollTo({top:0,behavior:'instant'});window.scrollTo(0,0)}
function setSetting(name,value){if(['src','dst','kind'].includes(name))patternReset();state[name]=value;if(name==='kind'&&value==='phrase'&&state.gameMode==='color')state.gameMode='choice';if(name==='gameMode'&&value==='color')state.kind='word';ui.session=null;ui.question=null;persist();render()}
function exportProgress(){const output=JSON.stringify({version:3,app:'Quiz Lab browser',exportedAt:new Date().toISOString(),progress:state.progress,attempts:state.attempts,excluded:state.excluded,typingHistory:state.typingHistory,patternAttempts:state.patternAttempts,similarity:state.similarity,preferredWords},null,2);const url=URL.createObjectURL(new Blob([output],{type:'application/json'}));const a=document.createElement('a');a.href=url;a.download='quizlab-browser-progress.json';a.click();URL.revokeObjectURL(url)}
function onFile(f){if(!f)return;const reader=new FileReader();reader.onload=()=>{try{const data=JSON.parse(reader.result);let a=[];if(Array.isArray(data.terms)){a=data.terms.map((t,i)=>{const path=(t.topic||'General / General').split(' / ');return {id:'user:'+ (data.id||'pack') + ':'+t.id,c:t.category||path[0],s:t.subtopic||path[1]||'General',k:t.kind||'word',t:Object.fromEntries(Object.entries(t.translations||{}).map(([k,v])=>[k.toLowerCase(),String(v)]))}})}else if(Array.isArray(data.entries)){a=data.entries.map((t,i)=>({id:'user:'+t.id,c:t.category||'General',s:t.subtopic||'General',k:t.type||'word',t:Object.fromEntries(Object.entries(t.words||{}).map(([k,v])=>[k.toLowerCase(),String(v)]))}))}else if(Array.isArray(data.preferredWords))a=[];else throw Error('Expected a JSON object containing terms[], entries[] or preferredWords[].');a=a.filter(t=>t.id&&Object.keys(t.t).length>=2);let added=0;for(const t of a){if(!ids.has(t.id)){terms.push(t);ids.add(t.id);added++}}byId.clear();for(const t of terms)byId.set(t.id,t);localStorage.setItem(DATA_KEY,JSON.stringify(terms.slice(window.QUIZLAB_DATA.length)));let savedAdded=0;if(Array.isArray(data.preferredWords)){for(const p of data.preferredWords){if(!p||!p.id||!p.src||!p.dst||!p.sourceText||!p.targetText)continue;const k=preferredKey(p.id,p.src,p.dst,p.kind);if(!preferredWords.some(x=>preferredKey(x.id,x.src,x.dst,x.kind)===k)){preferredWords.push({...p,rating:['difficult','medium','easy'].includes(p.rating)?p.rating:null});savedAdded++}}preferredPersist()}ui.importStatus='Imported '+added+' new vocabulary items and '+savedAdded+' saved words ('+a.length+' valid records).';ui.question=null;setTab('settings')}catch(e){ui.importStatus='Import error: '+e.message;render()}};reader.readAsText(f,'utf-8')}
nav.addEventListener('click',e=>{const b=e.target.closest('[data-nav]');if(b){if(b.dataset.nav==='settings')ui.setupStep=1;setTab(b.dataset.nav)}});
view.addEventListener('click',e=>{const b=e.target.closest('button,[data-toggle-cat],[data-toggle-sub],[data-cloud-index]');if(!b)return;const d=b.dataset;if(d.cloudIndex!==undefined){wordCloudShowDetail(Number(d.cloudIndex));return}if(d.wordcloudPage){ui.wordCloudPageIndex=d.wordcloudPage==='next'?Math.min(wordCloudPageCount()-1,ui.wordCloudPageIndex+1):Math.max(0,ui.wordCloudPageIndex-1);updateWordCloudPager();applyWordCloudOcclusion();return}if(d.wordcloudSpeechToggle!==undefined){if(ui.wordCloudSpeechWanted)stopWordCloudSpeech();else startWordCloudSpeech();return}if(d.wordcloudBack!==undefined)return setTab('patterns');if(d.wordcloudPrint!==undefined){printWordCloudAfterReady(b);return}if(d.wordcloudMode){ui.wordCloudFilterMode=d.wordcloudMode;updateWordCloudControls();applyWordCloudOcclusion();return}if(d.wordcloudClear!==undefined){ui.wordCloudFilter='';const input=document.getElementById('wordCloudFilter');if(input)input.value='';applyWordCloudOcclusion();return}if(d.patternSelectedCloud!==undefined){const pool=patternUniqueChecked();if(pool.length)openPatternWordCloud(pool);return}if(d.preferredSave!==undefined){togglePreferredWord(d.preferredSave,d.preferredSrc,d.preferredDst,d.preferredKind);return render()}if(d.preferredRate!==undefined){setPreferredRatingForQuiz(d.preferredId,d.preferredSrc,d.preferredDst,d.preferredKind,d.preferredRate);return render()}if(d.preferredRating!==undefined){setPreferredRatingByKey(d.preferredKey,d.preferredRating);return render()}if(d.preferredRemoveKey!==undefined){const idx=preferredWords.findIndex(p=>preferredKey(p.id,p.src,p.dst,p.kind)===d.preferredRemoveKey);if(idx>=0){preferredWords.splice(idx,1);preferredPersist()}return render()}if(d.preferredFilter!==undefined){ui.preferredFilter=d.preferredFilter;return render()}if(d.collectionStart!==undefined)return startCollectionQuiz(d.collectionStart);if(d.collectionDifficultyAll!==undefined){collectionFilterState(d.collectionDifficultyAll).difficulties=COLLECTION_DIFFICULTIES.map(x=>x.id);return render()}if(d.collectionDifficultyClear!==undefined){collectionFilterState(d.collectionDifficultyClear).difficulties=[];return render()}if(d.collectionCategoryAll!==undefined){collectionFilterState(d.collectionCategoryAll).categories=null;return render()}if(d.collectionCategoryClear!==undefined){collectionFilterState(d.collectionCategoryClear).categories=[];return render()}if(d.collectionCategorySort!==undefined){collectionFilterState(d.collectionCategorySort).categorySort=d.collectionCategoryOrder==='asc'?'asc':'desc';return render()}if(d.quizLimitMax!==undefined){state.quizLimit=0;persist();return render()}if(d.nav){if(d.nav==='settings')ui.setupStep=1;return setTab(d.nav)}if(d.step)return goStep(d.step);if(d.kind)return setSetting('kind',d.kind);if(d.mode)return setSetting('reviewMode',d.mode);if(d.quickmode){state.gameMode=d.quickmode;if(d.quickmode==='color')state.kind='word';persist();return goStep(1)}if(d.game)return setSetting('gameMode',d.game);if(d.limit)return setSetting('quizLimit',Number(d.limit));if(d.color)return setSimilarity(d.color);if(d.toggleCat!==undefined)return toggleGroup('cat',d.toggleCat);if(d.toggleSub!==undefined)return toggleGroup('sub',d.toggleSub);if(d.option!==undefined){if(ui.revealed)return;ui.answer=Number(d.option);ui.revealed=true;if(state.reviewMode==='automatic'){const good=ui.options[ui.answer]===shown(ui.question,state.dst);record(ui.question,good,good?'good':'again');ui.session[good?'correct':'wrong']++}render();return}if(d.rate){const good=ui.options[ui.answer]===shown(ui.question,state.dst)&&d.rate!=='again';record(ui.question,good,d.rate);ui.session[good?'correct':'wrong']++;advance();return}if(d.patternKind){ui.patternKind=d.patternKind;if(d.patternKind==='phrase'&&state.gameMode==='color')state.gameMode='choice';patternReset();persist();return render()}
 if(d.patternGame){state.gameMode=d.patternGame;persist();return render()}if(d.writingStyle){state.writingStyle=d.writingStyle;persist();return render()}if(d.patternReview){state.patternReview=d.patternReview;persist();return render()}if(d.patternRating){state.reviewMode=d.patternRating;persist();return render()}
 if(d.patternLimit){state.quizLimit=Number(d.patternLimit);persist();return render()}
 if(d.patternMode){ui.patternMode=d.patternMode;patternReset();return render()}
 if(d.patternBack!==undefined){ui.patternFocus=ui.patternFocus.slice(0,-1);ui.patternCollapsed.clear();return render()}
 if(d.patternExpand!==undefined){ui.patternCollapsed.has(d.patternExpand)?ui.patternCollapsed.delete(d.patternExpand):ui.patternCollapsed.add(d.patternExpand);return render()}
 if(d.patternAll!==undefined){ui.patternShowAll=d.patternAll;return render()}
 if(d.patternSplit!==undefined){const root=d.patternSplit;ui.patternBranchRoot=ui.patternBranchRoot===root?null:root;ui.patternBranchTrail=[];ui.patternBranchShowAll.clear();ui.patternCollapsed.delete(root);return render()}
 if(d.patternBranchUp!==undefined){if(ui.patternBranchTrail.length)ui.patternBranchTrail.pop();else ui.patternBranchRoot=null;ui.patternBranchShowAll.clear();return render()}
 if(d.patternBranchJump!==undefined){const level=Number(d.patternBranchJump);if(Number.isInteger(level)&&level>=0){ui.patternBranchTrail=ui.patternBranchTrail.slice(0,level);ui.patternBranchShowAll.clear();return render()}return}
 if(d.patternBranchChoice!==undefined){ui.patternBranchTrail.push(d.patternBranchChoice);ui.patternBranchShowAll.clear();return render()}
 if(d.patternBranchAll!==undefined){ui.patternBranchShowAll.add(d.patternBranchAll);return render()}
 if(d.patternBranchPlay!==undefined){const pool=ui.patternBranchPools.get(d.patternBranchPlay);if(pool?.length){ui.patternStudyBefore={src:state.src,dst:state.dst,kind:state.kind};state.src=ui.patternSource;state.dst=ui.patternTarget;state.kind=ui.patternKind;persist();return startGame(pool,true)}return}
 if(d.patternSelectedClear!==undefined){ui.patternChecked.clear();return render()}
 if(d.patternSelectedPlay!==undefined){const pool=patternUniqueChecked();if(pool.length){state.gameMode='choice';patternLaunch(pool)}return}
 if(d.patternDrill!==undefined){ui.patternFocus=d.patternDrill;ui.patternCollapsed.clear();ui.patternSearch='';ui.patternBranchRoot=null;ui.patternBranchTrail=[];return render()}
 if(d.patternPlay!==undefined){const pool=ui.patternPools.get(d.patternPlay);if(pool?.length){ui.patternStudyBefore={src:state.src,dst:state.dst,kind:state.kind};state.src=ui.patternSource;state.dst=ui.patternTarget;state.kind=ui.patternKind;persist();return startGame(pool,true)}return}
 if(d.action==='repeat')return startGame(ui.session?.originIds?.map(id=>byId.get(id)).filter(Boolean)||null,ui.patternFromNav,ui.quizReturnTab);
 if(d.action==='start')return startGame();if(d.action==='next')return advance();if(d.action==='hint'){ui.typedHint=true;render();document.getElementById('typingAnswer')?.focus();return}if(d.action==='reveal')return markTyping(false,true,'');if(d.action==='all-select'||d.action==='all-clear'){const q=ui.wordFilter.trim().toLowerCase(),a=terms.filter(t=>eligible(t)&&(!q||[t.c,t.s,shown(t,state.src),shown(t,state.dst)].join(' ').toLowerCase().includes(q)));return toggleSelection(a,d.action==='all-select')}if(d.action==='export')return exportProgress();if(d.action==='reset'){if(confirm('Delete all browser quiz progress? Vocabulary content will remain.')){state.progress={};state.attempts=[];state.typingHistory=[];state.patternAttempts=[];state.similarity={};persist();render()}}});
view.addEventListener('submit',e=>{if(e.target.id!=='typingForm')return;e.preventDefault();if(ui.typedSubmitted||!ui.question)return;const input=document.getElementById('typingAnswer').value;ui.typedEntry=input;markTyping(matchingForm(input)===matchingForm(copyTarget(ui.question)),false,input)});
view.addEventListener('change',e=>{const d=e.target.dataset;if(d.wordcloudOcclusion!==undefined){ui.wordCloudOcclusion=e.target.checked;applyWordCloudOcclusion();return}if(d.collectionDifficulty!==undefined){const f=collectionFilterState(d.collectionDifficultyKind),set=new Set(f.difficulties);if(e.target.checked)set.add(d.collectionDifficulty);else set.delete(d.collectionDifficulty);f.difficulties=[...set];return render()}if(d.collectionCategory!==undefined){const f=collectionFilterState(d.collectionCategoryKind),cats=unique(collectionRecords(d.collectionCategoryKind).map(p=>p.category)).sort(),set=new Set(f.categories===null?cats:f.categories);if(e.target.checked)set.add(d.collectionCategory);else set.delete(d.collectionCategory);f.categories=[...set];return render()}if(d.collectionPair!==undefined){ui.savedPair=e.target.value;return render()}if(d.patternCheck!==undefined){const pool=ui.patternCheckPools.get(d.patternCheck);if(e.target.checked&&pool?.length)ui.patternChecked.set(d.patternCheck,[...pool]);else ui.patternChecked.delete(d.patternCheck);return render()}if(d.quizLimitInput){const n=Math.floor(Number(e.target.value));if(Number.isFinite(n)&&n>0){state.quizLimit=Math.min(n,999999);persist();return render()}return}if(d.patternSort){state.patternSort=e.target.value;ui.patternShowAll='';persist();return render()}if(d.patternSetting){if(d.patternSetting==='source'){ui.patternSource=e.target.value;if(ui.patternTarget===ui.patternSource)ui.patternTarget=Object.keys(langNames).find(k=>k!==ui.patternSource)}else if(d.patternSetting==='target'&&e.target.value!==ui.patternSource)ui.patternTarget=e.target.value;patternReset();return render()}if(d.setting){if(d.setting==='src'&&e.target.value===state.dst)state.dst=Object.keys(langNames).find(k=>k!==e.target.value);return setSetting(d.setting,e.target.value)}if(d.settingCheck)return setSetting(d.settingCheck,e.target.checked);if(d.catSelect!==undefined)return toggleSelection(terms.filter(t=>eligible(t)&&t.c===d.catSelect),e.target.checked);if(d.subSelect!==undefined){const [cat,sub]=d.subSelect.split('|');return toggleSelection(terms.filter(t=>eligible(t)&&t.c===cat&&t.s===sub),e.target.checked)}if(d.wordSelect!==undefined){const t=byId.get(d.wordSelect);if(t)return toggleSelection([t],e.target.checked)}if(e.target.id==='importJson')return onFile(e.target.files?.[0]);});
view.addEventListener('input',e=>{if(e.target.id==='wordCloudFilter'){ui.wordCloudFilter=e.target.value;applyWordCloudOcclusion();return}if(e.target.id==='preferredSearch'||e.target.id==='phraseSearch'){const id=e.target.id,pos=e.target.selectionStart;if(id==='preferredSearch')ui.preferredSearch=e.target.value;else ui.phraseSearch=e.target.value;render();const n=document.getElementById(id);if(n){n.focus();n.setSelectionRange(pos,pos)}return}if(e.target.id==='typingAnswer'){ui.typedEntry=e.target.value;updateTypingSlots();return}if(e.target.id==='patternSearch'){const a=e.target.selectionStart;ui.patternSearch=e.target.value;ui.patternFocus='';ui.patternCollapsed.clear();ui.patternBranchRoot=null;ui.patternBranchTrail=[];render();const n=document.getElementById('patternSearch');if(n){n.focus();n.setSelectionRange(a,a)}return}if(e.target.id==='vocabSearch'){const a=e.target.selectionStart;ui.wordFilter=e.target.value;render();const n=document.getElementById('vocabSearch');n.focus();n.setSelectionRange(a,a)}});
document.getElementById('topInfo')?.addEventListener('click',()=>{alert(`Quiz Lab mobile web preview\n${terms.length} learning items (1,804 original + 67 reference)\nStorage: your browser only\nCloud: not connected\nBuild: 2026-10-13`)});
window.QuizLabSyncHooks={state,terms,persist,render};
render();
})();
/* Quiz Lab offline-first Supabase sync. The browser remains fully usable without cloud. */
(() => {
  'use strict';
  const app = window.QuizLabSyncHooks;
  const config = window.QUIZLAB_SUPABASE_CONFIG || {};
  const api = config.url && config.publishableKey && window.supabase
    ? window.supabase.createClient(config.url, config.publishableKey) : null;
  if (!app) return;
  const {state, terms, persist, render} = app;
  const ownerKey = 'quizlab.sync.owner.v1';
  const known = new Map(terms.map(t => [t.id, t]));
  let user = null, busy = false, applying = false, timer = null;
  let message = api ? 'Sign in on both devices to sync progress.'
    : 'Cloud sync is ready in the code, but needs the Supabase project URL and publishable key.';
  const freshId = () => (window.crypto && crypto.randomUUID)
    ? crypto.randomUUID() : 'web-' + Date.now().toString(36) + '-' + Math.random().toString(36).slice(2);
  const dateDay = date => {
    const d = new Date(date);
    return Date.UTC(d.getFullYear(), d.getMonth(), d.getDate()) / 864e5;
  };
  const normalizedEvent = (entry, type) => {
    if (!entry.event_id) entry.event_id = freshId();
    const at = entry.at && !Number.isNaN(Date.parse(entry.at)) ? entry.at : new Date().toISOString();
    const payload = type === 'quiz_answer' ? {
      item_id: 'language:' + entry.id + ':' + entry.src + '>' + entry.dst,
      topic: (entry.category || '') + ' / ' + (entry.sub || ''),
      category: 'language', source_lang: entry.src, target_lang: entry.dst,
      correct: !!entry.c, rating: entry.rating || (entry.c ? 'good' : 'again'),
      elapsed_ms: 0, kind: entry.kind || 'word'
    } : {web_record: entry};
    return {event_id: entry.event_id, event_type: type, occurred_at: at, payload};
  };

  function reviewStep(previous, correct, rating, at) {
    const now = new Date(at), p = {...previous};
    let start = p.start ? new Date(p.start)
      : new Date(now.getFullYear(), now.getMonth(), now.getDate());
    let week = Math.floor((dateDay(now) - dateDay(start)) / 7);
    if (p.mastered && !correct) {
      start = new Date(now.getFullYear(), now.getMonth(), now.getDate());
      p.w1 = p.w2 = p.w3 = 0; p.mastered = false; week = 0;
    }
    const missed = week < 0 || week > 2 || (week >= 1 && p.w1 < 3) || (week >= 2 && p.w2 < 2);
    if (!p.mastered && missed) {
      start = new Date(now.getFullYear(), now.getMonth(), now.getDate());
      p.w1 = p.w2 = p.w3 = 0; week = 0;
    }
    if (correct && !p.mastered) {
      if (week === 0) p.w1++;
      else if (week === 1) p.w2++;
      else if (week === 2) p.w3++;
      p.mastered = p.w1 >= 3 && p.w2 >= 2 && p.w3 >= 1;
    }
    p.c += correct ? 1 : 0;
    p.w += correct ? 0 : 1;
    p.streak = correct ? 0 : p.streak + 1;
    p.start = start.toISOString();
    p.next = null;
    if (!p.mastered) {
      const minutes = !correct || rating === 'again' ? 5 :
        rating === 'hard' ? 360 : rating === 'easy' ? 4320 : 1440;
      let next = new Date(now.getTime() + minutes * 60000);
      const quota = [3, 2, 1][week];
      const count = [p.w1, p.w2, p.w3][week];
      const end = new Date(start.getFullYear(), start.getMonth(), start.getDate() + (week + 1) * 7);
      if (count >= quota) next = end;
      else if (next > end) next = new Date(end.getTime() - 60000);
      p.next = next.toISOString();
    }
    return p;
  }

  function rebuildReview() {
    const grouped = new Map();
    for (const answer of state.attempts) {
      if (!answer.id || !answer.src || !answer.dst) continue;
      const key = 'language:' + answer.id + ':' + answer.src + '>' + answer.dst;
      if (!grouped.has(key)) grouped.set(key, []);
      grouped.get(key).push(answer);
    }
    for (const [key, answers] of grouped) {
      answers.sort((a, b) => Date.parse(a.at) - Date.parse(b.at) ||
        String(a.event_id).localeCompare(String(b.event_id)));
      let value = {w1: 0, w2: 0, w3: 0, c: 0, w: 0, streak: 0, mastered: false, start: null, next: null};
      for (const a of answers) value = reviewStep(value, !!a.c, a.rating || 'good', a.at);
      state.progress[key] = value;
    }
  }

  async function syncNow() {
    if (busy || !api || !user) return;
    const owner = localStorage.getItem(ownerKey);
    if (owner && owner !== user.id) throw new Error('Local progress is already linked to another Supabase account. Sign in with that account.');
    busy = true;
    message = 'Syncing quiz history…'; renderPanel();
    try {
      applying = true;
      const local = [
        ...state.attempts.map(a => normalizedEvent(a, 'quiz_answer')),
        ...state.typingHistory.map(a => normalizedEvent(a, 'writing_attempt')),
        ...state.patternAttempts.map(a => normalizedEvent(a, 'pattern_attempt')),
      ];
      persist();
      applying = false;
      for (let i = 0; i < local.length; i += 200) {
        const rows = local.slice(i, i + 200).map(e => ({...e, user_id: user.id}));
        const {error} = await api.from('quiz_sync_events')
          .upsert(rows, {onConflict: 'user_id,event_id', ignoreDuplicates: true});
        if (error) throw error;
      }
      const remote = [];
      for (let offset = 0; ; offset += 500) {
        const {data, error} = await api.from('quiz_sync_events')
          .select('event_id,event_type,occurred_at,payload').eq('user_id', user.id)
          .order('occurred_at', {ascending: true}).order('event_id', {ascending: true})
          .range(offset, offset + 499);
        if (error) throw error;
        remote.push(...data);
        if (data.length < 500) break;
      }
      if ((await api.auth.getUser()).data.user?.id !== user.id) throw new Error('Account changed during sync.');
      const seen = new Set([...state.attempts, ...state.typingHistory, ...state.patternAttempts].map(x => x.event_id));
      let added = 0;
      applying = true;
      for (const e of remote) {
        if (seen.has(e.event_id)) continue;
        const p = e.payload || {};
        if (e.event_type === 'quiz_answer' && typeof p.item_id === 'string') {
          const match = /^language:(.*):([^:]+)>([^:]+)$/.exec(p.item_id);
          if (!match) continue;
          const [, id, src, dst] = match;
          const term = known.get(id);
          state.attempts.push({event_id: e.event_id, at: e.occurred_at, id, src, dst,
            c: !!p.correct, rating: p.rating || 'good', kind: term?.k || p.kind || 'word',
            category: term?.c || 'Language', sub: term?.s || ''});
        } else if ((e.event_type === 'writing_attempt' || e.event_type === 'pattern_attempt') &&
                   p.web_record && typeof p.web_record === 'object') {
          const entry = {...p.web_record, event_id: e.event_id};
          (e.event_type === 'writing_attempt' ? state.typingHistory : state.patternAttempts).push(entry);
        } else continue;
        seen.add(e.event_id); added++;
      }
      if (added) rebuildReview();
      persist(); render();
      applying = false;
      localStorage.setItem(ownerKey, user.id);
      message = 'Synced ✓ · ' + added + ' events received · ' + new Date().toLocaleTimeString();
      renderPanel();
    } catch (error) {
      message = 'Sync error: ' + (error.message || error);
      throw error;
    } finally {
      applying = false; busy = false; renderPanel();
    }
  }

  function scheduleSync() {
    if (!api || !user || applying) return;
    clearTimeout(timer);
    timer = setTimeout(() => { syncNow().catch(() => {}); }, 3000);
  }

  function renderPanel() {
    document.getElementById('quizlab-sync-panel')?.remove();
    if (state.tab !== 'settings') return;
    const wrapper = document.createElement('section');
    wrapper.id = 'quizlab-sync-panel'; wrapper.className = 'card flat';
    wrapper.innerHTML = '<div class="section" style="margin-top:0">Cloud progress</div>' +
      '<p class="small">Answers, 3·2·1 reviews, writing and pattern history sync across devices; offline work stays on this device.</p>' +
      (user ? '<p class="small">Connected: ' + String(user.email || user.id).replace(/[&<>"\']/g, '') + '</p>' +
        '<div class="row"><button class="secondary" data-sync-now="1" type="button" ' + (busy ? 'disabled' : '') + '>Sync now</button>' +
        '<button class="ghost" data-cloud-out="1" type="button">Sign out</button></div>'
      : api ? '<form id="quizlab-cloud-auth"><input class="field" type="email" name="email" autocomplete="email" placeholder="Email" required>' +
        '<input class="field" type="password" name="password" autocomplete="current-password" placeholder="Password" required style="margin-top:8px">' +
        '<div class="row" style="margin-top:8px"><button class="secondary" type="submit" name="action" value="signin">Sign in</button>' +
        '<button class="ghost" type="submit" name="action" value="signup">Create account</button></div></form>' : '') +
      '<p class="small" role="status">' + String(message).replace(/[&<>]/g, '') + '</p>';
    document.getElementById('view').prepend(wrapper);
  }

  document.getElementById('view').addEventListener('submit', async event => {
    if (event.target.id !== 'quizlab-cloud-auth') return;
    event.preventDefault();
    const form = event.target;
    const email = form.elements.namedItem('email').value;
    const password = form.elements.namedItem('password').value;
    const action = event.submitter?.value || 'signin';
    try {
      const result = action === 'signup' ? await api.auth.signUp({email, password})
        : await api.auth.signInWithPassword({email, password});
      if (result.error) throw result.error;
      user = result.data.user && result.data.session ? result.data.user : null;
      message = user ? 'Signed in. Starting sync…' : 'Check email confirmation, then sign in.';
      renderPanel();
      if (user) await syncNow();
    } catch (error) { message = 'Authentication error: ' + (error.message || error); renderPanel(); }
  });
  document.getElementById('view').addEventListener('click', async event => {
    if (event.target.closest('[data-sync-now]')) {
      syncNow().catch(() => {});
    } else if (event.target.closest('[data-cloud-out]')) {
      await api.auth.signOut(); user = null; message = 'Signed out; local progress is preserved.'; renderPanel();
    }
  });
  window.addEventListener('quizlab:rendered', renderPanel);
  window.addEventListener('quizlab:changed', scheduleSync);
  if (api) {
    api.auth.onAuthStateChange((event, session) => {
      user = session?.user || null;
      renderPanel();
      if (user && (event === 'SIGNED_IN' || event === 'INITIAL_SESSION')) scheduleSync();
    });
  }
  renderPanel();
})();

