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
import 'package:mennyiment/menti_identity/menti_visual_catalog.dart';

void main() {
  testWidgets('fixed-camera twenty necklines on all nine runtime rigs', (
    t,
  ) async {
    final layered = Platform.environment['MENTI_LAYERED'] == '1';
    final output = Directory(
      Platform.environment['MENTI_NECK_DIR'] ??
          'docs/images/menti-2.2.6-checkpoint/necks-after',
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
    t.view.physicalSize = const Size(1440, 1600);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
    final key = GlobalKey();
    final manifest = <String, dynamic>{};
    for (final rig in MentiReferenceRig.all) {
      final tiles = <Widget>[];
      for (final r in [rig]) {
        final h = MentiHeadGeometry(
          r,
          clean: true,
          hair: r.hairId,
          hairVisible: true,
        );
        for (final option in MentiVisualCatalog.forField('outfit')) {
          final index = MentiVisualCatalog.forField('outfit').indexOf(option);
          final name = option.id, outfit = option.id;
          const glasses = 'none', neck = 'none';
          final p = MentiIdentityProfile(
            visual: MentiVisualProfile({
              'family': r.family,
              'age': r.age,
              'hair': layered
                  ? '${r.family}-${['crop', 'waves', 'curls', 'braid', 'bob', 'crest'][index % 6]}'
                  : r.hairId,
              'hairVisible': true,
              'headwear': layered
                  ? [
                      'none',
                      'crown-cap',
                      'beanie',
                      'hood',
                      'headphones',
                      'sport-cap',
                      'beret',
                      'cowboy',
                    ][index % 8]
                  : 'none',
              'outfit': outfit,
              'glasses': layered
                  ? ['none', 'round-glasses', 'sunglasses'][index % 3]
                  : glasses,
              'neck': layered
                  ? ['none', 'chain', 'bow', 'scarf'][index % 4]
                  : neck,
              'held': layered
                  ? ['none', 'notebook', 'flower', 'spark-wand'][(index ~/ 2) %
                        4]
                  : 'none',
              'aura': 'none',
            }),
          );
          final camera = layered
              ? const Rect.fromLTWH(0, 0, 320, 400)
              : Rect.fromLTWH(
                  h.mouth.center.dx - 49,
                  h.mouth.bottom - 10,
                  98,
                  89.8333333,
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
                    height: layered ? 360 : 264,
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
                  for (var row = 0; row < 4; row++)
                    Row(children: tiles.skip(row * 5).take(5).toList()),
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
        File(
          '${output.path}/${rig.family}-${rig.age}-${layered ? 'layered' : 'necks'}.png',
        ).writeAsBytesSync(bytes!.buffer.asUint8List());
        image.dispose();
      });
    }
    File(
      '${output.path}/manifest.json',
    ).writeAsStringSync(const JsonEncoder.withIndent('  ').convert(manifest));
    await t.pumpWidget(const SizedBox.shrink());
  });
}
