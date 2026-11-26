import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mennyiment/l10n/generated/app_localizations.dart';
import 'package:mennyiment/mai_menti.dart';
import 'package:mennyiment/menti_club_store.dart';
import 'package:mennyiment/menti_memory.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget _app(Widget child) => MaterialApp(
  locale: const Locale('en'),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(body: SingleChildScrollView(child: child)),
);

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('Memory pauses its current cue and accepts keyboard input', (
    t,
  ) async {
    final record = MentiClubStore(key: MentiClubStore.memoryTestKey);
    await record.load();
    addTearDown(record.dispose);
    await t.pumpWidget(
      _app(SizedBox(height: 560, child: MentiMemory(store: record))),
    );
    await t.pumpAndSettle();
    await t.sendKeyEvent(LogicalKeyboardKey.digit1);
    await t.pump();
    await t.tap(find.byKey(const ValueKey('memory-start')));
    await t.pump();
    final cue = find.byKey(const ValueKey('memory-cue'));
    final first = t.widget<Text>(cue).data!;
    t.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await t.pump(const Duration(seconds: 5));
    expect(t.widget<Text>(cue).data, first);
    t.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    final pattern = <String>[];
    for (var index = 0; index < 3; index++) {
      pattern.add(t.widget<Text>(cue).data!);
      await t.pump(const Duration(milliseconds: 950));
    }
    expect(find.byKey(const ValueKey('memory-input')), findsOneWidget);
    const keys = {
      'Circle': LogicalKeyboardKey.digit1,
      'Triangle': LogicalKeyboardKey.digit2,
      'Square': LogicalKeyboardKey.digit3,
    };
    for (final symbol in pattern) {
      await t.sendKeyEvent(keys[symbol]!);
      await t.pump();
    }
    await t.pumpAndSettle();
    expect(find.text('Pattern matched!'), findsOneWidget);
    expect(record.record.best, 1);
    await t.tap(find.byKey(const ValueKey('memory-replay')));
    await t.pump();
    expect(cue, findsOneWidget);
    await t.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
    'A mood dialog opened before midnight cannot save for the old day',
    (t) async {
      var now = DateTime(2030, 1, 1, 23, 59, 59);
      await t.pumpWidget(
        _app(
          MaiMenti(
            character: const SizedBox(width: 50, height: 50),
            name: 'Menti',
            clock: () => now,
          ),
        ),
      );
      await t.pumpAndSettle();
      final adventure = find.byKey(const ValueKey('adventure-start'));
      expect(t.widget<FilledButton>(adventure).onPressed, isNotNull);
      await t.tap(adventure);
      await t.pumpAndSettle();
      now = DateTime(2030, 1, 2);
      await t.tap(find.byKey(const ValueKey('adventure-mood-2')));
      await t.pumpAndSettle();
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.get(MentiClubStore.adventureWeekKey), isNull);
      expect(
        prefs.getKeys().where(
          (key) => key.startsWith('mennyiment_daily_menti_v1_'),
        ),
        isEmpty,
      );
      expect(t.widget<FilledButton>(adventure).onPressed, isNotNull);
      await t.pumpWidget(const SizedBox.shrink());
    },
  );
}
