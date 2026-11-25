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

async function finishClip(page, fragment) {
  await page.waitForFunction(value => [...document.querySelectorAll('video')]
    .some(video => video.currentSrc.includes(value) && video.currentTime > 0.12 && !video.paused)
    || window.maiClips.some(clip => clip.source.includes(value) && clip.time > 0.12),
    fragment, { timeout: 12000 });
  await page.waitForFunction(() => !document.querySelector('video'), null, { timeout: 12000 });
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
      const reduced = family === 'neutral';
      const rating = hu ? 2 : 4;
      const fixture = {
        ...seed(lang, family),
        [key('complete_look_v1')]: encode({
          version: 2, active: true, look: family === 'boy' ? 'boy-festival-v1' : family + '-base-v1', acquired: [], announced: [],
        }),
        [key('reduce_motion_v1')]: JSON.stringify(reduced),
        ...(hu ? { [key('mai_menti_test_date_v1')]: JSON.stringify('2030-01-01') } : {}),
      };
      const context = await browser.newContext({
        viewport: { width: 420, height: 850 },
        reducedMotion: reduced ? 'reduce' : 'no-preference',
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
      await p.addInitScript(() => {
        window.maiClips = [];
        for (const event of ['playing', 'timeupdate', 'ended', 'error']) {
          document.addEventListener(event, e => {
            const video = e.target;
            if (video instanceof HTMLVideoElement && window.maiClips.length < 600) {
              window.maiClips.push({event, source: video.currentSrc, time: video.currentTime});
            }
          }, true);
        }
      });
      await p.goto(host, { waitUntil: 'networkidle' });
      assert((await (await p.request.get(host + '/build-info.txt')).text()).includes(source));
      if (!reduced) {
          await finishClip(p, family === 'boy'
            ? 'alive-review-welcome' : 'girl-base-welcome');
      }
      if (hu) {
        // The review's fixed 420px viewport puts rating 2 in the second chip.
        // Click it before accessibility activation, which can prefer still art.
        await p.mouse.click(110, 301);
        await finishClip(p, 'girl-base-thinking');
      }
      await semantics(p);
      await accessibleText(p, hu ? 'Mai Menti' : 'Today with Menti');
      await p.screenshot({ path: path.join(output, family + '-arrival.png') });
      if (reduced) assert.equal(await p.locator('video').count(), 0);
      if (!hu) {
        await click(p, button(p, s.clubTestMode));
        const mood = p.getByRole('checkbox', { name: String(rating), exact: true })
          .or(p.getByRole('button', { name: String(rating), exact: true }));
        await click(p, mood);
      }
      const expectedReaction = hu ? 'Mára egy kis lépés is elég.' : 'Thanks for checking in.';
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
      // The accessible game path also works when Chrome keeps the selected art
      // static. Check for a bounded return to the poster if a video was mounted.
      await p.waitForFunction(() => !document.querySelector('video'), null, { timeout: 12000 });
      await p.screenshot({ path: path.join(output, family + '-result.png') });
      await click(p, button(p, hu ? 'Heti áttekintés' : 'Weekly overview'));
      await accessibleText(p, hu ? 'Az elmúlt hét' : 'The last seven days');
      const back = button(p, hu ? 'Vissza' : 'Back');
      const backBox = await back.boundingBox();
      assert(backBox, 'Weekly overview back action is visible');
      await p.mouse.click(backBox.x + backBox.width / 2, backBox.y + backBox.height / 2);
      await accessibleText(p, hu ? 'Mai Menti' : 'Today with Menti');
      await click(p, button(p, s.clubNextDay));
      const recap = hu
        ? 'Tegnap · Közérzet: 2 / 5 · Ritmus: 3 / 3'
        : 'Yesterday · Mood: 4 / 5 · Rhythm: 3 / 3';
      await accessibleText(p, recap);
      await p.reload({ waitUntil: 'networkidle' });
      await semantics(p);
      await accessibleText(p, recap);
      await click(p, button(p, s.clubNextDay));
      await accessibleText(p, hu
        ? 'Utolsó közérzetjelzés: 2 / 5'
        : 'Last mood check-in: 4 / 5');
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
      assert.equal(JSON.parse(data.mood), rating);
      assert.equal(JSON.parse(data.date), '2030-01-03');
      assert.equal(JSON.parse(JSON.parse(data.record)).best, 3);
      assert.equal(JSON.parse(JSON.parse(data.record)).dailyScores['2030-01-01'], 3);
      assert.equal(data.actual, null);
      assert.equal(data.journal, fixture[key('drinks_v1')]);
      assert.equal(data.xp, fixture[key('menti_xp_v2')]);
      assert.deepEqual(errors, []);
      } catch (error) {
        await p.screenshot({ path: path.join(output, family + '-failure.png') }).catch(() => {});
        const tree = await p.locator('body').ariaSnapshot().catch(() => '');
        fs.writeFileSync(path.join(output, family + '-failure.txt'), tree);
        const clips = await p.evaluate(() => window.maiClips || []).catch(() => []);
        fs.writeFileSync(path.join(output, family + '-clips.json'), JSON.stringify(clips));
        throw error;
      }
      const recording = p.video();
      await context.close();
      if (recording) await recording.saveAs(path.join(output, 'Mai-Menti-napi-kor.webm'));
      checks.push({ lang, family, reducedMotion: reduced, input: 'mouse' });
    }
    fs.writeFileSync(path.join(output, 'verification.json'), JSON.stringify({
      source, browser: browser.version(), windows: true, checks,
    }, null, 2));
  } finally {
    await browser.close();
  }
}

main().catch(error => { console.error(error); process.exitCode = 1; });
