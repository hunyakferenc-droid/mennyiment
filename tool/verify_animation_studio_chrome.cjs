// Actual Studio UI; intentionally reduced motion, native video tested separately.
const fs=require('node:fs'),path=require('node:path'),assert=require('node:assert/strict');
const {chromium,open,seed,snapshot,semantics,reach,strings,out,errors}=require('./verify_stabilization_226_chrome.cjs');
const source=process.env.MENTI_SOURCE_COMMIT;assert(/^[a-f0-9]{40}$/.test(source||''));
const checks=[];
async function studioReach(page,locator,description){
 try{return await reach(page,locator);}catch(error){
  const matches=await locator.evaluateAll(nodes=>nodes.map(n=>{const r=n.getBoundingClientRect();return {role:n.getAttribute('role'),label:n.getAttribute('aria-label'),x:r.x,y:r.y,width:r.width,height:r.height};})).catch(()=>[]);
  const tree=await page.locator('body').ariaSnapshot().catch(()=>'(unavailable)');
  console.error('Studio reach failed:',description,'matches:',JSON.stringify(matches),'viewport:',JSON.stringify(page.viewportSize()),'accessibility:',tree.slice(0,5000));
  throw error;
 }
}
(async()=>{const browser=await chromium.launch({executablePath:process.env.CHROME_BIN||'/usr/bin/chromium',headless:true,args:['--no-sandbox','--disable-dev-shm-usage']});let active;
try{for(const lang of ['hu','en']){
 const values=seed(lang);delete values['flutter.mennyiment_complete_look_v1'];
 const {context,page:p}=await open(browser,390,values);active=p;
 await p.waitForTimeout(400);if(lang==='en'){await p.getByRole('button',{name:'EN',exact:true}).evaluate(e=>e.click());await p.waitForTimeout(200);await semantics(p);}
 assert((await(await p.request.get('http://127.0.0.1:7357/build-info.txt')).text()).includes(source));
 const before=await snapshot(p);const s=strings[lang];await p.getByText(s.studioInventory,{exact:true}).waitFor();
 const bundled=await(await p.request.get('http://127.0.0.1:7357/assets/assets/menti_alive_review/catalog.json')).json();
 assert.equal(bundled.clips.length,5);
 assert(bundled.clips.some(c=>c.lookId==='girl-base-v1'&&c.reaction==='thinking'));
 assert(bundled.clips.some(c=>c.lookId==='neutral-base-v1'&&c.reaction==='welcome'));
 await p.getByRole('checkbox',{name:lang==='hu'?'Jóváhagyásra vár: 5':'Awaiting approval: 5',exact:true}).waitFor();
 await p.getByRole('checkbox',{name:lang==='hu'?'Hiányzik: 247':'Missing: 247',exact:true}).waitFor();
 for(const [family,label] of [['girl',s.collectionGirl],['neutral',s.collectionNeutral],['boy',s.collectionBoy]]){
  const chip=p.getByRole('checkbox',{name:label,exact:true});await studioReach(p,chip,`${lang}/${family} family chip`);await chip.evaluate(e=>e.click());await p.waitForTimeout(150);await semantics(p);
  const selector=p.getByRole('button',{name:new RegExp('^'+s.aliveSelection)});await studioReach(p,selector,`${lang}/${family} selector`);await selector.evaluate(e=>e.click());await p.waitForTimeout(150);await semantics(p);
  // All six choices are present in the Flutter dropdown, independent of XP.
  const body=await p.locator('body').ariaSnapshot();assert(body.includes(s.collectionLegendary));
  await p.keyboard.press('Escape');await p.waitForTimeout(150);await semantics(p);
  await p.mouse.move(280,250);await p.mouse.wheel(0,-30000);await p.waitForTimeout(200);
  await p.screenshot({path:path.join(out,`studio-${family}-${lang}-390.png`)});
  assert.deepEqual(await snapshot(p),before);checks.push(`${lang}/${family}: all six choices, inventory and unchanged saved data`);
 }
 const events=p.getByRole('button',{name:s.studioEvents,exact:true});await studioReach(p,events,`${lang} events`);await events.evaluate(e=>e.click());await p.waitForTimeout(150);await semantics(p);
 await p.getByText(s.studioEventHint,{exact:true}).waitFor();assert.deepEqual(await snapshot(p),before);
 checks.push(`${lang}: event simulation is clearly marked and read-only`);
 assert.deepEqual(errors,[]);p.closing=true;await context.close();active=null;
}
// Separate codec smoke on actual bundled girl/neutral MP4 bytes. The native
// integration suite checks the full Studio button -> shared player route.
const clips=JSON.parse(fs.readFileSync(path.join(__dirname,'menti_animation_studio/review_assets/catalog.json'))).clips;
const codecPage=await browser.newPage();await codecPage.goto('http://127.0.0.1:7357');
for(const clip of clips){const url='http://127.0.0.1:7357/assets/'+clip.asset;const body=await(await codecPage.request.get(url)).body();assert.equal(require('node:crypto').createHash('sha256').update(body).digest('hex'),clip.sha256);
 const result=await codecPage.evaluate(async url=>{const v=document.createElement('video');v.muted=true;v.playsInline=true;v.src=url;document.body.append(v);try{await v.play();await new Promise((resolve,reject)=>{const started=performance.now();const tick=()=>{if(v.currentTime>.2)resolve();else if(performance.now()-started>10000)reject(Error('decoder timeout'));else setTimeout(tick,30)};tick()});return {width:v.videoWidth,height:v.videoHeight,muted:v.muted};}finally{v.pause();v.remove();}},url);
 assert.deepEqual(result,{width:540,height:720,muted:true});checks.push(clip.lookId+': exact bundled bytes decode in native browser codec (separate smoke)');}
await codecPage.close();
fs.writeFileSync(path.join(out,'studio-chrome-verification.json'),JSON.stringify({sourceCommit:source,version:'3.0.0+42',realWindows:process.platform==='win32',browser:browser.version(),checks,runtimeErrors:errors},null,2)+'\n');console.log(checks.length+' Studio checks passed');
}catch(e){if(active&&!active.isClosed()){await active.screenshot({path:path.join(out,'studio-failure.png')}).catch(()=>{});fs.writeFileSync(path.join(out,'studio-failure-dom.txt'),await active.locator('body').ariaSnapshot().catch(()=>''));}throw e;}finally{await browser.close();}})().catch(e=>{console.error(e);process.exitCode=1;});
