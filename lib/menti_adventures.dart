import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'app_language.dart';
import 'menti_access.dart';
import 'menti_adventure_store.dart';
import 'menti_experience_settings.dart';
import 'menti_identity/menti_avatar_renderer.dart';
import 'menti_identity/menti_identity_controller.dart';
import 'menti_reactions.dart';
import 'menti_ui.dart';

/// Existing wellbeing/goals routes are supplied by home; this page owns no copy
/// of their data. Manual actions explicitly ask for the user's own report.
class MentiAdventuresPage extends StatefulWidget {
  const MentiAdventuresPage({
    super.key,
    required this.onWellbeing,
    required this.onGoals,
    this.store,
    this.clock,
  });
  final Future<void> Function() onWellbeing, onGoals;
  final AdventureStore? store;
  final DateTime Function()? clock;

  @override
  State<MentiAdventuresPage> createState() => _MentiAdventuresPageState();
}

class _MentiAdventuresPageState extends State<MentiAdventuresPage>
    with WidgetsBindingObserver {
  DateTime get now => (widget.clock ?? DateTime.now)().toLocal();
  late final AdventureStore store =
      widget.store ?? AdventureStore(clock: widget.clock);
  late DateTime day;
  bool loading = true, saving = false, failed = false;
  Timer? _dayTimer, _feedbackTimer;
  AdventureResult? feedback;
  int sequence = 0;

  @override
  void initState() {
    super.initState();
    day = now;
    WidgetsBinding.instance.addObserver(this);
    _load();
    _dayTimer = Timer.periodic(const Duration(minutes: 1), (_) => _rollDay());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !saving) _load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _dayTimer?.cancel();
    _feedbackTimer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    if (saving || !mounted) return;
    setState(() {
      loading = true;
      failed = false;
      feedback = null;
    });
    try {
      await store.load();
      if (mounted) day = now;
    } catch (_) {
      if (mounted) failed = true;
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  bool _rollDay() {
    if (!mounted || loading || saving) return false;
    if (adventureDay(day) == adventureDay(now)) return false;
    _load();
    return true;
  }

  Future<void> _act(Future<AdventureResult?> Function() action) async {
    if (loading || saving || failed || !store.writable || _rollDay()) return;
    _feedbackTimer?.cancel();
    setState(() {
      saving = true;
      feedback = null;
    });
    final result = await action();
    if (!mounted) return;
    setState(() {
      saving = false;
      if (result?.completed == true) {
        feedback = result;
        sequence = store.document.completedCount(day);
      }
    });
    if (result == null) {
      final s = appStrings(context);
      final message = switch (store.failure) {
        AdventureFailure.dayChanged => s.adventureDayChanged,
        AdventureFailure.capacity => s.adventureCapacity,
        AdventureFailure.evidence => s.adventureEvidence,
        AdventureFailure.access => s.adventureAccess,
        AdventureFailure.stale => s.adventureStale,
        _ => s.adventureSaveError,
      };
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    }
    if (feedback != null) {
      _feedbackTimer = Timer(const Duration(seconds: 5), () {
        if (mounted) setState(() => feedback = null);
      });
    }
    _rollDay();
  }

  Future<void> _confirm(AdventureTask task, {bool cancel = false}) async {
    if (saving || loading || _rollDay()) return;
    // Capture the day before opening a dialog: midnight cannot silently apply
    // this confirmation to a newly selected task on another day.
    final selectedDay = day;
    final s = appStrings(context);
    final controller = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        scrollable: true,
        title: Text(cancel ? s.adventureCancelTitle : s.adventureConfirmTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(cancel ? s.adventureCancelBody : s.adventureConfirmBody),
            if (!cancel && task == AdventureTask.decision)
              TextField(
                key: const ValueKey('adventure-note'),
                controller: controller,
                autofocus: true,
                maxLength: 500,
                minLines: 2,
                maxLines: 5,
                decoration: InputDecoration(labelText: s.adventureDecisionHint),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(s.adventureLater),
          ),
          FilledButton(
            key: const ValueKey('adventure-confirm'),
            onPressed: () {
              if (!cancel &&
                  task == AdventureTask.decision &&
                  controller.text.trim().isEmpty) {
                ScaffoldMessenger.of(
                  ctx,
                ).showSnackBar(SnackBar(content: Text(s.adventureNoteMissing)));
                return;
              }
              Navigator.pop(ctx, true);
            },
            child: Text(cancel ? s.adventureCancel : s.adventureComplete),
          ),
        ],
      ),
    );
    final note = controller.text;
    // A dialog's exit transition can still hold its text field/controller.
    await Future<void>.delayed(const Duration(milliseconds: 300));
    controller.dispose();
    if (confirmed != true || !mounted) return;
    await _act(
      () => cancel
          ? store.cancel(selectedDay, task)
          : store.complete(selectedDay, task, note: note),
    );
  }

  Future<void> _open(Future<void> Function() route) async {
    if (saving || loading || _rollDay()) return;
    await route();
    // Re-read both after navigation and at the next action. A return from a
    // screen is never itself proof that anything was saved there.
    if (mounted) await _load();
  }

  String _taskName(AdventureTask task) {
    final s = appStrings(context);
    return switch (task) {
      AdventureTask.wellbeing => s.adventureWellbeing,
      AdventureTask.movement => s.adventureMovement,
      AdventureTask.rest => s.adventureRest,
      AdventureTask.decision => s.adventureDecision,
      AdventureTask.goal => s.adventureGoal,
    };
  }

  Widget _task(AdventureTask task, bool enabled) {
    final s = appStrings(context);
    final status = store.document.status(day, task);
    final done = status == 'completed';
    final active = status == 'active';
    final verified = task == AdventureTask.wellbeing;
    final hint = switch (task) {
      AdventureTask.wellbeing => s.adventureWellbeingHint,
      AdventureTask.movement => s.adventureMovementHint,
      AdventureTask.rest => s.adventureRestHint,
      AdventureTask.decision => s.adventureDecisionHelp,
      AdventureTask.goal => s.adventureGoalHint,
    };
    return Semantics(
      container: true,
      identifier: 'adventure-task-${task.name}',
      child: MentiPanel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Semantics(
              header: true,
              child: Text(
                _taskName(task),
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            const SizedBox(height: 8),
            Text(hint),
            const SizedBox(height: 8),
            Text(verified ? s.adventureVerified : s.adventureManual),
            if (status != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  done
                      ? s.adventureDone
                      : active
                      ? s.adventureActive
                      : s.adventureCancelled,
                ),
              ),
            if (!done) ...[
              const SizedBox(height: 8),
              if (!active)
                FilledButton(
                  key: ValueKey('adventure-select-${task.name}'),
                  onPressed: enabled
                      ? () => _act(() => store.select(day, task))
                      : null,
                  child: Text(
                    status == 'cancelled'
                        ? s.adventureResume
                        : s.adventureChoose,
                  ),
                ),
              if (active) ...[
                if (verified || task == AdventureTask.goal)
                  OutlinedButton(
                    key: ValueKey('adventure-open-${task.name}'),
                    onPressed: enabled
                        ? () => _open(
                            verified ? widget.onWellbeing : widget.onGoals,
                          )
                        : null,
                    child: Text(
                      verified
                          ? s.adventureOpenWellbeing
                          : s.adventureOpenGoals,
                    ),
                  ),
                FilledButton(
                  key: ValueKey('adventure-complete-${task.name}'),
                  onPressed: enabled
                      ? () {
                          if (verified) {
                            _act(() => store.complete(day, task));
                          } else {
                            _confirm(task);
                          }
                        }
                      : null,
                  child: Text(
                    verified ? s.adventureVerify : s.adventureComplete,
                  ),
                ),
                TextButton(
                  key: ValueKey('adventure-cancel-${task.name}'),
                  onPressed: enabled
                      ? () => _confirm(task, cancel: true)
                      : null,
                  child: Text(s.adventureCancel),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _map() {
    final s = appStrings(context);
    final completed = store.document.completedCount(day);
    final current = store.document.completedStations(day);
    final titles = [
      s.adventureStation0,
      s.adventureStation1,
      s.adventureStation2,
      s.adventureStation3,
      s.adventureStation4,
    ];
    final name = MentiIdentityScope.of(context)?.profile.name ?? s.menti;
    return MentiPageBody(
      children: [
        Text(
          s.adventureProgress(completed, adventureTargets.last),
          style: Theme.of(context).textTheme.titleLarge,
        ),
        Text(s.adventureNoPenalty),
        const SizedBox(height: 16),
        for (var i = 0; i < adventureTargets.length; i++)
          MentiPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  i < current
                      ? Icons.check_circle
                      : i == current
                      ? Icons.explore
                      : Icons.lock_outline,
                  color: i <= current ? const Color(0xFFF6C36B) : null,
                ),
                Semantics(
                  header: true,
                  child: Text(
                    '${i + 1}. ${titles[i]}',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                Text(
                  i < current
                      ? s.adventureStationDone
                      : i == current
                      ? s.adventureStationCurrent
                      : s.adventureStationFuture,
                ),
                Text(s.adventureStationRule(adventureTargets[i])),
                if (i == current ||
                    (current == adventureTargets.length &&
                        i == adventureTargets.length - 1)) ...[
                  const SizedBox(height: 12),
                  Center(
                    child: MentiCurrentAvatar(
                      size: 140,
                      legacyChild: const Icon(Icons.emoji_emotions, size: 80),
                    ),
                  ),
                  Center(child: Text(name)),
                ],
              ],
            ),
          ),
      ],
    );
  }

  Widget _badges() {
    final s = appStrings(context);
    final titles = [
      s.adventureBadgeFirst,
      s.adventureBadgeVariety,
      s.adventureBadgeStation,
    ];
    final rules = [
      s.adventureBadgeFirstRule,
      s.adventureBadgeVarietyRule,
      s.adventureBadgeStationRule,
    ];
    final dates = store.document.badges;
    final format = DateFormat.yMMMd(
      Localizations.localeOf(context).languageCode,
    );
    return MentiPageBody(
      children: [
        Text(s.adventureNoXp),
        const SizedBox(height: 16),
        for (var i = 0; i < adventureBadges.length; i++)
          MentiPanel(
            key: ValueKey('adventure-badge-${adventureBadges[i]}'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  dates.containsKey(adventureBadges[i])
                      ? Icons.workspace_premium
                      : Icons.lock_outline,
                  color: const Color(0xFFF6C36B),
                ),
                Semantics(
                  header: true,
                  child: Text(
                    titles[i],
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                Text(rules[i]),
                Text(
                  dates[adventureBadges[i]] == null
                      ? s.adventureLocked
                      : s.adventureEarned(
                          format.format(dates[adventureBadges[i]]!.toLocal()),
                        ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = appStrings(context);
    final adult = MentiAccessScope.adultOf(context);
    final enabled = !saving && store.writable;
    final name = MentiIdentityScope.of(context)?.profile.name ?? s.menti;
    final supports = [
      s.adventureSupport0,
      s.adventureSupport1,
      s.adventureSupport2,
    ];
    return PopScope(
      canPop: !saving,
      child: DefaultTabController(
        length: 3,
        child: Scaffold(
          appBar: AppBar(
            toolbarHeight:
                56 * MediaQuery.textScalerOf(context).scale(1).clamp(1, 2),
            title: Text(s.adventureTitle, maxLines: 2),
            actions: [
              IconButton(
                tooltip: s.adventureRetry,
                onPressed: saving || loading ? null : _load,
                icon: const Icon(Icons.refresh),
              ),
            ],
            bottom: loading || failed
                ? null
                : TabBar(
                    isScrollable: true,
                    tabs: [
                      Tab(text: s.adventureDaily),
                      Tab(text: s.adventureMap),
                      Tab(text: s.adventureBadges),
                    ],
                  ),
          ),
          body: loading
              ? const Center(child: CircularProgressIndicator())
              : failed
              ? MentiPageBody(
                  children: [
                    Text(s.adventureLoadError),
                    TextButton(onPressed: _load, child: Text(s.adventureRetry)),
                  ],
                )
              : Column(
                  children: [
                    if (!store.writable)
                      MaterialBanner(
                        content: Text(s.adventureStale),
                        actions: [
                          TextButton(
                            onPressed: saving ? null : _load,
                            child: Text(s.adventureRetry),
                          ),
                        ],
                      ),
                    if (feedback != null &&
                        MentiExperienceScope.reactionsOf(context))
                      Flexible(
                        flex: 0,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxHeight: MediaQuery.sizeOf(context).height * .35,
                          ),
                          child: SingleChildScrollView(
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const MentiCurrentAvatar(
                                    size: 64,
                                    reaction: 'personality',
                                    legacyChild: Icon(
                                      Icons.emoji_emotions,
                                      size: 48,
                                    ),
                                  ),
                                  Semantics(
                                    liveRegion: true,
                                    child: MentiSpeechBubble(
                                      eventToken: sequence,
                                      message: s.adventureMentiSays(
                                        name,
                                        feedback!.station
                                            ? s.adventureStationCompleted
                                            : supports[(sequence - 1) %
                                                  supports.length],
                                      ),
                                    ),
                                  ),
                                  TextButton(
                                    key: const ValueKey(
                                      'adventure-dismiss-feedback',
                                    ),
                                    onPressed: () =>
                                        setState(() => feedback = null),
                                    child: Text(s.adventureSkipFeedback),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    Expanded(
                      child: TabBarView(
                        children: [
                          MentiPageBody(
                            children: [
                              Text(s.adventureIntro),
                              const SizedBox(height: 8),
                              Text(
                                s.adventureToday(
                                  DateFormat.yMMMMd(
                                    Localizations.localeOf(context)
                                        .languageCode,
                                  ).format(day),
                                ),
                              ),
                              Text(
                                s.adventureSlots(store.document.occupied(day)),
                              ),
                              Text(s.adventureNoPenalty),
                              const SizedBox(height: 16),
                              for (final task in AdventureTask.values)
                                if (adult || task != AdventureTask.goal)
                                  _task(task, enabled),
                            ],
                          ),
                          _map(),
                          _badges(),
                        ],
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
