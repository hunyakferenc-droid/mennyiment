/* Real Studio controls, isolated synthetic profile; never a real browser profile. */
const fs=require('node:fs'),path=require('node:path'),assert=require('node:assert/strict');
const {chromium,open,seed,semantics,snapshot,screenshot,strings,errors}=require('./verify_stabilization_226_chrome.cjs');
const source=process.env.MENTI_SOURCE_COMMIT,mode=process.env.MENTI_CAPTURE_STAGE||'after';
assert(/^[a-f0-9]{40}$/.test(source||''));
const out=process.env.MENTI_EVIDENCE_DIR;assert(out);fs.mkdirSync(out,{recursive:true});
const key='flutter.mennyiment_identity_v22',xp='flutter.mennyiment_menti_xp_v2';
const unpack=v=>JSON.parse(JSON.parse(v));
const button=(p,name)=>p.getByRole('button',{name,exact:true});
const escape=s=>s.replace(/[.*+?^${}()|[\]\\]/g,'\\$&');
const text=(p,name)=>p.getByText(name,{exact:true}).or(p.getByLabel(name,{exact:true})).first();
async function ready(p){const end=Date.now()+60000;while(p.pendingRequests.size||Date.now()-p.lastNetworkActivity<800){if(Date.now()>end)throw Error('Assets did not settle');await p.waitForTimeout(100)}}
async function action(p,l){await l.waitFor();await l.evaluate(e=>e.click());await p.waitForTimeout(200);await semantics(p);}
async function editorTop(p){await p.mouse.move(p.viewportSize().width*.65,p.viewportSize().height*.75);await p.mouse.wheel(0,-20000);await p.waitForTimeout(180);}
async function tab(p,label){await editorTop(p);for(let n=0;n<16;n++){const l=p.getByRole('checkbox',{name:label,exact:true});if(await l.count()){const b=await l.first().boundingBox();if(b&&b.x+b.width/2>16&&b.x+b.width/2<p.viewportSize().width-16){await action(p,l.first());await editorTop(p);return;}}await p.mouse.move(p.viewportSize().width*.65,76);await p.mouse.wheel(n===0?-3000:220,0);await p.waitForTimeout(120);}throw Error('Unreachable Studio category '+label);}
async function choice(p,s,field,id,label){
 await editorTop(p);const title=s['avatarField'+field[0].toUpperCase()+field.slice(1)];const heading=text(p,title);
 let rect;for(let n=0;n<65;n++){const b=await heading.boundingBox().catch(()=>null);if(b&&b.y>100&&b.y<p.viewportSize().height-160){rect=b;break}await p.mouse.move(p.viewportSize().width*.68,p.viewportSize().height*.75);await p.mouse.wheel(0,180);await p.waitForTimeout(90);}if(!rect)throw Error('Missing field '+field);
 const y=Math.min(p.viewportSize().height-95,rect.y+rect.height+100);await p.mouse.move(p.viewportSize().width*.60,y);await p.mouse.wheel(-10000,0);await p.waitForTimeout(150);
 for(let n=0;n<24;n++){
  let l=p.locator(`[flt-semantics-identifier="option-${field}-${id}"]`).first();
  if(!await l.count())l=p.getByRole('button',{name:new RegExp('^'+escape(label)+'(?:\\s|$)')}).first();
  const b=await l.boundingBox().catch(()=>null),v=p.viewportSize();
  if(b&&b.width>0&&b.x+b.width/2>20&&b.x+b.width/2<v.width-20&&b.y+b.height/2>110&&b.y+b.height/2<v.height-65){await p.mouse.click(b.x+b.width/2,b.y+b.height/2);await p.waitForTimeout(220);await semantics(p);return;}
  await p.mouse.move(v.width*.6,y);await p.mouse.wheel(260,0);await p.waitForTimeout(100);
 }throw Error('Unreachable choice '+field+'/'+id);
}
function fixture(locale){const values=seed(locale),id=unpack(values[key]);id.profile.name='Mira';id.profile.visual.face='calm';id.profile.visual.eyes='round';id.unlocks.unlocked.push('future:preserve');values[key]=JSON.stringify(JSON.stringify(id));values[xp]=JSON.stringify(JSON.stringify({xp:5000,days:[],completed:[],future:'preserve'}));return values;}
(async()=>{const browser=await chromium.launch({executablePath:'/usr/bin/chromium',headless:true,args:['--no-sandbox','--disable-dev-shm-usage']});const checks=[];let active;
try{for(const locale of ['hu','en']){const s=strings[locale],{context,page:p}=await open(browser,390,fixture(locale));active=p;p.harnessPhase=locale+' '+mode;const info=await(await p.request.get('http://127.0.0.1:7357/build-info.txt')).text();assert(info.includes(source));await button(p,s.visualStudio).waitFor();await ready(p);const before=await snapshot(p);await action(p,button(p,s.visualStudio));
 await tab(p,s.avatarTabAtmosphere);await choice(p,s,'reaction','proud',s.avatarReactionProud);await ready(p);
 assert.deepEqual(await snapshot(p),before,'Selecting a reaction wrote the draft');
 await screenshot(p,`studio-${mode}-reaction-${locale}-390`);
 await action(p,button(p,s.avatarEnlargePreview));await screenshot(p,`studio-${mode}-zoom-${locale}-390`);await action(p,button(p,s.avatarClosePreview));
 checks.push(locale+': matching draft reaction and enlarged view captured without writing profile/XP/journal');
 if(mode==='after'){
  await tab(p,s.avatarTabBasics);await choice(p,s,'family','boy',s.avatarFamilyBoy);await choice(p,s,'age','adult',s.avatarAgeAdult);
  await tab(p,s.avatarTabOutfit);await choice(p,s,'outfit','business-alt',s.avatarOutfitBusinessAlt);
  await tab(p,s.avatarTabFace);await choice(p,s,'headwear','party-hat',s.avatarHeadwearPartyHat);
  await tab(p,s.avatarTabAccessories);await choice(p,s,'glasses','sunglasses',s.avatarGlassesSunglasses);await choice(p,s,'held','flower',s.avatarHeldFlower);
  await tab(p,s.avatarTabAtmosphere);await choice(p,s,'reaction','focused',s.avatarReactionFocused);await ready(p);
  assert.deepEqual(await snapshot(p),before,'Outfit/appearance selection wrote before Save');await screenshot(p,`studio-${mode}-selected-${locale}-390`);
  await action(p,button(p,s.avatarSave));await p.waitForFunction(key=>JSON.parse(JSON.parse(localStorage.getItem(key))).profile.reaction.style==='focused',key);
  const saved=await snapshot(p),id=unpack(saved[key]);for(const [field,value]of Object.entries({family:'boy',age:'adult',outfit:'business-alt',headwear:'party-hat',glasses:'sunglasses',held:'flower',face:'calm',eyes:'round'}))assert.equal(id.profile.visual[field],value,field);
  assert.equal(id.profile.visual.future,'preserve');assert.equal(id.future,'preserve');assert(id.unlocks.unlocked.includes('future:preserve'));for(const k of Object.keys(before).filter(k=>k!==key))assert.equal(saved[k],before[k],k);
  await ready(p);p.reloading=true;await p.reload({waitUntil:'networkidle'});await semantics(p);p.reloading=false;await button(p,s.visualStudio).waitFor();assert.deepEqual(await snapshot(p),saved);
  await screenshot(p,`home-${mode}-reloaded-${locale}-390`);await action(p,button(p,s.visualStudio));await tab(p,s.avatarTabAtmosphere);await ready(p);await screenshot(p,`studio-${mode}-reloaded-${locale}-390`);assert.deepEqual(await snapshot(p),saved);
  checks.push(locale+': actual family/age/outfit/hat/glasses/held-object/reaction selection, Save, full reload and Studio reopen retain selected IDs, unknown fields, unlocks and exact XP/journal');
 }
 assert.deepEqual(errors,[]);await ready(p);p.closing=true;await context.close();active=null;console.log('Passed '+locale+' '+mode);
}fs.writeFileSync(path.join(out,'character-flows.json'),JSON.stringify({sourceCommit:source,stage:mode,browser:browser.version(),checks,runtimeErrors:errors,physicalAndroid:false,emulator:false},null,2));}catch(e){if(active&&!active.isClosed()){fs.writeFileSync(path.join(out,'character-flow-failure-dom.txt'),await active.locator('body').ariaSnapshot());await active.screenshot({path:path.join(out,'character-flow-failure.png')});}throw e;}finally{await browser.close()}})().catch(e=>{console.error(e);process.exitCode=1});
