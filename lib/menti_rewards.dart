import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'menti_character_catalog.dart';
import 'menti_profile_storage.dart';

/// Stable reward IDs are independent of labels and storage for equipped items.
/// Future accessories can use a new kind and explicit assets in this catalog.
enum MentiRewardKind { outfit, accessory }

class MentiReward {
  const MentiReward({
    required this.id,
    required this.kind,
    required this.requiredLevel,
    required this.assets,
    this.outfit,
  });
  final String id;
  final MentiRewardKind kind;
  final int requiredLevel;
  final Map<MentiCharacterFamily, String> assets;
  final MentiOutfit? outfit;

  bool available(Set<String> bundledAssets) =>
      assets.length == MentiCharacterFamily.values.length &&
      assets.values.every(bundledAssets.contains);
}

class MentiRewards {
  static const preferenceKey = 'mennyiment_menti_rewards_v1';
  static final catalog = List<MentiReward>.unmodifiable([
    for (final outfit in MentiOutfit.values)
      MentiReward(
        id: 'outfit:${outfit.id}',
        kind: MentiRewardKind.outfit,
        requiredLevel: outfit.requiredLevel,
        outfit: outfit,
        assets: {
          for (final family in MentiCharacterFamily.values)
            family: family.assetFor(outfit),
        },
      ),
  ]);

  static Future<Set<String>> bundledAssets() async =>
      (await AssetManifest.loadFromAssetBundle(rootBundle)).listAssets().toSet();

  /// Union only: preserve unknown future IDs and the legacy equipped outfit.
  /// No XP is awarded here. A missing image cannot create a new reward.
  static Future<Set<String>> load({
    required int level,
    required Set<String> assets,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.get(preferenceKey);
    if (raw != null && (raw is! List<String>)) {
      throw StateError('Unreadable Menti rewards');
    }
    final saved = raw == null ? <String>{} : (raw as List<String>).toSet();
    final unlocked = {...saved};
    final legacy = MentiOutfit.resolve(prefs.get(MentiProfileStorage.outfitKey));
    if (legacy != null) unlocked.add('outfit:${legacy.id}');
    for (final reward in catalog) {
      if (level >= reward.requiredLevel && reward.available(assets)) {
        unlocked.add(reward.id);
      }
    }
    if (unlocked.length != saved.length) {
      try {
        if (!await prefs.setStringList(preferenceKey, unlocked.toList()..sort())) {
          throw StateError('Menti reward save failed');
        }
      } catch (_) {
        await prefs.reload();
        rethrow;
      }
    }
    return Set.unmodifiable(unlocked);
  }

  static MentiReward? next(Set<String> unlocked, Set<String> assets) {
    for (final reward in catalog) {
      if (!unlocked.contains(reward.id) && reward.available(assets)) return reward;
    }
    return null;
  }
}
