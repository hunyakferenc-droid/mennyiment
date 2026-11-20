import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mennyiment/menti_alive_review_catalog.dart';
import 'package:mennyiment/menti_animation_catalog.dart';
import 'package:mennyiment/menti_animation_controller.dart';
import 'package:mennyiment/menti_animation_studio_model.dart';
import 'package:mennyiment/menti_collection_model.dart';
import 'package:mennyiment/menti_reaction_engine.dart';

import 'menti_life_engine_test.dart' show FakeMentiVideo;

Map<String, dynamic> studioData() {
  final original = jsonDecode(
    File('tool/menti_alive/review_assets/catalog.json').readAsStringSync(),
  ) as Map<String, dynamic>;
  final extra = jsonDecode(
    File('tool/menti_animation_studio/review_assets/catalog.json')
        .readAsStringSync(),
  ) as Map<String, dynamic>;
  return {
    ...original,
    'clips': [...original['clips'], ...extra['clips']],
  };
}

MentiAliveReviewCatalog studio() => MentiAliveReviewCatalog.decode(
  jsonEncode(studioData()),
  developerPreview: true,
);
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'Own girl and neutral source PNGs and processed videos match exact hashes',
    () {
      final data = jsonDecode(
        File('tool/menti_animation_studio/review_assets/catalog.json')
            .readAsStringSync(),
      );
      expect(data['clips'].length, 2);
      for (final c in data['clips']) {
        final look = CompleteLook.find(c['lookId'])!;
        expect(c['sourcePng'], look.asset);
        expect(
          sha256.convert(File(look.asset).readAsBytesSync()).toString(),
          c['sourcePngSha256'],
        );
        final name = (c['asset'] as String).split('/').last;
        final bytes = File('tool/menti_animation_studio/review_assets/$name')
            .readAsBytesSync();
        expect(bytes.length, c['bytes']);
        expect(sha256.convert(bytes).toString(), c['sha256']);
        for (final flag in [
          'ownerApproved',
          'identityVerified',
          'rightsVerified',
          'backgroundApproved',
        ]) {
          expect(c[flag], false);
        }
      }
    },
  );
  test('Actual combined inventory has 5 REVIEW and 247 missing, never a production clip', () {
    final c = studio();
    final i = MentiStudioInventory(review: c);
    expect(i.slots.length, 252);
    expect(i.count(MentiStudioStatus.reviewRequired), 5);
    expect(i.count(MentiStudioStatus.missing), 247);
    expect(i.count(MentiStudioStatus.approved), 0);
    final prod = MentiAnimationCatalog(c.clips);
    for (final look in CompleteLook.all) {
      for (final r in MentiLifeReaction.values) {
        expect(prod.find(look.id, r), isNull);
      }
    }
    for (final look in CompleteLook.all.where(
      (x) => ![
        'girl-base-v1',
        'neutral-base-v1',
        'boy-festival-v1',
      ].contains(x.id),
    )) {
      for (final r in MentiLifeReaction.values) {
        expect(c.find(look.id, r), isNull);
      }
    }
  });
  for (final family in ['girl', 'neutral']) {
    test(
      '$family own clip initialization error recovers by explicit restart, one decoder',
      () async {
        var allocations = 0, live = 0, maxLive = 0;
        final c = MentiAnimationController(
          catalog: studio(),
          verify: (_) async {},
          factory: (_) {
            allocations++;
            return FakeMentiVideo(
              initializeError: allocations == 1,
              onOpen: () {
                live++;
                if (live > maxLive) maxLive = live;
              },
              onClose: () => live--,
            );
          },
        );
        final host = Object();
        c.configure(
          look: '$family-base-v1',
          allowed: true,
          frequency: MentiAnimationFrequency.normal,
        );
        c.host(host, look: '$family-base-v1', size: 180, visible: true);
        final reaction = family == 'girl'
            ? MentiLifeReaction.thinking
            : MentiLifeReaction.welcome;
        expect(c.request(reaction, token: 'first', manual: true), true);
        await c.settled;
        expect(c.status, MentiPlaybackStatus.error);
        expect(c.active, isNull);
        expect(live, 0);
        expect(await c.restart(reaction, token: 'retry'), true);
        await c.settled;
        expect(c.active!.lookId, '$family-base-v1');
        expect(c.active!.reaction, reaction);
        expect(maxLive, 1);
        c.foreground(false);
        await c.settled;
        expect(c.active, isNull);
        expect(c.handle, isNull);
        c.foreground(true);
        expect(c.active, isNull);
        c.configure(
          look: '$family-party-v1',
          allowed: true,
          frequency: MentiAnimationFrequency.normal,
        );
        c.host(host, look: '$family-party-v1', size: 180, visible: true);
        expect(c.request(reaction, token: 'wrong-outfit', manual: true), false);
        expect(allocations, 2);
        c.dispose();
        await c.settled;
        expect(live, 0);
      },
    );
  }
}
