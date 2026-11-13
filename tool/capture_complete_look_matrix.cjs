/* Real app home at all requested widths, synthetic stored selections; no user data. */
const fs=require('node:fs'),path=require('node:path'),assert=require('node:assert/strict');
const {chromium,open,seed,screenshot,snapshot,strings,out,errors}=require('./verify_stabilization_226_chrome.cjs');
const source=process.env.MENTI_SOURCE_COMMIT;assert(/^[0-9a-f]{40}$/.test(source||''));
(async()=>{const browser=await chromium.launch({executablePath:process.env.CHROME_BIN||'/usr/bin/chromium',headless:true,args:['--no-sandbox','--disable-dev-shm-usage']});const records=[];
try{for(const locale of ['hu','en'])for(const width of [320,360,390,430])for(const family of ['boy','girl','neutral']){
const values={...seed(locale,family),'flutter.mennyiment_complete_look_v1':JSON.stringify(JSON.stringify({version:1,active:true,look:family+'-base-v1'}))};
const {context,page}=await open(browser,width,values);page.setDefaultTimeout(120000);await page.getByRole('button',{name:strings[locale].visualStudio,exact:true}).waitFor();
assert((await(await page.request.get('http://127.0.0.1:7357/build-info.txt')).text()).includes(source));
const name=`matrix-${family}-${locale}-${width}`;await screenshot(page,name);
const stored=await snapshot(page);assert.equal(stored['flutter.mennyiment_complete_look_v1'],values['flutter.mennyiment_complete_look_v1']);
const timings=await page.evaluate(()=>performance.getEntriesByType('resource').filter(e=>e.name.includes('/menti_complete/')).map(e=>({file:new URL(e.name).pathname,durationMs:e.duration,transferSize:e.transferSize,encodedBodySize:e.encodedBodySize,decodedBodySize:e.decodedBodySize})));
records.push({locale,width,height:844,family,look:family+'-base-v1',file:name+'.png',timings});console.log(name);page.closing=true;await context.close();
}assert.deepEqual(errors,[]);fs.writeFileSync(path.join(out,'matrix-verification.json'),JSON.stringify({sourceCommit:source,browser:browser.version(),textScale:1,records,runtimeErrors:errors,physicalPhone:false},null,2)+'\n');}finally{await browser.close();}})().catch(e=>{console.error(e);process.exitCode=1});
