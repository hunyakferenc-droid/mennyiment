import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mennyiment/l10n/generated/app_localizations.dart';
import 'package:mennyiment/menti_identity/menti_avatar_renderer.dart';
import 'package:mennyiment/menti_identity/menti_identity.dart';
import 'package:mennyiment/menti_identity/menti_identity_controller.dart';
import 'package:mennyiment/menti_identity/menti_identity_store.dart';
import 'package:mennyiment/menti_identity/menti_studio_page.dart';
import 'package:mennyiment/menti_identity/menti_visual_catalog.dart';

Widget host(Widget child, {String locale = 'hu', double scale = 1}) => MaterialApp(
  locale: Locale(locale), localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  builder: (context, child) => MediaQuery(data: MediaQuery.of(context).copyWith(
    textScaler: TextScaler.linear(scale), disableAnimations: true), child: child!), home: child);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));
  test('catalog has required variety and every SVG/thumbnail is bundled', () async {
    final manifest = (await AssetManifest.loadFromAssetBundle(rootBundle)).listAssets().toSet();
    expect(MentiVisualCatalog.forField('outfit').length, 20);
    expect(MentiVisualCatalog.forField('headwear').length, greaterThanOrEqualTo(8));
    for (final family in ['boy','girl','neutral']) {
      expect(MentiVisualCatalog.forField('hair', family: family).length, greaterThanOrEqualTo(6));
      for (final age in ['young','adult','veteran']) {
        expect(manifest, contains('${MentiVisualCatalog.root}bases/$family-$age.svg'));
      }
    }
    final sources = <String>{};
    for (final o in MentiVisualCatalog.options) {
      for (final path in [o.asset, o.preview]) {
        expect(manifest, contains(MentiVisualCatalog.root + path));
        if (path.endsWith('.png')) {
          final bytes = await rootBundle.load(MentiVisualCatalog.root + path);
          expect(bytes.getUint32(0), 0x89504e47);
        } else {
          final source = await rootBundle.loadString(MentiVisualCatalog.root + path);
          expect(source, contains('<svg'));
        }
      }
      expect(sources.add(o.preview), isTrue, reason: 'Every option has its own preview');
    }
  });
  test('layer order puts bag behind body, glasses over eyes and reaction last', () {
    final p = MentiIdentityProfile(visual: MentiVisualProfile({
      'back': 'cape', 'glasses': 'sunglasses', 'held': 'flower'}));
    final layers = MentiAvatarRenderer.layers(p, reaction: 'proud');
    expect(layers.indexWhere((p) => p.endsWith('accessories/cape.svg')),
      lessThan(layers.indexWhere((p) => p.contains('/bases/'))));
    expect(layers.indexWhere((p) => p.endsWith('accessories/sunglasses.svg')),
      greaterThan(layers.indexWhere((p) => p.contains('/eyes/'))));
    expect(layers.last, endsWith('reactions/proud.svg'));
  });
  test('unknown option safely renders but preserves stored identifier', () {
    final p = MentiIdentityProfile(visual: MentiVisualProfile({'family': 'future', 'outfit': 'future'}));
    expect(MentiAvatarRenderer.layers(p), contains('${MentiVisualCatalog.root}bases/boy-young.svg'));
    expect(MentiAvatarRenderer.layers(p), contains('${MentiVisualCatalog.root}outfits/basic.svg'));
    expect(p.visual.value('outfit'), 'future');
  });
  test('family and age produce distinct base layer paths', () {
    final paths = <String>{};
    for (final family in ['boy','girl','neutral']) {
      for (final age in ['young','adult','veteran']) {
        final layers = MentiAvatarRenderer.layers(MentiIdentityProfile(
          visual: MentiVisualProfile({'family': family, 'age': age})));
        paths.add(layers.singleWhere((p) => p.contains('/bases/')));
      }
    }
    expect(paths.length, 9);
  });
  test('random only chooses unlocked, family-compatible options and does not write', () async {
    final c = MentiIdentityController(); addTearDown(c.dispose); await c.load();
    for (var i = 0; i < 25; i++) {
      c.randomize(Random(i));
      final v = c.draft.profile.visual;
      expect(v.value('hair'), startsWith('${v.value('family')}-'));
      for (final field in MentiVisualProfile.defaults.keys) {
        expect(c.unlocked(MentiVisualCatalog.resolve(field, v.value(field))), isTrue);
      }
    }
    expect((await SharedPreferences.getInstance()).containsKey(MentiIdentityStore.key), isFalse);
  });
  test('save reload revert reset and presets preserve permanent cosmetics', () async {
    final c = MentiIdentityController(); addTearDown(c.dispose); await c.load();
    c.choose(MentiVisualCatalog.resolve('family','girl'));
    c.rename('Lili');
    expect(c.addPreset('Első'), isTrue);
    c.favorite(c.draft.presets.single);
    c.duplicate(c.draft.presets.single, 'Második');
    expect(await c.save(), isTrue);
    c.reset();
    expect(c.draft.profile.visual.value('family'), 'boy');
    c.revert();
    expect(c.draft.profile.visual.value('family'), 'girl');
    final again = MentiIdentityController(); addTearDown(again.dispose); await again.load();
    expect(again.profile.name, 'Lili');
    expect(again.draft.presets.length, 2);
    expect(again.draft.presets.map((p) => p.id).toSet().length, 2);
    expect(again.draft.presets.first.favorite, isTrue);
  });
  test('locked new reward cannot be chosen at level one', () async {
    final c = MentiIdentityController(); addTearDown(c.dispose); await c.load();
    c.choose(MentiVisualCatalog.resolve('outfit','legendary'));
    expect(c.draft.profile.visual.value('outfit'), 'basic');
  });
  test('existing unlocked outfit survives missing XP and reset', () async {
    final data = MentiIdentityDocument(profile: MentiIdentityProfile(),
      unlocks: MentiUnlockState(unlocked: ['outfit:legendary']));
    SharedPreferences.setMockInitialValues({MentiIdentityStore.key: data.encode()});
    final c = MentiIdentityController(); addTearDown(c.dispose); await c.load();
    c.choose(MentiVisualCatalog.resolve('outfit','legendary'));
    expect(c.draft.profile.visual.value('outfit'), 'legendary');
    c.reset(); await c.save();
    expect(c.draft.unlocks.unlocked, contains('outfit:legendary'));
  });
  test('corrupt XP uses defaults without changing any XP data', () async {
    SharedPreferences.setMockInitialValues({'mennyiment_menti_xp_v2': '{broken'});
    final c = MentiIdentityController(); addTearDown(c.dispose); await c.load();
    expect(c.ready, isTrue); expect(c.xpUnavailable, isTrue);
    expect(c.unlocked(MentiVisualCatalog.resolve('outfit','legendary')), isFalse);
    expect(await c.save(), isTrue);
    expect((await SharedPreferences.getInstance()).get('mennyiment_menti_xp_v2'), '{broken');
  });
  for (final locale in ['hu','en']) {
    for (final width in [320.0, 390.0, 1000.0]) {
      testWidgets('Studio $locale width $width at 200% has usable tabs and no overflow', (tester) async {
        tester.view.physicalSize = Size(width, 850); tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize); addTearDown(tester.view.resetDevicePixelRatio);
        final c = MentiIdentityController(); addTearDown(c.dispose); await c.load();
        await tester.pumpWidget(host(MentiStudioPage(controller: c), locale: locale, scale: 2));
        await tester.pumpAndSettle();
        for (var tab = 0; tab < 6; tab++) {
          final target = find.byKey(ValueKey('studio-tab-$tab'));
          await tester.ensureVisible(target); await tester.tap(target); await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        }
        await tester.pumpWidget(const SizedBox.shrink());
      });
    }
    testWidgets('live selection save and both renderer sizes in $locale', (tester) async {
      final c = MentiIdentityController(); addTearDown(c.dispose); await c.load();
      await tester.pumpWidget(host(MentiStudioPage(controller: c), locale: locale));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('option-family-girl'))); await tester.pumpAndSettle();
      expect(c.draft.profile.visual.value('family'), 'girl');
      await tester.tap(find.byKey(const ValueKey('studio-save'))); await tester.pumpAndSettle();
      expect(c.profile.visual.value('family'), 'girl');
      await tester.pumpWidget(host(Scaffold(body: Column(children: [
        MentiAvatarRenderer(profile: c.profile, size: 64),
        MentiReactionRenderer(profile: c.profile, mood: 'focused', size: 160),
      ])), locale: locale));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
}
