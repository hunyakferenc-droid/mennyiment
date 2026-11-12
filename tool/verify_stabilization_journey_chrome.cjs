/* Fresh installation, editing and journal checks using real browser storage. */
const fs=require('node:fs'),path=require('node:path'),assert=require('node:assert/strict');
const {chromium,screenshot,snapshot,reach,semantics,observe,strings,out,errors}=require('./verify_stabilization_226_chrome.cjs');
const url=process.env.MENTI_WEB_URL||'http://127.0.0.1:7357';
const s=strings.en, checks=[];
const click=locator=>locator.click({noWaitAfter:true});
const button=(p,name)=>p.getByRole('button',{name,exact:true});
const escape=value=>value.replace(/[.*+?^${}()|[\]\\]/g,'\\$&');
function value(values,suffix){const key=Object.keys(values).find(k=>k.endsWith(suffix));assert.ok(key,suffix);return JSON.parse(values[key]);}
const document=(values,suffix)=>JSON.parse(value(values,suffix));
async function fresh(browser,width){
  const context=await browser.newContext({viewport:{width,height:844},reducedMotion:'reduce'});
  const page=await context.newPage();observe(page);await page.goto(url,{waitUntil:'networkidle'});await semantics(page);return {context,page};
}
async function start(p,adult,name){
  await click(p.getByRole('checkbox',{name:'English',exact:true}));
  await click(button(p,s.experienceIntroNext));
  await click(p.getByRole('radio',{name:adult?s.startAdult:s.startMinor,exact:true}));
  await click(button(p,s.experienceIntroBack));
  await p.getByText(s.startLanguage,{exact:true}).waitFor();
  await click(button(p,s.experienceIntroNext));
  await click(button(p,s.experienceIntroNext));
  await click(await reach(p,p.getByRole('checkbox',{name:s.avatarFamilyGirl,exact:true})));
  await click(await reach(p,p.getByRole('checkbox',{name:s.avatarAgeAdult,exact:true})));
  await click(button(p,s.experienceIntroNext));
  const field=await reach(p,p.getByRole('textbox',{name:s.startName}));
  await click(field);await p.keyboard.press('Control+A');await p.keyboard.type(name);
  await click(button(p,s.startFinish));
  await button(p,s.chooseMenti).waitFor();
  const values=await snapshot(p);
  assert.equal(value(values,'mennyiment_locale_v1'),'en');
  assert.equal(document(values,'mennyiment_access_v1').audience,adult?'adult':'minor');
  assert.equal(document(values,'mennyiment_identity_v22').profile.name,name);
}
(async()=>{
  const browser=await chromium.launch({executablePath:process.env.CHROME_BIN||'/usr/bin/chromium',headless:true,args:['--no-sandbox','--disable-dev-shm-usage']});let active;
  try{
    const {context,page:p}=await fresh(browser,390);active=p;
    await start(p,true,'Fresh Menti');await screenshot(p,'fresh-home-en');
    checks.push('Fresh 390px adult installation: HU to EN, onboarding Back retains age, chosen girl identity and name save');
    await click(button(p,s.chooseMenti));await p.getByRole('heading',{name:s.avatarStudio,exact:true}).waitFor();
    await click(p.getByRole('checkbox',{name:s.avatarTabFace,exact:true}));
    const before=await snapshot(p);
    await click(await reach(p,p.getByRole('button',{name:new RegExp(s.avatarEyesRelaxed)}).first()));
    assert.deepEqual(await snapshot(p),before,'Draft preview wrote storage');
    await click(button(p,s.avatarSave));await p.getByText(s.avatarSaved,{exact:true}).last().waitFor();
    const saved=await snapshot(p);assert.equal(document(saved,'mennyiment_identity_v22').profile.visual.eyes,'relaxed');
    await click(await reach(p,p.getByRole('button',{name:new RegExp(s.avatarEyesWide)}).first()));
    await click(button(p,s.avatarRevert));assert.deepEqual(await snapshot(p),saved);
    checks.push('Real Studio choice, save and undo: draft stays private, selected eyes persist and undo does not write');
    p.reloading=true;await p.reload({waitUntil:'networkidle'});p.reloading=false;await semantics(p);await button(p,s.chooseMenti).waitFor();
    assert.equal(document(await snapshot(p),'mennyiment_identity_v22').profile.visual.eyes,'relaxed');
    assert.equal(value(await snapshot(p),'mennyiment_locale_v1'),'en');
    checks.push('Reload keeps language, saved character and completed onboarding');
    await click(await reach(p,button(p,s.addDrink)));
    await click(await reach(p,p.getByRole('button',{name:new RegExp(escape(s.catalogBeer))}).first()));
    const fields=p.getByRole('textbox');
    for(const [i,text] of ['250','4.5','1234.75'].entries()){
      await click(fields.nth(i));await p.keyboard.press('Control+A');await p.keyboard.type(text);
    }
    await screenshot(p,'drink-details-390-en');
    await click(button(p,s.journalSave));
    await p.getByText(s.journalSaved.replace('{name}',s.catalogBeer),{exact:true}).waitFor();
    let records=document(await snapshot(p),'mennyiment_drinks_v1');
    assert.equal(records.length,1);assert.equal(records[0].name,'Sör (általános)');assert.equal(records[0].priceFt,1234.75);
    checks.push('Actual drink entry saves fractional HUF price and original catalog name; feedback uses its English label');
    await click(await reach(p,p.getByText(s.homeMore,{exact:true})));
    await click(await reach(p,button(p,s.homeRecordActions)));
    await click(p.getByText(/^Price:.*edit$/));
    const price=p.getByRole('textbox');await click(price);assert.equal(await price.inputValue(),'1234.75');
    await p.getByText(s.journalPriceHint,{exact:true}).waitFor();
    await p.getByText(s.journalSetPrice.replace('{name}',s.catalogBeer),{exact:true}).waitFor();
    await screenshot(p,'fractional-price-dialog-en');
    await click(button(p,s.avatarSave));records=document(await snapshot(p),'mennyiment_drinks_v1');assert.equal(records[0].priceFt,1234.75);
    checks.push('Existing-price editor opens with exact fractional value and English helper/title; saving does not round');
    await screenshot(p,'localized-recent-entry-en');
    const minor=await fresh(browser,320);active=minor.page;await start(minor.page,false,'Minor Menti');
    assert.equal(await button(minor.page,s.addDrink).count(),0);await screenshot(minor.page,'fresh-minor-home-en-320');
    minor.page.reloading=true;await minor.page.reload({waitUntil:'networkidle'});minor.page.reloading=false;await semantics(minor.page);await button(minor.page,s.chooseMenti).waitFor();
    assert.equal(await button(minor.page,s.addDrink).count(),0);
    checks.push('Fresh 320px minor installation and reload retain restriction and expose no alcohol logging action');
    assert.deepEqual(errors,[]);
    const report={sourceCommit:process.env.SOURCE_COMMIT||'working-tree',browser:browser.version(),checks,runtimeErrors:errors};
    fs.writeFileSync(path.join(out,'journey-verification.json'),JSON.stringify(report,null,2)+'\n');console.log(JSON.stringify(report,null,2));
    await context.close();await minor.context.close();
  }catch(e){if(active&&!active.isClosed()){console.error((await active.locator('body').ariaSnapshot()).slice(0,18000));await screenshot(active,'journey-failure');}throw e;}finally{await browser.close();}
})().catch(e=>{console.error(e);process.exit(1);});
