import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mennyiment/menti_identity/menti_reference_rig.dart';
import 'package:mennyiment/menti_identity/menti_face_anchors.dart';
import 'package:mennyiment/menti_identity/menti_head_geometry.dart';
import 'package:mennyiment/menti_identity/menti_feature_mesh.dart';
import 'package:mennyiment/menti_identity/menti_identity.dart';
import 'package:mennyiment/menti_identity/menti_identity_controller.dart';
import 'package:mennyiment/menti_identity/menti_identity_store.dart';
import 'package:mennyiment/menti_identity/menti_avatar_renderer.dart';
import 'package:mennyiment/menti_identity/menti_premium_renderer.dart';
import 'package:mennyiment/menti_identity/menti_premium_atlas.dart';
import 'package:mennyiment/menti_identity/menti_visual_catalog.dart';

void main() {
  setUpAll(() async {
    if (Platform.environment['MENTI_CAPTURE'] == '1') {
      final file = File('/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf');
      if (await file.exists()) {
        await (FontLoader(
          'ProofSans',
        )..addFont(file.readAsBytes().then(ByteData.sublistView))).load();
      }
    }
  });
  test('all actual feature meshes preserve orientation, boundaries and bounded displacement', () {
    for (final rig in MentiReferenceRig.all) {
      for (final clean in [false, true]) {
        final a = MentiFaceAnchors
            .values['${rig.family}-${rig.age}${clean ? '-clean' : ''}']!;
        for (final name in ['leftEye', 'rightEye', 'mouth']) {
          final src = a[name]!, dest = rig.register(src);
          for (final scales in [
            (1.0, .48),
            (1.0, .85),
            (1.0, 1.055),
            (.96, .93),
            (.98, .93),
            (1.025, .98),
            (.96, .97),
            (.93, .87),
            (.98, .90),
          ]) {
            final mesh = MentiFeatureMesh(
              dest,
              src,
              sx: scales.$1,
              sy: scales.$2,
            );
            for (var i = 0; i < mesh.indices.length; i += 3) {
              final p = mesh.positions[mesh.indices[i]],
                  q = mesh.positions[mesh.indices[i + 1]],
                  r = mesh.positions[mesh.indices[i + 2]];
              expect(
                (q.dx - p.dx) * (r.dy - p.dy) - (q.dy - p.dy) * (r.dx - p.dx),
                greaterThan(0),
                reason:
                    'No folded or reversed triangle: ${rig.family}/${rig.age}/$clean/$name',
              );
            }
            for (var i = 0; i < mesh.positions.length; i++) {
              final p = mesh.positions[i];
              expect(
                p.dx,
                inInclusiveRange(dest.left - 1e-7, dest.right + 1e-7),
              );
              expect(
                p.dy,
                inInclusiveRange(dest.top - 1e-7, dest.bottom + 1e-7),
              );
              final x = i % 25, y = i ~/ 25;
              if (x == 0 || y == 0 || x == 24 || y == 24) {
                expect(
                  (p -
                          Offset(
                            dest.left + x * dest.width / 24,
                            dest.top + y * dest.height / 24,
                          ))
                      .distance,
                  lessThan(1e-7),
                );
              }
            }
          }
        }
      }
    }
  });
  test('cap fit is calibrated for every family, age and hairstyle, below old width and above eyes', () {
    for (final r in MentiReferenceRig.all) {
      for (final o in MentiVisualCatalog.forField('hair', family: r.family)) {
        for (final visible in [false, true]) {
          final g = MentiHeadGeometry(
            r,
            clean: true,
            hair: o.id,
            hairVisible: visible,
          );
          final source = MentiPremiumAtlas.rects['headwear/crown-cap']!;
          final cap = g.cap(source);
          expect(cap.bottom, lessThanOrEqualTo(g.eyes.top - 2 + 1e-6));
          expect(cap.width, lessThan(r.register(r.face).width + 20));
          expect(
            cap.width / cap.height,
            closeTo(source.width / source.height, 1e-8),
          );
          expect(cap.left, greaterThan(0));
          expect(cap.right, lessThan(320));
          expect(cap.top, greaterThanOrEqualTo(0));
        }
      }
    }
  });
  testWidgets(
    'cap centre follows source upper-scalp pixels, with and without hair',
    (t) async {
      await t.runAsync(() async {
        for (final family in ['boy', 'girl', 'neutral']) {
          final bytes = await rootBundle.load(
            'assets/images/menti_2_2/reference/$family-hairless.png',
          );
          final codec = await ui.instantiateImageCodec(
            bytes.buffer.asUint8List(),
          );
          final image = (await codec.getNextFrame()).image;
          final data = (await image.toByteData(
            format: ui.ImageByteFormat.rawRgba,
          ))!.buffer.asUint8List();
          for (final rig in MentiReferenceRig.all.where(
            (r) => r.family == family,
          )) {
            final skull =
                MentiFaceAnchors.values['$family-${rig.age}-clean']!['skull']!;
            var total = 0.0, count = 0;
            for (
              var y = (skull.top + skull.height * .15).round();
              y <= (skull.top + skull.height * .22).round();
              y++
            ) {
              int? left, right;
              for (var x = skull.left.round(); x < skull.right.round(); x++) {
                final i = (y * image.width + x) * 4;
                final r = data[i], g = data[i + 1], b = data[i + 2];
                if (data[i + 3] > 100 &&
                    r > 140 &&
                    g > 65 &&
                    r > g * 1.1 &&
                    g > b * 1.6) {
                  left ??= x;
                  right = x;
                }
              }
              if (left != null && right != null) {
                total += (left + right) / 2;
                count++;
              }
            }
            expect(count, greaterThan(8));
            final sourceCentre = total / count;
            final registered = rig
                .register(Rect.fromLTWH(sourceCentre, skull.top, 1, 1))
                .left;
            for (final visible in [false, true]) {
              for (final hair in MentiVisualCatalog.forField(
                'hair',
                family: family,
              )) {
                final g = MentiHeadGeometry(
                  rig,
                  clean: true,
                  hair: hair.id,
                  hairVisible: visible,
                );
                final cap = g.cap(
                  MentiPremiumAtlas.rects['headwear/crown-cap']!,
                );
                expect(
                  (cap.center.dx - registered).abs(),
                  lessThan(1),
                  reason: '$family/${rig.age}/$visible/${hair.id}',
                );
                expect(
                  cap.bottom,
                  greaterThan(g.scalp.top + g.scalp.height * .30),
                );
              }
            }
          }
          image.dispose();
          codec.dispose();
        }
      });
    },
  );
  test('old identities keep visible hair; clean toggle saves, reverts and preserves future fields', () async {
    final old = MentiIdentityDocument(
      profile: MentiIdentityProfile(
        visual: MentiVisualProfile({
          'family': 'girl',
          'hair': 'girl-braid',
          'future': 'keep',
        }),
      ),
      extras: {'unknown': 42},
    );
    SharedPreferences.setMockInitialValues({
      MentiIdentityStore.key: old.encode(),
      'mennyiment_menti_xp_v2': '{"xp":200,"days":[],"completed":[]}',
    });
    final c = MentiIdentityController();
    addTearDown(c.dispose);
    await c.load();
    expect(c.profile.visual.hairVisible, isTrue);
    expect(
      (await SharedPreferences.getInstance()).getString(MentiIdentityStore.key),
      old.encode(),
    );
    c.setHairVisible(false);
    expect(c.profile.visual.hairVisible, isTrue);
    expect(c.draft.profile.visual.value('hair'), 'girl-braid');
    c.revert();
    expect(c.draft.profile.visual.hairVisible, isTrue);
    c.setHairVisible(false);
    expect(await c.save(), isTrue);
    final reload = MentiIdentityController();
    addTearDown(reload.dispose);
    await reload.load();
    expect(reload.profile.visual.hairVisible, isFalse);
    expect(reload.profile.visual.toJson()['future'], 'keep');
    expect(reload.draft.toJson()['unknown'], 42);
    reload.choose(MentiVisualCatalog.resolve('hair', 'girl-curls'));
    expect(reload.draft.profile.visual.hairVisible, isTrue);
    reload.reset();
    expect(reload.draft.profile.visual.hairVisible, isFalse);
    final girl = MentiVisualCatalog.resolve('family', 'girl');
    final preview = MentiPreviewRenderer.previewProfile(
      reload.draft.profile,
      girl,
    );
    reload.choose(girl);
    expect(reload.draft.profile.visual.toJson(), preview.visual.toJson());
    expect(reload.draft.profile.visual.hairVisible, isTrue);
    expect(reload.draft.profile.visual.value('hair'), 'girl-waves');
    reload.setHairVisible(false);
    expect(await reload.save(), isTrue);
    final hidden = MentiIdentityController();
    addTearDown(hidden.dispose);
    await hidden.load();
    expect(hidden.profile.visual.hairVisible, isFalse);
    expect(hidden.profile.visual.value('family'), 'girl');
    expect(
      (await SharedPreferences.getInstance()).getString(
        'mennyiment_menti_xp_v2',
      ),
      '{"xp":200,"days":[],"completed":[]}',
    );
    expect(MentiVisualCatalog.options.length, 115);
  });
  testWidgets(
    'every family age hair face eye combination preserves all pixels outside feature supports',
    (t) async {
      t.view.physicalSize = const Size(200, 250);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.resetPhysicalSize);
      addTearDown(t.view.resetDevicePixelRatio);
      final key = GlobalKey();
      late StateSetter update;
      var profile = MentiIdentityProfile();
      await t.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, set) {
                update = set;
                return RepaintBoundary(
                  key: key,
                  child: SizedBox(
                    width: 200,
                    height: 250,
                    child: MentiPremiumComposition(profile: profile),
                  ),
                );
              },
            ),
          ),
        ),
      );
      await t.runAsync(() async {
        final ctx = t.element(find.byType(Scaffold));
        for (final a in MentiPremiumComposition.assets) {
          await precacheImage(AssetImage(a), ctx);
        }
      });
      Future<List<int>> pixels() async {
        await t.pumpAndSettle();
        expect(t.takeException(), isNull);
        return (await t.runAsync(() async {
          final im =
              await (key.currentContext!.findRenderObject()!
                      as RenderRepaintBoundary)
                  .toImage(pixelRatio: .5);
          final d = await im.toByteData(format: ui.ImageByteFormat.rawRgba);
          im.dispose();
          return d!.buffer.asUint8List().toList();
        }))!;
      }

      for (final rig in MentiReferenceRig.all) {
        final a = MentiFaceAnchors.values['${rig.family}-${rig.age}-clean']!;
        final supports = [
          for (final name in ['leftEye', 'rightEye', 'mouth'])
            rig.register(a[name]!.inflate(2)).inflate(3),
        ];
        final compare = <int>[];
        for (var y = 0; y < 125; y++) {
          for (var x = 0; x < 100; x++) {
            if (!supports.any(
              (r) => r.contains(Offset((x + .5) * 3.2, (y + .5) * 3.2)),
            )) {
              compare.add((y * 100 + x) * 4);
            }
          }
        }
        for (final hair in MentiVisualCatalog.forField(
          'hair',
          family: rig.family,
        )) {
          final values = <String, dynamic>{
            'family': rig.family,
            'age': rig.age,
            'hair': hair.id,
            'headwear': 'crown-cap',
          };
          update(
            () => profile = MentiIdentityProfile(
              visual: MentiVisualProfile(values),
            ),
          );
          final original = await pixels();
          for (final face in MentiVisualCatalog.forField('face')) {
            for (final eyes in MentiVisualCatalog.forField('eyes')) {
              update(
                () => profile = MentiIdentityProfile(
                  visual: MentiVisualProfile({
                    ...values,
                    'face': face.id,
                    'eyes': eyes.id,
                  }),
                ),
              );
              final actual = await pixels();
              for (final i in compare) {
                for (var c = 0; c < 4; c++) {
                  if (actual[i + c] != original[i + c]) {
                    fail(
                      'Changed head/body outside expression: ${rig.family}/${rig.age}/${hair.id}/${face.id}/${eyes.id}, byte ${i + c}',
                    );
                  }
                }
              }
            }
          }
        }
      }
      await t.pumpWidget(const SizedBox.shrink());
      await t.pump();
    },
  );
  testWidgets(
    '2.2.3 family defaults, caps, face and hair contact sheets use actual runtime',
    (t) async {
      t.view.physicalSize = const Size(1440, 2200);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.resetPhysicalSize);
      addTearDown(t.view.resetDevicePixelRatio);
      final key = GlobalKey();
      Widget label(String s) => Text(
        s,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontFamily: 'ProofSans',
          fontSize: 15,
          color: Colors.white,
        ),
      );
      MentiIdentityProfile p(
        MentiReferenceRig r, {
        bool? hair,
        String? hairId,
        String cap = 'crown-cap',
        String face = 'cheerful',
        String eyes = 'round',
      }) => MentiIdentityProfile(
        visual: MentiVisualProfile({
          'family': r.family,
          'age': r.age,
          'hair': hairId ?? r.hairId,
          'hairVisible': hair ?? r.family == 'girl',
          'headwear': cap,
          'face': face,
          'eyes': eyes,
        }),
      );
      Widget tile(MentiIdentityProfile p, String title, {double width = 280}) =>
          SizedBox(
            width: width,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                label(title),
                MentiAvatarRenderer(profile: p, size: width),
              ],
            ),
          );
      Future<void> capture(String name, Widget child) async {
        await t.pumpWidget(
          MaterialApp(
            home: Scaffold(
              backgroundColor: const Color(0xff171020),
              body: RepaintBoundary(key: key, child: child),
            ),
          ),
        );
        await t.runAsync(() async {
          final ctx = t.element(find.byType(Scaffold));
          for (final asset in MentiPremiumComposition.assets) {
            await precacheImage(AssetImage(asset), ctx);
          }
        });
        await t.pumpAndSettle();
        expect(t.takeException(), isNull, reason: name);
        if (Platform.environment['MENTI_CAPTURE'] == '1') {
          await t.runAsync(() async {
            final im =
                await (key.currentContext!.findRenderObject()!
                        as RenderRepaintBoundary)
                    .toImage();
            final data = await im.toByteData(format: ui.ImageByteFormat.png);
            File('docs/images/menti-2.2.3/$name.png')
                .writeAsBytesSync(data!.buffer.asUint8List());
            im.dispose();
          });
        }
      }

      await capture(
        'default-nine',
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            label('2.2.3 · family defaults · actual Flutter runtime'),
            for (final family in ['boy', 'girl', 'neutral'])
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (final r in MentiReferenceRig.all.where(
                    (r) => r.family == family,
                  ))
                    tile(p(r), '${r.family} / ${r.age}', width: 370),
                ],
              ),
          ],
        ),
      );
      for (final family in ['boy', 'girl', 'neutral']) {
        final rigs = MentiReferenceRig.all
            .where((r) => r.family == family)
            .toList();
        await capture(
          '$family-defaults',
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              label('$family · 2.2.3 defaults · actual Flutter runtime'),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (final r in rigs)
                    tile(p(r), '${r.family} / ${r.age}', width: 370),
                ],
              ),
            ],
          ),
        );
        await capture(
          '$family-cap-pairs',
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              label('$family · no cap / calibrated cap'),
              for (final r in rigs)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    tile(p(r, cap: 'none'), '${r.age} · no cap', width: 340),
                    tile(p(r), '${r.age} · cap', width: 340),
                  ],
                ),
            ],
          ),
        );
        await capture(
          '$family-hair-pairs',
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              label(
                '$family · hair off / hair on · same head and calibrated cap',
              ),
              for (final r in rigs)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    tile(p(r, hair: false), '${r.age} · hair off', width: 340),
                    tile(p(r, hair: true), '${r.age} · hair on', width: 340),
                  ],
                ),
            ],
          ),
        );
        await capture(
          '$family-hair',
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              label('$family · all six optional hairstyles / all ages'),
              for (final r in rigs)
                Row(
                  children: [
                    for (final o in MentiVisualCatalog.forField(
                      'hair',
                      family: family,
                    ))
                      tile(
                        p(r, hair: true, hairId: o.id),
                        '${r.age} / ${o.id}',
                        width: 240,
                      ),
                  ],
                ),
            ],
          ),
        );
        await capture(
          '$family-expressions',
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              label('$family · six bounded facial expressions / all ages'),
              for (final r in rigs)
                Row(
                  children: [
                    for (final o in MentiVisualCatalog.forField('face'))
                      tile(p(r, face: o.id), '${r.age} / ${o.id}', width: 240),
                  ],
                ),
            ],
          ),
        );
        await capture(
          '$family-eyes',
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              label('$family · four eye variants / all ages'),
              for (final r in rigs)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (final o in MentiVisualCatalog.forField('eyes'))
                      tile(p(r, eyes: o.id), '${r.age} / ${o.id}', width: 280),
                  ],
                ),
            ],
          ),
        );
      }
      await t.pumpWidget(const SizedBox.shrink());
      await t.pump();
    },
  );
}
