import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'menti_head_geometry.dart';
import 'menti_wardrobe_geometry.dart';

/// Separate measured lens seats, plus a clothing-aware collar. No global SVG
/// stretching: each eye retains its own size, height and perspective.
class MentiAccessoryRig {
  MentiAccessoryRig(this.head, this.wardrobe);
  final MentiHeadGeometry head;
  final MentiWardrobeGeometry wardrobe;
  Rect lens(bool right) {
    final e = right ? head.rightEye : head.leftEye;
    return Rect.fromCenter(
      center: e.center,
      width: e.width * 1.13,
      height: e.height * .94,
    );
  }

  double get angle =>
      math.atan2(
        head.rightEye.center.dy - head.leftEye.center.dy,
        head.rightEye.center.dx - head.leftEye.center.dx,
      ) *
      .65;
  Rect get glasses => lens(false).expandToInclude(lens(true)).inflate(9);
  Rect get collar {
    final native = wardrobe.outfit == 'basic';
    final chin = head.mouth.bottom + head.scalp.height * .045;
    final y = native
        ? math.max(chin, wardrobe.neck)
        : math.max(chin, wardrobe.garment.top + 5);
    final width = head.scalp.width * (head.rig.family == 'girl' ? .48 : .52);
    return Rect.fromLTWH(
      head.mouth.center.dx - width / 2,
      y,
      width,
      width * .48,
    );
  }

  Rect get neckBounds => collar
      .expandToInclude(
        Rect.fromLTWH(
          collar.left,
          collar.top,
          collar.width,
          collar.height * 2.4,
        ),
      )
      .inflate(5);
}

class MentiFittedAccessories extends CustomPainter {
  MentiFittedAccessories(this.rig, {this.glasses = 'none', this.neck = 'none'});
  final MentiAccessoryRig rig;
  final String glasses, neck;
  Paint stroke(Color c, double w) => Paint()
    ..color = c
    ..style = PaintingStyle.stroke
    ..strokeWidth = w
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;
  void line(Canvas c, Offset a, Offset b, Color color, double width) =>
      c.drawLine(a, b, stroke(color, width));
  @override
  void paint(Canvas c, Size size) {
    c.save();
    c.scale(size.width / 320, size.height / 400);
    if (neck != 'none') _neck(c);
    if (glasses != 'none') _glasses(c);
    c.restore();
  }

  void _glasses(Canvas c) {
    final left = rig.lens(false), right = rig.lens(true);
    final dark = glasses == 'sunglasses';
    final frame = dark ? const Color(0xff292132) : const Color(0xff9b6729);
    // Temples sit behind the front rims; the smaller far lens stays smaller.
    for (final pair in [(left, false), (right, true)]) {
      final (r, far) = pair;
      final anchor = Offset(
        far ? r.right : r.left,
        r.center.dy - r.height * .12,
      );
      line(
        c,
        anchor,
        Offset(anchor.dx + (far ? 7 : -7), anchor.dy - 3),
        const Color(0xff382737),
        2.1,
      );
    }
    final bridge = Path()
      ..moveTo(left.right - 1, left.center.dy - 2)
      ..quadraticBezierTo(
        (left.right + right.left) / 2,
        math.min(left.center.dy, right.center.dy) - 5,
        right.left + 1,
        right.center.dy - 2,
      );
    c.drawPath(bridge, stroke(frame, 2.0));
    for (final r in [left, right]) {
      c.save();
      c.translate(r.center.dx, r.center.dy);
      c.rotate(rig.angle);
      final local = Rect.fromCenter(
        center: Offset.zero,
        width: r.width,
        height: r.height,
      );
      final shape = RRect.fromRectAndRadius(
        local,
        Radius.circular(dark ? r.height * .23 : r.height * .48),
      );
      c.drawRRect(
        shape.shift(const Offset(0, 1.1)),
        stroke(const Color(0x44301919), 2),
      );
      c.drawRRect(
        shape,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: dark
                ? [
                    const Color(0xff60546e),
                    const Color(0xff191a32),
                    const Color(0xff151020),
                  ]
                : [const Color(0x22e4f5ff), const Color(0x09b7d6ff)],
          ).createShader(local),
      );
      c.drawRRect(shape, stroke(frame, dark ? 2.8 : 1.65));
      c.drawArc(
        local.deflate(1.8),
        3.6,
        1.7,
        false,
        stroke(const Color(0xaaffedc4), .7),
      );
      c.clipRRect(shape);
      line(
        c,
        Offset(local.left + 3, local.top + 3),
        Offset(local.center.dx, local.top + local.height * .32),
        const Color(0x55ffffff),
        1.5,
      );
      c.restore();
    }
  }

  void _neck(Canvas c) {
    final r = rig.collar;
    final w = r.width;
    c.save();
    // No fabric/jewellery may overwrite the mouth or jaw.
    c.clipRect(Rect.fromLTRB(0, r.top, 320, 400));
    if (neck == 'chain') {
      final path = Path()
        ..moveTo(r.left + 3, r.top + 2)
        ..cubicTo(
          r.left + w * .10,
          r.bottom + w * .24,
          r.right - w * .10,
          r.bottom + w * .24,
          r.right - 3,
          r.top + 2,
        );
      c.drawPath(
        path.shift(const Offset(0, 1.5)),
        stroke(const Color(0x77321714), 2.8),
      );
      c.drawPath(path, stroke(const Color(0xff986022), 2.6));
      c.drawPath(path, stroke(const Color(0xffffd566), 1.3));
      final metric = path.computeMetrics().first;
      for (double d = 0; d < metric.length; d += 3.0) {
        final t = metric.getTangentForOffset(d)!;
        c.drawCircle(t.position, .62, Paint()..color = const Color(0xfffff4b6));
      }
      final pendant = Offset(r.center.dx, r.bottom + w * .17);
      c.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: pendant, width: w * .16, height: w * .20),
          const Radius.circular(2),
        ),
        Paint()
          ..shader = const LinearGradient(
            colors: [Color(0xffffed9d), Color(0xffb67a24)],
          ).createShader(r),
      );
      c.drawCircle(pendant, w * .035, Paint()..color = const Color(0xff683794));
    } else if (neck == 'scarf') {
      final loop = Path()
        ..moveTo(r.left, r.top)
        ..quadraticBezierTo(r.center.dx, r.top + r.height * .6, r.right, r.top)
        ..lineTo(r.right - 2, r.bottom)
        ..quadraticBezierTo(
          r.center.dx,
          r.bottom + r.height * .4,
          r.left + 2,
          r.bottom,
        )
        ..close();
      final tail = Path()
        ..moveTo(r.center.dx + 3, r.bottom - 3)
        ..lineTo(r.right - 4, r.bottom - 5)
        ..lineTo(r.right + 4, r.bottom + w * .58)
        ..lineTo(r.center.dx + 2, r.bottom + w * .65)
        ..close();
      final paint = Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xffbda0df), Color(0xff7942ac), Color(0xff39204f)],
        ).createShader(rig.neckBounds);
      c.drawShadow(tail, Colors.black, 2, false);
      c.drawPath(tail, paint);
      c.drawShadow(loop, Colors.black, 1.5, false);
      c.drawPath(loop, paint);
      c.save();
      c.clipPath(loop);
      for (double x = r.left; x < r.right; x += 1.8) {
        line(
          c,
          Offset(x, r.top),
          Offset(x - 2, r.bottom + 4),
          const Color(0x22f5d9ff),
          .4,
        );
      }
      c.restore();
      for (var i = 1; i < 4; i++) {
        final y = r.top + r.height * i / 4;
        final p = Path()
          ..moveTo(r.left + 3, y)
          ..quadraticBezierTo(r.center.dx, y + r.height * .36, r.right - 3, y);
        c.drawPath(p, stroke(const Color(0x77e1c7f2), .65));
      }
      for (var i = 0; i < 7; i++) {
        final x = r.center.dx + 3 + (w * .38) * i / 7;
        line(
          c,
          Offset(x, r.bottom + w * .57),
          Offset(x + 1, r.bottom + w * .67),
          const Color(0xffd7b77a),
          .8,
        );
      }
    } else {
      for (final side in [-1.0, 1.0]) {
        final p = Path()
          ..moveTo(r.center.dx, r.center.dy)
          ..quadraticBezierTo(
            r.center.dx + side * w * .22,
            r.top - 2,
            r.center.dx + side * w * .44,
            r.top + 2,
          )
          ..quadraticBezierTo(
            r.center.dx + side * w * .47,
            r.bottom + 2,
            r.center.dx,
            r.center.dy,
          )
          ..close();
        c.drawPath(
          p,
          Paint()
            ..shader = const LinearGradient(
              colors: [Color(0xffdab3ed), Color(0xff623286)],
            ).createShader(r),
        );
        c.drawPath(p, stroke(const Color(0xff3c214c), .8));
      }
      c.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: r.center,
            width: w * .17,
            height: r.height * .7,
          ),
          const Radius.circular(2),
        ),
        Paint()..color = const Color(0xff9c73bb),
      );
    }
    c.restore();
  }

  @override
  bool shouldRepaint(covariant MentiFittedAccessories old) =>
      old.rig != rig || old.glasses != glasses || old.neck != neck;
}
