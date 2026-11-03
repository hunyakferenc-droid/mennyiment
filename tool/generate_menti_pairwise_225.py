"""Deterministic pair cover; emits reviewable cases, not the Cartesian product."""
import json,re,itertools
from pathlib import Path
opts=re.findall(r"MentiVisualOption\('([^']+)', '([^']+)'",Path('lib/menti_identity/menti_visual_catalog.dart').read_text())
fields=['outfit','headwear','hair','neck','held','glasses','face','eyes','hairVisible']
values={f:[i for field,i in opts if field==f] for f in fields}
values['hair']=['crop','waves','curls','braid','bob','crest'];values['hairVisible']=[False,True]
missing={(i,a,j,b) for i in range(len(fields)) for j in range(i+1,len(fields)) for a in range(len(values[fields[i]])) for b in range(len(values[fields[j]]))}
count=len(missing);rows=[]
while missing:
 i,a,j,b=min(missing);row={i:a,j:b}
 for k in range(len(fields)):
  if k in row:continue
  def score(v):
   return sum(((h,hv,k,v) if h<k else (k,v,h,hv)) in missing for h,hv in row.items())
  row[k]=max(range(len(values[fields[k]])),key=lambda v:(score(v),-v))
 for i,j in itertools.combinations(range(len(fields)),2):missing.discard((i,row[i],j,row[j]))
 rows.append({f:values[f][row[k]] for k,f in enumerate(fields)})
result={'fields':values,'pairs':count,'rows':rows}
Path('test/fixtures/menti_pairwise_225.json').write_text(json.dumps(result,indent=2)+'\n')
print(len(rows),'rows;',count,'value pairs per rig;',len(rows)*9,'runtime renders')
