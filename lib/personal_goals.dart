import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'app_language.dart';
import 'menti_experience_settings.dart';
import 'menti_completion.dart';
import 'menti_reactions.dart';
import 'menti_ui.dart';
import 'personal_goal_store.dart';
import 'weekly_challenges.dart';

class PersonalGoalDrink {
  const PersonalGoalDrink({required this.time, this.priceFt});
  final DateTime time;
  final double? priceFt;
}

class PersonalGoalsPage extends StatefulWidget {
  const PersonalGoalsPage({super.key, required this.drinks, this.store, this.clock});
  final List<PersonalGoalDrink> drinks;
  final PersonalGoalStore? store;
  final DateTime Function()? clock;

  @override
  State<PersonalGoalsPage> createState() => _PersonalGoalsPageState();
}

class _PersonalGoalsPageState extends State<PersonalGoalsPage>
    with WidgetsBindingObserver {
  late final PersonalGoalStore _store = widget.store ?? PersonalGoalStore();
  DateTime get _now => (widget.clock ?? DateTime.now)().toLocal();
  int _back = 0;
  DateTime get _week => mentiCalendarDay(mentiMonday(_now), -7 * _back);
  bool _loading = true;
  bool _saving = false;
  bool _error = false;
  MentiMood? _reaction;
  int _reactionSequence = 0;
  Timer? _timer;
  late String _shownDay;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _shownDay = mentiDateKey(_now);
    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (_loading || _saving || !mounted) return;
      final day = mentiDateKey(_now);
      if (day != _shownDay) {
        _shownDay = day;
        _load();
      }
    });
    _load();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !_saving) _load();
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _load() async {
    if (_saving || !mounted) return;
    setState(() { _loading = true; _error = false; _reaction = null; });
    try {
      await _store.load();
    } catch (error, stack) {
      debugPrint('Personal goals load failure: ${error.runtimeType}\n$stack');
      if (mounted) _error = true;
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<bool> _commit(Map<String, dynamic> changes) async {
    if (_loading || _saving || _error || !_store.writable) return false;
    setState(() { _saving = true; _reaction = null; });
    final saved = await _store.update(changes);
    if (!mounted) return false;
    setState(() => _saving = false);
    if (!saved) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(appStrings(context).goalSaveError)));
    }
    return saved;
  }

  Future<void> _checkIn() async {
    if (_back != 0 || _loading || _saving || _error) return;
    final now = _now;
    final today = mentiDateKey(now);
    if (_store.reflectionDays.contains(today)) return;
    final week = mentiMonday(now);
    final before = recordedGoalDays(_store.reflectionDays, week, now);
    final target = _store.reflectionGoal;
    final saved = await _commit({'reflectionDays': [..._store.reflectionDays, today]});
    if (!saved || !mounted || mentiMonday(_now) != week) return;
    final after = recordedGoalDays(_store.reflectionDays, week, _now);
    if (MentiExperienceScope.reactionsOf(context) && crossedRecordedGoal(before: before, after: after,
        previousTarget: target, target: _store.reflectionGoal)) {
      setState(() { _reaction = MentiMood.personalGoalCompleted; _reactionSequence++; });
    }
  }

  Future<void> _editNumber({required bool budget}) async {
    if (_saving || _loading || _error || !_store.writable) return;
    final controller = TextEditingController(
      text: budget ? _store.weeklyBudget?.toString() ?? '' : '${_store.reflectionGoal}');
    final value = await showDialog<int>(context: context, builder: (dialogContext) {
      final s = appStrings(dialogContext);
      return AlertDialog(
        title: Text(budget ? s.goalBudgetDialog : s.goalTargetDialog),
        content: SingleChildScrollView(child: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: budget ? s.goalBudgetHint : s.goalTargetHint,
            helperMaxLines: 3,
            helperText: budget ? s.goalBudgetHelp : s.goalTargetHelp),
        )),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: Text(s.challengeCancel)),
          FilledButton(onPressed: () {
            final parsed = int.tryParse(controller.text.trim());
            if (parsed == null || (budget && (parsed < 0 || parsed > 100000000)) ||
                (!budget && (parsed < 1 || parsed > 7))) {
              ScaffoldMessenger.of(dialogContext).showSnackBar(SnackBar(content: Text(s.goalInvalidValue)));
              return;
            }
            Navigator.pop(dialogContext, parsed);
          }, child: Text(s.challengeSave)),
        ],
      );
    });
    // Keep the controller alive while the dialog's exit animation uses it.
    await Future<void>.delayed(const Duration(milliseconds: 300));
    controller.dispose();
    if (value != null && mounted) {
      await _commit({budget ? 'weeklyBudget' : 'reflectionGoal': value});
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = appStrings(context);
    final locale = Localizations.localeOf(context).languageCode;
    final now = _now;
    final week = _week;
    final end = mentiCalendarDay(week, 7);
    final entries = widget.drinks.where((d) => !d.time.isBefore(week) &&
        d.time.isBefore(end) && !d.time.isAfter(now)).toList();
    final spent = entries.fold<double>(0, (sum, d) => sum + (d.priceFt ?? 0));
    final unknown = entries.where((d) => d.priceFt == null).length;
    final checks = recordedGoalDays(_store.reflectionDays, week, now);
    final target = _store.reflectionGoal;
    final budget = _store.weeklyBudget;
    final enabled = !_loading && !_saving && !_error && _store.writable;
    final dateFormat = DateFormat.MMMd(locale);
    final weekdays = DateFormat.E(locale);
    final checkedToday = _store.reflectionDays.contains(mentiDateKey(now));
    return Scaffold(
      appBar: AppBar(title: Text(s.goalPageTitle)),
      body: _loading ? const Center(child: CircularProgressIndicator())
          : _error ? MentiPageBody(children: [
              Text(s.goalLoadError, key: const ValueKey('personal-goals-error')),
              TextButton(onPressed: _load, child: Text(s.goalReload)),
            ])
          : MentiPageBody(children: [
              FilledButton.icon(
                onPressed: _saving ? null : () => Navigator.push<void>(context,
                  MaterialPageRoute(builder: (_) => const WeeklyChallengesPage())),
                icon: const Icon(Icons.flag_outlined), label: Text(s.challengeTitle)),
              const SizedBox(height: 16),
              MentiPanel(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(s.goalOwnPace, style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 8),
                Text(s.goalIntro),
                Row(children: [
                  IconButton(onPressed: _saving ? null : () => setState(() { _back++; _reaction = null; }),
                    tooltip: s.challengePrevious, icon: const Icon(Icons.chevron_left)),
                  Expanded(child: Text('${dateFormat.format(week)} – ${dateFormat.format(mentiCalendarDay(end, -1))}',
                    textAlign: TextAlign.center)),
                  IconButton(onPressed: _back == 0 || _saving ? null
                      : () => setState(() { _back--; _reaction = null; }),
                    tooltip: s.challengeNext, icon: const Icon(Icons.chevron_right)),
                ]),
              ])),
              if (_reaction != null) MentiReactionCard(mood: _reaction!,
                bubbleKey: const ValueKey('personal-goal-reaction'), eventToken: _reactionSequence),
              MentiPanel(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(s.goalBudgetTitle, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                Text(s.goalRecordedSpending(localeCurrency(spent, locale))),
                Text(budget == null ? s.goalNoBudget : s.goalBudgetValue(localeCurrency(budget, locale))),
                if (budget != null && budget > 0)
                  LinearProgressIndicator(value: (spent / budget).clamp(0.0, 1.0)),
                const SizedBox(height: 8),
                Text(unknown > 0 ? s.goalMissingPrices(unknown)
                    : budget == null ? s.goalNoBudget
                    : spent > budget ? s.goalOverBudget : s.goalWithinBudget),
                TextButton.icon(onPressed: enabled ? () => _editNumber(budget: true) : null,
                  icon: const Icon(Icons.edit_outlined), label: Text(s.goalEditBudget)),
              ])),
              MentiPanel(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(s.goalReflectionTitle, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                Text(s.goalProgress(checks, target), key: const ValueKey('personal-goal-count')),
                LinearProgressIndicator(value: (checks / target).clamp(0.0, 1.0)),
                Wrap(spacing: 7, children: List.generate(7, (i) {
                  final day = mentiCalendarDay(week, i);
                  final checked = !day.isAfter(mentiCalendarDay(now)) &&
                      _store.reflectionDays.contains(mentiDateKey(day));
                  return Chip(label: Text(weekdays.format(day)), avatar: Icon(
                    checked ? Icons.check_circle : Icons.circle_outlined, size: 17));
                })),
                FilledButton.icon(
                  key: const ValueKey('personal-goal-check-in'),
                  onPressed: enabled && _back == 0 && !checkedToday ? _checkIn : null,
                  icon: const Icon(Icons.task_alt),
                  label: Text(_back != 0 ? s.goalCurrentWeekOnly
                      : checkedToday ? s.goalCheckDone : s.goalCheckAction)),
                TextButton.icon(onPressed: enabled ? () => _editNumber(budget: false) : null,
                  icon: const Icon(Icons.tune), label: Text(s.goalEditTarget)),
              ])),
              MentiPanel(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                if (MentiExperienceScope.reactionsOf(context)) ...[
                  Text(s.goalMentiThought, style: Theme.of(context).textTheme.titleLarge),
                  Text(checks >= target ? s.goalThoughtComplete
                      : checks == 0 ? s.goalThoughtStart : s.goalThoughtProgress(checks)),
                  const SizedBox(height: 8),
                ],
                Text(s.goalCaution),
              ])),
              OutlinedButton(onPressed: _saving ? null : _load, child: Text(s.goalReload)),
            ]),
    );
  }
}
