import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mennyiment/app_information.dart';
import 'package:mennyiment/data_backup.dart';
import 'package:mennyiment/data_backup_page.dart';
import 'package:mennyiment/data_restore.dart';
import 'package:mennyiment/l10n/generated/app_localizations.dart';
import 'package:mennyiment/main.dart';
import 'package:mennyiment/menti_access.dart';
import 'package:mennyiment/menti_design.dart';
import 'package:mennyiment/menti_settings_page.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(initializeDateFormatting);
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    PackageInfo.setMockInitialValues(
      appName: 'MennyiMent?',
      packageName: 'com.example.mennyiment',
      version: '9.8.7',
      buildNumber: '123',
      buildSignature: '',
    );
  });
  Finder key(String id) => find.byKey(ValueKey(id));
  Future<void> reveal(WidgetTester t, Finder finder) async {
    if (finder.evaluate().isEmpty) {
      final list = find.byType(ListView).first;
      final scrollable = find
          .descendant(of: list, matching: find.byType(Scrollable))
          .first;
      t.state<ScrollableState>(scrollable).position.jumpTo(0);
      await t.pumpAndSettle();
      for (var i = 0; i < 100 && finder.evaluate().isEmpty; i++) {
        await t.drag(list, const Offset(0, -180));
        await t.pumpAndSettle();
      }
      if (finder.evaluate().isEmpty) {
        fail('Unreachable information control: $finder');
      }
    }
    await t.ensureVisible(finder);
    await t.pumpAndSettle();
  }

  Future<void> tap(WidgetTester t, Finder finder) async {
    await reveal(t, finder);
    await t.tap(finder);
    await t.pumpAndSettle();
    expect(t.takeException(), isNull);
  }

  Future<void> show(
    WidgetTester t, {
    String locale = 'hu',
    double width = 320,
    double scale = 2,
    Widget? page,
    OpenLocalBackup? onBackup,
  }) async {
    t.view.physicalSize = Size(width, 700);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
    await t.pumpWidget(
      MaterialApp(
        theme: MentiDesign.theme,
        locale: Locale(locale),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        builder: (c, child) => MediaQuery(
          data: MediaQuery.of(c).copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        ),
        home: page ?? MentiSettingsPage(onOpenBackup: onBackup),
      ),
    );
    await t.pumpAndSettle();
    addTearDown(() async {
      await t.pumpWidget(const SizedBox.shrink());
      await t.pumpAndSettle();
    });
  }

  for (final locale in ['hu', 'en']) {
    for (final width in [320.0, 360.0, 390.0, 430.0]) {
      for (final scale in [1.0, 2.0]) {
        testWidgets(
          '$locale $width/$scale: all information pages, true build number and existing backup callback are reachable',
          (t) async {
            var opens = 0;
            await show(
              t,
              locale: locale,
              width: width,
              scale: scale,
              onBackup: () async {
                opens++;
              },
            );
            final s = lookupAppLocalizations(Locale(locale));
            await tap(t, key('settings-open-data'));
            for (final id in [
              'data-records',
              'data-profile',
              'data-device',
              'data-browser',
              'data-protection',
              'data-backup',
              'data-restore',
              'data-internet',
              'data-permissions',
            ]) {
              await reveal(t, key(id));
              expect(t.takeException(), isNull);
            }
            expect(find.text(s.infoPermissionsBody), findsOneWidget);
            await tap(
              t,
              find.descendant(
                of: key('data-open-backup'),
                matching: find.byType(FilledButton),
              ),
            );
            expect(opens, 1);
            await tap(t, find.byType(BackButton));
            await tap(t, key('settings-open-help'));
            for (final id in [
              'help-self-report',
              'help-journal',
              'help-editor',
              'help-prices',
              'help-goals',
              'help-adventures',
              'help-backup',
            ]) {
              await reveal(t, key(id));
              expect(t.takeException(), isNull);
            }
            await reveal(t, key('help-prices'));
            expect(find.text(s.infoPricesBody), findsOneWidget);
            await tap(t, find.byType(BackButton));
            await tap(t, key('settings-open-about'));
            expect(find.text(s.infoVersion('9.8.7', '123')), findsOneWidget);
            expect(find.textContaining('2.3.1'), findsNothing);
            await reveal(t, key('about-open-licenses'));
            expect(t.takeException(), isNull);
            await tap(t, key('about-open-data'));
            expect(find.byType(DataSafetyPage), findsOneWidget);
            await tap(
              t,
              find.descendant(
                of: key('data-open-backup'),
                matching: find.byType(FilledButton),
              ),
            );
            expect(opens, 2);
          },
        );
      }
    }
  }

  for (final invalid in ['throw', 'version', 'build']) {
    testWidgets(
      'About never guesses missing metadata; retry recovers: $invalid',
      (t) async {
        var attempts = 0;
        await show(
          t,
          locale: 'en',
          page: MentiAboutPage(
            onOpenBackup: () async {},
            loadInfo: () async {
              attempts++;
              if (attempts == 1 && invalid == 'throw') {
                throw StateError('private diagnostic');
              }
              return PackageInfo(
                appName: 'MennyiMent?',
                packageName: 'com.example.mennyiment',
                version: attempts == 1 && invalid == 'version' ? '' : '4.5.6',
                buildNumber: attempts == 1 && invalid == 'build' ? '' : '789',
              );
            },
          ),
        );
        expect(key('about-version-error'), findsOneWidget);
        expect(key('about-version'), findsNothing);
        expect(find.textContaining('private diagnostic'), findsNothing);
        await tap(t, key('about-version-retry'));
        await reveal(t, key('about-version'));
        expect(find.text('Version: 4.5.6 · build 789'), findsOneWidget);
        expect(key('about-version-error'), findsNothing);
      },
    );
  }

  for (final throwing in [false, true]) {
    testWidgets(
      'Backup link serializes navigation and reports failure safely: $throwing',
      (t) async {
        var opens = 0;
        final gate = Completer<void>();
        await show(
          t,
          locale: 'en',
          page: DataSafetyPage(
            onOpenBackup: () async {
              opens++;
              await gate.future;
              if (throwing) throw StateError('private path');
            },
          ),
        );
        final link = find.descendant(
          of: key('data-open-backup'),
          matching: find.byType(FilledButton),
        );
        final activate = t.widget<FilledButton>(link).onPressed!;
        activate();
        activate();
        await t.pump();
        expect(opens, 1);
        expect(t.widget<FilledButton>(link).onPressed, isNull);
        gate.complete();
        await t.pumpAndSettle();
        expect(t.widget<FilledButton>(link).onPressed, isNotNull);
        expect(find.textContaining('private path'), findsNothing);
        expect(
          find.text(lookupAppLocalizations(const Locale('en')).infoBackupError),
          throwing ? findsOneWidget : findsNothing,
        );
      },
    );
  }

  for (final locale in ['hu', 'en']) {
    testWidgets(
      '$locale: information navigation writes no profile, journal, XP, age or unknown data',
      (t) async {
        const raw = '{"version":99,"future":[1,true,"keep"]}';
        SharedPreferences.setMockInitialValues({
          'mennyiment_identity_v22': raw,
          'mennyiment_drinks_v1': '[{"future":"raw"}]',
          'mennyiment_menti_xp_v2': raw,
          'mennyiment_adventures_v1': raw,
          'mennyiment_unknown_future_v1': raw,
          MentiAccessSettings.key:
              '{"version":1,"audience":"minor","complete":true}',
        });
        final prefs = await SharedPreferences.getInstance();
        final before = {for (final k in prefs.getKeys()) k: prefs.get(k)};
        await show(t, locale: locale, onBackup: () async {});
        for (final id in [
          'settings-open-data',
          'settings-open-help',
          'settings-open-about',
        ]) {
          await tap(t, key(id));
          await tap(t, find.byType(BackButton));
        }
        expect({for (final k in prefs.getKeys()) k: prefs.get(k)}, before);
      },
    );
  }

  testWidgets(
    'Minor help preserves restrictions and explains declaration without adult tutorial',
    (t) async {
      SharedPreferences.setMockInitialValues({
        MentiAccessSettings.key:
            '{"version":1,"audience":"minor","complete":true}',
      });
      final access = MentiAccessSettings();
      await access.load();
      addTearDown(access.dispose);
      await show(
        t,
        locale: 'en',
        page: MentiAccessScope(
          settings: access,
          child: MentiHelpPage(onOpenBackup: () async {}),
        ),
      );
      await reveal(t, key('help-minor'));
      expect(key('help-minor'), findsOneWidget);
      expect(key('help-journal'), findsNothing);
      expect(key('help-editor'), findsNothing);
      await reveal(t, key('help-prices'));
      expect(t.takeException(), isNull);
    },
  );

  for (final locale in ['hu', 'en']) {
    testWidgets(
      '$locale: settings link reuses real backup and root restore refresh',
      (t) async {
        t.view.physicalSize = const Size(390, 900);
        t.view.devicePixelRatio = 1;
        addTearDown(t.view.resetPhysicalSize);
        addTearDown(t.view.resetDevicePixelRatio);
        SharedPreferences.setMockInitialValues({
          MentiAccessSettings.key:
              '{"version":1,"audience":"adult","complete":true}',
          'mennyiment_character_setup_complete_v1': true,
          'mennyiment_locale_v1': locale,
          'mennyiment_reduce_motion_v1': true,
          'mennyiment_drinks_v1': '[]',
          'mennyiment_menti_xp_v2': '{"xp":150,"days":[],"completed":[]}',
        });
        await t.pumpWidget(const MennyiMentApp());
        await t.pumpAndSettle();
        final prefs = await SharedPreferences.getInstance();
        final before = {for (final k in prefs.getKeys()) k: prefs.get(k)};
        await t.tap(key('home-menu'));
        await t.pumpAndSettle();
        await tap(t, key('open-menti-settings'));
        await tap(t, key('settings-open-data'));
        await tap(
          t,
          find.descendant(
            of: key('data-open-backup'),
            matching: find.byType(FilledButton),
          ),
        );
        final page = t.widget<DataBackupPage>(find.byType(DataBackupPage));
        expect(page.onRestored, isNotNull);
        expect({for (final k in prefs.getKeys()) k: prefs.get(k)}, before);
        final backup =
            jsonDecode((await BackupExporter().capture()).json) as Map;
        backup['entries']['mennyiment_drinks_v1']['value'] = jsonEncode([
          Drink(
            'Restored sample',
            250,
            0,
            time: DateTime.now(),
            priceFt: 0,
          ).toJson(),
        ]);
        final restorer = BackupRestorer();
        await restorer.restore(
          await restorer.prepare(jsonEncode(backup)),
          confirmed: true,
        );
        page.onRestored!();
        await t.pumpAndSettle();
        expect(find.byType(DataBackupPage), findsNothing);
        await t.scrollUntilVisible(
          find.text('Restored sample'),
          180,
          scrollable: find.byType(Scrollable).first,
          maxScrolls: 60,
        );
        await t.pumpAndSettle();
        expect(find.textContaining('Restored sample'), findsWidgets);
        expect(
          prefs.getString('mennyiment_menti_xp_v2'),
          before['mennyiment_menti_xp_v2'],
        );
        await t.pumpWidget(const SizedBox.shrink());
        await t.pumpAndSettle();
      },
    );
  }
}
