import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mennyiment/menti_club_store.dart';
import 'package:mennyiment/menti_movement_cards.dart';
import 'package:mennyiment/l10n/generated/app_localizations.dart';

void main() {
  for (final lang in ['hu', 'en']) {
    testWidgets(
      '$lang REVIEW card completion uses the advanced day, not the starting day',
      (t) async {
        SharedPreferences.setMockInitialValues({});
        var now = DateTime(2030, 1, 1, 23, 59);
        final store = MentiClubStore(
          key: MentiClubStore.testKey,
          clock: () => now,
        );
        await store.load();
        await t.pumpWidget(
          MaterialApp(
            locale: Locale(lang),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: MentiMovementCards(
              store: store,
              testClock: () => now,
              nextTestDay: () => now = DateTime(2030, 1, 2),
            ),
          ),
        );
        await t.pumpAndSettle();
        Future<void> hit(String key) async {
          final scroll = find.byType(Scrollable).first;
          await t.drag(scroll, const Offset(0, 4000));
          await t.pumpAndSettle();
          final f = find.byKey(ValueKey(key));
          await t.scrollUntilVisible(f, 200, maxScrolls: 30);
          await t.ensureVisible(f);
          await t.pumpAndSettle();
          await t.tap(f);
          await t.pumpAndSettle();
        }

        await hit('cards-start');
        await hit('cards-next');
        expect(store.record.days, isEmpty);
        await hit('cards-next-test-day');
        await hit('cards-next');
        await hit('cards-next');
        expect(store.record.days, ['2030-01-02']);
        final fresh = MentiClubStore(
          key: MentiClubStore.testKey,
          clock: () => now,
        );
        await fresh.load();
        expect(fresh.record.days, ['2030-01-02']);
        final p = await SharedPreferences.getInstance();
        expect(p.containsKey(MentiClubStore.normalKey), false);
        expect(await fresh.cards(), ClubSave.alreadyToday);
      },
    );
  }
}
