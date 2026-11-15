import unittest
from check_android_update import decision
class PreflightTest(unittest.TestCase):
 def setUp(self):self.old=dict(applicationId='com.example.mennyiment',certificateSha256='a'*64,versionCode=40)
 def test_same_key_upgrade(self):self.assertEqual(decision(self.old,{**self.old,'versionCode':41})[0],'compatible-signature')
 def test_different_key_blocks(self):self.assertEqual(decision(self.old,{**self.old,'certificateSha256':'b'*64,'versionCode':41})[0],'blocked-signature')
 def test_separate_review_has_no_data_migration(self):self.assertEqual(decision(self.old,{**self.old,'applicationId':'com.example.mennyiment.review'})[0],'separate-app')
 def test_downgrade_blocks(self):self.assertEqual(decision(self.old,{**self.old,'versionCode':39})[0],'blocked-downgrade')
if __name__=='__main__':unittest.main()
