// Real Flutter artwork rendered on light/dark inspection plates, not an app screen.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mennyiment/menti_complete_looks.dart';
import 'package:mennyiment/l10n/generated/app_localizations.dart';

void main() {
  testWidgets(
    'Capture the three complete PNGs at common scale on light and dark plates',
    (tester) async {
      tester.view.physicalSize = const Size(780, 720);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final key = GlobalKey();
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('hu'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: Scaffold(
            body: RepaintBoundary(
              key: key,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final color in [Colors.white, const Color(0xFF21182B)])
                    ColoredBox(
                      color: color,
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            for (final look in CompleteLook.all)
                              CompleteLookArtwork(
                                look: look,
                                size: 250,
                                background: false,
                              ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.runAsync(() async {
        final context = tester.element(find.byKey(key));
        for (final look in CompleteLook.all) {
          final width =
              (look.sourceSize.width * (250 * 4 / 3 * .88 / look.bounds.height))
                  .ceil();
          await precacheImage(
            ResizeImage(AssetImage(look.asset), width: width),
            context,
          );
        }
        await Future<void>.delayed(const Duration(milliseconds: 200));
      });
      await tester.pumpAndSettle();
      for (final image in tester.widgetList<RawImage>(find.byType(RawImage))) {
        expect(image.image, isNotNull);
      }
      final target = Platform.environment['MENTI_CAPTURE_OUTPUT'];
      if (target != null) {
        await tester.runAsync(() async {
          final boundary =
              key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
          final image = await boundary.toImage(pixelRatio: 1);
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          File(target).writeAsBytesSync(bytes!.buffer.asUint8List());
          image.dispose();
        });
      }
      expect(tester.takeException(), isNull);
    },
  );
}
