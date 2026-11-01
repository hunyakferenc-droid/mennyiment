import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../app_language.dart';
import '../menti_experience_settings.dart';
import 'menti_identity.dart';
import 'menti_identity_controller.dart';
import 'menti_visual_catalog.dart';
import 'menti_family_layout.dart';
import 'menti_premium_renderer.dart';
import 'menti_reference_rig.dart';
import 'menti_premium_motion.dart';

/// Pure, deterministic composition. Unknown IDs render a known safe layer without
/// mutating the saved identity. No timers, rewards or preference writes.
class MentiAvatarRenderer extends StatelessWidget {
  const MentiAvatarRenderer({super.key, required this.profile, this.size = 260,
    this.reaction, this.showBackground = true, this.animate = false});
  final MentiIdentityProfile profile;
  final double size;
  final String? reaction;
  final bool showBackground;
  final bool animate;

  /// Actual source files used by the current premium composition.
  static List<String> layers(MentiIdentityProfile profile, {String? reaction,
      bool showBackground = true}) => MentiPremiumComposition.layers(profile,
        reaction:reaction,showBackground:showBackground);

  /// Retained only to reproduce the immutable PR28/29 SVG evidence and fixtures.
  static List<String> legacyLayers(MentiIdentityProfile profile, {String? reaction,
      bool showBackground = true}) {
    final v = profile.visual;
    final family = MentiVisualCatalog.resolve('family', v.value('family')).id;
    MentiVisualOption option(String field) => MentiVisualCatalog.resolve(field,
      v.value(field), family: field == 'hair' ? family : null);
    final age = MentiVisualCatalog.resolve('age', v.value('age')).id;
    String asset(String field) => MentiVisualCatalog.root + option(field).asset;
    return [
      if (showBackground) asset('background'), asset('aura'),
      if (v.value('back') != 'none') asset('back'),
      MentiFamilyLayout.of(profile).core,
      '${MentiVisualCatalog.root}bases/$family-$age.svg',
      asset('outfit'), asset('style'), asset('accent'), asset('hair'),
      asset('face'), asset('eyes'),
      if (v.value('detail') != 'none') asset('detail'),
      if (v.value('neck') != 'none') asset('neck'),
      if (v.value('headwear') != 'none') asset('headwear'),
      if (v.value('glasses') != 'none') asset('glasses'),
      if (v.value('held') != 'none') asset('held'),
      if (reaction != null) MentiVisualCatalog.root +
        MentiVisualCatalog.resolve('reaction', reaction).asset,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final activeReaction = MentiExperienceScope.reactionsOf(context) ? reaction : null;
    final paths = MentiPremiumComposition.layers(profile,reaction:activeReaction,showBackground:showBackground);
    return Semantics(label: appStrings(context).avatarPreview(profile.name), image: true,
      child: ExcludeSemantics(child: RepaintBoundary(child: SizedBox(
        width: size, height: size * 1.25,
        child: MentiMaterialGate(paths: paths.where((p) => p.endsWith('.png')).toList(),
          child: animate ? MentiPremiumMotion(profile: profile,reaction: activeReaction,showBackground:showBackground)
            : MentiPremiumComposition(profile: profile, reaction: activeReaction,showBackground:showBackground)),
      ))));
  }
}

/// One registration contract for full avatars and cropped option thumbnails.
class MentiAssetLayer extends StatelessWidget {
  const MentiAssetLayer({super.key, required this.path});
  final String path;
  static const core = '${MentiVisualCatalog.root}core/menti-body.png';
  static bool isCore(String path) => path == core || path.contains('/identities/');
  static const crownCap = '${MentiVisualCatalog.root}core/crown-cap.png';
  @override
  Widget build(BuildContext context) {
    if (path == crownCap) {
      return LayoutBuilder(builder: (context, constraints) => Stack(children: [
        Positioned(left: constraints.maxWidth * .10625, top: 0,
          width: constraints.maxWidth * .8375, height: constraints.maxHeight * .28,
          child: Image.asset(path, key: ValueKey(path), fit: BoxFit.fill,
            excludeFromSemantics: true, gaplessPlayback: true)),
      ]));
    }
    if (path.endsWith('.png')) {
      return Image.asset(path, key: ValueKey(path), fit: BoxFit.fill,
        cacheWidth: 960, excludeFromSemantics: true, gaplessPlayback: true);
    }
    return SvgPicture.asset(path, key: ValueKey(path), fit: BoxFit.fill,
      excludeFromSemantics: true,
      errorBuilder: (_, _, _) => Center(child: Icon(Icons.broken_image_outlined,
        semanticLabel: appStrings(context).evolutionImage)));
  }
}

/// Never flashes eyes/clothes without the material body while bitmaps decode.
/// Shares the exact resized image cache key used by the rendered core.
class MentiMaterialGate extends StatefulWidget {
  const MentiMaterialGate({super.key, required this.paths, required this.child});
  final List<String> paths;
  final Widget child;
  @override
  State<MentiMaterialGate> createState() => _MentiMaterialGateState();
}
class _MentiMaterialGateState extends State<MentiMaterialGate> {
  Future<void>? _ready;
  Future<void> _prepare() async {
    var failed = false;
    await Future.wait(widget.paths.map((path) => precacheImage(
      MentiAssetLayer.isCore(path)
        ? ResizeImage(AssetImage(path), width: 960)
        : AssetImage(path), context,
      onError: (_, _) { failed = true; },
    )));
    if (failed) throw const FormatException('Menti material asset unavailable');
  }
  @override
  void didChangeDependencies() { super.didChangeDependencies(); _ready ??= _prepare(); }
  @override
  void didUpdateWidget(covariant MentiMaterialGate oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.paths.join('|') != widget.paths.join('|')) _ready = _prepare();
  }
  @override
  Widget build(BuildContext context) => FutureBuilder<void>(future: _ready,
    builder: (context, snapshot) {
      if (snapshot.hasError) return const Center(child: Icon(Icons.broken_image_outlined));
      if (snapshot.connectionState != ConnectionState.done) {
        return const Center(child: Icon(Icons.face_retouching_natural, color: Color(0xFFC48A43)));
      }
      return widget.child;
    });
}

class MentiFittedLayer extends StatelessWidget {
  const MentiFittedLayer({super.key, required this.path, required this.layout});
  final String path;
  final MentiFamilyLayout layout;
  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, constraints) =>
    Transform(transform: layout.forPath(path).matrix(constraints.maxWidth, constraints.maxHeight),
      child: MentiAssetLayer(path: path)));
}

class MentiPreviewRenderer extends StatelessWidget {
  const MentiPreviewRenderer({super.key, required this.option, this.size = 120, this.profile});
  final MentiVisualOption option;
  final double size;
  final MentiIdentityProfile? profile;
  static MentiIdentityProfile previewProfile(MentiIdentityProfile base, MentiVisualOption option) {
    if (option.field == 'reaction') { return base.copyWith(reaction:
      MentiReactionProfile({...base.reaction.toJson(), 'style': option.id})); }
    final values = {option.field: option.id};
    if (option.field == 'family') {
      values['hair'] = MentiReferenceRig.of(option.id,
      MentiVisualCatalog.resolve('age', base.visual.value('age')).id).hairId;
    }
    if (option.field == 'style') { values['outfit'] =
      {'classic':'basic','sporty':'sport'}[option.id] ?? option.id; }
    return base.copyWith(visual: base.visual.withValues(values));
  }
  static Rect cropFor(MentiVisualOption option, {MentiIdentityProfile? profile}) {
    Rect crop;
    if (option.field == 'family' || option.field == 'age') return const Rect.fromLTWH(0,0,320,400);
    if (option.field == 'held' && option.id == 'notebook') {
      crop = const Rect.fromLTWH(0, 225, 100, 115);
    } else if (option.field == 'held' && option.id != 'none') {
      crop = const Rect.fromLTWH(230, 225, 90, 115);
    } else {
      final box = MentiPremiumComposition.previewCrops[option.field]!;
      crop = Rect.fromLTWH(box[0],box[1],box[2],box[3]);
    }
    return crop.intersect(const Rect.fromLTWH(0,0,320,400));
  }
  @override
  Widget build(BuildContext context) {
    final candidate = previewProfile(profile ?? MentiIdentityProfile(), option);
    final crop = cropFor(option, profile: candidate);
    return ExcludeSemantics(child: SizedBox(width: size, height: size,
      child: FittedBox(fit: BoxFit.contain, child: SizedBox(width: crop.width,height: crop.height,
        child: ClipRect(child: OverflowBox(alignment: Alignment.topLeft,
          minWidth: 320,maxWidth: 320,minHeight: 400,maxHeight: 400,
          child: Transform.translate(offset: Offset(-crop.left,-crop.top),
            child: MentiAvatarRenderer(profile: candidate,size: 320,
              reaction: option.field == 'reaction' ? candidate.reaction.style : null)),
        )),
      )),
    ));
  }
}

class MentiReactionRenderer extends StatelessWidget {
  const MentiReactionRenderer({super.key, required this.profile, this.mood, this.size = 96});
  final MentiIdentityProfile profile;
  final String? mood;
  final double size;
  @override
  Widget build(BuildContext context) => MentiAvatarRenderer(profile: profile,
    reaction: mood ?? profile.reaction.style, size: size);
}

/// Runtime screens share the saved identity. Legacy rendering is only available
/// to standalone consumers that have not mounted the application identity scope.
class MentiCurrentAvatar extends StatelessWidget {
  const MentiCurrentAvatar({super.key, required this.legacyChild,
    this.size = 160, this.reaction, this.outfit});
  final Widget legacyChild;
  final double size;
  final String? reaction;
  final String? outfit;
  @override
  Widget build(BuildContext context) {
    final identity = MentiIdentityScope.of(context);
    if (identity == null) return legacyChild;
    if (!identity.ready) { return SizedBox(width: size, height: size * 1.25,
      child: Center(child: identity.error == null ? const CircularProgressIndicator()
        : Text(appStrings(context).avatarReadError))); }
    var profile = identity.profile;
    if (outfit != null) { profile = profile.copyWith(
      visual: profile.visual.withValues({'outfit': outfit!})); }
    return MentiAvatarRenderer(profile: profile, size: size, animate:true,
      reaction: reaction == 'personality' ? profile.reaction.style : reaction);
  }
}
