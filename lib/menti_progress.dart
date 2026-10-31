import 'package:flutter/material.dart';
import 'menti_xp_store.dart';
import 'menti_animation.dart';

/// Az XP a tudatos önreflexiót jutalmazza, nem az alkoholfogyasztást.
class MentiProgressPage extends StatefulWidget {
  const MentiProgressPage({super.key});

  @override
  State<MentiProgressPage> createState() => _MentiProgressPageState();
}

class _MentiProgressPageState extends State<MentiProgressPage> {
  static const _mint = Color(0xFF76E4B8);
  static const _background = Color(0xFF0B1715);
  static const _card = Color(0xFF172923);
  static const _tasks = <(String, String, IconData, int)>[
    ('review', 'Átnéztem a naplómat', Icons.menu_book_outlined, 15),
    ('cost', 'Átgondoltam a költéseimet', Icons.account_balance_wallet_outlined, 15),
    ('goal', 'Kijelöltem egy személyes célt', Icons.flag_outlined, 20),
  ];

  bool _loading = true;
  int _xp = 0;
  int _reaction = 0;
  final Set<String> _days = {};
  final Set<String> _completed = {};

  String _dayKey(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  String _weekKey(DateTime date) {
    final monday = DateTime(date.year, date.month, date.day)
        .subtract(Duration(days: date.weekday - 1));
    return _dayKey(monday);
  }

  int get _level => 1 + (_xp ~/ 50);
  int get _levelXp => _xp % 50;
  bool get _checkedToday => _days.contains(_dayKey(DateTime.now()));
  bool _done(String id) => _completed.contains('${_weekKey(DateTime.now())}:$id');

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final state = await MentiXpStore.load();
      if (!mounted) return;
      setState(() {
        _xp = state.xp;
        _days..clear()..addAll(state.days);
        _completed..clear()..addAll(state.completed);
      });
    } catch (error) {
      debugPrint('Menti fejlődés betöltési hiba: $error');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _dailyCheckin() async {
    if (_loading || _checkedToday) return;
    setState(() => _loading = true);
    try {
      final wasChecked = _checkedToday;
      final state = await MentiXpStore.checkInToday();
      if (!mounted) return;
      setState(() {
        _xp = state.xp;
        _days..clear()..addAll(state.days);
        _completed..clear()..addAll(state.completed);
        if (!wasChecked) _reaction++;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mai bejelentkezés kész! +10 XP')),
      );
    } catch (error) {
      debugPrint('Menti XP mentési hiba: $error');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('A mentés nem sikerült.')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _completeTask(String id, int points) async {
    if (_loading || _done(id)) return;
    setState(() => _loading = true);
    try {
      final state = await MentiXpStore.completeWeekly(id);
      if (!mounted) return;
      setState(() {
        _xp = state.xp;
        _days..clear()..addAll(state.days);
        _completed..clear()..addAll(state.completed);
        _reaction++;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Kihívás teljesítve! +$points XP')),
      );
    } catch (error) {
      debugPrint('Menti heti kihívás mentési hiba: $error');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('A mentés nem sikerült.')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget _panel(Widget child) => Container(
    width: double.infinity,
    margin: const EdgeInsets.only(bottom: 16),
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: _card,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
    ),
    child: child,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(title: const Text('Menti fejlődése')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 680),
                child: ListView(
                  padding: const EdgeInsets.all(18),
                  children: [
                    _panel(Column(children: [
                      MentiAnimation(size: 170, reaction: _reaction),
                      Text('Menti • $_level. szint',
                        style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text('$_xp XP összesen', style: const TextStyle(color: _mint)),
                      const SizedBox(height: 14),
                      LinearProgressIndicator(
                        value: _levelXp / 50,
                        minHeight: 10,
                        borderRadius: BorderRadius.circular(12),
                        backgroundColor: Colors.white12,
                        color: _mint,
                      ),
                      const SizedBox(height: 7),
                      Text('$_levelXp / 50 XP a következő szintig',
                        style: const TextStyle(color: Colors.white70)),
                    ])),
                    _panel(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('Napi bejelentkezés',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      const Text('Szánj egy pillanatot arra, hogy átgondold a napodat. +10 XP'),
                      const SizedBox(height: 14),
                      SizedBox(width: double.infinity, child: FilledButton.icon(
                        onPressed: _checkedToday ? null : _dailyCheckin,
                        icon: Icon(_checkedToday ? Icons.check_circle : Icons.favorite_outline),
                        label: Text(_checkedToday ? 'Ma már bejelentkeztél' : 'Mai bejelentkezés'),
                      )),
                    ])),
                    _panel(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('Heti kihívások',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      const Text('Az XP-rendszer közös a kezdőlappal. Hétfőn új kihívások indulnak.',
                        style: TextStyle(color: Colors.white70)),
                      const SizedBox(height: 10),
                      for (final task in _tasks) ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(task.$3, color: _mint),
                        title: Text(task.$2),
                        subtitle: Text('+${task.$4} XP • hetente egyszer'),
                        trailing: _done(task.$1)
                            ? const Icon(Icons.check_circle, color: _mint)
                            : OutlinedButton(
                                onPressed: () => _completeTask(task.$1, task.$4),
                                child: const Text('Kész'),
                              ),
                      ),
                    ])),
                    _panel(const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Mérföldkövek',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      SizedBox(height: 10),
                      Text('🌱 Kezdő felfedező • 1. szint'),
                      SizedBox(height: 8),
                      Text('⭐ Tudatos útitárs • 3. szint'),
                      SizedBox(height: 8),
                      Text('🏆 Kitartó felfedező • 5. szint'),
                    ])),
                    const Text(
                      'Az XP a bejelentkezéseket és a saját magad által jelölt tevékenységeket követi. '
                      'Nem méri az alkoholmentességet vagy az egészségi állapotot.',
                      style: TextStyle(color: Colors.white60, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
