import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'app_language.dart';
import 'data_backup.dart';
import 'backup_file.dart';

class DataBackupPage extends StatefulWidget {
  const DataBackupPage({super.key, this.capture, this.save});
  final Future<BackupDocument> Function()? capture;
  final Future<BackupSaveResult> Function(BackupDocument)? save;
  @override
  State<DataBackupPage> createState() => _DataBackupPageState();
}

class _DataBackupPageState extends State<DataBackupPage> {
  BackupDocument? _document;
  bool _busy = false;
  String? _message;

  Future<void> _prepare() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _message = null;
      _document = null;
    });
    try {
      final document = await (widget.capture ?? BackupExporter().capture)();
      if (mounted) setState(() => _document = document);
    } catch (_) {
      if (mounted) {
        setState(() => _message = appStrings(context).backupPrepareError);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _save() async {
    if (_busy || _document == null) return;
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      final result = await (widget.save ?? saveBackupFile)(_document!);
      if (mounted) {
        final strings = appStrings(context);
        setState(
          () => _message = switch (result) {
            BackupSaveResult.saved => strings.backupSaved,
            BackupSaveResult.cancelled => strings.backupCancelled,
            BackupSaveResult.downloadRequested =>
              strings.backupDownloadRequested,
          },
        );
      }
    } catch (_) {
      if (mounted) {
        setState(() => _message = appStrings(context).backupSaveError);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = appStrings(context);
    final document = _document;
    return Scaffold(
      appBar: AppBar(title: Text(strings.backupTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(strings.backupContents),
          const SizedBox(height: 12),
          Text(strings.backupPrivacy),
          const SizedBox(height: 12),
          Text(strings.backupRestoreDeferred),
          const SizedBox(height: 20),
          FilledButton.icon(
            key: const ValueKey('backup-prepare'),
            onPressed: _busy ? null : _prepare,
            icon: const Icon(Icons.backup_outlined),
            label: Text(strings.backupPrepare),
          ),
          if (_busy)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(strings.backupWorking),
            ),
          if (document != null) ...[
            const SizedBox(height: 20),
            Text(
              strings.backupPreview,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(document.fileName),
            Text(
              strings.backupCreated(
                DateFormat.yMd(strings.localeName)
                    .add_Hm()
                    .format(document.createdAt.toLocal()),
              ),
            ),
            Text(
              strings.backupSize(
                NumberFormat.decimalPattern(strings.localeName)
                    .format(document.bytes.length),
              ),
            ),
            Text(strings.backupValidated),
            const SizedBox(height: 12),
            FilledButton.icon(
              key: const ValueKey('backup-save'),
              onPressed: _busy ? null : _save,
              icon: const Icon(Icons.save_alt),
              label: Text(strings.backupSave),
            ),
          ],
          if (_message != null)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Text(
                _message!,
                key: const ValueKey('backup-result'),
                semanticsLabel: _message,
              ),
            ),
        ],
      ),
    );
  }
}
