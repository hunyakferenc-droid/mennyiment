import 'dart:math' as math;
import 'dart:ui';

import 'menti_reference_rig.dart';
import 'menti_head_geometry.dart';
import 'menti_premium_atlas.dart';
import 'menti_visual_catalog.dart';

/// Shared garment, cuff and grip anchors for the full figure and Studio crops.
class MentiWardrobeGeometry {
  MentiWardrobeGeometry(this.head, String outfit)
    : outfit = MentiVisualCatalog.resolve('outfit', outfit).id;
  final MentiHeadGeometry head;
  final String outfit;
  MentiReferenceRig get rig => head.rig;
  double get neck => math.min(
    MentiReferenceRig.target.top +
        rig.neckY * MentiReferenceRig.target.height / 820,
    head.mouth.bottom + 3,
  );
  Rect get garment {
    final face = rig.register(rig.face);
    final src = MentiPremiumAtlas.rects['outfits/$outfit']!;
    final height = 397 - neck;
    final width = height * src.width / src.height;
    // Uniform material scale: stitching, buttons and shoes retain their shape.
    return Rect.fromLTWH(face.center.dx - width / 2, neck, width, height);
  }

  Rect hand(bool right) {
    if (outfit == 'basic') {
      return rig.mask(right ? 'rightHand' : 'leftHand').getBounds();
    }
    final g = garment;
    return Rect.fromLTWH(
      right ? g.right - g.width * .16 - 6 : g.left + 6,
      g.top + g.height * (_cuffs[outfit] ?? .38),
      g.width * .16,
      g.width * .225,
    );
  }

  // Sleeve openings in the retained 20 masters. Native basic uses its mask.
  static const _cuffs = <String, double>{
    'basic-alt': .38,
    'party': .38,
    'party-alt': .38,
    'sport': .38,
    'sport-alt': .31,
    'business': .35,
    'business-alt': .35,
    'festival': .38,
    'festival-alt': .38,
    'legendary': .37,
    'legendary-alt': .37,
    'street': .38,
    'street-alt': .38,
    'cozy': .39,
    'cozy-alt': .39,
    'explorer': .36,
    'explorer-alt': .36,
    'creative': .38,
    'creative-alt': .31,
  };
  Rect get shoulders => Rect.fromLTWH(
    garment.left + garment.width * .12,
    garment.top + garment.height * .06,
    garment.width * .76,
    garment.height * .12,
  );
  Rect get waist => Rect.fromLTWH(
    garment.left + garment.width * .25,
    garment.top + garment.height * .45,
    garment.width * .5,
    garment.height * .1,
  );
  Rect get shoes => Rect.fromLTWH(
    garment.left,
    garment.bottom - garment.height * .20,
    garment.width,
    garment.height * .20,
  );
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
