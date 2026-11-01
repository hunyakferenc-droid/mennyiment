import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// A registered, uniformly scaled view of an unchanged reference PNG. All source
/// coordinates refer to the original 1942 × 809 artboards, never a redrawn body.
class MentiReferenceRig {
  const MentiReferenceRig(
    this.family,
    this.age,
    this.originX,
    this.face,
    this.eyes,
    this.mouth,
    this.skin,
    this.neckY,
    this.hairId,
  );
  final String family, age, hairId;
  final double originX, neckY;
  final Rect face, eyes, mouth, skin;
  String get asset => 'assets/images/menti_2_2/reference/$family.png';
  Rect get source => Rect.fromLTWH(originX, 0, 520, 820);
  // Original source aspect and ground line remain invariant for every layer.
  static const target = Rect.fromLTWH(33.17, 0, 253.66, 400);
  static const assets = [
    'assets/images/menti_2_2/reference/boy.png',
    'assets/images/menti_2_2/reference/girl.png',
    'assets/images/menti_2_2/reference/neutral.png',
  ];
  static const all = [
    MentiReferenceRig(
      'boy',
      'young',
      130,
      Rect.fromLTWH(270, 141, 267, 184),
      Rect.fromLTWH(327, 162, 182, 101),
      Rect.fromLTWH(322, 231, 184, 86),
      Rect.fromLTWH(380, 145, 35, 20),
      320,
      'boy-crop',
    ),
    MentiReferenceRig(
      'boy',
      'adult',
      700,
      Rect.fromLTWH(837, 87, 234, 205),
      Rect.fromLTWH(893, 119, 165, 103),
      Rect.fromLTWH(890, 189, 160, 83),
      Rect.fromLTWH(974, 105, 20, 20),
      285,
      'boy-waves',
    ),
    MentiReferenceRig(
      'boy',
      'veteran',
      1295,
      Rect.fromLTWH(1434, 90, 252, 218),
      Rect.fromLTWH(1466, 129, 196, 104),
      Rect.fromLTWH(1474, 194, 182, 87),
      Rect.fromLTWH(1541, 104, 26, 21),
      300,
      'boy-crop',
    ),
    MentiReferenceRig(
      'girl',
      'young',
      190,
      Rect.fromLTWH(381, 115, 208, 194),
      Rect.fromLTWH(411, 150, 161, 105),
      Rect.fromLTWH(416, 216, 151, 77),
      Rect.fromLTWH(489, 124, 20, 19),
      300,
      'girl-waves',
    ),
    MentiReferenceRig(
      'girl',
      'adult',
      710,
      Rect.fromLTWH(897, 91, 203, 194),
      Rect.fromLTWH(920, 122, 163, 100),
      Rect.fromLTWH(927, 191, 151, 72),
      Rect.fromLTWH(998, 103, 21, 18),
      284,
      'girl-waves',
    ),
    MentiReferenceRig(
      'girl',
      'veteran',
      1260,
      Rect.fromLTWH(1423, 84, 216, 214),
      Rect.fromLTWH(1451, 124, 172, 102),
      Rect.fromLTWH(1456, 192, 163, 76),
      Rect.fromLTWH(1535, 102, 22, 19),
      294,
      'girl-bob',
    ),
    MentiReferenceRig(
      'neutral',
      'young',
      150,
      Rect.fromLTWH(303, 109, 241, 180),
      Rect.fromLTWH(331, 132, 180, 106),
      Rect.fromLTWH(355, 211, 139, 60),
      Rect.fromLTWH(417, 115, 21, 17),
      279,
      'neutral-curls',
    ),
    MentiReferenceRig(
      'neutral',
      'adult',
      690,
      Rect.fromLTWH(851, 78, 231, 199),
      Rect.fromLTWH(888, 105, 172, 109),
      Rect.fromLTWH(905, 196, 135, 60),
      Rect.fromLTWH(974, 91, 20, 18),
      270,
      'neutral-crest',
    ),
    MentiReferenceRig(
      'neutral',
      'veteran',
      1235,
      Rect.fromLTWH(1409, 86, 238, 201),
      Rect.fromLTWH(1447, 117, 178, 107),
      Rect.fromLTWH(1463, 201, 140, 61),
      Rect.fromLTWH(1530, 96, 20, 18),
      278,
      'neutral-crop',
    ),
  ];
  static MentiReferenceRig of(String family, String age) =>
      all.firstWhere((r) => r.family == family && r.age == age);
  Rect register(Rect original) => Rect.fromLTWH(
    target.left + (original.left - originX) * target.width / 520,
    original.top * 400 / 820,
    original.width * target.width / 520,
    original.height * 400 / 820,
  );
}

/// Uses the shared Flutter image cache; no per-avatar PNG decoding or resizing.
/// Clipping/registration happen on the GPU, with the original source pixels.
class MentiReferencePlate extends StatefulWidget {
  const MentiReferencePlate({
    super.key,
    required this.rig,
    this.part,
    this.exclude,
    this.tint,
    this.eyeStyle = 'round',
    this.faceStyle = 'cheerful',
    this.blink = false,
    this.wink = false,
  });
  final MentiReferenceRig rig;
  final Path? part, exclude;
  final Color? tint;
  final String eyeStyle, faceStyle;
  final bool blink, wink;
  @override
  State<MentiReferencePlate> createState() => _MentiReferencePlateState();
}

class _MentiReferencePlateState extends State<MentiReferencePlate> {
  ImageStream? _stream;
  ImageInfo? _info;
  late final ImageStreamListener _listener = ImageStreamListener((info, sync) {
    final old = _info;
    if (mounted) {
      setState(() => _info = info);
    } else {
      info.dispose();
    }
    old?.dispose();
  });
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _resolve();
  }

  @override
  void didUpdateWidget(MentiReferencePlate oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.rig.asset != widget.rig.asset) _resolve();
  }

  void _resolve() {
    final stream = AssetImage(widget.rig.asset)
        .resolve(createLocalImageConfiguration(context));
    if (_stream?.key == stream.key) return;
    _stream?.removeListener(_listener);
    _stream = stream..addListener(_listener);
  }

  @override
  void dispose() {
    _stream?.removeListener(_listener);
    _info?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      CustomPaint(painter: _PlatePainter(widget, _info?.image));
}

class _PlatePainter extends CustomPainter {
  _PlatePainter(this.spec, this.image);
  final MentiReferencePlate spec;
  final ui.Image? image;
  @override
  void paint(Canvas canvas, Size size) {
    if (image == null) return;
    final rig = spec.rig;
    canvas.save();
    canvas.scale(size.width / 320, size.height / 400);
    if (spec.part != null) canvas.clipPath(spec.part!);
    if (spec.exclude != null) canvas.clipPath(spec.exclude!, doAntiAlias: true);
    final paint = Paint()..filterQuality = FilterQuality.high;
    if (spec.tint != null) {
      paint.colorFilter = ColorFilter.mode(spec.tint!, BlendMode.modulate);
    }
    canvas.drawImageRect(
      image!,
      rig.source.intersect(const Rect.fromLTWH(0, 0, 1942, 809)),
      Rect.fromLTWH(
        MentiReferenceRig.target.left,
        0,
        MentiReferenceRig.target.width,
        809 * 400 / 820,
      ),
      paint,
    );
    // Changes preserve each family's own source eye/mouth, including lashes,
    // asymmetric smiles, skin texture and age-specific wrinkles. They do not
    // replace a girl or veteran's face with the common atlas expression.
    if (spec.eyeStyle != 'round' || spec.blink || spec.wink) {
      for (var side = 0; side < 2; side++) {
        final eye = Rect.fromLTWH(
          rig.eyes.left + side * rig.eyes.width / 2,
          rig.eyes.top,
          rig.eyes.width / 2,
          rig.eyes.height,
        );
        final dest = rig.register(eye);
        canvas.save();
        canvas.clipRRect(
          RRect.fromRectAndRadius(dest, const Radius.circular(9)),
        );
        canvas.drawImageRect(
          image!,
          rig.skin,
          dest,
          Paint()..filterQuality = FilterQuality.high,
        );
        final sy = spec.blink || (spec.wink && side == 1)
            ? .10
            : switch (spec.eyeStyle) {
                'wide' => 1.13,
                'relaxed' => .64,
                'sharp' => .82,
                _ => 1.0,
              };
        canvas.translate(dest.center.dx, dest.center.dy);
        if (spec.eyeStyle == 'sharp') canvas.rotate(side == 0 ? -.12 : .12);
        final eyeTarget = Rect.fromCenter(
          center: Offset.zero,
          width: dest.width * (spec.eyeStyle == 'wide' ? 1.08 : 1),
          height: dest.height * sy,
        );
        canvas.drawImageRect(
          image!,
          eye,
          eyeTarget,
          Paint()..filterQuality = FilterQuality.high,
        );
        canvas.restore();
      }
    }
    if (spec.faceStyle != 'cheerful') {
      final dest = rig.register(rig.mouth);
      canvas.save();
      canvas.clipRRect(RRect.fromRectAndRadius(dest, const Radius.circular(9)));
      canvas.drawImageRect(
        image!,
        rig.skin,
        dest,
        Paint()..filterQuality = FilterQuality.high,
      );
      canvas.translate(dest.center.dx, dest.center.dy);
      final (sx, sy, angle) = switch (spec.faceStyle) {
        'calm' => (.8, .40, 0.0),
        'playful' => (1.0, .88, -.12),
        'confident' => (.93, .65, 0.0),
        'sleepy' => (.53, 1.0, 0.0),
        _ => (.87, .28, .05),
      };
      canvas.rotate(angle);
      canvas.drawImageRect(
        image!,
        rig.mouth,
        Rect.fromCenter(
          center: Offset.zero,
          width: dest.width * sx,
          height: dest.height * sy,
        ),
        Paint()..filterQuality = FilterQuality.high,
      );
      canvas.restore();
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_PlatePainter old) =>
      image != old.image || spec != old.spec;
}
