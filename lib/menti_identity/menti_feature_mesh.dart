import 'dart:ui';
import 'dart:math' as math;

/// Bounded local resampling. Boundary vertices are fixed; no rotation, head
/// scaling, cross-feature sampling or contour movement is part of an expression.
class MentiFeatureMesh {
  MentiFeatureMesh(
    Rect dest,
    Rect source, {
    required double sx,
    required double sy,
    double intensity = 1,
    double tilt = 0,
  }) {
    if (sx < .9 || sx > 1.06 || sy < .4 || sy > 1.06) {
      throw ArgumentError('Unsafe feature deformation');
    }
    if (intensity < 1 || intensity > 4) {
      throw ArgumentError('Unsafe expression intensity');
    }
    if (tilt.abs() > .18) throw ArgumentError('Unsafe eyebrow tilt');
    const steps = 24;
    for (var y = 0; y <= steps; y++) {
      for (var x = 0; x <= steps; x++) {
        final u = 2 * x / steps - 1, v = 2 * y / steps - 1;
        final baseWeight = (1 - u * u) * (1 - v * v);
        final weight = intensity == 1
            ? baseWeight
            : (1 - math.pow(1 - baseWeight, intensity)).toDouble();
        positions.add(
          Offset(
            dest.center.dx + u * (1 + (sx - 1) * weight) * dest.width / 2,
            dest.center.dy +
                v * (1 + (sy - 1) * weight) * dest.height / 2 +
                tilt * u * weight * dest.height,
          ),
        );
        texture.add(
          Offset(
            source.left + x * source.width / steps,
            source.top + y * source.height / steps,
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
  }
  final positions = <Offset>[], texture = <Offset>[];
  final indices = <int>[];
}
