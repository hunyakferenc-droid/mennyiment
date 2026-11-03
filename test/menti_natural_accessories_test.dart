import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mennyiment/menti_identity/menti_accessory_rig.dart';
import 'package:mennyiment/menti_identity/menti_head_geometry.dart';
import 'package:mennyiment/menti_identity/menti_wardrobe_geometry.dart';
import 'package:mennyiment/menti_identity/menti_reference_rig.dart';
import 'package:mennyiment/menti_identity/menti_identity.dart';
import 'package:mennyiment/menti_identity/menti_visual_catalog.dart';

void main() {
  test('sunglasses and collar ornaments stay subordinate to the measured face across all wardrobes', () {
    for (final r in MentiReferenceRig.all) {
      final h = MentiHeadGeometry(
        r,
        clean: true,
        hair: r.hairId,
        hairVisible: true,
      );
      for (final outfit in MentiVisualCatalog.forField('outfit')) {
        final w = MentiWardrobeGeometry(h, outfit.id);
        for (final compact in [false, true]) {
          final a = MentiAccessoryRig(h, w, compact: compact);
          for (final right in [false, true]) {
            final clear = a.lens(right),
                sun = a.lens(right, style: 'sunglasses');
            expect(
              sun.size.width * sun.size.height,
              lessThan(clear.size.width * clear.size.height * .85),
            );
            expect((sun.center - clear.center).distance, lessThan(1e-8));
            expect(sun.top, greaterThan(h.eyes.top - 1));
            final rim = a.rim(right, true, style: 'sunglasses');
            expect(rim.dx, greaterThan(0));
            expect(rim.dx, lessThan(320));
          }
          expect(a.collar.width, lessThanOrEqualTo(h.scalp.width * .33));
          expect(a.collar.height, lessThan(a.collar.width * .30));
          expect(a.collar.top, greaterThan(h.mouth.bottom));
          expect(a.neckBounds.bottom, lessThan(w.waist.bottom));
        }
      }
    }
  });
  test('ensemble refinement preserves all selections and ignores unavailable future accessories', () {
    final r = MentiReferenceRig.of('girl', 'adult');
    final h = MentiHeadGeometry(
      r,
      clean: true,
      hair: r.hairId,
      hairVisible: true,
    );
    final w = MentiWardrobeGeometry(h, 'business');
    final p = MentiVisualProfile({
      'family': 'girl',
      'headwear': 'crown-cap',
      'neck': 'scarf',
      'glasses': 'sunglasses',
      'held': 'flower',
      'future': 42,
    });
    final before = jsonEncode(p.toJson());
    final fitted = MentiAccessoryRig.forProfile(h, w, p);
    expect(fitted.compact, isTrue);
    expect(jsonEncode(p.toJson()), before);
    final sparse = p.withValues({'glasses': 'none', 'held': 'none'});
    expect(MentiAccessoryRig.forProfile(h, w, sparse).compact, isFalse);
    expect(
      fitted.collar.width,
      lessThan(MentiAccessoryRig.forProfile(h, w, sparse).collar.width),
    );
    final future = sparse.withValues({
      'glasses': 'future-frame',
      'held': 'future-object',
    });
    expect(MentiAccessoryRig.forProfile(h, w, future).compact, isFalse);
    expect(future.value('glasses'), 'future-frame');
  });
}
