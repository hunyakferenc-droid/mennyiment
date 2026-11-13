import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_language.dart';
import 'journal_watch.dart';
import 'menti_access.dart';
import 'menti_adventure_store.dart';
import 'menti_ui.dart';

/// Earliest selected active task, using only validated existing records.
AdventureTask? nextHomeAdventure(
  AdventureDocument document,
  DateTime day, {
  required bool adult,
}) {
  final tasks = document.tasks(day);
  final active = AdventureTask.values
      .where(
        (task) =>
            (adult || task != AdventureTask.goal) &&
            document.status(day, task) == 'active',
      )
      .toList();
  active.sort((a, b) {
    final compared = DateTime.parse(
      (tasks[a.name] as Map)['selectedAt'] as String,
    ).compareTo(DateTime.parse((tasks[b.name] as Map)['selectedAt'] as String));
    return compared != 0 ? compared : a.index.compareTo(b.index);
  });
  return active.isEmpty ? null : active.first;
}

/// Read-only view of the existing adventure document. No second store or writes.
class HomeAdventureSummary extends StatefulWidget {
  const HomeAdventureSummary({
    super.key,
    required this.refreshToken,
    required this.onOpen,
    this.clock,
  });
  final Object refreshToken;
  final VoidCallback onOpen;
  final DateTime Function()? clock;
  @override
  State<HomeAdventureSummary> createState() => _HomeAdventureSummaryState();
}

class _HomeAdventureSummaryState extends State<HomeAdventureSummary>
    with WidgetsBindingObserver, AutomaticKeepAliveClientMixin {
  late Future<(DateTime, AdventureDocument)> snapshot;
  late final VoidCallback stopWatching;
  Future<(DateTime, AdventureDocument)> _read() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();
    return (
      (widget.clock ?? DateTime.now)().toLocal(),
      AdventureDocument.decode(prefs.get(AdventureStore.key)),
    );
  }

  void _reload() {
    if (mounted) setState(() => snapshot = _read());
  }

  @override
  void initState() {
    super.initState();
    snapshot = _read();
    WidgetsBinding.instance.addObserver(this);
    stopWatching = watchJournal(_reload, storageKey: AdventureStore.key);
  }

  @override
  void didUpdateWidget(HomeAdventureSummary oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshToken != widget.refreshToken) snapshot = _read();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _reload();
  }

  @override
  void dispose() {
    stopWatching();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;
  @override
  Widget build(BuildContext context) {
    super.build(context);
    final s = appStrings(context);
    return MentiPanel(
      child: FutureBuilder<(DateTime, AdventureDocument)>(
        future: snapshot,
        builder: (context, value) {
          final data =
              value.connectionState == ConnectionState.done && !value.hasError
              ? value.data
              : null;
          final next = data == null
              ? null
              : nextHomeAdventure(
                  data.$2,
                  data.$1,
                  adult: MentiAccessScope.adultOf(context),
                );
          final name = switch (next) {
            AdventureTask.wellbeing => s.adventureWellbeing,
            AdventureTask.movement => s.adventureMovement,
            AdventureTask.rest => s.adventureRest,
            AdventureTask.decision => s.adventureDecision,
            AdventureTask.goal => s.adventureGoal,
            null => s.visualNoActive,
          };
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                s.visualTodayTitle,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              if (data != null) ...[
                Text(
                  DateFormat.yMMMd(Localizations.localeOf(context).languageCode)
                      .format(data.$1),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                Text(s.adventureSlots(data.$2.occupied(data.$1))),
                const SizedBox(height: 8),
                if (next != null)
                  Text(
                    s.visualNextTask,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                Text(name, key: const ValueKey('home-next-adventure')),
              ] else if (value.hasError)
                Text(
                  s.visualAdventureUnavailable,
                  key: const ValueKey('home-adventure-unavailable'),
                )
              else
                const LinearProgressIndicator(),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                key: const ValueKey('open-adventures'),
                onPressed: widget.onOpen,
                icon: const Icon(Icons.explore_outlined),
                label: Text(s.adventureTitle),
              ),
            ],
          );
        },
      ),
    );
  }
}
