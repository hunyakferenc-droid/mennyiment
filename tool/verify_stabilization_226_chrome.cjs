/* Real browser checks against the locally served release webbuild. No real data. */
const fs = require('node:fs');
const path = require('node:path');
const assert = require('node:assert/strict');
const { chromium } = require(process.env.PLAYWRIGHT_MODULE_PATH || 'playwright');
const root = path.resolve(__dirname, '..');
const strings = Object.fromEntries(['hu', 'en'].map(l => [l, JSON.parse(fs.readFileSync(path.join(root, `lib/l10n/app_${l}.arb`), 'utf8'))]));
const url = process.env.MENTI_WEB_URL || 'http://127.0.0.1:7357';
const out = process.env.MENTI_EVIDENCE_DIR || path.join(root, '.agent-workspace/stabilization-chrome');
fs.mkdirSync(out, { recursive: true });
const checks = [], errors = [], cancelled = [];
const pref = (key) => `flutter.mennyiment_${key}`;
const encode = value => JSON.stringify(typeof value === 'object' ? JSON.stringify(value) : value);
function seed(locale, family = 'girl', age = 'adult') {
  return {
    [pref('locale_v1')]: encode(locale),
    [pref('access_v1')]: encode({ version: 1, audience: 'adult', complete: true }),
    [pref('reduce_motion_v1')]: JSON.stringify(true),
    [pref('identity_v22')]: encode({ version: 1,
      profile: { name: `${family} ${age}`, visual: {family, age, style:'classic',
        hair: family === 'girl' ? 'girl-curls' : family === 'boy' ? 'boy-crop' : 'neutral-waves',
        hairVisible: true, outfit:'business', headwear:'beanie', glasses:'round-glasses',
        neck:'scarf', held:'notebook', future:'preserve'}, reaction: {style:'motivating'} },
      unlocks: { unlocked:['outfit:business','headwear:beanie'], seen:[] }, presets:[], future:'preserve' }),
    [pref('drinks_v1')]: encode([{name:'Mobile record',ml:250,percent:4.5,priceFt:1234.75,time:'2026-11-12T13:15:00.000',future:'preserve'}]),
    [pref('menti_xp_v2')]: encode({xp:150,days:[],completed:[],future:'preserve'}),
  };
}
function observe(page) {
  page.pendingRequests = new Set();
  page.lastNetworkActivity = Date.now();
  page.on('request', r => { page.pendingRequests.add(r); page.lastNetworkActivity=Date.now(); });
  page.on('requestfinished', r => { page.pendingRequests.delete(r); page.lastNetworkActivity=Date.now(); });
  page.on('pageerror', e => errors.push(e.message));
  page.on('console', m => { if(m.type()==='error') errors.push(m.text()); });
  page.on('response', r => { if(r.status()>=400) errors.push(`${r.status()} ${r.url()}`); });
  page.on('requestfailed', r => {
    page.pendingRequests.delete(r); page.lastNetworkActivity=Date.now();
    const message=`${r.url()}: ${r.failure()?.errorText}`;
    if(page.reloading && r.failure()?.errorText==='net::ERR_ABORTED') cancelled.push(message);
    else errors.push(message);
  });
}
async function semantics(page) {
  const p=page.locator('flt-semantics-placeholder');
  const deadline=Date.now()+30000;
  while(!await page.locator('flt-semantics').count()) {
    // Activation may remove the placeholder between a count and a separate
    // action. Query and activate atomically, also allowing an already enabled tree.
    await p.evaluateAll(elements=>elements.forEach(element=>element.click()));
    if(Date.now()>deadline) throw Error('Flutter accessibility tree did not start');
    await page.waitForTimeout(100);
  }
}
async function open(browser, width, values) {
  const context=await browser.newContext({viewport:{width,height:844},reducedMotion:'reduce',acceptDownloads:true});
  await context.addInitScript(v=>{
    if (!localStorage.getItem('menti_test_fixture_loaded')) {
      for(const[k,x]of Object.entries(v)) localStorage.setItem(k,x);
      localStorage.setItem('menti_test_fixture_loaded','1');
    }
  },values);
  const page=await context.newPage(); observe(page);
  await page.goto(url,{waitUntil:'networkidle'}); await semantics(page);
  return {context,page};
}
async function screenshot(page, name) {
  await page.mouse.move(1,1);
  const deadline=Date.now()+45000;
  while(page.pendingRequests.size || Date.now()-page.lastNetworkActivity<1500) {
    if(Date.now()>deadline) throw Error(`Assets did not settle for screenshot ${name}`);
    await page.waitForTimeout(100);
  }
  // Image decoding and Flutter's material gate may finish after HTTP completes.
  await page.waitForTimeout(1000);
  await page.screenshot({path:path.join(out,`${name}.png`)});
}
async function snapshot(page) {
  return page.evaluate(()=>Object.fromEntries(Object.entries(localStorage).filter(([k])=>k.startsWith('flutter.mennyiment_'))));
}
async function reach(page, locator) {
  // Native DOM scrolling can remove Flutter's virtualized semantics node before
  // the action resolves. Scroll the rendered list with wheel input instead.
  for(let i=0;i<80;i++) {
    const v=page.viewportSize();
    const boxes=await locator.evaluateAll(nodes=>nodes.map(node=>{
      const r=node.getBoundingClientRect();return {x:r.x,y:r.y,w:r.width,h:r.height};
    }));
    const nav=await page.getByRole('tablist').evaluateAll(nodes=>nodes.map(node=>node.getBoundingClientRect().top));
    const bottom=nav.find(y=>y>0)||v.height;
    const box=boxes.find(r=>r.w>0&&r.h>0);
    if(box&&box.x>=0&&box.x+box.w<=v.width+1&&box.y+box.h/2>60&&box.y+box.h/2<bottom-2) return locator;
    await page.mouse.move(v.width*.65,v.height*.67);
    await page.mouse.wheel(0,box&&box.y<60?-240:240);await page.waitForTimeout(100);
  }
  throw Error('Unreachable control');
}
async function semanticTap(locator) {
  await locator.waitFor({state:'visible'});
  await locator.evaluate(element=>element.click());
}
module.exports={chromium,open,seed,screenshot,snapshot,reach,semantics,observe,strings,out,errors};
if(require.main===module) (async()=>{
  const browser=await chromium.launch({executablePath:process.env.CHROME_BIN||'/usr/bin/chromium',headless:true,args:['--no-sandbox','--disable-dev-shm-usage']});
  let active;
  try {
    for(const locale of ['hu','en']) for(const width of [320,360,390,430]) {
      const s=strings[locale], {context,page}=await open(browser,width,seed(locale)); active=page;
      await page.getByRole('button',{name:s.chooseMenti,exact:true}).waitFor();
      const before=await snapshot(page);
      await screenshot(page,`home-${locale}-${width}`);
      // Flutter uses in-app Navigator routes; assert their rendered state rather
      // than Playwright's implicit document-navigation barrier (CDP: no navigation).
      await page.getByRole('button',{name:s.chooseMenti,exact:true}).click({noWaitAfter:true});
      await page.getByRole('heading',{name:s.avatarStudio,exact:true}).waitFor();
      await semanticTap(page.getByRole('button',{name:s.avatarEnlargePreview,exact:true}));
      await page.getByRole('button',{name:s.avatarClosePreview,exact:true}).waitFor();
      await screenshot(page,`zoom-${locale}-${width}`);
      await semanticTap(page.getByRole('button',{name:s.avatarClosePreview,exact:true}));
      await page.getByRole('heading',{name:s.avatarStudio,exact:true}).waitFor();
      await screenshot(page,`studio-${locale}-${width}`);
      assert.deepEqual(await snapshot(page),before,'Viewing Studio changed local data');
      checks.push(`${width}px ${locale}: home, selected family card, live preview and zoom; saved profile/XP/journal unchanged`);
      await context.close(); active=null;
    }
    for(const family of ['girl','boy','neutral']) for(const age of ['young','adult','veteran']) {
      const {context,page}=await open(browser,390,seed('en',family,age)); active=page;
      const s=strings.en;
      await page.getByRole('button',{name:s.chooseMenti,exact:true}).click({noWaitAfter:true});
      await page.getByRole('heading',{name:s.avatarStudio,exact:true}).waitFor();
      await semanticTap(page.getByRole('button',{name:s.avatarEnlargePreview,exact:true}));
      await page.getByRole('button',{name:s.avatarClosePreview,exact:true}).waitFor();
      await screenshot(page,`character-${family}-${age}`);
      checks.push(`390px ${family}/${age}: saved business outfit, hat, scarf, glasses and notebook rendered`);
      await context.close(); active=null;
    }
    // Actual browser file APIs: export a downloaded JSON, reject a malformed file,
    // preview/cancel, then confirm an authentic file and reload the restored app.
    const {context,page}=await open(browser,360,seed('en')); active=page;
    const s=strings.en;
    await semanticTap(page.getByRole('button',{name:s.avatarMore,exact:true}));
    await page.getByRole('menuitem',{name:s.backupTitle,exact:true}).click({noWaitAfter:true});
    await (await reach(page,page.getByRole('button',{name:s.backupPrepare,exact:true}))).click({noWaitAfter:true});
    const save=await reach(page,page.getByRole('button',{name:s.backupSave,exact:true}));
    const downloadPromise=page.waitForEvent('download'); await save.click({noWaitAfter:true});
    const download=await downloadPromise;
    const backupPath=path.join(out,'browser-test-backup.json'); await download.saveAs(backupPath);
    const document=JSON.parse(fs.readFileSync(backupPath,'utf8'));
    assert.equal(document.format,'mennyiment.local-backup');
    assert.ok(document.entries.mennyiment_identity_v22);
    checks.push('360px EN: real browser backup download has valid envelope, profile, XP and drink records');
    const before=await snapshot(page);
    async function pick(file) {
      const chooserPromise=page.waitForEvent('filechooser');
      await (await reach(page,page.getByRole('button',{name:s.restorePick,exact:true}))).click({noWaitAfter:true});
      const chooser=await chooserPromise; await chooser.setFiles(file);
    }
    const invalid=path.join(out,'invalid-test-backup.json'); fs.writeFileSync(invalid,'{broken');
    await pick(invalid);
    await page.getByText(s.restoreInvalid,{exact:true}).waitFor();
    assert.deepEqual(await snapshot(page),before);
    checks.push('Malformed file is rejected without changing browser data');
    await pick(backupPath);
    await (await reach(page,page.getByRole('button',{name:s.restoreConfirm,exact:true}))).click({noWaitAfter:true});
    await page.getByRole('button',{name:s.restoreCancel,exact:true}).click({noWaitAfter:true});
    assert.deepEqual(await snapshot(page),before);
    await (await reach(page,page.getByRole('button',{name:s.restoreConfirm,exact:true}))).click({noWaitAfter:true});
    await screenshot(page,'restore-confirm-360-en');
    await page.getByRole('button',{name:s.restoreConfirm,exact:true}).click({noWaitAfter:true});
    await page.getByRole('button',{name:s.chooseMenti,exact:true}).waitFor();
    await screenshot(page,'restored-home-360-en');
    checks.push('Authentic file preview, cancel, confirmed restore and application remount complete');
    // Turn off fixture injection before reload to verify persisted data itself.
    const persisted=await snapshot(page);
    const reloadPage=await context.newPage(); observe(reloadPage);
    // The fixture initializer runs once per isolated context, never on this tab.
    await reloadPage.goto(url,{waitUntil:'networkidle'}); await semantics(reloadPage);
    await reloadPage.getByRole('button',{name:s.chooseMenti,exact:true}).waitFor();
    assert.deepEqual(await snapshot(reloadPage),persisted);
    await screenshot(reloadPage,'restored-second-tab-360-en');
    checks.push('Restored profile, journal and XP survive a second tab');
    await context.close(); active=null;
    const metadata=await (await browser.newContext()).request.get(`${url}/version.json`).then(r=>r.json());
    assert.equal(metadata.version,'2.2.6'); assert.equal(metadata.build_number,'30');
    assert.deepEqual(errors,[]);
    const report={sourceCommit:process.env.SOURCE_COMMIT||'working-tree',browser:browser.version(),version:metadata,
      checks,runtimeErrors:errors,intentionalReloadCancellations:cancelled,
      textScale:'Chrome: normal. Actual 1x/2x Flutter text layout is verified by widget tests at every requested width/language.',
      physicalAndroid:false,emulator:false};
    fs.writeFileSync(path.join(out,'verification.json'),JSON.stringify(report,null,2)+'\n');
    console.log(JSON.stringify(report,null,2));
  }catch(error){
    if(active&&!active.isClosed()) { console.error((await active.locator('body').ariaSnapshot()).slice(0,18000)); await screenshot(active,'failure'); }
    throw error;
  }finally{await browser.close();}
})().catch(error=>{console.error(error);process.exit(1);});
