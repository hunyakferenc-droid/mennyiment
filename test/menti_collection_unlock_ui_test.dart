import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mennyiment/menti_complete_looks.dart';
import 'package:mennyiment/menti_xp_store.dart';
import 'package:mennyiment/l10n/generated/app_localizations.dart';

void main() {
  for (final locale in ['hu', 'en']) {
    for (final width in [320.0, 360.0, 390.0, 430.0]) {
      testWidgets(
        '$locale $width 200% filters and live XP acquisition with once-only feedback',
        (t) async {
          t.view.physicalSize = Size(width, 844);
          t.view.devicePixelRatio = 1;
          addTearDown(t.view.resetPhysicalSize);
          addTearDown(t.view.resetDevicePixelRatio);
          SharedPreferences.setMockInitialValues({
            MentiXpStore.currentKey: jsonEncode({
              'xp': 190,
              'days': [],
              'completed': [],
            }),
          });
          final store = CompleteLookStore();
          await store.load();
          await t.pumpWidget(
            MaterialApp(
              locale: Locale(locale),
              supportedLocales: AppLocalizations.supportedLocales,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              builder: (ctx, child) => MediaQuery(
                data: MediaQuery.of(ctx).copyWith(
                  textScaler: const TextScaler.linear(2),
                  disableAnimations: true,
                ),
                child: CompleteLookScope(store: store, child: child!),
              ),
              home: const CompleteLooksPage(),
            ),
          );
          await t.pumpAndSettle();
          final strings = AppLocalizations.of(
            t.element(find.byType(CompleteLooksPage)),
          )!;
          Future<void> tap(String key) async {
            final f = find.byKey(ValueKey(key));
            t
                .state<ScrollableState>(find.byType(Scrollable).last)
                .position
                .jumpTo(0);
            await t.pumpAndSettle();
            await t.scrollUntilVisible(
              f,
              200,
              maxScrolls: 100,
              scrollable: find.byType(Scrollable).last,
            );
            await t.ensureVisible(f);
            await t.pumpAndSettle();
            await t.tap(f);
            await t.pumpAndSettle();
          }

          await tap('collection-family-girl');
          await tap('collection-view-locked');
          expect(
            t
                .widget<ChoiceChip>(
                  find.byKey(const ValueKey('collection-view-locked')),
                )
                .selected,
            true,
          );
          expect(
            t
                .widget<ChoiceChip>(
                  find.byKey(const ValueKey('collection-family-girl')),
                )
                .selected,
            true,
          );
          final locked = find.byKey(
            const ValueKey('complete-girl-legendary-v1'),
          );
          await t.scrollUntilVisible(
            locked,
            200,
            maxScrolls: 100,
            scrollable: find.byType(Scrollable).last,
          );
          expect(t.widget<FilledButton>(locked).onPressed, isNull);
          expect(store.selection.acquired, isEmpty);
          final state = await MentiXpStore.checkInToday(
            now: DateTime(2026, 11, 14),
          );
          expect(state.xp, 200);
          await t.pumpAndSettle();
          expect(store.selection.acquired.length, 3);
          expect(
            find.textContaining(
              locale == 'hu' ? 'Új Menti-kinézet:' : 'New Menti look:',
            ),
            findsOneWidget,
          );
          await t.pump(const Duration(seconds: 5));
          await t.pumpAndSettle();
          t
              .state<ScrollableState>(find.byType(Scrollable).last)
              .position
              .jumpTo(0);
          await t.pumpAndSettle();
          await t.scrollUntilVisible(
            find.text(strings.collectionNoMatches),
            150,
            maxScrolls: 100,
            scrollable: find.byType(Scrollable).last,
          );
          expect(find.text(strings.collectionNoMatches), findsOneWidget);
          await store.load();
          await t.pumpAndSettle();
          expect(find.byType(SnackBar), findsNothing);
          await tap('collection-view-owned');
          final selected = find.byKey(
            const ValueKey('complete-girl-legendary-v1'),
          );
          await t.scrollUntilVisible(
            selected,
            220,
            maxScrolls: 100,
            scrollable: find.byType(Scrollable).last,
          );
          expect(t.widget<FilledButton>(selected).onPressed, isNotNull);
          final p = await SharedPreferences.getInstance();
          expect(jsonDecode(p.getString(MentiXpStore.currentKey)!)['xp'], 200);
          expect(t.takeException(), isNull);
          await t.pumpWidget(const SizedBox.shrink());
          await t.pumpAndSettle();
          store.dispose();
        },
      );
    }
  }
  for (final locale in ['hu', 'en']) {
    testWidgets(
      '$locale external choice during a dirty preview requires explicit reload',
      (t) async {
        t.view.physicalSize = const Size(320, 844);
        t.view.devicePixelRatio = 1;
        addTearDown(t.view.resetPhysicalSize);
        addTearDown(t.view.resetDevicePixelRatio);
        SharedPreferences.setMockInitialValues({});
        final store = CompleteLookStore();
        await store.load();
        await t.pumpWidget(
          MaterialApp(
            locale: Locale(locale),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            builder: (ctx, child) =>
                CompleteLookScope(store: store, child: child!),
            home: const CompleteLooksPage(),
          ),
        );
        await t.pumpAndSettle();
        final girl = find.byKey(const ValueKey('complete-girl-base-v1'));
        await t.scrollUntilVisible(
          girl,
          200,
          maxScrolls: 100,
          scrollable: find.byType(Scrollable).last,
        );
        await t.ensureVisible(girl);
        await t.pumpAndSettle();
        await t.tap(girl);
        await t.pumpAndSettle();
        final other = CompleteLookStore();
        await other.load();
        expect(
          await other.save(
            const CompleteLookSelection(
              active: true,
              lookId: 'neutral-base-v1',
            ),
          ),
          true,
        );
        await store.load();
        await t.pumpAndSettle();
        expect(
          t
              .widget<FilledButton>(find.byKey(const ValueKey('complete-save')))
              .onPressed,
          isNull,
        );
        final strings = AppLocalizations.of(
          t.element(find.byType(CompleteLooksPage)),
        )!;
        t
            .state<ScrollableState>(find.byType(Scrollable).last)
            .position
            .jumpTo(0);
        await t.pumpAndSettle();
        await t.scrollUntilVisible(
          find.text(strings.collectionChanged),
          200,
          maxScrolls: 100,
          scrollable: find.byType(Scrollable).last,
        );
        expect(find.text(strings.collectionChanged), findsOneWidget);
        final retry = find.text(strings.restoreRetry);
        await t.ensureVisible(retry);
        await t.pumpAndSettle();
        await t.tap(retry);
        await t.pumpAndSettle();
        expect(
          t
              .widget<FilledButton>(find.byKey(const ValueKey('complete-save')))
              .onPressed,
          isNotNull,
        );
        expect(store.selection.lookId, 'neutral-base-v1');
        final p = await SharedPreferences.getInstance();
        expect(
          CompleteLookSelection.decode(p.getString(CompleteLookStore.key))
              .lookId,
          'neutral-base-v1',
        );
        expect(t.takeException(), isNull);
        await t.pumpWidget(const SizedBox.shrink());
        await t.pumpAndSettle();
        store.dispose();
        other.dispose();
      },
    );
  }
}
