
import 'package:flutter/material.dart';
import 'cartoon_avatar.dart';
import 'menti_motion.dart';

class _MovingCartoonAvatar extends StatefulWidget {
  final Color color;
  final double size;
  final int expression;
  final int hat;

  const _MovingCartoonAvatar({
    required this.color,
    this.size = 150,
    this.expression = 0,
    this.hat = 0,
  });

  @override
  State<_MovingCartoonAvatar> createState() =>
      __MovingCartoonAvatarState();
}

class __MovingCartoonAvatarState
    extends State<_MovingCartoonAvatar>
    with SingleTickerProviderStateMixin {
  late final AnimationController controller;
  late final Animation<double> rotation;

  @override
  void initState() {
    super.initState();

    controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    rotation = Tween<double>(
      begin: -0.07,
      end: 0.07,
    ).animate(controller);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: rotation,
      child: CartoonAvatar(
        color: widget.color,
        size: widget.size,
        expression: widget.expression,
        hat: widget.hat,
      ),
      builder: (context, child) {
        return Transform.rotate(
          angle: rotation.value,
          child: child,
        );
      },
    );
  }
}

class AnimatedCartoonAvatar extends StatelessWidget {
  const AnimatedCartoonAvatar({super.key, required this.color, this.size = 150,
      this.expression = 0, this.hat = 0});
  final Color color;
  final double size;
  final int expression;
  final int hat;
  @override
  Widget build(BuildContext context) => MentiMotionScope.animateOf(context)
      ? _MovingCartoonAvatar(color: color, size: size, expression: expression, hat: hat)
      : CartoonAvatar(color: color, size: size, expression: expression, hat: hat);
}
