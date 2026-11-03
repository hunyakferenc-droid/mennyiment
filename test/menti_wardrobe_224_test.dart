import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mennyiment/menti_identity/menti_wardrobe_geometry.dart';
import 'package:mennyiment/menti_identity/menti_head_geometry.dart';
import 'package:mennyiment/menti_identity/menti_reference_rig.dart';
import 'package:mennyiment/menti_identity/menti_premium_atlas.dart';
import 'package:mennyiment/menti_identity/menti_visual_catalog.dart';

void main() {
  test('fitted source viewBoxes keep natural aspect and place the grip on the hand across 180 outfits', () {
    for (final rig in MentiReferenceRig.all) {
      final head = MentiHeadGeometry(
        rig,
        clean: true,
        hair: rig.hairId,
        hairVisible: true,
      );
      final kinds = <String>{};
      for (final outfit in MentiVisualCatalog.forField('outfit')) {
        final w = MentiWardrobeGeometry(head, outfit.id);
        kinds.add(w.collarKind);
        for (final id in ['notebook', 'flower', 'spark-wand']) {
          final source = File(MentiWardrobeGeometry.heldAsset(id))
              .readAsStringSync();
          final box = RegExp(r'viewBox="0 0 (\d+) (\d+)"').firstMatch(source)!;
          final width = double.parse(box[1]!), height = double.parse(box[2]!);
          expect(
            w.held(id).width / w.held(id).height,
            closeTo(width / height, 1e-8),
          );
          expect(
            (w.heldGrip(id) - w.hand(id != 'notebook').center).distance,
            lessThan(1e-8),
          );
        }
      }
      expect(kinds, containsAll(['open', 'shirt', 'knit', 'stand', 'hooded']));
    }
  });
  test(
    'all 180 wardrobe fits retain material proportions, floor and safe collar',
    () {
      for (final r in MentiReferenceRig.all) {
        final head = MentiHeadGeometry(
          r,
          clean: true,
          hair: r.hairId,
          hairVisible: true,
        );
        for (final o in MentiVisualCatalog.forField('outfit')) {
          final w = MentiWardrobeGeometry(head, o.id);
          final source = MentiPremiumAtlas.rects['outfits/${o.id}']!;
          expect(
            w.garment.width / w.garment.height,
            closeTo(source.width / source.height, 1e-8),
          );
          expect(w.garment.bottom, closeTo(397, 1e-8));
          expect(w.garment.top, lessThanOrEqualTo(head.mouth.bottom + 9));
          expect(w.garment.left, greaterThan(0));
          expect(w.garment.right, lessThan(320));
          for (final id in ['notebook', 'flower', 'spark-wand']) {
            final held = w.held(id);
            expect(held.contains(w.hand(id != 'notebook').center), isTrue);
            expect(held.top, greaterThan(head.eyes.bottom));
          }
        }
      }
    },
  );
}
