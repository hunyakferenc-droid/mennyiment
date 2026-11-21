// Real normal-home REVIEW flow. Isolated synthetic browser contexts, no user data.
const fs=require('node:fs'),path=require('node:path'),assert=require('node:assert/strict');
const {chromium,seed,semantics,snapshot,strings,reach}=require('./verify_stabilization_226_chrome.cjs');
const out=process.env.MENTI_EVIDENCE_DIR||'/tmp/menti-home-chrome';fs.mkdirSync(out,{recursive:true});
const source=process.env.MENTI_SOURCE_COMMIT;assert(/^[a-f0-9]{40}$/.test(source||''));
const checks=[],errors=[];const url='http://127.0.0.1:7357';
const enc=x=>JSON.stringify(JSON.stringify(x));
const button=(p,name)=>p.getByRole('button',{name,exact:true});
async function top(p){await p.mouse.move(250,240);await p.mouse.wheel(0,-30000);await p.waitForTimeout(180);}
async function action(p,l){await semantics(p);await reach(p,l);await l.evaluate(e=>e.click());await p.waitForTimeout(180);await semantics(p);}
(async()=>{const b=await chromium.launch({executablePath:process.env.CHROME_BIN||'/usr/bin/chromium',headless:true,args:['--no-sandbox','--disable-dev-shm-usage']});let active;
try {
 for(const lang of ['hu','en']) for(const family of ['girl','neutral']) {
  const values={...seed(lang,family),'flutter.mennyiment_reduce_motion_v1':'false','flutter.mennyiment_complete_look_v1':enc({version:2,active:true,look:family+'-base-v1',acquired:[],announced:[],future:'preserve'})};
  const context=await b.newContext({viewport:{width:430,height:1000},reducedMotion:'no-preference'});
  await context.addInitScript(v=>{if(!localStorage.getItem('home_fixture')){for(const[k,x]of Object.entries(v))localStorage.setItem(k,x);localStorage.setItem('home_fixture','1');}},values);
  const p=await context.newPage();active=p;p.on('pageerror',e=>errors.push(e.message));p.setDefaultTimeout(30000);
  await p.goto(url,{waitUntil:'domcontentloaded'});
  assert((await(await p.request.get(url+'/build-info.txt')).text()).includes(source));
  async function video(reaction){await p.waitForFunction(({family,reaction})=>[...document.querySelectorAll('video')].some(v=>v.currentSrc.includes('alive-review-'+family+'-'+reaction+'-v1.mp4')&&!v.paused&&v.currentTime>.15),{family,reaction},{timeout:60000});
   const playing=await p.locator('video').evaluateAll(vs=>vs.filter(v=>!v.paused).map(v=>({src:v.currentSrc,w:v.videoWidth,h:v.videoHeight,muted:v.muted,time:v.currentTime})));
   assert.equal(playing.length,1);assert.equal(playing[0].w,540);assert.equal(playing[0].h,720);assert(playing[0].muted);return playing[0];}
  await video('welcome');const before=await snapshot(p);await p.screenshot({path:path.join(out,`home-${family}-${lang}-welcome-430.png`)});
  await p.mouse.click(97,252);await video('wink');
  for(let i=0;i<8;i++)await p.mouse.click(97,252);
  assert(await p.locator('video').count()<=1);
  await p.screenshot({path:path.join(out,`home-${family}-${lang}-wink-430.png`)});
  await p.waitForFunction(()=>document.querySelectorAll('video').length===0);
  await p.waitForTimeout(300);assert.equal(await p.locator('video').count(),0);
  assert.deepEqual(await snapshot(p),before);checks.push(`${lang}/${family}: real home welcome and tap-wink decoded, rapid taps max one, completion to own PNG, no writes`);
  await p.emulateMedia({reducedMotion:'reduce'});await semantics(p);
  const s=strings[lang];await action(p,button(p,s.lifeWink));assert.equal(await p.locator('video').count(),0);
  checks.push(`${lang}/${family}: reduced motion respects PNG fallback`);
  if(family==='girl') {
   // Same real app, accessible narrow viewport. Browser font-scale is covered
   // by Android system 200% and widget matrix, never claimed as a web setting.
   await p.setViewportSize({width:320,height:1000});await top(p);
   await action(p,button(p,s.fitnessTitle));await action(p,button(p,s.rhythmPlay));
   await p.getByRole('heading',{name:s.rhythmTitle,exact:true}).waitFor();
   const beforeGame=await snapshot(p);
   async function sequence(){const result=[];for(let n=0;n<10;n++) {
    const tree=await p.locator('body').ariaSnapshot();const cue=tree.split('\n').find(l=>l.includes(lang==='hu'?'Figyelj:':'Watch:'));
    if(!cue)break;const a=cue.includes(s.rhythmStretch)?0:cue.includes(s.rhythmLeft)?1:cue.includes(s.rhythmRight)?2:-1;assert(a>=0,cue);result.push(a);
    await action(p,button(p,s.rhythmNext));
   }return result;}
   let seq=await sequence();assert.equal(seq.length,3);
   await p.keyboard.press(String((seq[0]+1)%3+1));await p.waitForTimeout(180);await semantics(p);
   await action(p,button(p,s.rhythmRetry));
   for(let round=1;round<=5;round++) {
    seq=await sequence();assert.equal(seq.length,round+2);
    for(const a of seq){await p.keyboard.press(String(a+1));await p.waitForTimeout(100);}
    await semantics(p);
   }
   await action(p,button(p,s.rhythmBack));await p.getByRole('heading',{name:s.fitnessTitle,exact:true}).waitFor();
   assert.deepEqual(await snapshot(p),beforeGame);
   await action(p,button(p,lang==='hu'?'Vissza':'Back'));await top(p);
   assert.deepEqual(await snapshot(p),beforeGame);
   await p.screenshot({path:path.join(out,`home-return-${lang}-320.png`)});
   checks.push(`${lang}: 320px keyboard wrong/retry, lengths 3..7, five rounds, result/back club/home, no XP/journal/profile writes`);
   await p.reload({waitUntil:'networkidle'});await semantics(p);assert.deepEqual(await snapshot(p),beforeGame);
   checks.push(`${lang}: reload preserves all saved data; game remains ephemeral`);
  }
  await context.close();active=null;
 }
 assert.deepEqual(errors,[]);
 fs.writeFileSync(path.join(out,'home-chrome-verification.json'),JSON.stringify({sourceCommit:source,version:'3.1.0+44',realWindows:process.platform==='win32',browser:b.version(),checks,runtimeErrors:errors},null,2)+'\n');console.log(checks.length+' home REVIEW checks passed');
} catch(e) { if(active&&!active.isClosed()){await active.screenshot({path:path.join(out,'home-failure.png')}).catch(()=>{});fs.writeFileSync(path.join(out,'home-failure-dom.txt'),await active.locator('body').ariaSnapshot().catch(()=>''));}throw e; } finally {await b.close();}})().catch(e=>{console.error(e);process.exitCode=1;});
