import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mennyiment/l10n/generated/app_localizations.dart';
import 'package:mennyiment/menti_identity/menti_avatar_renderer.dart';
import 'package:mennyiment/menti_identity/menti_identity.dart';

void main() {
  testWidgets('Menti brand classic and customized identity render consistently', (tester) async {
    await tester.binding.setSurfaceSize(const Size(640, 400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final classic = MentiIdentityProfile();
    final variant = MentiIdentityProfile(visual: MentiVisualProfile({
      'family': 'girl', 'age': 'veteran', 'hair': 'girl-braid', 'headwear': 'beanie',
      'outfit': 'cozy', 'style': 'cozy', 'neck': 'scarf', 'background': 'rose',
    }));
    await tester.pumpWidget(MaterialApp(locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: RepaintBoundary(key: const ValueKey('brand-golden'),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          MentiAvatarRenderer(profile: classic, size: 320),
          MentiAvatarRenderer(profile: variant, size: 320),
        ])))));
    final ctx = tester.element(find.byType(Row));
    await tester.runAsync(() async {
      await precacheImage(const ResizeImage(AssetImage(MentiAssetLayer.core), width: 960), ctx);
      await precacheImage(const AssetImage(MentiAssetLayer.crownCap), ctx);
    });
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await expectLater(find.byKey(const ValueKey('brand-golden')),
      matchesGoldenFile('goldens/menti_brand_pair.png'));
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
