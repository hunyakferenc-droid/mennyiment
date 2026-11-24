import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';
import 'package:mennyiment/main.dart';
import 'package:mennyiment/l10n/generated/app_localizations.dart';

import 'support/adult_access_fixture.dart';
import 'menti_favorites_store_test.dart' show FavoriteBackend;

void main() {
  testWidgets(
    'Same-frame double favorite tap waits for durable write, makes one write and reports no false error',
    (t) async {
      SharedPreferences.setMockInitialValues({});
      final gate = Completer<void>();
      final io = FavoriteBackend({
        'flutter.$adultAccessKey': adultAccessValue,
        'flutter.mennyiment_character_setup_complete_v1': true,
        'flutter.mennyiment_reduce_motion_v1': true,
      }, gate: gate);
      SharedPreferencesStorePlatform.instance = io;
      await t.pumpWidget(const MennyiMentApp());
      await t.pumpAndSettle();
      final add = find.byKey(const ValueKey('home-primary-log'));
      await t.scrollUntilVisible(add, 200, maxScrolls: 40);
      await t.ensureVisible(add);
      await t.pumpAndSettle();
      await t.tap(add);
      await t.pumpAndSettle();
      final star = find.byIcon(Icons.star_border).first;
      await t.tap(star);
      await t.tap(star);
      await t.pump();
      expect(find.byIcon(Icons.star), findsNothing);
      gate.complete();
      await t.pumpAndSettle();
      expect(io.writes, 1);
      expect(find.byIcon(Icons.star), findsOneWidget);
      final button = find.ancestor(
        of: find.byIcon(Icons.star),
        matching: find.byType(IconButton),
      );
      expect(t.widget<IconButton>(button).isSelected, true);
      final s = AppLocalizations.of(t.element(find.byType(HomePage)))!;
      expect(find.text(s.journalFavoritesWriteError), findsNothing);
      await t.pumpWidget(const SizedBox.shrink());
      await t.pumpAndSettle();
    },
  );

  for (final lang in ['hu', 'en']) {
    testWidgets(
      '$lang real favorite star stays unchanged when native write fails',
      (t) async {
        SharedPreferences.setMockInitialValues({});
        SharedPreferencesStorePlatform.instance = FavoriteBackend({
          'flutter.$adultAccessKey': adultAccessValue,
          'flutter.mennyiment_character_setup_complete_v1': true,
          'flutter.mennyiment_reduce_motion_v1': true,
          'flutter.mennyiment_locale_v1': lang,
        }, fail: true);
        await t.pumpWidget(const MennyiMentApp());
        await t.pumpAndSettle();
        final f = find.byKey(const ValueKey('home-primary-log'));
        await t.scrollUntilVisible(f, 200, maxScrolls: 40);
        await t.ensureVisible(f);
        await t.pumpAndSettle();
        await t.tap(f);
        await t.pumpAndSettle();
        final star = find.byIcon(Icons.star_border).first;
        await t.tap(star);
        await t.pumpAndSettle();
        expect(find.byIcon(Icons.star), findsNothing);
        final s = AppLocalizations.of(t.element(find.byType(HomePage)))!;
        expect(find.text(s.journalFavoritesWriteError), findsOneWidget);
        final p = await SharedPreferences.getInstance();
        expect(p.getStringList('mennyiment_favorites_v1'), isNull);
        await t.pumpWidget(const SizedBox.shrink());
        await t.pumpAndSettle();
      },
    );
  }
}
