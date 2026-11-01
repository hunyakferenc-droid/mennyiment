import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'daily_menti_store.dart';
import 'drink_journal.dart';
import 'menti_character_catalog.dart';
import 'menti_identity/menti_identity.dart';
import 'menti_identity/menti_identity_store.dart';
import 'menti_character_setup.dart';
import 'menti_completion.dart';
import 'menti_profile_storage.dart';
import 'menti_reactions.dart';
import 'menti_xp_store.dart';
import 'personal_goal_store.dart';
import 'weekly_challenges.dart';

enum HubReadStatus { missing, ready, error }

/// Ephemeral read result, never a second persistence source.
class HubRead<T> {
  const HubRead.missing() : status = HubReadStatus.missing, value = null;
  const HubRead.error() : status = HubReadStatus.error, value = null;
  const HubRead.ready(this.value) : status = HubReadStatus.ready;
  final HubReadStatus status;
  final T? value;

  static HubRead<T> decode<T>(Object? raw, T Function(Object) reader) {
    if (raw == null) return HubRead<T>.missing();
    try {
      return HubRead<T>.ready(reader(raw));
    } catch (error, stack) {
      // Do not log raw values or exception messages containing personal content.
      debugPrint('Personal hub read failure: ${error.runtimeType}\n$stack');
      return HubRead<T>.error();
    }
  }
}

class HubProfile {
  const HubProfile(this.name, this.family, this.outfit, {this.identity});
  final MentiIdentityProfile? identity;
  final String name;
  final MentiCharacterFamily family;
  final MentiOutfit outfit;
  String get asset => family.assetFor(outfit);
}

class HubXp {
  HubXp(Object raw) : state = MentiXpStore.readCurrent(raw) {
    final document = jsonDecode(raw as String) as Map;
    hasDays = document['days'] is List;
  }
  final MentiXpState state;
  late final bool hasDays;
}

class HubChallenge {
  const HubChallenge({required this.id, required this.title, required this.status,
    required this.target, required this.days, required this.count});
  final String id;
  final String title;
  final String status;
  final int target;
  final Set<String>? days;
  final int? count;
  bool get completed => status == 'active' && count != null && count! >= target;
}

class PersonalHubSnapshot {
  PersonalHubSnapshot._({required this.now, required this.profile, required this.xp,
    required this.daily, required this.journal, required this.goals,
    required this.challenges, required this.wellbeing});
  final DateTime now;
  final HubRead<HubProfile> profile;
  final HubRead<HubXp> xp;
  final HubRead<Map<String, dynamic>> daily;
  final HubRead<List<Drink>> journal;
  final HubRead<Map<String, dynamic>> goals;
  final HubRead<Map<String, dynamic>> challenges;
  final HubRead<Set<String>> wellbeing;
  DateTime get week => mentiMonday(now);
  DateTime get end => mentiCalendarDay(week, 7);

  factory PersonalHubSnapshot.fromValues(Map<String, Object?> values, DateTime time) {
    final now = time.toLocal();
    final family = values[MentiProfileStorage.characterStyleKey] ??
        (values[MentiProfileStorage.legacyStyleKey] is String
            ? values[MentiProfileStorage.legacyStyleKey] : null);
    final outfit = values[MentiProfileStorage.outfitKey];
    final hasProfile = family != null || outfit != null;
    final newIdentity = values[MentiIdentityStore.key];
    final profile = newIdentity != null ? HubRead.decode<HubProfile>(newIdentity, (raw) {
      final identity = MentiIdentityDocument.decode(raw).profile;
      return HubProfile(identity.name,
        MentiCharacterFamily.resolve(identity.visual.value('family')) ?? MentiCharacterFamily.boy,
        MentiOutfit.resolve(identity.visual.value('outfit')) ?? MentiOutfit.basic, identity: identity);
    }) : HubRead.decode<HubProfile>(hasProfile ? true : null, (_) {
      final resolvedFamily = MentiCharacterFamily.resolve(family);
      final resolvedOutfit = MentiOutfit.resolve(outfit);
      final name = values[MentiCharacterProfile.nameKey];
      if (resolvedFamily == null || resolvedOutfit == null || (name != null && name is! String)) {
        throw const FormatException('Incomplete or unknown Menti profile');
      }
      return HubProfile(name as String? ?? 'Menti', resolvedFamily, resolvedOutfit);
    });
    return PersonalHubSnapshot._(
      now: now,
      profile: profile,
      xp: HubRead.decode<HubXp>(values[MentiXpStore.currentKey], HubXp.new),
      daily: HubRead.decode(values[DailyMentiStore.key(now)], DailyMentiStore.decodeDocument),
      journal: HubRead.decode<List<Drink>>(values['mennyiment_drinks_v1'], (raw) {
        if (raw is! String) throw const FormatException('Invalid journal type');
        return List<Drink>.unmodifiable((jsonDecode(raw) as List).map((entry) =>
          Drink.fromJson(Map<String, dynamic>.from(entry as Map))));
      }),
      goals: HubRead.decode(values[PersonalGoalStore.key], PersonalGoalStore.decodeDocument),
      challenges: HubRead.decode(values[ChallengeStore.key], ChallengeStore.decodeDocument),
      wellbeing: HubRead.decode(values['mennyiment_wellbeing_v1'], (raw) => recordedWellbeingDays(raw, now, includeFuture: true)),
    );
  }

  late final List<Drink> weeklyDrinks = List.unmodifiable((journal.value ?? <Drink>[]).where((drink) =>
      !drink.time.isBefore(week) && drink.time.isBefore(end) && !drink.time.isAfter(now)));
  late final double knownCost = weeklyDrinks.fold(0.0, (sum, drink) => sum + (drink.priceFt ?? 0));
  late final int unknownPrices = weeklyDrinks.where((drink) => drink.priceFt == null).length;
  late final double grams = weeklyDrinks.fold(0.0, (sum, drink) => sum + drink.alcoholGrams);
  bool get dailyAnswersRecorded => daily.value != null &&
      ['mood', 'energy', 'goal', 'evening'].any(daily.value!.containsKey);
  int? get personalTarget => (goals.value?['reflectionGoal'] as num?)?.toInt();
  int? get budget => (goals.value?['weeklyBudget'] as num?)?.toInt();
  Set<String>? get personalDays => goals.value?['reflectionDays'] is List
      ? (goals.value!['reflectionDays'] as List).cast<String>().toSet() : null;
  int? get personalCount => personalDays == null ? null : recordedGoalDays(personalDays!, week, now);
  bool get personalCompleted => personalCount != null && personalTarget != null && personalCount! >= personalTarget!;

  List<HubChallenge> get weeklyChallenges {
    final weeks = challenges.value?['weeks'] as Map?;
    final current = weeks?[mentiDateKey(week)] as Map? ?? {};
    return current.entries.map((entry) {
      final item = entry.value as Map;
      final days = entry.key == 'journal' && item['status'] == 'active'
          ? wellbeing.value : (item['days'] as List).cast<String>().toSet();
      return HubChallenge(id: entry.key as String, title: item['title'] as String,
        status: item['status'] as String, target: item['goal'] as int, days: days,
        count: days == null ? null : recordedGoalDays(days, week, now));
    }).toList();
  }

  /// Only new recorded evidence can trigger a reaction, never initial rendering,
  /// a changed target, a clock-only rollover, or a duplicate refresh.
  MentiMood? reactionSince(PersonalHubSnapshot? previous) {
    if (previous == null || previous.week != week) return null;
    if (personalDays != null && previous.personalDays != null && personalCount != null &&
        previous.personalCount != null && personalTarget != null && previous.personalTarget != null &&
        personalDays!.difference(previous.personalDays!).isNotEmpty &&
        crossedRecordedGoal(before: previous.personalCount!, after: personalCount!,
          previousTarget: previous.personalTarget!, target: personalTarget!)) {
      return MentiMood.personalGoalCompleted;
    }
    for (final current in weeklyChallenges) {
      for (final old in previous.weeklyChallenges.where((item) => item.id == current.id)) {
        if (current.status == 'active' && old.status == 'active' && current.days != null &&
            old.days != null && current.days!.difference(old.days!).isNotEmpty &&
            current.count != null && old.count != null && crossedRecordedGoal(
              before: old.count!, after: current.count!, previousTarget: old.target, target: current.target)) {
          return MentiMood.challengeCompleted;
        }
      }
    }
    return null;
  }
}

class PersonalHubReader {
  PersonalHubReader({Future<SharedPreferences> Function()? open})
      : open = open ?? SharedPreferences.getInstance;
  final Future<SharedPreferences> Function() open;

  Future<PersonalHubSnapshot> load(DateTime Function() clock) async {
    final prefs = await open();
    await prefs.reload();
    // One synchronous snapshot after reload. No store.load() migrations or writes.
    final values = <String, Object?>{
      for (final key in prefs.getKeys())
        if (key.startsWith('mennyiment_')) key: prefs.get(key),
    };
    return PersonalHubSnapshot.fromValues(values, clock());
  }
}
