import 'package:flutter/material.dart';

/// Kizárólag a kézzel rögzített, ténylegesen félretett pénzhez kötött mérföldkövek.
/// Az italnapló becsült megtakarítása itt nem számít bele.
class MentiMilestones {
  static const List<int> thresholds = [25, 50, 75, 100];

  static int percent({required int savedFt, required int targetFt}) {
    if (targetFt <= 0 || savedFt <= 0) return 0;
    return ((savedFt / targetFt) * 100).floor().clamp(0, 100).toInt();
  }

  static List<int> achieved({required int savedFt, required int targetFt}) {
    final p = percent(savedFt: savedFt, targetFt: targetFt);
    return thresholds.where((v) => p >= v).toList();
  }

  static String message({required int savedFt, required int targetFt}) {
    if (targetFt <= 0) return 'Állíts be egy érvényes célösszeget!';
    final p = percent(savedFt: savedFt, targetFt: targetFt);
    if (p >= 100) return 'Menti: Elérted a kitűzött célod! 🎉';
    if (p >= 75) return 'Menti: Már nagyon közel vagy a célodhoz!';
    if (p >= 50) return 'Menti: Félúton jársz, haladj a saját tempódban!';
    if (p >= 25) return 'Menti: Megvan az első negyed!';
    if (savedFt > 0) return 'Menti: Minden ténylegesen félretett forint számít.';
    return 'Menti: Minden nagy cél egy apró lépéssel kezdődik.';
  }
}

class MentiGoalMilestones extends StatelessWidget {
  const MentiGoalMilestones({super.key, required this.savedFt, required this.targetFt});
  final int savedFt;
  final int targetFt;

  @override
  Widget build(BuildContext context) {
    final achieved = MentiMilestones.achieved(savedFt: savedFt, targetFt: targetFt);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF35213E),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(children: [
          const Text('🌟', style: TextStyle(fontSize: 26)),
          const SizedBox(width: 10),
          Expanded(child: Text(
            MentiMilestones.message(savedFt: savedFt, targetFt: targetFt),
            style: const TextStyle(color: Color(0xFFFFD39B)),
          )),
        ]),
      ),
      const SizedBox(height: 10),
      Wrap(spacing: 8, runSpacing: 8, children: MentiMilestones.thresholds.map((step) {
        final unlocked = achieved.contains(step);
        return Chip(
          avatar: Icon(unlocked ? Icons.emoji_events : Icons.lock_outline,
            size: 16, color: unlocked ? const Color(0xFFFF9E2C) : Colors.white54),
          label: Text('$step%'),
          backgroundColor: unlocked ? const Color(0xFF482C38) : const Color(0xFF221D29),
          side: BorderSide(color: unlocked ? const Color(0xFFFF9E2C) : Colors.white12),
        );
      }).toList()),
      const SizedBox(height: 4),
      const Text('A jelvények a kézzel rögzített félretett összeg alapján nyílnak meg.',
        style: TextStyle(color: Colors.white60, fontSize: 11)),
    ]);
  }
}
