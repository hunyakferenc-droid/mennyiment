import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mennyiment/menti_character_catalog.dart';
import 'package:mennyiment/menti_character_setup.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const directories = [
    'assets/images/menti_outfits',
    'assets/images/menti_outfits_642/lany',
    'assets/images/menti_outfits_642/semleges',
  ];
  const families = ['Fiú Menti', 'Lány Menti', 'Semleges Menti'];
  const familyIds = ['boy', 'girl', 'neutral'];
  const files = [
    'alap.png',
    'buli.png',
    'sport.png',
    'uzleti.png',
    'fesztival.png',
    'legendas.png',
  ];
  const labels = [
    'Alap szett',
    'Buli szett',
    'Sport szett',
    'Üzleti szett',
    'Fesztivál szett',
    'Legendás szett',
  ];
  const ids = ['basic', 'party', 'sport', 'business', 'festival', 'legendary'];
  const levels = [1, 1, 1, 2, 3, 5];

  test('Catalog identifiers, order and unlock levels are stable', () {
    expect(MentiCharacterFamily.values.map((f) => f.id), familyIds);
    expect(MentiOutfit.values.map((o) => o.id), ids);
    expect(MentiOutfit.values.map((o) => o.requiredLevel), levels);
    expect(MentiCharacterFamily.values.length * MentiOutfit.values.length, 18);
    expect(
      MentiCharacterFamily.values.map((f) => f.selectorAsset).toSet().length,
      3,
    );
    expect(MentiCharacterFamily.resolve('unknown'), isNull);
    expect(MentiCharacterFamily.resolve(1), isNull);
    expect(MentiOutfit.resolve(null), isNull);
    expect(MentiOutfit.resolve('unknown'), isNull);
  });

  for (var f = 0; f < families.length; f++) {
    for (var o = 0; o < labels.length; o++) {
      test(
        '${families[f]} / ${labels[o]} resolves to the existing bundled image',
        () async {
          final family = MentiCharacterFamily.values[f];
          final outfit = MentiOutfit.values[o];
          expect(MentiCharacterFamily.resolve(families[f]), family);
          expect(MentiCharacterFamily.resolve(familyIds[f]), family);
          expect(MentiOutfit.resolve(labels[o]), outfit);
          expect(MentiOutfit.resolve(ids[o]), outfit);
          final expected = '${directories[f]}/${files[o]}';
          expect(family.assetFor(outfit), expected);
          expect(File(expected).existsSync(), isTrue);
          expect(
            (await rootBundle.load(expected)).lengthInBytes,
            greaterThan(0),
          );
          expect(File(family.selectorAsset).existsSync(), isTrue);
          expect(
            (await rootBundle.load(family.selectorAsset)).lengthInBytes,
            greaterThan(0),
          );
        },
      );
    }
  }

  testWidgets('All 18 legacy selections survive save as IDs and reopen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1100, 4000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    const familyKey = MentiCharacterProfile.styleKey;
    const outfitKey = MentiCharacterProfile.outfitKey;
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

    for (final family in MentiCharacterFamily.values) {
      for (final outfit in MentiOutfit.values) {
        SharedPreferences.setMockInitialValues({
          familyKey: family.label,
          outfitKey: outfit.label,
        });
        final prefs = await SharedPreferences.getInstance();
        await open();
        expect(
          find.text('${family.label}  •  ${outfit.label}'),
          findsOneWidget,
        );
        final selectedImage = find.byWidgetPredicate(
          (w) =>
              w is Image &&
              w.image is AssetImage &&
              (w.image as AssetImage).assetName == family.assetFor(outfit),
        );
        expect(selectedImage, findsNWidgets(2));
        // Loading does not rewrite legacy preferences.
        expect(prefs.get(familyKey), family.label);
        expect(prefs.get(outfitKey), outfit.label);
        await tester.ensureVisible(find.text('Saját Menti mentése'));
        await tester.tap(find.text('Saját Menti mentése'));
        await tester.pumpAndSettle();
        expect(prefs.get(familyKey), family.id);
        expect(prefs.get(outfitKey), outfit.id);
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
        await prefs.reload();
        await open();
        expect(
          find.text('${family.label}  •  ${outfit.label}'),
          findsOneWidget,
        );
        expect(selectedImage, findsNWidgets(2));
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
      }
    }
  });
}
