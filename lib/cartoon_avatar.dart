
import 'package:flutter/material.dart';

class CartoonAvatar extends StatefulWidget {
  final Color color;
  final double size;
  final int expression;
  final int hat;

  const CartoonAvatar({
    super.key,
    this.color = Colors.orange,
    this.size = 150,
    this.expression = 0,
    this.hat = 0,
  });

  @override
  State<CartoonAvatar> createState() => _CartoonAvatarState();
}

class _CartoonAvatarState extends State<CartoonAvatar>
    with SingleTickerProviderStateMixin {
  late final AnimationController blinkController;

  @override
  void initState() {
    super.initState();

    blinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat();
  }

  @override
  void dispose() {
    blinkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: blinkController,
      builder: (context, child) {
        final t = blinkController.value;
        final blinking = t > 0.75 && t < 0.90;

        return SizedBox(
          width: widget.size,
          height: widget.size * 1.4,
          child: CustomPaint(
            painter: AvatarPainter(
              color: widget.color,
              blinking: blinking,
              expression: widget.expression,
              hat: widget.hat,
            ),
          ),
        );
      },
    );
  }
}

class AvatarPainter extends CustomPainter {
  final Color color;
  final bool blinking;
  final int expression;
  final int hat;

  AvatarPainter({
    required this.color,
    required this.blinking,
    required this.expression,
    required this.hat,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final bodyPaint = Paint()..color = color;

    final blackPaint = Paint()
      ..color = Colors.black
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    // Test
    canvas.drawOval(
      Rect.fromLTWH(
        w * 0.25,
        h * 0.55,
        w * 0.5,
        h * 0.4,
      ),
      bodyPaint,
    );

    // Fej
    canvas.drawCircle(
      Offset(w * 0.5, h * 0.3),
      w * 0.3,
      bodyPaint,
    );

    // Fejfedők
    final hatPaint = Paint()
      ..color = Colors.deepPurple
      ..style = PaintingStyle.fill;

    switch (hat) {
      case 1: // Baseballsapka
        canvas.drawArc(
          Rect.fromLTWH(
            w * 0.25,
            h * 0.05,
            w * 0.5,
            h * 0.28,
          ),
          3.14,
          3.14,
          false,
          hatPaint,
        );

        canvas.drawOval(
          Rect.fromLTWH(
            w * 0.43,
            h * 0.16,
            w * 0.38,
            h * 0.055,
          ),
          hatPaint,
        );
        break;

      case 2: // Bulikalap
        hatPaint.color = Colors.pinkAccent;

        final partyHat = Path()
          ..moveTo(w * 0.5, 0)
          ..lineTo(w * 0.31, h * 0.17)
          ..lineTo(w * 0.69, h * 0.17)
          ..close();

        canvas.drawPath(partyHat, hatPaint);

        canvas.drawCircle(
          Offset(w * 0.5, 0),
          w * 0.045,
          Paint()..color = Colors.yellow,
        );
        break;

      case 3: // Cowboykalap
        hatPaint.color = Colors.brown;

        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(
              w * 0.32,
              h * 0.015,
              w * 0.36,
              h * 0.19,
            ),
            const Radius.circular(12),
          ),
          hatPaint,
        );

        canvas.drawOval(
          Rect.fromLTWH(
            w * 0.18,
            h * 0.16,
            w * 0.64,
            h * 0.055,
          ),
          hatPaint,
        );
        break;
    }

    // Szemek
    if (blinking) {
      for (final x in [0.4, 0.6]) {
        canvas.drawLine(
          Offset(w * (x - 0.05), h * 0.27),
          Offset(w * (x + 0.05), h * 0.27),
          blackPaint,
        );
      }
    } else {
      for (final x in [0.4, 0.6]) {
        canvas.drawCircle(
          Offset(w * x, h * 0.27),
          w * 0.08,
          Paint()..color = Colors.white,
        );

        canvas.drawCircle(
          Offset(w * x, h * 0.27),
          w * 0.033,
          blackPaint,
        );
      }
    }

    // Száj és arckifejezés
    final mouthPaint = Paint()
      ..color = Colors.black
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final mouth = Path();

    switch (expression) {
      case 1: // Bolondos
        mouth.moveTo(w * 0.38, h * 0.39);
        mouth.quadraticBezierTo(
          w * 0.5,
          h * 0.52,
          w * 0.62,
          h * 0.39,
        );
        break;

      case 2: // Bulizós
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(w * 0.5, h * 0.41),
            width: w * 0.17,
            height: h * 0.10,
          ),
          Paint()..color = Colors.black,
        );
        break;

      case 3: // Vagány
        mouth.moveTo(w * 0.4, h * 0.42);
        mouth.lineTo(w * 0.6, h * 0.39);
        break;

      case 4: // Morcos
        mouth.moveTo(w * 0.4, h * 0.44);
        mouth.quadraticBezierTo(
          w * 0.5,
          h * 0.36,
          w * 0.6,
          h * 0.44,
        );
        break;

      case 5: // Hős
        mouth.moveTo(w * 0.37, h * 0.38);
        mouth.quadraticBezierTo(
          w * 0.5,
          h * 0.50,
          w * 0.63,
          h * 0.38,
        );
        break;

      default: // Mosolygós
        mouth.moveTo(w * 0.4, h * 0.38);
        mouth.quadraticBezierTo(
          w * 0.5,
          h * 0.46,
          w * 0.6,
          h * 0.38,
        );
    }

    canvas.drawPath(mouth, mouthPaint);
  }

  @override
  bool shouldRepaint(covariant AvatarPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.blinking != blinking ||
        oldDelegate.expression != expression ||
        oldDelegate.hat != hat;
  }
}
