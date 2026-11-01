import 'package:flutter/material.dart';

/// Shared spacing for progressively modernized screens.
class MentiPanel extends StatelessWidget {
  const MentiPanel({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 16),
    child: Padding(padding: const EdgeInsets.all(18), child: child),
  );
}

/// Scrollable and safe on small phones, with a readable width on larger screens.
class MentiPageBody extends StatelessWidget {
  const MentiPageBody({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680),
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: children,
        ),
      ),
    ),
  );
}
