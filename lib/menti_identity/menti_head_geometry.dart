import 'dart:ui';
import 'dart:typed_data';

import 'menti_face_anchors.dart';
import 'menti_reference_rig.dart';

/// One measured head contract for runtime, option cards and full-screen preview.
class MentiHeadGeometry {
  MentiHeadGeometry(
    this.rig, {
    required this.clean,
    required this.hair,
    required this.hairVisible,
  });
  final MentiReferenceRig rig;
  final bool clean, hairVisible;
  final String hair;
  Map<String, Rect> get features => MentiFaceAnchors
      .values['${rig.family}-${rig.age}${clean ? '-clean' : ''}']!;
  Rect get leftEye => rig.register(features['leftEye']!);
  Rect get rightEye => rig.register(features['rightEye']!);
  Rect get mouth => rig.register(features['mouth']!);
  Rect get eyes => leftEye.expandToInclude(rightEye);
  Rect get scalp => rig.register(
    MentiFaceAnchors.values['${rig.family}-${rig.age}-clean']!['skull']!,
  );
  // Crown centres were checked against the upper scalp (15–30% height),
  // not the ear-to-ear bounding box: ears bias that box to the left.
  // Each entry is (bare scalp, hair on), with (width, centre offset, seat).
  static const _capFit =
      <String, ((double, double, double), (double, double, double))>{
        'boy-young': ((.89, .053, .365), (.905, .053, .357)),
        'boy-adult': ((.91, .047, .350), (.925, .047, .342)),
        'boy-veteran': ((.87, .061, .345), (.885, .061, .337)),
        'girl-young': ((.88, .057, .332), (.895, .057, .326)),
        'girl-adult': ((.89, .055, .382), (.905, .055, .374)),
        'girl-veteran': ((.85, .046, .392), (.865, .046, .384)),
        'neutral-young': ((.91, .086, .412), (.925, .086, .404)),
        'neutral-adult': ((.90, .090, .412), (.915, .090, .404)),
        'neutral-veteran': ((.87, .092, .382), (.885, .092, .374)),
      };
  static const _hairFit = <String, (double, double)>{
    'crop': (1, 0),
    'waves': (1.005, -.002),
    'curls': (1.012, -.004),
    'braid': (1, .002),
    'bob': (1.003, .002),
    'crest': (1.012, -.005),
  };
  Rect cap(Rect source) {
    final fits = _capFit['${rig.family}-${rig.age}']!;
    final (scale, x, seat) = hairVisible ? fits.$2 : fits.$1;
    final (volume, dy) = hairVisible
        ? _hairFit[hair.split('-').last]!
        : (1.0, 0.0);
    final width = scalp.width * scale * volume;
    final height = width * source.height / source.width;
    final natural = scalp.top + scalp.height * (seat + dy);
    final bottom = natural.clamp(1, eyes.top - 2).toDouble();
    return Rect.fromLTWH(
      scalp.center.dx + scalp.width * x - width / 2,
      bottom - height,
      width,
      height,
    );
  }

  Rect get hairTarget {
    final style = hair.split('-').last;
    final long = ['waves', 'curls', 'braid', 'bob'].contains(style);
    final width = scalp.width * (long ? 1.14 : 1.04);
    return Rect.fromLTWH(scalp.center.dx - width / 2, scalp.top - 5, width, 0);
  }

  Path guard() {
    final face = eyes.expandToInclude(mouth).inflate(5);
    var path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(face, Radius.circular(face.width * .30)),
      );
    for (final rect in [
      leftEye.inflate(3),
      rightEye.inflate(3),
      mouth.inflate(4),
    ]) {
      path = Path.combine(
        PathOperation.union,
        path,
        Path()
          ..addRRect(RRect.fromRectAndRadius(rect, const Radius.circular(4))),
      );
    }
    return path;
  }

  Path window(Rect target) {
    final transform = Float64List.fromList([
      1 / target.width,
      0,
      0,
      0,
      0,
      1 / target.height,
      0,
      0,
      0,
      0,
      1,
      0,
      -target.left / target.width,
      -target.top / target.height,
      0,
      1,
    ]);
    return Path.combine(
      PathOperation.difference,
      Path()..addRect(const Rect.fromLTWH(0, 0, 1, 1)),
      guard().transform(transform),
    );
  }
}
