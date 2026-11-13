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
  // The skin masks include each original shirt's exposed neck. Remove that
  // original neck along the measured curved jaw before wearing another collar.
  static const _nativeNecks = <String, Rect>{
    'boy-young': Rect.fromLTWH(350, 325, 90, 46),
    'boy-adult': Rect.fromLTWH(918, 279, 96, 44),
    'boy-veteran': Rect.fromLTWH(1522, 296, 90, 50),
    'girl-young': Rect.fromLTWH(418, 273, 88, 55),
    'girl-adult': Rect.fromLTWH(931, 251, 96, 68),
    'girl-veteran': Rect.fromLTWH(1481, 269, 98, 62),
    'neutral-young': Rect.fromLTWH(366, 267, 85, 35),
    'neutral-adult': Rect.fromLTWH(920, 243, 97, 40),
    'neutral-veteran': Rect.fromLTWH(1467, 262, 94, 39),
  };
  Path get skullSkin {
    final n = rig.register(_nativeNecks['${rig.family}-${rig.age}']!);
    final originalNeck = Path()
      ..moveTo(n.left, n.top - 2)
      ..quadraticBezierTo(n.center.dx, n.top + 8, n.right, n.top - 2)
      ..lineTo(n.right, 400)
      ..lineTo(n.left, 400)
      ..close();
    final skull = Path.combine(
      PathOperation.intersect,
      rig.mask('cleanHeadSkin'),
      Path()..addRect(Rect.fromLTRB(0, 0, 320, scalp.bottom + 2)),
    );
    // Expressions remain exactly on the original face, including low smiles.
    return Path.combine(
      PathOperation.difference,
      skull,
      Path.combine(PathOperation.difference, originalNeck, guard()),
    );
  }

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
    var width = scalp.width * scale * volume;
    var height = width * source.height / source.width;
    final natural = scalp.top + scalp.height * (seat + dy);
    final bottom = natural.clamp(1, eyes.top - 2).toDouble();
    // Fit the accessory itself, not the face or body. A tall cone may exceed
    // the available crown space on an adult head. Keep its aspect and seat,
    // with a one-pixel top margin, while pupils stay at their original pixels.
    final available = (bottom - 1).clamp(1, double.infinity).toDouble();
    if (height > available) {
      final fit = available / height;
      width *= fit;
      height *= fit;
    }
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
