import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mennyiment/l10n/generated/app_localizations.dart';
import 'package:mennyiment/menti_identity/menti_avatar_renderer.dart';
import 'package:mennyiment/menti_identity/menti_premium_renderer.dart';
import 'package:mennyiment/menti_identity/menti_identity.dart';

void main() {
  for (final cap in [false,true]) {
    testWidgets('nine full family-age identities ${cap ? 'classic' : 'uncovered'} golden', (tester) async {
      await tester.binding.setSurfaceSize(const Size(600,750));
      addTearDown(()=>tester.binding.setSurfaceSize(null));
      final profiles=[for(final family in ['boy','girl','neutral'])
        for(final age in ['young','adult','veteran']) MentiIdentityProfile(visual:MentiVisualProfile({
          'family':family,'age':age,'hair':'$family-crop','headwear':cap?'crown-cap':'none'}))];
      await tester.pumpWidget(MaterialApp(locale:const Locale('en'),
        localizationsDelegates:AppLocalizations.localizationsDelegates,
        supportedLocales:AppLocalizations.supportedLocales,
        home:Scaffold(body:RepaintBoundary(key:const ValueKey('family-grid'),
          child:Column(mainAxisSize:MainAxisSize.min,children:[
            for(var row=0;row<3;row++) Row(mainAxisSize:MainAxisSize.min,children:[
              for(var col=0;col<3;col++) MentiAvatarRenderer(profile:profiles[row*3+col],size:200),
            ]),
          ])))));
      final ctx=tester.element(find.byKey(const ValueKey('family-grid')));
      await tester.runAsync(() async {
        for(final path in MentiPremiumComposition.assets) { await precacheImage(AssetImage(path),ctx); }
      });
      await tester.pumpAndSettle();
      expect(tester.takeException(),isNull);
      await expectLater(find.byKey(const ValueKey('family-grid')),
        matchesGoldenFile('goldens/menti_final_families_${cap ? 'classic' : 'uncovered'}.png'));
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
}
