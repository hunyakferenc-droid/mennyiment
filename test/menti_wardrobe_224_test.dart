import 'package:flutter_test/flutter_test.dart';
import 'package:mennyiment/menti_identity/menti_wardrobe_geometry.dart';
import 'package:mennyiment/menti_identity/menti_head_geometry.dart';
import 'package:mennyiment/menti_identity/menti_reference_rig.dart';
import 'package:mennyiment/menti_identity/menti_premium_atlas.dart';
import 'package:mennyiment/menti_identity/menti_visual_catalog.dart';

void main() {
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
