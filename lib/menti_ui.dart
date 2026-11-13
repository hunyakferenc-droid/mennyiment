import 'package:flutter/material.dart';

import 'menti_identity/menti_identity_controller.dart';
import 'menti_identity/menti_avatar_renderer.dart';

/// Shared spacing for progressively modernized screens.
class MentiPanel extends StatelessWidget {
  const MentiPanel({super.key, required this.child, this.highlighted = false});

  final Widget child;
  final bool highlighted;

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 16),
    shape: highlighted
        ? RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: Theme.of(context).colorScheme.primary,
              width: 1.5,
            ),
          )
        : null,
    child: Padding(padding: const EdgeInsets.all(16), child: child),
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
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.all(16),
          children: children,
        ),
      ),
    ),
  );
}

/// Shared missing/error presentation. Never silently substitutes a zero value.
class MentiStatusMessage extends StatelessWidget {
  const MentiStatusMessage({
    super.key,
    required this.message,
    this.onRetry,
    this.retryLabel,
    this.isError = false,
  });
  final String message;
  final VoidCallback? onRetry;
  final String? retryLabel;
  final bool isError;

  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: isError,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!isError && MentiIdentityScope.of(context)?.ready == true)
          const MentiCurrentAvatar(size: 72, legacyChild: SizedBox.shrink()),
        ExcludeSemantics(
          child: Icon(isError ? Icons.error_outline : Icons.info_outline),
        ),
        const SizedBox(height: 8),
        Text(message),
        if (onRetry != null && retryLabel != null)
          TextButton(onPressed: onRetry, child: Text(retryLabel!)),
      ],
    ),
  );
}

class MentiProgressSummary extends StatelessWidget {
  const MentiProgressSummary({
    super.key,
    required this.label,
    required this.current,
    required this.target,
  });
  final String label;
  final int current;
  final int target;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label),
      const SizedBox(height: 8),
      Semantics(
        label: label,
        value: '$current / $target',
        child: ExcludeSemantics(
          child: LinearProgressIndicator(
            value: target > 0 ? (current / target).clamp(0.0, 1.0) : 0,
          ),
        ),
      ),
    ],
  );
}

/// State stays understandable without color; grows naturally with large text.
class MentiStatusBadge extends StatelessWidget {
  const MentiStatusBadge({
    super.key,
    required this.label,
    required this.icon,
    this.highlight = false,
  });
  final String label;
  final IconData icon;
  final bool highlight;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: highlight ? const Color(0xFF3A2A16) : const Color(0xFF32253F),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ExcludeSemantics(
          child: Icon(
            icon,
            size: 18,
            color: highlight ? Theme.of(context).colorScheme.primary : null,
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(label, style: Theme.of(context).textTheme.bodySmall),
        ),
      ],
    ),
  );
}
