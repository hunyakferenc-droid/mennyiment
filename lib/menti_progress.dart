import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_language.dart';
import 'menti_xp_store.dart';
import 'menti_evolution.dart';
import 'menti_profile_storage.dart';
import 'menti_character_catalog.dart';
import 'menti_character_setup.dart';
import 'menti_rewards.dart';
import 'menti_reward_widgets.dart';
import 'menti_reactions.dart';
import 'menti_ui.dart';

/// All actions reuse the existing XP events. Badges never grant extra XP.
class MentiProgressPage extends StatefulWidget {
  const MentiProgressPage({super.key});
  @override
  State<MentiProgressPage> createState() => _MentiProgressPageState();
}

class _MentiProgressPageState extends State<MentiProgressPage> {
  MentiXpState? _state;
  MentiCharacterFamily _family = MentiCharacterFamily.boy;
  String _asset = 'assets/images/menti_outfits/alap.png';
  Set<String> _assets = {};
  Set<String> _unlocked = {};
  bool _busy = true;
  bool _error = false;
  int _reaction = 0;
  MentiMood? _message;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _busy = true; _error = false; });
    try {
      final state = await MentiXpStore.load();
      final prefs = await SharedPreferences.getInstance();
      await MentiProfileStorage.migrate(prefs);
      final assets = await MentiRewards.bundledAssets();
      final unlocked = await MentiRewards.load(level: state.level, assets: assets);
      if (!mounted) return;
      setState(() {
        _state = state;
        _family = MentiProfileStorage.family(prefs);
        _asset = MentiProfileStorage.assetPath(prefs);
        _assets = assets;
        _unlocked = unlocked;
      });
    } catch (error, stack) {
      // Keep journal/profile values out of diagnostic output.
      debugPrint('Menti progress failure: ${error.runtimeType}\n$stack');
      if (mounted) setState(() => _error = true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _complete([String? task]) async {
    if (_busy || _error || _state == null) return;
    setState(() => _busy = true);
    final before = _state!.xp;
    try {
      final state = task == null
        ? await MentiXpStore.checkInToday()
        : await MentiXpStore.completeWeekly(task);
      final unlocked = await MentiRewards.load(level: state.level, assets: _assets);
      if (!mounted) return;
      setState(() {
        _state = state;
        _unlocked = unlocked;
        // No reaction for duplicate events: the persisted XP must have changed.
        if (state.xp > before) {
          _reaction++;
          _message = state.level > MentiXpState.levelFor(before)
              ? MentiMood.levelUp
              : task == null
                  ? MentiMood.dailyCheckIn
                  : MentiMood.weeklyCompleted;
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(appStrings(context).evolutionSaved(state.xp - before))));
    } catch (error, stack) {
      // Keep journal/profile values out of diagnostic output.
      debugPrint('Menti progress failure: ${error.runtimeType}\n$stack');
      if (mounted) setState(() => _error = true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = appStrings(context);
    final state = _state;
    final now = DateTime.now();
    final checked = state?.checkedOn(now) ?? false;
    final week = MentiXpStore.weekKey(now);
    final days = state?.days.where((day) {
      final date = DateTime.tryParse(day);
      return date != null && MentiXpStore.weekKey(date) == week;
    }).length ?? 0;
    final tasks = state?.completed.where((event) => event.startsWith('$week:')).length ?? 0;
    final badges = <(String, bool)>[
      (s.evolutionReflectionBadge, state != null && state.days.isNotEmpty),
      (s.evolutionGoalBadge, state?.completed.any((event) => event.endsWith(':goal')) ?? false),
      (s.evolutionConsistencyBadge, (state?.days.length ?? 0) >= 7),
    ];
    final weekly = [
      ('review', s.evolutionReview, Icons.menu_book_outlined),
      ('cost', s.evolutionCost, Icons.account_balance_wallet_outlined),
      ('goal', s.evolutionGoal, Icons.flag_outlined),
    ];
    return Scaffold(
      appBar: AppBar(title: Text(s.evolutionTitle)),
      body: _busy && state == null
          ? const Center(child: CircularProgressIndicator())
          : MentiPageBody(children: [
            if (_error) MentiPanel(child: Column(children: [
              Text(s.evolutionError),
              TextButton(onPressed: _busy ? null : _load, child: Text(s.evolutionRetry)),
            ])),
            if (state != null) ...[
              MentiPanel(child: Column(children: [
                MentiEvolution(size: 170, reaction: _reaction,
                  level: state.level, assetPath: _asset),
                Text('Menti • ${s.evolutionLevel(state.level)}'),
                MentiLevelIndicator(xp: state.xp),
                if (_message != null) ...[
                  const SizedBox(height: 12),
                  MentiSpeechBubble(message: MentiReactions.message(_message!,
                    index: _reaction,
                    locale: Localizations.localeOf(context).languageCode)),
                ],
              ])),
              MentiPanel(child: MentiNextReward(xp: state.xp, family: _family,
                unlocked: _unlocked, assets: _assets)),
              OutlinedButton.icon(
                icon: const Icon(Icons.checkroom_outlined),
                label: Text(s.evolutionWardrobe),
                onPressed: _busy ? null : () async {
                  await Navigator.of(context).push(MaterialPageRoute<void>(
                    builder: (_) => const MentiCharacterSetupPage()));
                  if (mounted) await _load();
                },
              ),
              MentiPanel(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(s.evolutionDaily, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                Text(s.evolutionDailyHint),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: _busy || _error || checked ? null : () => _complete(),
                  icon: Icon(checked ? Icons.check_circle : Icons.favorite_outline),
                  label: Text(checked ? s.evolutionChecked : s.evolutionCheck),
                ),
              ])),
              MentiPanel(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(s.evolutionWeekly, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                Text(s.evolutionWeeklyHint),
                const SizedBox(height: 8),
                Text(s.evolutionWeek(days, tasks)),
                for (final task in weekly) ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(task.$3),
                  title: Text(task.$2),
                  subtitle: Text(s.evolutionPoints(MentiXpStore.weeklyPoints[task.$1]!)),
                  trailing: state.completedThisWeek(task.$1, now)
                    ? const Icon(Icons.check_circle)
                    : OutlinedButton(
                      onPressed: _busy || _error ? null : () => _complete(task.$1),
                      child: Text(s.evolutionDone)),
                ),
              ])),
              MentiPanel(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(s.evolutionBadges, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                for (final badge in badges) ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(badge.$2 ? Icons.verified : Icons.radio_button_unchecked),
                  title: Text(badge.$1),
                  subtitle: Text(badge.$2 ? s.evolutionEarned : s.evolutionLocked),
                ),
              ])),
              Text(s.evolutionPolicy),
            ],
          ]),
    );
  }
}
