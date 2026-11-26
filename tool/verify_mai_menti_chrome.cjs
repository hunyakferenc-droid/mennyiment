const fs = require('node:fs');
const path = require('node:path');
const os = require('node:os');
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
  for (let attempt = 0; attempt < 110; attempt++) {
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

async function recordComparison(browser, name) {
  const s = strings.hu;
  const context = await browser.newContext({
    viewport: { width: 1280, height: 800 },
    reducedMotion: 'reduce',
    recordVideo: { dir: output, size: { width: 960, height: 600 } },
  });
  const fixture = { ...seed('hu', 'girl'), [key('reduce_motion_v1')]: JSON.stringify(true) };
  await context.addInitScript(values => {
    for (const [key, value] of Object.entries(values)) localStorage.setItem(key, value);
  }, fixture);
  const page = await context.newPage();
  const recording = await page.video().path();
  try {
    await page.goto(host, { waitUntil: 'networkidle' });
    await accessibleText(page, 'Mai Menti');
    await page.screenshot({ path: path.join(output, name + '-kezdolap.png') });
    await page.waitForTimeout(600);
    await click(page, button(page, s.rhythmPlay).first());
    const moves = [s.rhythmStretch, s.rhythmLeft, s.rhythmRight];
    for (let length = 1; length <= 3; length++) {
      const tree = await page.locator('body').ariaSnapshot();
      const pattern = Array.from({ length }, (_, index) =>
        moves.find(move => tree.includes((index + 1) + '. ' + move)));
      assert(pattern.every(Boolean), tree);
      await click(page, button(page, 'Mehet'));
      for (const move of pattern) await click(page, button(page, move));
    }
    await accessibleText(page, 'Eredmény: 3 / 3');
    await page.screenshot({ path: path.join(output, name + '-ritmus.png') });
    await page.waitForTimeout(750);
  } finally {
    await context.close();
  }
  fs.renameSync(recording, path.join(output, name + '.webm'));
}

async function playTrialWeek(lang) {
  const hu = lang === 'hu';
  const s = strings[lang];
  const profile = fs.mkdtempSync(path.join(os.tmpdir(), 'menti-trial-week-'));
  const fixture = {
    ...seed(lang, hu ? 'girl' : 'boy'),
    [key('mai_menti_test_date_v1')]: JSON.stringify('2030-01-01'),
  };
  let context;
  let page;
  async function launch() {
    context = await chromium.launchPersistentContext(profile, {
      executablePath: process.env.CHROME_BIN,
      headless: true,
      viewport: { width: hu ? 420 : 320, height: 850 },
      reducedMotion: 'reduce',
      ...(hu ? { recordVideo: { dir: output, size: { width: 420, height: 850 } } } : {}),
    });
    await context.addInitScript(values => {
      if (localStorage.getItem('trial_week_fixture')) return;
      for (const [name, value] of Object.entries(values)) localStorage.setItem(name, value);
      localStorage.setItem('trial_week_fixture', '1');
    }, fixture);
    page = context.pages()[0] || await context.newPage();
    page.setDefaultTimeout(20000);
    await page.goto(host, { waitUntil: 'networkidle' });
    await semantics(page);
  }
  async function close(filmName) {
    const recording = page.video();
    const recordingPath = recording && filmName ? await recording.path() : null;
    await context.close();
    context = null;
    if (recordingPath) fs.renameSync(recordingPath, path.join(output, filmName));

  }
  async function advance() {
    await click(page, button(page, s.clubNextDay));
  }
  function count(n) {
    return hu ? `Teljesített kalandok: ${n} / 28` : `Adventures completed: ${n} / 28`;
  }
  try {
    await launch();
    const labels = [s.rhythmStretch, s.rhythmLeft, s.rhythmRight];
    const rhythmStages = [1, 5, 10, 16, 19, 22, 25];
    const movementStages = [2, 4, 8, 12, 14, 17, 24];
    const memoryStages = [7, 11, 15, 23, 26];
    for (let stage = 0; stage < 28; stage++) {
      await accessibleText(page, count(stage));
      await click(page, button(page, hu ? 'Mai kaland' : 'Today’s adventure'));
      if (rhythmStages.includes(stage)) {
        for (let size = 1; size <= 3; size++) {
          const tree = await page.locator('body').ariaSnapshot();
          const moves = Array.from({ length: size }, (_, index) =>
            labels.find(label => tree.includes((index + 1) + '. ' + label)));
          assert(moves.every(Boolean), tree);
          await click(page, button(page, hu ? 'Mehet' : 'Ready'));
          for (const move of moves) await click(page, button(page, move));
        }
        await click(page, button(page, hu ? 'Vissza a kalandhoz' : 'Back to the adventure'));
      } else if (movementStages.includes(stage)) {
        await click(page, button(page, s.rhythmPlay));
        for (let n = 0; n < 3; n++) await click(page, button(page, s.cardsDone));
        await click(page, button(page, s.rhythmBack));
      } else if (memoryStages.includes(stage)) {
        const symbols = hu ? ['Kör', 'Háromszög', 'Négyzet'] : ['Circle', 'Triangle', 'Square'];
        await click(page, button(page, '1. ' + symbols[0]));
        await click(page, button(page, hu ? 'Minta indítása' : 'Start pattern'));
        const pattern = [];
        for (let i = 1; i <= 3; i++) {
          for (let attempt = 0; attempt < 22; attempt++) {
            const tree = await page.locator('body').ariaSnapshot();
            const cue = symbols.find(symbol => tree.includes(symbol));
            if (cue && tree.includes(i + ' / 3')) {
              pattern.push(cue);
              break;
            }
            await page.waitForTimeout(35);
          }
        }
        assert.equal(pattern.length, 3);
        await accessibleText(page, hu ? 'Te jössz' : 'Your turn');
        for (const cue of pattern) await click(page, button(page, (symbols.indexOf(cue) + 1) + '. ' + cue));
        await accessibleText(page, hu ? 'Megvan a minta!' : 'Pattern matched!');
        await click(page, button(page, hu ? 'Vissza Mentihez' : 'Back to Menti'));
      } else {
        await click(page, button(page, '4'));
      }
      await accessibleText(page, count(stage + 1));
      if ((stage + 1) % 7 === 0) {
        if (stage < 27) {
          await accessibleText(page, hu ? 'Végigjártad a hetet!' : 'You finished the week!');
          const back = button(page, hu ? 'Vissza' : 'Back');
          const box = await back.boundingBox();
          assert(box);
          await page.mouse.click(box.x + box.width / 2, box.y + box.height / 2);
        }
        await page.screenshot({ path: path.join(output, 'chapter-' + (stage + 1) + '-' + lang + '.png') });
      }
      if (stage < 27) {
        await advance();
        if (stage === 2) await advance();
      }
      if (stage === 0 || stage === 7 || stage === 25) {
        await close(stage === 0 ? 'Probahet-elso-kaland.webm' : stage === 7 ? 'Menti-Emlekminta.webm' : 'Menti-utja-kozben.webm');
        await launch();
        await accessibleText(page, count(stage + 1));
      }
    }
    await accessibleText(page, hu ? 'Végigjártad Menti útját!' : 'You finished Menti’s Journey!');
    await page.screenshot({ path: path.join(output, 'trial-week-' + lang + '.png') });
    const snapshot = await page.evaluate(() => Object.fromEntries(Object.entries(localStorage)));
    const trial = JSON.parse(JSON.parse(snapshot[key('adventure_week_test_v1')]));
    assert.deepEqual(trial.days, ['2030-01-01', '2030-01-02', '2030-01-03',
      '2030-01-05', '2030-01-06', '2030-01-07', '2030-01-08']);
    const journey = JSON.parse(JSON.parse(snapshot[key('menti_journey_test_v1')]));
    assert.equal(journey.days.length, 21);
    assert(journey.days[0] > trial.days[6]);
    assert.equal(trial.best, 3);
    assert.equal(JSON.parse(JSON.parse(snapshot[key('menti_memory_test_v1')])).best, 1);
    assert.equal(snapshot[key('menti_journey_v1')], undefined);
    assert.equal(snapshot[key('menti_memory_v1')], undefined);
    assert.equal(snapshot[key('adventure_week_v1')], undefined);
    assert.equal(snapshot[key('mai_menti_rhythm_v1')], undefined);
    assert.equal(snapshot[key('fitness_club_v1')], undefined);
    assert.equal(snapshot[key('drinks_v1')], fixture[key('drinks_v1')]);
    assert.equal(snapshot[key('menti_xp_v2')], fixture[key('menti_xp_v2')]);
    await close('Probahet-zaras.webm');
    return { lang, stages: [...trial.days, ...journey.days], best: 3, restartedChrome: true };
  } catch (error) {
    if (page && !page.isClosed()) {
      await page.screenshot({ path: path.join(output, 'trial-week-failure-' + lang + '.png') }).catch(() => {});
      const tree = await page.locator('body').ariaSnapshot().catch(() => '');
      fs.writeFileSync(path.join(output, 'trial-week-failure-' + lang + '.txt'), tree);
    }
    throw error;
  } finally {
    if (context) await context.close();
    fs.rmSync(profile, { recursive: true, force: true, maxRetries: 5 });
  }
}

async function main() {
  fs.mkdirSync(output, { recursive: true });
  assert.equal(process.platform, 'win32');
  const browser = await chromium.launch({ executablePath: process.env.CHROME_BIN, headless: true });
  const checks = [];
  try {
    if (process.env.MENTI_RECORD_BASELINE === 'true') {
      assert((await (await (await browser.newPage()).request
        .get(host + '/build-info.txt')).text()).includes('2f7c0c672bcd13bc82a4cd0df2ff72f38e292107'));
      await recordComparison(browser, '01-Elotte');
      return;
    }
    await recordComparison(browser, '02-Utana');
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
      await p.keyboard.press('1');
      await accessibleText(p, hu ? 'Korai koppintás' : 'Too soon');
      await click(p, button(p, hu ? 'Mehet' : 'Ready'));
      await accessibleText(p, hu ? 'Késői koppintás' : 'Too late. Time ran out.');
      await click(p, button(p, hu ? 'Új játék' : 'New game'));
      for (let size = 1; size <= 3; size++) {
        const moves = [];
        for (let index = 1; index <= size; index++) {
          const tree = await p.locator('body').ariaSnapshot();
          const label = labels.find(item => tree.includes(index + '. ' + item));
          assert(label, tree);
          moves.push(label);
        }
        await click(p, button(p, hu ? 'Mehet' : 'Ready'));
        for (const move of moves) {
          if (family === 'boy') {
            await p.keyboard.press(String(labels.indexOf(move) + 1));
            await p.waitForTimeout(240);
          } else {
            await click(p, button(p, move));
          }
        }
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
      checks.push({ lang, family, reducedMotion: reduced, input: family === 'boy' ? 'keyboard and mouse' : 'mouse' });
    }
    const trialWeeks = [await playTrialWeek('hu'), await playTrialWeek('en')];
    fs.writeFileSync(path.join(output, 'verification.json'), JSON.stringify({
      source, browser: browser.version(), windows: true, checks, trialWeeks,
    }, null, 2));
  } finally {
    await browser.close();
  }
}

main().catch(error => { console.error(error); process.exitCode = 1; });
