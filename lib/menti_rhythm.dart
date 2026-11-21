import 'dart:math';

enum RhythmAction { stretch, left, right }

enum RhythmPhase { demonstration, input, mistake, finished }

/// One ephemeral game, five rounds of length 3..7. No persistence or rewards.
class MentiRhythm {
  MentiRhythm({Random? random}) : _random = random ?? Random() {
    restart();
  }
  final Random _random;
  final List<RhythmAction> _sequence = [];
  List<RhythmAction> get sequence => List.unmodifiable(_sequence);
  RhythmPhase phase = RhythmPhase.demonstration;
  int completed = 0, shown = 0, entered = 0;
  int get round => completed + 1;
  RhythmAction get highlighted => _sequence[shown];
  void restart() {
    completed = shown = entered = 0;
    _sequence.clear();
    for (var i = 0; i < 3; i++) {
      _append();
    }
    phase = RhythmPhase.demonstration;
  }

  void _append() => _sequence.add(RhythmAction.values[_random.nextInt(3)]);
  void next() {
    if (phase != RhythmPhase.demonstration) return;
    if (shown + 1 < _sequence.length) {
      shown++;
    } else {
      phase = RhythmPhase.input;
      entered = 0;
    }
  }

  void press(RhythmAction action) {
    if (phase != RhythmPhase.input) return;
    if (_sequence[entered] != action) {
      phase = RhythmPhase.mistake;
      return;
    }
    entered++;
    if (entered < _sequence.length) return;
    completed++;
    if (completed == 5) {
      phase = RhythmPhase.finished;
      return;
    }
    _append();
    shown = entered = 0;
    phase = RhythmPhase.demonstration;
  }

  void retry() {
    if (phase != RhythmPhase.mistake) return;
    shown = entered = 0;
    phase = RhythmPhase.demonstration;
  }
}
