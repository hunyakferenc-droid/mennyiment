import 'package:flutter/material.dart';
import 'menti_identity/menti_identity_controller.dart';
import 'menti_identity/menti_avatar_renderer.dart';

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

/// Shared missing/error presentation. Never silently substitutes a zero value.
class MentiStatusMessage extends StatelessWidget {
  const MentiStatusMessage({super.key, required this.message, this.onRetry,
    this.retryLabel, this.isError = false});
  final String message;
  final VoidCallback? onRetry;
  final String? retryLabel;
  final bool isError;

  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: isError,
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (!isError && MentiIdentityScope.of(context)?.ready == true)
        const MentiCurrentAvatar(size: 72, legacyChild: SizedBox.shrink()),
      ExcludeSemantics(child: Icon(isError ? Icons.error_outline : Icons.info_outline)),
      const SizedBox(height: 8),
      Text(message),
      if (onRetry != null && retryLabel != null)
        TextButton(onPressed: onRetry, child: Text(retryLabel!)),
    ]),
  );
}

class MentiProgressSummary extends StatelessWidget {
  const MentiProgressSummary({super.key, required this.label,
    required this.current, required this.target});
  final String label;
  final int current;
  final int target;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label),
      const SizedBox(height: 8),
      Semantics(label: label, value: '$current / $target', child: ExcludeSemantics(
        child: LinearProgressIndicator(value: target > 0
            ? (current / target).clamp(0.0, 1.0) : 0))),
    ],
  );
}
