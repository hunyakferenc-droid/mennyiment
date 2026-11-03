import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'menti_head_geometry.dart';
import 'menti_wardrobe_geometry.dart';
import 'menti_identity.dart';
import 'menti_visual_catalog.dart';

/// Separate measured lens seats, plus a clothing-aware collar. No global SVG
/// stretching: each eye retains its own size, height and perspective.
class MentiAccessoryRig {
  MentiAccessoryRig(this.head, this.wardrobe, {this.compact = false});
  final bool compact;
  factory MentiAccessoryRig.forProfile(
    MentiHeadGeometry head,
    MentiWardrobeGeometry wardrobe,
    MentiVisualProfile visual,
  ) {
    final count = ['glasses', 'neck', 'held', 'headwear', 'back', 'detail']
        .where(
          (f) => MentiVisualCatalog.resolve(f, visual.value(f)).id != 'none',
        )
        .length;
    return MentiAccessoryRig(head, wardrobe, compact: count >= 3);
  }
  final MentiHeadGeometry head;
  final MentiWardrobeGeometry wardrobe;
  Rect lens(bool right, {String style = 'round-glasses'}) {
    final e = right ? head.rightEye : head.leftEye;
    return Rect.fromCenter(
      center: e.center,
      width: e.width * (style == 'sunglasses' ? (compact ? .98 : 1.01) : 1.10),
      height: e.height * (style == 'sunglasses' ? .82 : .92),
    );
  }

  double get angle =>
      math.atan2(
        head.rightEye.center.dy - head.leftEye.center.dy,
        head.rightEye.center.dx - head.leftEye.center.dx,
      ) *
      .65;
  Offset rim(bool right, bool outer, {String style = 'round-glasses'}) {
    final r = lens(right, style: style);
    final x = (right == outer ? 1.0 : -1.0) * r.width / 2;
    final y = -r.height * .06;
    return r.center +
        Offset(
          x * math.cos(angle) - y * math.sin(angle),
          x * math.sin(angle) + y * math.cos(angle),
        );
  }

  Rect get glasses => lens(false).expandToInclude(lens(true)).inflate(9);
  Rect get collar {
    final native = wardrobe.outfit == 'basic';
    final chin = head.mouth.bottom + head.scalp.height * .045;
    final kind = wardrobe.collarKind;
    final seat = switch (kind) {
      'hooded' => 3.0,
      'stand' => 2.0,
      _ => 0.0,
    };
    final y =
        (native
            ? math.max(chin, wardrobe.neck)
            : math.max(chin, wardrobe.garment.top + 5)) +
        seat;
    final width =
        head.scalp.width *
        switch (kind) {
          'shirt' => .28,
          'knit' => .32,
          'stand' => .30,
          _ => head.rig.family == 'girl' ? .29 : .32,
        } *
        (compact ? .92 : 1);
    return Rect.fromLTWH(
      head.mouth.center.dx - width / 2,
      y,
      width,
      width * .27,
    );
  }

  Rect get neckBounds => Rect.fromLTWH(
    collar.left - 3,
    collar.top,
    collar.width + 6,
    collar.height + collar.width * (compact ? .38 : .55),
  ).inflate(5);
}

class MentiFittedAccessories extends CustomPainter {
  MentiFittedAccessories(
    this.rig, {
    this.glasses = 'none',
    this.neck = 'none',
    this.detail = 'none',
  });
  final MentiAccessoryRig rig;
  final String glasses, neck, detail;
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
    if (detail != 'none') _detail(c);
    if (glasses != 'none') _glasses(c);
    c.restore();
  }

  void _detail(Canvas c) {
    final h = rig.head;
    final y = h.eyes.bottom + 2;
    final left = Offset(h.leftEye.center.dx - h.leftEye.width * .32, y);
    final right = Offset(h.rightEye.center.dx + h.rightEye.width * .30, y + 1);
    if (detail == 'freckles') {
      for (final centre in [left, right]) {
        for (var i = 0; i < 3; i++) {
          c.drawCircle(
            centre + Offset((i - 1) * 3, (i % 2) * 2),
            .85,
            Paint()..color = const Color(0x997c481b),
          );
        }
      }
    } else if (detail == 'star') {
      final r = Rect.fromCenter(center: left, width: 8, height: 8);
      final p = Path();
      for (var i = 0; i < 10; i++) {
        final a = i * math.pi / 5 - math.pi / 2;
        final radius = i.isEven ? 4.0 : 1.9;
        final x = left.dx + math.cos(a) * radius,
            y = left.dy + math.sin(a) * radius;
        if (i == 0) {
          p.moveTo(x, y);
        } else {
          p.lineTo(x, y);
        }
      }
      p.close();
      c.drawPath(
        p,
        Paint()
          ..shader = const LinearGradient(
            colors: [Color(0xfffff0b3), Color(0xffb78128)],
          ).createShader(r),
      );
      c.drawPath(p, stroke(const Color(0xffbd7d22), .5));
    } else {
      c.drawArc(
        Rect.fromCenter(center: left, width: 7, height: 7),
        .6,
        4.2,
        false,
        stroke(const Color(0xffe7ddfa), 2),
      );
      c.drawArc(
        Rect.fromCenter(center: left, width: 7, height: 7),
        .6,
        4.2,
        false,
        stroke(const Color(0xffa38bbb), .5),
      );
    }
  }

  void _glasses(Canvas c) {
    final left = rig.lens(false, style: glasses),
        right = rig.lens(true, style: glasses);
    final dark = glasses == 'sunglasses';
    final frame = dark ? const Color(0xff292132) : const Color(0xff9b6729);
    // Temples sit behind the front rims; the smaller far lens stays smaller.
    for (final far in [false, true]) {
      final anchor = rig.rim(far, true, style: glasses);
      line(c, anchor, anchor + Offset(far ? 4 : -4, -1.5), frame, 1.1);
    }
    final innerLeft = rig.rim(false, false, style: glasses);
    final innerRight = rig.rim(true, false, style: glasses);
    final bridge = Path()
      ..moveTo(innerLeft.dx, innerLeft.dy)
      ..quadraticBezierTo(
        (innerLeft.dx + innerRight.dx) / 2,
        (innerLeft.dy + innerRight.dy) / 2 - 1.5,
        innerRight.dx,
        innerRight.dy,
      );
    c.drawPath(bridge, stroke(frame, 1.1));
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
        Radius.circular(dark ? r.height * .36 : r.height * .48),
      );
      c.drawRRect(
        shape.shift(const Offset(0, 1.1)),
        stroke(const Color(0x22301919), .8),
      );
      c.drawRRect(
        shape,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: dark
                ? [
                    const Color(0xe04e4b56),
                    const Color(0xf0262733),
                    const Color(0xed151922),
                  ]
                : [const Color(0x22e4f5ff), const Color(0x09b7d6ff)],
          ).createShader(local),
      );
      c.drawRRect(
        shape,
        stroke(frame, dark ? (rig.compact ? 1.2 : 1.4) : 1.15),
      );
      c.drawArc(
        local.deflate(1.8),
        3.6,
        1.7,
        false,
        stroke(const Color(0x55ffedc4), .5),
      );
      c.clipRRect(shape);
      line(
        c,
        Offset(local.left + 3, local.top + 3),
        Offset(local.center.dx, local.top + local.height * .32),
        const Color(0x33ffffff),
        .85,
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
        stroke(const Color(0x44321714), 1.7),
      );
      c.drawPath(path, stroke(const Color(0xff986022), 1.3));
      c.drawPath(path, stroke(const Color(0xffffd566), .65));
      final metric = path.computeMetrics().first;
      for (double d = 0; d < metric.length; d += 2.2) {
        final t = metric.getTangentForOffset(d)!;
        c.drawCircle(t.position, .38, Paint()..color = const Color(0xfffff4b6));
      }
      final pendant = Offset(r.center.dx, r.bottom + w * .17);
      c.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: pendant, width: w * .10, height: w * .13),
          const Radius.circular(2),
        ),
        Paint()
          ..shader = const LinearGradient(
            colors: [Color(0xffffed9d), Color(0xffb67a24)],
          ).createShader(r),
      );
      c.drawCircle(pendant, w * .022, Paint()..color = const Color(0xff683794));
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
      final fall = rig.compact ? .30 : .44;
      final tail = Path()
        ..moveTo(r.center.dx + w * .06, r.bottom - 2)
        ..lineTo(r.right - w * .18, r.bottom - 3)
        ..quadraticBezierTo(
          r.right - w * .17,
          r.bottom + w * .20,
          r.right - w * .08,
          r.bottom + w * fall,
        )
        ..lineTo(r.center.dx + w * .10, r.bottom + w * (fall + .04))
        ..quadraticBezierTo(
          r.center.dx + w * .14,
          r.bottom + w * .20,
          r.center.dx + w * .06,
          r.bottom - 2,
        )
        ..close();
      final paint = Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xffa48dbb), Color(0xff70517d), Color(0xff382d42)],
        ).createShader(rig.neckBounds);
      c.drawShadow(tail, const Color(0x66000000), 1.1, false);
      c.drawPath(tail, paint);
      c.drawShadow(loop, const Color(0x66000000), .8, false);
      c.drawPath(loop, paint);
      c.save();
      c.clipPath(loop);
      for (double x = r.left; x < r.right; x += 1.8) {
        line(
          c,
          Offset(x, r.top),
          Offset(x - 2, r.bottom + 4),
          const Color(0x18f5d9ff),
          .4,
        );
      }
      c.restore();
      for (var i = 1; i < 4; i++) {
        final y = r.top + r.height * i / 4;
        final p = Path()
          ..moveTo(r.left + 3, y)
          ..quadraticBezierTo(r.center.dx, y + r.height * .36, r.right - 3, y);
        c.drawPath(p, stroke(const Color(0x55d4c4df), .45));
      }
      for (var i = 0; i < 7; i++) {
        final x = r.center.dx + w * .10 + (w * .32) * i / 7;
        line(
          c,
          Offset(x, r.bottom + w * fall),
          Offset(x + 1, r.bottom + w * (fall + .06)),
          const Color(0xffbca98b),
          .5,
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
              colors: [Color(0xffb7a4c7), Color(0xff594263)],
            ).createShader(r),
        );
        c.drawPath(p, stroke(const Color(0xff3c2b42), .65));
        final crease = Path()
          ..moveTo(r.center.dx + side * w * .07, r.center.dy)
          ..quadraticBezierTo(
            r.center.dx + side * w * .22,
            r.center.dy - r.height * .16,
            r.center.dx + side * w * .36,
            r.top + r.height * .22,
          );
        c.drawPath(crease, stroke(const Color(0x88644870), .8));
        c.drawPath(
          crease.shift(const Offset(0, -.6)),
          stroke(const Color(0x55e4d7ec), .4),
        );
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
      old.rig != rig ||
      old.glasses != glasses ||
      old.neck != neck ||
      old.detail != detail;
}
