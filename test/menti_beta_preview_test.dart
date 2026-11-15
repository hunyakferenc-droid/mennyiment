import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mennyiment/l10n/generated/app_localizations.dart';
import 'package:mennyiment/menti_alive_preview.dart';
import 'package:mennyiment/menti_alive_review_catalog.dart';
import 'package:mennyiment/menti_animation_controller.dart';
import 'package:mennyiment/menti_motion.dart';

import 'menti_life_engine_test.dart' show FakeMentiVideo;

void main() {
  for (final lang in ['hu', 'en']) {
    for (final action in ['stop', 'switch', 'disable']) {
      testWidgets(
        '$lang $action cancels play still scrolling before decoder allocation',
        (t) async {
          var allocations = 0;
          final catalog = MentiAliveReviewCatalog.decode(
            File('tool/menti_alive/review_assets/catalog.json')
                .readAsStringSync(),
            developerPreview: true,
          );
          final c = MentiAnimationController(
            catalog: catalog,
            verify: (_) async {},
            factory: (_) {
              allocations++;
              return FakeMentiVideo();
            },
          );
          SharedPreferences.setMockInitialValues({});
          await t.pumpWidget(
            MaterialApp(
              locale: Locale(lang),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: MentiMotionScope(
                child: MentiAlivePreviewPage(
                  developerPreview: true,
                  controller: c,
                  reviewCatalog: catalog,
                  readPreferences: false,
                ),
              ),
            ),
          );
          await t.pumpAndSettle();
          final play = find.byKey(const ValueKey('alive-play-welcome'));
          await t.ensureVisible(play);
          await t.pumpAndSettle();
          t.widget<FilledButton>(play).onPressed!();
          if (action == 'stop') {
            t
                .widget<OutlinedButton>(
                  find.byKey(const ValueKey('alive-stop')),
                )
                .onPressed!();
          } else if (action == 'switch') {
            t
                .widget<DropdownButtonFormField<String>>(
                  find.byType(DropdownButtonFormField<String>),
                )
                .onChanged!('girl-base-v1');
          } else {
            t
                .widget<SwitchListTile>(
                  find.byKey(const ValueKey('alive-enabled')),
                )
                .onChanged!(false);
          }
          await t.pumpAndSettle();
          await t.runAsync(() => c.settled);
          expect(allocations, 0);
          expect(c.active, isNull);
          if (action == 'switch') {
            await t.ensureVisible(
              find.byKey(const ValueKey('alive-candidates')),
            );
            await t.tap(find.byKey(const ValueKey('alive-candidates')));
            await t.pumpAndSettle();
            expect(
              t
                  .widget<DropdownButtonFormField<String>>(
                    find.byType(DropdownButtonFormField<String>),
                  )
                  .initialValue,
              'boy-festival-v1',
            );
          }
          expect(t.takeException(), isNull);
          await t.pumpWidget(const SizedBox.shrink());
          await t.pumpAndSettle();
          c.dispose();
          await t.runAsync(() => c.settled);
        },
      );
    }
  }
}
