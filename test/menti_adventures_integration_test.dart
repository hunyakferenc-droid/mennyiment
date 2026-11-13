import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mennyiment/main.dart';
import 'package:mennyiment/menti_adventures.dart';
import 'package:mennyiment/menti_adventure_store.dart';
import 'package:mennyiment/menti_identity/menti_identity.dart';
import 'package:mennyiment/menti_identity/menti_identity_store.dart';
import 'package:mennyiment/l10n/generated/app_localizations.dart';
import 'package:mennyiment/wellbeing_journal.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  Future<void> reveal(WidgetTester t, Finder finder) async {
    for (var i = 0; i < 60; i++) {
      if (finder.evaluate().isNotEmpty) {
        await t.ensureVisible(finder);
        await t.pumpAndSettle();
        return;
      }
      final list = find.byType(ListView).first;
      await t.drag(list, const Offset(0, -250));
      await t.pumpAndSettle();
    }
    fail('Unreachable control: $finder');
  }

  Future<void> tap(WidgetTester t, Finder finder) async {
    await reveal(t, finder);
    await t.tap(finder);
    await t.pumpAndSettle();
    expect(t.takeException(), isNull);
  }

  for (final locale in ['hu', 'en']) {
    testWidgets(
      '$locale: home links real wellbeing, verifies saved data, preserves own Menti and XP',
      (t) async {
        t.view.physicalSize = const Size(390, 900);
        t.view.devicePixelRatio = 1;
        addTearDown(t.view.resetPhysicalSize);
        addTearDown(t.view.resetDevicePixelRatio);
        final identity = MentiIdentityDocument(
          profile: MentiIdentityProfile(name: 'Mira'),
        ).encode();
        const xp = '{"xp":150,"days":[],"completed":[],"future":"keep"}';
        SharedPreferences.setMockInitialValues({
          'mennyiment_access_v1':
              '{"version":1,"audience":"adult","complete":true}',
          'mennyiment_character_setup_complete_v1': true,
          'mennyiment_reduce_motion_v1': true,
          'mennyiment_locale_v1': locale,
          'mennyiment_drinks_v1': '[]',
          'mennyiment_menti_xp_v2': xp,
          MentiIdentityStore.key: identity,
        });
        await t.pumpWidget(const MennyiMentApp());
        await t.pumpAndSettle();
        final prefs = await SharedPreferences.getInstance();
        final before = {for (final k in prefs.getKeys()) k: prefs.get(k)};
        final s = lookupAppLocalizations(Locale(locale));
        await tap(t, find.byKey(const ValueKey('open-adventures')));
        expect(find.byType(MentiAdventuresPage), findsOneWidget);
        await tap(t, find.byKey(const ValueKey('adventure-select-wellbeing')));
        await tap(t, find.byKey(const ValueKey('adventure-open-wellbeing')));
        expect(find.byType(WellbeingJournalPage), findsOneWidget);
        await tap(t, find.text(s.wellbeingSave));
        await tap(t, find.byType(BackButton));
        await t.pumpAndSettle();
        await tap(
          t,
          find.byKey(const ValueKey('adventure-complete-wellbeing')),
        );
        expect(
          AdventureDocument.decode(prefs.get(AdventureStore.key))
              .completedCount(DateTime.now()),
          1,
        );
        await t.pump(const Duration(seconds: 6));
        await t.pumpAndSettle();
        await tap(t, find.text(s.adventureMap));
        await reveal(t, find.text('Mira'));
        expect(find.text('Mira'), findsOneWidget);
        for (final e in before.entries) {
          expect(prefs.get(e.key), e.value, reason: e.key);
        }
        expect(prefs.getString(MentiIdentityStore.key), identity);
        expect(prefs.getString('mennyiment_menti_xp_v2'), xp);
        await tap(t, find.byType(BackButton));
        await t.pumpAndSettle();
        await tap(t, find.byKey(const ValueKey('open-adventures')));
        expect(
          find.byKey(const ValueKey('adventure-dismiss-feedback')),
          findsNothing,
        );
        expect(
          find.byKey(const ValueKey('adventure-complete-wellbeing')),
          findsNothing,
        );
        await t.pumpWidget(const SizedBox.shrink());
        await t.pumpAndSettle();
      },
    );
  }

  testWidgets(
    'A minor can reach adventures and real wellbeing without adult controls',
    (t) async {
      t.view.physicalSize = const Size(430, 900);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.resetPhysicalSize);
      addTearDown(t.view.resetDevicePixelRatio);
      SharedPreferences.setMockInitialValues({
        'mennyiment_access_v1':
            '{"version":1,"audience":"minor","complete":true}',
        'mennyiment_character_setup_complete_v1': true,
        'mennyiment_reduce_motion_v1': true,
        'mennyiment_locale_v1': 'en',
        'mennyiment_drinks_v1': '[]',
      });
      await t.pumpWidget(const MennyiMentApp());
      await t.pumpAndSettle();
      await tap(t, find.byKey(const ValueKey('open-adventures')));
      expect(find.byKey(const ValueKey('adventure-select-goal')), findsNothing);
      await tap(t, find.byKey(const ValueKey('adventure-select-wellbeing')));
      await tap(t, find.byKey(const ValueKey('adventure-open-wellbeing')));
      expect(find.byType(WellbeingJournalPage), findsOneWidget);
      expect(find.text('Hangover symptoms'), findsNothing);
      final raw = (await SharedPreferences.getInstance()).getString(
        'mennyiment_access_v1',
      );
      expect((jsonDecode(raw!) as Map)['audience'], 'minor');
      await t.pumpWidget(const SizedBox.shrink());
      await t.pumpAndSettle();
    },
  );
}
