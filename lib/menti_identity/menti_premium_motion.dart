import 'dart:async';

import 'package:flutter/material.dart';

import '../menti_motion.dart';
import '../menti_experience_settings.dart';
import 'menti_identity.dart';
import 'menti_premium_renderer.dart';

/// Brief eye and smile frames, not a continuously ticking animation. Never owns
/// or mutates character data. Pauses with hidden routes, background and reduced
/// motion; previews do not mount this widget.
class MentiPremiumMotion extends StatefulWidget {
  const MentiPremiumMotion({
    super.key,
    required this.profile,
    this.reaction,
    this.showBackground = true,
  });
  final MentiIdentityProfile profile;
  final String? reaction;
  final bool showBackground;
  @override
  State<MentiPremiumMotion> createState() => _MentiPremiumMotionState();
}

class _MentiPremiumMotionState extends State<MentiPremiumMotion>
    with WidgetsBindingObserver {
  Timer? _idle, _reset;
  bool _blink = false,
      _wink = false,
      _smile = false,
      _foreground = true,
      _enabled = false,
      _presented = false;
  static const _positive = {'proud', 'celebrating', 'motivating'};
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  void _stop() {
    _idle?.cancel();
    _reset?.cancel();
    _idle = null;
    _reset = null;
    _blink = false;
    _wink = false;
    _smile = false;
  }

  void _schedule() {
    _idle?.cancel();
    if (!_enabled || !_foreground) return;
    _idle = Timer(const Duration(seconds: 7), () => _expression());
  }

  void _expression({bool wink = false, bool smile = false}) {
    if (!mounted || !_enabled || !_foreground) return;
    _idle?.cancel();
    _reset?.cancel();
    setState(() {
      _smile = smile;
      _blink = !wink && !smile;
      _wink = wink;
    });
    _reset = Timer(
      Duration(
        milliseconds: smile
            ? 900
            : wink
            ? 280
            : 140,
      ),
      () {
        if (!mounted) return;
        setState(() {
          _blink = false;
          _wink = false;
          _smile = false;
        });
        _schedule();
      },
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final enabled =
        MentiMotionScope.animateOf(context) &&
        MentiExperienceScope.reactionsOf(context);
    final first = !_presented;
    _presented = true;
    if (enabled == _enabled) return;
    _enabled = enabled;
    if (enabled) {
      if (first && _positive.contains(widget.reaction)) {
        _expression(smile: true);
      } else if (first && widget.reaction == 'funny') {
        _expression(wink: true);
      } else {
        _schedule();
      }
    } else {
      _stop();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    if (_foreground) {
      _schedule();
    } else {
      setState(_stop);
    }
  }

  @override
  void didUpdateWidget(covariant MentiPremiumMotion oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.reaction == widget.reaction) return;
    if (widget.reaction == 'focused') {
      _stop();
      _schedule();
    } else if (widget.reaction == 'funny') {
      _expression(wink: true);
    } else if (_positive.contains(widget.reaction)) {
      _expression(smile: true);
    }
  }

  @override
  void dispose() {
    _stop();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MentiPremiumComposition(
    profile: widget.profile,
    reaction: widget.reaction,
    showBackground: widget.showBackground,
    blink: _blink,
    wink: _wink,
    smile: _smile,
  );
}
