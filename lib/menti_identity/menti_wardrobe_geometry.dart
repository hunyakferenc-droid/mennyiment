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
  String get collarKind {
    if (outfit == 'basic') {
      if ((rig.family == 'boy' || rig.family == 'neutral') &&
          rig.age == 'young') {
        return 'hooded';
      }
      return 'open';
    }
    if (['basic-alt', 'sport', 'street-alt'].contains(outfit)) return 'hooded';
    if (['cozy', 'cozy-alt'].contains(outfit)) return 'knit';
    if (['business', 'business-alt', 'party'].contains(outfit)) return 'shirt';
    if ([
      'legendary',
      'legendary-alt',
      'explorer',
      'explorer-alt',
    ].contains(outfit)) {
      return 'stand';
    }
    return 'open';
  }

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
  static const _heldFit = <String, (double, double, double, double)>{
    // width / scalp, natural height / width, source grip x/y.
    'notebook': (.38, 112 / 80, .82, .78),
    'flower': (.32, 120 / 70, .52, .80),
    'spark-wand': (.24, 140 / 60, .5, .84),
  };
  Rect held(String id) {
    final grip = hand(id != 'notebook').center;
    final (scale, aspect, gx, gy) = _heldFit[id]!;
    final width = head.scalp.width * scale, height = width * aspect;
    return Rect.fromLTWH(
      grip.dx - width * gx,
      grip.dy - height * gy,
      width,
      height,
    );
  }

  Offset heldGrip(String id) {
    final r = held(id), fit = _heldFit[id]!;
    return Offset(r.left + r.width * fit.$3, r.top + r.height * fit.$4);
  }

  static String heldAsset(String id) =>
      'assets/images/menti_2_2/fitted/$id.svg';

  static const heldCrops = <String, List<double>>{
    'notebook': [1, 233, 58, 34],
    'flower': [257, 215, 58, 49],
    'spark-wand': [271, 208, 49, 55],
  };
}
