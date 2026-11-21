import 'dart:async';

import 'package:flutter/foundation.dart';

import 'menti_animation_controller.dart';
import 'menti_life_events.dart';
import 'menti_reaction_engine.dart';

/// Ephemeral application-session state. No preferences, XP or journal writes.
/// Signals from a save are coalesced while its route is open, then the highest
/// priority signal is presented once on return. Old-character events are dropped.
class MentiHomeReactions extends ChangeNotifier {
  MentiAnimationController? _controller;
  bool _homeVisible = false, _ready = true;
  void ready(bool value) {
    _ready = value;
  }

  void visibility(bool value) {
    _homeVisible = value;
    refresh();
  }

  bool _welcomed = false, _disposed = false;
  String? _look;
  MentiLifeSignal? _pending;
  Timer? _batch;
  DateTime? _lastTap;
  final Set<String> _seen = {};
  MentiLifeEvent? event;
  bool wink = false;
  int presentations = 0;
  void attach(MentiAnimationController controller, {bool ready = true}) {
    _controller = controller;
    _ready = ready;
  }

  void detach() {
    _batch?.cancel();
    _controller = null;
  }

  void refresh() {
    final c = _controller;
    if (c == null || !_ready) return;
    if (_look != c.lookId) {
      _look = c.lookId;
      _pending = null;
      event = null;
      wink = false;
      _notify();
    }
    if (!c.hasVisibleHost && !(_homeVisible && c.lookId != null)) return;
    if (_pending != null) {
      _schedule();
    } else if (!_welcomed) {
      _welcomed = true;
      _show(const MentiLifeSignal(MentiLifeEvent.appOpened, 'home-welcome'));
    }
  }

  void receive(MentiLifeSignal signal) {
    if (_controller == null || _look == null || _seen.contains(signal.token)) {
      return;
    }
    _seen.add(signal.token);
    if (_seen.length > 128) _seen.remove(_seen.first);
    final old = _pending;
    if (old == null ||
        MentiReactionEngine.plan(signal.event).priority >=
            MentiReactionEngine.plan(old.event).priority) {
      _pending = signal;
    }
    _schedule();
  }

  void _schedule() {
    _batch?.cancel();
    _batch = Timer(const Duration(milliseconds: 100), () {
      final c = _controller;
      if (c == null ||
          (!c.hasVisibleHost && !_homeVisible) ||
          _pending == null) {
        return;
      }
      final signal = _pending!;
      _pending = null;
      _welcomed = true;
      _show(signal);
    });
  }

  void _show(MentiLifeSignal signal) {
    event = signal.event;
    wink = false;
    presentations++;
    // Stop any previous reaction even when the new exact slot has no media.
    _controller!.stop();
    _controller!.react(signal);
    _notify();
  }

  void requestWink({DateTime? now}) {
    final c = _controller;
    if (c == null) return;
    final at = now ?? DateTime.now();
    if (_lastTap != null &&
        at.difference(_lastTap!) < const Duration(milliseconds: 600)) {
      return;
    }
    _lastTap = at;
    wink = true;
    event = null;
    presentations++;
    c.request(
      MentiLifeReaction.wink,
      token: 'home-tap-$presentations',
      manual: true,
    );
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    detach();
    super.dispose();
  }
}
