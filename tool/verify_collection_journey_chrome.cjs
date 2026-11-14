/* New-user complete-look onboarding and real daily-XP threshold UI; synthetic isolated data. */
const fs=require('node:fs'),path=require('node:path'),assert=require('node:assert/strict');
const {chromium,open,seed,semantics,observe,screenshot,snapshot,strings,out,errors}=require('./verify_stabilization_226_chrome.cjs');
const source=process.env.MENTI_SOURCE_COMMIT;assert(/^[0-9a-f]{40}$/.test(source||''));
const url='http://127.0.0.1:7357',checks=[];
const button=(p,name)=>p.getByRole('button',{name,exact:true});
const doc=(values,suffix)=>JSON.parse(JSON.parse(values['flutter.mennyiment_'+suffix]));
async function click(p,l){for(let i=0;i<100;i++){const boxes=await l.evaluateAll(ns=>ns.map(n=>{const r=n.getBoundingClientRect();return {x:r.x,y:r.y,width:r.width,height:r.height}}));const b=boxes.find(r=>r.width&&r.height);if(b&&b.y+b.height/2>115&&b.y+b.height/2<p.viewportSize().height-8){await l.evaluate(e=>e.click());await p.waitForTimeout(150);await semantics(p);return;}await p.mouse.move(p.viewportSize().width*.7,p.viewportSize().height*.55);await p.mouse.wheel(0,b&&b.y<115?-250:250);await p.waitForTimeout(70);}throw Error('Unreachable '+await l.count());}
async function top(p){await p.mouse.move(250,240);await p.mouse.wheel(0,-30000);await p.waitForTimeout(150);}
(async()=>{const browser=await chromium.launch({executablePath:process.env.CHROME_BIN||'/usr/bin/chromium',headless:true,args:['--no-sandbox','--disable-dev-shm-usage']});let active;
try{
 for(const locale of ['hu','en']){
  const s=strings[locale];const context=await browser.newContext({viewport:{width:390,height:844},reducedMotion:'reduce'});
  await context.addInitScript(locale=>{localStorage.setItem('flutter.mennyiment_locale_v1',JSON.stringify(locale));localStorage.setItem('flutter.mennyiment_reduce_motion_v1','true');},locale);
  const p=await context.newPage();active=p;observe(p);p.setDefaultTimeout(120000);await p.goto(url,{waitUntil:'networkidle'});await semantics(p);
  assert((await(await p.request.get(url+'/build-info.txt')).text()).includes(source));
  await click(p,button(p,s.experienceIntroNext));await click(p,p.getByRole('radio',{name:s.startMinor,exact:true}));
  await click(p,button(p,s.experienceIntroBack));await p.getByText(s.startLanguage,{exact:true}).waitFor();
  await click(p,button(p,s.experienceIntroNext));await click(p,button(p,s.experienceIntroNext));
  await click(p,p.getByRole('checkbox',{name:s.collectionGirl,exact:true}));
  const girlName=s.collectionLookName.replace('{family}',s.collectionGirl).replace('{style}',s.collectionParty);
  // The card's name precedes its Select control in the same accessible group.
  await click(p,button(p,s.collectionSelect).first());
  await screenshot(p,`onboarding-girl-${locale}-390`);
  await click(p,button(p,s.experienceIntroNext));const name=p.getByRole('textbox',{name:s.startName});await click(p,name);await name.fill('Új Menti');
  await click(p,button(p,s.startFinish));await button(p,s.collectionTitle).waitFor();
  let saved=await snapshot(p);assert.equal(doc(saved,'access_v1').audience,'minor');assert.equal(doc(saved,'identity_v22').profile.name,'Új Menti');assert.equal(doc(saved,'complete_look_v1').look,'girl-party-v1');assert.equal(doc(saved,'complete_look_v1').active,true);
  assert(!Object.keys(saved).some(k=>k.endsWith('drinks_v1')));await screenshot(p,`fresh-collection-home-${locale}-390`);
  await click(p,button(p,s.adventureTitle));await screenshot(p,`fresh-collection-adventure-${locale}-390`);await click(p,button(p,locale==='hu'?'Vissza':'Back'));await top(p);
  await click(p,button(p,s.collectionTitle));await p.getByRole('heading',{name:s.collectionTitle,exact:true}).waitFor();await screenshot(p,`fresh-collection-gallery-${locale}-390`);
  await click(p,button(p,s.avatarEnlargePreview).first());await screenshot(p,`fresh-collection-zoom-${locale}-390`);await click(p,button(p,s.avatarClosePreview));await click(p,button(p,s.avatarCancel));
  p.reloading=true;await p.reload({waitUntil:'networkidle'});await semantics(p);p.reloading=false;await button(p,s.collectionTitle).waitFor();saved=await snapshot(p);assert.equal(doc(saved,'complete_look_v1').look,'girl-party-v1');assert.equal(doc(saved,'access_v1').audience,'minor');
  checks.push(`${locale}: real fresh language/age/back/full girl-party choice/name/save, minor home/adventures/collection/zoom/reload preserve selection`);
  p.closing=true;await context.close();active=null;
  const values=seed(locale);values['flutter.mennyiment_menti_xp_v2']=JSON.stringify(JSON.stringify({xp:190,days:[],completed:[]}));
  const opened=await open(browser,390,values);const q=opened.page;active=q;q.setDefaultTimeout(120000);
  await click(q,button(q,s.dailyOpen));await click(q,button(q,s.dailySave));
  await q.waitForFunction(()=>{const raw=localStorage.getItem('flutter.mennyiment_complete_look_v1');return raw&&JSON.parse(JSON.parse(raw)).acquired?.length===3});
  let earned=await snapshot(q);assert.equal(doc(earned,'menti_xp_v2').xp,200);assert.equal(doc(earned,'complete_look_v1').announced.length,3);assert.equal(doc(earned,'complete_look_v1').active,false);
  await screenshot(q,`xp-unlock-${locale}-390`);
  q.reloading=true;await q.reload({waitUntil:'networkidle'});await semantics(q);q.reloading=false;await button(q,s.collectionTitle).waitFor();await click(q,button(q,s.collectionTitle));
  await click(q,q.getByRole('checkbox',{name:s.collectionUnlockable,exact:true}));await screenshot(q,`xp-empty-unlockable-${locale}-390`);assert((await q.locator('body').ariaSnapshot()).includes(s.collectionNoMatches));
  earned=await snapshot(q);assert.equal(doc(earned,'menti_xp_v2').xp,200);assert.equal(doc(earned,'complete_look_v1').acquired.length,3);checks.push(`${locale}: actual daily check-in crosses 190 to 200 XP, owns/announces all three real legendary looks without spending or converting legacy mode; reload and unlockable filter stay coherent`);
  q.closing=true;await opened.context.close();active=null;
 }
 assert.deepEqual(errors,[]);fs.writeFileSync(path.join(out,'collection-journey-verification.json'),JSON.stringify({sourceCommit:source,version:'2.6.0+38',browser:browser.version(),checks,runtimeErrors:errors,physicalAndroid:false,realWindows:false},null,2)+'\n');console.log(checks.join('\n'));
}catch(e){if(active&&!active.isClosed()){fs.writeFileSync(path.join(out,'journey-failure-dom.txt'),await active.locator('body').ariaSnapshot().catch(()=>''));await active.screenshot({path:path.join(out,'journey-failure.png')}).catch(()=>{});}throw e;}finally{await browser.close();}})().catch(e=>{console.error(e);process.exitCode=1});
