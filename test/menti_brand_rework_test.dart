import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mennyiment/l10n/generated/app_localizations.dart';
import 'package:mennyiment/data_backup_page.dart';
import 'package:mennyiment/menti_identity/menti_avatar_renderer.dart';
import 'package:mennyiment/menti_identity/menti_identity.dart';
import 'package:mennyiment/menti_identity/menti_identity_controller.dart';
import 'package:mennyiment/menti_identity/menti_studio_page.dart';
import 'package:mennyiment/menti_identity/menti_visual_catalog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));
  test('all 115 stable selectors remain unique, including the premium cap asset', () {
    final options = MentiVisualCatalog.options;
    expect(options.length, 115);
    expect(options.map((o) => '${o.field}:${o.id}').toSet().length, 115);
    expect(MentiVisualCatalog.resolve('headwear', 'crown-cap').asset, 'core/crown-cap.png');
    expect(options.map((o) => o.preview).toSet().length, 115);
  });
  test('option IDs and required levels match the pre-rework fixture exactly', () {
    final baseline = jsonDecode(File('test/fixtures/menti_brand_stable_options.json').readAsStringSync());
    expect([for (final o in MentiVisualCatalog.options) [o.field, o.id, o.level.toString()]], baseline);
  });
  test('all seven original brand bitmaps remain byte-identical', () {
    final reference = jsonDecode(File('tool/menti_brand_reference/history.json').readAsStringSync()) as Map;
    for (final entry in (reference['references'] as List).cast<Map>()) {
      final bytes = File(entry['path'] as String).readAsBytesSync();
      var crc = 0xffffffff;
      for (final byte in bytes) {
        crc ^= byte;
        for (var bit = 0; bit < 8; bit++) {
          crc = (crc >> 1) ^ ((crc & 1) == 1 ? 0xedb88320 : 0);
        }
      }
      expect((crc ^ 0xffffffff) & 0xffffffff, entry['crc32'], reason: entry['path'] as String);
      expect(bytes.length, entry['bytes']);
      expect(entry['gitBlob'], entry['mainGitBlob']);
    }
  });
  test('committed visual evidence matches the actual renderer layer contracts', () {
    final cases = jsonDecode(File('test/fixtures/menti_brand_render_cases.json').readAsStringSync()) as List;
    expect(cases.length, 6);
    for (final item in cases.cast<Map>()) {
      final profile = MentiIdentityProfile(visual: MentiVisualProfile(
        Map<String, dynamic>.from(item['visual'] as Map)));
      expect(MentiAvatarRenderer.layers(profile), item['layers'], reason: item['name'] as String);
    }
  });
  test('same species material core is used once by all nine family/age combinations', () {
    for (final family in ['boy', 'girl', 'neutral']) {
      for (final age in ['young', 'adult', 'veteran']) {
        final p = MentiIdentityProfile(visual: MentiVisualProfile({'family': family, 'age': age}));
        final paths = MentiAvatarRenderer.layers(p);
        expect(paths.where((p) => p == MentiAssetLayer.core).length, 1);
        expect(paths, contains('${MentiVisualCatalog.root}bases/$family-$age.svg'));
        expect(paths.indexOf(MentiAssetLayer.core), lessThan(paths.indexWhere((p) => p.contains('/outfits/'))));
      }
    }
  });
  test('eyes face hat and clothing previews focus on their changing region', () {
    for (final field in ['eyes', 'face', 'headwear', 'outfit']) {
      final crop = MentiPreviewRenderer.cropFor(MentiVisualCatalog.forField(field).first);
      expect(crop.height, lessThan(180));
      expect(crop.width, lessThanOrEqualTo(320));
      expect(crop.left, greaterThanOrEqualTo(0));
      expect(crop.right, lessThanOrEqualTo(320));
      expect(crop.bottom, lessThanOrEqualTo(400));
    }
    expect(MentiPreviewRenderer.cropFor(MentiVisualCatalog.resolve('held', 'notebook')).right, 100);
    expect(MentiPreviewRenderer.cropFor(MentiVisualCatalog.resolve('held', 'flower')).left, 230);
  });
  test('every preview is a lightweight vector foreground, shared raster never duplicated', () async {
    for (final o in MentiVisualCatalog.options) {
      final source = await rootBundle.loadString(MentiVisualCatalog.root + o.preview);
      expect(source, isNot(contains('base64,')));
      expect(source.length, lessThan(30000));
    }
  });
  testWidgets('backup screen keeps the saved identity while an uncommitted draft differs', (tester) async {
    final c = MentiIdentityController(); addTearDown(c.dispose); await c.load();
    await tester.pumpWidget(MaterialApp(locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) => MentiIdentityScope(controller: c, child: child!),
      home: const DataBackupPage()));
    await tester.pumpAndSettle();
    final before = (await SharedPreferences.getInstance()).getKeys();
    c.choose(MentiVisualCatalog.resolve('family', 'girl'));
    await tester.pumpAndSettle();
    expect(c.draft.profile.visual.value('family'), 'girl');
    expect(tester.widget<MentiAvatarRenderer>(find.byType(MentiAvatarRenderer)).profile.visual.value('family'), 'boy');
    final prepare = find.byKey(const ValueKey('backup-prepare'));
    await tester.ensureVisible(prepare); await tester.tap(prepare); await tester.pumpAndSettle();
    expect((await SharedPreferences.getInstance()).getKeys(), before);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
  for (final locale in ['hu', 'en']) {
    for (final width in [320.0, 360.0, 390.0]) {
      for (final scale in [1.0, 2.0]) {
        testWidgets('brand Studio $locale $width ${scale}x has larger live identity and regional choices', (tester) async {
          tester.view.physicalSize = Size(width, 850); tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize); addTearDown(tester.view.resetDevicePixelRatio);
          final c = MentiIdentityController(); addTearDown(c.dispose); await c.load();
          final before = (await SharedPreferences.getInstance()).getKeys();
          await tester.pumpWidget(MaterialApp(locale: Locale(locale),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            builder: (context, child) => MediaQuery(data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(scale), disableAnimations: true), child: child!),
            home: MentiStudioPage(controller: c)));
          await tester.pumpAndSettle();
          final live = tester.widget<MentiAvatarRenderer>(find.byKey(const ValueKey('studio-live-preview')));
          expect(live.size, greaterThanOrEqualTo(220));
          for (final tabIndex in [1, 2, 3, 4]) {
            final tab = find.byKey(ValueKey('studio-tab-$tabIndex'));
            await tester.ensureVisible(tab); await tester.tap(tab); await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
          }
          expect((await SharedPreferences.getInstance()).getKeys(), before, reason: 'Preview does not write');
          await tester.pumpWidget(const SizedBox.shrink());
        });
      }
    }
  }
}
