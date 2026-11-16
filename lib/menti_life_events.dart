import 'package:flutter/foundation.dart';

/// Ephemeral presentation events only. No notes, quantities, names or new XP.
enum MentiLifeEvent {
  appOpened,
  journalSaved,
  checkInSaved,
  goalReached,
  xpMilestone,
  lookUnlocked,
  selfControlCompleted,
  difficultDay,
  eveningSaved,
  taskCompleted,
  xpEarned,
  accessoryUnlocked,
  encouragementRequested,
}

class MentiLifeSignal {
  const MentiLifeSignal(this.event, this.token);
  final MentiLifeEvent event;
  final String token;
}

class MentiLifeEvents extends ChangeNotifier {
  static final instance = MentiLifeEvents();
  MentiLifeSignal? last;
  int _sequence = 0;
  void emit(MentiLifeEvent event, {String? token}) {
    last = MentiLifeSignal(event, token ?? 'session-event-${++_sequence}');
    notifyListeners();
  }
}
