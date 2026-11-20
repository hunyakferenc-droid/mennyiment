import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mennyiment/l10n/generated/app_localizations.dart';
import 'package:mennyiment/menti_animation_catalog.dart';
import 'package:mennyiment/menti_alive_review_catalog.dart';
import 'package:mennyiment/menti_alive_preview.dart';
import 'package:mennyiment/menti_animation_studio_model.dart';
import 'package:mennyiment/menti_collection_model.dart';
import 'package:mennyiment/menti_animation_controller.dart';
import 'package:mennyiment/menti_animation_player.dart';
import 'package:mennyiment/menti_life_events.dart';
import 'package:mennyiment/menti_motion.dart';
import 'package:mennyiment/menti_reaction_engine.dart';
import 'package:mennyiment/menti_xp_store.dart';

import 'menti_life_engine_test.dart' show fixture, FakeMentiVideo;

MentiAliveReviewCatalog review() => MentiAliveReviewCatalog.decode(
  File('tool/menti_alive/review_assets/catalog.json').readAsStringSync(),
  developerPreview: true,
);
void main() {
  test('All 252 exact slots: 0 approved, 3 review, 249 missing; girl/neutral first', () {
    final inventory = MentiStudioInventory(review: review());
    expect(inventory.slots.length, 252);
    expect(inventory.count(MentiStudioStatus.approved), 0);
    expect(inventory.count(MentiStudioStatus.reviewRequired), 3);
    expect(inventory.count(MentiStudioStatus.missing), 249);
    expect(
      MentiStudioInventory.looks.take(6).every((v) => v.family == 'girl'),
      true,
    );
    expect(
      MentiStudioInventory.looks
          .skip(6)
          .take(6)
          .every((v) => v.family == 'neutral'),
      true,
    );
    for (final slot in inventory.slots) {
      if (slot.clip != null) {
        expect(slot.clip!.lookId, slot.look.id);
        expect(slot.clip!.reaction, slot.reaction);
        expect(slot.clip!.playable, false);
      }
    }
  });
  test('Every girl/neutral/boy reaction selects its own approved media, never another look', () {
    final clips = [
      for (final look in CompleteLook.all)
        for (final r in MentiLifeReaction.values)
          fixture(id: '${look.id}-${r.name}', look: look.id, reaction: r.name),
    ];
    final prod = MentiAnimationCatalog(clips);
    final inventory = MentiStudioInventory(production: prod, review: review());
    expect(inventory.count(MentiStudioStatus.approved), 252);
    for (final slot in inventory.slots) {
      expect(slot.clip!.id, '${slot.look.id}-${slot.reaction.name}');
      expect(slot.clip!.playable, true);
    }
    expect(
      const MentiAnimationCatalog().find(
        'girl-base-v1',
        MentiLifeReaction.welcome,
      ),
      isNull,
    );
    expect(
      MentiAnimationCatalog(review().clips)
          .find('boy-festival-v1', MentiLifeReaction.welcome),
      isNull,
    );
  });
  test('Approved exact slot wins over review; ordinary catalog cannot activate candidates', () {
    final approved = fixture(look: 'boy-festival-v1');
    final adapter = MentiStudioPlaybackCatalog(
      MentiAnimationCatalog([approved]),
      review(),
    );
    expect(
      adapter.find('boy-festival-v1', MentiLifeReaction.welcome),
      same(approved),
    );
    for (final look in CompleteLook.all.where(
      (v) => v.id != 'boy-festival-v1',
    )) {
      for (final r in MentiLifeReaction.values) {
        expect(adapter.find(look.id, r), isNull);
      }
    }
  });
  test('Non-level XP event follows persistence exactly once; no migration or extra XP', () async {
    SharedPreferences.setMockInitialValues({
      MentiXpStore.currentKey:
          '{"xp":100,"days":[],"completed":[],"future":"keep"}',
    });
    final signals = <MentiLifeSignal>[];
    void listener() => signals.add(MentiLifeEvents.instance.last!);
    MentiLifeEvents.instance.addListener(listener);
    addTearDown(() => MentiLifeEvents.instance.removeListener(listener));
    final day = DateTime(2026, 11, 16);
    expect((await MentiXpStore.checkInToday(now: day)).xp, 110);
    expect(signals.single.event, MentiLifeEvent.xpEarned);
    expect((await MentiXpStore.checkInToday(now: day)).xp, 110);
    await MentiXpStore.load();
    expect(signals.length, 1);
    expect(
      jsonDecode(
        (await SharedPreferences.getInstance()).getString(
          MentiXpStore.currentKey,
        )!,
      )['future'],
      'keep',
    );
  });
  test('A REVIEW asset/hash cannot be assigned to another character', () {
    final data = jsonDecode(
      File('tool/menti_alive/review_assets/catalog.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    final wrong = Map<String, dynamic>.from(data['clips'][0] as Map)
      ..['id'] = 'other-look'
      ..['lookId'] = 'girl-base-v1';
    (data['clips'] as List).add(wrong);
    expect(
      () => MentiAliveReviewCatalog.decode(
        jsonEncode(data),
        developerPreview: true,
      ),
      throwsFormatException,
    );
    expect(
      MentiStudioInventory(production: review())
          .count(MentiStudioStatus.approved),
      0,
    );
  });
  test('A source Higgsfield job cannot be reused for another Menti look', () {
    final data = jsonDecode(
      File('tool/menti_alive/review_assets/catalog.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    final original = Map<String, dynamic>.from(data['clips'][0] as Map);
    final other = Map<String, dynamic>.from(original)
      ..['id'] = 'cross-look-job-reuse'
      ..['lookId'] = 'girl-base-v1'
      ..['asset'] = 'assets/menti_life/clips/alive-review-other-v1.mp4'
      ..['sha256'] = 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
    (data['clips'] as List).add(other);
    expect(
      () => MentiAliveReviewCatalog.decode(
        jsonEncode(data),
        developerPreview: true,
      ),
      throwsFormatException,
    );
  });
  for (final lang in ['hu', 'en']) {
    for (final width in [320.0, 360.0, 390.0, 430.0]) {
      testWidgets(
        '$lang $width 200% Studio selects all 18, lists all 14, writes nothing',
        (t) async {
          await t.binding.setSurfaceSize(Size(width, 844));
          addTearDown(() => t.binding.setSurfaceSize(null));
          final preserved = <String, Object>{
            'mennyiment_drinks_v1': 'unknown historical journal',
            MentiXpStore.currentKey: 'future XP',
            'mennyiment_identity_v22': 'future identity',
          };
          SharedPreferences.setMockInitialValues(preserved);
          final c = MentiAnimationController(
            verify: (_) async {},
            factory: (_) => FakeMentiVideo(),
          );
          await t.pumpWidget(
            MaterialApp(
              locale: Locale(lang),
              supportedLocales: AppLocalizations.supportedLocales,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              home: MediaQuery(
                data: MediaQueryData(
                  size: Size(width, 844),
                  textScaler: TextScaler.linear(2),
                ),
                child: MentiMotionScope(
                  child: MentiAlivePreviewPage(
                    developerPreview: true,
                    studioMode: true,
                    controller: c,
                    reviewCatalog: review(),
                    readPreferences: false,
                  ),
                ),
              ),
            ),
          );
          await t.pumpAndSettle();
          expect(
            t
                .widget<MentiAnimationPlayer>(find.byType(MentiAnimationPlayer))
                .look
                .id,
            'girl-base-v1',
          );
          for (final family in MentiStudioInventory.families) {
            final chip = find.byKey(ValueKey('studio-family-$family'));
            await t.ensureVisible(chip);
            await t.tap(chip);
            await t.pumpAndSettle();
            for (final look in CompleteLook.all.where(
              (x) => x.family == family,
            )) {
              t
                  .widget<DropdownButtonFormField<String>>(
                    find.byType(DropdownButtonFormField<String>),
                  )
                  .onChanged!(look.id);
              await t.pumpAndSettle();
              expect(
                t
                    .widget<MentiAnimationPlayer>(
                      find.byType(MentiAnimationPlayer),
                    )
                    .look
                    .id,
                look.id,
              );
              for (final reaction in MentiLifeReaction.values) {
                expect(
                  find.byKey(ValueKey('studio-slot-${reaction.name}')),
                  findsOneWidget,
                );
                final play = t.widget<FilledButton>(
                  find.byKey(ValueKey('alive-play-${reaction.name}')),
                );
                expect(
                  play.onPressed != null,
                  review().find(look.id, reaction) != null,
                  reason:
                      '${look.id}/${reaction.name} status=${c.status} clips=${c.catalog.clips.length}',
                );
              }
            }
          }
          final toggle = find.byKey(const ValueKey('alive-enabled'));
          t.widget<SwitchListTile>(toggle).onChanged!(false);
          await t.pumpAndSettle();
          expect(c.handle, isNull);
          for (final r in MentiLifeReaction.values) {
            expect(
              t
                  .widget<FilledButton>(
                    find.byKey(ValueKey('alive-play-${r.name}')),
                  )
                  .onPressed,
              isNull,
            );
          }
          final p = await SharedPreferences.getInstance();
          expect({for (final k in p.getKeys()) k: p.get(k)}, preserved);
          expect(t.takeException(), isNull);
          await t.pumpWidget(const SizedBox.shrink());
          await t.pumpAndSettle();
          c.dispose();
          await t.runAsync(() => c.settled);
        },
      );
    }
  }
  for (final lang in ['hu', 'en']) {
    testWidgets(
      '$lang seven Studio event simulations never emit global events or write data',
      (t) async {
        SharedPreferences.setMockInitialValues({
          'mennyiment_drinks_v1': 'raw journal',
          'mennyiment_menti_xp_v2': 'raw XP',
        });
        final p = await SharedPreferences.getInstance();
        final before = {for (final k in p.getKeys()) k: p.get(k)};
        final globalBefore = MentiLifeEvents.instance.last;
        var allocations = 0;
        final c = MentiAnimationController(
          verify: (_) async {},
          factory: (_) {
            allocations++;
            return FakeMentiVideo();
          },
        );
        await t.pumpWidget(
          MaterialApp(
            locale: Locale(lang),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: MentiMotionScope(
              child: MentiAlivePreviewPage(
                studioMode: true,
                developerPreview: true,
                readPreferences: false,
                reviewCatalog: review(),
                controller: c,
              ),
            ),
          ),
        );
        await t.pumpAndSettle();
        t
            .widget<ChoiceChip>(find.byKey(const ValueKey('studio-family-boy')))
            .onSelected!(true);
        await t.pumpAndSettle();
        t
            .widget<DropdownButtonFormField<String>>(
              find.byType(DropdownButtonFormField<String>),
            )
            .onChanged!('boy-festival-v1');
        await t.pumpAndSettle();
        final exp = find.byKey(const ValueKey('studio-events'));
        await t.ensureVisible(exp);
        await t.tap(exp);
        await t.pumpAndSettle();
        for (final event in [
          MentiLifeEvent.journalSaved,
          MentiLifeEvent.xpEarned,
          MentiLifeEvent.xpMilestone,
          MentiLifeEvent.lookUnlocked,
          MentiLifeEvent.accessoryUnlocked,
          MentiLifeEvent.taskCompleted,
          MentiLifeEvent.encouragementRequested,
        ]) {
          final f = find.byKey(ValueKey('studio-event-${event.name}'));
          t.widget<IconButton>(f).onPressed!();
          await t.pumpAndSettle();
          await t.runAsync(() => c.settled);
          await t.pump();
          if (event == MentiLifeEvent.xpMilestone) {
            expect(c.active?.reaction, MentiLifeReaction.congratulation);
          } else {
            expect(c.active, isNull);
          }
          expect(MentiLifeEvents.instance.last, same(globalBefore));
          expect({for (final k in p.getKeys()) k: p.get(k)}, before);
          c.stop();
          await t.runAsync(() => c.settled);
          await t.pumpAndSettle();
        }
        expect(allocations, 1);
        await t.pumpWidget(const SizedBox.shrink());
        await t.pumpAndSettle();
        c.dispose();
        await t.runAsync(() => c.settled);
        expect(t.takeException(), isNull);
      },
    );
  }
}
