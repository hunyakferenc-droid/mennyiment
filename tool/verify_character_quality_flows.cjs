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
async function action(p,l){await semantics(p);await l.waitFor();const b=await l.boundingBox();assert(b&&b.width>0&&b.height>0,'Visible action target');await p.mouse.click(b.x+b.width/2,b.y+b.height/2);await p.waitForTimeout(250);await semantics(p);}
async function screenAction(p,l){for(let i=0;i<100;i++){await semantics(p);const b=await l.boundingBox({timeout:800}).catch(()=>null),v=p.viewportSize();if(b&&b.y+b.height/2>60&&b.y+b.height/2<v.height-65){await action(p,l);return;}await p.mouse.move(v.width*.7,v.height*.72);await p.mouse.wheel(0,b&&b.y<60?-180:180);await p.waitForTimeout(100);}throw Error('Unreachable screen control');}
async function editorTop(p){await p.mouse.move(p.viewportSize().width*.65,p.viewportSize().height*.75);await p.mouse.wheel(0,-20000);await p.waitForTimeout(180);}
async function swipe(p,y,forward){const v=p.viewportSize(),cdp=await p.context().newCDPSession(p);const start=forward?v.width-35:35,end=forward?35:v.width-35;await cdp.send('Input.dispatchTouchEvent',{type:'touchStart',touchPoints:[{x:start,y}]});for(let i=1;i<=8;i++){await cdp.send('Input.dispatchTouchEvent',{type:'touchMove',touchPoints:[{x:start+(end-start)*i/8,y}]});await p.waitForTimeout(16)}await cdp.send('Input.dispatchTouchEvent',{type:'touchEnd',touchPoints:[]});await cdp.detach();await p.waitForTimeout(180);}
async function tab(p,label){await editorTop(p);const s=p.flowStrings;const index=[s.avatarTabBasics,s.avatarTabFace,s.avatarTabOutfit,s.avatarTabAccessories,s.avatarTabAtmosphere,s.avatarTabPresets].indexOf(label);for(let n=0;n<14;n++){const l=p.getByRole('checkbox',{name:label,exact:true});if(await l.count()){const b=await l.first().boundingBox();if(b&&b.x+b.width/2>16&&b.x+b.width/2<p.viewportSize().width-16){await action(p,l.first());await editorTop(p);return;}}await swipe(p,76,index>2);}throw Error('Unreachable Studio category '+label);}
async function choice(p,s,field,id,label){
 console.log(p.harnessPhase+' choose '+field+'/'+id);await editorTop(p);const l=mode==='after'?p.locator('[flt-semantics-identifier="option-'+field+'-'+id+'"]'):p.getByRole('button',{name:new RegExp('^'+escape(label)+'(?:\\s|$)')}).first();
 for(let n=0;n<85;n++){
  const b=await l.boundingBox({timeout:800}).catch(()=>null),v=p.viewportSize(),name=await button(p,'Mira').boundingBox();
  const upper=name?name.y+name.height+12:370,lower=v.height-65;
  if(b&&b.width>0){const x=b.x+b.width/2,y=b.y+b.height/2;
   if(y>upper+10&&y<lower-10){if(x>20&&x<v.width-20){await p.mouse.click(x,y);await p.waitForTimeout(220);await semantics(p);return;}await swipe(p,y,x>=v.width-20);continue;}
   await p.mouse.move(v.width*.68,v.height*.75);await p.mouse.wheel(0,y<=upper?-140:160);await p.waitForTimeout(100);
  }else{await p.mouse.move(v.width*.68,v.height*.75);await p.mouse.wheel(0,160);await p.waitForTimeout(100);}
 }throw Error('Unreachable choice '+field+'/'+id);
}
function fixture(locale){const values=seed(locale),id=unpack(values[key]);id.profile.name='Mira';id.profile.visual.face='calm';id.profile.visual.eyes='round';id.unlocks.unlocked.push('future:preserve');values[key]=JSON.stringify(JSON.stringify(id));values[xp]=JSON.stringify(JSON.stringify({xp:5000,days:[],completed:[],future:'preserve'}));return values;}
(async()=>{const browser=await chromium.launch({executablePath:process.env.CHROME_BIN||'/usr/bin/chromium',headless:true,args:['--no-sandbox','--disable-dev-shm-usage']});const checks=[];let active;
try{for(const locale of ['hu','en']){const s=strings[locale],{context,page:p}=await open(browser,390,fixture(locale));active=p;p.flowStrings=s;p.harnessPhase=locale+' '+mode;const info=await(await p.request.get('http://127.0.0.1:7357/build-info.txt')).text();assert(info.includes(source));await button(p,s.visualStudio).waitFor();await ready(p);const before=await snapshot(p);await action(p,button(p,s.visualStudio));await p.getByRole('heading',{name:s.avatarStudio,exact:true}).waitFor();
 await tab(p,s.avatarTabAtmosphere);await choice(p,s,'reaction','proud',s.avatarReactionProud);await ready(p);
 assert.deepEqual(await snapshot(p),before,'Selecting a reaction wrote the draft');
 await screenshot(p,`studio-${mode}-reaction-${locale}-390`);
 await action(p,button(p,s.avatarEnlargePreview));await screenshot(p,`studio-${mode}-zoom-${locale}-390`);await action(p,button(p,s.avatarClosePreview));
 checks.push(locale+': matching draft reaction and enlarged view captured without writing profile/XP/journal');
 if(mode==='after'){
  await tab(p,s.avatarTabBasics);await choice(p,s,'family','boy',s.avatarFamilyBoy);await choice(p,s,'age','adult',s.avatarAgeAdult);
  await tab(p,s.avatarTabOutfit);await choice(p,s,'outfit','business-alt',s.avatarOutfitBusinessAlt);
  await tab(p,s.avatarTabFace);await choice(p,s,'hair','boy-braid',s.avatarHairBoyBraid);await choice(p,s,'headwear','party-hat',s.avatarHeadwearPartyHat);
  await tab(p,s.avatarTabAccessories);await choice(p,s,'glasses','sunglasses',s.avatarGlassesSunglasses);await choice(p,s,'held','flower',s.avatarHeldFlower);
  await tab(p,s.avatarTabAtmosphere);await choice(p,s,'reaction','focused',s.avatarReactionFocused);await ready(p);
  assert.deepEqual(await snapshot(p),before,'Outfit/appearance selection wrote before Save');await screenshot(p,`studio-${mode}-selected-${locale}-390`);
  await action(p,button(p,s.avatarSave));await p.waitForFunction(key=>JSON.parse(JSON.parse(localStorage.getItem(key))).profile.reaction.style==='focused',key);
  const saved=await snapshot(p),id=unpack(saved[key]);for(const [field,value]of Object.entries({family:'boy',age:'adult',outfit:'business-alt',headwear:'party-hat',hair:'boy-braid',glasses:'sunglasses',held:'flower',face:'calm',eyes:'round'}))assert.equal(id.profile.visual[field],value,field);
  assert.equal(id.profile.visual.future,'preserve');assert.equal(id.future,'preserve');assert(id.unlocks.unlocked.includes('future:preserve'));for(const k of Object.keys(before).filter(k=>k!==key))assert.equal(saved[k],before[k],k);
  await ready(p);p.reloading=true;await p.reload({waitUntil:'networkidle'});await semantics(p);p.reloading=false;await button(p,s.visualStudio).waitFor();assert.deepEqual(await snapshot(p),saved);
  await screenshot(p,`home-${mode}-reloaded-${locale}-390`);await action(p,button(p,s.visualStudio));await p.getByRole('heading',{name:s.avatarStudio,exact:true}).waitFor();await tab(p,s.avatarTabAtmosphere);await ready(p);await screenshot(p,`studio-${mode}-reloaded-${locale}-390`);assert.deepEqual(await snapshot(p),saved);
  checks.push(locale+': actual family/age/outfit/hat/glasses/held-object/reaction selection, Save, full reload and Studio reopen retain selected IDs, unknown fields, unlocks and exact XP/journal');
  await action(p,button(p,locale==='hu'?'Vissza':'Back'));await button(p,s.visualStudio).waitFor();await editorTop(p);await screenAction(p,button(p,s.adventureTitle));
  await action(p,p.getByRole('tab',{name:s.adventureMap,exact:true}));await ready(p);await screenshot(p,`map-after-saved-${locale}-390`);
  assert.equal((await snapshot(p))[key],saved[key]);await action(p,p.getByRole('tab',{name:s.adventureDaily,exact:true}));
  const rest=p.locator('[flt-semantics-identifier="adventure-task-rest"]');await screenAction(p,rest.getByRole('button',{name:s.adventureChoose,exact:true}));await screenAction(p,rest.getByRole('button',{name:s.adventureComplete,exact:true}));
  const dialog=p.getByRole('dialog').or(p.getByRole('alertdialog')).last();await dialog.waitFor();await action(p,dialog.getByRole('button',{name:s.adventureComplete,exact:true}));await dialog.waitFor({state:'hidden'});
  await button(p,s.adventureSkipFeedback).waitFor();await ready(p);await screenshot(p,`celebration-after-saved-${locale}-390`);assert.equal((await snapshot(p))[key],saved[key]);assert.equal((await snapshot(p))[xp],saved[xp]);
  checks.push(locale+': saved selected character also rendered on the adventure map and completion feedback; profile and XP stay byte-identical');

 }
 assert.deepEqual(errors,[]);await ready(p);p.closing=true;await context.close();active=null;console.log('Passed '+locale+' '+mode);
}fs.writeFileSync(path.join(out,'character-flows.json'),JSON.stringify({sourceCommit:source,stage:mode,browser:browser.version(),checks,runtimeErrors:errors,physicalAndroid:false,emulator:false},null,2));}catch(e){if(active&&!active.isClosed()){fs.writeFileSync(path.join(out,'character-flow-failure-dom.txt'),await active.locator('body').ariaSnapshot());await active.screenshot({path:path.join(out,'character-flow-failure.png')});}throw e;}finally{await browser.close()}})().catch(e=>{console.error(e);process.exitCode=1});
