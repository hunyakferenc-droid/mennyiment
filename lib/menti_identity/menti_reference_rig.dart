import 'dart:ui' as ui;
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'menti_reference_masks.dart';

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
    'assets/images/menti_2_2/reference/boy-hairless.png',
    'assets/images/menti_2_2/reference/girl-hairless.png',
    'assets/images/menti_2_2/reference/neutral-hairless.png',
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
  static final _maskCache = <String, Path>{};
  Path mask(String kind) => _maskCache.putIfAbsent('$family-$age/$kind', () {
    final result = Path()..fillType = PathFillType.evenOdd;
    for (final contour
        in MentiReferenceMasks.contours['$family-$age']![kind]!) {
      result.addPolygon([
        for (final p in contour)
          Offset(
            target.left + (p.dx - originX) * target.width / 520,
            p.dy * 400 / 820,
          ),
      ], true);
    }
    return result;
  });
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
    this.hairless = false,
  });
  final MentiReferenceRig rig;
  final Path? part, exclude;
  final Color? tint;
  final String eyeStyle, faceStyle;
  final bool blink, wink, hairless;
  String get asset =>
      hairless ? rig.asset.replaceFirst('.png', '-hairless.png') : rig.asset;
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
    if (oldWidget.asset != widget.asset) _resolve();
  }

  void _resolve() {
    final stream = AssetImage(widget.asset)
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
    // Native feature meshes keep their boundary fixed. Source skin fills the
    // space without repainting rectangles or swapping a family's face.
    if (spec.eyeStyle != 'round' || spec.blink || spec.wink) {
      for (var side = 0; side < 2; side++) {
        final eye = Rect.fromLTWH(
          rig.eyes.left + side * rig.eyes.width / 2,
          rig.eyes.top,
          rig.eyes.width / 2,
          rig.eyes.height,
        );
        final sy = spec.blink || (spec.wink && side == 1)
            ? .10
            : switch (spec.eyeStyle) {
                'wide' => 1.12,
                'relaxed' => .62,
                'sharp' => .80,
                _ => 1.0,
              };
        _warp(
          canvas,
          rig,
          eye.inflate(6),
          sx: spec.eyeStyle == 'wide' ? 1.06 : 1,
          sy: sy,
          angle: spec.eyeStyle == 'sharp' ? (side == 0 ? -.11 : .11) : 0,
        );
      }
    }
    if (spec.faceStyle != 'cheerful') {
      final (sx, sy, angle) = switch (spec.faceStyle) {
        'calm' => (.86, .44, 0.0),
        'playful' => (1.0, .91, -.10),
        'confident' => (.96, .70, 0.0),
        'sleepy' => (.58, 1.0, 0.0),
        _ => (.91, .32, .04),
      };
      _warp(canvas, rig, rig.mouth.inflate(8), sx: sx, sy: sy, angle: angle);
    }
    canvas.restore();
  }

  void _warp(
    Canvas canvas,
    MentiReferenceRig rig,
    Rect region, {
    required double sx,
    required double sy,
    required double angle,
  }) {
    const steps = 24;
    final positions = <Offset>[], texture = <Offset>[], indices = <int>[];
    final dest = rig.register(region);
    for (var y = 0; y <= steps; y++) {
      for (var x = 0; x <= steps; x++) {
        final u = 2 * x / steps - 1, v = 2 * y / steps - 1;
        final weight = (1 - math.pow(u.abs(), 4)) * (1 - math.pow(v.abs(), 4));
        final px = u * (1 + (sx - 1) * weight),
            py = v * (1 + (sy - 1) * weight);
        final r = angle * weight;
        positions.add(
          Offset(
            dest.center.dx +
                (px * math.cos(r) - py * math.sin(r)) * dest.width / 2,
            dest.center.dy +
                (px * math.sin(r) + py * math.cos(r)) * dest.height / 2,
          ),
        );
        texture.add(
          Offset(
            region.left + x * region.width / steps,
            region.top + y * region.height / steps,
          ),
        );
        if (x < steps && y < steps) {
          final n = y * (steps + 1) + x;
          indices.addAll([
            n,
            n + 1,
            n + steps + 1,
            n + 1,
            n + steps + 2,
            n + steps + 1,
          ]);
        }
      }
    }
    canvas.drawVertices(
      ui.Vertices(
        ui.VertexMode.triangles,
        positions,
        textureCoordinates: texture,
        indices: indices,
      ),
      BlendMode.srcOver,
      Paint()
        ..filterQuality = FilterQuality.high
        ..shader = ui.ImageShader(
          image!,
          TileMode.clamp,
          TileMode.clamp,
          Float64List.fromList([
            1,
            0,
            0,
            0,
            0,
            1,
            0,
            0,
            0,
            0,
            1,
            0,
            0,
            0,
            0,
            1,
          ]),
        ),
    );
  }

  @override
  bool shouldRepaint(_PlatePainter old) =>
      image != old.image || spec != old.spec;
}
