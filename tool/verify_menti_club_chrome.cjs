const fs=require('node:fs'),path=require('node:path'),assert=require('node:assert/strict');
const {chromium,open,seed,semantics,snapshot,strings,reach}=require('./verify_stabilization_226_chrome.cjs');
const out=process.env.MENTI_EVIDENCE_DIR||'/tmp/menti-club-chrome';fs.mkdirSync(out,{recursive:true});
const source=process.env.MENTI_SOURCE_COMMIT;assert(/^[a-f0-9]{40}$/.test(source||''));
const normal='flutter.mennyiment_fitness_club_v1',test='flutter.mennyiment_fitness_club_test_v1',checks=[],errors=[];
const decode=x=>JSON.parse(JSON.parse(x)),encode=x=>JSON.stringify(JSON.stringify(x));
const button=(p,name)=>p.getByRole('button',{name,exact:true});
async function top(p){await p.mouse.move(230,240);await p.mouse.wheel(0,-30000);await p.waitForTimeout(150);}
async function action(p,l){await top(p);await semantics(p);await reach(p,l);await l.evaluate(e=>e.click());await p.waitForTimeout(180);await semantics(p);}
(async()=>{const b=await chromium.launch({executablePath:process.env.CHROME_BIN||'/usr/bin/chromium',headless:true,args:['--no-sandbox','--disable-dev-shm-usage']});let active;
try{for(const lang of ['hu','en']){
 const values={...seed(lang),'flutter.mennyiment_complete_look_v1':encode({version:2,active:true,look:'girl-base-v1',acquired:[],announced:[]})};
 const {context,page:p}=await open(b,320,values);active=p;await p.evaluate(()=>document.documentElement.style.fontSize='32px');await p.waitForTimeout(300);assert.equal(await p.evaluate(()=>getComputedStyle(document.documentElement).fontSize),'32px');await semantics(p);p.on('pageerror',e=>errors.push(e.message));const s=strings[lang];
 assert((await(await p.request.get('http://127.0.0.1:7357/build-info.txt')).text()).includes(source));
 await action(p,button(p,s.fitnessTitle));
 const before=await snapshot(p);assert.equal(before[normal],undefined);
 async function cards(mode='complete',standing=false){
  await action(p,button(p,s.cardsTitle));if(standing)await action(p,p.getByRole('checkbox',{name:s.cardsStanding,exact:true}));
  await action(p,button(p,s.rhythmPlay));
  if(mode==='partial'){await action(p,button(p,s.cardsDone));await action(p,button(p,s.cardsExit));return;}
  for(let i=0;i<3;i++){if(mode==='complete' && i===0){await p.keyboard.press('n');await p.waitForTimeout(200);await semantics(p);}else{await action(p,button(p,mode==='skip'?s.cardsSkip:s.cardsDone));}}
  await p.screenshot({path:path.join(out,`cards-${mode}-${lang}-320.png`)});
  await action(p,button(p,s.rhythmBack));
 }
 await cards('partial');assert.deepEqual(await snapshot(p),before);
 await cards('skip');assert.deepEqual(await snapshot(p),before);
 await cards('complete');let record=decode((await snapshot(p))[normal]);assert.equal(record.days.length,1);assert.equal(record.best,0);
 await cards('complete',true);assert.deepEqual(decode((await snapshot(p))[normal]),record);
 const realBefore=await snapshot(p),realRecord=realBefore[normal];
 checks.push(`${lang}: 320px / 200% browser font seated/standing, partial exit and all-skip do not count, completed cards save exactly one local day, same-day repeat idempotent`);
 await action(p,button(p,s.clubTestMode));
 for(let day=0;day<7;day++){
  await cards('complete');const state=decode((await snapshot(p))[test]);assert.equal(state.days.length,day+1);
  if(day===0){await cards('complete');assert.equal(decode((await snapshot(p))[test]).days.length,1);}
  if(day<6){await action(p,button(p,s.clubNextDay));if(day===1)await action(p,button(p,s.clubNextDay));}
 }
 let state=decode((await snapshot(p))[test]);assert.deepEqual(state.days,['2030-01-01','2030-01-02','2030-01-04','2030-01-05','2030-01-06','2030-01-07','2030-01-08']);
 await top(p);await semantics(p);const lastDay=p.getByRole('checkbox',{name:lang==='hu'?'7. nap':'Day 7',exact:false});await reach(p,lastDay);assert(await lastDay.isChecked());await p.screenshot({path:path.join(out,`club-seven-${lang}-320.png`)});
 await action(p,button(p,s.clubNewChallenge));state=decode((await snapshot(p))[test]);assert.equal(state.days.length,0);assert.equal(state.last,'2030-01-08');
 await cards('complete');assert.equal(decode((await snapshot(p))[test]).days.length,0);
 await action(p,button(p,s.clubNextDay));await cards('complete');state=decode((await snapshot(p))[test]);assert.deepEqual(state.days,['2030-01-09']);
 const saved=await snapshot(p),protectedValues={...saved};delete protectedValues[test];assert.deepEqual(protectedValues,realBefore);assert.equal(saved[normal],realRecord);
 await p.reload({waitUntil:'networkidle'});await semantics(p);await action(p,button(p,s.fitnessTitle));await action(p,button(p,s.clubTestMode));assert.deepEqual(await snapshot(p),saved);
 await top(p);await p.screenshot({path:path.join(out,`club-reloaded-${lang}-320.png`)});
 checks.push(`${lang}: seven virtual days with a skipped calendar day, same-day repeat, complete week/new challenge, same-day cross-challenge limit, reload; test storage isolated from actual club and all profile/journal/XP data`);
 await context.close();active=null;
}
assert.deepEqual(errors,[]);fs.writeFileSync(path.join(out,'club-chrome-verification.json'),JSON.stringify({sourceCommit:source,version:'3.3.0+46',realWindows:process.platform==='win32',browserFontPx:32,textScale:2,checks,runtimeErrors:errors},null,2));console.log(checks.length+' club Chrome checks passed');
}catch(e){if(active&&!active.isClosed()){await active.screenshot({path:path.join(out,'club-failure.png')}).catch(()=>{});fs.writeFileSync(path.join(out,'club-failure-dom.txt'),await active.locator('body').ariaSnapshot().catch(()=>''));}throw e;}finally{await b.close();}})().catch(e=>{console.error(e);process.exitCode=1;});
