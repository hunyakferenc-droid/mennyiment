const fs = require('node:fs');
const path = require('node:path');
const assert = require('node:assert/strict');
const { chromium, semantics, reach, seed, strings } = require('./verify_stabilization_226_chrome.cjs');

const output = process.env.MENTI_EVIDENCE_DIR;
const source = process.env.MENTI_SOURCE_COMMIT;
const host = 'http://127.0.0.1:7357';
const encode = value => JSON.stringify(JSON.stringify(value));
const key = name => 'flutter.mennyiment_' + name;
const button = (page, name) => page.getByRole('button', { name, exact: true });

async function click(page, control) {
  await semantics(page);
  await reach(page, control);
  const box = await control.boundingBox();
  assert(box, 'Control must have a visible mouse target');
  await page.mouse.click(box.x + box.width / 2, box.y + box.height / 2);
  await page.waitForTimeout(240);
}

async function accessibleText(page, text) {
  for (let attempt = 0; attempt < 70; attempt++) {
    await semantics(page);
    if ((await page.locator('body').ariaSnapshot()).includes(text)) return;
    await page.waitForTimeout(125);
  }
  throw new Error('Missing accessible text: ' + text);
}

async function main() {
  fs.mkdirSync(output, { recursive: true });
  assert.equal(process.platform, 'win32');
  const browser = await chromium.launch({ executablePath: process.env.CHROME_BIN, headless: true });
  const checks = [];
  try {
    for (const [lang, family] of [['hu', 'girl'], ['en', 'boy'], ['en', 'neutral']]) {
      const hu = lang === 'hu';
      const s = strings[lang];
      const fixture = {
        ...seed(lang, family),
        [key('complete_look_v1')]: encode({
          version: 2, active: true, look: family + '-base-v1', acquired: [], announced: [],
        }),
        [key('reduce_motion_v1')]: JSON.stringify(family !== 'girl'),
      };
      const context = await browser.newContext({
        viewport: { width: 420, height: 850 },
        reducedMotion: family === 'girl' ? 'no-preference' : 'reduce',
        ...(hu ? { recordVideo: { dir: output, size: { width: 420, height: 850 } } } : {}),
      });
      await context.addInitScript(values => {
        if (localStorage.getItem('mai_fixture')) return;
        for (const [name, value] of Object.entries(values)) localStorage.setItem(name, value);
        localStorage.setItem('mai_fixture', '1');
      }, fixture);
      const p = await context.newPage();
      try {
      p.setDefaultTimeout(20000);
      const errors = [];
      p.on('pageerror', error => errors.push(error.message));
      await p.goto(host, { waitUntil: 'networkidle' });
      assert((await (await p.request.get(host + '/build-info.txt')).text()).includes(source));
      await semantics(p);
      await accessibleText(p, hu ? 'Mai Menti' : 'Today with Menti');
      await p.screenshot({ path: path.join(output, family + '-arrival.png') });
      if (family !== 'girl') assert.equal(await p.locator('video').count(), 0);
      await click(p, button(p, s.clubTestMode));
      const mood = p.getByRole('checkbox', { name: '4', exact: true })
        .or(p.getByRole('button', { name: '4', exact: true }));
      await click(p, mood);
      const expectedReaction = hu ? 'Köszönöm, hogy bejelentkeztél.' : 'Thanks for checking in.';
      await accessibleText(p, expectedReaction);
      await click(p, button(p, s.rhythmPlay).first());

      const labels = [s.rhythmStretch, s.rhythmLeft, s.rhythmRight];
      for (let size = 1; size <= 3; size++) {
        const moves = [];
        for (let index = 1; index <= size; index++) {
          const tree = await p.locator('body').ariaSnapshot();
          const label = labels.find(item => tree.includes(index + '. ' + item));
          assert(label, tree);
          moves.push(label);
        }
        await click(p, button(p, hu ? 'Mehet' : 'Ready'));
        for (const move of moves) await click(p, button(p, move));
      }
      await accessibleText(p, hu ? 'Eredmény: 3 / 3' : 'Result: 3 / 3');
      await p.screenshot({ path: path.join(output, family + '-result.png') });
      await click(p, button(p, hu ? 'Heti áttekintés' : 'Weekly overview'));
      await accessibleText(p, hu ? 'Az elmúlt hét' : 'The last seven days');
      const back = button(p, hu ? 'Vissza' : 'Back');
      const backBox = await back.boundingBox();
      assert(backBox, 'Weekly overview back action is visible');
      await p.mouse.click(backBox.x + backBox.width / 2, backBox.y + backBox.height / 2);
      await accessibleText(p, hu ? 'Mai Menti' : 'Today with Menti');
      await click(p, button(p, s.clubNextDay));
      await p.reload({ waitUntil: 'networkidle' });
      await semantics(p);
      const data = await p.evaluate(names => ({
        mood: localStorage.getItem(names[0]),
        date: localStorage.getItem(names[1]),
        record: localStorage.getItem(names[2]),
        actual: localStorage.getItem(names[3]),
        journal: localStorage.getItem(names[4]),
        xp: localStorage.getItem(names[5]),
      }), [key('mai_menti_test_mood_v1_2030-01-01'),
        key('mai_menti_test_date_v1'), key('mai_menti_test_rhythm_v1'),
        key('mai_menti_rhythm_v1'), key('drinks_v1'), key('menti_xp_v2')]);
      assert.equal(JSON.parse(data.mood), 4);
      assert.equal(JSON.parse(data.date), '2030-01-02');
      assert.equal(JSON.parse(JSON.parse(data.record)).best, 3);
      assert.equal(data.actual, null);
      assert.equal(data.journal, fixture[key('drinks_v1')]);
      assert.equal(data.xp, fixture[key('menti_xp_v2')]);
      assert.deepEqual(errors, []);
      } catch (error) {
        await p.screenshot({ path: path.join(output, family + '-failure.png') }).catch(() => {});
        const tree = await p.locator('body').ariaSnapshot().catch(() => '');
        fs.writeFileSync(path.join(output, family + '-failure.txt'), tree);
        throw error;
      }
      const recording = p.video();
      await context.close();
      if (recording) await recording.saveAs(path.join(output, 'Mai-Menti-napi-kor.webm'));
      checks.push({ lang, family, reducedMotion: family !== 'girl', input: 'mouse' });
    }
    fs.writeFileSync(path.join(output, 'verification.json'), JSON.stringify({
      source, browser: browser.version(), windows: true, checks,
    }, null, 2));
  } finally {
    await browser.close();
  }
}

main().catch(error => { console.error(error); process.exitCode = 1; });
