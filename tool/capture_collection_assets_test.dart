// Technical captures of the real Flutter renderer; never edits source PNGs.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mennyiment/menti_complete_looks.dart';
import 'package:mennyiment/l10n/generated/app_localizations.dart';

void main() {
  testWidgets(
    'Render bounded real thumbnails and original/light/dark comparison sheets',
    (tester) async {
      final font = FontLoader('Roboto')
        ..addFont(rootBundle.load('assets/fonts/roboto/Roboto-Regular.ttf'));
      await font.load();
      tester.view.physicalSize = const Size(810, 2500);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      Future<void> capture(
        Widget child,
        String path,
        List<ImageProvider> images,
      ) async {
        final key = GlobalKey();
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData(fontFamily: 'Roboto'),
            locale: const Locale('hu'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: Scaffold(
              body: Align(
                alignment: Alignment.topLeft,
                child: RepaintBoundary(key: key, child: child),
              ),
            ),
          ),
        );
        await tester.runAsync(() async {
          final context = tester.element(find.byKey(key));
          for (final image in [
            ...images,
            ...tester.widgetList<Image>(find.byType(Image)).map((w) => w.image),
          ]) {
            await precacheImage(image, context);
          }
          await Future<void>.delayed(const Duration(milliseconds: 200));
        });
        await tester.pumpAndSettle();
        for (final image in tester.widgetList<RawImage>(
          find.byType(RawImage),
        )) {
          expect(image.image, isNotNull);
        }
        await tester.runAsync(() async {
          final boundary =
              key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
          final image = await boundary.toImage();
          final data = await image.toByteData(format: ui.ImageByteFormat.png);
          File(path).parent.createSync(recursive: true);
          File(path).writeAsBytesSync(data!.buffer.asUint8List());
          image.dispose();
        });
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
        PaintingBinding.instance.imageCache.clear();
      }

      for (final look in CompleteLook.all) {
        await capture(
          CompleteLookArtwork(look: look, size: 360),
          look.thumbnail!,
          [AssetImage(look.asset)],
        );
      }
      final target = Platform.environment['MENTI_COLLECTION_EVIDENCE'];
      if (target == null) return;
      const refs = {
        'base': 'alap',
        'party': 'buli',
        'festival': 'fesztival',
        'sport': 'sport',
        'business': 'uzleti',
        'legendary': 'legendas',
      };
      for (final family in ['boy', 'girl', 'neutral']) {
        final looks = CompleteLook.all
            .where((l) => l.family == family)
            .toList();
        final directory = {
          'boy': 'fiu',
          'girl': 'lany',
          'neutral': 'semleges',
        }[family];
        String original(CompleteLook l) =>
            'docs/images/menti-complete-looks/originals/$directory/${refs[l.style]}.png';
        await capture(
          SizedBox(
            width: 810,
            child: ColoredBox(
              color: Colors.white,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Eredeti referencia • Flutter sötét felületen • Flutter világos felületen',
                  ),
                  for (final look in looks)
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${look.reference} · ${look.id} · ${look.minXp == 0 ? "ingyenes" : "200 XP"}',
                        ),
                        Row(
                          children: [
                            SizedBox(
                              width: 270,
                              height: 360,
                              child: Image.memory(
                                File(original(look)).readAsBytesSync(),
                                fit: BoxFit.contain,
                              ),
                            ),
                            ColoredBox(
                              color: const Color(0xFF21182B),
                              child: CompleteLookArtwork(look: look, size: 270),
                            ),
                            CompleteLookArtwork(look: look, size: 270),
                          ],
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
          '$target/comparison-$family.png',
          [
            for (final look in looks) ...[
              AssetImage(look.asset),
              MemoryImage(File(original(look)).readAsBytesSync()),
            ],
          ],
        );
      }
    },
  );
}
