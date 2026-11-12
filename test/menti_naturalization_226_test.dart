import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mennyiment/menti_identity/menti_accessory_rig.dart';
import 'package:mennyiment/menti_identity/menti_head_geometry.dart';
import 'package:mennyiment/menti_identity/menti_identity.dart';
import 'package:mennyiment/menti_identity/menti_premium_renderer.dart';
import 'package:mennyiment/menti_identity/menti_reference_rig.dart';
import 'package:mennyiment/menti_identity/menti_visual_catalog.dart';
import 'package:mennyiment/menti_identity/menti_wardrobe_geometry.dart';

void main() {
  test(
    'all garment sleeves meet real wrists without changing hand anatomy',
    () {
      for (final r in MentiReferenceRig.all) {
        final h = MentiHeadGeometry(
          r,
          clean: true,
          hair: r.hairId,
          hairVisible: true,
        );
        for (final option in MentiVisualCatalog.forField('outfit')) {
          final w = MentiWardrobeGeometry(h, option.id);
          if (option.id == 'basic') continue;
          for (final right in [false, true]) {
            final hand = w.hand(right), wrist = w.sourceWrist(right);
            final mask = r.mask(right ? 'rightHand' : 'leftHand');
            final b = mask.getBounds();
            expect(
              mask.contains(
                Offset(
                  b.left + b.width * wrist.dx,
                  b.top + b.height * wrist.dy,
                ),
              ),
              isTrue,
            );
            expect(hand.width / hand.height, closeTo(b.width / b.height, 1e-8));
            final registeredWrist = Offset(
              hand.left + hand.width * wrist.dx,
              hand.top + hand.height * wrist.dy,
            );
            expect((registeredWrist - w.cuff(right)).distance, lessThan(1e-8));
            expect(
              hand.bottom,
              lessThan(w.shoes.top),
              reason: '${r.family}/${r.age}/${option.id}/$right',
            );
          }
        }
      }
    },
  );

  test(
    'cloth source aspect and collar safety hold for every rig and garment',
    () {
      for (final r in MentiReferenceRig.all) {
        final h = MentiHeadGeometry(
          r,
          clean: true,
          hair: r.hairId,
          hairVisible: true,
        );
        for (final o in MentiVisualCatalog.forField('outfit')) {
          final w = MentiWardrobeGeometry(h, o.id);
          for (final compact in [false, true]) {
            final a = MentiAccessoryRig(h, w, compact: compact);
            for (final (id, aspect) in [
              ('bow', 2015 / 737),
              ('scarf', 928 / 888),
            ]) {
              final target = a.neckTarget(id);
              expect(target.width / target.height, closeTo(aspect, 1e-8));
              expect(
                id == 'scarf' ? target.top + target.height * .42 : target.top,
                greaterThan(h.mouth.bottom),
              );
              expect(target.bottom, lessThan(w.waist.top));
              expect(a.neckBounds.contains(target.topLeft), isTrue);
              expect(a.neckBounds.contains(target.bottomRight), isTrue);
            }
          }
        }
      }
    },
  );

  testWidgets(
    'runtime uses detailed cloth and separate occluded temples without rewriting selection',
    (t) async {
      final p = MentiIdentityProfile(
        visual: MentiVisualProfile({
          'family': 'girl',
          'age': 'veteran',
          'outfit': 'business',
          'neck': 'bow',
          'glasses': 'sunglasses',
          'headwear': 'crown-cap',
          'hair': 'girl-bob',
          'future-field': 'preserved',
        }),
      );
      final before = jsonEncode(p.toJson());
      await t.pumpWidget(
        MaterialApp(
          home: SizedBox(
            width: 320,
            height: 400,
            child: MentiPremiumComposition(profile: p),
          ),
        ),
      );
      final context = t.element(find.byType(MentiPremiumComposition));
      await t.runAsync(() async {
        for (final asset in MentiPremiumComposition.assets) {
          await precacheImage(AssetImage(asset), context);
        }
      });
      await t.pumpAndSettle();
      expect(t.takeException(), isNull);
      expect(find.byType(MentiClothAccessory), findsOneWidget);
      final passes = t
          .widgetList<CustomPaint>(find.byType(CustomPaint))
          .map((w) => w.painter)
          .whereType<MentiFittedAccessories>()
          .where((p) => p.glasses != 'none')
          .map((p) => p.glassesPass)
          .toList();
      expect(passes, [MentiGlassesPass.temples, MentiGlassesPass.front]);
      expect(
        MentiPremiumComposition.layers(p),
        contains(MentiAccessoryRig.clothAssets['bow']),
      );
      expect(jsonEncode(p.toJson()), before);
      await t.pumpWidget(const SizedBox.shrink());
    },
  );
  testWidgets(
    'scarf wraps below the jaw without changing eyes or mouth in all nine rigs',
    (t) async {
      t.view.physicalSize = const Size(320, 400);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.resetPhysicalSize);
      addTearDown(t.view.resetDevicePixelRatio);
      final key = GlobalKey();
      var profile = MentiIdentityProfile();
      late StateSetter update;
      await t.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, set) {
                update = set;
                return RepaintBoundary(
                  key: key,
                  child: SizedBox(
                    width: 320,
                    height: 400,
                    child: MentiPremiumComposition(profile: profile),
                  ),
                );
              },
            ),
          ),
        ),
      );
      await t.runAsync(() async {
        for (final asset in MentiPremiumComposition.assets) {
          await precacheImage(AssetImage(asset), key.currentContext!);
        }
      });
      Future<List<int>> pixels() async {
        await t.pumpAndSettle();
        expect(t.takeException(), isNull);
        return (await t.runAsync(() async {
          final image =
              await (key.currentContext!.findRenderObject()
                      as RenderRepaintBoundary)
                  .toImage();
          final data = await image.toByteData(
            format: ui.ImageByteFormat.rawRgba,
          );
          image.dispose();
          return data!.buffer.asUint8List().toList();
        }))!;
      }

      for (final r in MentiReferenceRig.all) {
        final h = MentiHeadGeometry(
          r,
          clean: true,
          hair: r.hairId,
          hairVisible: false,
        );
        for (final outfit in ['basic', 'cozy']) {
          final visual = MentiVisualProfile({
            'family': r.family,
            'age': r.age,
            'hairVisible': false,
            'headwear': 'none',
            'outfit': outfit,
            'neck': 'none',
          });
          update(() => profile = MentiIdentityProfile(visual: visual));
          final before = await pixels();
          update(
            () => profile = MentiIdentityProfile(
              visual: visual.withValues({'neck': 'scarf'}),
            ),
          );
          final after = await pixels();
          final a = MentiAccessoryRig(h, MentiWardrobeGeometry(h, outfit));
          final protected = [
            h.leftEye.inflate(1),
            h.rightEye.inflate(1),
            h.mouth.inflate(1),
          ];
          var changedNeck = 0;
          for (var y = 0; y < 400; y++) {
            for (var x = 0; x < 320; x++) {
              final point = Offset(x + .5, y + .5), i = (y * 320 + x) * 4;
              final changed = List.generate(
                4,
                (channel) => before[i + channel] != after[i + channel],
              ).any((v) => v);
              if (changed && protected.any((rect) => rect.contains(point))) {
                fail(
                  'Scarf changed protected face ${r.family}/${r.age}/$outfit at $point',
                );
              }
              if (changed && a.neckBounds.contains(point)) changedNeck++;
            }
          }
          expect(
            changedNeck,
            greaterThan(15),
            reason: '${r.family}/${r.age}/$outfit scarf really rendered',
          );
        }
      }
      await t.pumpWidget(const SizedBox.shrink());
    },
  );
}
