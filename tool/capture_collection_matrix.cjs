/* Real Chrome viewports and engine text scaling. Synthetic data only. */
const fs=require('node:fs'),path=require('node:path'),assert=require('node:assert/strict');
const {chromium,seed,observe,semantics,screenshot,snapshot,strings,out,errors}=require('./verify_stabilization_226_chrome.cjs');
const source=process.env.MENTI_SOURCE_COMMIT;assert(/^[0-9a-f]{40}$/.test(source||''));
const url='http://127.0.0.1:7357';
(async()=>{const browser=await chromium.launch({executablePath:process.env.CHROME_BIN||'/usr/bin/chromium',headless:true,args:['--no-sandbox','--disable-dev-shm-usage']});let active;const records=[];
try{for(const locale of ['hu','en'])for(const width of [320,360,390,430])for(const scale of [1,2]){
 const family=width===320?'girl':width===360?'boy':'neutral';
 const id=family+'-'+(width===430?'business':'base')+'-v1';
 const values={...seed(locale,family),'flutter.mennyiment_complete_look_v1':JSON.stringify(JSON.stringify({version:1,active:true,look:id}))};
 const context=await browser.newContext({viewport:{width,height:844},reducedMotion:'reduce'});
 await context.addInitScript(({values,scale})=>{
  if(!localStorage.getItem('collection_matrix_fixture')) {for(const[k,v]of Object.entries(values))localStorage.setItem(k,v);localStorage.setItem('collection_matrix_fixture','1')}
  const set=()=>{if(!document.documentElement)return false;document.documentElement.style.fontSize=16*scale+'px';return true};
  if(!set()){const observer=new MutationObserver(()=>{if(set())observer.disconnect()});observer.observe(document,{childList:true,subtree:true})}
 },{values,scale});
 const p=await context.newPage();active=p;observe(p);p.setDefaultTimeout(120000);await p.goto(url,{waitUntil:'networkidle'});await semantics(p);const s=strings[locale];
 await p.getByRole('button',{name:s.collectionTitle,exact:true}).waitFor();
 assert((await(await p.request.get(url+'/build-info.txt')).text()).includes(source));
 assert.equal(await p.evaluate(()=>getComputedStyle(document.documentElement).fontSize),16*scale+'px');
 const before=await snapshot(p),name=`collection-home-${locale}-${width}-${scale}x`;await screenshot(p,name);
 await p.getByRole('button',{name:s.collectionTitle,exact:true}).evaluate(e=>e.click());await p.getByRole('heading',{name:s.collectionTitle,exact:true}).waitFor();await screenshot(p,`collection-gallery-${locale}-${width}-${scale}x`);
 assert.deepEqual(await snapshot(p),before);assert.equal(before['flutter.mennyiment_complete_look_v1'],values['flutter.mennyiment_complete_look_v1']);
 const resources=await p.evaluate(()=>performance.getEntriesByType('resource').filter(e=>e.name.includes('/menti_complete/')).map(e=>({file:new URL(e.name).pathname,transferBytes:e.transferSize,durationMs:e.duration})));
 records.push({locale,width,height:844,textScale:scale,look:id,screens:[name+'.png',`collection-gallery-${locale}-${width}-${scale}x.png`],resources});console.log(name);p.closing=true;await context.close();active=null;
}assert.deepEqual(errors,[]);fs.writeFileSync(path.join(out,'collection-matrix-verification.json'),JSON.stringify({sourceCommit:source,version:'2.6.0+38',browser:browser.version(),scaling:'HTML root 16/32px, read by Flutter web findBrowserTextScaleFactor; browser test, not physical OS accessibility settings',records,runtimeErrors:errors,physicalPhone:false},null,2)+'\n');
}catch(e){if(active&&!active.isClosed()){fs.writeFileSync(path.join(out,'matrix-failure-dom.txt'),await active.locator('body').ariaSnapshot().catch(()=>''));await active.screenshot({path:path.join(out,'matrix-failure.png')}).catch(()=>{})}throw e}finally{await browser.close()}})().catch(e=>{console.error(e);process.exitCode=1});
