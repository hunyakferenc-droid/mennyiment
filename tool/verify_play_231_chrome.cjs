/* Exact CI web build; isolated synthetic storage, no real user profile. */
const fs=require('node:fs'),path=require('node:path'),assert=require('node:assert/strict');
const {chromium,open,seed,semantics,screenshot,snapshot,observe,strings,out,errors,cancelled,closedCancelled}=require('./verify_stabilization_226_chrome.cjs');
const url=process.env.MENTI_WEB_URL||'http://127.0.0.1:7357';
const sourceCommit=process.env.MENTI_SOURCE_COMMIT;
assert(/^[0-9a-f]{40}$/.test(sourceCommit||''),'Exact built MENTI_SOURCE_COMMIT is required');
const checks=[],candidates=[];
const button=(p,n)=>p.getByRole('button',{name:n,exact:true});
const text=(p,n)=>p.getByText(n,{exact:false}).or(p.getByLabel(n,{exact:false})).first();
async function ready(p){const end=Date.now()+45000;while(p.pendingRequests.size||Date.now()-p.lastNetworkActivity<800){if(Date.now()>end)throw Error('Assets did not settle');await p.waitForTimeout(100);}}
async function top(p){await p.mouse.move(p.viewportSize().width*.7,300);await p.mouse.wheel(0,-20000);await p.waitForTimeout(160);}
async function reach(p,l){
 for(let i=0;i<90;i++){
  const boxes=await l.evaluateAll(nodes=>nodes.map(e=>{const r=e.getBoundingClientRect();return {x:r.x,y:r.y,w:r.width,h:r.height};})),v=p.viewportSize();
  const b=boxes.find(x=>x.w>0&&x.h>0);
  if(b&&b.x>=0&&b.x+b.w<=v.width+1&&b.y+b.h/2>60&&b.y+b.h/2<v.height-20)return l;
  await p.mouse.move(v.width*.75,v.height*.7);await p.mouse.wheel(0,b&&b.y<60?-220:220);await p.waitForTimeout(90);
 }
 throw Error('Unreachable information control: '+await l.count());
}
async function act(p,l){await semantics(p);await reach(p,l);await l.evaluate(e=>e.click());await p.waitForTimeout(200);await semantics(p);}
async function fixed(p,l){await l.waitFor();await l.evaluate(e=>e.click());await p.waitForTimeout(200);await semantics(p);}
async function back(p,locale){await ready(p);await fixed(p,button(p,locale==='hu'?'Vissza':'Back'));}
async function settings(p,s){await fixed(p,button(p,s.avatarMore));await fixed(p,p.getByRole('menuitem',{name:s.experienceSettings,exact:true}));await button(p,s.infoDataTitle).waitFor();}
async function metadata(p){assert((await (await p.request.get(url+'/build-info.txt')).text()).includes('source_commit='+sourceCommit));const v=await(await p.request.get(url+'/version.json')).json();assert.equal(v.version,'2.3.1');assert.equal(v.build_number,'34');}
function external(p){p.externalRequests=[];p.on('request',r=>{if(new URL(r.url()).origin!==new URL(url).origin)p.externalRequests.push(r.url());});}
function fixture(locale){const values=seed(locale);const identity=JSON.parse(JSON.parse(values['flutter.mennyiment_identity_v22']));identity.profile.name='Mira';values['flutter.mennyiment_identity_v22']=JSON.stringify(JSON.stringify(identity));values['flutter.mennyiment_drinks_v1']=JSON.stringify(JSON.stringify([
 {name:locale==='hu'?'Citromos víz':'Lemon water',ml:300,percent:0,priceFt:0,time:'2026-11-13T08:10:00.000',future:'preserve'},
 {name:locale==='hu'?'Gyümölcstea':'Fruit tea',ml:250,percent:0,time:'2026-11-13T09:20:00.000',future:'preserve'}]));return values;}
(async()=>{
 const browser=await chromium.launch({executablePath:process.env.CHROME_BIN||'/usr/bin/chromium',headless:true,args:['--no-sandbox','--disable-dev-shm-usage','--force-renderer-accessibility']});let active;
 try{
  for(const locale of (process.env.MENTI_LOCALES||'hu,en').split(','))for(const width of (process.env.MENTI_WIDTHS||'320,360,390,430').split(',').map(Number)){
   const s=strings[locale],{context,page:p}=await open(browser,width,fixture(locale),external);active=p;
   await metadata(p);await button(p,s.chooseMenti).waitFor();await ready(p);const before=await snapshot(p);
   await settings(p,s);await act(p,button(p,s.infoDataTitle));await screenshot(p,`data-top-${locale}-${width}`);
   for(const name of ['Records','Profile','Device','Browser','Protection','Backup','Restore','Internet','Permissions'])await reach(p,text(p,s[`info${name}Title`]));
   await screenshot(p,`data-permissions-${locale}-${width}`);
   checks.push(`${locale} ${width}px: all nine data/storage/backup/internet/permission sections are reachable`);
   await top(p);await act(p,button(p,s.infoBackupOpen));await text(p,s.backupTitle).waitFor();
   await act(p,button(p,s.backupPrepare));
   const download=p.waitForEvent('download');await act(p,button(p,s.backupSave));const file=await download;
   const destination=path.join(out,`read-only-export-${locale}-${width}.json`);await file.saveAs(destination);
   const exported=JSON.parse(fs.readFileSync(destination));assert.equal(exported.format,'mennyiment.local-backup');assert(exported.entries.mennyiment_drinks_v1);assert.deepEqual(await snapshot(p),before);
   await screenshot(p,`backup-existing-${locale}-${width}`);await back(p,locale);await back(p,locale);
   checks.push(`${locale} ${width}px: settings data center uses the existing real file export route; downloaded JSON is valid and viewing/exporting changes no preference`);
   await act(p,button(p,s.infoAboutTitle));await text(p,s.infoVersion.replace('{version}','2.3.1').replace('{build}','34')).waitFor();
   await screenshot(p,`about-${locale}-${width}`);
   await reach(p,button(p,s.infoLicenses));await act(p,button(p,s.infoLicenses));await reach(p,text(p,'Roboto'));await back(p,locale);
   await act(p,button(p,s.infoHelpTitle));
   for(const name of ['SelfReport','Journal','Editor','Prices','Goals','Adventures'])await reach(p,text(p,s[`info${name}Title`]));
   await screenshot(p,`help-${locale}-${width}`);await reach(p,button(p,s.infoBackupOpen));await screenshot(p,`help-backup-${locale}-${width}`);
   assert.deepEqual(await snapshot(p),before);
   checks.push(`${locale} ${width}px: actual version/build 2.3.1+34, bundled licenses, journal/editor/goals/adventures and missing versus zero-price help are reachable without writes`);
   await ready(p);p.reloading=true;await p.reload({waitUntil:'networkidle'});await semantics(p);await button(p,s.chooseMenti).waitFor();await ready(p);p.reloading=false;
   assert.deepEqual(await snapshot(p),before);await settings(p,s);await act(p,button(p,s.infoAboutTitle));await text(p,s.infoVersion.replace('{version}','2.3.1').replace('{build}','34')).waitFor();
   assert.deepEqual(p.externalRequests,[]);checks.push(`${locale} ${width}px: reload preserves all existing preferences; fresh About metadata remains correct; tested routes make no external request`);
   await ready(p);p.closing=true;await context.close();active=null;process.stdout.write(`Passed ${locale} ${width}px\n`);
  }
  if(process.env.MENTI_STORE_CANDIDATES!=='0')for(const locale of ['hu','en']){
   const s=strings[locale],context=await browser.newContext({viewport:{width:360,height:640},deviceScaleFactor:3,reducedMotion:'reduce'});
   await context.addInitScript(v=>{for(const[k,x]of Object.entries(v))localStorage.setItem(k,x);},fixture(locale));
   const p=await context.newPage();observe(p);external(p);active=p;await p.goto(url,{waitUntil:'networkidle'});await semantics(p);await metadata(p);await button(p,s.chooseMenti).waitFor();
   const folder=path.join(out,'store-candidates');fs.mkdirSync(folder,{recursive:true});
   async function capture(screen,hu,en){await ready(p);await p.mouse.move(1,1);await p.waitForTimeout(1000);const name=`${screen}-${locale}.jpg`,file=path.join(folder,name);await p.screenshot({path:file,type:'jpeg',quality:94});candidates.push({file:'store-candidates/'+name,locale,screen,width:1080,height:1920,logicalViewport:'360x640',deviceScaleFactor:3,sourceCommit,sha256:require('node:crypto').createHash('sha256').update(fs.readFileSync(file)).digest('hex'),alt:{hu,en},capture:'Unedited actual Flutter web in Chrome; synthetic data; not a physical Android capture'});}
   await capture('home','Mira Mentije a kezdőlapon, helyi próbaadatokkal.','Mira’s Menti on the home screen with local sample data.');
   await act(p,button(p,s.adventureTitle));await fixed(p,p.getByRole('tab',{name:s.adventureMap,exact:true}));await capture('adventures','Önkéntes Menti-kalandok térképe és állomásai.','The map and stations of voluntary Menti adventures.');await back(p,locale);
   await fixed(p,p.getByRole('tab',{name:s.journal,exact:false}));await p.getByRole('textbox',{name:s.journalSearch,exact:true}).waitFor();await capture('journal','Kereshető napló ismert nulla forintos és hiányzó árral.','Searchable journal with a known zero price and a missing price.');await back(p,locale);
   await settings(p,s);await act(p,button(p,s.infoDataTitle));await capture('data','Adatok és biztonság: helyi tárolás és a meglévő fájlos mentés.','Data and safety: local storage and the existing file backup.');
   assert.deepEqual(p.externalRequests,[]);await ready(p);p.closing=true;await context.close();active=null;
  }
  assert.deepEqual(errors,[]);
  fs.writeFileSync(path.join(out,'store-candidates.json'),JSON.stringify({sourceCommit,candidates,physicalAndroid:false,edited:false},null,2)+'\n');
  fs.writeFileSync(path.join(out,'verification.json'),JSON.stringify({sourceCommit,completedAt:new Date().toISOString(),browser:browser.version(),version:'2.3.1+34',checks,runtimeErrors:errors,intentionalReloadCancellations:cancelled,intentionalContextCloseCancellations:closedCancelled,physicalAndroid:false,emulator:false,textScale:'Chrome normal; true Flutter 200% text in all 320/360/390/430 HU/EN widget cases.'},null,2)+'\n');
  process.stdout.write(`${checks.length} browser checks and ${candidates.length} store candidates passed\n`);
 }catch(e){if(active&&!active.isClosed()){fs.writeFileSync(path.join(out,'failure-dom.txt'),await active.locator('body').ariaSnapshot().catch(()=>''));await active.screenshot({path:path.join(out,'failure.png')}).catch(()=>{});}fs.writeFileSync(path.join(out,'failure.json'),JSON.stringify({error:String(e),checks,runtimeErrors:errors},null,2));throw e;}finally{await browser.close();}
})().catch(e=>{console.error(e);process.exitCode=1;});
