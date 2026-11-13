/* Real application UI, isolated synthetic preferences, no production profile. */
const fs=require('node:fs'),path=require('node:path'),assert=require('node:assert/strict');
const {chromium,open,seed,semantics,screenshot,snapshot,strings,out,errors}=require('./verify_stabilization_226_chrome.cjs');
const source=process.env.MENTI_SOURCE_COMMIT; assert(/^[0-9a-f]{40}$/.test(source||''));
const key='flutter.mennyiment_complete_look_v1',checks=[],metrics=[];
const dialog=p=>p.getByRole('dialog').or(p.getByRole('alertdialog'));
const button=(p,name)=>p.getByRole('button',{name,exact:true});
const decode=x=>JSON.parse(JSON.parse(x));
async function ready(p){const until=Date.now()+60000;while(p.pendingRequests.size||Date.now()-p.lastNetworkActivity<500){if(Date.now()>until)throw Error('Assets did not settle');await p.waitForTimeout(100);}}
async function top(p){await p.mouse.move(p.viewportSize().width*.7,250);await p.mouse.wheel(0,-30000);await p.waitForTimeout(150);}
async function act(p,l){await semantics(p);for(let n=0;n<80;n++){const b=await l.boundingBox();const h=p.viewportSize().height;if(b&&b.y+b.height/2>115&&b.y+b.height/2<h-10){await l.evaluate(e=>e.click());await p.waitForTimeout(180);await semantics(p);return;}await p.mouse.move(p.viewportSize().width*.7,h*.6);await p.mouse.wheel(0,b&&b.y<115?-250:250);await p.waitForTimeout(75);}throw Error('Unreachable '+await l.count());}
async function fixed(p,l){await l.waitFor();await l.evaluate(e=>e.click());await p.waitForTimeout(200);await semantics(p);}
async function back(p,locale){await fixed(p,button(p,locale==='hu'?'Vissza':'Back'));}
async function home(p,locale,s){for(let n=0;n<4;n++){if(await button(p,s.visualStudio).count()){await top(p);return;}await back(p,locale);}throw Error('Home route missing');}
async function gallery(p,s){await top(p);await act(p,button(p,s.visualStudio));await ready(p);if(await button(p,s.completeTitle).count())await fixed(p,button(p,s.completeTitle));await p.getByRole('heading',{name:s.completeTitle,exact:true}).waitFor();}
async function choose(p,name){const rx=new RegExp(name.replace(/[.*+?^${}()|[\]\\]/g,'\\$&'));await act(p,p.getByRole('button',{name:rx}).last());}
(async()=>{const browser=await chromium.launch({executablePath:process.env.CHROME_BIN||'/usr/bin/chromium',headless:true,args:['--no-sandbox','--disable-dev-shm-usage']});let active;
try{for(const locale of ['hu','en']){const s=strings[locale],width=390,external=[];
const {context,page:p}=await open(browser,width,seed(locale),p=>{p.on('request',r=>{if(new URL(r.url()).origin!=='http://127.0.0.1:7357')external.push(r.url());});});active=p;p.setDefaultTimeout(120000);
const provenance=await(await p.request.get('http://127.0.0.1:7357/build-info.txt')).text();assert(provenance.includes(source));
await button(p,s.visualStudio).waitFor();await ready(p);const before=await snapshot(p);await screenshot(p,`legacy-home-${locale}-${width}`);
await gallery(p,s);await choose(p,s.completeGirl);assert.deepEqual(await snapshot(p),before);await act(p,button(p,s.avatarCancel));await dialog(p).waitFor();await fixed(p,dialog(p).getByRole('button',{name:s.avatarCancel,exact:true}));assert.deepEqual(await snapshot(p),before);await back(p,locale);await fixed(p,dialog(p).getByRole('button',{name:s.completeLeave,exact:true}));await home(p,locale,s);assert.deepEqual(await snapshot(p),before);checks.push(`${locale}: preview and both cancel/back confirmation paths write nothing`);
for(const [id,name]of [['boy-base-v1',s.completeBoy],['girl-base-v1',s.completeGirl],['neutral-base-v1',s.completeNeutral]]){
 await gallery(p,s);await choose(p,name);await top(p);await screenshot(p,`gallery-${id}-${locale}-${width}`);
 const start=Date.now();await act(p,button(p,s.avatarEnlargePreview));await ready(p);await screenshot(p,`enlarged-${id}-${locale}-${width}`);metrics.push({locale,id,enlargeAndSettleMs:Date.now()-start});await fixed(p,dialog(p).getByRole('button',{name:s.avatarClosePreview,exact:true}));
 await act(p,button(p,s.avatarSave));await p.waitForFunction(([key,id])=>{const raw=localStorage.getItem(key);if(!raw)return false;const x=JSON.parse(JSON.parse(raw));return x.active&&x.look===id;},[key,id]);await home(p,locale,s);await ready(p);await screenshot(p,`complete-home-${id}-${locale}-${width}`);
 const saved=await snapshot(p);for(const[k,v]of Object.entries(before))assert.equal(saved[k],v,`Unrelated data changed: ${k}`);
 p.reloading=true;await p.reload({waitUntil:'networkidle'});await semantics(p);await button(p,s.visualStudio).waitFor();await ready(p);p.reloading=false;assert.deepEqual(await snapshot(p),saved);
 await act(p,button(p,s.adventureTitle));await fixed(p,p.getByRole('tab',{name:s.adventureMap,exact:true}));await screenshot(p,`adventure-${id}-${locale}-${width}`);await back(p,locale);await home(p,locale,s);
 await fixed(p,button(p,s.avatarMore));await fixed(p,p.getByRole('menuitem',{name:s.profile,exact:true}));await screenshot(p,`profile-${id}-${locale}-${width}`);await back(p,locale);await home(p,locale,s);
 checks.push(`${locale} ${id}: select/save/reload and gallery/enlarged/home/profile/adventure use the persisted choice; old data byte-identical`);
}
// Real file download, state change, file picker, preview and confirmed restore.
await fixed(p,button(p,s.avatarMore));await fixed(p,p.getByRole('menuitem',{name:s.backupTitle,exact:true}));await act(p,button(p,s.backupPrepare));const download=p.waitForEvent('download');await act(p,button(p,s.backupSave));const destination=path.join(out,`complete-export-${locale}.json`);await(await download).saveAs(destination);const exported=JSON.parse(fs.readFileSync(destination));assert.equal(JSON.parse(exported.entries.mennyiment_complete_look_v1.value).look,'neutral-base-v1');await back(p,locale);await home(p,locale,s);
await gallery(p,s);await choose(p,s.completeGirl);await act(p,button(p,s.avatarSave));await home(p,locale,s);
await fixed(p,button(p,s.avatarMore));await fixed(p,p.getByRole('menuitem',{name:s.backupTitle,exact:true}));const chooser=p.waitForEvent('filechooser');await act(p,button(p,s.restorePick));await(await chooser).setFiles(destination);await act(p,button(p,s.restoreConfirm));await fixed(p,dialog(p).getByRole('button',{name:s.restoreConfirm,exact:true}));await button(p,s.visualStudio).waitFor();assert.equal(decode((await snapshot(p))[key]).look,'neutral-base-v1');await screenshot(p,`restored-home-${locale}-${width}`);
await gallery(p,s);await act(p,button(p,s.completeLegacy));await act(p,button(p,s.avatarSave));await home(p,locale,s);assert.equal(decode((await snapshot(p))[key]).active,false);const after=await snapshot(p);for(const[k,v]of Object.entries(before))assert.equal(after[k],v);await screenshot(p,`legacy-return-${locale}-${width}`);checks.push(`${locale}: actual backup file download, choice change, file import/preview/restore returns the saved sample; legacy switch preserves old outfit/XP/unlocks`);
assert.deepEqual(external,[]);assert.deepEqual(errors,[]);p.closing=true;await context.close();active=null;console.log('Passed '+locale);
}
fs.writeFileSync(path.join(out,'complete-verification.json'),JSON.stringify({sourceCommit:source,version:'2.5.0+37',browser:browser.version(),checks,metrics,runtimeErrors:errors,physicalAndroid:false,emulator:false,realWindows:false,textScale:'Chrome normal; 200% text and keyboard independently tested by Flutter widgets.'},null,2)+'\n');console.log(`${checks.length} complete-look checks passed`);
}catch(e){if(active&&!active.isClosed()){fs.writeFileSync(path.join(out,'complete-failure-dom.txt'),await active.locator('body').ariaSnapshot().catch(()=>''));await active.screenshot({path:path.join(out,'complete-failure.png')}).catch(()=>{});}throw e;}finally{await browser.close();}})().catch(e=>{console.error(e);process.exitCode=1;});
