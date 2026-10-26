(function () {
  'use strict';
  const E=window.DWARVEN_ENGINE, D=window.DWARVEN_DATA;
  if (!E || !D) { document.body.textContent='Could not load translation data. Please reload.';return; }
  const $=id=>document.getElementById(id);
  const PRESETS=['Subtle','Balanced','Heavy'];
  const STORAGE='dwarven-accent-review-1';
  let saved={reviews:{},custom:[]};
  try {const val=JSON.parse(localStorage.getItem(STORAGE)||'null');if(val && typeof val==='object') {saved.reviews=val.reviews||{};saved.custom=Array.isArray(val.custom)?val.custom:[];}}catch(_){}
  let view='library',shown=18,noticeTimer=0;
  const persist=()=>{try{localStorage.setItem(STORAGE,JSON.stringify(saved));}catch(e){notice('Could not save: browser storage is full or disabled. Export your reviews.');}};
  function el(tag,cls,text){const node=document.createElement(tag);if(cls)node.className=cls;if(text!==undefined)node.textContent=text;return node;}
  const corpus=()=>[...D.phrases,...saved.custom];
  function notice(message){const node=$('notice');node.textContent=message;node.hidden=false;clearTimeout(noticeTimer);noticeTimer=setTimeout(()=>{node.hidden=true;},4000);}
  function updateStats(){
    const rows=corpus(), statuses=rows.map(p=>saved.reviews[p.id]?.status||'pending');
    const reviewed=statuses.filter(s=>s!=='pending').length, flagged=statuses.filter(s=>s==='flagged').length;
    $('count-reviewed').textContent=reviewed;$('count-flagged').textContent=flagged;
    $('count-approved').textContent=statuses.filter(s=>s==='approved').length;
    $('count-custom').textContent=saved.custom.length;
    $('progress-total').textContent='of '+rows.length+' samples';
    $('progress').setAttribute('aria-valuenow',String(Math.round(100*reviewed/Math.max(1,rows.length))));
    $('progress-fill').style.width=(100*reviewed/Math.max(1,rows.length))+'%';
    $('intro-count').textContent=rows.length;
    $('tab-library-count').textContent='('+rows.length+')';
    $('source-label').textContent='Advanced '+D.version;
  }
  function setupCategory(){const control=$('category');control.replaceChildren();
    control.append(new Option('All scenarios','all'));
    for(const category of [...new Set(D.phrases.map(p=>p.category))]) control.append(new Option(category,category));
    control.append(new Option('My phrases','custom'));
  }
  function settings(preset){return {preset};}
  function makeOutput(src,preset,extra={}){return E.transform(src,{...settings(preset),...extra});}
  function renderedOutput(output){const n=el('div','output');
    for(const part of output.parts){if(part.changed){const b=el('mark','highlight',part.text);b.title='From: '+part.source;n.append(b);}else n.append(document.createTextNode(part.text||''));}
    return n;
  }
  function translationCard(source,preset,live=false,extra={}){const result=makeOutput(source,preset,extra);
    const card=el('div',live?'translation':'translation');
    const heading=el('div','translation-head');heading.append(el('strong','',preset),el('small','',result.count+' '+(result.count===1?'change':'changes')));
    card.append(heading,renderedOutput(result));return card;
  }
  function phraseCard(p){
    const rev=saved.reviews[p.id]||{};
    const card=el('article','phrase-card'+(rev.status==='flagged'?' flagged':''));card.dataset.id=p.id;
    const heading=el('div','phrase-head'),meta=el('div','phrase-meta');
    meta.append(el('span','',p.category),el('span','separator','·'),el('span','',p.id));
    heading.append(meta);
    if(rev.status && rev.status!=='pending')heading.append(el('span','status-chip '+(rev.status==='approved'?'good':'flag'),rev.status==='approved'?'✓ Approved':'⚑ Flagged'));
    card.append(heading,el('div','original',p.text));
    const selection=$('preset').value, presets=selection==='All'?PRESETS:[selection];
    const grid=el('div','translation-grid'+(presets.length===1?' single':''));
    for(const preset of presets)grid.append(translationCard(p.text,preset));card.append(grid);
    const actions=el('div','card-actions');
    const good=el('button','action-approve'+(rev.status==='approved'?' active':''),'✓ Sounds good');good.type='button';good.setAttribute('aria-label','Approve phrase '+p.id);good.setAttribute('aria-pressed',rev.status==='approved');
    const flag=el('button','action-flag'+(rev.status==='flagged'?' active':''),'⚑ Flag awkward');flag.type='button';flag.setAttribute('aria-label','Flag phrase '+p.id);flag.setAttribute('aria-pressed',rev.status==='flagged');
    const copy=el('button','action-copy','Copy text');copy.type='button';
    good.addEventListener('click',()=>setReview(p.id,rev.status==='approved'?'pending':'approved'));
    flag.addEventListener('click',()=>setReview(p.id,rev.status==='flagged'?'pending':'flagged'));
    copy.addEventListener('click',()=>{const output=presets.map(k=>k+': '+makeOutput(p.text,k).text).join('\n');
      if(navigator.clipboard?.writeText) navigator.clipboard.writeText('Original: '+p.text+'\n'+output).then(()=>notice('Comparison copied.'),()=>notice('Copy not available in this browser.'));
      else notice('Clipboard access unavailable in this browser.');});
    actions.append(good,flag,copy);card.append(actions);
    if(rev.status==='flagged'){
      const wrap=el('div','note-area'),note=el('textarea');
      note.placeholder='What sounds off? Suggest the wording you would prefer…';note.value=rev.note||'';
      note.setAttribute('aria-label','Issue notes for '+p.id);
      note.maxLength=1500;
      note.addEventListener('input',()=>{saved.reviews[p.id] ||= {status:'flagged'};saved.reviews[p.id].note=note.value;persist();});
      wrap.append(note);card.append(wrap);
    }
    return card;
  }
  function setReview(id,status){const prev=saved.reviews[id]||{};
    if(status==='pending')delete saved.reviews[id];
    else saved.reviews[id]={status,note:prev.note||''};
    persist();updateStats();renderList();
  }
  function filtered(){
    const query=$('search').value.trim().toLowerCase(), category=$('category').value;
    const status=$('review-filter').value,changed=$('change-filter').value,preset=$('preset').value;
    return corpus().filter(p=>{
      if(category!=='all' && (category==='custom'?p.category!=='My phrases':p.category!==category))return false;
      if(query && !(p.text+' '+p.category+' '+p.id+' '+(saved.reviews[p.id]?.note||'')).toLowerCase().includes(query))return false;
      const s=saved.reviews[p.id]?.status||'pending';
      if(status!=='all' && s!==status)return false;
      if(changed!=='all'){
        const ps=preset==='All'?PRESETS:[preset];
        const any=ps.some(x=>makeOutput(p.text,x).count>0);
        if(changed==='changed'&&!any || changed==='untouched'&&any)return false;
      }
      return true;
    });
  }
  function renderList(){const rows=filtered(), visible=rows.slice(0,shown),list=$('phrase-list');
    list.replaceChildren(...visible.map(phraseCard));
    $('results-caption').textContent=rows.length+' matching '+(rows.length===1?'phrase':'phrases')+' · showing '+visible.length;
    $('load-more').hidden=visible.length>=rows.length;
    $('empty-state').hidden=rows.length>0;
  }
  function updateList(){shown=18;renderList();}
  function switchView(next){view=next;
    $('library-view').hidden=next!=='library';$('playground-view').hidden=next!=='playground';
    $('tab-library').classList.toggle('selected',next==='library');$('tab-playground').classList.toggle('selected',next==='playground');
    $('tab-library').setAttribute('aria-current',next==='library'?'page':'false');$('tab-playground').setAttribute('aria-current',next==='playground'?'page':'false');
    if(next==='playground')$('custom-input').focus();
  }
  function customPreview(){const src=$('custom-input').value;
    $('custom-length').textContent=src.length+' / 2500 characters';$('save-custom').disabled=!src.trim();
    const full=document.querySelector('input[name="custom-mode"]:checked')?.value!=='game';
    const extra=full?{reviewUnlimited:true}:{};
    const description=full
      ? 'Reviewing every eligible phrase throughout the passage. In-game, Subtle stops at 2 and Balanced at 3; Heavy is uncapped by default.'
      : 'Exact in-game simulation: Subtle stops after 2 changes, Balanced after 3; Heavy is unlimited by default.';
    $('custom-mode-note').textContent=description;
    const holder=$('custom-results');holder.replaceChildren(...PRESETS.map(p=>translationCard(src,p,true,extra)));
  }
  function download(name,text,type){const blob=new Blob([text],{type});const url=URL.createObjectURL(blob);
    const a=el('a');a.href=url;a.download=name;document.body.append(a);a.click();a.remove();setTimeout(()=>URL.revokeObjectURL(url),1000);
  }
  function exportReview(){const snapshot={format:'DwarvenAccentReview',version:1,addonVersion:D.version,sourceHash:D.sourceHash,
    exportedAt:new Date().toISOString(),reviews:corpus().filter(p=>saved.reviews[p.id]).map(p=>({id:p.id,category:p.category,original:p.text,
      status:saved.reviews[p.id].status,note:saved.reviews[p.id].note||'',
      translations:Object.fromEntries(PRESETS.map(pr=>[pr,makeOutput(p.text,pr).text]))})),custom:saved.custom};
    download('dwarven-accent-review.json',JSON.stringify(snapshot,null,2),'application/json');notice('Review exported as JSON.');
  }
  async function importReview(file){if(!file || file.size>3_000_000){notice('Choose a review JSON file smaller than 3 MB.');return;}
    try{const data=JSON.parse(await file.text());
      if(data.format!=='DwarvenAccentReview'||data.version!==1||!Array.isArray(data.reviews)||!Array.isArray(data.custom))throw Error('Unsupported review file');
      const customs=[];
      for(const p of data.custom.slice(0,300))if(typeof p.text==='string'&&p.text.length<=2500&&/^c_[0-9a-z_-]+$/i.test(p.id||''))customs.push({id:p.id,category:'My phrases',text:p.text});
      const ids=new Set([...D.phrases,...customs].map(p=>p.id)),merged={};
      for(const r of data.reviews.slice(0,2000))if(ids.has(r.id)&&['approved','flagged'].includes(r.status))merged[r.id]={status:r.status,note:typeof r.note==='string'?r.note.slice(0,1500):''};
      saved={custom:customs,reviews:merged};persist();updateStats();updateList();
      notice('Imported '+Object.keys(merged).length+' reviews'+(data.sourceHash!==D.sourceHash?' · Note: different engine version':'')+'.');
    }catch(error){notice('Import failed: '+error.message);}
    $('import-file').value='';
  }
  function init(){setupCategory();updateStats();
    for(const id of ['search','category','review-filter','change-filter','preset'])$(id).addEventListener(id==='search'?'input':'change',updateList);
    $('reset-filters').addEventListener('click',()=>{$('search').value='';$('category').value='all';$('review-filter').value='all';$('change-filter').value='all';$('preset').value='All';updateList();});
    $('load-more').addEventListener('click',()=>{shown+=18;renderList();});
    $('tab-library').addEventListener('click',()=>switchView('library'));
    $('tab-playground').addEventListener('click',()=>switchView('playground'));
    $('custom-input').addEventListener('input',customPreview);
    for(const radio of document.querySelectorAll('input[name="custom-mode"]'))
      radio.addEventListener('change',customPreview);
    for(const btn of document.querySelectorAll('[data-sample]'))btn.addEventListener('click',()=>{$('custom-input').value=btn.dataset.sample;customPreview();$('custom-input').focus();});
    $('save-custom').addEventListener('click',()=>{
      const text=$('custom-input').value.trim();if(!text)return;
      if(saved.custom.length>=300){notice('Custom phrase limit reached. Export your current work.');return;}
      const id='c_'+Date.now().toString(36)+'_'+Math.random().toString(36).slice(2,9);
      saved.custom.unshift({id,category:'My phrases',text});persist();updateStats();
      $('category').value='custom';$('search').value='';$('review-filter').value='all';$('change-filter').value='all';
      updateList();switchView('library');notice('Phrase saved to My phrases.');
    });
    $('export-button').addEventListener('click',exportReview);
    $('import-button').addEventListener('click',()=>$('import-file').click());
    $('import-file').addEventListener('change',e=>importReview(e.target.files?.[0]));
    $('clear-data').addEventListener('click',()=>{if(confirm('Clear all saved ratings, notes, and custom phrases in this browser? Export first if you want to keep them.')){
      saved={reviews:{},custom:[]};persist();updateStats();$('category').value='all';updateList();notice('Saved reviews cleared.');}});
    customPreview();renderList();
  }
  init();
})();
