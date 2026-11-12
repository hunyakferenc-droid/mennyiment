/* Run against the release web build using synthetic data only. */
const fs = require('node:fs');
const path = require('node:path');
const assert = require('node:assert/strict');
const {chromium, open, seed, screenshot, snapshot, reach, semantics, strings, out, errors} = require('./verify_stabilization_226_chrome.cjs');
const checks = [];
const encode = value => JSON.stringify(JSON.stringify(value));
const records = [
  {name:'Őszibarack üdítő',ml:250,percent:0,priceFt:1234.75,time:'2026-11-12T13:15:00.000',future:'preserve'},
  {name:'Sör (általános)',ml:330,percent:4,time:'2026-11-11T12:00:00.000'},
  {name:'Ingyenes',ml:500,percent:0,priceFt:0,time:'2026-11-10T12:00:00.000'},
  {name:'Korábbi',ml:100,percent:0,priceFt:100,time:'2026-10-13T12:00:00.000'},
  {name:'Sör (általános)',ml:330,percent:4,time:'2026-11-11T12:00:00.000'},
  {name:'Jövőbeli',ml:100,percent:0,priceFt:50,time:'2027-01-01T12:00:00.000'},
];
async function tap(page, locator) {
  await page.mouse.move(page.viewportSize().width*.8,300);
  await page.mouse.wheel(0,-20000); await page.waitForTimeout(200);
  await (await reach(page, locator)).click({noWaitAfter:true});
  await page.waitForTimeout(200);
}
async function search(page, s, text) {
  const input = page.getByRole('textbox', {name:s.journalSearch,exact:true});
  await tap(page,input); await page.keyboard.press('Control+A');
  if(text) await page.keyboard.type(text); else await page.keyboard.press('Backspace');
  await page.keyboard.press('Tab'); await page.waitForTimeout(300);
}
async function menu(page, label, choice) {
  await tap(page,page.getByRole('button',{name:label,exact:false}));
  await semantics(page);
  await page.getByRole('menuitem',{name:choice,exact:true}).evaluate(element=>element.click());
  await page.waitForTimeout(300);
}
async function expectCount(page, s, count) {
  const text=s.drinkCount.replace('{count}',String(count));
  await reach(page,page.getByText(text,{exact:false}).first());
  assert((await page.locator('flt-semantics').allTextContents()).join(' ').includes(text));
}
(async()=>{
  const browser=await chromium.launch({executablePath:process.env.CHROME_BIN||'/usr/bin/chromium',headless:true,args:['--no-sandbox','--disable-dev-shm-usage']});
  let active;
  try {
    for(const locale of (process.env.MENTI_LOCALES||'hu,en').split(',')) for(const width of (process.env.MENTI_WIDTHS||'320,360,390,430').split(',').map(Number)) {
      const values=seed(locale);values['flutter.mennyiment_drinks_v1']=encode(records);
      const {context,page}=await open(browser,width,values);active=page;
      const metadata=await (await page.request.get('http://127.0.0.1:7357/version.json')).json();
      assert.equal(metadata.version,'2.2.7');assert.equal(metadata.build_number,'31');
      const s=strings[locale];process.stdout.write(`Checking ${locale} ${width}px\n`);
      await page.getByRole('button',{name:s.chooseMenti,exact:true}).waitFor();
      const before=await snapshot(page);
      await page.getByRole('tab',{name:s.journal,exact:false}).evaluate(element=>element.click());
      await page.getByRole('textbox',{name:s.journalSearch,exact:true}).waitFor();
      await screenshot(page,`journal-${locale}-${width}`);
      await search(page,s,'OSZIBARACK UDITO');
      await reach(page,page.getByText(/^Őszibarack üdítő(?:\s|$)/));
      const price=locale==='hu'?'1 234,75':'1,234.75';
      assert((await page.locator('flt-semantics').allTextContents()).join(' ').replaceAll('\u00a0',' ').includes(price));
      await screenshot(page,`search-${locale}-${width}`);
      assert.deepEqual(await snapshot(page),before);
      checks.push(`${locale} ${width}px: accent-free multiword search, exact fractional price, read-only storage`);
      if(width===390) {
        await tap(page,page.getByRole('button',{name:s.journalReset,exact:true}));
        await tap(page,page.getByLabel(s.month,{exact:true}));
        await tap(page,page.getByRole('button',{name:s.previousPeriod,exact:true}));
        await reach(page,page.getByText(/^Korábbi(?:\s|$)/));
        await screenshot(page,`previous-month-${locale}`);
        await tap(page,page.getByRole('button',{name:s.nextPeriod,exact:true}));
        await menu(page,s.journalPriceFilter,s.journalMissingPrices);
        await expectCount(page,s,2);
        await reach(page,page.getByText(s.catalogBeer,{exact:false}).first());
        await screenshot(page,`missing-price-${locale}`);
        assert.equal(await page.getByText('Ingyenes',{exact:false}).count(),0);
        assert.deepEqual(await snapshot(page),before);
        checks.push(`${locale}: month back/forward, missing-price filter excludes genuine zero, duplicate catalog records retained`);
        await tap(page,page.getByRole('button',{name:s.journalReset,exact:true}));
        await search(page,s,locale==='en'?'beer':'sor');
        await expectCount(page,s,2);
        await reach(page,page.getByText(s.catalogBeer,{exact:false}).first());
        await screenshot(page,`catalog-search-${locale}`);
        checks.push(`${locale}: localized catalog search`);
        await search(page,s,'no-match-xyz');
        await reach(page,page.getByLabel(s.journalNoMatches,{exact:false}));
        await screenshot(page,`no-matches-${locale}`);
        await tap(page,page.getByRole('button',{name:s.journalReset,exact:true}).first());
        await menu(page,s.journalSort,s.journalHighestPrice);
        await screenshot(page,`price-sort-${locale}`);
        await menu(page,s.journalSort,s.journalOldest);
        await screenshot(page,`oldest-sort-${locale}`);
        await menu(page,s.journalSort,s.journalNewest);
        await screenshot(page,`newest-sort-${locale}`);
        assert.deepEqual(await snapshot(page),before);
        checks.push(`${locale}: no-match/reset and all three sorting controls preserve raw storage`);
        await page.getByRole('button',{name:locale==='hu'?'Vissza':'Back',exact:true}).evaluate(element=>element.click());
        await page.getByRole('tab',{name:s.journal,exact:false}).evaluate(element=>element.click());
        assert.equal(await page.getByRole('textbox',{name:s.journalSearch,exact:true}).inputValue(),'');
        assert.deepEqual(await snapshot(page),before);
        checks.push(`${locale}: reopening clears temporary filters and preserves journal/profile/XP`);
        await page.reload({waitUntil:'networkidle'});await semantics(page);
        await page.getByRole('button',{name:s.chooseMenti,exact:true}).waitFor();
        await screenshot(page,`reloaded-home-${locale}`);
        assert.deepEqual(await snapshot(page),before);
        checks.push(`${locale}: application reload preserves raw journal, profile, XP and language`);
      }
      await context.close();active=null;
    }
    assert.deepEqual(errors,[]);
    fs.writeFileSync(path.join(out,'verification.json'),JSON.stringify({completedAt:new Date().toISOString(),browser:browser.version(),checks,runtimeErrors:errors},null,2));
    process.stdout.write(`${checks.length} browser checks passed\n`);
  } catch(e) {
    if(active){await active.screenshot({path:path.join(out,'failure.png')});fs.writeFileSync(path.join(out,'failure-dom.txt'),await active.locator('body').innerText());}
    fs.writeFileSync(path.join(out,'failure.json'),JSON.stringify({checks,errors,error:String(e)},null,2));
    throw e;
  } finally {await browser.close();}
})().catch(e=>{process.stderr.write(`${e.stack}\n`);process.exitCode=1;});
