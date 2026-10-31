import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mennyiment/backup_file.dart';
import 'package:mennyiment/data_backup.dart';

class _Picker extends FilePickerPlatform {
  Uri? result;
  String? name;
  Uint8List? data;
  String? mime;
  @override
  Future<Uri?> saveFile({
    required String fileName,
    required Uint8List bytes,
    required String mimeType,
    String? dialogTitle,
    String? initialDirectory,
    Function(FilePickerStatus)? onFileSaving,
    WindowsOptions windowsOptions = const WindowsOptions(),
    LinuxOptions linuxOptions = const LinuxOptions(),
    WebOptions webOptions = const WebOptions(),
  }) async {
    name = fileName;
    data = bytes;
    mime = mimeType;
    return result;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'File adapter sends the actual validated JSON bytes to the platform saver',
    () async {
      SharedPreferences.setMockInitialValues({'mennyiment_drinks_v1': 'raw'});
      final doc = await BackupExporter().capture();
      final original = FilePickerPlatform.instance;
      addTearDown(() => FilePickerPlatform.instance = original);
      final picker = _Picker()..result = Uri.file('/chosen/backup.json');
      FilePickerPlatform.instance = picker;
      expect(await saveBackupFile(doc), BackupSaveResult.saved);
      expect(picker.data, doc.bytes);
      expect(picker.name, doc.fileName);
      expect(picker.mime, 'application/json');
      picker.result = null;
      expect(await saveBackupFile(doc), BackupSaveResult.cancelled);
    },
  );
  test('A browser download request is distinct from a native cancellation or saved file', () {
    expect(
      backupSaveResult(null, web: true),
      BackupSaveResult.downloadRequested,
    );
    expect(backupSaveResult(null, web: false), BackupSaveResult.cancelled);
    expect(
      backupSaveResult(Uri.file('/saved'), web: false),
      BackupSaveResult.saved,
    );
  });
}
