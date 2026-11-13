import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mennyiment/menti_identity/menti_identity.dart';
import 'package:mennyiment/menti_identity/menti_reference_rig.dart';
import 'package:mennyiment/menti_identity/menti_head_geometry.dart';
import 'package:mennyiment/menti_identity/menti_wardrobe_geometry.dart';
import 'package:mennyiment/menti_identity/menti_accessory_rig.dart';
import 'package:mennyiment/menti_identity/menti_premium_renderer.dart';
import 'package:mennyiment/menti_identity/menti_visual_catalog.dart';

void main() {
  for (final r in MentiReferenceRig.all) {
    test(
      '${r.family}/${r.age}: adding a held item never resizes worn accessories in any outfit',
      () {
        final h = MentiHeadGeometry(
          r,
          clean: true,
          hair: r.hairId,
          hairVisible: true,
        );
        for (final outfit in MentiVisualCatalog.options.where(
          (o) => o.field == 'outfit',
        )) {
          final w = MentiWardrobeGeometry(h, outfit.id);
          final sparse = MentiVisualProfile({
            'family': r.family,
            'age': r.age,
            'outfit': outfit.id,
            'neck': 'scarf',
            'headwear': 'crown-cap',
            'future': {'keep': true},
          });
          final crowded = sparse.withValues({
            'held': 'flower',
            'glasses': 'sunglasses',
            'back': 'cape',
          });
          final before = jsonEncode(crowded.toJson());
          final a = MentiAccessoryRig.forProfile(h, w, sparse),
              b = MentiAccessoryRig.forProfile(h, w, crowded);
          expect(a.collar, b.collar, reason: outfit.id);
          for (final neck in ['scarf', 'bow', 'chain']) {
            expect(a.neckTarget(neck), b.neckTarget(neck), reason: outfit.id);
          }
          for (final side in [false, true]) {
            expect(
              a.lens(side, style: 'sunglasses'),
              b.lens(side, style: 'sunglasses'),
              reason: outfit.id,
            );
          }
          expect(jsonEncode(crowded.toJson()), before);
        }
      },
    );
    testWidgets(
      '${r.family}/${r.age}: tall hat stays entirely inside a 120px mobile figure',
      (t) async {
        const key = ValueKey('figure');
        await t.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: SizedBox(
                  key: key,
                  width: 120,
                  height: 150,
                  child: MentiPremiumComposition(
                    profile: MentiIdentityProfile(
                      visual: MentiVisualProfile({
                        'family': r.family,
                        'age': r.age,
                        'hair': '${r.family}-crop',
                        'headwear': 'party-hat',
                      }),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await t.pumpAndSettle();
        final cap = find.byWidgetPredicate(
          (w) => w is MentiPremiumSprite && w.sprite == 'headwear/party-hat',
        );
        final bounds = t.getRect(find.byKey(key)), hat = t.getRect(cap);
        expect(hat.top, greaterThanOrEqualTo(bounds.top - .01));
        expect(hat.left, greaterThanOrEqualTo(bounds.left - .01));
        expect(hat.right, lessThanOrEqualTo(bounds.right + .01));
        expect(hat.bottom, lessThanOrEqualTo(bounds.bottom + .01));
        expect(t.takeException(), isNull);
        await t.pumpWidget(const SizedBox.shrink());
      },
    );
  }
}
