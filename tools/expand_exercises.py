#!/usr/bin/env python3
"""Append public-domain exercise records without changing any existing exercise ID.
Source: yuhonas/free-exercise-db, pinned commit below. Run from the repository root.
Images are fetched separately and converted to 640px JPEGs by tools/resize_images.swift.
"""
import json,re,urllib.request,concurrent.futures
from pathlib import Path
COMMIT='f00c92c7dcf1216a928a52c3706c7ce8e2f71ed5'
BASE=f'https://raw.githubusercontent.com/yuhonas/free-exercise-db/{COMMIT}/'
root=Path(__file__).resolve().parents[1]
up=json.load(urllib.request.urlopen(BASE+'dist/exercises.json'))
p=root/'res/exercises.json';old=json.loads(p.read_text());before={e['id']:e for e in old};out=list(old);downloads=[]
for e in up:
 if e['id'] in before or e['category']=='cardio':continue
 n={k:e.get(k) for k in ['id','name','equipment','level','mechanic','force','instructions','category']}
 n['equipment']=n['equipment'] or 'body only';n['primary']=e['primaryMuscles'];n['secondary']=e['secondaryMuscles'];n['images']=[]
 for i,img in enumerate(e['images'][:2]):
  filename=f"{e['id']}_{i}.jpg";n['images'].append(filename);downloads.append((BASE+'exercises/'+img,filename))
 out.append(n)
special={
 'Barbell_Bench_Press_-_Medium_Grip':['bench press','flat bench','bb bench','chest press'],
 'Barbell_Deadlift':['deadlift','conventional deadlift','bb deadlift'],
 'Romanian_Deadlift':['rdl','romanian deadlift'],
 'Dumbbell_Single_Leg_Split_Squat':['bulgarian split squat','rear foot elevated split squat','rfess'],
 'Split_Squats':['split squat'],
 'Wide-Grip_Lat_Pulldown':['lat pulldown','lat pull down','lat machine'],
 'Butterfly':['pec deck','pec fly','machine chest fly'],
 'Lying_Triceps_Press':['skull crusher','skullcrusher','skullcrushers','lying triceps extension'],
 'Barbell_Hip_Thrust':['hip thrust','glute thrust','glute bridge barbell'],
 'Seated_Dumbbell_Press':['db shoulder press','dumbbell overhead press','seated ohp'],
 'Standing_Military_Press':['ohp','overhead press','military press'],
 'Pullups':['pull up','pullup','pull ups'],
 'Pushups':['push up','pushup','press up','pressup'],
 'Bent_Over_Barbell_Row':['barbell row','bb row','bent over row'],
 'One-Arm_Dumbbell_Row':['single arm row','one arm row','db row'],
 'Standing_Palms-Up_Barbell_Behind_The_Back_Wrist_Curl':['behind back wrist curl'],
 'Dumbbell_Bicep_Curl':['db curl','biceps curl'],
 'Face_Pull':['facepull','cable face pull'],
 'Dips_-_Triceps_Version':['triceps dip','dip'],
 'Dips_-_Chest_Version':['chest dip','dip'],
 'Leg_Extensions':['leg extension','quad extension'],
 'Seated_Leg_Curl':['hamstring curl','leg curl'],
 'Lying_Leg_Curls':['hamstring curl','prone leg curl'],
 'Dumbbell_Lunges':['db lunge','lunge'],
 'Goblet_Squat':['goblet squat','db goblet squat'],
 'Pallof_Press':['pallof press','anti rotation press'],
}
for e in out:
 aliases=set(e.get('aliases',[]));name=e['name'].lower();plain=re.sub(r'[^a-z0-9 ]',' ',name);plain=' '.join(plain.split());aliases.add(plain)
 for a,b in [('dumbbell','db'),('barbell','bb'),('kettlebell','kb'),('tricep','triceps'),('bicep','biceps'),('pull-up','pullup'),('push-up','pushup'),('pulldown','pull down'),('pushdown','push down'),('flyes','fly'),('flyes','flies')]:
  if a in name:aliases.add(name.replace(a,b))
 aliases.update(special.get(e['id'],[]));e['aliases']=sorted(aliases)
out.sort(key=lambda e:(e['name'].lower(),e['id']))
# Except for new search aliases, existing records stay byte-for-byte equivalent as JSON values.
for e in out:
 if e['id'] in before:
  assert {k:v for k,v in e.items() if k!='aliases'}=={k:v for k,v in before[e['id']].items() if k!='aliases'}
p.write_text(json.dumps(out,ensure_ascii=False,separators=(',',':'))+'\n')
raw=root/'test-build/exercise-images';raw.mkdir(parents=True,exist_ok=True)
# Resume safely after a partial download, including records appended by an earlier run.
downloads=[(BASE+'exercises/'+img,f"{e['id']}_{i}.jpg") for e in up if e['id'] in {x['id'] for x in out} for i,img in enumerate(e['images'][:2]) if not (root/'res/exercises'/f"{e['id']}_{i}.jpg").exists()]
def fetch(job):
 url,filename=job;dest=raw/filename
 if not dest.exists():
  for attempt in range(3):
   try:dest.write_bytes(urllib.request.urlopen(url,timeout=45).read());break
   except Exception:
    if attempt==2:raise
 return filename
with concurrent.futures.ThreadPoolExecutor(max_workers=12) as pool:
 for i,f in enumerate(pool.map(fetch,downloads),1):
  if i%100==0:print(f'{i}/{len(downloads)} exercise images fetched',flush=True)
print(f'{len(old)} → {len(out)} exercises; original IDs and fields preserved',flush=True)
