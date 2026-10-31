import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'app_language.dart';
import 'data_backup.dart';
import 'backup_file.dart';
import 'data_restore.dart';

class DataBackupPage extends StatefulWidget {
  const DataBackupPage({super.key, this.capture, this.save, this.pick, this.restorer, this.onRestored});
  final Future<BackupDocument> Function()? capture;
  final Future<BackupSaveResult> Function(BackupDocument)? save;
  final Future<String?> Function()? pick;
  final BackupRestorer? restorer;
  final VoidCallback? onRestored;
  @override
  State<DataBackupPage> createState() => _DataBackupPageState();
}

class _DataBackupPageState extends State<DataBackupPage> {
  BackupDocument? _document;
  RestorePlan? _plan;
  bool _recovery = false;
  late final BackupRestorer _restorer = widget.restorer ?? BackupRestorer();
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

  Future<void> _pick() async {
    if (_busy || _recovery) return;
    setState(() { _busy = true; _plan = null; _message = null; });
    try {
      final text = await (widget.pick ?? readBackupFile)();
      if (text == null) return;
      final plan = await _restorer.prepare(text);
      if (mounted) setState(() => _plan = plan);
    } on RestoreFailure catch (error) {
      if (mounted) setState(() { _recovery = error.recoveryRequired;
        _message = appStrings(context).restoreRecovery; });
    } catch (_) {
      if (mounted) setState(() => _message = appStrings(context).restoreInvalid);
    } finally { if (mounted) setState(() => _busy = false); }
  }

  Future<void> _restore() async {
    if (_busy || _plan == null || _recovery) return;
    final plan = _plan!;
    setState(() => _busy = true);
    final strings = appStrings(context);
    final confirmed = await showDialog<bool>(context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text(strings.restoreQuestion),
        content: Text(strings.restoreWarning),
        actions: [
          TextButton(key: const ValueKey('restore-cancel'), onPressed: () => Navigator.pop(ctx, false), child: Text(strings.restoreCancel)),
          FilledButton(key: const ValueKey('restore-confirm'), onPressed: () => Navigator.pop(ctx, true), child: Text(strings.restoreConfirm)),
        ],
      ));
    if (!mounted) return;
    if (confirmed != true) { setState(() => _busy = false); return; }
    try {
      await _restorer.restore(plan, confirmed: true);
      if (!mounted) return;
      setState(() { _message = strings.restoreSuccess; _plan = null; _document = null; });
      widget.onRestored?.call();
    } on RestoreFailure catch (error) {
      if (mounted) setState(() { _recovery = error.recoveryRequired;
        _plan = null; _message = _recovery ? strings.restoreRecovery : strings.restoreFailed; });
    } catch (_) {
      if (mounted) setState(() { _plan = null; _message = strings.restoreStale; });
    } finally { if (mounted) setState(() => _busy = false); }
  }

  Future<void> _retryRecovery() async {
    setState(() => _busy = true);
    try {
      await _restorer.recover();
      if (mounted) { setState(() { _recovery = false; _plan = null; _document = null;
        _message = appStrings(context).restoreFailed; }); }
    } catch (_) { /* Keep recovery controls and block editing. */ }
    finally { if (mounted) setState(() => _busy = false); }
  }

  @override
  Widget build(BuildContext context) {
    final strings = appStrings(context);
    final document = _document;
    return PopScope(canPop: !_busy && !_recovery, child: Scaffold(
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
            onPressed: _busy || _recovery ? null : _prepare,
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
              onPressed: _busy || _recovery ? null : _save,
              icon: const Icon(Icons.save_alt),
              label: Text(strings.backupSave),
            ),
          ],
          const SizedBox(height: 24),
          Text(strings.restoreHint),
          FilledButton.icon(key: const ValueKey('restore-pick'),
            onPressed: _busy || _recovery ? null : _pick,
            icon: const Icon(Icons.restore), label: Text(strings.restorePick)),
          if (_plan case final plan?) ...[
            Text(strings.restorePreview, style: Theme.of(context).textTheme.titleLarge),
            Text(strings.backupCreated(DateFormat.yMd(strings.localeName).add_Hm().format(plan.document.createdAt.toLocal()))),
            Text(strings.restoreCounts(plan.added, plan.replaced, plan.unchanged)),
            for (final key in plan.keys) SelectableText(key),
            FilledButton(key: const ValueKey('restore-apply'),
              onPressed: _busy ? null : _restore, child: Text(strings.restoreConfirm)),
          ],
          if (_recovery) FilledButton(key: const ValueKey('restore-retry'),
            onPressed: _busy ? null : _retryRecovery, child: Text(strings.restoreRetry)),
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
    ));
  }
}
