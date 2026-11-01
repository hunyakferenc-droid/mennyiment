import 'dart:async';

import 'package:flutter/material.dart';

import 'app_language.dart';
import 'menti_completion.dart';
import 'menti_experience_settings.dart';
import 'menti_ui.dart';
import 'personal_hub_data.dart';

enum DailyMentiContext { invitation, answers, checked, personalGoal, challenge, unavailable }

/// Stable, evidence-only presentation. Does not create events, entries or XP.
class DailyMentiMessage {
  static DailyMentiContext context(PersonalHubSnapshot snapshot) {
    if ([snapshot.xp.status, snapshot.daily.status, snapshot.goals.status,
      snapshot.challenges.status, snapshot.wellbeing.status].contains(HubReadStatus.error)) {
      return DailyMentiContext.unavailable;
    }
    if (snapshot.personalCompleted) return DailyMentiContext.personalGoal;
    if (snapshot.weeklyChallenges.any((item) => item.completed)) return DailyMentiContext.challenge;
    if (snapshot.dailyAnswersRecorded) return DailyMentiContext.answers;
    if (snapshot.xp.value?.hasDays == true && snapshot.xp.value!.state.checkedOn(snapshot.now)) {
      return DailyMentiContext.checked;
    }
    return DailyMentiContext.invitation;
  }

  static String text(BuildContext context, PersonalHubSnapshot? snapshot, DateTime now) {
    final s = appStrings(context);
    final status = snapshot == null ? DailyMentiContext.unavailable : DailyMentiMessage.context(snapshot);
    return switch (status) {
      DailyMentiContext.invitation => (now.year * 372 + now.month * 31 + now.day).isEven
          ? s.experienceTodayStart1 : s.experienceTodayStart2,
      DailyMentiContext.answers => s.experienceTodayAnswers,
      DailyMentiContext.checked => s.experienceTodayChecked,
      DailyMentiContext.personalGoal => s.experienceTodayGoal,
      DailyMentiContext.challenge => s.experienceTodayChallenge,
      DailyMentiContext.unavailable => s.experienceTodayUnknown,
    };
  }
}

class DailyMentiMiniCard extends StatefulWidget {
  const DailyMentiMiniCard({super.key, required this.onOpenDaily, required this.onOpenHub,
    this.refreshToken, this.reader, this.clock});
  final VoidCallback onOpenDaily;
  final VoidCallback onOpenHub;
  final Object? refreshToken;
  final PersonalHubReader? reader;
  final DateTime Function()? clock;
  @override
  State<DailyMentiMiniCard> createState() => _DailyMentiMiniCardState();
}

class _DailyMentiMiniCardState extends State<DailyMentiMiniCard> with WidgetsBindingObserver {
  late final PersonalHubReader _reader = widget.reader ?? PersonalHubReader();
  DateTime get _now => (widget.clock ?? DateTime.now)().toLocal();
  PersonalHubSnapshot? _snapshot;
  int _request = 0;
  bool _loading = true;
  Timer? _timer;
  late String _day;
  @override
  void initState() {
    super.initState();
    _day = mentiDateKey(_now);
    WidgetsBinding.instance.addObserver(this);
    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (_day != mentiDateKey(_now)) {
        _day = mentiDateKey(_now);
        _load();
      }
    });
    _load();
  }
  @override
  void didUpdateWidget(covariant DailyMentiMiniCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.refreshToken != oldWidget.refreshToken) _load();
  }
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _load();
  }
  Future<void> _load() async {
    final request = ++_request;
    _loading = true;
    try {
      final data = await _reader.load(() => _now);
      if (mounted && request == _request) setState(() { _snapshot = data; _loading = false; });
    } catch (failure, stack) {
      debugPrint('Daily Menti read failure: ${failure.runtimeType}\n$stack');
      if (mounted && request == _request) setState(() { _snapshot = null; _loading = false; });
    }
  }
  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    if (!MentiExperienceScope.reactionsOf(context)) return const SizedBox.shrink();
    final s = appStrings(context);
    return MentiPanel(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(s.experienceToday, style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 8),
      Text(_loading && _snapshot == null ? s.experienceTodayLoading
          : DailyMentiMessage.text(context, _snapshot, _snapshot?.now ?? _now),
        key: const ValueKey('daily-menti-message')),
      Wrap(spacing: 8, runSpacing: 8, children: [
        TextButton(onPressed: widget.onOpenDaily, child: Text(s.experienceOpenDaily)),
        TextButton(onPressed: widget.onOpenHub, child: Text(s.experienceOpenHub)),
      ]),
    ]));
  }
}
