import 'dart:async';
import 'dart:convert';
import 'dart:ui' show CheckedState;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';
import 'package:mennyiment/menti_fitness.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';
import 'package:mennyiment/menti_club_store.dart';
import 'package:mennyiment/menti_movement_cards.dart';
import 'package:mennyiment/l10n/generated/app_localizations.dart';
import 'package:mennyiment/data_backup.dart';
import 'package:mennyiment/data_restore.dart';

class ClubFault extends InMemorySharedPreferencesStore {
  ClubFault(super.data, {this.gate, this.persist = false}) : super.withData();
  final Completer<void>? gate;
  final bool persist;
  @override
  Future<bool> setValue(String type, String key, Object value) async {
    if (key == 'flutter.${MentiClubStore.normalKey}') {
      if (gate != null) {
        await gate!.future;
        return super.setValue(type, key, value);
      }
      if (persist) await super.setValue(type, key, value);
      return false;
    }
    return super.setValue(type, key, value);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(
    () => SharedPreferences.setMockInitialValues({
      'journal-sentinel': 'unchanged',
      'xp-sentinel': 73,
    }),
  );
  test('Trial Week credits once per date, survives a gap and restores independently', () async {
    final real = MentiClubStore(key: MentiClubStore.adventureWeekKey);
    final trial = MentiClubStore(key: MentiClubStore.adventureWeekTestKey);
    await real.load();
    await trial.load();
    final first = DateTime(2030, 1, 1);
    expect(await trial.completeAdventure(first, rhythmScore: 1), ClubSave.saved);
    expect(await trial.completeAdventure(first, rhythmScore: 3), ClubSave.alreadyToday);
    expect(trial.record.best, 1);
    expect(await trial.completeAdventure(DateTime(2030, 1, 3), rhythmScore: 3),
      ClubSave.saved);
    expect(trial.record.days, ['2030-01-01', '2030-01-03']);
    expect(trial.record.best, 3);
    expect(real.record.days, isEmpty);

    final backup = await BackupExporter().capture();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(MentiClubStore.adventureWeekTestKey);
    final restorer = BackupRestorer();
    await restorer.restore(await restorer.prepare(backup.json), confirmed: true);
    await trial.load();
    expect(trial.record.days, ['2030-01-01', '2030-01-03']);
    expect(trial.record.best, 3);
    expect(prefs.containsKey(MentiClubStore.adventureWeekKey), isFalse);
    real.dispose();
    trial.dispose();
  });

  test('Missing club load is read-only; partial rhythm keeps best but marks no day; real restart reloads', () async {
    final p = await SharedPreferences.getInstance(),
        s = MentiClubStore(clock: () => DateTime(2026, 11, 22));
    final before = {for (final k in p.getKeys()) k: p.get(k)};
    await s.load();
    expect(s.ready, true);
    expect({for (final k in p.getKeys()) k: p.get(k)}, before);
    expect(await s.rhythm(3), ClubSave.saved);
    expect(s.record.best, 3);
    expect(s.record.days, isEmpty);
    expect(s.record.last, isNull);
    final reload = MentiClubStore();
    await reload.load();
    expect(reload.record.best, 3);
    expect(reload.record.days, isEmpty);
    final after = {for (final k in p.getKeys()) k: p.get(k)}
      ..remove(MentiClubStore.normalKey);
    expect(after, before);
    s.dispose();
    reload.dispose();
  });
  test('Seven local days with gap, midnight at completion, repeat, full, restart and reset; same day cannot count across challenges', () async {
    var now = DateTime(2026, 3, 28, 23, 59);
    final s = MentiClubStore(clock: () => now);
    await s.load();
    now = DateTime(
      2026,
      3,
      29,
      0,
      1,
    ); // Completed after midnight, not the starting day.
    expect(await s.cards(), ClubSave.saved);
    expect(s.record.days, ['2026-03-29']);
    expect(await s.rhythm(5), ClubSave.alreadyToday);
    expect(s.record.best, 5);
    expect(s.record.days.length, 1);
    now = DateTime(2026, 3, 31); // March 30 skipped; progress remains.
    expect(s.record.days.length, 1);
    expect(await s.cards(), ClubSave.saved);
    for (var i = 1; i <= 5; i++) {
      now = DateTime(2026, 3, 31 + i);
      expect(await s.cards(), ClubSave.saved);
    }
    expect(s.record.days.length, 7);
    expect(s.record.last, '2026-04-05');
    final cold = MentiClubStore(clock: () => now);
    await cold.load();
    expect(cold.record.days, s.record.days);
    expect(cold.record.best, 5);
    now = DateTime(2026, 4, 6);
    expect(await cold.cards(), ClubSave.full);
    expect(cold.record.days.length, 7);
    expect(await cold.newChallenge(), ClubSave.saved);
    expect(cold.record.days, isEmpty);
    expect(cold.record.best, 5);
    expect(cold.record.last, '2026-04-05');
    // Reconstruct an ended challenge whose seventh day was today.
    final p = await SharedPreferences.getInstance();
    await p.setString(
      MentiClubStore.normalKey,
      const MentiClubRecord(
        best: 5,
        days: [
          '2026-04-01',
          '2026-04-02',
          '2026-04-03',
          '2026-04-04',
          '2026-04-05',
          '2026-04-06',
          '2026-04-07',
        ],
        last: '2026-04-07',
      ).encode(),
    );
    now = DateTime(2026, 4, 7);
    await cold.load();
    expect(await cold.newChallenge(), ClubSave.saved);
    expect(await cold.cards(), ClubSave.alreadyToday);
    expect(cold.record.days, isEmpty);
    now = DateTime(2026, 4, 8);
    expect(await cold.cards(), ClubSave.saved);
    expect(cold.record.days, ['2026-04-08']);
    s.dispose();
    cold.dispose();
  });
  test('Existing export/import includes own and test club records, validates corrupt club data, old backups do not delete club', () async {
    final oldBackup = await BackupExporter().capture();
    final a = MentiClubStore(clock: () => DateTime(2026, 11, 22)),
        b = MentiClubStore(
          key: MentiClubStore.testKey,
          clock: () => DateTime(2030),
        );
    await a.load();
    await b.load();
    await a.cards();
    await b.rhythm(2);
    final p = await SharedPreferences.getInstance(),
        raw = p.getString(MentiClubStore.normalKey);
    final backup = await BackupExporter().capture();
    expect(backup.json, contains(MentiClubStore.normalKey));
    expect(backup.json, contains(MentiClubStore.testKey));
    validateRestoreValue(MentiClubStore.normalKey, raw!);
    expect(
      () => validateRestoreValue(MentiClubStore.normalKey, 'broken'),
      throwsFormatException,
    );
    final restorer = BackupRestorer();
    final plan = await restorer.prepare(backup.json);
    await restorer.restore(plan, confirmed: true);
    final older = await restorer.prepare(oldBackup.json);
    await restorer.restore(older, confirmed: true);
    await a.load();
    expect(a.record.days, ['2026-11-22']);
    await b.load();
    expect(b.record.best, 2);
    a.dispose();
    b.dispose();
  });
  for (final raw in [
    'broken',
    '{"version":1,"version":1,"best":0,"days":[],"last":null}',
    '{"version":2}',
    '{"version":1,"best":8,"days":[],"last":null}',
    jsonEncode({
      'version': 1,
      'best': 0,
      'days': ['2026-02-30'],
      'last': '2026-02-30',
    }),
    jsonEncode({
      'version': 1,
      'best': 0,
      'days': ['2026-01-01', '2026-01-01'],
      'last': '2026-01-01',
    }),
    jsonEncode({
      'version': 1,
      'best': 0,
      'days': ['2026-01-01'],
      'last': null,
    }),
    42,
  ]) {
    test('Corrupt/unknown club storage preserved: $raw', () async {
      SharedPreferences.setMockInitialValues({MentiClubStore.normalKey: raw});
      final p = await SharedPreferences.getInstance(), s = MentiClubStore();
      await s.load();
      expect(s.ready, false);
      expect(await s.cards(), ClubSave.failed);
      expect(await s.rhythm(5), ClubSave.failed);
      expect(await s.newChallenge(), ClubSave.failed);
      await p.reload();
      expect(p.get(MentiClubStore.normalKey), raw);
      s.dispose();
    });
  }
  test('Unknown historical club fields preserved, clock reversal and incomplete reset do not overwrite', () async {
    final raw = jsonEncode({
      'version': 1,
      'best': 2,
      'days': ['2030-01-01'],
      'last': '2030-01-01',
      'future': {
        'raw': [1, null, 'kept'],
      },
    });
    SharedPreferences.setMockInitialValues({MentiClubStore.normalKey: raw});
    final p = await SharedPreferences.getInstance(),
        s = MentiClubStore(clock: () => DateTime(2026));
    await s.load();
    expect(await s.cards(), ClubSave.failed);
    expect(p.getString(MentiClubStore.normalKey), raw);
    expect(await s.newChallenge(), ClubSave.failed);
    expect(p.getString(MentiClubStore.normalKey), raw);
    expect(await s.rhythm(4), ClubSave.saved);
    expect(s.record.extras, {
      'future': {
        'raw': [1, null, 'kept'],
      },
    });
    s.dispose();
  });
  test('External snapshot and two loaded stores never overwrite another completion', () async {
    final a = MentiClubStore(clock: () => DateTime(2026, 11, 22)),
        b = MentiClubStore(clock: () => DateTime(2026, 11, 23));
    await a.load();
    await b.load();
    expect(await a.cards(), ClubSave.saved);
    final p = await SharedPreferences.getInstance(),
        raw = p.getString(MentiClubStore.normalKey);
    expect(await b.cards(), ClubSave.failed);
    expect(b.ready, false);
    expect(p.getString(MentiClubStore.normalKey), raw);
    await b.load();
    expect(await b.cards(), ClubSave.saved);
    expect(b.record.days.length, 2);
    a.dispose();
    b.dispose();
  });
  for (final persist in [false, true]) {
    test(
      'Unconfirmed write never presents success; explicit reload/retry remains idempotent ($persist)',
      () async {
        final platform = SharedPreferencesStorePlatform.instance;
        SharedPreferencesStorePlatform.instance = ClubFault({
          'flutter.journal-sentinel': 'unchanged',
        }, persist: persist);
        addTearDown(() => SharedPreferencesStorePlatform.instance = platform);
        final s = MentiClubStore(clock: () => DateTime(2026, 11, 22));
        await s.load();
        expect(await s.cards(), ClubSave.failed);
        expect(s.record.days, isEmpty);
        expect(s.error, 'save');
        await s.load();
        expect(s.record.days.length, persist ? 1 : 0);
        s.dispose();
      },
    );
  }
  test(
    'Double submit blocks before asynchronous persistence; exactly one day',
    () async {
      final platform = SharedPreferencesStorePlatform.instance,
          gate = Completer<void>();
      SharedPreferencesStorePlatform.instance = ClubFault({}, gate: gate);
      addTearDown(() => SharedPreferencesStorePlatform.instance = platform);
      final s = MentiClubStore(clock: () => DateTime(2026, 11, 22));
      await s.load();
      final first = s.cards();
      expect(await s.cards(), ClubSave.failed);
      gate.complete();
      expect(await first, ClubSave.saved);
      expect(s.record.days.length, 1);
      s.dispose();
    },
  );
  test('Virtual date and dedicated test key never change actual club, XP or journal', () async {
    final p = await SharedPreferences.getInstance();
    final real = MentiClubStore(clock: () => DateTime(2026, 11, 22));
    await real.load();
    await real.rhythm(2);
    final before = {for (final k in p.getKeys()) k: p.get(k)};
    var day = DateTime(2030, 1, 1);
    final test = MentiClubStore(key: MentiClubStore.testKey, clock: () => day);
    await test.load();
    for (var i = 0; i < 7; i++) {
      day = DateTime(2030, 1, 1 + i);
      expect(await test.cards(), ClubSave.saved);
    }
    expect(test.record.days.length, 7);
    final after = {for (final k in p.getKeys()) k: p.get(k)}
      ..remove(MentiClubStore.testKey);
    expect(after, before);
    real.dispose();
    test.dispose();
  });
  for (final lang in ['hu', 'en']) {
    for (final width in [320.0, 430.0]) {
      testWidgets(
        'Movement cards $lang $width 200% skip/leave/all-skipped/seated/standing, own PNG and one daily mark',
        (t) async {
          t.view.physicalSize = Size(width, 1000);
          t.view.devicePixelRatio = 1;
          addTearDown(t.view.resetPhysicalSize);
          addTearDown(t.view.resetDevicePixelRatio);
          final s = MentiClubStore(clock: () => DateTime(2026, 11, 22));
          await s.load();
          await t.pumpWidget(
            MaterialApp(
              locale: Locale(lang),
              supportedLocales: AppLocalizations.supportedLocales,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(textScaler: TextScaler.linear(2)),
                child: child!,
              ),
              home: Builder(
                builder: (context) => Scaffold(
                  body: TextButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => MentiMovementCards(store: s),
                      ),
                    ),
                    child: const Text('Open'),
                  ),
                ),
              ),
            ),
          );
          Future<void> tapKey(String key) async {
            final f = find.byKey(ValueKey(key));
            for (var i = 0; i < 30 && f.evaluate().isEmpty; i++) {
              await t.drag(
                find.byType(Scrollable).first,
                const Offset(0, -200),
              );
              await t.pumpAndSettle();
            }
            expect(f, findsOneWidget);
            await t.ensureVisible(f);
            await t.pumpAndSettle();
            await t.tap(f);
            await t.pumpAndSettle();
          }

          Future<void> open() async {
            await t.tap(find.text('Open'));
            await t.pumpAndSettle();
          }

          await open();
          await tapKey('cards-start');
          await tapKey('cards-next');
          await tapKey('cards-exit');
          expect(
            s.record.days,
            isEmpty,
          ); // A partial session is not a completion.
          await open();
          await tapKey('cards-start');
          for (var i = 0; i < 3; i++) {
            await tapKey('cards-skip');
          }
          expect(s.record.days, isEmpty);
          await tapKey('cards-club');
          for (final seated in [true, false]) {
            await open();
            await tapKey(seated ? 'cards-seated' : 'cards-standing');
            if (seated) {
              final start = find.byKey(const ValueKey('cards-start'));
              await t.ensureVisible(start);
              await t.pumpAndSettle();
              Focus.of(
                t.element(
                  find.descendant(of: start, matching: find.byType(Text)).first,
                ),
              ).requestFocus();
              await t.pump();
              await t.sendKeyEvent(LogicalKeyboardKey.enter);
              await t.pumpAndSettle();
            } else {
              await tapKey('cards-start');
            }
            if (seated) {
              for (final key in [
                LogicalKeyboardKey.keyN,
                LogicalKeyboardKey.keyS,
                LogicalKeyboardKey.keyN,
              ]) {
                await t.sendKeyEvent(key);
                await t.pumpAndSettle();
              }
            } else {
              await tapKey('cards-next');
              await tapKey('cards-skip');
              await tapKey('cards-next');
            }
            expect(s.record.days, ['2026-11-22']);
            expect(s.record.best, 0);
            await tapKey('cards-club');
          }
          expect(t.takeException(), isNull);
          s.dispose();
        },
      );
    }
  }
  for (final lang in ['hu', 'en']) {
    for (final width in [320.0, 430.0]) {
      testWidgets(
        'Seven-day club $lang $width 200% all days and reset reachable, last date/best retained',
        (t) async {
          SharedPreferences.setMockInitialValues({
            MentiClubStore.normalKey: MentiClubRecord(
              best: 5,
              days: [
                for (var i = 1; i <= 7; i++) clubDay(DateTime(2030, 1, i)),
              ],
              last: '2030-01-07',
            ).encode(),
          });
          final store = MentiClubStore(clock: () => DateTime(2030, 1, 8));
          await store.load();
          t.view.physicalSize = Size(width, 1000);
          t.view.devicePixelRatio = 1;
          addTearDown(t.view.resetPhysicalSize);
          addTearDown(t.view.resetDevicePixelRatio);
          await t.pumpWidget(
            MaterialApp(
              locale: Locale(lang),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(textScaler: TextScaler.linear(2)),
                child: child!,
              ),
              home: MentiFitnessClub(store: store),
            ),
          );
          await t.pumpAndSettle();
          final semantics = t.ensureSemantics();

          try {
            final first = find.byKey(const ValueKey('club-day-0'));
            await t.scrollUntilVisible(first, 200, maxScrolls: 40);
            await t.pumpAndSettle();
            for (var i = 0; i < 7; i++) {
              expect(find.byKey(ValueKey('club-day-$i')), findsOneWidget);
              final label = find
                  .descendant(
                    of: find.byKey(ValueKey('club-day-$i')),
                    matching: find.byType(Text),
                  )
                  .first;
              expect(
                t.renderObject<RenderParagraph>(label).didExceedMaxLines,
                false,
                reason: 'Full completion date must remain visible at 200%',
              );
              final paragraph = t.renderObject<RenderParagraph>(label);
              final value = t.widget<Text>(label).data!;
              // Selection boxes may include hanging line-end whitespace;
              // inspect the visible date glyphs rather than that empty space.
              for (var index = 0; index < value.length; index++) {
                if (value[index].trim().isEmpty) continue;
                for (final box in paragraph.getBoxesForSelection(
                  TextSelection(baseOffset: index, extentOffset: index + 1),
                )) {
                  expect(
                    box.right,
                    lessThanOrEqualTo(paragraph.size.width + .5),
                    reason:
                        'Date $value glyph ${value[index]} must not be clipped horizontally',
                  );
                  expect(
                    box.bottom,
                    lessThanOrEqualTo(paragraph.size.height + .5),
                    reason: 'No date line may be clipped vertically',
                  );
                }
              }

              expect(
                t
                    .getSemantics(find.byKey(ValueKey('club-day-$i')))
                    .getSemanticsData()
                    .flagsCollection
                    .isChecked,
                CheckedState.isTrue,
              );
            }
            final f = find.byKey(const ValueKey('club-new-challenge'));
            await t.scrollUntilVisible(f, 200, maxScrolls: 40);
            await t.ensureVisible(f);
            await t.pumpAndSettle();
            await t.tap(f);
            await t.pumpAndSettle();
            expect(store.record.days, isEmpty);
            expect(store.record.best, 5);
            expect(store.record.last, '2030-01-07');
            expect(t.takeException(), isNull);
          } finally {
            semantics.dispose();
            store.dispose();
          }
        },
      );
    }
  }
}
