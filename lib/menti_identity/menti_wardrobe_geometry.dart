import 'dart:math' as math;
import 'dart:ui';

import 'menti_reference_rig.dart';
import 'menti_head_geometry.dart';
import 'menti_premium_atlas.dart';

/// Shared garment, cuff and grip anchors for the full figure and Studio crops.
class MentiWardrobeGeometry {
  MentiWardrobeGeometry(this.head, this.outfit);
  final MentiHeadGeometry head;
  final String outfit;
  MentiReferenceRig get rig => head.rig;
  double get neck => math.min(
    MentiReferenceRig.target.top +
        rig.neckY * MentiReferenceRig.target.height / 820,
    head.mouth.bottom + 9,
  );
  Rect get garment {
    final face = rig.register(rig.face);
    final src = MentiPremiumAtlas.rects['outfits/$outfit']!;
    final height = 397 - neck;
    final width = math.min(
      face.width * (rig.family == 'girl' ? 1.74 : 1.68),
      height * src.width / src.height,
    );
    // Uniform material scale: stitching, buttons and shoes retain their shape.
    return Rect.fromLTWH(face.center.dx - width / 2, neck, width, height);
  }

  Rect hand(bool right) {
    if (outfit == 'basic')
      return rig.mask(right ? 'rightHand' : 'leftHand').getBounds();
    final g = garment;
    return Rect.fromLTWH(
      right ? g.right - g.width * .16 - 6 : g.left + 6,
      g.top + g.height * .39,
      g.width * .16,
      g.width * .225,
    );
  }

  Rect held(String id) {
    final grip = hand(id != 'notebook').center;
    final width = head.scalp.width * (id == 'notebook' ? .44 : .34);
    final height = width * (id == 'notebook' ? 1.08 : 1.7);
    return Rect.fromLTWH(
      grip.dx - width / 2,
      grip.dy - height * .8,
      width,
      height,
    );
  }

  static const heldCrops = <String, List<double>>{
    'notebook': [1, 233, 58, 34],
    'flower': [257, 215, 58, 49],
    'spark-wand': [271, 208, 49, 55],
  };
}
