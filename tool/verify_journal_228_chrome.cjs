/* Real Flutter-web editing with synthetic data; no user browser profile is used. */
const fs=require('node:fs');
const path=require('node:path');
const assert=require('node:assert/strict');
const {chromium,open,seed,screenshot,snapshot,reach,semantics,strings,out,errors}=require('./verify_stabilization_226_chrome.cjs');
const url=process.env.MENTI_WEB_URL||'http://127.0.0.1:7357';
const key='flutter.mennyiment_drinks_v1';
const encode=value=>JSON.stringify(JSON.stringify(value));
const decode=values=>JSON.parse(JSON.parse(values[key]));
const checks=[];
function fixture() {
  const twin={name:'Twin',ml:250,percent:4,priceFt:'invalid',time:'2026-11-12T12:15:12.123456',extension:{keep:[1,'raw',null]}};
  return [structuredClone(twin),structuredClone(twin),
    {name:'Zero',ml:500,percent:0,priceFt:0,time:'2026-11-11T10:00:00.000'},
    {name:'Earlier',ml:100,percent:0,priceFt:12.5,time:'2026-10-31T10:00:00.000'}];
}
async function top(page) {
  await page.mouse.move(page.viewportSize().width*.8,300);
  await page.mouse.wheel(0,-20000);await page.waitForTimeout(180);await semantics(page);
}
async function ready(page) {
  const deadline=Date.now()+45000;
  while(page.pendingRequests.size || Date.now()-page.lastNetworkActivity<1500) {
    if(Date.now()>deadline)throw Error('Assets did not settle before navigation');
    await page.waitForTimeout(100);
  }
}
const button=(page,name)=>page.getByRole('button',{name,exact:true});
const text=(page,name)=>page.getByText(name,{exact:false}).or(page.getByLabel(name,{exact:false})).first();
async function action(page,locator) {
  await semantics(page);await reach(page,locator);
  await locator.evaluate(element=>element.click());await page.waitForTimeout(200);await semantics(page);
}
async function input(page,label,value) {
  const control=page.getByRole('textbox',{name:label,exact:false}).first();
  await semantics(page);await reach(page,control);await control.click({noWaitAfter:true});
  await page.keyboard.press('Control+A');
  if(value)await page.keyboard.type(value);else await page.keyboard.press('Backspace');
  await page.keyboard.press('Tab');await page.waitForTimeout(160);
}
async function search(page,s,value) {await top(page);await input(page,s.journalSearch,value);}
async function menu(page,label,choice) {
  await top(page);await action(page,page.getByRole('button',{name:label,exact:false}));
  await semantics(page);
  await page.getByRole('menuitem',{name:choice,exact:true}).evaluate(element=>element.click());
  await page.waitForTimeout(200);await semantics(page);
}
async function openJournal(page,s) {
  const tab=page.getByRole('tab',{name:s.journal,exact:false});
  await tab.waitFor();assert(await tab.isEnabled());
  await tab.evaluate(element=>element.click());
  await page.getByRole('textbox',{name:s.journalSearch,exact:true}).waitFor();
}
async function back(page,locale) {
  await ready(page);const control=button(page,locale==='hu'?'Vissza':'Back');
  await control.waitFor();await control.evaluate(element=>element.click());
  await page.waitForTimeout(200);await semantics(page);
}
async function assertProtected(page,before) {
  const current=await snapshot(page),left={...before},right={...current};delete left[key];delete right[key];
  assert.deepEqual(right,left,'Editing changed profile/XP/language or another preference');return decode(current);
}
async function filters(page,s,{searchValue='Twin',missing=true,oldest=false,month=false}={}) {
  await top(page);
  const searchControl=page.getByRole('textbox',{name:s.journalSearch,exact:true});
  // Flutter synchronizes its shared DOM editing value when the field receives
  // focus; an unfocused semantics input may have an empty DOM value.
  await searchControl.click({noWaitAfter:true});
  assert.equal(await searchControl.inputValue(),searchValue);await page.keyboard.press('Tab');
  const price=page.getByRole('button',{name:s.journalPriceFilter,exact:false});
  assert((await price.ariaSnapshot()).includes(missing?s.journalMissingPrices:s.journalAllPrices));
  if(oldest)assert((await page.getByRole('button',{name:s.journalSort,exact:false}).ariaSnapshot()).includes(s.journalOldest));
  if(month)await page.getByRole('checkbox',{name:s.month,exact:true,checked:true}).waitFor();
}
async function count(page,s,n) {await reach(page,text(page,s.drinkCount.replace('{count}',String(n))));}
async function editor(page,s,priceOnly=false) {
  await top(page);await action(page,button(page,priceOnly?s.entryEditPrice:s.entryEdit).first());
  await page.getByRole('textbox',{name:priceOnly?s.journalPrice:s.journalDrinkName,exact:false}).first().waitFor();
  await ready(page);
}
async function save(page,s,filtered) {
  await ready(page);
  await action(page,button(page,s.avatarSave));
  await text(page,filtered?s.entrySavedFiltered:s.entrySaved).waitFor({state:'visible'});
}
(async()=>{
  const browser=await chromium.launch({executablePath:process.env.CHROME_BIN||'/usr/bin/chromium',headless:true,
    args:['--no-sandbox','--disable-dev-shm-usage']});
  let active;
  try {
    for(const locale of (process.env.MENTI_LOCALES||'hu,en').split(',')) {
      for(const width of (process.env.MENTI_WIDTHS||'320,360,390,430').split(',').map(Number)) {
        const records=fixture(),values=seed(locale);values[key]=encode(records);
        const {context,page}=await open(browser,width,values,page=>{active=page;});active=page;
        const s=strings[locale];process.stdout.write(`Checking ${locale} ${width}px\n`);
        const metadata=await (await page.request.get(`${url}/version.json`)).json();
        assert.equal(metadata.version,'2.2.8');assert.equal(metadata.build_number,'32');
        await button(page,s.chooseMenti).waitFor();const before=await snapshot(page);
        await screenshot(page,`home-loaded-${locale}-${width}`);
        await openJournal(page,s);await search(page,s,'Twin');
        if(width===390) {await top(page);await action(page,page.getByLabel(s.month,{exact:true}));}
        await menu(page,s.journalPriceFilter,s.journalMissingPrices);
        if(width===390)await menu(page,s.journalSort,s.journalOldest);
        await count(page,s,2);await screenshot(page,`missing-${locale}-${width}`);
        if(width!==390) {
          await editor(page,s,true);await input(page,s.journalPrice,locale==='hu'?'1234,75':'1234.75');
          await screenshot(page,`price-editor-${locale}-${width}`);await save(page,s,true);
          records[0].priceFt=1234.75;
          assert.deepEqual(await assertProtected(page,before),records);
          await filters(page,s);await count(page,s,1);await screenshot(page,`price-saved-${locale}-${width}`);
          checks.push(`${locale} ${width}px: direct fractional price save affects one duplicate, preserves filters/unknown fields/profile/XP, updates missing-price results`);
        } else {
          await editor(page,s);
          for(const [label,value] of [[s.journalDrinkName,'Edited drink'],[s.journalMl,'330,0'],[s.journalPercent,'5,5'],
            [s.journalPrice,'1234,75'],[s.entryDate,'2026-11-10'],[s.entryTime,'18:30']])await input(page,label,value);
          await screenshot(page,`full-editor-${locale}`);await save(page,s,true);
          records[0]={...records[0],name:'Edited drink',ml:330,percent:5.5,priceFt:1234.75,time:'2026-11-10T18:30:00.000'};
          assert.deepEqual(await assertProtected(page,before),records);
          await filters(page,s,{oldest:true,month:true});await count(page,s,1);
          await screenshot(page,`full-saved-${locale}`);
          checks.push(`${locale}: all six fields persisted for only the selected duplicate; search/month/missing-price/order survive; filtered-out feedback is visible`);
          await editor(page,s,true);await input(page,s.journalPrice,'0');await save(page,s,true);
          records[1].priceFt=0;assert.deepEqual(await assertProtected(page,before),records);
          await filters(page,s,{oldest:true,month:true});await reach(page,text(page,s.journalNoMatches));
          await screenshot(page,`zero-saved-${locale}`);
          checks.push(`${locale}: genuine zero is saved as known and leaves the missing-price view without changing filters`);
          await top(page);await action(page,button(page,s.journalReset).first());await search(page,s,'Twin');
          await editor(page,s,true);await input(page,s.journalPrice,'12.5');await save(page,s,false);
          records[1].priceFt=12.5;assert.deepEqual(await assertProtected(page,before),records);
          await editor(page,s,true);await action(page,button(page,s.journalRemovePrice));await save(page,s,false);
          delete records[1].priceFt;assert.deepEqual(await assertProtected(page,before),records);
          await search(page,s,'');await menu(page,s.journalPriceFilter,s.journalMissingPrices);
          await count(page,s,1);await screenshot(page,`price-removed-${locale}`);
          checks.push(`${locale}: an existing price can be modified and explicitly removed; totals/coverage/results refresh and the separate zero-price record stays known`);
          await editor(page,s);await input(page,s.journalDrinkName,'Unsaved draft');await back(page,locale);
          await button(page,s.entryKeepEditing).waitFor();await screenshot(page,`discard-confirm-${locale}`);
          await action(page,button(page,s.entryKeepEditing));
          await page.getByRole('textbox',{name:s.journalDrinkName,exact:false}).click({noWaitAfter:true});
          assert.equal(await page.getByRole('textbox',{name:s.journalDrinkName,exact:false}).inputValue(),'Unsaved draft');
          await back(page,locale);await action(page,button(page,s.entryDiscard));
          assert.deepEqual(await assertProtected(page,before),records);
          checks.push(`${locale}: Back asks before discarding, keep-editing retains the draft, confirmed discard writes nothing`);
          // A real storage event from another tab must mark the already-open view stale.
          const other=await context.newPage();await other.goto(`${url}/version.json`,{waitUntil:'networkidle'});
          records[3].priceFt=88;const external=encode(records);
          await other.evaluate(({key,value})=>localStorage.setItem(key,value),{key,value:external});
          await text(page,s.entryStale).waitFor({state:'visible'});await screenshot(page,`external-change-${locale}`);
          assert.equal((await snapshot(page))[key],external);
          // This fixed banner control is above the scrolling content/app bar.
          await button(page,s.homeJournalRetry).evaluate(element=>element.click());
          await page.waitForTimeout(250);await semantics(page);await top(page);
          await text(page,s.entryStale).waitFor({state:'hidden'});
          await filters(page,s,{searchValue:''});assert.deepEqual(await assertProtected(page,before),records);
          await other.close();await screenshot(page,`external-reloaded-${locale}`);
          checks.push(`${locale}: another tab's real storage event marks the open journal stale; explicit reload retains filters and preserves the external data`);
          await back(page,locale);await top(page);await action(page,button(page,s.homeMore));
          await action(page,text(page,s.statisticsNav));await reach(page,text(page,s.knownSpending));
          assert((await page.locator('flt-semantics').allTextContents()).join(' ').replace(/[\s,]/g,'').includes('1235'));
          await screenshot(page,`statistics-refreshed-${locale}`);await back(page,locale);await top(page);
          await action(page,button(page,s.financeCenter));
          assert((await page.locator('flt-semantics').allTextContents()).join(' ').replace(/[\s,]/g,'').includes('1235'));
          await screenshot(page,`finance-refreshed-${locale}`);await back(page,locale);
          assert.deepEqual(await assertProtected(page,before),records);
          checks.push(`${locale}: next statistics and finance views show the edited current-month cost and do not change journal/profile/XP`);
        }
        await page.reload({waitUntil:'networkidle'});await semantics(page);await button(page,s.chooseMenti).waitFor();
        await openJournal(page,s);await screenshot(page,`reloaded-${locale}-${width}`);
        assert.deepEqual(await assertProtected(page,before),records);
        assert.equal(await page.getByRole('textbox',{name:s.journalSearch,exact:true}).inputValue(),'');
        checks.push(`${locale} ${width}px: application reload keeps the edited raw records, profile, XP and language; temporary filters reset`);
        await context.close();active=null;
      }
    }
    assert.deepEqual(errors,[]);
    fs.writeFileSync(path.join(out,'verification.json'),JSON.stringify({completedAt:new Date().toISOString(),browser:browser.version(),checks,runtimeErrors:errors},null,2));
    process.stdout.write(`${checks.length} browser checks passed\n`);
  } catch(e) {
    if(active) {
      await active.screenshot({path:path.join(out,'failure.png')});
      fs.writeFileSync(path.join(out,'failure-dom.txt'),await active.locator('body').ariaSnapshot());
    }
    fs.writeFileSync(path.join(out,'failure.json'),JSON.stringify({checks,errors,error:String(e)},null,2));throw e;
  } finally {await browser.close();}
})().catch(e=>{process.stderr.write(`${e.stack}\n`);process.exitCode=1;});
