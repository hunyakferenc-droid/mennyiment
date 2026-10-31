import 'package:flutter/material.dart';

import 'app_language.dart';
import 'menti_motion.dart';
import 'menti_xp_store.dart';

/// A natural-height grid that respects the user's chosen text size.
class HomeAdaptiveGrid extends StatelessWidget {
  const HomeAdaptiveGrid({super.key, required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, size) {
    final largeText = MediaQuery.textScalerOf(context).scale(16) > 20;
    final columns = size.maxWidth < 360 || largeText ? 1 : 2;
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (final child in children)
          SizedBox(
            width: columns == 1 ? size.maxWidth : (size.maxWidth - 10) / 2,
            child: child,
          ),
      ],
    );
  });
}

class HomeStatTile extends StatelessWidget {
  const HomeStatTile({super.key, required this.label, required this.value,
    required this.icon});
  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    child: Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 12),
          Text(value, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 4),
          Text(label),
        ]),
      ),
    ),
  );
}

class HomeActionCard extends StatelessWidget {
  const HomeActionCard({super.key, required this.title, required this.subtitle,
    required this.icon, required this.onTap});
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    enabled: onTap != null,
    child: Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 12),
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(subtitle),
          ]),
        ),
      ),
    ),
  );
}

/// Presentation only: profile, XP and event persistence stay in the home state.
class HomeMentiCard extends StatelessWidget {
  const HomeMentiCard({super.key, required this.character, required this.name,
    required this.xp, required this.message, required this.checkedToday,
    required this.busy, required this.onChoose, required this.onProgress,
    required this.onCheckIn});
  final Widget character;
  final String name;
  final int xp;
  final String message;
  final bool checkedToday;
  final bool busy;
  final VoidCallback onChoose;
  final VoidCallback onProgress;
  final VoidCallback onCheckIn;

  @override
  Widget build(BuildContext context) {
    final s = appStrings(context);
    final details = Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('$name • ${s.evolutionLevel(MentiXpState.levelFor(xp))}',
        style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 6),
      Text(s.homeMentiHint),
      const SizedBox(height: 8),
      Text(message, style: TextStyle(color: Theme.of(context).colorScheme.primary)),
      TextButton.icon(onPressed: onChoose,
        icon: const Icon(Icons.palette_outlined), label: Text(s.chooseMenti)),
      TextButton.icon(onPressed: onProgress,
        icon: const Icon(Icons.auto_awesome), label: Text(s.mentiProgress)),
    ]);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          LayoutBuilder(builder: (context, size) {
            final stack = size.maxWidth < 340 ||
                MediaQuery.textScalerOf(context).scale(16) > 20;
            return stack
                ? Column(crossAxisAlignment: CrossAxisAlignment.start,
                    children: [Center(child: character), const SizedBox(height: 16), details])
                : Row(children: [character, const SizedBox(width: 16),
                    Expanded(child: details)]);
          }),
          const SizedBox(height: 12),
          Wrap(spacing: 12, runSpacing: 8, children: [
            Text(s.homeTotalXp(xp)),
            Text(s.evolutionRemaining(MentiXpState.remainingFor(xp))),
          ]),
          const SizedBox(height: 8),
          Semantics(
            label: s.homeLevelProgress,
            value: '${(MentiXpState.levelXpFor(xp) * 2).round()}%',
            child: ExcludeSemantics(child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: MentiXpState.levelXpFor(xp) / 50),
              duration: MentiMotionScope.reducedOf(context)
                  ? Duration.zero : const Duration(milliseconds: 650),
              builder: (context, value, child) => LinearProgressIndicator(
                value: value, minHeight: 9,
                borderRadius: BorderRadius.circular(8)),
            )),
          ),
          const SizedBox(height: 12),
          SizedBox(width: double.infinity, child: OutlinedButton.icon(
            onPressed: busy ? null : onCheckIn,
            icon: Icon(checkedToday ? Icons.check_circle_outline : Icons.favorite_border),
            label: Text(checkedToday ? s.dailyOpenSaved : s.dailyOpen),
          )),
          Text(s.homeXpHint, style: Theme.of(context).textTheme.bodySmall),
        ]),
      ),
    );
  }
}
