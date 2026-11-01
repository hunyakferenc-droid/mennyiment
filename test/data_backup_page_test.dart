import 'support/adult_access_fixture.dart';
import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mennyiment/main.dart';
import 'package:mennyiment/data_backup.dart';
import 'package:mennyiment/backup_file.dart';
import 'package:mennyiment/data_backup_page.dart';
import 'package:mennyiment/l10n/generated/app_localizations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final at = DateTime.utc(2026, 10, 31, 12, 34);
  Future<BackupDocument> document() =>
      BackupExporter(clock: () => at).capture();
  Widget app(String locale, Widget child) => MaterialApp(
    locale: Locale(locale),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    home: child,
  );
  AppLocalizations strings(WidgetTester tester) =>
      AppLocalizations.of(tester.element(find.byType(DataBackupPage)))!;
  Finder prepare() => find.byKey(const ValueKey('backup-prepare'));
  Finder save() => find.byKey(const ValueKey('backup-save'));
  setUp(
    () => SharedPreferences.setMockInitialValues({adultAccessKey: adultAccessValue,
      'mennyiment_drinks_v1': '  [{"legacy": true}]  ',
      'mennyiment_character_style_v2': 'Lány Menti',
      'mennyiment_outfit_v2': 'Legendás szett',
      'mennyiment_menti_xp_v2': '{"xp":150,"days":[],"completed":[]}',
      'mennyiment_reduce_motion_v1': true,
    }),
  );

  for (final locale in ['hu', 'en']) {
    testWidgets(
      '$locale: narrow preview and explicit file save preserve all source values',
      (tester) async {
        tester.view.physicalSize = const Size(360, 2200);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final prefs = await SharedPreferences.getInstance();
        final before = {for (final k in prefs.getKeys()) k: prefs.get(k)};
        var saved = 0;
        BackupDocument? artifact;
        await tester.pumpWidget(
          app(
            locale,
            DataBackupPage(
              capture: document,
              save: (doc) async {
                saved++;
                artifact = doc;
                return BackupSaveResult.saved;
              },
            ),
          ),
        );
        final text = strings(tester);
        expect(find.text(text.backupPrivacy), findsOneWidget);
        expect(find.text(text.backupRestoreDeferred), findsOneWidget);
        expect(save(), findsNothing);
        await tester.tap(prepare());
        await tester.pumpAndSettle();
        expect(find.text(text.backupPreview), findsOneWidget);
        expect(saved, 0);
        await tester.ensureVisible(save());
        await tester.tap(save());
        await tester.pumpAndSettle();
        expect(saved, 1);
        expect(
          BackupDocument.decode(utf8.decode(artifact!.bytes)).entryCount,
          before.length,
        );
        expect(find.text(text.backupSaved), findsOneWidget);
        expect({for (final k in prefs.getKeys()) k: prefs.get(k)}, before);
        expect(tester.takeException(), isNull);
      },
    );
    testWidgets('$locale: preparation failure never offers an invalid file', (
      tester,
    ) async {
      await tester.pumpWidget(
        app(
          locale,
          DataBackupPage(capture: () => throw StateError('unreadable')),
        ),
      );
      await tester.tap(prepare());
      await tester.pumpAndSettle();
      expect(find.text(strings(tester).backupPrepareError), findsOneWidget);
      expect(save(), findsNothing);
    });
    testWidgets(
      '$locale: save failure is visible and a retry uses the same validated artifact',
      (tester) async {
        var calls = 0;
        final payloads = <String>[];
        await tester.pumpWidget(
          app(
            locale,
            DataBackupPage(
              capture: document,
              save: (doc) async {
                payloads.add(doc.json);
                if (++calls == 1) throw StateError('disk failure');
                return BackupSaveResult.saved;
              },
            ),
          ),
        );
        await tester.tap(prepare());
        await tester.pumpAndSettle();
        await tester.ensureVisible(save());
        await tester.tap(save());
        await tester.pumpAndSettle();
        expect(find.text(strings(tester).backupSaveError), findsOneWidget);
        await tester.tap(save());
        await tester.pumpAndSettle();
        expect(find.text(strings(tester).backupSaved), findsOneWidget);
        expect(payloads[0], payloads[1]);
      },
    );
    for (final result in [
      BackupSaveResult.cancelled,
      BackupSaveResult.downloadRequested,
    ]) {
      testWidgets('$locale: $result does not claim a saved disk file', (
        tester,
      ) async {
        await tester.pumpWidget(
          app(
            locale,
            DataBackupPage(capture: document, save: (_) async => result),
          ),
        );
        await tester.tap(prepare());
        await tester.pumpAndSettle();
        await tester.ensureVisible(save());
        await tester.tap(save());
        await tester.pumpAndSettle();
        final text = strings(tester);
        expect(
          find.text(
            result == BackupSaveResult.cancelled
                ? text.backupCancelled
                : text.backupDownloadRequested,
          ),
          findsOneWidget,
        );
        expect(find.text(text.backupSaved), findsNothing);
      });
    }
    testWidgets(
      '$locale: home opens backup without disturbing profile, XP or reduced motion',
      (tester) async {
        tester.view.physicalSize = const Size(1100, 4000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('mennyiment_locale_v1', locale);
        await prefs.setBool('mennyiment_character_setup_complete_v1', true);
        await tester.pumpWidget(const MennyiMentApp());
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 600));
        final before = {for (final k in prefs.getKeys()) k: prefs.get(k)};
        await tester.tap(find.byKey(const ValueKey('open-data-backup')));
        await tester.pumpAndSettle();
        expect(find.byType(DataBackupPage), findsOneWidget);
        await tester.tap(prepare());
        await tester.pumpAndSettle();
        expect(find.text(strings(tester).backupPreview), findsOneWidget);
        expect({for (final k in prefs.getKeys()) k: prefs.get(k)}, before);
        expect(tester.hasRunningAnimations, false);
        await tester.tap(find.byType(BackButton));
        await tester.pumpAndSettle();
        expect(prefs.getString('mennyiment_character_style_v2'), 'Lány Menti');
        expect(prefs.getString('mennyiment_outfit_v2'), 'Legendás szett');
        expect(prefs.getBool('mennyiment_reduce_motion_v1'), true);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
      },
    );
  }
  testWidgets(
    'Busy guards prevent duplicate IO and late completion after disposal is safe',
    (tester) async {
      final prepared = Completer<BackupDocument>();
      final saved = Completer<BackupSaveResult>();
      var reads = 0;
      var writes = 0;
      await tester.pumpWidget(
        app(
          'hu',
          DataBackupPage(
            capture: () {
              reads++;
              return prepared.future;
            },
            save: (_) {
              writes++;
              return saved.future;
            },
          ),
        ),
      );
      final prepareCallback = tester.widget<FilledButton>(prepare()).onPressed!;
      prepareCallback();
      prepareCallback();
      await tester.pump();
      expect(reads, 1);
      expect(tester.widget<FilledButton>(prepare()).onPressed, isNull);
      prepared.complete(await document());
      await tester.pumpAndSettle();
      await tester.ensureVisible(save());
      final saveCallback = tester.widget<FilledButton>(save()).onPressed!;
      saveCallback();
      saveCallback();
      await tester.pump();
      expect(writes, 1);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      saved.complete(BackupSaveResult.saved);
      await tester.pump();
      expect(tester.takeException(), isNull);
    },
  );
}
