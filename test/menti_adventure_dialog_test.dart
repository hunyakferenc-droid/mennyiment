import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mennyiment/l10n/generated/app_localizations.dart';
import 'package:mennyiment/menti_adventures.dart';
import 'package:mennyiment/menti_adventure_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  for (final repeatedOpen in [false, true]) {
    testWidgets(
      'Rapid activation: repeated open=$repeatedOpen, confirmation resolves once',
      (t) async {
        SharedPreferences.setMockInitialValues({});
        final store = AdventureStore();
        t.view.physicalSize = const Size(430, 1200);
        t.view.devicePixelRatio = 1;
        addTearDown(t.view.resetPhysicalSize);
        addTearDown(t.view.resetDevicePixelRatio);
        await t.pumpWidget(
          MaterialApp(
            locale: const Locale('en'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: Builder(
              builder: (context) => Scaffold(
                body: TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => MentiAdventuresPage(
                        store: store,
                        onWellbeing: () async {},
                        onGoals: () async {},
                      ),
                    ),
                  ),
                  child: const Text('Open adventures'),
                ),
              ),
            ),
          ),
        );
        await t.tap(find.text('Open adventures'));
        await t.pumpAndSettle();
        final choose = find.byKey(const ValueKey('adventure-select-rest'));
        await t.scrollUntilVisible(
          choose,
          200,
          scrollable: find
              .descendant(
                of: find.byType(ListView).first,
                matching: find.byType(Scrollable),
              )
              .first,
          maxScrolls: 40,
        );
        await t.ensureVisible(choose);
        await t.pumpAndSettle();
        await t.tap(choose);
        await t.pumpAndSettle();
        final complete = find.byKey(const ValueKey('adventure-complete-rest'));
        await t.ensureVisible(complete);
        await t.pumpAndSettle();
        // Repeated accessibility/command activation can arrive before a new frame
        // removes the old semantics node; use the actual button callback.
        final activate = t.widget<FilledButton>(complete).onPressed!;
        activate();
        if (repeatedOpen) activate();
        await t.pumpAndSettle();
        expect(find.byType(AlertDialog, skipOffstage: false), findsOneWidget);
        final confirm = t
            .widget<FilledButton>(
              find.byKey(const ValueKey('adventure-confirm')),
            )
            .onPressed!;
        confirm();
        confirm();
        await t.pumpAndSettle();
        expect(find.byType(MentiAdventuresPage), findsOneWidget);
        expect(store.document.completedCount(DateTime.now()), 1);
        expect(find.byType(AlertDialog, skipOffstage: false), findsNothing);
        await t.pumpWidget(const SizedBox.shrink());
        await t.pumpAndSettle();
      },
    );
  }
}
