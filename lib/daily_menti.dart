import 'dart:async';

import 'package:flutter/material.dart';

import 'app_language.dart';
import 'daily_menti_store.dart';
import 'menti_xp_store.dart';
import 'menti_identity/menti_avatar_renderer.dart';
import 'menti_identity/menti_identity_controller.dart';

/// A static character uses the selected profile asset and adds no motion.
class DailyMentiPage extends StatefulWidget {
  const DailyMentiPage({
    super.key,
    required this.characterName,
    required this.assetPath,
    this.clock,
  });

  final String characterName;
  final String assetPath;
  final DateTime Function()? clock;

  @override
  State<DailyMentiPage> createState() => _DailyMentiPageState();
}

class _DailyMentiPageState extends State<DailyMentiPage>
    with WidgetsBindingObserver {
  DateTime get _now => (widget.clock?.call() ?? DateTime.now()).toLocal();
  late DateTime _date;
  Timer? _timer;
  int? _mood;
  int? _energy;
  final _goal = TextEditingController();
  final _evening = TextEditingController();
  bool _loading = true;
  bool _busy = false;
  bool _error = false;
  bool _checked = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _date = _now;
    _load();
    _timer = Timer.periodic(const Duration(minutes: 1), (_) => _rollDay());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _rollDay();
  }

  bool _rollDay() {
    if (_busy || _loading || !mounted) return false;
    final now = _now;
    if (MentiXpStore.dayKey(now) == MentiXpStore.dayKey(_date)) return false;
    _date = now;
    _load();
    return true;
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = false; });
    try {
      final data = await DailyMentiStore.load(_date);
      final xp = await MentiXpStore.load();
      if (!mounted) return;
      setState(() {
        _mood = data['mood'] as int?;
        _energy = data['energy'] as int?;
        _goal.text = data['goal'] as String? ?? '';
        _evening.text = data['evening'] as String? ?? '';
        _checked = xp.checkedOn(_date);
      });
    } catch (_) {
      if (mounted) setState(() => _error = true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    if (_busy || _loading || _error || _rollDay()) return;
    setState(() => _busy = true);
    try {
      await DailyMentiStore.save(
        date: _date, mood: _mood, energy: _energy,
        goal: _goal.text, evening: _evening.text,
      );
      if (!mounted) return;
      setState(() => _checked = true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(appStrings(context).dailySaved)),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(appStrings(context).dailySaveError)),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
      _rollDay();
    }
  }

  Widget _rating(String title, String id, int? value, ValueChanged<int?> select) {
    final s = appStrings(context);
    return Card(child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        Text(s.dailyScale),
        Wrap(spacing: 8, children: [
          for (var n = 1; n <= 5; n++) ChoiceChip(
            key: ValueKey('$id-$n'),
            label: Text('$n'), selected: n == value,
            onSelected: _busy ? null : (selected) =>
                setState(() => select(selected ? n : null)),
          ),
          TextButton(
            key: ValueKey('$id-skip'),
            onPressed: _busy ? null : () => setState(() => select(null)),
            child: Text(s.dailySkip),
          ),
        ]),
      ]),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final s = appStrings(context);
    final characterName = MentiIdentityScope.of(context)?.profile.name ?? widget.characterName;
    final greeting = _now.hour < 12 ? s.dailyMorning :
        _now.hour < 18 ? s.dailyAfternoon : s.dailyEveningGreeting;
    final feedback = _mood == null ? s.dailyWelcome : _mood! <= 2
        ? s.dailySupportLow : _mood == 3 ? s.dailySupportMid : s.dailySupportHigh;
    return Scaffold(
      appBar: AppBar(title: Text(s.dailyTitle)),
      body: Center(child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680),
        child: _loading ? const Center(child: CircularProgressIndicator()) :
        _error ? Column(mainAxisSize: MainAxisSize.min, children: [
          Text(s.dailyLoadError),
          TextButton(onPressed: _load, child: Text(s.dailyRetry)),
        ]) : ListView(padding: const EdgeInsets.all(16), children: [
          Center(child: MentiCurrentAvatar(size: 120, reaction: _mood == null ? null :
              _mood! <= 2 ? 'calming' : _mood! == 3 ? 'focused' : 'personality',
            legacyChild: Image.asset(widget.assetPath, height: 120, fit: BoxFit.contain,
              semanticLabel: characterName))),
          Text(s.dailyGreeting(greeting, characterName),
            style: Theme.of(context).textTheme.headlineSmall),
          Text(MaterialLocalizations.of(context).formatMediumDate(_date)),
          Text(s.dailyOptional),
          const SizedBox(height: 12),
          Text(feedback, key: const ValueKey('daily-feedback')),
          _rating(s.dailyMood, 'mood', _mood, (v) => _mood = v),
          _rating(s.dailyEnergy, 'energy', _energy, (v) => _energy = v),
          Card(child: Padding(padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(s.dailyGoal, style: Theme.of(context).textTheme.titleMedium),
              TextField(controller: _goal, enabled: !_busy, maxLength: 200,
                decoration: InputDecoration(hintText: s.dailyGoalHint)),
            ]),
          )),
          ExpansionTile(title: Text(s.dailyEvening), children: [
            Padding(padding: const EdgeInsets.all(16), child: TextField(
              controller: _evening, enabled: !_busy, maxLength: 500,
              minLines: 2, maxLines: 5,
              decoration: InputDecoration(labelText: s.dailyEveningHint),
            )),
          ]),
          Text(_checked ? s.dailyRewardDone : s.dailyReward),
          FilledButton(key: const ValueKey('daily-save'),
            onPressed: _busy ? null : _save, child: Text(s.dailySave)),
          TextButton(onPressed: _busy ? null : () => Navigator.of(context).pop(),
            child: Text(s.dailyLater)),
        ]),
      )),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _goal.dispose();
    _evening.dispose();
    super.dispose();
  }
}
