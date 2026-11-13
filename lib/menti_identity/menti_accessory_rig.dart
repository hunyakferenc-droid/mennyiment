import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'menti_head_geometry.dart';
import 'menti_wardrobe_geometry.dart';
import 'menti_identity.dart';
import 'menti_visual_catalog.dart';

/// Separate measured lens seats, plus a clothing-aware collar. No global SVG
/// stretching: each eye retains its own size, height and perspective.
class MentiAccessoryRig {
  static const clothAssets = {
    'bow': 'assets/images/menti_2_2/premium/bow-silk-226.png',
    'scarf': 'assets/images/menti_2_2/premium/scarf-wool-226.png',
  };
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
      width: e.width * (style == 'sunglasses' ? 1.01 : 1.10),
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

  Rect get glasses => lens(false).expandToInclude(lens(true)).inflate(12);
  Rect get collar {
    final chin = head.mouth.bottom + head.scalp.height * .045;
    final opening = wardrobe.collarOpening;
    final width = math.min(opening.width, head.scalp.width * .32);
    return Rect.fromCenter(
      center: Offset(
        opening.center.dx,
        math.max(chin + width * .135, opening.center.dy),
      ),
      width: width,
      height: width * .27,
    );
  }

  Rect neckTarget(String id) {
    final r = collar;
    if (id == 'bow') {
      return Rect.fromCenter(
        center: r.center,
        width: r.width * .90,
        height: r.width * .90 * 737 / 2015,
      );
    }
    if (id == 'scarf') {
      final width = r.width * 1.12;
      final height = width * 888 / 928;
      final jaw = head.scalp.bottom;
      return Rect.fromLTWH(
        r.center.dx - width / 2,
        math.max(head.mouth.bottom + 2 - height * .42, jaw - height * .44),
        width,
        height,
      );
    }
    return Rect.fromLTWH(r.left, r.top, r.width, r.height + r.width * .55);
  }

  Rect get neckBounds =>
      neckTarget('scarf')
          .expandToInclude(neckTarget('bow'))
          .expandToInclude(neckTarget('chain'))
          .inflate(5);
}

enum MentiGlassesPass { all, temples, front }

/// Uses the original high-resolution PNG, cropping only transparent canvas.
/// The same cached image is shared by every runtime and Studio card.
class MentiClothAccessory extends StatelessWidget {
  const MentiClothAccessory({super.key, required this.id});
  final String id;
  static const _frames = {
    'bow': (Size(2098, 749), Rect.fromLTWH(38, 6, 2015, 737)),
    'scarf': (Size(1195, 1316), Rect.fromLTWH(124, 241, 928, 888)),
  };

  @override
  Widget build(BuildContext context) {
    final (source, crop) = _frames[id]!;
    Widget material() => MentiMaterialPatch(
      asset: MentiAccessoryRig.clothAssets[id]!,
      source: source,
      crop: crop,
    );
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(
          child: Transform.translate(
            offset: const Offset(.4, 1.2),
            child: ImageFiltered(
              imageFilter: ui.ImageFilter.blur(sigmaX: .55, sigmaY: .55),
              child: ColorFiltered(
                colorFilter: const ColorFilter.mode(
                  Color(0x4420182a),
                  BlendMode.srcIn,
                ),
                child: material(),
              ),
            ),
          ),
        ),
        Positioned.fill(child: material()),
      ],
    );
  }
}

class MentiMaterialPatch extends StatelessWidget {
  const MentiMaterialPatch({
    super.key,
    required this.asset,
    required this.source,
    required this.crop,
  });
  final String asset;
  final Size source;
  final Rect crop;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      asset,
      excludeFromSemantics: true,
      gaplessPlayback: true,
      filterQuality: FilterQuality.medium,
      fit: BoxFit.fill,
      frameBuilder: (context, image, frame, synchronous) => frame == null
          ? const SizedBox.shrink()
          : LayoutBuilder(
              builder: (context, constraints) {
                final scaleX = constraints.maxWidth / crop.width;
                final scaleY = constraints.maxHeight / crop.height;
                return ClipRect(
                  child: OverflowBox(
                    alignment: Alignment.topLeft,
                    minWidth: 0,
                    minHeight: 0,
                    maxWidth: double.infinity,
                    maxHeight: double.infinity,
                    child: Transform.translate(
                      offset: Offset(-crop.left * scaleX, -crop.top * scaleY),
                      child: SizedBox(
                        width: source.width * scaleX,
                        height: source.height * scaleY,
                        child: image,
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class MentiFittedAccessories extends CustomPainter {
  MentiFittedAccessories(
    this.rig, {
    this.glasses = 'none',
    this.neck = 'none',
    this.detail = 'none',
    this.glassesPass = MentiGlassesPass.all,
  });
  final MentiAccessoryRig rig;
  final String glasses, neck, detail;
  final MentiGlassesPass glassesPass;
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
    // Runtime puts these arms behind hair/headwear, with the lenses in front.
    if (glassesPass != MentiGlassesPass.front) {
      for (final far in [false, true]) {
        final anchor = rig.rim(far, true, style: glasses);
        final direction = far ? 1.0 : -1.0;
        final length = rig.head.scalp.width * .065;
        final arm = Path()
          ..moveTo(anchor.dx, anchor.dy)
          ..quadraticBezierTo(
            anchor.dx + direction * length * .60,
            anchor.dy - 2,
            anchor.dx + direction * length,
            anchor.dy - .8,
          );
        c.drawPath(arm, stroke(const Color(0x33271923), 1.8));
        c.drawPath(arm, stroke(frame, dark ? 1.05 : .8));
        c.drawPath(
          arm.shift(const Offset(0, -.3)),
          stroke(const Color(0x66eee2ca), .25),
        );
      }
    }
    if (glassesPass == MentiGlassesPass.temples) return;
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
        stroke(const Color(0x44301919), 1.2)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, .8),
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
        stroke(frame, dark ? 1.4 : 1.15),
      );
      // Fine reflected bevel and inner lip give the frame material thickness
      // without restoring the old heavy outline.
      c.drawArc(
        local.deflate(.15),
        3.25,
        2.7,
        false,
        stroke(dark ? const Color(0x887f7d86) : const Color(0xffe5c98f), .4),
      );
      c.drawArc(
        local.deflate(.7),
        .2,
        2.4,
        false,
        stroke(const Color(0x55201822), .35),
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
      for (double d = 0; d < metric.length; d += 1.65) {
        final t = metric.getTangentForOffset(d)!;
        c.save();
        c.translate(t.position.dx, t.position.dy);
        c.rotate(t.angle);
        const link = Rect.fromLTWH(-.85, -.48, 1.7, .96);
        c.drawOval(link, stroke(const Color(0xff704418), .55));
        c.drawOval(
          link.shift(const Offset(0, -.15)),
          stroke(const Color(0xffffe4a1), .3),
        );
        c.restore();
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
      final fall = .44;
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
      old.glassesPass != glassesPass ||
      old.neck != neck ||
      old.detail != detail;
}
