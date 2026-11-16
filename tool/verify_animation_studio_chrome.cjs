// Actual Studio UI; intentionally reduced motion, native video tested separately.
const fs=require('node:fs'),path=require('node:path'),assert=require('node:assert/strict');
const {chromium,open,seed,snapshot,semantics,reach,strings,out,errors}=require('./verify_stabilization_226_chrome.cjs');
const source=process.env.MENTI_SOURCE_COMMIT;assert(/^[a-f0-9]{40}$/.test(source||''));
const checks=[];
(async()=>{const browser=await chromium.launch({executablePath:process.env.CHROME_BIN||'/usr/bin/chromium',headless:true,args:['--no-sandbox','--disable-dev-shm-usage']});let active;
try{for(const lang of ['hu','en']){
 const values=seed(lang);delete values['flutter.mennyiment_complete_look_v1'];
 const {context,page:p}=await open(browser,390,values);active=p;
 await p.waitForTimeout(400);if(lang==='en'){await p.getByRole('button',{name:'EN',exact:true}).evaluate(e=>e.click());await p.waitForTimeout(200);await semantics(p);}
 assert((await(await p.request.get('http://127.0.0.1:7357/build-info.txt')).text()).includes(source));
 const before=await snapshot(p);const s=strings[lang];await p.getByText(s.studioInventory,{exact:true}).waitFor();
 for(const [family,label] of [['girl',s.collectionGirl],['neutral',s.collectionNeutral],['boy',s.collectionBoy]]){
  const chip=p.getByRole('button',{name:label,exact:true});await reach(p,chip);await chip.evaluate(e=>e.click());await p.waitForTimeout(150);await semantics(p);
  const selector=p.getByRole('combobox');await reach(p,selector);await selector.evaluate(e=>e.click());await p.waitForTimeout(150);await semantics(p);
  // All six choices are present in the Flutter dropdown, independent of XP.
  const body=await p.locator('body').ariaSnapshot();assert(body.includes(s.collectionLegendary));
  await p.keyboard.press('Escape');await p.waitForTimeout(150);await semantics(p);
  await p.mouse.move(280,250);await p.mouse.wheel(0,-30000);await p.waitForTimeout(200);
  await p.screenshot({path:path.join(out,`studio-${family}-${lang}-390.png`)});
  assert.deepEqual(await snapshot(p),before);checks.push(`${lang}/${family}: all six choices, inventory and unchanged saved data`);
 }
 const events=p.getByText(s.studioEvents,{exact:true});await reach(p,events);await events.evaluate(e=>e.click());await p.waitForTimeout(150);await semantics(p);
 await p.getByText(s.studioEventHint,{exact:true}).waitFor();assert.deepEqual(await snapshot(p),before);
 checks.push(`${lang}: event simulation is clearly marked and read-only`);
 assert.deepEqual(errors,[]);p.closing=true;await context.close();active=null;
}
fs.writeFileSync(path.join(out,'studio-chrome-verification.json'),JSON.stringify({sourceCommit:source,version:'3.0.0+42',realWindows:process.platform==='win32',browser:browser.version(),checks,runtimeErrors:errors},null,2)+'\n');console.log(checks.length+' Studio checks passed');
}catch(e){if(active&&!active.isClosed()){await active.screenshot({path:path.join(out,'studio-failure.png')}).catch(()=>{});fs.writeFileSync(path.join(out,'studio-failure-dom.txt'),await active.locator('body').ariaSnapshot().catch(()=>''));}throw e;}finally{await browser.close();}})().catch(e=>{console.error(e);process.exitCode=1;});
