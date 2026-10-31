import 'package:flutter/material.dart';
import 'app_language.dart';
import 'l10n/generated/app_localizations.dart';
import 'menti_character_catalog.dart';
import 'menti_rewards.dart';
import 'menti_xp_store.dart';

String outfitName(AppLocalizations s, MentiOutfit outfit) => switch (outfit) {
  MentiOutfit.basic => s.evolutionBasic,
  MentiOutfit.party => s.evolutionParty,
  MentiOutfit.sport => s.evolutionSport,
  MentiOutfit.business => s.evolutionBusiness,
  MentiOutfit.festival => s.evolutionFestival,
  MentiOutfit.legendary => s.evolutionLegendary,
};

class MentiLevelIndicator extends StatelessWidget {
  const MentiLevelIndicator({super.key, required this.xp});
  final int xp;
  @override
  Widget build(BuildContext context) {
    final s = appStrings(context);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('${s.evolutionLevel(MentiXpState.levelFor(xp))} • ${s.evolutionTotal(xp)}',
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
      const SizedBox(height: 12),
      LinearProgressIndicator(
        value: MentiXpState.levelXpFor(xp) / 50,
        minHeight: 10,
        semanticsLabel: s.evolutionRemaining(MentiXpState.remainingFor(xp)),
        borderRadius: BorderRadius.circular(10),
      ),
      const SizedBox(height: 8),
      Text(s.evolutionRemaining(MentiXpState.remainingFor(xp))),
    ]);
  }
}

class MentiNextReward extends StatelessWidget {
  const MentiNextReward({super.key, required this.xp, required this.family,
    required this.unlocked, required this.assets});
  final int xp;
  final MentiCharacterFamily family;
  final Set<String> unlocked;
  final Set<String> assets;
  @override
  Widget build(BuildContext context) {
    final s = appStrings(context);
    final next = MentiRewards.next(unlocked, assets);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(s.evolutionNext, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
      const SizedBox(height: 10),
      if (next == null) Text(s.evolutionAll) else ...[
        Image.asset(next.assets[family]!, height: 160, fit: BoxFit.contain,
          semanticLabel: next.outfit == null ? s.evolutionNext : outfitName(s, next.outfit!),
          errorBuilder: (_, _, _) => Text(s.evolutionImage)),
        Text(next.outfit == null ? s.evolutionNext : outfitName(s, next.outfit!)),
        Text(s.evolutionUnlock(next.requiredLevel,
          ((next.requiredLevel - 1) * 50 - xp).clamp(0, 9007199254740991))),
      ],
      const SizedBox(height: 8),
      Text(s.evolutionRules),
    ]);
  }
}
