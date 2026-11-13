/* Actual offline-gallery UI, using the original, verified PNG files. */
const fs=require('node:fs'),assert=require('node:assert/strict');
const {chromium}=require(process.env.PLAYWRIGHT_MODULE_PATH||'playwright');
(async()=>{const browser=await chromium.launch({executablePath:process.env.CHROME_BIN||'/usr/bin/chromium',headless:true,args:['--no-sandbox','--disable-dev-shm-usage']});
 const context=await browser.newContext({viewport:{width:1500,height:1100}}),page=await context.newPage(),errors=[],external=[];
 page.on('pageerror',e=>errors.push(String(e)));page.on('response',r=>{if(r.status()>=400)errors.push(r.status()+' '+r.url())});page.on('request',r=>{if(new URL(r.url()).origin!=='http://127.0.0.1:7357')external.push(r.url())});
 try{
  await page.goto('http://127.0.0.1:7357/',{waitUntil:'networkidle'});
  const manifest=await(await page.request.get('http://127.0.0.1:7357/manifest.json')).json();
  assert.equal(manifest.afterCommit,process.env.MENTI_SOURCE_COMMIT);
  await page.getByLabel('Csoport').selectOption('reaction');await page.getByLabel('Keresés').fill('proud');
  const article=page.locator('article:not([hidden])');assert.equal(await article.count(),1);await article.scrollIntoViewIfNeeded();
  await page.waitForFunction(()=>[...document.querySelectorAll('article:not([hidden]) img')].every(i=>i.complete&&i.naturalWidth===720&&i.naturalHeight===960));
  const sizes=[];
  for(const width of [386,720]){await page.getByLabel('Méret').selectOption(String(width));const images=await article.locator('img').evaluateAll(ns=>ns.map(n=>({width:n.getBoundingClientRect().width,naturalWidth:n.naturalWidth,height:n.naturalHeight})));assert.equal(images.length,2);assert(images.every(n=>n.width===width&&n.naturalWidth===720&&n.height===960));sizes.push({sheetWidth:width,avatarLogicalWidth:224*width/720});await article.screenshot({path:process.env.MENTI_EVIDENCE_DIR+'/gallery-'+width+'.png'});}
  assert.deepEqual(errors,[]);assert.deepEqual(external,[]);
  fs.writeFileSync(process.env.MENTI_EVIDENCE_DIR+'/gallery-browser.json',JSON.stringify({sourceCommit:manifest.afterCommit,browser:browser.version(),matchedPair:'reaction-proud.png',sizes,runtimeErrors:errors,externalRequests:external,originalImages:manifest.images.length},null,2)+'\n');
  console.log('Gallery filtering and original before/after images verified at 120px and 224px avatar sizes');
 }finally{await browser.close();}
})().catch(e=>{console.error(e);process.exitCode=1});
