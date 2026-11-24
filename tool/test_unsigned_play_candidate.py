import struct,tempfile,unittest
from pathlib import Path
from build_unsigned_play_candidate import prepare_unsigned,elf_alignments,remove_integration_test_dependency
ROOT=Path(__file__).resolve().parents[1]
class UnsignedPreparationTest(unittest.TestCase):
 def test_only_disposable_copy_changes_and_normal_release_guard_remains(self):
  original=(ROOT/'android/app/build.gradle.kts').read_bytes()
  with tempfile.TemporaryDirectory() as d:
   work=Path(d);p=work/'android/app/build.gradle.kts';p.parent.mkdir(parents=True);p.write_bytes(original)
   prepare_unsigned(work);modified=p.read_text()
   self.assertIn('signingConfig = null // EXPLICIT UNSIGNED',modified)
   self.assertNotIn('dependsOn(validateMennyiMentReleaseSigning)',modified)
   self.assertIn('MENNYIMENT_RELEASE_SIGNING[',modified)
   self.assertEqual((ROOT/'android/app/build.gradle.kts').read_bytes(),original)
   self.assertIn(b'dependsOn(validateMennyiMentReleaseSigning)',original)
   self.assertIn(b'signingConfig = signingConfigs.getByName("release")',original)
 def test_live_checkout_cannot_be_patched(self):
  before=(ROOT/'android/app/build.gradle.kts').read_bytes()
  with self.assertRaisesRegex(ValueError,'working checkout'):prepare_unsigned(ROOT)
  self.assertEqual((ROOT/'android/app/build.gradle.kts').read_bytes(),before)
 def test_unexpected_guard_is_refused_without_rewriting(self):
  with tempfile.TemporaryDirectory() as d:
   p=Path(d)/'android/app/build.gradle.kts';p.parent.mkdir(parents=True);p.write_text('different owner configuration')
   with self.assertRaises(ValueError):prepare_unsigned(Path(d))
   self.assertEqual(p.read_text(),'different owner configuration')
 def test_release_copy_excludes_native_test_plugin(self):
  original=(ROOT/'pubspec.yaml').read_text()
  with tempfile.TemporaryDirectory() as d:
   work=Path(d)
   pubspec=work/'pubspec.yaml'
   pubspec.write_text(original)
   remove_integration_test_dependency(work)
   self.assertEqual(pubspec.read_text(),original.replace('  integration_test:\n    sdk: flutter\n',''))
   self.assertIn('  integration_test:',(ROOT/'pubspec.yaml').read_text())
 def test_actual_elf_program_header_alignment_and_endianness(self):
  for endian in ['<','>']:
   for alignment in [4096,16384,65536]:
    raw=bytearray(120);raw[:6]=b'\x7fELF'+bytes([2,1 if endian=='<' else 2])
    struct.pack_into(endian+'Q',raw,32,64);struct.pack_into(endian+'HH',raw,54,56,1)
    struct.pack_into(endian+'I',raw,64,1);struct.pack_into(endian+'Q',raw,112,alignment)
    self.assertEqual(elf_alignments(raw),[alignment])
 def test_truncated_or_unknown_elf_is_not_silently_accepted(self):
  for raw in [b'',b'\x7fELF',bytes(128),b'\x7fELF'+bytes([3,1])+bytes(122)]:
   with self.assertRaises(ValueError):elf_alignments(raw)
if __name__=='__main__':unittest.main()
