/* Exact release build, synthetic local data only. No real browser profile. */
const fs=require('node:fs'),path=require('node:path'),assert=require('node:assert/strict');
const {chromium,open,seed,semantics,screenshot,snapshot,strings,out,errors,cancelled}=require('./verify_stabilization_226_chrome.cjs');
const url=process.env.MENTI_WEB_URL||'http://127.0.0.1:7357';
const key='flutter.mennyiment_adventures_v1',wellbeing='flutter.mennyiment_wellbeing_v1';
const checks=[];
const sourceCommit=process.env.MENTI_SOURCE_COMMIT;
assert(/^[0-9a-f]{40}$/.test(sourceCommit||''),'Set MENTI_SOURCE_COMMIT to the exact built source');
const button=(p,n)=>p.getByRole('button',{name:n,exact:true});
const text=(p,n)=>p.getByText(n,{exact:false}).or(p.getByLabel(n,{exact:false})).first();
const decode=v=>JSON.parse(JSON.parse(v));
const taskButton=(p,id,name)=>p.locator(`[flt-semantics-identifier="adventure-task-${id}"]`).getByRole('button',{name,exact:true});
async function ready(p){const end=performance.now()+45000;while(p.pendingRequests.size||Date.now()-p.lastNetworkActivity<800){if(performance.now()>end)throw Error('Assets did not settle');await p.waitForTimeout(100);}}
async function reach(p,l){
 for(let i=0;i<65;i++){
  const boxes=await l.evaluateAll(nodes=>nodes.map(e=>{const r=e.getBoundingClientRect();return {x:r.x,y:r.y,w:r.width,h:r.height};}));
  const b=boxes.find(x=>x.w>0&&x.h>0),v=p.viewportSize();
  const nav=await p.getByRole('tablist').evaluateAll(nodes=>nodes.map(n=>n.getBoundingClientRect().top));
  const bottom=nav.find(y=>y>v.height*.5)||v.height;
  if(b&&b.x>=0&&b.x+b.w<=v.width+1&&b.y+b.h/2>132&&b.y+b.h/2<bottom-8)return l;
  await p.mouse.move(v.width*.75,v.height*.7);await p.mouse.wheel(0,b&&b.y<132?-240:240);await p.waitForTimeout(100);
 }
 throw Error('Unreachable adventure control: '+await l.count());
}
async function act(p,l){await semantics(p);await reach(p,l);await l.evaluate(e=>e.click());await p.waitForTimeout(180);await semantics(p);}
async function fixed(p,l){await l.waitFor();await l.evaluate(e=>e.click());await p.waitForTimeout(200);await semantics(p);}
async function fields(p,label,value){const l=p.getByRole('textbox',{name:label,exact:false}).first();await reach(p,l);await l.click({noWaitAfter:true});await p.keyboard.press('Control+A');await p.keyboard.type(value);await p.keyboard.press('Tab');await p.waitForTimeout(100);}
async function protect(p,before){const after=await snapshot(p);const a={...after},b={...before};delete a[key];delete b[key];delete a[wellbeing];delete b[wellbeing];assert.deepEqual(a,b,'Adventure changed journal/profile/age/XP/unlocks/settings');return decode(after[key]);}
(async()=>{
 const browser=await chromium.launch({executablePath:process.env.CHROME_BIN||'/usr/bin/chromium',headless:true,args:['--no-sandbox','--disable-dev-shm-usage','--force-renderer-accessibility']});let active;
 try{
  for(const locale of (process.env.MENTI_LOCALES||'hu,en').split(','))for(const width of (process.env.MENTI_WIDTHS||'320,360,390,430').split(',').map(Number)){
   const values=seed(locale);delete values[key];const s=strings[locale];
   const {context,page:p}=await open(browser,width,values,p=>{
    active=p;p.externalRequests=[];
    p.on('request',r=>{if(new URL(r.url()).origin!==new URL(url).origin)p.externalRequests.push(r.url());});
   });active=p;
   assert((await (await p.request.get(url+'/build-info.txt')).text()).includes('source_commit='+sourceCommit));
   assert.equal((await (await p.request.get(url+'/version.json')).json()).version,'2.3.0');
   assert.equal((await (await p.request.get(url+'/version.json')).json()).build_number,'33');
   await button(p,s.chooseMenti).waitFor();await ready(p);const before=await snapshot(p);
   await act(p,button(p,s.adventureTitle));await p.getByRole('tab',{name:s.adventureMap,exact:true}).waitFor();
   await screenshot(p,`missions-${locale}-${width}`);
   // Cancel before completion: selecting again must not duplicate a reward.
   await act(p,taskButton(p,'movement',s.adventureChoose));
   await act(p,button(p,s.adventureCancel).first());
   await fixed(p,button(p,s.adventureCancel).last());
   let state=await protect(p,before);let today=Object.keys(state.days)[0];
   assert.equal(state.days[today].movement.status,'cancelled');
   await act(p,taskButton(p,'movement',s.adventureResume));
   await act(p,button(p,s.adventureComplete).first());
   await fixed(p,button(p,s.adventureLater));
   state=await protect(p,before);assert.equal(state.days[today].movement.status,'active');
   await act(p,button(p,s.adventureComplete).first());await fixed(p,button(p,s.adventureComplete).last());
   await screenshot(p,`celebration-${locale}-${width}`);
   // The short celebration may disappear between separate locator operations.
   await button(p,s.adventureSkipFeedback).evaluateAll(nodes=>nodes.forEach(node=>node.click()));
   state=await protect(p,before);assert.equal(state.days[today].movement.status,'completed');assert.equal(Object.keys(state.badges).length,1);
   checks.push(`${locale} ${width}px: choose, cancel, resume, cancel completion dialog, then one confirmed self-report; one badge and protected existing data`);
   // Complete wellbeing from the real existing route in the deep 390px cases.
   const third=width===390?'wellbeing':'rest';
   if(third==='wellbeing'){
    await p.mouse.move(width*.7,300);await p.mouse.wheel(0,-12000);await p.waitForTimeout(200);
    await act(p,taskButton(p,'wellbeing',s.adventureChoose));
    await act(p,button(p,s.adventureVerify));
    state=await protect(p,before);assert.equal(state.days[today].wellbeing.status,'active');
    await act(p,button(p,s.adventureOpenWellbeing));await button(p,s.wellbeingSave).waitFor();
    await act(p,button(p,s.wellbeingSave));await text(p,s.wellbeingSaved).waitFor();
    await ready(p);await fixed(p,button(p,locale==='hu'?'Vissza':'Back'));
    await act(p,button(p,s.adventureVerify));
   }else{
    // Select Rest by its named card, without depending on button order after a rebuild.
    await act(p,taskButton(p,'rest',s.adventureChoose));
    await act(p,button(p,s.adventureComplete).first());await fixed(p,button(p,s.adventureComplete).last());
   }
   // The short celebration may disappear between separate locator operations.
   await button(p,s.adventureSkipFeedback).evaluateAll(nodes=>nodes.forEach(node=>node.click()));
   state=await protect(p,before);assert.equal(state.days[today][third].status,'completed');
   // Decision note is persisted only through an explicit confirmation.
   await act(p,taskButton(p,'decision',s.adventureChoose));
   await act(p,button(p,s.adventureComplete).first());
   await fields(p,s.adventureDecisionHint,locale==='hu'?'Tartottam egy nyugodt szünetet.':'I took a quiet break.');
   await screenshot(p,`decision-${locale}-${width}`);await fixed(p,button(p,s.adventureComplete).last());
   // The short celebration may disappear between separate locator operations.
   await button(p,s.adventureSkipFeedback).evaluateAll(nodes=>nodes.forEach(node=>node.click()));
   state=await protect(p,before);assert.equal(Object.values(state.days[today]).filter(x=>x.status==='completed').length,3);assert.deepEqual(Object.keys(state.badges).sort(),['first','station','variety']);
   assert.equal(state.days[today].decision.reactionConsumed,true);assert(state.days[today].decision.note.length>0);
   checks.push(`${locale} ${width}px: three actual completions grant first station and three dated badges; wellbeing is data-verified in 390px cases, manual activities are explicitly self-reported`);
   await fixed(p,p.getByRole('tab',{name:s.adventureMap,exact:true}));
   await reach(p,text(p,s.adventureStationCurrent));
   await reach(p,text(p,'girl adult'));
   await screenshot(p,`map-${locale}-${width}`);
   assert((await p.locator('body').ariaSnapshot()).includes('girl adult'));
   await fixed(p,p.getByRole('tab',{name:s.adventureBadges,exact:true}));
   await reach(p,text(p,s.adventureBadgeStation));
   await screenshot(p,`badges-${locale}-${width}`);
   const encoded=(await snapshot(p))[key];await ready(p);p.reloading=true;
   await p.reload({waitUntil:'networkidle'});await semantics(p);await button(p,s.chooseMenti).waitFor();await ready(p);p.reloading=false;
   await act(p,button(p,s.adventureTitle));assert.equal((await snapshot(p))[key],encoded);
   assert.equal(await button(p,s.adventureSkipFeedback).count(),0);await protect(p,before);
   await screenshot(p,`reloaded-${locale}-${width}`);
   assert.deepEqual(p.externalRequests,[]);
   checks.push(`${locale} ${width}px: application reload preserves selected/completed state and badges, never replays a celebration, and makes no external request`);
   await context.close();active=null;process.stdout.write(`Passed ${locale} ${width}px\n`);
  }
  assert.deepEqual(errors,[]);fs.writeFileSync(path.join(out,'verification.json'),JSON.stringify({sourceCommit,completedAt:new Date().toISOString(),browser:browser.version(),checks,runtimeErrors:errors,intentionalReloadCancellations:cancelled},null,2));process.stdout.write(`${checks.length} browser checks passed\n`);
 }catch(e){if(active){fs.writeFileSync(path.join(out,'failure-dom.txt'),await active.locator('body').ariaSnapshot().catch(()=>''));await active.screenshot({path:path.join(out,'failure.png')}).catch(()=>{});}fs.writeFileSync(path.join(out,'failure.json'),JSON.stringify({error:String(e),checks,runtimeErrors:errors},null,2));throw e;}finally{await browser.close();}
})().catch(e=>{console.error(e);process.exitCode=1;});
