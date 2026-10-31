import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

import 'data_backup.dart';

enum BackupSaveResult { saved, cancelled, downloadRequested }

Future<BackupSaveResult> saveBackupFile(BackupDocument document) async {
  final result = await FilePicker.saveFile(
    fileName: document.fileName,
    bytes: document.bytes,
    mimeType: 'application/json',
  );
  return backupSaveResult(result, web: kIsWeb);
}

/// The plugin's default web download returns null even on a successful request.
/// A browser download request is not proof that a file reached the disk.
BackupSaveResult backupSaveResult(Uri? result, {required bool web}) => web
    ? BackupSaveResult.downloadRequested
    : result == null
    ? BackupSaveResult.cancelled
    : BackupSaveResult.saved;
