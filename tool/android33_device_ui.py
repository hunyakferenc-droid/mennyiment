"""Real Android UI + lifecycle on an explicitly disposable CI emulator only."""
import json,os,re,subprocess,time
from pathlib import Path
import xml.etree.ElementTree as ET

REVIEW='com.example.mennyiment.review';NORMAL='com.example.mennyiment'
TEST_KEY='flutter.mennyiment_fitness_club_test_v1'
ROOT=Path(__file__).resolve().parents[1]
STRINGS=json.loads((ROOT/'lib/l10n/app_en.arb').read_text())

def adb(*args,check=True):
 return subprocess.run(['adb',*map(str,args)],check=check,capture_output=True,timeout=35).stdout

def require_emulator():
 if os.environ.get('GITHUB_ACTIONS')!='true' or adb('shell','getprop','ro.kernel.qemu').strip()!=b'1':
  raise RuntimeError('Disposable CI emulator required; physical devices are refused.')

def prefs(package):
 raw=adb('exec-out','run-as',package,'cat','shared_prefs/FlutterSharedPreferences.xml')
 root=ET.fromstring(raw)
 return {n.get('name'):(n.tag,tuple(sorted(n.attrib.items())),n.text,tuple(sorted(x.text or '' for x in n))) for n in root}

def club_record(data,key=TEST_KEY):
 return json.loads(data[key][2]) if key in data else None

class DeviceUI:
 def __init__(self,out):self.out=Path(out);self.out.mkdir(parents=True,exist_ok=True)
 def screen(self,name):
  (self.out/(name+'.png')).write_bytes(adb('exec-out','screencap','-p'))
 def dump(self):
  adb('shell','uiautomator','dump','--compressed','/sdcard/mennyiment-33-ui.xml')
  raw=adb('exec-out','cat','/sdcard/mennyiment-33-ui.xml');(self.out/'last-ui.xml').write_bytes(raw)
  return ET.fromstring(raw)
 def size(self):
  text=adb('shell','wm','size').decode();m=re.findall(r'(\d+)x(\d+)',text)[-1];return tuple(map(int,m))
 def swipe(self,down=False):
  w,h=self.size();adb('shell','input','swipe',w//2,int(h*(.32 if down else .72)),w//2,int(h*(.80 if down else .27)),300);time.sleep(.25)
 def top(self):
  for _ in range(5):self.swipe(down=True)
 def nodes(self,label):
  w,h=self.size();found=[]
  for n in self.dump().iter('node'):
   names=[n.get('text',''),n.get('content-desc','')]
   if not any(x==label or x.split('\n')[0]==label for x in names):continue
   b=re.findall(r'-?\d+',n.get('bounds',''))
   if len(b)!=4:continue
   x1,y1,x2,y2=map(int,b);x,y=(x1+x2)//2,(y1+y2)//2
   if 0<x<w and 40<y<h-50 and x2>x1 and y2>y1 and n.get('enabled')=='true':found.append(((x2-x1)*(y2-y1),x,y))
  return sorted(found)
 def click(self,label,top=True):
  if top:self.top()
  for _ in range(35):
   targets=self.nodes(label)
   if targets:
    _,x,y=targets[0];adb('shell','input','tap',x,y);time.sleep(.9);return
   self.swipe()
  self.screen('FAILURE');raise AssertionError('Native Android control unreachable: '+label)
 def visible(self,label):
  for _ in range(35):
   if self.nodes(label):return
   self.swipe()
  self.screen('FAILURE');raise AssertionError('Native label absent: '+label)
 def back(self):adb('shell','input','keyevent','KEYCODE_BACK');time.sleep(.8)
 def start(self,package):
  adb('shell','am','start','-W','-a','android.intent.action.MAIN','-c','android.intent.category.LAUNCHER','-f','0x10200000','-n',package+'/com.example.mennyiment.MainActivity');time.sleep(3)
 def stop(self,package):adb('shell','am','force-stop',package);time.sleep(.5)

def lifecycle(out):
 require_emulator();ui=DeviceUI(out);initial=prefs(REVIEW)
 assert club_record(initial,'flutter.mennyiment_fitness_club_v1')['best']==5
 assert TEST_KEY not in initial
 def protected():
  after=prefs(REVIEW);after.pop(TEST_KEY,None);assert after==initial,'Non-test data changed during isolated lifecycle trial'
 def open_test():
  ui.click(STRINGS['fitnessTitle']);ui.click(STRINGS['clubTestMode'])
 def open_cards():
  ui.click(STRINGS['cardsTitle']);ui.click(STRINGS['rhythmPlay'])
 def done():ui.click(STRINGS['cardsDone'])
 def complete():
  open_cards()
  for _ in range(3):done()
  ui.click(STRINGS['rhythmBack'])
 ui.start(REVIEW);open_test();open_cards();done()
 ui.top();ui.visible(STRINGS['cardsStep'].replace('{step}','2'))
 adb('shell','input','keyevent','KEYCODE_HOME');time.sleep(2);ui.start(REVIEW)
 ui.top();ui.visible(STRINGS['cardsStep'].replace('{step}','2'));assert TEST_KEY not in prefs(REVIEW);protected()
 ui.screen('review-background-partial-en-320-200')
 ui.stop(REVIEW);ui.start(REVIEW);assert TEST_KEY not in prefs(REVIEW);protected()
 open_test();complete();assert club_record(prefs(REVIEW))['days']==['2030-01-01']
 complete();assert club_record(prefs(REVIEW))['days']==['2030-01-01']
 open_cards();done();ui.click(STRINGS['clubNextDay']);done();done()
 assert club_record(prefs(REVIEW))['days']==['2030-01-01','2030-01-02']
 ui.click(STRINGS['rhythmBack']);ui.click(STRINGS['clubNextDay']);ui.click(STRINGS['clubNextDay']);complete()
 expected=['2030-01-01','2030-01-02','2030-01-04']
 assert club_record(prefs(REVIEW))['days']==expected;protected()
 ui.stop(REVIEW);ui.start(REVIEW);open_test();assert club_record(prefs(REVIEW))['days']==expected;protected()
 ui.top();ui.screen('review-club-reloaded-en-320-200')
 return {'realAdbBackground':True,'partialSurvivesBackground':True,'forceStoppedPartialNotCommitted':True,
         'savedProgressSurvivesProcessRestart':True,'sameDayRepeatSingleCredit':True,
         'virtualDayAdvancedDuringWorkout':True,'realDeviceClockChanged':False,'skippedVirtualDayRetainedProgress':True,
         'testDays':expected,'allNonTestPreferencesUnchanged':True,'physicalAndroid':False}

def store_screens(out,locale="en"):
 require_emulator();ui=DeviceUI(out)
 labels=json.loads((ROOT/f'lib/l10n/app_{locale}.arb').read_text())
 assert prefs(NORMAL)['flutter.mennyiment_locale_v1'][2]==locale
 for setting in ['animator_duration_scale','transition_animation_scale','window_animation_scale']:
  adb('shell','settings','put','global',setting,'0')
 adb('shell','wm','size','1080x1920');adb('shell','wm','density','480');adb('shell','settings','put','system','font_scale','1.0')
 ui.stop(NORMAL);ui.start(NORMAL);ui.top();ui.screen(f'store-{locale}-home-1080x1920')
 ui.click(labels['allEntries'],top=False);ui.visible(labels['visualFilters']);ui.screen(f'store-{locale}-journal-1080x1920');ui.back()
 ui.click(labels['statisticsNav'],top=False);ui.top();ui.visible(labels['statistics']);ui.screen(f'store-{locale}-statistics-1080x1920');ui.back()
 return {'sourceCommit':os.environ['SOURCE_SHA'],'variant':'normal','emulator':True,'physicalAndroid':False,'locale':locale,'width':1080,'height':1920,'systemFontScale':1,'syntheticData':True}
