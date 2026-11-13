import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'app_language.dart';
import 'menti_access.dart';
import 'menti_ui.dart';

/// Informational routes only. Existing home owns export/import and its refresh.
typedef OpenLocalBackup = Future<void> Function();

class InformationBody extends StatelessWidget {
  const InformationBody({
    super.key,
    required this.title,
    required this.children,
  });
  final String title;
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      toolbarHeight: 56 * MediaQuery.textScalerOf(context).scale(1).clamp(1, 2),
      title: Text(title, maxLines: 2),
      actions: const [LanguageMenu()],
    ),
    body: MentiPageBody(children: children),
  );
}

Widget informationSection(
  BuildContext context,
  String id,
  String title,
  String body,
) => MentiPanel(
  key: ValueKey(id),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Semantics(
        header: true,
        child: Text(title, style: Theme.of(context).textTheme.titleLarge),
      ),
      const SizedBox(height: 8),
      Text(body),
    ],
  ),
);

class _BackupLink extends StatefulWidget {
  const _BackupLink({super.key, this.onOpen});
  final OpenLocalBackup? onOpen;
  @override
  State<_BackupLink> createState() => _BackupLinkState();
}

class _BackupLinkState extends State<_BackupLink> {
  bool opening = false;
  Future<void> _open() async {
    if (opening || widget.onOpen == null) return;
    setState(() => opening = true);
    try {
      await widget.onOpen!();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(appStrings(context).infoBackupError)),
        );
      }
    } finally {
      if (mounted) setState(() => opening = false);
    }
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: FilledButton.icon(
      onPressed: opening || widget.onOpen == null ? null : _open,
      icon: const Icon(Icons.save_alt),
      label: Text(appStrings(context).infoBackupOpen),
    ),
  );
}

class DataSafetyPage extends StatelessWidget {
  const DataSafetyPage({super.key, required this.onOpenBackup});
  final OpenLocalBackup? onOpenBackup;
  @override
  Widget build(BuildContext context) {
    final s = appStrings(context);
    return InformationBody(
      title: s.infoDataTitle,
      children: [
        Text(s.infoDataIntro),
        const SizedBox(height: 16),
        _BackupLink(
          key: const ValueKey('data-open-backup'),
          onOpen: onOpenBackup,
        ),
        informationSection(
          context,
          'data-records',
          s.infoRecordsTitle,
          s.infoRecordsBody,
        ),
        informationSection(
          context,
          'data-profile',
          s.infoProfileTitle,
          s.infoProfileBody,
        ),
        informationSection(
          context,
          'data-device',
          s.infoDeviceTitle,
          s.infoDeviceBody,
        ),
        informationSection(
          context,
          'data-browser',
          s.infoBrowserTitle,
          s.infoBrowserBody,
        ),
        informationSection(
          context,
          'data-protection',
          s.infoProtectionTitle,
          s.infoProtectionBody,
        ),
        informationSection(
          context,
          'data-backup',
          s.infoBackupTitle,
          s.infoBackupBody,
        ),
        informationSection(
          context,
          'data-restore',
          s.infoRestoreTitle,
          s.infoRestoreBody,
        ),
        informationSection(
          context,
          'data-internet',
          s.infoInternetTitle,
          s.infoInternetBody,
        ),
        informationSection(
          context,
          'data-permissions',
          s.infoPermissionsTitle,
          s.infoPermissionsBody,
        ),
      ],
    );
  }
}

class MentiHelpPage extends StatelessWidget {
  const MentiHelpPage({super.key, required this.onOpenBackup});
  final OpenLocalBackup? onOpenBackup;
  @override
  Widget build(BuildContext context) {
    final s = appStrings(context);
    return InformationBody(
      title: s.infoHelpTitle,
      children: [
        informationSection(
          context,
          'help-self-report',
          s.infoSelfReportTitle,
          s.infoSelfReportBody,
        ),
        if (MentiAccessScope.adultOf(context)) ...[
          informationSection(
            context,
            'help-journal',
            s.infoJournalTitle,
            s.infoJournalBody,
          ),
          informationSection(
            context,
            'help-editor',
            s.infoEditorTitle,
            s.infoEditorBody,
          ),
        ] else
          informationSection(
            context,
            'help-minor',
            s.infoMinorTitle,
            s.infoMinorBody,
          ),
        informationSection(
          context,
          'help-prices',
          s.infoPricesTitle,
          s.infoPricesBody,
        ),
        informationSection(
          context,
          'help-goals',
          s.infoGoalsTitle,
          s.infoGoalsBody,
        ),
        informationSection(
          context,
          'help-adventures',
          s.infoAdventuresTitle,
          s.infoAdventuresBody,
        ),
        informationSection(
          context,
          'help-backup',
          s.infoBackupTitle,
          s.infoHelpBackupBody,
        ),
        _BackupLink(
          key: const ValueKey('help-open-backup'),
          onOpen: onOpenBackup,
        ),
        OutlinedButton.icon(
          key: const ValueKey('help-open-data'),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute<void>(
              builder: (_) => DataSafetyPage(onOpenBackup: onOpenBackup),
            ),
          ),
          icon: const Icon(Icons.privacy_tip_outlined),
          label: Text(s.infoDataTitle),
        ),
      ],
    );
  }
}

bool _fontLicensesRegistered = false;
void _registerFontLicenses() {
  if (_fontLicensesRegistered) return;
  _fontLicensesRegistered = true;
  LicenseRegistry.addLicense(() async* {
    yield LicenseEntryWithLineBreaks([
      'Roboto',
    ], await rootBundle.loadString('assets/fonts/roboto/LICENSE.txt'));
    yield LicenseEntryWithLineBreaks([
      'Noto Color Emoji',
    ], await rootBundle.loadString('assets/fonts/menti_emoji/OFL.txt'));
  });
}

class MentiAboutPage extends StatefulWidget {
  const MentiAboutPage({super.key, required this.onOpenBackup, this.loadInfo});
  final OpenLocalBackup? onOpenBackup;
  final Future<PackageInfo> Function()? loadInfo;
  @override
  State<MentiAboutPage> createState() => _MentiAboutPageState();
}

class _MentiAboutPageState extends State<MentiAboutPage> {
  PackageInfo? info;
  bool loading = true, failed = false;
  @override
  void initState() {
    super.initState();
    _registerFontLicenses();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      loading = true;
      failed = false;
    });
    try {
      final next =
          await (widget.loadInfo?.call() ?? PackageInfo.fromPlatform());
      if (next.version.isEmpty || next.buildNumber.isEmpty) {
        throw const FormatException('Unavailable build metadata');
      }
      if (mounted) setState(() => info = next);
    } catch (_) {
      if (mounted) setState(() => failed = true);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = appStrings(context);
    return InformationBody(
      title: s.infoAboutTitle,
      children: [
        Semantics(
          header: true,
          child: Text(
            s.appTitle,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
        ),
        const SizedBox(height: 12),
        if (loading)
          const LinearProgressIndicator()
        else if (failed) ...[
          Text(s.infoVersionError, key: const ValueKey('about-version-error')),
          TextButton(
            key: const ValueKey('about-version-retry'),
            onPressed: _load,
            child: Text(s.infoRetry),
          ),
        ] else
          Text(
            s.infoVersion(info!.version, info!.buildNumber),
            key: const ValueKey('about-version'),
          ),
        const SizedBox(height: 16),
        informationSection(
          context,
          'about-summary',
          s.infoAboutSummaryTitle,
          s.infoAboutSummaryBody,
        ),
        informationSection(
          context,
          'about-self-report',
          s.infoSelfReportTitle,
          s.infoSelfReportBody,
        ),
        OutlinedButton.icon(
          key: const ValueKey('about-open-help'),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute<void>(
              builder: (_) => MentiHelpPage(onOpenBackup: widget.onOpenBackup),
            ),
          ),
          icon: const Icon(Icons.help_outline),
          label: Text(s.infoHelpTitle),
        ),
        OutlinedButton.icon(
          key: const ValueKey('about-open-data'),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute<void>(
              builder: (_) => DataSafetyPage(onOpenBackup: widget.onOpenBackup),
            ),
          ),
          icon: const Icon(Icons.privacy_tip_outlined),
          label: Text(s.infoDataTitle),
        ),
        TextButton(
          key: const ValueKey('about-open-licenses'),
          onPressed: () => showLicensePage(
            context: context,
            applicationName: s.appTitle,
            applicationVersion: info == null
                ? null
                : '${info!.version}+${info!.buildNumber}',
          ),
          child: Text(s.infoLicenses),
        ),
      ],
    );
  }
}
