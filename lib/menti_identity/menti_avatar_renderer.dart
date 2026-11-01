import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../app_language.dart';
import '../menti_experience_settings.dart';
import 'menti_identity.dart';
import 'menti_visual_catalog.dart';

/// Pure, deterministic composition. Unknown IDs render a known safe layer without
/// mutating the saved identity. No timers, rewards or preference writes.
class MentiAvatarRenderer extends StatelessWidget {
  const MentiAvatarRenderer({super.key, required this.profile, this.size = 260,
    this.reaction, this.showBackground = true});
  final MentiIdentityProfile profile;
  final double size;
  final String? reaction;
  final bool showBackground;

  static List<String> layers(MentiIdentityProfile profile, {String? reaction,
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
    return Semantics(label: appStrings(context).avatarPreview(profile.name), image: true,
      child: ExcludeSemantics(child: RepaintBoundary(child: SizedBox(
        width: size, height: size * 1.25,
        child: Stack(fit: StackFit.expand, children: [
          for (final path in layers(profile, reaction: activeReaction, showBackground: showBackground))
            SvgPicture.asset(path, key: ValueKey(path), fit: BoxFit.contain,
              excludeFromSemantics: true,
              errorBuilder: (_, _, _) => Center(child: Icon(Icons.broken_image_outlined,
                semanticLabel: appStrings(context).evolutionImage))),
        ]),
      ))));
  }
}

class MentiPreviewRenderer extends StatelessWidget {
  const MentiPreviewRenderer({super.key, required this.option, this.size = 76});
  final MentiVisualOption option;
  final double size;
  @override
  Widget build(BuildContext context) => SvgPicture.asset(
    MentiVisualCatalog.root + option.preview, width: size, height: size * 1.25,
    fit: BoxFit.contain, excludeFromSemantics: true,
    errorBuilder: (_, _, _) => const Icon(Icons.broken_image_outlined));
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
