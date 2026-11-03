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
    final opening = cuff(right);
    final original = rig.mask(right ? 'rightHand' : 'leftHand').getBounds();
    final width = g.width * .155;
    final height = width * original.height / original.width;
    final wrist = sourceWrist(right);
    // The wrist enters the actual sleeve opening. Preserve the original hand's
    // aspect rather than stretching every age to one generic hand rectangle.
    return Rect.fromLTWH(
      opening.dx - width * wrist.dx,
      opening.dy - height * wrist.dy,
      width,
      height,
    );
  }

  static final _wristCache = <String, Offset>{};
  Offset sourceWrist(bool right) =>
      _wristCache.putIfAbsent('${rig.family}-${rig.age}-$right', () {
        final path = rig.mask(right ? 'rightHand' : 'leftHand');
        final b = path.getBounds();
        final y = b.top + b.height * .20;
        final samples = [
          for (var i = 0; i <= 100; i++)
            if (path.contains(Offset(b.left + b.width * i / 100, y))) i / 100,
        ];
        return Offset(
          samples.isEmpty ? .5 : (samples.first + samples.last) / 2,
          .20,
        );
      });

  // Normalized centres of the two visible cuff openings in the retained atlas.
  // These are independent: the asymmetric masters must not share one y-offset.
  static const _cuffs = <String, (Offset, Offset)>{
    'basic-alt': (Offset(.065, .423), Offset(.939, .423)),
    'party': (Offset(.058, .413), Offset(.939, .413)),
    'party-alt': (Offset(.055, .409), Offset(.940, .409)),
    'sport': (Offset(.061, .425), Offset(.939, .425)),
    'sport-alt': (Offset(.055, .315), Offset(.943, .315)),
    'business': (Offset(.071, .413), Offset(.929, .413)),
    'business-alt': (Offset(.067, .404), Offset(.929, .404)),
    'festival': (Offset(.070, .416), Offset(.930, .416)),
    'festival-alt': (Offset(.061, .420), Offset(.939, .420)),
    'legendary': (Offset(.067, .418), Offset(.934, .418)),
    'legendary-alt': (Offset(.069, .407), Offset(.927, .407)),
    'street': (Offset(.068, .420), Offset(.935, .420)),
    'street-alt': (Offset(.067, .430), Offset(.928, .430)),
    'cozy': (Offset(.068, .417), Offset(.932, .417)),
    'cozy-alt': (Offset(.067, .414), Offset(.934, .414)),
    'explorer': (Offset(.065, .398), Offset(.937, .398)),
    'explorer-alt': (Offset(.067, .401), Offset(.936, .401)),
    'creative': (Offset(.067, .415), Offset(.932, .415)),
    'creative-alt': (Offset(.045, .304), Offset(.955, .304)),
  };

  Offset cuff(bool right) {
    if (outfit == 'basic') return hand(right).topCenter;
    final points = _cuffs[outfit]!;
    final p = right ? points.$2 : points.$1;
    final g = garment;
    return Offset(g.left + g.width * p.dx, g.top + g.height * p.dy);
  }

  // Actual neck opening, not the atlas rectangle's upper edge (which can be a
  // hood, lapel or raised collar). Kept in source coordinates so every rig and
  // Studio crop uses the same garment-specific seat.
  static const _collars = <String, Rect>{
    'basic-alt': Rect.fromLTWH(.405, .020, .205, .100),
    'party': Rect.fromLTWH(.410, .012, .180, .100),
    'party-alt': Rect.fromLTWH(.410, .015, .180, .100),
    'sport': Rect.fromLTWH(.390, .020, .220, .105),
    'sport-alt': Rect.fromLTWH(.385, .010, .230, .075),
    'business': Rect.fromLTWH(.405, .013, .190, .100),
    'business-alt': Rect.fromLTWH(.400, .013, .200, .100),
    'festival': Rect.fromLTWH(.410, .020, .180, .110),
    'festival-alt': Rect.fromLTWH(.405, .010, .190, .105),
    'legendary': Rect.fromLTWH(.405, .010, .190, .105),
    'legendary-alt': Rect.fromLTWH(.410, .015, .180, .100),
    'street': Rect.fromLTWH(.405, .015, .190, .105),
    'street-alt': Rect.fromLTWH(.405, .020, .190, .110),
    'cozy': Rect.fromLTWH(.390, .015, .220, .100),
    'cozy-alt': Rect.fromLTWH(.390, .010, .220, .070),
    'explorer': Rect.fromLTWH(.405, .015, .190, .110),
    'explorer-alt': Rect.fromLTWH(.405, .020, .190, .100),
    'creative': Rect.fromLTWH(.400, .015, .200, .100),
    'creative-alt': Rect.fromLTWH(.380, .005, .240, .075),
  };

  Rect get collarOpening {
    if (outfit == 'basic') {
      return Rect.fromCenter(
        center: Offset(head.mouth.center.dx, neck + 7),
        width: head.scalp.width * .32,
        height: head.scalp.width * .11,
      );
    }
    final p = _collars[outfit]!, g = garment;
    return Rect.fromLTWH(
      g.left + g.width * p.left,
      g.top + g.height * p.top,
      g.width * p.width,
      g.height * p.height,
    );
  }

  Rect get neckBridge {
    final opening = collarOpening;
    final top = math.max(head.mouth.bottom + 2, garment.top - 4);
    return Rect.fromLTRB(
      opening.center.dx - opening.width * .39,
      top,
      opening.center.dx + opening.width * .39,
      math.max(top + 1, opening.bottom + 1),
    );
  }

  Path get garmentMask {
    final g = garment, opening = collarOpening;
    final hole = Rect.fromLTWH(
      (opening.left + opening.width * .18 - g.left) / g.width,
      (opening.top - g.top) / g.height,
      opening.width * .64 / g.width,
      opening.height * .44 / g.height,
    );
    // Retained masters contain an opaque empty-neck insert. Expose the small
    // inner opening to the original skin material; leave the collar lip intact.
    return Path.combine(
      PathOperation.difference,
      Path()..addRect(const Rect.fromLTWH(0, 0, 1, 1)),
      // A polygon avoids conic containment precision loss when the normalized
      // opening is transformed nonuniformly to different garment dimensions.
      Path()..addPolygon([
        for (var i = 0; i < 32; i++)
          Offset(
            hole.center.dx + hole.width / 2 * math.cos(i * math.pi / 16),
            hole.center.dy + hole.height / 2 * math.sin(i * math.pi / 16),
          ),
      ], true),
    );
  }

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
