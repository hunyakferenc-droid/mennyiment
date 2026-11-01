import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'app_language.dart';
import 'menti_experience_settings.dart';
import 'home_widgets.dart';
import 'menti_character_catalog.dart';
import 'menti_completion.dart';
import 'menti_evolution.dart';
import 'menti_identity/menti_avatar_renderer.dart';
import 'menti_identity/menti_identity_controller.dart';
import 'menti_identity/menti_visual_catalog.dart';
import 'menti_reactions.dart';
import 'menti_ui.dart';
import 'personal_hub_data.dart';

class PersonalHubPage extends StatefulWidget {
  const PersonalHubPage({super.key, this.reader, this.clock});
  final PersonalHubReader? reader;
  final DateTime Function()? clock;
  @override
  State<PersonalHubPage> createState() => _PersonalHubPageState();
}

class _PersonalHubPageState extends State<PersonalHubPage> with WidgetsBindingObserver {
  late final PersonalHubReader _reader = widget.reader ?? PersonalHubReader();
  DateTime get _now => (widget.clock ?? DateTime.now)().toLocal();
  PersonalHubSnapshot? _snapshot;
  bool _loading = true;
  bool _failed = false;
  int _request = 0;
  MentiMood? _reaction;
  int _reactionSequence = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (!_loading && (_snapshot == null || mentiDateKey(_snapshot!.now) != mentiDateKey(_now))) {
        _load();
      }
    });
    _load();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _load();
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _load() async {
    if (!mounted) return;
    final request = ++_request;
    final previous = _failed ? null : _snapshot;
    setState(() { _loading = true; _failed = false; _reaction = null; });
    try {
      final data = await _reader.load(() => _now);
      if (!mounted || request != _request) return;
      setState(() {
        _snapshot = data;
        _reaction = MentiExperienceScope.reactionsOf(context) ? data.reactionSince(previous) : null;
        if (_reaction != null) _reactionSequence++;
        _loading = false;
      });
    } catch (error, stack) {
      debugPrint('Personal hub load failure: ${error.runtimeType}\n$stack');
      if (mounted && request == _request) {
        setState(() { _failed = true; _loading = false; _snapshot = null; });
      }
    }
  }

  Widget _section<T>(String id, String title, HubRead<T> result, Widget Function(T) builder) {
    final s = appStrings(context);
    return MentiPanel(key: ValueKey('hub-$id'), child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        if (result.status == HubReadStatus.ready) builder(result.value as T)
        else MentiStatusMessage(
          key: ValueKey('hub-status-$id'),
          message: result.status == HubReadStatus.error ? s.hubReadError : s.hubMissing,
          isError: result.status == HubReadStatus.error,
          onRetry: _load, retryLabel: s.challengeRetry),
      ],
    ));
  }

  @override
  Widget build(BuildContext context) {
    final s = appStrings(context);
    final locale = Localizations.localeOf(context).languageCode;
    final data = _snapshot;
    final date = DateFormat.yMMMd(locale);
    return Scaffold(
      appBar: AppBar(title: Text(s.hubOverview, maxLines: 1, overflow: TextOverflow.ellipsis), actions: [
        IconButton(key: const ValueKey('hub-refresh'), tooltip: s.hubRefresh,
          onPressed: _loading ? null : _load, icon: const Icon(Icons.refresh)),
      ]),
      body: _loading ? const Center(child: CircularProgressIndicator())
          : _failed || data == null ? MentiPageBody(children: [
              MentiStatusMessage(key: const ValueKey('hub-global-error'),
                message: s.hubGlobalError, isError: true,
                onRetry: _load, retryLabel: s.challengeRetry),
            ])
          : MentiPageBody(children: [
              Text(s.hubTitle, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text(s.hubIntro),
              const SizedBox(height: 12),
              Text(s.hubWeek(date.format(data.week), date.format(mentiCalendarDay(data.end, -1)))),
              Text(s.hubUpdated(DateFormat.yMMMd(locale).add_Hm().format(data.now))),
              const SizedBox(height: 16),
              if (_reaction != null) MentiReactionCard(mood: _reaction!,
                bubbleKey: const ValueKey('hub-reaction'), eventToken: _reactionSequence),
              _section('profile', s.hubProfile, data.profile, (profile) {
                final currentIdentity = profile.identity ?? MentiIdentityScope.of(context)?.profile;
                final family = switch (profile.family) {
                  MentiCharacterFamily.boy => s.hubFamilyBoy,
                  MentiCharacterFamily.girl => s.hubFamilyGirl,
                  MentiCharacterFamily.neutral => s.hubFamilyNeutral,
                };
                final outfit = switch (profile.outfit) {
                  MentiOutfit.basic => s.hubOutfitBasic,
                  MentiOutfit.party => s.hubOutfitParty,
                  MentiOutfit.sport => s.hubOutfitSport,
                  MentiOutfit.business => s.hubOutfitBusiness,
                  MentiOutfit.festival => s.hubOutfitFestival,
                  MentiOutfit.legendary => s.hubOutfitLegendary,
                };
                return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Center(child: Semantics(label: '${profile.name} • $family • $outfit',
                    child: ExcludeSemantics(child: currentIdentity != null
                      ? MentiAvatarRenderer(profile: currentIdentity, size: 130)
                      : data.xp.value == null
                      ? Image.asset(profile.asset, width: 130, height: 130,
                          errorBuilder: (_, error, stack) => Text(s.hubImageError))
                      : MentiEvolution(assetPath: profile.asset, size: 130,
                          level: data.xp.value!.state.level)))),
                  Text(currentIdentity?.name ?? profile.name, style: Theme.of(context).textTheme.titleMedium),
                  if (currentIdentity == null) Text('$family • $outfit')
                  else Text('${MentiVisualCatalog.resolve('family', currentIdentity.visual.value('family')).label(s)} • ${MentiVisualCatalog.resolve('outfit', currentIdentity.visual.value('outfit')).label(s)}'),
                ]);
              }),
              _section('xp', s.hubXp, data.xp, (xp) => Column(
                crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(s.evolutionLevel(xp.state.level)),
                  Text(s.homeTotalXp(xp.state.xp)),
                  MentiProgressSummary(label: s.evolutionRemaining(xp.state.remainingXp),
                    current: xp.state.levelXp, target: 50),
                  const SizedBox(height: 8),
                  if (xp.hasDays) ...[
                    Text(xp.state.checkedOn(data.now) ? s.hubXpToday : s.hubNoXpToday),
                    Text(s.hubWeekChecks(recordedGoalDays(xp.state.days, data.week, data.now))),
                  ] else Text(s.hubNoCheckDays),
                ])),
              _section('daily', s.hubDaily, data.daily, (_) => Text(
                data.dailyAnswersRecorded ? s.hubDailyAnswers : s.hubNoDailyAnswers)),
              _section('goals', s.hubGoals, data.goals, (_) => Column(
                crossAxisAlignment: CrossAxisAlignment.start, children: [
                  if (data.personalTarget == null) Text(s.hubNoTarget)
                  else if (data.personalCount == null) Text(s.hubNoCheckDays)
                  else ...[
                    MentiProgressSummary(label: s.goalProgress(data.personalCount!, data.personalTarget!),
                      current: data.personalCount!, target: data.personalTarget!),
                    const SizedBox(height: 8),
                    Text(data.personalCompleted ? s.hubGoalConfirmed : s.hubGoalOngoing),
                  ],
                  const SizedBox(height: 8),
                  Text(data.budget == null ? s.goalNoBudget : s.goalBudgetValue(localeCurrency(data.budget!, locale))),
                  Text(s.goalCaution),
                ])),
              _section('challenges', s.hubChallenges, data.challenges, (_) {
                final challenges = data.weeklyChallenges;
                if (challenges.isEmpty) return Text(s.hubNoChallenges);
                return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  for (final item in challenges) Padding(padding: const EdgeInsets.only(bottom: 16),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(switch (item.id) {
                        'reflection' => s.challengeReflection,
                        'journal' => s.challengeJournal,
                        'habit' => s.challengeHabit,
                        'custom' => item.title,
                        _ => item.title.isEmpty ? item.id : item.title,
                      }, style: Theme.of(context).textTheme.titleMedium),
                      if (item.count == null) MentiStatusMessage(
                        message: s.hubEvidenceMissing, onRetry: _load, retryLabel: s.challengeRetry)
                      else MentiProgressSummary(label: s.goalProgress(item.count!, item.target),
                        current: item.count!, target: item.target),
                      if (item.status == 'skipped') Text(s.challengeSkipped)
                      else if (item.status == 'stopped') Text(s.challengeStopped)
                      else if (item.completed) Text(s.hubGoalConfirmed),
                    ])),
                  Text(s.challengeCaution),
                ]);
              }),
              _section('journal', s.hubJournal, data.journal, (_) => Column(
                crossAxisAlignment: CrossAxisAlignment.start, children: [
                  if (data.weeklyDrinks.isEmpty) Text(s.hubRecordedEmpty),
                  HomeAdaptiveGrid(children: [
                    HomeStatTile(label: s.drinks, value: '${data.weeklyDrinks.length}', icon: Icons.local_bar_outlined),
                    HomeStatTile(label: s.knownSpending, value: localeCurrency(data.knownCost, locale), icon: Icons.payments_outlined),
                    HomeStatTile(label: s.pureAlcohol,
                      value: s.grams(NumberFormat.decimalPatternDigits(locale: locale, decimalDigits: 1).format(data.grams)),
                      icon: Icons.info_outline),
                  ]),
                  const SizedBox(height: 12),
                  Text(data.unknownPrices > 0 ? s.partialPrices(data.unknownPrices) : s.completePrices),
                  if (data.knownCost == 0 && data.weeklyDrinks.isNotEmpty) Text(s.hubKnownZero),
                  Text(s.statisticsCaution),
                ])),
            ]),
    );
  }
}
