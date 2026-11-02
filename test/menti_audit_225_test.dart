import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mennyiment/menti_identity/menti_identity.dart';
import 'package:mennyiment/menti_identity/menti_avatar_renderer.dart';
import 'package:mennyiment/menti_identity/menti_premium_renderer.dart';
import 'package:mennyiment/menti_identity/menti_reference_rig.dart';
import 'package:mennyiment/menti_identity/menti_visual_catalog.dart';

void main() {
  testWidgets(
    '927 compatible options, 180 outfits and 18 complete identities actual runtime audit',
    (t) async {
      if (Platform.environment['MENTI_AUDIT'] != '1') return;
      final dir =
          'docs/images/menti-2.2.5/${Platform.environment['MENTI_STAGE'] ?? 'after'}';
      Directory(dir).createSync(recursive: true);
      await t.runAsync(() async {
      final loader = FontLoader('ProofSans')
        ..addFont(
          File('/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf')
              .readAsBytes()
              .then(ByteData.sublistView),
        );
      await loader.load();
      });
      t.view.physicalSize = const Size(1440, 2200);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.resetPhysicalSize);
      addTearDown(t.view.resetDevicePixelRatio);
      final key = GlobalKey();
      final manifest = <String, dynamic>{};
      Widget label(String s) => Text(
        s,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontFamily: 'ProofSans',
          fontSize: 12,
          color: Colors.white,
        ),
      );
      Future<void> capture(String name, List<Widget> tiles, int cols) async {
        await t.pumpWidget(
          MaterialApp(
            home: Scaffold(
              backgroundColor: const Color(0xff171020),
              body: RepaintBoundary(
                key: key,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    label(name),
                    for (var row = 0; row < (tiles.length / cols).ceil(); row++)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: tiles.skip(row * cols).take(cols).toList(),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
        await t.runAsync(() async {
          for (final a in MentiPremiumComposition.assets) {
            await precacheImage(AssetImage(a), key.currentContext!);
          }
        });
        await t.pumpAndSettle();
        expect(t.takeException(), isNull, reason: name);
        await t.runAsync(() async {
          final im =
              await (key.currentContext!.findRenderObject()
                      as RenderRepaintBoundary)
                  .toImage();
          final d = await im.toByteData(format: ui.ImageByteFormat.png);
          File('$dir/$name.png').writeAsBytesSync(d!.buffer.asUint8List());
          im.dispose();
        });
      }

      final combos = <Widget>[];
      for (final r in MentiReferenceRig.all) {
        final base = MentiIdentityProfile(
          visual: MentiVisualProfile({
            'family': r.family,
            'age': r.age,
            'hair': r.hairId,
            'hairVisible': r.family == 'girl',
          }),
        );
        final options = MentiVisualCatalog.options
            .where((o) => o.field != 'hair' || o.id.startsWith('${r.family}-'))
            .toList();
        manifest['${r.family}-${r.age}'] = {
          'base': base.toJson(),
          'options': options.map((o) => '${o.field}:${o.id}').toList(),
        };
        await capture('${r.family}-${r.age}-options', [
          for (final o in options)
            SizedBox(
              width: 144,
              child: Column(
                children: [
                  label('${o.field}:${o.id}'),
                  MentiPreviewRenderer(profile: base, option: o, size: 128),
                ],
              ),
            ),
        ], 10);
        await capture('${r.family}-${r.age}-outfits', [
          for (final o in MentiVisualCatalog.forField('outfit'))
            SizedBox(
              width: 288,
              child: Column(
                children: [
                  label('${r.family}/${r.age}/${o.id}'),
                  MentiAvatarRenderer(
                    profile: MentiPreviewRenderer.previewProfile(base, o),
                    size: 288,
                  ),
                ],
              ),
            ),
        ], 5);
        for (var i = 0; i < 2; i++) {
          final values = {
            'outfit': i == 0 ? 'business' : 'legendary-alt',
            'glasses': i == 0 ? 'round-glasses' : 'sunglasses',
            'neck': i == 0 ? 'chain' : 'scarf',
            'headwear': i == 0 ? 'crown-cap' : 'hood',
            'held': i == 0 ? 'notebook' : 'flower',
            'face': i == 0 ? 'confident' : 'playful',
            'eyes': i == 0 ? 'sharp' : 'wide',
          };
          final p = base.copyWith(
            visual: base.visual.withValues(values).withHairVisible(true),
          );
          manifest['${r.family}-${r.age}-combo$i'] = p.toJson();
          combos.add(
            SizedBox(
              width: 288,
              child: Column(
                children: [
                  label('${r.family}/${r.age}/combo$i'),
                  MentiAvatarRenderer(profile: p, size: 288),
                ],
              ),
            ),
          );
        }
      }
      await capture('complete-combinations', combos, 5);
      File(
        '$dir/manifest.json',
      ).writeAsStringSync(const JsonEncoder.withIndent('  ').convert(manifest));
      await t.pumpWidget(const SizedBox.shrink());
    },
  );
}
