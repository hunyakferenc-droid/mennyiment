import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'menti_identity.dart';
import 'menti_visual_catalog.dart';
import 'menti_premium_atlas.dart';
import 'menti_reference_rig.dart';

/// Original high-resolution material sheets are shared by the image cache.
/// Runtime crops avoid hundreds of duplicate files and preserve source pixels.
class MentiPremiumSprite extends StatelessWidget {
  const MentiPremiumSprite({
    super.key,
    required this.sprite,
    this.color,
    this.sourcePart,
  });
  final String sprite;
  final Color? color;
  final Rect? sourcePart;
  @override
  Widget build(BuildContext context) {
    final group = sprite.split('/').first;
    final original = MentiPremiumAtlas.rects[sprite]!;
    final part = sourcePart;
    final rect = part == null
        ? original
        : Rect.fromLTWH(
            original.left + part.left * original.width,
            original.top + part.top * original.height,
            part.width * original.width,
            part.height * original.height,
          );
    return Image(
      image: AssetImage('${MentiPremiumAtlas.root}$group.png'),
      excludeFromSemantics: true,
      gaplessPlayback: true,
      frameBuilder: (context, child, frame, sync) => frame == null
          ? const SizedBox.shrink()
          : LayoutBuilder(
              builder: (context, c) => ClipRect(
                child: OverflowBox(
                  alignment: Alignment.topLeft,
                  minWidth: c.maxWidth,
                  maxWidth: double.infinity,
                  minHeight: c.maxHeight,
                  maxHeight: double.infinity,
                  child: Transform.translate(
                    offset: Offset(
                      -rect.left * c.maxWidth / rect.width,
                      -rect.top * c.maxHeight / rect.height,
                    ),
                    child: SizedBox(
                      width: _sizes[group]!.width * c.maxWidth / rect.width,
                      height: _sizes[group]!.height * c.maxHeight / rect.height,
                      child: color == null
                          ? child
                          : ColorFiltered(
                              colorFilter: group == 'hair'
                                  ? const ColorFilter.matrix([
                                      .22,
                                      .52,
                                      .06,
                                      0,
                                      62,
                                      .22,
                                      .52,
                                      .06,
                                      0,
                                      62,
                                      .22,
                                      .52,
                                      .06,
                                      0,
                                      68,
                                      0,
                                      0,
                                      0,
                                      1,
                                      0,
                                    ])
                                  : ColorFilter.mode(
                                      color!,
                                      BlendMode.modulate,
                                    ),
                              child: child,
                            ),
                    ),
                  ),
                ),
              ),
            ),
      fit: BoxFit.fill,
    );
  }

  static const _sizes = {
    'bodies': Size(1121, 1403),
    'outfits': Size(1254, 1254),
    'hair': Size(1774, 887),
    'features': Size(2172, 724),
    'headwear': Size(1254, 1254),
  };
}

class MentiAtlasComposition extends StatelessWidget {
  const MentiAtlasComposition({
    super.key,
    required this.profile,
    this.reaction,
    this.showBackground = true,
    this.blink = false,
    this.wink = false,
    this.smile = false,
  });
  final MentiIdentityProfile profile;
  final String? reaction;
  final bool showBackground, blink, wink, smile;

  static const previewCrops = <String, List<double>>{
    'style': [85, 200, 150, 65],
    'face': [65, 112, 190, 62],
    'eyes': [60, 60, 200, 90],
    'hair': [0, 0, 320, 205],
    'headwear': [0, 0, 320, 145],
    'outfit': [25, 155, 270, 245],
    'glasses': [50, 65, 220, 85],
    'neck': [80, 165, 160, 75],
    'held': [0, 220, 320, 120],
    'detail': [75, 90, 170, 90],
    'back': [20, 150, 280, 180],
    'accent': [65, 160, 190, 225],
    'background': [0, 0, 320, 400],
    'aura': [0, 0, 320, 400],
    'reaction': [0, 0, 320, 400],
  };
  static List<String> layers(
    MentiIdentityProfile p, {
    String? reaction,
    bool showBackground = true,
  }) {
    String asset(String f) => MentiVisualCatalog.root + resolve(p, f).asset;
    return [
      if (showBackground) asset('background'),
      asset('aura'),
      if (resolve(p, 'back').id != 'none') asset('back'),
      '${MentiPremiumAtlas.root}bodies.png',
      '${MentiPremiumAtlas.root}hair.png',
      '${MentiPremiumAtlas.root}outfits.png',
      asset('style'),
      '${MentiPremiumAtlas.root}features.png',
      for (final field in ['detail', 'neck'])
        if (resolve(p, field).id != 'none') asset(field),
      if (resolve(p, 'headwear').id != 'none')
        '${MentiPremiumAtlas.root}headwear.png',
      for (final field in ['glasses', 'held'])
        if (resolve(p, field).id != 'none') asset(field),
      if (reaction != null)
        MentiVisualCatalog.root +
            MentiVisualCatalog.resolve('reaction', reaction).asset,
    ];
  }

  static const sheets = ['bodies', 'outfits', 'hair', 'features', 'headwear'];
  static List<String> get assets => [
    for (final sheet in sheets) '${MentiPremiumAtlas.root}$sheet.png',
  ];
  static MentiVisualOption resolve(MentiIdentityProfile p, String f) =>
      MentiVisualCatalog.resolve(
        f,
        p.visual.value(f),
        family: f == 'hair'
            ? MentiVisualCatalog.resolve('family', p.visual.value('family')).id
            : null,
      );
  static List<String> sprites(MentiIdentityProfile p) => [
    'bodies/${resolve(p, 'family').id}-${resolve(p, 'age').id}',
    for (final side in ['left', 'right'])
      'bodies/${resolve(p, 'family').id}-${resolve(p, 'age').id}-$side-hand',
    'outfits/${resolve(p, 'outfit').id}',
    'hair/${resolve(p, 'hair').id}',
    'features/face:${resolve(p, 'face').id}',
    'features/eyes:${resolve(p, 'eyes').id}',
    if (resolve(p, 'headwear').id != 'none')
      'headwear/${resolve(p, 'headwear').id}',
  ];
  @override
  Widget build(BuildContext context) {
    String id(String f) => resolve(profile, f).id;
    final family = id('family'), age = id('age');
    final headWidth =
        (family == 'girl'
            ? .49
            : family == 'neutral'
            ? .55
            : .52) *
        (age == 'adult'
            ? .93
            : age == 'veteran'
            ? 1.04
            : 1);
    final outfitWidth =
        (family == 'girl'
            ? .60
            : family == 'neutral'
            ? .70
            : .66) +
        (age == 'veteran'
            ? .035
            : age == 'adult'
            ? -.015
            : 0);
    final outfitTop = age == 'adult'
        ? .375
        : age == 'veteran'
        ? .395
        : .405;
    final outfitHeight = .985 - outfitTop;
    final eyeTop = age == 'adult'
        ? .145
        : age == 'veteran'
        ? .15
        : .17;
    final mouthScale = age == 'adult'
        ? .82
        : age == 'veteran'
        ? .90
        : 1.0;
    final mouthTop = age == 'adult'
        ? .28
        : age == 'veteran'
        ? .29
        : .305;
    final hx = (1 - headWidth) / 2;
    final hair = id('hair').split('-').last;
    final longHair =
        hair == 'braid' ||
        (family == 'girl' && ['waves', 'curls', 'crest'].contains(hair));
    final accent = <String, Color>{
      'violet': const Color(0xFFCCAEEA),
      'blue': const Color(0xFFBAD7F2),
      'mint': const Color(0xFFB9EAD8),
      'rose': const Color(0xFFF1BFD3),
      'orange': const Color(0xFFFFD4A0),
    }[id('accent')];
    final hrect = Rect.fromLTWH(
      hx - .035,
      .005,
      headWidth + .07,
      longHair ? .46 : .34,
    );
    final eyes = blink
        ? 'blink'
        : wink
        ? 'wink'
        : id('eyes');
    Widget sprite(String s, Rect r, {Color? color, Rect? sourcePart}) =>
        Positioned.fromRect(
          rect: Rect.fromLTWH(
            r.left * 320,
            r.top * 400,
            r.width * 320,
            r.height * 400,
          ),
          child: s.endsWith('-hand')
              ? ClipPath(
                  clipper: _HandClipper(MentiPremiumAtlas.handOutlines[s]!),
                  child: MentiPremiumSprite(sprite: s),
                )
              : s.startsWith('hair/') ||
                    s == 'headwear/hood' ||
                    s == 'headwear/headphones'
              ? ClipPath(
                  clipper: _HairFaceClipper(
                    (s == 'headwear/hood' || s == 'headwear/headphones')
                        ? Rect.fromLTWH(
                            (hx + .02 - r.left) / r.width,
                            (.105 - r.top) / r.height,
                            (headWidth - .04) / r.width,
                            .33 / r.height,
                          )
                        : Rect.fromLTWH(
                            (hx + .055 - r.left) / r.width,
                            (eyeTop + .01 - r.top) / r.height,
                            (headWidth - .11) / r.width,
                            .235 / r.height,
                          ),
                  ),
                  child: MentiPremiumSprite(
                    sprite: s,
                    color: color,
                    sourcePart: sourcePart,
                  ),
                )
              : MentiPremiumSprite(
                  sprite: s,
                  color: color,
                  sourcePart: sourcePart,
                ),
        );
    Widget vector(String field, {Rect? target}) {
      final o = resolve(profile, field);
      final path = MentiVisualCatalog.root + o.asset;
      if (target == null) {
        return Positioned.fill(
          child: SvgPicture.asset(path, key: ValueKey(path), fit: BoxFit.fill),
        );
      }
      final crop = MentiVisualCatalog.previewCrops[field]!;
      return Positioned(
        left: target.left * 320,
        top: target.top * 400,
        width: target.width * 320,
        height: target.height * 400,
        child: ClipRect(
          child: OverflowBox(
            alignment: Alignment.topLeft,
            minWidth: 0,
            maxWidth: double.infinity,
            minHeight: 0,
            maxHeight: double.infinity,
            child: Transform.translate(
              offset: Offset(
                -crop[0] * target.width * 320 / crop[2],
                -crop[1] * target.height * 400 / crop[3],
              ),
              child: SizedBox(
                width: 320 * target.width * 320 / crop[2],
                height: 400 * target.height * 400 / crop[3],
                child: SvgPicture.asset(
                  path,
                  key: ValueKey(path),
                  fit: BoxFit.fill,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return FittedBox(
      fit: BoxFit.fill,
      child: SizedBox(
        width: 320,
        height: 400,
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            if (showBackground) vector('background'), vector('aura'),
            if (id('back') != 'none')
              vector('back', target: const Rect.fromLTWH(.12, .40, .76, .37)),
            // Base skin remains behind equipment; feet are hidden under fitted shoes.
            Positioned.fill(
              child: ClipPath(
                clipper: _BodyClipper(),
                child: Stack(
                  children: [
                    sprite(
                      'bodies/$family-$age',
                      const Rect.fromLTWH(.20, .04, .60, .93),
                    ),
                  ],
                ),
              ),
            ),
            if (longHair)
              sprite(
                'hair/${id('hair')}',
                hrect,
                color: age == 'veteran' ? const Color(0xFFE3DFE8) : null,
              ),
            for (final right in [false, true])
              sprite(
                'bodies/$family-$age-${right ? 'right' : 'left'}-hand',
                Rect.fromLTWH(
                  right
                      ? (1 + outfitWidth) / 2 - .135
                      : (1 - outfitWidth) / 2 + .02,
                  outfitTop + outfitHeight * .38,
                  .115,
                  .14,
                ),
              ),
            sprite(
              'outfits/${id('outfit')}',
              Rect.fromLTWH(
                (1 - outfitWidth) / 2,
                outfitTop,
                outfitWidth,
                outfitHeight,
              ),
              color: accent,
            ),
            vector('style', target: const Rect.fromLTWH(.37, .53, .26, .10)),
            sprite(
              'features/face:${smile ? 'cheerful' : id('face')}',
              Rect.fromLTWH(
                .5 - .14 * mouthScale,
                mouthTop,
                .28 * mouthScale,
                .105 * mouthScale,
              ),
            ),
            sprite(
              'features/eyes:$eyes',
              Rect.fromLTWH(
                hx + .07,
                eyeTop,
                headWidth - .14,
                age == 'young' ? .155 : .14,
              ),
            ),
            if (!longHair)
              sprite(
                'hair/${id('hair')}',
                hrect,
                color: age == 'veteran' ? const Color(0xFFE3DFE8) : null,
              ),
            if (id('detail') != 'none')
              vector('detail', target: const Rect.fromLTWH(.28, .28, .44, .09)),
            if (id('neck') != 'none')
              vector('neck', target: const Rect.fromLTWH(.33, .43, .34, .13)),
            if (id('headwear') != 'none')
              sprite('headwear/${id('headwear')}', switch (id('headwear')) {
                'headphones' => Rect.fromLTWH(
                  hx - .12,
                  .07,
                  headWidth + .24,
                  .30,
                ),
                'hood' => Rect.fromLTWH(hx - .04, .045, headWidth + .08, .40),
                'party-hat' => const Rect.fromLTWH(.34, 0, .32, .20),
                _ => Rect.fromLTWH(hx - .025, .005, headWidth + .05, .20),
              }),
            if (id('glasses') != 'none')
              vector(
                'glasses',
                target: Rect.fromLTWH(hx + .055, .215, headWidth - .11, .105),
              ),
            if (id('held') != 'none')
              vector('held', target: const Rect.fromLTWH(.08, .59, .84, .25)),
            if (reaction != null)
              Positioned.fill(
                child: SvgPicture.asset(
                  MentiVisualCatalog.root +
                      MentiVisualCatalog.resolve('reaction', reaction!).asset,
                  key: ValueKey(
                    MentiVisualCatalog.root +
                        MentiVisualCatalog.resolve('reaction', reaction!).asset,
                  ),
                  fit: BoxFit.fill,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _BodyClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) => Path()
    ..addRect(Rect.fromLTWH(0, 0, size.width, size.height * .41))
    ..addRect(
      Rect.fromLTWH(
        size.width * .32,
        size.height * .40,
        size.width * .36,
        size.height * .50,
      ),
    );
  @override
  bool shouldReclip(_BodyClipper oldClipper) => false;
}

class _HairFaceClipper extends CustomClipper<Path> {
  const _HairFaceClipper(this.face);
  final Rect face;
  @override
  Path getClip(Size size) => Path()
    ..fillType = PathFillType.evenOdd
    ..addRect(Offset.zero & size)
    ..addOval(
      Rect.fromLTWH(
        face.left * size.width,
        face.top * size.height,
        face.width * size.width,
        face.height * size.height,
      ),
    );
  @override
  bool shouldReclip(_HairFaceClipper oldClipper) => face != oldClipper.face;
}

class _HandClipper extends CustomClipper<Path> {
  const _HandClipper(this.points);
  final List<Offset> points;
  @override
  Path getClip(Size size) => Path()
    ..addPolygon([
      for (final point in points)
        Offset(point.dx * size.width, point.dy * size.height),
    ], true);
  @override
  bool shouldReclip(_HandClipper oldClipper) => points != oldClipper.points;
}

/// 2.2.1: the nine complete source characters define anatomy and materials.
/// Native regions stay registered together. Equipment adapts to that rig.
class MentiPremiumComposition extends StatelessWidget {
  const MentiPremiumComposition({
    super.key,
    required this.profile,
    this.reaction,
    this.showBackground = true,
    this.blink = false,
    this.wink = false,
    this.smile = false,
  });
  final MentiIdentityProfile profile;
  final String? reaction;
  final bool showBackground, blink, wink, smile;
  static const previewCrops = <String, List<double>>{
    'style': [95, 160, 130, 100],
    'face': [80, 75, 170, 85],
    'eyes': [80, 40, 170, 100],
    'hair': [35, 0, 250, 190],
    'headwear': [35, 0, 250, 145],
    'outfit': [40, 145, 240, 255],
    'glasses': [80, 45, 170, 100],
    'neck': [95, 120, 140, 80],
    'held': [0, 210, 320, 125],
    'detail': [80, 65, 170, 90],
    'back': [30, 130, 260, 235],
    'accent': [60, 135, 210, 265],
    'background': [0, 0, 320, 400],
    'aura': [0, 0, 320, 400],
    'reaction': [0, 0, 320, 400],
  };
  static MentiVisualOption resolve(MentiIdentityProfile p, String f) =>
      MentiAtlasComposition.resolve(p, f);
  static const sheets = MentiAtlasComposition.sheets;
  static List<String> get assets => [
    ...MentiReferenceRig.assets,
    ...MentiAtlasComposition.assets,
  ];
  // Legacy atlas indexing remains available for archive integrity regressions.
  static List<String> sprites(MentiIdentityProfile p) =>
      MentiAtlasComposition.sprites(p);
  static List<String> layers(
    MentiIdentityProfile p, {
    String? reaction,
    bool showBackground = true,
  }) {
    final rig = MentiReferenceRig.of(
      resolve(p, 'family').id,
      resolve(p, 'age').id,
    );
    return [
      if (showBackground)
        MentiVisualCatalog.root + resolve(p, 'background').asset,
      MentiVisualCatalog.root + resolve(p, 'aura').asset,
      if (resolve(p, 'back').id != 'none')
        MentiVisualCatalog.root + resolve(p, 'back').asset,
      resolve(p, 'hair').id == rig.hairId
          ? rig.asset
          : rig.asset.replaceFirst('.png', '-hairless.png'),
      if (resolve(p, 'outfit').id != 'basic') ...[
        '${MentiPremiumAtlas.root}outfits.png',
        rig.asset,
      ],
      if (resolve(p, 'hair').id != rig.hairId)
        '${MentiPremiumAtlas.root}hair.png',
      if (resolve(p, 'headwear').id != 'none')
        '${MentiPremiumAtlas.root}headwear.png',
      for (final f in ['style', 'detail', 'neck', 'glasses', 'held'])
        if (resolve(p, f).id != 'none' &&
            (f != 'style' || resolve(p, f).id != 'classic'))
          MentiVisualCatalog.root + resolve(p, f).asset,
      if (reaction != null)
        MentiVisualCatalog.root +
            MentiVisualCatalog.resolve('reaction', reaction).asset,
    ];
  }

  @override
  Widget build(BuildContext context) {
    String id(String f) => resolve(profile, f).id;
    final rig = MentiReferenceRig.of(id('family'), id('age'));
    final nativeHair = id('hair') == rig.hairId;
    final nativeOutfit = id('outfit') == 'basic';
    final face = rig.register(rig.face);
    final neckY =
        MentiReferenceRig.target.top +
        rig.neckY * MentiReferenceRig.target.height / 820;
    final accent = <String, Color>{
      'violet': const Color(0xFFD9BFF5),
      'blue': const Color(0xFFB5D9FC),
      'mint': const Color(0xFFB1E8D0),
      'rose': const Color(0xFFF6BDDA),
      'orange': const Color(0xFFFFC57E),
    }[id('accent')];
    final full = Path()..addRect(const Rect.fromLTWH(0, 0, 320, 400));
    final head = nativeHair
        ? Path.combine(
            PathOperation.union,
            Path()..addRect(Rect.fromLTWH(0, 0, 320, neckY - 12)),
            rig.mask('headSkin'),
          )
        : rig.mask('cleanHeadSkin');
    Widget plate({Path? part, Color? tint, bool expression = false}) =>
        Positioned.fill(
          child: MentiReferencePlate(
            rig: rig,
            hairless: !nativeHair,
            part: part,
            tint: tint,
            eyeStyle: expression ? id('eyes') : 'round',
            faceStyle: expression
                ? (smile ? 'cheerful' : id('face'))
                : 'cheerful',
            blink: expression && blink,
            wink: expression && wink,
          ),
        );
    Widget sprite(String s, Rect target, {Color? color, Path? mask}) =>
        Positioned.fromRect(
          rect: target,
          child: ClipPath(
            clipper: _RegisteredClipper(mask),
            child: MentiPremiumSprite(sprite: s, color: color),
          ),
        );
    Widget vector(String field, {Rect? target}) {
      final path = MentiVisualCatalog.root + resolve(profile, field).asset;
      if (target == null) {
        return Positioned.fill(
          child: SvgPicture.asset(path, key: ValueKey(path), fit: BoxFit.fill),
        );
      }
      final crop = MentiVisualCatalog.previewCrops[field]!;
      return Positioned.fromRect(
        rect: target,
        child: ClipRect(
          child: OverflowBox(
            alignment: Alignment.topLeft,
            minWidth: 0,
            maxWidth: double.infinity,
            minHeight: 0,
            maxHeight: double.infinity,
            child: Transform.translate(
              offset: Offset(
                -crop[0] * target.width / crop[2],
                -crop[1] * target.height / crop[3],
              ),
              child: SizedBox(
                width: 320 * target.width / crop[2],
                height: 400 * target.height / crop[3],
                child: SvgPicture.asset(
                  path,
                  key: ValueKey(path),
                  fit: BoxFit.fill,
                ),
              ),
            ),
          ),
        ),
      );
    }

    // A native full master remains intact whenever the selected hair and outfit
    // match it. Other equipment is scaled to the native neck and foot anchors.
    final outfitTarget = Rect.fromLTRB(
      face.center.dx - face.width * (id('family') == 'girl' ? .87 : .84),
      neckY,
      face.center.dx + face.width * (id('family') == 'girl' ? .87 : .84),
      397,
    );
    final hairSource = MentiPremiumAtlas.rects['hair/${id('hair')}']!;
    final hairWidth = face.width + 32;
    final hairHeight = hairWidth * hairSource.height / hairSource.width;
    final hairTarget = Rect.fromLTWH(
      face.center.dx - hairWidth / 2,
      face.top - hairHeight * .30,
      hairWidth,
      hairHeight,
    );
    // Hair and head equipment leave the original, family-specific face visible.
    Path faceWindow(Rect target) => Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(const Rect.fromLTWH(0, 0, 1, 1))
      ..addOval(
        Rect.fromLTWH(
          (face.left + 8 - target.left) / target.width,
          (face.top + 9 - target.top) / target.height,
          (face.width - 16) / target.width,
          (face.height - 18) / target.height,
        ),
      );
    final hatSource = MentiPremiumAtlas.rects['headwear/${id('headwear')}'];
    final hatWidth = face.width + 20;
    final hatHeight = hatSource == null
        ? 0.0
        : hatWidth * hatSource.height / hatSource.width;
    final eyeTop = rig.register(rig.eyes).top;
    final hat = switch (id('headwear')) {
      'headphones' => Rect.fromLTRB(
        face.left - 25,
        face.top - 40,
        face.right + 25,
        face.bottom - 4,
      ),
      'hood' => Rect.fromLTRB(
        face.left - 25,
        face.top - 28,
        face.right + 25,
        face.bottom + 12,
      ),
      _ => Rect.fromLTWH(
        face.center.dx - hatWidth / 2,
        eyeTop - 6 - hatHeight,
        hatWidth,
        hatHeight,
      ),
    };
    return FittedBox(
      fit: BoxFit.fill,
      child: SizedBox(
        width: 320,
        height: 400,
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            if (showBackground) vector('background'),
            vector('aura'),
            if (id('back') != 'none')
              vector('back', target: const Rect.fromLTWH(45, 145, 230, 205)),
            if (nativeOutfit) ...[
              plate(part: full, expression: true),
              if (accent != null)
                plate(part: rig.mask('garments'), tint: accent),
            ] else ...[
              // Real source hands stay behind the sleeve edge, never generic
              // hand shapes or a body-sized rectangle sampled from an atlas.
              for (final right in [false, true])
                Positioned.fill(
                  child: LayoutBuilder(
                    builder: (context, c) {
                      final path = rig.mask(right ? 'rightHand' : 'leftHand');
                      final bounds = path.getBounds();
                      final target = Rect.fromLTWH(
                        right
                            ? outfitTarget.right - outfitTarget.width * .16 - 6
                            : outfitTarget.left + 6,
                        neckY + (397 - neckY) * .39,
                        outfitTarget.width * .16,
                        outfitTarget.width * .225,
                      );
                      return Transform(
                        transform: Matrix4.identity()
                          ..translateByDouble(
                            target.left -
                                bounds.left * target.width / bounds.width,
                            target.top -
                                bounds.top * target.height / bounds.height,
                            0,
                            1,
                          )
                          ..scaleByDouble(
                            target.width / bounds.width,
                            target.height / bounds.height,
                            1,
                            1,
                          ),
                        child: MentiReferencePlate(rig: rig, part: path),
                      );
                    },
                  ),
                ),
              plate(part: head, expression: true),
              sprite('outfits/${id('outfit')}', outfitTarget, color: accent),
              if (nativeHair) plate(part: rig.mask('hair')),
            ],
            if (!nativeHair)
              sprite(
                'hair/${id('hair')}',
                hairTarget,
                color: id('age') == 'veteran' ? const Color(0xFFE3DFE8) : null,
                mask: faceWindow(hairTarget),
              ),
            if (id('style') != 'classic')
              vector(
                'style',
                target: Rect.fromLTWH(face.center.dx - 30, neckY + 55, 60, 42),
              ),
            if (id('detail') != 'none')
              vector(
                'detail',
                target: Rect.fromLTWH(
                  face.left,
                  face.center.dy,
                  face.width,
                  35,
                ),
              ),
            if (id('neck') != 'none')
              vector(
                'neck',
                target: Rect.fromLTWH(face.center.dx - 36, neckY - 7, 72, 50),
              ),
            if (id('headwear') != 'none')
              sprite(
                'headwear/${id('headwear')}',
                hat,
                mask: ['hood', 'headphones'].contains(id('headwear'))
                    ? faceWindow(hat)
                    : null,
              ),
            if (id('glasses') != 'none')
              vector('glasses', target: rig.register(rig.eyes).inflate(4)),
            if (id('held') != 'none')
              vector('held', target: Rect.fromLTWH(25, neckY + 83, 270, 105)),
            if (reaction != null)
              Positioned.fill(
                child: SvgPicture.asset(
                  MentiVisualCatalog.root +
                      MentiVisualCatalog.resolve('reaction', reaction!).asset,
                  key: ValueKey(
                    MentiVisualCatalog.root +
                        MentiVisualCatalog.resolve('reaction', reaction!).asset,
                  ),
                  fit: BoxFit.fill,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _RegisteredClipper extends CustomClipper<Path> {
  const _RegisteredClipper(this.path);
  final Path? path;
  @override
  Path getClip(Size size) => path == null
      ? (Path()..addRect(Offset.zero & size))
      : path!.transform(
          Matrix4.diagonal3Values(size.width, size.height, 1).storage,
        );
  @override
  bool shouldReclip(_RegisteredClipper old) => path != old.path;
}
