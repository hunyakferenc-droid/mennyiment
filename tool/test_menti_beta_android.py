"""Regress the temporary manifest/Gradle patch, not just source text matching."""
import tempfile, unittest, shutil
from pathlib import Path
from menti_beta_android import prepare_review_android

ROOT=Path(__file__).resolve().parents[1]
class ReviewIsolationTest(unittest.TestCase):
 def test_isolated_id_activity_badge_without_signing_changes(self):
  with tempfile.TemporaryDirectory() as d:
   w=Path(d); shutil.copytree(ROOT/'android/app',w/'android/app',ignore=shutil.ignore_patterns('build'))
   gradle=(w/'android/app/build.gradle.kts');original=gradle.read_text()
   prepare_review_android(w)
   self.assertEqual(gradle.read_text().replace('applicationId = "com.example.mennyiment.review"','applicationId = "com.example.mennyiment"'),original)
   manifest=(w/'android/app/src/main/AndroidManifest.xml').read_text()
   self.assertIn('android:name="com.example.mennyiment.MainActivity"',manifest)
   self.assertIn('Menti Beta REVIEW',manifest)
   self.assertIn('@drawable/menti_review_launcher',manifest)
   self.assertIn('@drawable/menti_launcher',(w/'android/app/src/main/res/drawable/menti_review_launcher.xml').read_text())
   self.assertNotIn('menti_review_launcher',(ROOT/'android/app/src/main/AndroidManifest.xml').read_text())
 def test_unexpected_id_fails_without_rewriting(self):
  with tempfile.TemporaryDirectory() as d:
   w=Path(d);p=w/'android/app/build.gradle.kts';p.parent.mkdir(parents=True);p.write_text('applicationId = "unexpected.owner.app"')
   with self.assertRaisesRegex(ValueError,'Unexpected application ID'):prepare_review_android(w)
   self.assertEqual(p.read_text(),'applicationId = "unexpected.owner.app"')
if __name__=='__main__':unittest.main()
