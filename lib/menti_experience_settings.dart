import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Presentation flags only. Never reads journal values, migrates, or grants XP.
class MentiExperienceSettings extends ChangeNotifier {
  MentiExperienceSettings({Future<SharedPreferences> Function()? open})
      : open = open ?? SharedPreferences.getInstance;
  static const reactionsKey = 'mennyiment_reactions_enabled_v1';
  static const introKey = 'mennyiment_intro_seen_v1';
  final Future<SharedPreferences> Function() open;
  bool reactions = true;
  bool introSeen = false;
  bool ready = false;
  bool saving = false;
  String? error;
  Object? _rawReactions;
  Object? _rawIntro;
  bool _disposed = false;

  /// Call after recovery, before existing home migrations can create app keys.
  /// Any existing app data (including unknown future keys) suppresses the invite.
  static bool shouldOfferIntro(SharedPreferences prefs) =>
      prefs.get(introKey) == null && !prefs.getKeys().any((key) =>
        key.startsWith('mennyiment_') && key != reactionsKey && key != introKey);

  void _notify() { if (!_disposed) notifyListeners(); }

  Future<void> load() async {
    if (saving || _disposed) return;
    ready = false;
    error = null;
    _notify();
    try {
      final prefs = await open();
      await prefs.reload();
      final reactionValue = prefs.get(reactionsKey);
      final introValue = prefs.get(introKey);
      if ((reactionValue != null && reactionValue is! bool) ||
          (introValue != null && introValue is! bool)) {
        throw const FormatException('Invalid experience preference');
      }
      _rawReactions = reactionValue;
      _rawIntro = introValue;
      reactions = reactionValue as bool? ?? true;
      introSeen = introValue as bool? ?? false;
      ready = true;
    } catch (failure, stack) {
      error = 'load';
      debugPrint('Experience preference load failure: ${failure.runtimeType}\n$stack');
    }
    _notify();
  }

  Future<bool> setReactions(bool value) => _save(reactionsKey, value);
  Future<bool> markIntroSeen() => _save(introKey, true);

  Future<bool> _save(String key, bool value) async {
    if (!ready || saving || _disposed) return false;
    saving = true;
    error = null;
    _notify();
    SharedPreferences? prefs;
    try {
      prefs = await open();
      await prefs.reload();
      final previous = key == reactionsKey ? _rawReactions : _rawIntro;
      if (prefs.get(key) != previous) {
        ready = false;
        throw StateError('Experience preference changed; reload required');
      }
      // Idempotence still verifies the current stored value before reporting success.
      if (previous == value) return true;
      if (!await prefs.setBool(key, value)) {
        throw StateError('Experience preference write unconfirmed');
      }
      if (key == reactionsKey) {
        _rawReactions = value;
        reactions = value;
      } else {
        _rawIntro = value;
        introSeen = value;
      }
      return true;
    } catch (failure, stack) {
      error = 'save';
      debugPrint('Experience preference write failure: ${failure.runtimeType}\n$stack');
      try { await prefs?.reload(); } catch (_) { ready = false; }
      return false;
    } finally {
      saving = false;
      _notify();
    }
  }

  @override
  void dispose() { _disposed = true; super.dispose(); }
}

class MentiExperienceScope extends StatefulWidget {
  const MentiExperienceScope({super.key, required this.child, this.settings});
  final Widget child;
  final MentiExperienceSettings? settings;
  static MentiExperienceSettings? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_ExperienceInherited>()?.notifier;
  static bool reactionsOf(BuildContext context) {
    final settings = of(context);
    return settings == null || (settings.ready && settings.reactions);
  }
  @override
  State<MentiExperienceScope> createState() => _MentiExperienceScopeState();
}

class _MentiExperienceScopeState extends State<MentiExperienceScope> {
  late final MentiExperienceSettings settings = widget.settings ?? MentiExperienceSettings();
  @override
  void initState() { super.initState(); settings.load(); }
  @override
  void dispose() {
    if (widget.settings == null) settings.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) => _ExperienceInherited(notifier: settings, child: widget.child);
}

class _ExperienceInherited extends InheritedNotifier<MentiExperienceSettings> {
  const _ExperienceInherited({required super.notifier, required super.child});
}

/// Hides a disabled event and does not replay that same event after re-enabling.
/// A distinct verified event token may appear normally. Loading is not a disable.
class MentiReactionVisibility extends StatefulWidget {
  const MentiReactionVisibility({super.key, required this.token, required this.child});
  final Object token;
  final Widget child;
  @override
  State<MentiReactionVisibility> createState() => _MentiReactionVisibilityState();
}
class _MentiReactionVisibilityState extends State<MentiReactionVisibility> {
  bool _suppressed = false;
  @override
  void didUpdateWidget(covariant MentiReactionVisibility oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.token != widget.token) _suppressed = false;
  }
  @override
  Widget build(BuildContext context) {
    final settings = MentiExperienceScope.of(context);
    if (settings != null && !settings.ready) return const SizedBox.shrink();
    if (!MentiExperienceScope.reactionsOf(context)) _suppressed = true;
    return _suppressed ? const SizedBox.shrink() : widget.child;
  }
}
