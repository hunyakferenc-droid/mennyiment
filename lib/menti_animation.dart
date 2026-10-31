
import 'dart:async';
import 'package:flutter/material.dart';
import 'menti_motion.dart';


class _AnimatedMentiFrames extends StatefulWidget {
  const _AnimatedMentiFrames({
    this.size = 230,
    this.reaction = 0,
  });

  final double size;
  final int reaction;

  @override
  State<_AnimatedMentiFrames> createState() => __AnimatedMentiFramesState();
}

class __AnimatedMentiFramesState extends State<_AnimatedMentiFrames>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _floating;

  Timer? _expressionTimer;
  Timer? _resetTimer;

  int _sequence = 0;
  String _image = 'assets/images/menti_open.png';

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);

    _floating = Tween<double>(begin: -7, end: 7).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    _expressionTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _changeExpression(),
    );
  }

@override
void didUpdateWidget(covariant _AnimatedMentiFrames oldWidget) {
  super.didUpdateWidget(oldWidget);

  if (widget.reaction != oldWidget.reaction) {
    _resetTimer?.cancel();

    final expressions = [
      'assets/images/menti_wink.png',
      'assets/images/menti_blink.png',
      'assets/images/menti_double_blink.png',
    ];

    setState(() {
      _image = expressions[widget.reaction % expressions.length];
    });

    _resetTimer = Timer(
      const Duration(milliseconds: 1500),
      () {
        if (mounted) {
          setState(() {
            _image = 'assets/images/menti_open.png';
          });
        }
      },
    );
  }
}

  void _changeExpression() {
    if (!mounted) return;

    _resetTimer?.cancel();

    final expressions = [
      'assets/images/menti_blink.png',
      'assets/images/menti_double_blink.png',
      'assets/images/menti_wink.png',
    ];

    setState(() {
      _image = expressions[_sequence % expressions.length];
      _sequence++;
    });

    _resetTimer = Timer(
      const Duration(milliseconds: 350),
      () {
        if (mounted) {
          setState(() {
            _image = 'assets/images/menti_open.png';
          });
        }
      },
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    for (final path in [
      'assets/images/menti_open.png',
      'assets/images/menti_blink.png',
      'assets/images/menti_double_blink.png',
      'assets/images/menti_wink.png',
    ]) {
      precacheImage(AssetImage(path), context);
    }
  }

  @override
  void dispose() {
    _expressionTimer?.cancel();
    _resetTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _floating,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _floating.value),
          child: child,
        );
      },
      child: Image.asset(
        _image,
        width: widget.size,
        height: widget.size,
        fit: BoxFit.contain,
        gaplessPlayback: true,
      ),
    );
  }
}

/// Legacy frame animation; inactive in the current character/profile routes.
class MentiAnimation extends StatelessWidget {
  const MentiAnimation({super.key, this.size = 230, this.reaction = 0});
  final double size;
  final int reaction;
  @override
  Widget build(BuildContext context) => MentiMotionScope.animateOf(context)
      ? _AnimatedMentiFrames(size: size, reaction: reaction)
      : Image.asset('assets/images/menti_open.png', width: size, height: size,
          fit: BoxFit.contain);
}
