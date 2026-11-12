import 'package:flutter/material.dart';

import 'menti_accessory_rig.dart';
import 'menti_wardrobe_geometry.dart';

/// A garment's measured inner opening, filled from this character's own skin.
/// Coordinates are atlas pixels: the front collar, tie and seams stay intact.
class MentiNeckBridge extends StatelessWidget {
  const MentiNeckBridge({super.key, required this.wardrobe});
  final MentiWardrobeGeometry wardrobe;

  // Original shaded neck skin, never hair or forehead highlights.
  static const skinSamples = <String, Rect>{
    'boy-young': Rect.fromLTWH(387, 350, 28, 8),
    'boy-adult': Rect.fromLTWH(951, 306, 38, 8),
    'boy-veteran': Rect.fromLTWH(1552, 318, 26, 6),
    'girl-young': Rect.fromLTWH(440, 302, 30, 8),
    'girl-adult': Rect.fromLTWH(963, 292, 33, 9),
    'girl-veteran': Rect.fromLTWH(1510, 304, 32, 12),
    'neutral-young': Rect.fromLTWH(391, 290, 25, 6),
    'neutral-adult': Rect.fromLTWH(950, 271, 30, 6),
    'neutral-veteran': Rect.fromLTWH(1495, 285, 30, 5),
  };

  @override
  Widget build(BuildContext context) {
    final bounds = wardrobe.neckBridge.getBounds();
    return Positioned.fromRect(
      rect: bounds,
      child: ClipPath(
        clipper: _NeckClipper(wardrobe.neckBridge.shift(-bounds.topLeft)),
        child: Stack(
          fit: StackFit.expand,
          children: [
            MentiMaterialPatch(
              asset: wardrobe.rig.asset.replaceFirst('.png', '-hairless.png'),
              source: const Size(1942, 809),
              crop: skinSamples['${wardrobe.rig.family}-${wardrobe.rig.age}']!,
            ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0x483E1C04),
                    Color(0x003E1C04),
                    Color(0x003E1C04),
                    Color(0x243E1C04),
                  ],
                  stops: [0, .28, .68, 1],
                ),
              ),
            ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0x55452A13),
                    Color(0x00452A13),
                    Color(0x553E2518),
                  ],
                  stops: [0, .52, 1],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NeckClipper extends CustomClipper<Path> {
  const _NeckClipper(this.path);
  final Path path;
  @override
  Path getClip(Size size) => path;
  @override
  bool shouldReclip(_NeckClipper oldClipper) => true;
}
