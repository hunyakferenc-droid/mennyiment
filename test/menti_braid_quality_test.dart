import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mennyiment/l10n/generated/app_localizations.dart';
import 'package:mennyiment/menti_identity/menti_identity.dart';
import 'package:mennyiment/menti_identity/menti_visual_catalog.dart';
import 'package:mennyiment/menti_identity/menti_avatar_renderer.dart';
import 'package:mennyiment/menti_identity/menti_premium_renderer.dart';
import 'package:mennyiment/menti_identity/menti_premium_atlas.dart';
import 'package:mennyiment/menti_identity/menti_reference_rig.dart';
import 'package:mennyiment/menti_identity/menti_head_geometry.dart';
import 'package:mennyiment/menti_identity/menti_braid_isolation.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('braid cleanup preserves the opaque hair and its antialias halo, excluding neighbouring atlas cores', () async {
    final bytes = await rootBundle.load('${MentiPremiumAtlas.root}hair.png');
    final codec = await ui.instantiateImageCodec(bytes.buffer.asUint8List());
    final frame = await codec.getNextFrame();
    final data = (await frame.image.toByteData(
      format: ui.ImageByteFormat.rawRgba,
    ))!.buffer.asUint8List();
    for (final name in MentiBraidIsolation.sourceSizes.keys) {
      final rect = MentiPremiumAtlas.rects['hair/$name']!,
          size = MentiBraidIsolation.sourceSizes[name]!;
      expect(rect.size, size);
      final w = size.width.toInt(), h = size.height.toInt();
      final alpha = Uint8List(w * h), seen = Uint8List(w * h);
      for (var y = 0; y < h; y++) {
        for (var x = 0; x < w; x++) {
          alpha[y * w + x] =
              data[((rect.top.toInt() + y) * frame.image.width +
                          rect.left.toInt() +
                          x) *
                      4 +
                  3];
        }
      }
      final cores = <List<int>>[];
      for (var first = 0; first < alpha.length; first++) {
        if (seen[first] != 0 || alpha[first] <= 16) continue;
        final pending = [first], component = <int>[];
        seen[first] = 1;
        while (pending.isNotEmpty) {
          final n = pending.removeLast();
          component.add(n);
          final x = n % w, y = n ~/ w;
          for (var dy = -1; dy <= 1; dy++) {
            for (var dx = -1; dx <= 1; dx++) {
              final xx = x + dx, yy = y + dy;
              if (xx < 0 || xx >= w || yy < 0 || yy >= h) continue;
              final q = yy * w + xx;
              if (seen[q] == 0 && alpha[q] > 16) {
                seen[q] = 1;
                pending.add(q);
              }
            }
          }
        }
        if (component.length >= 64) cores.add(component);
      }
      cores.sort((a, b) => b.length.compareTo(a.length));
      final labels = List.filled(w * h, 0), queue = <int>[];
      for (var c = 0; c < cores.length; c++) {
        cores[c].sort();
        for (final n in cores[c]) {
          labels[n] = c == 0 ? 1 : 2;
          queue.add(n);
        }
      }
      for (var i = 0; i < queue.length; i++) {
        final n = queue[i], x = n % w, y = n ~/ w;
        for (
          var yy = (y - 1).clamp(0, h - 1);
          yy <= (y + 1).clamp(0, h - 1);
          yy++
        ) {
          for (
            var xx = (x - 1).clamp(0, w - 1);
            xx <= (x + 1).clamp(0, w - 1);
            xx++
          ) {
            final q = yy * w + xx;
            if (alpha[q] > 0 && labels[q] == 0) {
              labels[q] = labels[n];
              queue.add(q);
            }
          }
        }
      }
      final main = {
        for (var n = 0; n < labels.length; n++)
          if (labels[n] == 1) n,
      };
      final mask = MentiBraidIsolation.exclusions(name);
      // The neutral tile includes the previous girl's plait tip, joined only
      // by a faint alpha halo. It must be excluded even though alpha>0 connects it.
      if (name == 'neutral-braid') {
        expect(mask.contains(Offset(220 / w, 12 / h)), isTrue);
      }
      expect(main.length, greaterThan(37000));
      var removedMain = 0, remainingFragments = 0;
      for (var n = 0; n < alpha.length; n++) {
        if (alpha[n] == 0) continue;
        final removed = mask.contains(
          Offset((n % w + .5) / w, (n ~/ w + .5) / h),
        );
        if (main.contains(n) && removed) removedMain++;
        if (!main.contains(n) && !removed) remainingFragments++;
      }
      expect(removedMain, 0, reason: name);
      expect(remainingFragments, 0, reason: name);
    }
    frame.image.dispose();
    codec.dispose();
  });
  for (final r in MentiReferenceRig.all) {
    testWidgets(
      '${r.family}/${r.age}: the braid is visibly below the jaw, not swallowed by the face guard',
      (t) async {
        t.view.physicalSize = const Size(200, 250);
        t.view.devicePixelRatio = 1;
        addTearDown(t.view.resetPhysicalSize);
        addTearDown(t.view.resetDevicePixelRatio);
        final key = GlobalKey();
        var visible = false;
        late StateSetter set;
        final p = MentiIdentityProfile(
          visual: MentiVisualProfile({
            'family': r.family,
            'age': r.age,
            'hair': '${r.family}-braid',
            'headwear': 'none',
          }),
        );
        await t.pumpWidget(
          MaterialApp(
            locale: const Locale('en'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: Scaffold(
              body: StatefulBuilder(
                builder: (context, change) {
                  set = change;
                  return RepaintBoundary(
                    key: key,
                    child: MentiAvatarRenderer(
                      profile: p.copyWith(
                        visual: p.visual.withHairVisible(visible),
                      ),
                      size: 200,
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
        await t.pumpAndSettle();
        Future<Uint8List> pixels() async {
          late Uint8List result;
          await t.runAsync(() async {
            final im =
                await (key.currentContext!.findRenderObject()!
                        as RenderRepaintBoundary)
                    .toImage();
            result = (await im.toByteData(format: ui.ImageByteFormat.rawRgba))!
                .buffer
                .asUint8List();
            im.dispose();
          });
          return result;
        }

        final before = await pixels();
        set(() => visible = true);
        await t.pumpAndSettle();
        final after = await pixels();
        final g = MentiHeadGeometry(
          r,
          clean: true,
          hair: '${r.family}-braid',
          hairVisible: true,
        );
        var changed = 0;
        for (
          var y = ((g.mouth.bottom + 10) * 200 / 320).ceil();
          y < ((g.mouth.bottom + 65) * 200 / 320).floor();
          y++
        ) {
          for (
            var x = (g.scalp.center.dx * 200 / 320).ceil();
            x < ((g.scalp.right + 35) * 200 / 320).floor();
            x++
          ) {
            final i = (y * 200 + x) * 4;
            if ((before[i] - after[i]).abs() +
                    (before[i + 1] - after[i + 1]).abs() +
                    (before[i + 2] - after[i + 2]).abs() >
                15) {
              changed++;
            }
          }
        }
        expect(changed, greaterThan(40));
        expect(t.takeException(), isNull);
        final target = g.materialHairTarget(
          MentiPremiumAtlas.rects['hair/${r.family}-braid']!,
        );
        final crop = MentiPreviewRenderer.cropFor(
          MentiVisualCatalog.forField('hair')
              .firstWhere((o) => o.id == '${r.family}-braid'),
          profile: p,
        );
        expect(crop.bottom, greaterThanOrEqualTo(target.bottom));
        expect(
          target.width / target.height,
          closeTo(
            MentiPremiumAtlas.rects['hair/${r.family}-braid']!.width /
                MentiPremiumAtlas.rects['hair/${r.family}-braid']!.height,
            1e-10,
          ),
        );
        await t.pumpWidget(const SizedBox.shrink());
      },
    );
  }
}
