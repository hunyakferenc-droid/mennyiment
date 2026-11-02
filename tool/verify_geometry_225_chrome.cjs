/* Real Chromium smoke test for a locally served Flutter web build.
 * Run flutter build web --no-web-resources-cdn, serve build/web over HTTP,
 * install Playwright in a separate tools directory, then run this script.
 * Does not publish a website or contact any user accounts.
 */
const fs = require('node:fs');
const path = require('node:path');
const { chromium } = require(process.env.PLAYWRIGHT_MODULE_PATH || 'playwright');
const root = path.resolve(__dirname, '..');
const hu = JSON.parse(fs.readFileSync(path.join(root, 'lib/l10n/app_hu.arb'), 'utf8'));
const strings = JSON.parse(fs.readFileSync(path.join(root, 'lib/l10n/app_en.arb'), 'utf8'));
const target = process.env.MENTI_WEB_URL || 'http://127.0.0.1:8765';
const output = path.resolve(process.env.MENTI_EVIDENCE_DIR || path.join(root, '.agent-workspace/chrome-evidence'));
fs.mkdirSync(output, { recursive: true });
const failures = [];
const navigationCancellations = [];
const checks = [];
const escape = value => value.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
function observe(page) {
  page.on('pageerror', error => failures.push(error.message));
  page.on('requestfailed', request => {
    const message = `${request.url()}: ${request.failure()?.errorText}`;
    // A deliberate reload can cancel an in-flight emoji fallback font. Keep
    // these visible in the report without treating them as application errors.
    if (page.intentionalReload && request.failure()?.errorText === 'net::ERR_ABORTED') navigationCancellations.push(message);
    else failures.push(message);
  });
  page.on('response', response => { if (response.status() >= 400) failures.push(`${response.status()} ${response.url()}`); });
  page.on('console', message => { if (message.type() === 'error') failures.push(message.text()); });
}
// Let pointer tooltips close before capturing the unaltered Flutter canvas.
async function capture(page, options) {
  await page.mouse.move(1,1);
  await page.waitForTimeout(450);
  return page.screenshot(options);
}
async function option(page,label) {
  const target=page.getByRole('button',{name:new RegExp(escape(label))}).first();
  for(const direction of [1,-1]) {
    for(let n=0;n<14;n++) {
      if(await target.count()) {await target.scrollIntoViewIfNeeded();return target;}
      const v=page.viewportSize();await page.mouse.move(v.width*.72,v.height*.67);
      await page.mouse.wheel(0,direction*240);await page.waitForTimeout(160);
    }
  }
  throw new Error(`Option is unreachable: ${label}`);
}
async function open(context) {
  const page = await context.newPage();
  observe(page);
  await page.goto(target, { waitUntil: 'networkidle' });
  const placeholder = page.locator('flt-semantics-placeholder');
  if (await placeholder.count()) await placeholder.evaluate(element => element.click());
  return page;
}
async function start(page, adult, name) {
  await page.getByRole('checkbox', { name: 'English', exact: true }).click();
  await page.getByRole('button', { name: strings.experienceIntroNext, exact: true }).click();
  await page.getByRole('radio', { name: adult ? strings.startAdult : strings.startMinor, exact: true }).click();
  await page.getByRole('button', { name: strings.experienceIntroNext, exact: true }).click();
  await capture(page, {path: path.join(output, 'chrome-onboarding.png')});
  await page.getByRole('checkbox', { name: strings.avatarFamilyGirl, exact: true }).click();
  await page.getByRole('checkbox', { name: strings.avatarAgeAdult, exact: true }).click();
  await page.getByRole('button', { name: strings.experienceIntroNext, exact: true }).click();
  const input = page.getByRole('textbox', { name: strings.startName });
  await input.click();
  await page.keyboard.press('Control+A');
  await page.keyboard.type(name);
  await page.getByRole('button', { name: strings.startFinish, exact: true }).click();
  await page.getByRole('button', { name: strings.startFinish, exact: true }).waitFor({ state: 'detached' });
}
async function storage(page) {
  return page.evaluate(() => Object.fromEntries(Object.entries(localStorage).filter(([key]) => key.includes('mennyiment_'))));
}
function unpack(value) {
  for (let i = 0; i < 5; i++) {
    if (typeof value === 'string') value = JSON.parse(value);
    else if (value && typeof value === 'object' && 'value' in value) value = value.value;
    else break;
  }
  return value;
}
function identity(values) {
  const key = Object.keys(values).find(key => key.endsWith('mennyiment_identity_v22'));
  if (!key) throw new Error('No saved identity in browser storage');
  return unpack(values[key]);
}
(async () => {
  const browser = await chromium.launch({
    executablePath: process.env.CHROME_BIN || '/usr/bin/chromium', headless: true,
    args: ['--no-sandbox', '--disable-dev-shm-usage'],
  });
  let activePage;
  try {
    const mobile = await browser.newContext({ viewport: { width: 390, height: 844 }, reducedMotion: 'reduce' });
    const page = activePage = await open(mobile);
    await start(page, true, 'Chrome Menti');
    checks.push('HU to EN selection and complete adult onboarding');
    const nativeValues = await storage(page);
    const nativeIdentity = identity(nativeValues);
    if(nativeIdentity.profile.visual.hair !== 'girl-waves' || nativeIdentity.profile.visual.hairVisible !== true) throw new Error('Onboarding did not select the native girl hair');
    await capture(page,{ path: path.join(output, 'chrome-home-native-en.png') });
    await page.getByRole('button', { name: strings.chooseMenti, exact: true }).click();
    await page.getByRole('button',{name:strings.avatarEnlargePreview,exact:true}).click();
    await page.getByRole('button',{name:strings.avatarClosePreview,exact:true}).waitFor();
    await capture(page,{path:path.join(output,'chrome-studio-zoom-en.png')});
    await page.getByRole('button',{name:strings.avatarClosePreview,exact:true}).click();
    checks.push('Full-screen zoom shows the same draft character without saving');
    await page.getByRole('checkbox', { name: strings.avatarTabFace, exact: true }).click();
    const curls=await option(page,strings.avatarHairGirlCurls);
    await curls.scrollIntoViewIfNeeded(); await curls.click();
    await capture(page,{ path:path.join(output,'chrome-studio-hair-en.png') });
    const calm=await option(page,strings.avatarFaceCalm);
    await calm.scrollIntoViewIfNeeded();await calm.click();
    await capture(page,{path:path.join(output,'chrome-studio-face-en.png')});
    const wideEyes=await option(page,strings.avatarEyesWide);
    await wideEyes.scrollIntoViewIfNeeded(); await wideEyes.click();
    await capture(page,{ path:path.join(output,'chrome-studio-eyes-en.png') });
    if(JSON.stringify(identity(await storage(page)))!==JSON.stringify(nativeIdentity)) throw new Error('Preview changed saved identity');
    const noCap=await option(page,strings.avatarHeadwearNone);
    await noCap.scrollIntoViewIfNeeded();await noCap.click();
    await capture(page,{path:path.join(output,'chrome-studio-no-cap-en.png')});
    await page.getByRole('button', { name: strings.avatarRevert, exact:true }).click();
    checks.push('Hair and eye preview alter the draft, keep saved identity intact, and can be reverted');
    await page.getByRole('checkbox', { name: strings.avatarTabOutfit, exact: true }).click();
    await page.getByRole('button', { name: new RegExp(escape(strings.avatarOutfitBasicAlt)) }).first().click();
    await page.getByRole('button', { name: strings.avatarSave, exact: true }).click();
    await page.getByText(strings.avatarSaved, { exact: true }).last().waitFor();
    const saved = identity(await storage(page));
    if (saved.profile.name !== 'Chrome Menti' || saved.profile.visual.outfit !== 'basic-alt') {
      throw new Error('Studio did not persist the edited identity');
    }
    checks.push('Studio outfit editing and confirmed save');
    await capture(page,{ path: path.join(output, 'chrome-studio-mobile-en.png') });
    await page.waitForLoadState('networkidle');
    page.intentionalReload = true;
    await page.reload({ waitUntil: 'networkidle' });
    page.intentionalReload = false;
    const placeholder = page.locator('flt-semantics-placeholder');
    if (await placeholder.count()) await placeholder.evaluate(element => element.click());
    await page.getByRole('button', { name: strings.chooseMenti, exact: true }).waitFor();
    const reopened = identity(await storage(page));
    if (JSON.stringify(saved) !== JSON.stringify(reopened)) throw new Error('Reload changed the saved identity');
    checks.push('Reload preserves the full saved identity and skips completed onboarding');
    await capture(page,{ path: path.join(output, 'chrome-home-mobile-en.png') });
    const values = await storage(page);
    const desktop = await browser.newContext({ viewport: { width: 1280, height: 900 }, reducedMotion: 'reduce' });
    await desktop.addInitScript(values => { for (const [key, value] of Object.entries(values)) localStorage.setItem(key, value); }, values);
    const wide = activePage = await open(desktop);
    await wide.getByRole('button', { name: strings.chooseMenti, exact: true }).click();
    await wide.getByRole('heading', { name: strings.avatarStudio, exact: true }).waitFor();
    await capture(wide,{ path: path.join(output, 'chrome-studio-desktop-en.png') });
    checks.push('1280px desktop Studio loads the saved profile');
    const huValues={...nativeValues};
    const languageKey=Object.keys(huValues).find(key=>key.endsWith('mennyiment_locale_v1'));
    if(!languageKey) throw new Error('Missing language preference');
    huValues[languageKey]=JSON.stringify('hu');
    const hungarian=await browser.newContext({viewport:{width:320,height:740},reducedMotion:'reduce'});
    await hungarian.addInitScript(values=>{for(const [key,value] of Object.entries(values)) localStorage.setItem(key,value);},huValues);
    const huPage=activePage=await open(hungarian);
    await huPage.getByRole('button',{name:hu.chooseMenti,exact:true}).waitFor();
    await capture(huPage,{path:path.join(output,'chrome-home-native-hu-320.png')});
    await huPage.getByRole('button',{name:hu.chooseMenti,exact:true}).click();
    await huPage.getByRole('heading',{name:hu.avatarStudio,exact:true}).waitFor();
    await capture(huPage,{path:path.join(output,'chrome-studio-hu-320.png')});
    checks.push('320px Hungarian native girl home and Studio retain all controls');
    // An actual old-format document has no hairVisible field: loading keeps it
    // unchanged and the existing hairstyle stays visible.
    const oldDoc=JSON.parse(JSON.stringify(nativeIdentity));delete oldDoc.profile.visual.hairVisible;
    const oldValues={...nativeValues};const idKey=Object.keys(oldValues).find(k=>k.endsWith('mennyiment_identity_v22'));
    function repack(raw,doc){const x=JSON.parse(raw);if(typeof x==='string')return JSON.stringify(repack(x,doc));
      if(x&&typeof x==='object'&&'value' in x)return JSON.stringify({...x,value:typeof x.value==='string'?repack(x.value,doc):doc});
      return JSON.stringify(doc);}
    oldValues[idKey]=repack(oldValues[idKey],oldDoc);
    const legacy=await browser.newContext({viewport:{width:390,height:844},reducedMotion:'reduce'});
    await legacy.addInitScript(values=>{for(const[k,v]of Object.entries(values))localStorage.setItem(k,v);},oldValues);
    const oldPage=activePage=await open(legacy);await oldPage.getByRole('button',{name:strings.chooseMenti,exact:true}).waitFor();
    if(JSON.stringify(identity(await storage(oldPage)))!==JSON.stringify(oldDoc))throw new Error('Old profile was rewritten');
    await capture(oldPage,{path:path.join(output,'chrome-existing-profile-en.png')});
    checks.push('Existing document without the new hair flag loads without writes');
    const minor = await browser.newContext({ viewport: { width: 320, height: 740 }, reducedMotion: 'reduce' });
    const young = activePage = await open(minor);
    await start(young, false, 'Lifestyle Menti');
    if (await young.getByRole('button', { name: strings.addDrink, exact: true }).count()) {
      throw new Error('A minor can access the drink logging action');
    }
    await capture(young,{ path: path.join(output, 'chrome-home-minor-en.png') });
    checks.push('320px minor onboarding keeps alcohol logging unavailable');
    const version = await page.request.get(`${target}/version.json`);
    const metadata = await version.json();
    if (metadata.version !== '2.2.5' || metadata.build_number !== '27') throw new Error('Unexpected web build version');
    if (failures.length) throw new Error(failures.join('\n'));
    const report = { browser: await browser.version(), sourceCommit: process.env.SOURCE_COMMIT || 'working-tree',
      version: metadata, checks, runtimeErrors: failures, viewports: ['390x844 EN', '1280x900 EN', '320x740 HU', '320x740 minor EN'],
      reducedMotion: true, navigationCancellations };
    fs.writeFileSync(path.join(output, 'chrome-verification.json'), JSON.stringify(report, null, 2) + '\n');
    console.log(JSON.stringify(report, null, 2));
  } catch (error) {
    if (activePage) {
      console.error((await activePage.locator('body').ariaSnapshot()).slice(0,16000));
      await capture(activePage,{ path: path.join(output, 'chrome-failure.png') });
    }
    throw error;
  } finally { await browser.close(); }
})().catch(error => { console.error(error); process.exit(1); });
