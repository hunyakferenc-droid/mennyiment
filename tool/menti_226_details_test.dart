// Run explicitly with flutter test; uses an identical fixed camera on both commits.
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mennyiment/menti_identity/menti_identity.dart';
import 'package:mennyiment/menti_identity/menti_head_geometry.dart';
import 'package:mennyiment/menti_identity/menti_premium_renderer.dart';
import 'package:mennyiment/menti_identity/menti_reference_rig.dart';

void main() {
  testWidgets(
    'fixed-camera accessory material details, nine actual runtime rigs',
    (t) async {
      final output = Directory(
        Platform.environment['MENTI_DETAILS_DIR'] ??
            'docs/images/menti-2.2.6/details-after',
      );
      output.createSync(recursive: true);
      await t.runAsync(() async {
        final font = FontLoader('ProofSans')
          ..addFont(
            File('/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf')
                .readAsBytes()
                .then(ByteData.sublistView),
          );
        await font.load();
      });
      t.view.physicalSize = const Size(1152, 920);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.resetPhysicalSize);
      addTearDown(t.view.resetDevicePixelRatio);
      final key = GlobalKey();
      final manifest = <String, dynamic>{};
      for (final family in ['boy', 'girl', 'neutral']) {
        final tiles = <Widget>[];
        for (final r in MentiReferenceRig.all.where(
          (r) => r.family == family,
        )) {
          final h = MentiHeadGeometry(
            r,
            clean: true,
            hair: r.hairId,
            hairVisible: true,
          );
          for (final (name, outfit, glasses, neck) in [
            ('clear-frame', 'basic', 'round-glasses', 'none'),
            ('sun-frame', 'basic', 'sunglasses', 'none'),
            ('silk-bow', 'business', 'none', 'bow'),
            ('wool-scarf', 'cozy', 'none', 'scarf'),
          ]) {
            final p = MentiIdentityProfile(
              visual: MentiVisualProfile({
                'family': r.family,
                'age': r.age,
                'hair': r.hairId,
                'hairVisible': true,
                'headwear': 'none',
                'outfit': outfit,
                'glasses': glasses,
                'neck': neck,
                'aura': 'none',
              }),
            );
            final camera = neck == 'none'
                ? Rect.fromLTWH(
                    h.eyes.center.dx - 50,
                    h.eyes.center.dy - 34,
                    100,
                    91.6666667,
                  )
                : Rect.fromLTWH(
                    h.mouth.center.dx - 45,
                    h.mouth.bottom - 4,
                    90,
                    82.5,
                  );
            final title = '${r.family}/${r.age}/$name';
            manifest[title] = {
              'profile': p.toJson(),
              'camera': [camera.left, camera.top, camera.width, camera.height],
            };
            final scale = 288 / camera.width;
            tiles.add(
              SizedBox(
                width: 288,
                child: Column(
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontFamily: 'ProofSans',
                        fontSize: 12,
                      ),
                    ),
                    SizedBox(
                      width: 288,
                      height: 264,
                      child: ClipRect(
                        child: OverflowBox(
                          alignment: Alignment.topLeft,
                          minWidth: 0,
                          minHeight: 0,
                          maxWidth: double.infinity,
                          maxHeight: double.infinity,
                          child: Transform.translate(
                            offset: Offset(
                              -camera.left * scale,
                              -camera.top * scale,
                            ),
                            child: SizedBox(
                              width: 320 * scale,
                              height: 400 * scale,
                              child: MentiPremiumComposition(
                                profile: p,
                                showBackground: false,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
        }
        await t.pumpWidget(
          MaterialApp(
            home: Scaffold(
              backgroundColor: const Color(0xff302832),
              body: RepaintBoundary(
                key: key,
                child: Column(
                  children: [
                    for (var row = 0; row < 3; row++)
                      Row(children: tiles.skip(row * 4).take(4).toList()),
                  ],
                ),
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
        await t.runAsync(() async {
          final image =
              await (key.currentContext!.findRenderObject()
                      as RenderRepaintBoundary)
                  .toImage();
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          File('${output.path}/$family-details.png')
              .writeAsBytesSync(bytes!.buffer.asUint8List());
          image.dispose();
        });
      }
      File(
        '${output.path}/manifest.json',
      ).writeAsStringSync(const JsonEncoder.withIndent('  ').convert(manifest));
      await t.pumpWidget(const SizedBox.shrink());
    },
  );
}
