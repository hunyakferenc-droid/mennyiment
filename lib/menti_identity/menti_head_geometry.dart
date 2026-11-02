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
  static const _capFit = <String, (double, double, double)>{
    'boy-young': (.91, -.01, .34),
    'boy-adult': (.93, .00, .35),
    'boy-veteran': (.88, .01, .33),
    'girl-young': (.90, .02, .34),
    'girl-adult': (.91, .01, .36),
    'girl-veteran': (.86, .02, .34),
    'neutral-young': (.93, -.01, .34),
    'neutral-adult': (.92, .00, .35),
    'neutral-veteran': (.88, .01, .34),
  };
  static const _hairFit = <String, (double, double)>{
    'crop': (1, 0),
    'waves': (1.025, -.01),
    'curls': (1.04, -.018),
    'braid': (1.01, .005),
    'bob': (1.015, .005),
    'crest': (1.04, -.025),
  };
  Rect cap(Rect source) {
    final (scale, x, seat) = _capFit['${rig.family}-${rig.age}']!;
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
