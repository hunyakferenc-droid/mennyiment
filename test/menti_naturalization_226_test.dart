import 'dart:convert';

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

  test('cloth source aspect and collar safety hold for every rig and garment', () {
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
            expect(target.top, greaterThan(h.mouth.bottom));
            expect(target.bottom, lessThan(w.waist.top));
            expect(a.neckBounds.contains(target.topLeft), isTrue);
            expect(a.neckBounds.contains(target.bottomRight), isTrue);
          }
        }
        if (o.id != 'basic') {
          // The revealed inner hole is fully backed by original skin material.
          final g = w.garment, opening = w.collarOpening;
          final sample = Offset(
            opening.center.dx,
            opening.top + opening.height * .22,
          );
          final normalized = Offset(
            (sample.dx - g.left) / g.width,
            (sample.dy - g.top) / g.height,
          );
          expect(
            w.garmentMask
                .transform(
                  Matrix4.diagonal3Values(g.width, g.height, 1).storage,
                )
                .contains(
                  Offset(normalized.dx * g.width, normalized.dy * g.height),
                ),
            isFalse,
            reason:
                '${r.family}/${r.age}/${o.id}: $normalized, ${w.garmentMask.fillType}',
          );
          expect(w.neckBridge.contains(sample), isTrue);
          expect(w.garmentMask.contains(const Offset(.25, .25)), isTrue);
        }
      }
    }
  });

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
}
