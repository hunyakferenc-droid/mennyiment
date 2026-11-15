"""Regress the temporary manifest/Gradle patch, not just source text matching."""
import tempfile, unittest, shutil, subprocess
import xml.etree.ElementTree as ET
from pathlib import Path
from menti_beta_android import prepare_review_android, ensure_committed_source

ROOT=Path(__file__).resolve().parents[1]
class ReviewIsolationTest(unittest.TestCase):
 def test_isolated_id_activity_badge_without_signing_changes(self):
  with tempfile.TemporaryDirectory() as d:
   w=Path(d); shutil.copytree(ROOT/'android/app',w/'android/app',ignore=shutil.ignore_patterns('build'))
   gradle=(w/'android/app/build.gradle.kts');original=gradle.read_text()
   prepare_review_android(w)
   self.assertEqual(gradle.read_text().replace('applicationId = "com.example.mennyiment.review"','applicationId = "com.example.mennyiment"').replace('namespace = "com.example.mennyiment.review"','namespace = "com.example.mennyiment"'),original)
   self.assertIn('namespace = "com.example.mennyiment.review"',gradle.read_text())
   self.assertIn('namespace = "com.example.mennyiment"',(ROOT/'android/app/build.gradle.kts').read_text())
   manifest=(w/'android/app/src/main/AndroidManifest.xml').read_text()
   self.assertIn('android:name="com.example.mennyiment.MainActivity"',manifest)
   self.assertIn('Menti Beta REVIEW',manifest)
   self.assertIn('@drawable/menti_review_launcher',manifest)
   self.assertIn('@drawable/menti_launcher',(w/'android/app/src/main/res/drawable/menti_review_launcher.xml').read_text())
   layers=ET.parse(w/'android/app/src/main/res/drawable/menti_review_launcher.xml').getroot()
   width='{http://schemas.android.com/apk/res/android}width'
   # The original nodpi PNG is 1254 px: dp-sized badge must not shrink against it.
   self.assertEqual(layers[0].get(width),'48dp')
   self.assertEqual(layers[1].get(width),'20dp')
   self.assertNotIn('menti_review_launcher',(ROOT/'android/app/src/main/AndroidManifest.xml').read_text())
 def test_dirty_tracked_source_is_preserved_and_refused(self):
  with tempfile.TemporaryDirectory() as d:
   w=Path(d)
   def git(*args):subprocess.run(['git',*args],cwd=w,check=True,capture_output=True)
   git('init','-q');p=w/'source.txt';p.write_text('committed')
   git('add','source.txt');git('-c','user.name=CI fixture','-c','user.email=ci@example.invalid','commit','-q','-m','fixture')
   ensure_committed_source(w)
   p.write_text('unsaved user work')
   with self.assertRaisesRegex(ValueError,'Existing work is preserved'):ensure_committed_source(w)
   self.assertEqual(p.read_text(),'unsaved user work')
 def test_unexpected_id_fails_without_rewriting(self):
  with tempfile.TemporaryDirectory() as d:
   w=Path(d);p=w/'android/app/build.gradle.kts';p.parent.mkdir(parents=True);p.write_text('applicationId = "unexpected.owner.app"')
   with self.assertRaisesRegex(ValueError,'Unexpected application ID'):prepare_review_android(w)
   self.assertEqual(p.read_text(),'applicationId = "unexpected.owner.app"')
if __name__=='__main__':unittest.main()
