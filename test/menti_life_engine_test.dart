import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mennyiment/menti_animation_catalog.dart';
import 'package:mennyiment/menti_animation_controller.dart';
import 'package:mennyiment/menti_reaction_engine.dart';
import 'package:mennyiment/menti_collection_model.dart';
import 'package:mennyiment/menti_life_events.dart';

Map<String, dynamic> clipJson({
  String id = 'welcome',
  String look = 'boy-base-v1',
  String reaction = 'welcome',
}) => {
  'id': id,
  'lookId': look,
  'reaction': reaction,
  'asset': 'assets/menti_life/clips/$id.mp4',
  'sha256': 'a' * 64,
  'bytes': 100,
  'durationMs': 1000,
  'width': 180,
  'height': 240,
  'version': 1,
  'approvedBy': 'synthetic-test-fixture',
  'approvedAt': '2026-11-14',
  'rightsVerified': true,
  'identityVerified': true,
  'backgroundApproved': true,
  'audio': false,
};
MentiAnimationClip fixture({
  String id = 'welcome',
  String look = 'boy-base-v1',
  String reaction = 'welcome',
}) => MentiAnimationClip.fromJson(
  clipJson(id: id, look: look, reaction: reaction),
);

class FakeMentiVideo extends MentiVideoHandle {
  FakeMentiVideo({
    this.initializeGate,
    this.closeGate,
    this.initializeError = false,
    this.playError = false,
    this.onOpen,
    this.onClose,
  }) {
    onOpen?.call();
  }
  final Completer<void>? initializeGate, closeGate;
  final bool initializeError, playError;
  final VoidCallback? onOpen, onClose;
  bool closed = false, playing = false, error = false, done = false;
  int muteCalls = 0;
  @override
  bool get frameVisible => playing && !closed;
  @override
  bool get completed => done;
  @override
  bool get failed => error;
  @override
  Widget get view => const ColoredBox(
    key: ValueKey('real-video-test-surface'),
    color: Colors.purple,
  );
  @override
  Future<void> initialize() async {
    await initializeGate?.future;
    if (initializeError) throw StateError('decode failed');
  }

  @override
  Future<void> playMuted() async {
    muteCalls++;
    if (playError) throw StateError('autoplay failed');
    playing = true;
    notifyListeners();
  }

  @override
  Future<void> close() async {
    await closeGate?.future;
    if (!closed) {
      closed = true;
      playing = false;
      onClose?.call();
      super.dispose();
    }
  }

  void fail() {
    error = true;
    notifyListeners();
  }

  void finish() {
    done = true;
    notifyListeners();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('All 18 stable IDs have 14 exact-look reaction slots, no fake approved clip', () {
    final c = MentiAnimationCatalog.decode('{"version":1,"clips":[]}');
    expect(CompleteLook.all.length, 18);
    expect(MentiLifeReaction.values.length, 14);
    for (final l in CompleteLook.all) {
      for (final r in MentiLifeReaction.values) {
        expect(c.find(l.id, r), isNull);
      }
    }
  });
  test(
    'Only approved, reviewed offline exact-look media can enter catalog',
    () {
      final accepted = clipJson();
      expect(
        MentiAnimationCatalog.decode(
          jsonEncode({
            'version': 1,
            'clips': [accepted],
          }),
        ).clips.length,
        1,
      );
      final bad = [
        {'lookId': 'missing'},
        {'asset': 'https://example.com/x.mp4'},
        {'asset': 'assets/menti_life/clips/../x.mp4'},
        {'rightsVerified': false},
        {'identityVerified': false},
        {'backgroundApproved': false},
        {'approvedBy': ''},
        {'audio': true},
        {'bytes': 7 * 1024 * 1024},
        {'durationMs': 9000},
        {'width': 1920},
        {'sha256': 'x'},
        {'version': 0},
        {'reaction': 'unknown'},
      ];
      for (final change in bad) {
        expect(
          () => MentiAnimationCatalog.decode(
            jsonEncode({
              'version': 1,
              'clips': [
                {...accepted, ...change},
              ],
            }),
          ),
          throwsFormatException,
          reason: change.toString(),
        );
      }
      expect(
        () => MentiAnimationCatalog.decode(
          jsonEncode({
            'version': 2,
            'clips': [accepted],
          }),
        ),
        throwsFormatException,
      );
      expect(
        () => MentiAnimationCatalog.decode(
          jsonEncode({
            'version': 1,
            'clips': [accepted, accepted],
          }),
        ),
        throwsFormatException,
      );
    },
  );
  test(
    'Frequency, priority override and duplicate evidence are independent',
    () {
      final e = MentiReactionEngine(), now = DateTime(2026, 11, 14);
      expect(e.accept('one', now, MentiAnimationFrequency.low), true);
      expect(
        e.accept(
          'two',
          now.add(const Duration(seconds: 119)),
          MentiAnimationFrequency.low,
        ),
        false,
      );
      expect(
        e.accept(
          'urgent',
          now.add(const Duration(seconds: 1)),
          MentiAnimationFrequency.low,
          urgent: true,
        ),
        true,
      );
      expect(
        e.accept(
          'urgent',
          now.add(const Duration(minutes: 10)),
          MentiAnimationFrequency.low,
          urgent: true,
        ),
        false,
      );
      expect(
        e.accept('manual', now, MentiAnimationFrequency.low, manual: true),
        true,
      );
      expect(
        e.accept('manual', now, MentiAnimationFrequency.low, manual: true),
        true,
      );
      expect(
        MentiReactionEngine.plan(MentiLifeEvent.journalSaved).reaction,
        MentiLifeReaction.smile,
      );
      expect(
        MentiReactionEngine.plan(MentiLifeEvent.difficultDay).priority,
        greaterThan(
          MentiReactionEngine.plan(MentiLifeEvent.journalSaved).priority,
        ),
      );
    },
  );
  MentiAnimationController make(
    List<MentiAnimationClip> clips,
    MentiVideoHandle Function(MentiAnimationClip) factory,
  ) => MentiAnimationController(
    catalog: MentiAnimationCatalog(clips),
    factory: factory,
    verify: (_) async {},
  );
  void mount(MentiAnimationController c, String look) {
    c.configure(
      look: look,
      allowed: true,
      frequency: MentiAnimationFrequency.normal,
    );
    c.host('visible', look: look, size: 200, visible: true);
  }

  Future<void> close(MentiAnimationController c) async {
    c.dispose();
    await c.settled;
  }

  test('Wrong look and missing media never allocate a decoder or use another mascot', () async {
    var creates = 0;
    final c = make([fixture()], (_) {
      creates++;
      return FakeMentiVideo();
    });
    mount(c, 'girl-base-v1');
    expect(
      c.request(MentiLifeReaction.welcome, token: 'x', manual: true),
      false,
    );
    await c.settled;
    expect(creates, 0);
    expect(c.status, MentiPlaybackStatus.noClip);
    expect(c.active, isNull);
    await close(c);
  });
  test('Lower priority drops; higher priority closes old decoder before starting, muted once', () async {
    final handles = <FakeMentiVideo>[];
    var live = 0, maxLive = 0;
    final c = make([fixture(), fixture(id: 'empathy', reaction: 'empathy')], (
      _,
    ) {
      final h = FakeMentiVideo(
        onOpen: () {
          live++;
          if (live > maxLive) maxLive = live;
        },
        onClose: () => live--,
      );
      handles.add(h);
      return h;
    });
    mount(c, 'boy-base-v1');
    expect(
      c.request(MentiLifeReaction.welcome, token: 'one', priority: 10),
      true,
    );
    await c.settled;
    expect(
      c.request(MentiLifeReaction.welcome, token: 'double', priority: 5),
      false,
    );
    expect(
      c.request(MentiLifeReaction.empathy, token: 'hard-day', priority: 90),
      true,
    );
    await c.settled;
    expect(maxLive, 1);
    expect(handles.first.closed, true);
    expect(handles.last.muteCalls, 1);
    expect(c.status, MentiPlaybackStatus.playing);
    handles.last.finish();
    await c.settled;
    expect(c.active, isNull);
    expect(live, 0);
    await close(c);
  });
  test('Character switch during initialize disposes late result and never renders it', () async {
    final gate = Completer<void>();
    final h = FakeMentiVideo(initializeGate: gate);
    final c = make([fixture()], (_) => h);
    mount(c, 'boy-base-v1');
    c.request(MentiLifeReaction.welcome, token: 'one');
    await Future<void>.delayed(Duration.zero);
    c.configure(
      look: 'girl-base-v1',
      allowed: true,
      frequency: MentiAnimationFrequency.normal,
    );
    gate.complete();
    await c.settled;
    expect(h.closed, true);
    expect(h.muteCalls, 0);
    expect(c.active, isNull);
    await close(c);
  });
  for (final failure in ['hash', 'initialize', 'play', 'stream']) {
    test(
      '$failure failure returns to original PNG and releases handle',
      () async {
        final h = FakeMentiVideo(
          initializeError: failure == 'initialize',
          playError: failure == 'play',
        );
        final c = MentiAnimationController(
          catalog: MentiAnimationCatalog([fixture()]),
          factory: (_) => h,
          verify: (_) async {
            if (failure == 'hash') throw StateError('bad bytes');
          },
        );
        mount(c, 'boy-base-v1');
        c.request(MentiLifeReaction.welcome, token: 'one', manual: true);
        await c.settled;
        if (failure == 'stream') {
          h.fail();
          await c.settled;
        }
        expect(c.active, isNull);
        expect(c.status, MentiPlaybackStatus.error);
        if (failure != 'hash') expect(h.closed, true);
        await close(c);
      },
    );
  }
  test('Disabled/reduced policy, invisible host and background stop without automatic replay', () async {
    final c = make([fixture()], (_) => FakeMentiVideo());
    mount(c, 'boy-base-v1');
    c.request(MentiLifeReaction.welcome, token: 'one', manual: true);
    await c.settled;
    final h = c.handle as FakeMentiVideo;
    c.foreground(false);
    await c.settled;
    expect(h.closed, true);
    expect(
      c.request(MentiLifeReaction.welcome, token: 'two', manual: true),
      false,
    );
    c.foreground(true);
    expect(c.active, isNull);
    c.configure(
      look: 'boy-base-v1',
      allowed: false,
      frequency: MentiAnimationFrequency.normal,
    );
    expect(
      c.request(MentiLifeReaction.welcome, token: 'three', manual: true),
      false,
    );
    c.configure(
      look: 'boy-base-v1',
      allowed: true,
      frequency: MentiAnimationFrequency.normal,
    );
    c.removeHost('visible');
    expect(
      c.request(MentiLifeReaction.welcome, token: 'four', manual: true),
      false,
    );
    await close(c);
  });
  test('Global decoder lease waits for previous root disposal before allocating next', () async {
    final release = Completer<void>();
    var opened = 0;
    final first = FakeMentiVideo(closeGate: release);
    final a = make([fixture()], (_) => first),
        b = make([fixture()], (_) {
          opened++;
          return FakeMentiVideo();
        });
    mount(a, 'boy-base-v1');
    mount(b, 'boy-base-v1');
    a.request(MentiLifeReaction.welcome, token: 'a', manual: true);
    await a.settled;
    b.request(MentiLifeReaction.welcome, token: 'b', manual: true);
    await Future<void>.delayed(Duration.zero);
    expect(opened, 0);
    release.complete();
    await b.settled;
    expect(opened, 1);
    expect(first.closed, true);
    expect(a.active, isNull);
    await close(a);
    await close(b);
  });
  test(
    'Superseded pending requests do not allocate multiple players',
    () async {
      final gate = Completer<void>();
      var created = 0;
      final c = make([fixture(), fixture(id: 'wink', reaction: 'wink')], (_) {
        created++;
        return FakeMentiVideo(initializeGate: created == 1 ? gate : null);
      });
      mount(c, 'boy-base-v1');
      c.request(MentiLifeReaction.welcome, token: 'one', manual: true);
      await Future<void>.delayed(Duration.zero);
      c.request(MentiLifeReaction.wink, token: 'two', manual: true);
      c.stop();
      gate.complete();
      await c.settled;
      expect(created, 1);
      expect(c.active, isNull);
      await close(c);
    },
  );
  test(
    'Stalled initialization times out, releases decoder and keeps PNG',
    () async {
      final gate = Completer<void>();
      final media = FakeMentiVideo(initializeGate: gate);
      final c = make([fixture()], (_) => media);
      mount(c, 'boy-base-v1');
      expect(
        c.request(MentiLifeReaction.welcome, token: 'timeout', manual: true),
        true,
      );
      await c.settled;
      expect(c.status, MentiPlaybackStatus.error);
      expect(c.handle, isNull);
      expect(media.closed, true);
      gate.complete();
      await Future<void>.delayed(Duration.zero);
      expect(c.active, isNull);
      await close(c);
    },
  );
}
