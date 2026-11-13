import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mennyiment/l10n/generated/app_localizations.dart';
import 'package:mennyiment/menti_identity/menti_identity.dart';
import 'package:mennyiment/menti_identity/menti_avatar_renderer.dart';
import 'package:mennyiment/menti_identity/menti_premium_renderer.dart';
import 'package:mennyiment/menti_identity/menti_reference_rig.dart';
import 'package:mennyiment/menti_identity/menti_head_geometry.dart';

void main() {
  for (final rig in MentiReferenceRig.all) {
    testWidgets(
      '${rig.family}/${rig.age}: outfit transitions preserve the exact visible eyes without reopening',
      (t) async {
        t.view.physicalSize = const Size(200, 250);
        t.view.devicePixelRatio = 1;
        addTearDown(t.view.resetPhysicalSize);
        addTearDown(t.view.resetDevicePixelRatio);
        final key = GlobalKey();
        late StateSetter change;
        var profile = MentiIdentityProfile(
          visual: MentiVisualProfile({
            'family': rig.family,
            'age': rig.age,
            'hair': '${rig.family}-crop',
            'outfit': 'basic-alt',
          }),
        );
        await t.pumpWidget(
          MaterialApp(
            locale: const Locale('en'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: StatefulBuilder(
                builder: (context, set) {
                  change = set;
                  return RepaintBoundary(
                    key: key,
                    child: MentiAvatarRenderer(profile: profile, size: 200),
                  );
                },
              ),
            ),
          ),
        );
        await t.runAsync(() async {
          final context = key.currentContext!;
          for (final asset in MentiPremiumComposition.assets) {
            await precacheImage(AssetImage(asset), context);
          }
        });
        await t.pumpAndSettle();
        final g = MentiHeadGeometry(
          rig,
          clean: true,
          hair: '${rig.family}-crop',
          hairVisible: true,
        );
        final sample = g.eyes.deflate(2);
        Future<List<int>> eyes() async {
          late Uint8List rgba;
          await t.runAsync(() async {
            final image =
                await (key.currentContext!.findRenderObject()!
                        as RenderRepaintBoundary)
                    .toImage();
            final b = await image.toByteData(
              format: ui.ImageByteFormat.rawRgba,
            );
            rgba = b!.buffer.asUint8List();
            image.dispose();
          });
          final result = <int>[];
          for (
            var y = (sample.top * 200 / 320).ceil();
            y < (sample.bottom * 200 / 320).floor();
            y++
          )
            for (
              var x = (sample.left * 200 / 320).ceil();
              x < (sample.right * 200 / 320).floor();
              x++
            ) {
              final n = (y * 200 + x) * 4;
              result.addAll(rgba.sublist(n, n + 4));
            }
          return result;
        }

        final original = await eyes();
        for (final outfit in [
          'party',
          'party-alt',
          'sport',
          'sport-alt',
          'business',
          'creative-alt',
          'basic-alt',
        ]) {
          change(
            () => profile = profile.copyWith(
              visual: profile.visual.withValues({'outfit': outfit}),
            ),
          );
          await t.pumpAndSettle();
          expect(await eyes(), original, reason: outfit);
          expect(t.takeException(), isNull);
        }
        await t.pumpWidget(const SizedBox.shrink());
      },
    );
  }
}
