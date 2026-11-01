import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mennyiment/menti_identity/menti_identity.dart';
import 'package:mennyiment/menti_identity/menti_avatar_renderer.dart';
import 'package:mennyiment/menti_identity/menti_premium_renderer.dart';
import 'package:mennyiment/menti_identity/menti_premium_atlas.dart';
import 'package:mennyiment/menti_identity/menti_visual_catalog.dart';
import 'package:mennyiment/menti_identity/menti_reference_rig.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'all material sprites are present and inside unchanged source sheets',
    () {
      final manifest = jsonDecode(
        File('test/fixtures/menti_premium_atlases.json').readAsStringSync(),
      ) as Map;
      expect(manifest.keys.toSet(), {
        'bodies',
        'outfits',
        'hair',
        'features',
        'headwear',
      });
      expect(MentiPremiumAtlas.rects.length, 86);
      expect(MentiPremiumAtlas.handOutlines.length, 18);
      for (final contour in MentiPremiumAtlas.handOutlines.values) {
        expect(contour.length, greaterThan(12));
        for (final point in contour) {
          expect(point.dx, inInclusiveRange(0, 1));
          expect(point.dy, inInclusiveRange(0, 1));
        }
      }
      for (final entry in manifest.entries) {
        final data = entry.value as Map;
        final bytes = File(data['asset'] as String).readAsBytesSync();
        expect(bytes.length, data['bytes']);
        var crc = 0xffffffff;
        for (final byte in bytes) {
          crc ^= byte;
          for (var bit = 0; bit < 8; bit++) {
            crc = (crc >> 1) ^ ((crc & 1) == 1 ? 0xedb88320 : 0);
          }
        }
        expect((crc ^ 0xffffffff) & 0xffffffff, data['crc32']);

        for (final sprite in (data['sprites'] as Map).keys) {
          final rect = MentiPremiumAtlas.rects['${entry.key}/$sprite']!;
          expect(rect.width, greaterThan(0));
          expect(rect.height, greaterThan(0));
          expect(rect.left, greaterThanOrEqualTo(0));
          expect(rect.top, greaterThanOrEqualTo(0));
          expect(rect.right, lessThanOrEqualTo((data['size'] as List)[0]));
          expect(rect.bottom, lessThanOrEqualTo((data['size'] as List)[1]));
        }
      }
      expect(MentiVisualCatalog.options.length, 115);
      for (final family in ['boy', 'girl', 'neutral']) {
        for (final age in ['young', 'adult', 'veteran']) {
          final p = MentiIdentityProfile(
            visual: MentiVisualProfile({'family': family, 'age': age}),
          );
          for (final sprite in MentiPremiumComposition.sprites(p)) {
            expect(MentiPremiumAtlas.rects, contains(sprite));
          }
        }
      }
    },
  );
  testWidgets(
    'every compatible option changes rendered pixels for all nine identities',
    (tester) async {
      tester.view.physicalSize = const Size(220, 280);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final boundaryKey = GlobalKey();
      var profile = MentiIdentityProfile();
      String? reaction;
      late StateSetter update;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                update = setState;
                return RepaintBoundary(
                  key: boundaryKey,
                  child: MentiAvatarRenderer(
                    profile: profile,
                    reaction: reaction,
                    size: 200,
                  ),
                );
              },
            ),
          ),
        ),
      );
      await tester.runAsync(() async {
        final context = tester.element(find.byType(Scaffold));
        for (final path in MentiPremiumComposition.assets) {
          await precacheImage(AssetImage(path), context);
        }
      });
      await tester.pumpAndSettle();
      for (final family in ['boy', 'girl', 'neutral']) {
        for (final age in ['young', 'adult', 'veteran']) {
          final hashes = <String, Set<int>>{};
          final counts = <String, int>{};
          final base = MentiIdentityProfile(
            visual: MentiVisualProfile({
              'family': family,
              'age': age,
              'hair': '$family-crop',
              'headwear': 'none',
            }),
          );
          for (final option in MentiVisualCatalog.options.where(
            (o) => o.field != 'hair' || o.id.startsWith('$family-'),
          )) {
            update(() {
              profile = MentiPreviewRenderer.previewProfile(base, option);
              reaction = option.field == 'reaction' ? option.id : null;
            });
            await tester.pumpAndSettle();
            expect(
              tester.takeException(),
              isNull,
              reason: '$family/$age/${option.rewardId}',
            );
            final hash = await tester.runAsync(() async {
              final boundary =
                  boundaryKey.currentContext!.findRenderObject()!
                      as RenderRepaintBoundary;
              final image = await boundary.toImage(pixelRatio: .6);
              final data = await image.toByteData(
                format: ui.ImageByteFormat.rawRgba,
              );
              image.dispose();
              var value = 2166136261;
              for (final byte in data!.buffer.asUint8List()) {
                value = ((value ^ byte) * 16777619) & 0xffffffff;
              }
              return value;
            });
            hashes.putIfAbsent(option.field, () => {}).add(hash!);
            counts.update(option.field, (n) => n + 1, ifAbsent: () => 1);
          }
          for (final field in counts.keys) {
            expect(
              hashes[field]!.length,
              counts[field],
              reason: '$family/$age: each $field option must visibly differ',
            );
          }
        }
      }
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    },
  );
  testWidgets(
    'color accents preserve alpha and head equipment keeps the pupils visible',
    (tester) async {
      tester.view.physicalSize = const Size(220, 280);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final captureKey = GlobalKey();
      late StateSetter update;
      bool spriteOnly = true;
      Color? tint;
      String headwear = 'none';
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                update = setState;
                return RepaintBoundary(
                  key: captureKey,
                  child: SizedBox(
                    width: 200,
                    height: 250,
                    child: spriteOnly
                        ? MentiPremiumSprite(
                            sprite: 'outfits/basic',
                            color: tint,
                          )
                        : MentiAvatarRenderer(
                            size: 200,
                            profile: MentiIdentityProfile(
                              visual: MentiVisualProfile({
                                'headwear': headwear,
                              }),
                            ),
                          ),
                  ),
                );
              },
            ),
          ),
        ),
      );
      await tester.runAsync(() async {
        final context = tester.element(find.byType(Scaffold));
        for (final path in MentiPremiumComposition.assets) {
          await precacheImage(AssetImage(path), context);
        }
      });
      Future<List<int>> pixels() async {
        await tester.pumpAndSettle();
        return (await tester.runAsync(() async {
          final boundary =
              captureKey.currentContext!.findRenderObject()!
                  as RenderRepaintBoundary;
          final image = await boundary.toImage();
          final bytes = await image.toByteData(
            format: ui.ImageByteFormat.rawRgba,
          );
          image.dispose();
          return bytes!.buffer.asUint8List();
        }))!;
      }

      final plain = await pixels();
      update(() => tint = const Color(0xFFB9EAD8));
      final colored = await pixels();
      expect(colored.length, plain.length);
      for (var i = 3; i < plain.length; i += 4) {
        expect(colored[i], closeTo(plain[i], 1), reason: 'alpha byte $i');
      }
      update(() => spriteOnly = false);
      final uncovered = await pixels();
      for (final equipment in ['headphones', 'hood']) {
        update(() => headwear = equipment);
        final equipped = await pixels();
        final eyeRect=MentiReferenceRig.of('boy','young').register(
          MentiReferenceRig.of('boy','young').eyes);
        for (final xCenter in [eyeRect.left+eyeRect.width*.25,eyeRect.left+eyeRect.width*.75].map((x)=>(x*200/320).round())) {
          final cy=(eyeRect.center.dy*200/320).round();
          for (var y = cy-3; y < cy+3; y++) {
            for (var x = xCenter - 3; x < xCenter + 3; x++) {
              final offset = (y * 200 + x) * 4;
              expect(
                equipped.sublist(offset, offset + 4),
                uncovered.sublist(offset, offset + 4),
                reason: '$equipment must not paint over a pupil at $x,$y',
              );
            }
          }
        }
      }
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    },
  );
}
