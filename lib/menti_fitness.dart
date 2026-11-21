import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_language.dart';
import 'menti_collection_widgets.dart';
import 'menti_collection_model.dart';
import 'menti_identity/menti_identity_controller.dart';
import 'menti_identity/menti_avatar_renderer.dart';
import 'menti_rhythm.dart';

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

class MentiFitnessClub extends StatelessWidget {
  const MentiFitnessClub({super.key});
  @override
  Widget build(BuildContext context) {
    final s = appStrings(context);
    return Scaffold(
      appBar: AppBar(title: Text(s.fitnessTitle)),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Center(child: MentiFitnessArtwork()),
                Text(
                  s.rhythmTitle,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 12),
                Text(s.rhythmInstructions),
                const SizedBox(height: 12),
                Text(s.fitnessPrivacy),
                const SizedBox(height: 20),
                FilledButton.icon(
                  key: const ValueKey('fitness-play'),
                  icon: const Icon(Icons.play_arrow),
                  label: Text(s.rhythmPlay),
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const MentiRhythmPage(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class MentiRhythmPage extends StatefulWidget {
  const MentiRhythmPage({super.key, this.game});
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

  void change(VoidCallback action) {
    setState(action);
  }

  KeyEventResult key(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
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
                      onPressed: () => change(game.next),
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
                          onPressed: input
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
                      onPressed: () => change(game.retry),
                      child: Text(s.rhythmRetry),
                    ),
                  ],
                  if (game.phase == RhythmPhase.finished) ...[
                    Text(s.fitnessPrivacy),
                    FilledButton(
                      key: const ValueKey('rhythm-new'),
                      onPressed: () => change(game.restart),
                      child: Text(s.rhythmNew),
                    ),
                    OutlinedButton(
                      key: const ValueKey('rhythm-club'),
                      onPressed: () => Navigator.of(context).pop(),
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
