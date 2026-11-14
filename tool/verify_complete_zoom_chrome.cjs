const fs=require('node:fs'),path=require('node:path'),assert=require('node:assert/strict');
const {chromium,open,seed,semantics,screenshot,snapshot,strings,out,errors}=require('./verify_stabilization_226_chrome.cjs');
const s=strings.hu,button=(p,name)=>p.getByRole('button',{name,exact:true});
async function top(p){await p.mouse.move(300,250);await p.mouse.wheel(0,-30000);await p.waitForTimeout(100);}
async function act(p,l){for(let n=0;n<80;n++){const r=await l.boundingBox();if(r&&r.y+r.height/2>115&&r.y+r.height/2<830){await l.evaluate(e=>e.click());await p.waitForTimeout(200);await semantics(p);return;}await p.mouse.move(300,600);await p.mouse.wheel(0,r&&r.y<115?-200:200);await p.waitForTimeout(60);}throw Error('Unreachable');}
(async()=>{const browser=await chromium.launch({executablePath:process.env.CHROME_BIN,headless:true,args:['--no-sandbox','--disable-dev-shm-usage']});try{
const {context,page:p}=await open(browser,390,{...seed('hu'),'flutter.mennyiment_complete_look_v1':JSON.stringify(JSON.stringify({version:1,active:true,look:'boy-base-v1'}))});p.setDefaultTimeout(120000);const before=await snapshot(p);await act(p,button(p,s.visualStudio));await p.getByRole('heading',{name:s.completeTitle}).waitFor();const cdp=await context.newCDPSession(p);await cdp.send('Emulation.setTouchEmulationEnabled',{enabled:true,maxTouchPoints:2});const records=[];
for(const [id,name]of [['boy',s.completeBoy],['girl',s.completeGirl],['neutral',s.completeNeutral]]){
 await act(p,button(p,name));await top(p);await act(p,button(p,s.avatarEnlargePreview));const dialog=p.getByRole('alertdialog').or(p.getByRole('dialog'));await dialog.waitFor();await screenshot(p,`zoom-before-${id}-hu-390`);
 const img=dialog.getByRole('img').first(),box=await img.boundingBox();assert(box);const x=box.x+box.width/2,y=box.y+box.height*.27;
 await cdp.send('Input.dispatchTouchEvent',{type:'touchStart',touchPoints:[{x:x-18,y},{x:x+18,y}]});
 for(let n=1;n<=10;n++){await cdp.send('Input.dispatchTouchEvent',{type:'touchMove',touchPoints:[{x:x-18-n*4,y},{x:x+18+n*4,y}]});await p.waitForTimeout(30);}
 await cdp.send('Input.dispatchTouchEvent',{type:'touchEnd',touchPoints:[]});await p.waitForTimeout(250);await screenshot(p,`zoom-after-${id}-hu-390`);
 assert.notDeepEqual(fs.readFileSync(path.join(out,`zoom-before-${id}-hu-390.png`)),fs.readFileSync(path.join(out,`zoom-after-${id}-hu-390.png`)));
 records.push({id,gesture:'CDP two touch points, spread from 36 to 116 CSS pixels, maximum scale 3 in renderer',imageBox:box});
 await dialog.getByRole('button',{name:s.avatarClosePreview,exact:true}).evaluate(e=>e.click());await p.waitForTimeout(200);await semantics(p);
}assert.deepEqual(await snapshot(p),before);assert.deepEqual(errors,[]);fs.writeFileSync(path.join(out,'zoom-verification.json'),JSON.stringify({sourceCommit:process.env.MENTI_SOURCE_COMMIT,browser:browser.version(),records,physicalPhone:false,runtimeErrors:errors},null,2)+'\n');p.closing=true;await context.close();console.log('3 real touch-emulation zoom checks passed');}finally{await browser.close();}})().catch(e=>{console.error(e);process.exitCode=1});
