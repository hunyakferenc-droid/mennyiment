import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:mennyiment/menti_identity/menti_premium_renderer.dart';

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
      equals(MentiAccessoryRig.forProfile(h, w, sparse).collar.width),
    );
    final future = sparse.withValues({
      'glasses': 'future-frame',
      'held': 'future-object',
    });
    expect(MentiAccessoryRig.forProfile(h, w, future).compact, isFalse);
    expect(future.value('glasses'), 'future-frame');
  });
  testWidgets(
    'bow replaces the built-in business tie while preserving all pixels outside shirt and collar',
    (t) async {
      t.view.physicalSize = const Size(320, 400);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.resetPhysicalSize);
      addTearDown(t.view.resetDevicePixelRatio);
      final key = GlobalKey();
      late StateSetter update;
      var p = MentiIdentityProfile();
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
                    child: MentiPremiumComposition(profile: p),
                  ),
                );
              },
            ),
          ),
        ),
      );
      await t.runAsync(() async {
        for (final path in MentiPremiumComposition.assets) {
          await precacheImage(AssetImage(path), key.currentContext!);
        }
      });
      Future<List<int>> pixels() async {
        await t.pumpAndSettle();
        expect(t.takeException(), isNull);
        return (await t.runAsync(() async {
          final im =
              await (key.currentContext!.findRenderObject()
                      as RenderRepaintBoundary)
                  .toImage();
          final d = await im.toByteData(format: ui.ImageByteFormat.rawRgba);
          im.dispose();
          return d!.buffer.asUint8List().toList();
        }))!;
      }

      for (final r in MentiReferenceRig.all) {
        final visual = MentiVisualProfile({
          'family': r.family,
          'age': r.age,
          'hairVisible': false,
          'outfit': 'business',
          'headwear': 'none',
          'neck': 'none',
        });
        update(() => p = MentiIdentityProfile(visual: visual));
        final before = await pixels();
        update(
          () => p = MentiIdentityProfile(
            visual: visual.withValues({'neck': 'bow'}),
          ),
        );
        final after = await pixels();
        final h = MentiHeadGeometry(
          r,
          clean: true,
          hair: r.hairId,
          hairVisible: false,
        );
        final w = MentiWardrobeGeometry(h, 'business');
        final g = w.garment;
        final shirt = Rect.fromLTWH(
          g.left + g.width * .42,
          g.top + g.height * .07,
          g.width * .16,
          g.height * .26,
        );
        final collar = MentiAccessoryRig(h, w).neckBounds.inflate(3);
        var goldBefore = 0, goldAfter = 0;
        for (var y = 0; y < 400; y++) {
          for (var x = 0; x < 320; x++) {
            final pt = Offset(x + .5, y + .5), i = (y * 320 + x) * 4;
            bool gold(List<int> a) =>
                a[i] > 140 &&
                a[i] > a[i + 1] * 1.05 &&
                a[i + 1] > a[i + 2] * 1.35;
            if (shirt.deflate(2).contains(pt)) {
              if (gold(before)) goldBefore++;
              if (gold(after)) goldAfter++;
            }
            if (!shirt.inflate(3).contains(pt) && !collar.contains(pt)) {
              for (var c = 0; c < 4; c++) {
                if (before[i + c] != after[i + c]) {
                  fail(
                    'Unexpected change outside collar/shirt ${r.family}/${r.age} at $pt',
                  );
                }
              }
            }
          }
        }
        expect(goldBefore, greaterThan(5));
        expect(
          goldAfter,
          lessThan(goldBefore * .2),
          reason: 'Intrinsic tie removed ${r.family}/${r.age}',
        );
      }
      await t.pumpWidget(const SizedBox.shrink());
    },
  );
}
