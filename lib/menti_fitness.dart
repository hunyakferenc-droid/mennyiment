import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_language.dart';
import 'menti_collection_widgets.dart';
import 'menti_collection_model.dart';
import 'menti_identity/menti_identity_controller.dart';
import 'menti_identity/menti_avatar_renderer.dart';
import 'menti_rhythm.dart';
import 'menti_club_store.dart';
import 'menti_movement_cards.dart';

import 'package:intl/intl.dart';

class MentiFitnessArtwork extends StatelessWidget {
  const MentiFitnessArtwork({super.key});
  @override
  Widget build(BuildContext context) {
    final complete = CompleteLookScope.of(context);
    final identity = MentiIdentityScope.of(context);
    if (complete?.ready == true && complete!.selection.active) {
      final look = CompleteLook.find(complete.selection.lookId);
      if (look != null) {
        return CompleteLookArtwork(look: look, size: 120, background: false);
      }
    }
    if (identity != null) {
      return MentiAvatarRenderer(
        profile: identity.profile,
        size: 120,
        showBackground: false,
      );
    }
    return Image.asset(
      'assets/images/menti_open.png',
      width: 120,
      height: 160,
      fit: BoxFit.contain,
    );
  }
}

class MentiFitnessClub extends StatefulWidget {
  const MentiFitnessClub({super.key, this.store, this.testMode = false});
  final MentiClubStore? store;
  final bool testMode;
  @override
  State<MentiFitnessClub> createState() => _ClubState();
}

class _ClubState extends State<MentiFitnessClub> with WidgetsBindingObserver {
  DateTime _testDay = DateTime(2030, 1, 1);
  late final store =
      widget.store ??
      MentiClubStore(
        key: widget.testMode
            ? MentiClubStore.testKey
            : MentiClubStore.normalKey,
        clock: widget.testMode ? () => _testDay : null,
      );
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
  }

  Future<void> _load() async {
    await store.load();
    if (widget.testMode && store.record.last != null) {
      final last = parseClubDay(store.record.last!);
      if (last.isAfter(_testDay)) _testDay = last;
    }
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (widget.store == null) store.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _load();
  }

  @override
  Widget build(BuildContext context) {
    final s = appStrings(context);
    String date(String value) =>
        DateFormat.yMMMd(s.localeName).format(parseClubDay(value));
    return Scaffold(
      appBar: AppBar(title: Text(s.fitnessTitle)),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: ListenableBuilder(
              listenable: store,
              builder: (context, _) => ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (widget.testMode)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(s.clubTestNotice),
                            Text(
                              s.clubTestDate(date(clubDay(_testDay))),
                              key: const ValueKey('club-test-date'),
                            ),
                            OutlinedButton(
                              key: const ValueKey('club-next-day'),
                              onPressed: store.saving
                                  ? null
                                  : () => setState(
                                      () => _testDay = DateTime(
                                        _testDay.year,
                                        _testDay.month,
                                        _testDay.day + 1,
                                      ),
                                    ),
                              child: Text(s.clubNextDay),
                            ),
                          ],
                        ),
                      ),
                    ),
                  const Center(child: MentiFitnessArtwork()),
                  Text(
                    s.clubChallengeTitle,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 12),
                  Text(s.clubChallengeHint),
                  if (!store.ready) ...[
                    Text(store.error == null ? s.clubSaving : s.clubLoadError),
                    OutlinedButton(
                      key: const ValueKey('club-reload'),
                      onPressed: store.saving ? null : _load,
                      child: Text(s.homeRetryProgress),
                    ),
                  ] else ...[
                    Text(
                      s.clubBest(store.record.best),
                      key: const ValueKey('club-best'),
                    ),
                    Text(
                      s.clubProgress(store.record.days.length),
                      key: const ValueKey('club-progress'),
                    ),
                    Text(
                      store.record.last == null
                          ? s.clubNoCompletion
                          : s.clubLast(date(store.record.last!)),
                      key: const ValueKey('club-last'),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (var i = 0; i < 7; i++)
                          Semantics(
                            key: ValueKey('club-day-$i'),
                            checked: i < store.record.days.length,
                            readOnly: true,
                            label: i < store.record.days.length
                                ? s.clubDayDate(
                                    i + 1,
                                    date(store.record.days[i]),
                                  )
                                : s.clubDayPending(i + 1),
                            child: ExcludeSemantics(
                              child: Container(
                                width: double.infinity,
                                constraints: const BoxConstraints(
                                  minHeight: 48,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .surfaceContainerHigh,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Theme.of(context).colorScheme.primary
                                        .withValues(alpha: .35),
                                  ),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(
                                      i < store.record.days.length
                                          ? Icons.check_circle
                                          : Icons.radio_button_unchecked,
                                      size: 20,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primary,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        i < store.record.days.length
                                            ? s.clubDayDate(
                                                i + 1,
                                                date(store.record.days[i]),
                                              )
                                            : s.clubDayPending(i + 1),
                                        softWrap: true,
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelLarge,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    if (store.record.days.length == 7)
                      FilledButton(
                        key: const ValueKey('club-new-challenge'),
                        onPressed: store.saving
                            ? null
                            : () async {
                                await store.newChallenge();
                              },
                        child: Text(s.clubNewChallenge),
                      ),
                    if (store.error != null) Text(s.clubSaveError),
                    const SizedBox(height: 16),
                    Text(
                      s.rhythmTitle,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    Text(s.rhythmInstructions),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      key: const ValueKey('fitness-play'),
                      icon: const Icon(Icons.play_arrow),
                      label: Text(s.rhythmPlay),
                      onPressed: store.saving
                          ? null
                          : () async {
                              await Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => MentiRhythmPage(store: store),
                                ),
                              );
                              await _load();
                            },
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      key: const ValueKey('fitness-cards'),
                      icon: const Icon(Icons.accessibility_new),
                      label: Text(s.cardsTitle),
                      onPressed: store.saving
                          ? null
                          : () async {
                              await Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) =>
                                      MentiMovementCards(store: store),
                                ),
                              );
                              await _load();
                            },
                    ),
                    Text(s.clubLocalOnly),
                  ],
                  if (!widget.testMode)
                    TextButton(
                      key: const ValueKey('club-test-mode'),
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) =>
                              const MentiFitnessClub(testMode: true),
                        ),
                      ),
                      child: Text(s.clubTestMode),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class MentiRhythmPage extends StatefulWidget {
  const MentiRhythmPage({super.key, this.game, this.store});
  final MentiClubStore? store;
  final MentiRhythm? game;
  @override
  State<MentiRhythmPage> createState() => _RhythmPageState();
}

class _RhythmPageState extends State<MentiRhythmPage> {
  late final game = widget.game ?? MentiRhythm();
  final focus = FocusNode(debugLabel: 'Menti Rhythm keyboard');
  @override
  void dispose() {
    focus.dispose();
    super.dispose();
  }

  bool clubSaving = false;
  ClubSave? clubResult;
  Future<void> saveScore() async {
    if (widget.store == null || clubSaving) return;
    setState(() => clubSaving = true);
    final result = await widget.store!.rhythm(game.completed);
    if (mounted) {
      setState(() {
        clubSaving = false;
        clubResult = result;
      });
    }
  }

  void change(VoidCallback action) {
    if (clubSaving) return;
    final before = game.completed;
    setState(action);
    if (game.completed > before) saveScore();
  }

  KeyEventResult key(FocusNode node, KeyEvent event) {
    if (clubSaving || event is! KeyDownEvent) return KeyEventResult.ignored;
    final k = event.logicalKey;
    if (game.phase == RhythmPhase.demonstration &&
        (k == LogicalKeyboardKey.space || k == LogicalKeyboardKey.enter)) {
      change(game.next);
      return KeyEventResult.handled;
    }
    final action = switch (k) {
      LogicalKeyboardKey.digit1 ||
      LogicalKeyboardKey.arrowUp => RhythmAction.stretch,
      LogicalKeyboardKey.digit2 ||
      LogicalKeyboardKey.arrowLeft => RhythmAction.left,
      LogicalKeyboardKey.digit3 ||
      LogicalKeyboardKey.arrowRight => RhythmAction.right,
      _ => null,
    };
    if (action != null && game.phase == RhythmPhase.input) {
      change(() => game.press(action));
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final s = appStrings(context);
    String label(RhythmAction a) => switch (a) {
      RhythmAction.stretch => s.rhythmStretch,
      RhythmAction.left => s.rhythmLeft,
      RhythmAction.right => s.rhythmRight,
    };
    final demo = game.phase == RhythmPhase.demonstration;
    final input = game.phase == RhythmPhase.input;
    return Scaffold(
      appBar: AppBar(title: Text(s.rhythmTitle)),
      body: SafeArea(
        child: Focus(
          autofocus: true,
          focusNode: focus,
          onKeyEvent: key,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 620),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const Center(child: MentiFitnessArtwork()),
                  Semantics(
                    liveRegion: true,
                    child: Text(
                      game.phase == RhythmPhase.finished
                          ? s.rhythmResult(game.completed)
                          : s.rhythmRound(game.round),
                      key: const ValueKey('rhythm-round'),
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(s.rhythmKeyboard),
                  const SizedBox(height: 12),
                  if (demo) ...[
                    Text(
                      s.rhythmWatch(
                        game.shown + 1,
                        game.sequence.length,
                        label(game.highlighted),
                      ),
                      key: const ValueKey('rhythm-cue'),
                    ),
                    const SizedBox(height: 8),
                    FilledButton(
                      key: const ValueKey('rhythm-next'),
                      onPressed: clubSaving ? null : () => change(game.next),
                      child: Text(s.rhythmNext),
                    ),
                  ],
                  if (input)
                    Text(
                      s.rhythmYourTurn(game.entered, game.sequence.length),
                      key: const ValueKey('rhythm-input'),
                    ),
                  if (demo || input) ...[
                    const SizedBox(height: 12),
                    for (final a in RhythmAction.values)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: OutlinedButton.icon(
                          key: ValueKey('rhythm-${a.name}'),
                          onPressed: input && !clubSaving
                              ? () => change(() => game.press(a))
                              : null,
                          icon: Icon(
                            demo && game.highlighted == a
                                ? Icons.visibility
                                : switch (a) {
                                    RhythmAction.stretch =>
                                      Icons.accessibility_new,
                                    RhythmAction.left => Icons.arrow_back,
                                    RhythmAction.right => Icons.arrow_forward,
                                  },
                          ),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(48, 56),
                            side: BorderSide(
                              width: demo && game.highlighted == a ? 3 : 1,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          label: Text(
                            demo && game.highlighted == a
                                ? s.rhythmShowing(label(a))
                                : label(a),
                          ),
                        ),
                      ),
                  ],
                  if (game.phase == RhythmPhase.mistake) ...[
                    Text(s.rhythmMistake),
                    FilledButton(
                      key: const ValueKey('rhythm-retry'),
                      onPressed: clubSaving ? null : () => change(game.retry),
                      child: Text(s.rhythmRetry),
                    ),
                  ],
                  if (widget.store != null && clubSaving) Text(s.clubSaving),
                  if (widget.store != null &&
                      clubResult == ClubSave.failed) ...[
                    Text(s.clubSaveError),
                    OutlinedButton(
                      key: const ValueKey('rhythm-save-retry'),
                      onPressed: clubSaving
                          ? null
                          : () async {
                              await widget.store!.load();
                              await saveScore();
                            },
                      child: Text(s.homeRetryProgress),
                    ),
                  ],
                  if (game.phase == RhythmPhase.finished) ...[
                    if (widget.store != null &&
                        !clubSaving &&
                        clubResult != ClubSave.failed)
                      Text(
                        clubResult == ClubSave.alreadyToday
                            ? s.clubAlreadyToday
                            : clubResult == ClubSave.full
                            ? s.clubFull
                            : s.clubDaySaved,
                      ),
                    Text(
                      widget.store == null ? s.fitnessPrivacy : s.clubLocalOnly,
                    ),
                    FilledButton(
                      key: const ValueKey('rhythm-new'),
                      onPressed: clubSaving ? null : () => change(game.restart),
                      child: Text(s.rhythmNew),
                    ),
                    OutlinedButton(
                      key: const ValueKey('rhythm-club'),
                      onPressed: clubSaving
                          ? null
                          : () => Navigator.of(context).pop(),
                      child: Text(s.rhythmBack),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
