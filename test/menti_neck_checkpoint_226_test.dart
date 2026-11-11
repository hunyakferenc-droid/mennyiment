import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mennyiment/menti_identity/menti_head_geometry.dart';
import 'package:mennyiment/menti_identity/menti_identity.dart';
import 'package:mennyiment/menti_identity/menti_premium_renderer.dart';
import 'package:mennyiment/menti_identity/menti_reference_rig.dart';
import 'package:mennyiment/menti_identity/menti_visual_catalog.dart';
import 'package:mennyiment/menti_identity/menti_wardrobe_geometry.dart';

void main() {
  testWidgets(
    '180 actual outfits retain the face and fill the inner collar with skin',
    (t) async {
      t.view.physicalSize = const Size(320, 400);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.resetPhysicalSize);
      addTearDown(t.view.resetDevicePixelRatio);
      final key = GlobalKey();
      Future<List<int>> render(Widget child) async {
        await t.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: RepaintBoundary(
                key: key,
                child: SizedBox(width: 320, height: 400, child: child),
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
        expect(t.takeException(), isNull);
        return (await t.runAsync(() async {
          final image =
              await (key.currentContext!.findRenderObject()
                      as RenderRepaintBoundary)
                  .toImage();
          final bytes = await image.toByteData(
            format: ui.ImageByteFormat.rawRgba,
          );
          image.dispose();
          return bytes!.buffer.asUint8List().toList();
        }))!;
      }

      for (final r in MentiReferenceRig.all) {
        final h = MentiHeadGeometry(
          r,
          clean: true,
          hair: r.hairId,
          hairVisible: false,
        );
        final original = await render(
          MentiReferencePlate(rig: r, hairless: true),
        );
        for (final o in MentiVisualCatalog.forField('outfit')) {
          final pixels = await render(
            MentiPremiumComposition(
              showBackground: false,
              profile: MentiIdentityProfile(
                visual: MentiVisualProfile({
                  'family': r.family,
                  'age': r.age,
                  'hairVisible': false,
                  'headwear': 'none',
                  'aura': 'none',
                  'outfit': o.id,
                }),
              ),
            ),
          );
          final label = '${r.family}/${r.age}/${o.id}';
          for (final rect in [
            h.leftEye.deflate(1),
            h.rightEye.deflate(1),
            h.mouth.deflate(1),
          ]) {
            for (var y = rect.top.ceil(); y < rect.bottom.floor(); y++) {
              for (var x = rect.left.ceil(); x < rect.right.floor(); x++) {
                final i = (y * 320 + x) * 4;
                for (var c = 0; c < 4; c++) {
                  if (pixels[i + c] != original[i + c]) {
                    fail(
                      '$label changes protected face at ($x,$y), channel $c',
                    );
                  }
                }
              }
            }
          }
          if (o.id == 'basic') continue;
          final wardrobe = MentiWardrobeGeometry(h, o.id);
          for (final right in [false, true]) {
            final wrist = wardrobe.cuff(right);
            var wristSkin = 0;
            for (var y = wrist.dy.floor() - 1; y <= wrist.dy.floor() + 1; y++) {
              for (
                var x = wrist.dx.floor() - 1;
                x <= wrist.dx.floor() + 1;
                x++
              ) {
                final i = (y * 320 + x) * 4;
                if (pixels[i] > 145 &&
                    pixels[i + 1] > 40 &&
                    pixels[i + 2] < 105) {
                  wristSkin++;
                }
              }
            }
            expect(
              wristSkin,
              greaterThan(0),
              reason: '$label/$right wrist is hidden by the empty cuff',
            );
            final hand = wardrobe.hand(right).inflate(1);
            bool skinAt(int x, int y) {
              if (!hand.contains(Offset(x + .5, y + .5))) return false;
              final i = (y * 320 + x) * 4;
              return pixels[i] > 145 &&
                  pixels[i + 1] > 40 &&
                  pixels[i + 2] < 105;
            }

            final queue = <(int, int)>[
              for (var y = wrist.dy.floor() - 1; y <= wrist.dy.floor() + 1; y++)
                for (
                  var x = wrist.dx.floor() - 1;
                  x <= wrist.dx.floor() + 1;
                  x++
                )
                  if (skinAt(x, y)) (x, y),
            ];
            final visited = <int>{};
            var connected = false;
            for (var cursor = 0; cursor < queue.length; cursor++) {
              final (x, y) = queue[cursor];
              if (!visited.add(y * 320 + x)) continue;
              if (y > wardrobe.hand(right).center.dy) {
                connected = true;
                break;
              }
              for (var dy = -1; dy <= 1; dy++) {
                for (var dx = -1; dx <= 1; dx++) {
                  if (skinAt(x + dx, y + dy) &&
                      !visited.contains((y + dy) * 320 + x + dx)) {
                    queue.add((x + dx, y + dy));
                  }
                }
              }
            }
            expect(
              connected,
              isTrue,
              reason: '$label/$right wrist is severed by the cuff rim',
            );
          }
          final opening = wardrobe.innerNeck;
          var skin = 0, count = 0;
          for (var y = opening.top.ceil(); y < opening.center.dy.ceil(); y++) {
            for (
              var x = (opening.center.dx - opening.width * .2).ceil();
              x < (opening.center.dx + opening.width * .2).floor();
              x++
            ) {
              final i = (y * 320 + x) * 4;
              count++;
              if (pixels[i] > 145 &&
                  pixels[i + 1] > 40 &&
                  pixels[i + 2] < 105 &&
                  pixels[i] > pixels[i + 1] &&
                  pixels[i + 3] > 240) {
                skin++;
              }
            }
          }
          expect(count, greaterThan(0), reason: label);
          expect(
            skin / count,
            greaterThan(.85),
            reason: '$label has an empty or cloth-filled inner neck',
          );
        }
      }
      await t.pumpWidget(const SizedBox.shrink());
    },
  );
}
