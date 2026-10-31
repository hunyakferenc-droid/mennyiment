import 'package:flutter/material.dart';
import 'menti_motion.dart';

/// Megjelenítési adatmodell: a meglévő megtakarítási célokból készül.
/// Nem módosít és nem ment felhasználói adatokat.
class MentiWorldGoal {
  final String title;
  final String emoji;
  final int savedFt;
  final int targetFt;

  const MentiWorldGoal({required this.title, required this.emoji,
    required this.savedFt, required this.targetFt});

  int get percent => targetFt <= 0 ? 0 :
      ((savedFt / targetFt) * 100).floor().clamp(0, 100).toInt();
  int get unlocked => [25, 50, 75, 100].where((s) => percent >= s).length;
}

class MentiGoalWorldPage extends StatefulWidget {
  final List<MentiWorldGoal> goals;
  const MentiGoalWorldPage({super.key, required this.goals});

  @override
  State<MentiGoalWorldPage> createState() => _MentiGoalWorldPageState();
}

class _MentiGoalWorldPageState extends State<MentiGoalWorldPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _float;
  static const orange = Color(0xFFFF9E2C);
  static const purple = Color(0xFF9C67E8);

  @override
  void initState() {
    super.initState();
    _float = AnimationController(vsync: this,
      duration: const Duration(milliseconds: 2400));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MentiMotionScope.animateOf(context)) {
      if (!_float.isAnimating) _float.repeat(reverse: true);
    } else {
      _float.reset();
    }
  }

  @override
  void dispose() {
    _float.dispose();
    super.dispose();
  }

  String _formatFt(int value) =>
      '${value.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => ' ')} Ft';

  Widget _panel(Widget child) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: const Color(0xFF1F1828),
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: purple.withValues(alpha: .3))),
    child: child,
  );

  @override
  Widget build(BuildContext context) {
    final total = widget.goals.fold<int>(0, (sum, g) => sum + g.savedFt);
    final achieved = widget.goals.fold<int>(0, (sum, g) => sum + g.unlocked);
    final completed = widget.goals.where((g) => g.percent == 100).length;
    final message = widget.goals.isEmpty
        ? 'Szia! Válassz egy megtakarítási célt, és indulhat a közös kaland!'
        : completed > 0
            ? 'Ez igen! Már teljesítettél megtakarítási célt. Ünnepeljük meg!'
            : achieved > 0
                ? 'Már vannak feloldott mérföldköveid. Haladj a saját tempódban!'
                : 'Minden cél egy apró, valóban félretett összeggel kezdődik.';

    return Scaffold(
      backgroundColor: const Color(0xFF100C17),
      appBar: AppBar(
        backgroundColor: const Color(0xFF100C17),
        title: const Text('Menti világa'),
      ),
      body: Center(child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 700),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 32),
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF412451), Color(0xFF17101D)],
                  begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: purple.withValues(alpha: .45)),
              ),
              padding: const EdgeInsets.all(18),
              child: Column(children: [
                const Text('MENNYIMENT? • MENTI VILÁGA',
                  style: TextStyle(color: orange,
                    fontSize: 12, fontWeight: FontWeight.w800,
                    letterSpacing: 1.2)),
                const SizedBox(height: 10),
                AnimatedBuilder(animation: _float, builder: (ctx, child) =>
                  Transform.translate(offset: Offset(0, -5 + _float.value * 10),
                    child: child),
                  child: Semantics(label: 'Menti karakter',
                    child: Image.asset('assets/images/menti_open.png',
                      width: 180, height: 180, fit: BoxFit.contain))),
                const SizedBox(height: 8),
                Text(message, textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16,
                    fontWeight: FontWeight.w600)),
              ]),
            ),
            const SizedBox(height: 16),
            _panel(Column(crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('A saját eredményeid',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 14),
                Wrap(spacing: 18, runSpacing: 12, children: [
                  _metric('Félretett összesen', _formatFt(total)),
                  _metric('Feloldott jelvények', '$achieved db'),
                  _metric('Elért célok', '$completed db'),
                ]),
              ])),
            const SizedBox(height: 22),
            const Text('Céljaid és mérföldköveid',
              style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            if (widget.goals.isEmpty)
              _panel(const Text('Még nincs megtakarítási célod. A Céljaim képernyőn létrehozhatsz egyet.')),
            ...widget.goals.map((goal) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _panel(Column(crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Text(goal.emoji, style: const TextStyle(fontSize: 30)),
                    const SizedBox(width: 10),
                    Expanded(child: Text(goal.title,
                      style: const TextStyle(fontSize: 18,
                        fontWeight: FontWeight.bold))),
                    Text('${goal.percent}%',
                      style: const TextStyle(color: orange,
                        fontWeight: FontWeight.bold, fontSize: 18)),
                  ]),
                  const SizedBox(height: 12),
                  LinearProgressIndicator(value: goal.percent / 100,
                    color: orange, backgroundColor: Colors.white12,
                    minHeight: 9, borderRadius: BorderRadius.circular(8)),
                  const SizedBox(height: 9),
                  Text('${_formatFt(goal.savedFt)} / ${_formatFt(goal.targetFt)}',
                    style: const TextStyle(color: Colors.white70)),
                  const SizedBox(height: 14),
                  Wrap(spacing: 8, runSpacing: 8,
                    children: [25, 50, 75, 100].map((step) {
                      final unlocked = goal.percent >= step;
                      return Chip(
                        avatar: Icon(unlocked ? Icons.stars : Icons.lock_outline,
                          size: 17, color: unlocked ? orange : Colors.white54),
                        label: Text('$step%'),
                        side: BorderSide(color: unlocked ? orange : Colors.white24),
                        backgroundColor: unlocked
                          ? const Color(0xFF3B253A) : const Color(0xFF25202A),
                      );
                    }).toList()),
                ])),
              )),
            const SizedBox(height: 12),
            const Text('A jelvények kizárólag az alkalmazásban ténylegesen félretettként rögzített pénzhez kötődnek. A becsült megtakarítás nem számít bele. A felület nem kapcsolódik bankszámlához.',
              style: TextStyle(color: Colors.white60, fontSize: 12)),
          ],
        ),
      )),
    );
  }

  Widget _metric(String title, String value) => SizedBox(
    width: 160,
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(value, style: const TextStyle(fontSize: 22,
        fontWeight: FontWeight.w800, color: orange)),
      const SizedBox(height: 4),
      Text(title, style: const TextStyle(color: Colors.white70, fontSize: 12)),
    ]),
  );
}
