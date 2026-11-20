import 'menti_life_events.dart';

enum MentiLifeReaction {
  welcome,
  blink,
  wink,
  smile,
  joy,
  congratulation,
  victoryDance,
  thinking,
  surprise,
  encouragement,
  empathy,
  breathing,
  rest,
  milestone,
}

enum MentiAnimationFrequency { low, normal, frequent }

class MentiReactionPlan {
  const MentiReactionPlan(this.reaction, this.priority);
  final MentiLifeReaction reaction;
  final int priority;
}

class MentiReactionEngine {
  final Set<String> _seen = {};
  DateTime? _lastAutomatic;
  static MentiReactionPlan plan(MentiLifeEvent event) => switch (event) {
    MentiLifeEvent.xpEarned => const MentiReactionPlan(
      MentiLifeReaction.joy,
      25,
    ),
    MentiLifeEvent.accessoryUnlocked => const MentiReactionPlan(
      MentiLifeReaction.surprise,
      65,
    ),
    MentiLifeEvent.encouragementRequested => const MentiReactionPlan(
      MentiLifeReaction.encouragement,
      30,
    ),
    MentiLifeEvent.appOpened => const MentiReactionPlan(
      MentiLifeReaction.welcome,
      10,
    ),
    MentiLifeEvent.journalSaved => const MentiReactionPlan(
      MentiLifeReaction.smile,
      10,
    ),
    MentiLifeEvent.checkInSaved => const MentiReactionPlan(
      MentiLifeReaction.encouragement,
      30,
    ),
    MentiLifeEvent.goalReached => const MentiReactionPlan(
      MentiLifeReaction.milestone,
      70,
    ),
    MentiLifeEvent.xpMilestone => const MentiReactionPlan(
      MentiLifeReaction.congratulation,
      60,
    ),
    MentiLifeEvent.lookUnlocked => const MentiReactionPlan(
      MentiLifeReaction.joy,
      65,
    ),
    MentiLifeEvent.selfControlCompleted => const MentiReactionPlan(
      MentiLifeReaction.breathing,
      80,
    ),
    MentiLifeEvent.difficultDay => const MentiReactionPlan(
      MentiLifeReaction.empathy,
      90,
    ),
    MentiLifeEvent.eveningSaved => const MentiReactionPlan(
      MentiLifeReaction.rest,
      50,
    ),
    MentiLifeEvent.taskCompleted => const MentiReactionPlan(
      MentiLifeReaction.encouragement,
      40,
    ),
  };
  bool accept(
    String token,
    DateTime now,
    MentiAnimationFrequency frequency, {
    bool manual = false,
    bool urgent = false,
  }) {
    if (!manual && _seen.contains(token)) return false;
    final seconds = switch (frequency) {
      MentiAnimationFrequency.low => 120,
      MentiAnimationFrequency.normal => 30,
      MentiAnimationFrequency.frequent => 10,
    };
    if (!manual &&
        !urgent &&
        _lastAutomatic != null &&
        now.difference(_lastAutomatic!).inSeconds < seconds) {
      return false;
    }
    if (!manual) {
      _seen.add(token);
      if (_seen.length > 128) _seen.remove(_seen.first);
      _lastAutomatic = now;
    }
    return true;
  }
}
