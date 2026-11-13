/* Compare protected eyes and mouths in original PNGs in a separate canvas.
 * No application state, tolerance, edited image or screenshot replacement. */
const fs=require('node:fs'),path=require('node:path'),assert=require('node:assert/strict');
async function checkFaceGuard(context,folder,regions,sourceCommit,browser){
 const page=await context.newPage();
 try{
  assert.equal(regions.length,27); // two eyes and one mouth for nine identities
  const hats=['crown-cap','sport-cap','beanie','headphones','party-crown','hood','party-hat','beret','cowboy'];
  const names=['none',...hats].map(h=>'hair-braid--headwear-'+h+'.png');
  const pngs=names.map(n=>fs.readFileSync(path.join(folder,n)).toString('base64'));
  const result=await page.evaluate(async({pngs,regions})=>{
   const images=[];
   for(const png of pngs){const bytes=Uint8Array.from(atob(png),c=>c.charCodeAt(0));const bitmap=await createImageBitmap(new Blob([bytes],{type:'image/png'}));const canvas=new OffscreenCanvas(bitmap.width,bitmap.height),ctx=canvas.getContext('2d');ctx.drawImage(bitmap,0,0);images.push(ctx.getImageData(0,0,bitmap.width,bitmap.height));bitmap.close();}
   const mismatches=[];let checkedPixels=0;
   for(let hat=1;hat<images.length;hat++)for(const {identity,rect}of regions){let changed=0;const [left,top,right,bottom]=rect;if(left>=0&&top>=0&&right<=720&&bottom<=960&&right>left&&bottom>top){}else throw Error('Invalid guard region '+identity);
    for(let y=top;y<bottom;y++)for(let x=left;x<right;x++){const n=(y*720+x)*4;checkedPixels++;if([0,1,2,3].some(k=>images[0].data[n+k]!==images[hat].data[n+k]))changed++;}
    if(changed)mismatches.push({hat,identity,rect,changed});
   }
   return {checkedPixels,mismatches};
  },{pngs,regions});
  const report={sourceCommit,browser,identityHeadwearPairs:81,protectedRegions:243,...result};
  fs.writeFileSync(path.join(folder,'face-guard.json'),JSON.stringify(report,null,2)+'\n');
  assert.deepEqual(result.mismatches,[],'Head equipment changed protected eye or mouth pixels; see face-guard.json');
  console.log('Verified 81 identity/headwear pairs, 243 protected eye/mouth regions, '+result.checkedPixels+' exact pixels');
  return report;
 }finally{await page.close();}
}
module.exports={checkFaceGuard};
