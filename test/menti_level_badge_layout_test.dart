import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mennyiment/l10n/generated/app_localizations.dart';
import 'package:mennyiment/menti_evolution.dart';
import 'package:mennyiment/menti_identity/menti_avatar_renderer.dart';

void main() {
  for (final language in ['hu', 'en']) {
    for (final width in [320.0, 360.0, 390.0, 430.0]) {
      testWidgets('$language $width: 200% level stays below Menti', (
        tester,
      ) async {
        await tester.binding.setSurfaceSize(Size(width, 844));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        await tester.pumpWidget(
          MaterialApp(
            locale: Locale(language),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: MediaQuery(
              data: MediaQueryData(
                size: Size(width, 844),
                textScaler: TextScaler.linear(2),
                disableAnimations: true,
              ),
              child: Scaffold(
                body: SingleChildScrollView(
                  child: Center(
                    child: MentiEvolution(
                      size: width < 380 ? 120 : 140,
                      level: 123,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pump();
        final character = tester.getRect(find.byType(MentiCurrentAvatar));
        final level = tester.getRect(find.text('LVL 123'));
        expect(level.top, greaterThanOrEqualTo(character.bottom));
        expect(level.left, greaterThanOrEqualTo(0));
        expect(level.right, lessThanOrEqualTo(width));
        expect(level.height, greaterThan(20));
        expect(tester.takeException(), isNull);
      });
    }
  }
}
