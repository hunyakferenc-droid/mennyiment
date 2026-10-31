import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mennyiment/avatar.dart';
import 'package:mennyiment/menti_character_setup.dart';
import 'package:mennyiment/menti_profile_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const legacy = MentiProfileStorage.legacyStyleKey;
  const character = MentiProfileStorage.characterStyleKey;
  const background = MentiProfileStorage.studioBackgroundKey;
  const outfit = MentiCharacterProfile.outfitKey;

  Future<SharedPreferences> load(Map<String, Object> values) async {
    SharedPreferences.setMockInitialValues(values);
    return SharedPreferences.getInstance();
  }

  for (var index = 0; index < 4; index++) {
    test(
      'Legacy background $index is migrated without inventing a family',
      () async {
        final prefs = await load({legacy: index});
        await MentiProfileStorage.migrate(prefs);
        expect(prefs.get(background), index);
        expect(prefs.containsKey(character), isFalse);
        expect(prefs.get(legacy), index);
        expect(MentiProfileStorage.characterStyle(prefs), 'Fiú Menti');
      },
    );
  }

  for (final family in MentiProfileStorage.characterStyles) {
    test('Legacy $family is migrated without inventing a background', () async {
      final prefs = await load({legacy: family, outfit: 'Legendás szett'});
      await MentiProfileStorage.migrate(prefs);
      expect(prefs.get(character), family);
      expect(prefs.containsKey(background), isFalse);
      expect(prefs.get(legacy), family);
      expect(prefs.get(outfit), 'Legendás szett');
      expect(MentiProfileStorage.studioBackground(prefs), 0);
    });
  }

  final invalid = <Object?>[
    null,
    -1,
    4,
    true,
    1.5,
    '',
    'Ismeretlen',
    '2',
    <String>['Fiú Menti'],
  ];
  for (var i = 0; i < invalid.length; i++) {
    test('Missing/ambiguous legacy data $i is left untouched', () async {
      final value = invalid[i];
      final prefs = await load({legacy: ?value});
      await MentiProfileStorage.migrate(prefs);
      expect(prefs.get(legacy), value);
      expect(prefs.containsKey(character), isFalse);
      expect(prefs.containsKey(background), isFalse);
      expect(MentiProfileStorage.characterStyle(prefs), 'Fiú Menti');
      expect(MentiProfileStorage.studioBackground(prefs), 0);
    });
  }

  for (final value in [2, 'Lány Menti']) {
    test(
      'Existing destinations win over legacy $value, even if invalid',
      () async {
        final prefs = await load({
          legacy: value,
          character: false,
          background: 'unknown',
        });
        await MentiProfileStorage.migrate(prefs);
        expect(prefs.get(character), false);
        expect(prefs.get(background), 'unknown');
        expect(prefs.get(legacy), value);
        expect(MentiProfileStorage.characterStyle(prefs), 'Fiú Menti');
        expect(MentiProfileStorage.studioBackground(prefs), 0);
      },
    );
  }

  test('Repeated cold loads and migrations preserve independent choices and outfit', () async {
    var prefs = await load({
      legacy: 3,
      outfit: 'Legendás szett',
      'unrelated': 'keep',
    });
    await MentiProfileStorage.migrate(prefs);
    for (final family in MentiProfileStorage.characterStyles) {
      await prefs.setString(character, family);
      await prefs.setInt(background, 1);
      for (var restart = 0; restart < 3; restart++) {
        // Recreate the preference instance from persisted values, without widget state.
        final persisted = {
          for (final key in prefs.getKeys()) key: prefs.get(key)!,
        };
        prefs = await load(persisted);
        await prefs.reload();
        await MentiProfileStorage.migrate(prefs);
        await MentiProfileStorage.migrate(prefs);
        expect(MentiProfileStorage.characterStyle(prefs), family);
        expect(MentiProfileStorage.studioBackground(prefs), 1);
        expect(prefs.get(outfit), 'Legendás szett');
        expect(prefs.get(legacy), 3);
        expect(prefs.get('unrelated'), 'keep');
      }
    }
  });

  testWidgets('Studio reads migrated background and writes only its own key', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1100, 4000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final prefs = await load({legacy: 'Lány Menti', background: 1});
    await tester.pumpWidget(const MaterialApp(home: AvatarPage()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    final mint = find.ancestor(
      of: find.text('Mentazöld'),
      matching: find.byType(InkWell),
    );
    await tester.ensureVisible(mint);
    expect(
      find.descendant(of: mint, matching: find.text('Kiválasztva')),
      findsOneWidget,
    );
    await tester.ensureVisible(find.text('Éjszakai klub'));
    await tester.tap(find.text('Éjszakai klub'));
    await tester.pump();
    expect(prefs.get(background), 0);
    expect(prefs.get(character), 'Lány Menti');
    expect(prefs.get(legacy), 'Lány Menti');
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
    'Character page switches families, saves and reloads selected outfit',
    (tester) async {
      tester.view.physicalSize = const Size(1100, 4000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final prefs = await load({
        legacy: 1,
        character: 'Lány Menti',
        outfit: 'Legendás szett',
      });
      Future<void> open() async {
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) {
                return TextButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const MentiCharacterSetupPage(),
                    ),
                  ),
                  child: const Text('Open'),
                );
              },
            ),
          ),
        );
        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();
      }

      for (final family in MentiProfileStorage.characterStyles) {
        await open();
        expect(
          find.text('${prefs.getString(character)}  •  Legendás szett'),
          findsOneWidget,
        );
        await tester.ensureVisible(find.text(family).last);
        await tester.tap(find.text(family).last);
        await tester.pump();
        expect(find.text('$family  •  Legendás szett'), findsOneWidget);
        await tester.ensureVisible(find.text('Saját Menti mentése'));
        await tester.tap(find.text('Saját Menti mentése'));
        await tester.pumpAndSettle();
        expect(prefs.get(character), family);
        expect(prefs.get(background), 1);
        expect(prefs.get(legacy), 1);
        expect(prefs.get(outfit), 'Legendás szett');
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
      }
    },
  );
}
