import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mennyiment/menti_identity/menti_identity.dart';
import 'package:mennyiment/menti_identity/menti_premium_renderer.dart';
import 'package:mennyiment/menti_identity/menti_reference_rig.dart';

void main() {
  setUpAll(() async {
    if (Platform.environment['MENTI_CAPTURE'] == '1') {
      final font = File('/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf');
      if (await font.exists()) {
        await (FontLoader(
          'ProofSans',
        )..addFont(font.readAsBytes().then(ByteData.sublistView))).load();
      }
    }
  });
  test('all three approved age sheets are present as byte-identical runtime assets', () {
    final manifest = jsonDecode(
      File('test/fixtures/menti_reference_sources.json').readAsStringSync(),
    ) as Map;
    expect(MentiReferenceRig.all.length, 9);
    expect(
      MentiReferenceRig.all.map((r) => '${r.family}/${r.age}').toSet().length,
      9,
    );
    for (final entry in manifest.values) {
      expect(
        File(entry['asset']).readAsBytesSync(),
        File(entry['source']).readAsBytesSync(),
      );
    }
    for (final rig in MentiReferenceRig.all) {
      expect(rig.source.right, lessThanOrEqualTo(1942));
      expect(rig.register(rig.face).left, greaterThan(0));
      expect(rig.register(rig.face).right, lessThan(320));
      expect(MentiReferenceRig.assets, contains(rig.asset));
    }
  });
  testWidgets(
    'nine reference characters and actual 2.2 to 2.2.1 renderer comparison',
    (tester) async {
      tester.view.physicalSize = const Size(1440, 1680);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final capture = GlobalKey();
      MentiIdentityProfile profile(MentiReferenceRig r) => MentiIdentityProfile(
        visual: MentiVisualProfile({
          'family': r.family,
          'age': r.age,
          'hair': r.hairId,
          'headwear': 'none',
          'outfit': 'basic',
        }),
      );
      Future<void> show(String name, Widget content) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              backgroundColor: const Color(0xFF171020),
              body: RepaintBoundary(key: capture, child: content),
            ),
          ),
        );
        await tester.runAsync(() async {
          final ctx = tester.element(find.byType(Scaffold));
          for (final asset in MentiPremiumComposition.assets) {
            await precacheImage(AssetImage(asset), ctx);
          }
        });
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: name);
        if (Platform.environment['MENTI_CAPTURE'] == '1') {
          await tester.runAsync(() async {
            final im =
                await (capture.currentContext!.findRenderObject()!
                        as RenderRepaintBoundary)
                    .toImage();
            final bytes = await im.toByteData(format: ui.ImageByteFormat.png);
            File('docs/images/menti-2.2.1/$name.png')
                .writeAsBytesSync(bytes!.buffer.asUint8List());
            im.dispose();
          });
        }
      }

      Widget label(String text) => Text(
        text,
        style: const TextStyle(
          fontFamily: 'ProofSans',
          fontSize: 18,
          color: Colors.white,
        ),
      );
      Widget avatar(
        MentiReferenceRig r, {
        bool before = false,
        double width = 320,
      }) => Column(
        children: [
          label('${r.family} · ${r.age}'),
          SizedBox(
            width: width,
            height: width * 1.25,
            child: before
                ? MentiAtlasComposition(
                    profile: profile(r),
                    showBackground: false,
                  )
                : MentiPremiumComposition(
                    profile: profile(r),
                    showBackground: false,
                  ),
          ),
        ],
      );
      await show(
        'runtime-nine',
        Column(
          children: [
            label(
              '2.2.1 · Flutter runtime · original registered source plates',
            ),
            for (var row = 0; row < 3; row++)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var col = 0; col < 3; col++)
                    avatar(MentiReferenceRig.all[row * 3 + col], width: 390),
                ],
              ),
          ],
        ),
      );
      for (final family in ['boy', 'girl', 'neutral']) {
        await show(
          'runtime-$family',
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (final rig in MentiReferenceRig.all.where(
                (r) => r.family == family,
              ))
                avatar(rig, width: 460),
            ],
          ),
        );
      }
      await show(
        'runtime-before-after',
        Column(
          children: [
            label(
              'Actual Flutter render · 2.2 LEFT / 2.2.1 RIGHT · same profile IDs',
            ),
            for (final age in ['young', 'adult', 'veteran'])
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (final fam in ['boy', 'girl']) ...[
                    avatar(
                      MentiReferenceRig.of(fam, age),
                      before: true,
                      width: 330,
                    ),
                    avatar(MentiReferenceRig.of(fam, age), width: 330),
                  ],
                ],
              ),
          ],
        ),
      );
      await show(
        'runtime-face-comparison',
        Column(
          children: [
            label('Native family faces · Flutter runtime close-ups'),
            for (final age in ['young', 'adult', 'veteran'])
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  for (final fam in ['boy', 'girl', 'neutral'])
                    Column(
                      children: [
                        label('$fam · $age'),
                        SizedBox(
                          width: 400,
                          height: 420,
                          child: ClipRect(
                            child: OverflowBox(
                              alignment: Alignment.topLeft,
                              minWidth: 800,
                              maxWidth: 800,
                              minHeight: 1000,
                              maxHeight: 1000,
                              child: Transform.translate(
                                offset: const Offset(-200, 0),
                                child: SizedBox(
                                  width: 800,
                                  height: 1000,
                                  child: MentiPremiumComposition(
                                    profile: profile(
                                      MentiReferenceRig.of(fam, age),
                                    ),
                                    showBackground: false,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
          ],
        ),
      );
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    },
  );
}
