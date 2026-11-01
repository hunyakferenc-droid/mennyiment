import 'package:flutter/material.dart';
import 'app_language.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Presentation preference only; never reads or changes profile or XP data.
class MentiMotionSettings extends ChangeNotifier {
  static const preferenceKey = 'mennyiment_reduce_motion_v1';
  bool manual = false;
  bool ready = false;
  bool saving = false;
  String? error;
  bool _disposed = false;

  void _changed() {
    if (!_disposed) notifyListeners();
  }

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final value = prefs.get(preferenceKey);
      // Unknown values remain untouched; fail closed for motion.
      manual = value == null
          ? false
          : value is bool
          ? value
          : true;
      ready = true;
      error = null;
    } catch (_) {
      error = 'Nem sikerült betölteni a mozgásbeállítást.';
    }
    _changed();
  }

  Future<void> setReduced(bool value) async {
    if (!ready || saving || _disposed) return;
    saving = true;
    error = null;
    _changed();
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!await prefs.setBool(preferenceKey, value)) {
        throw StateError('Motion preference was not saved');
      }
      manual = value;
    } catch (_) {
      error = 'A mozgásbeállítás mentése nem sikerült. Próbáld újra.';
    } finally {
      saving = false;
      _changed();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

class MentiMotionScope extends StatefulWidget {
  const MentiMotionScope({super.key, required this.child});
  final Widget child;

  static MentiMotionSettings? settingsOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_MotionInherited>()?.notifier;

  static bool systemReducedOf(BuildContext context) =>
      MediaQuery.disableAnimationsOf(context) ||
      MediaQuery.accessibleNavigationOf(context);

  static bool reducedOf(BuildContext context) {
    final settings = settingsOf(context);
    return systemReducedOf(context) ||
        (settings != null && (!settings.ready || settings.manual));
  }

  /// Also stop work in routes hidden by the Navigator.
  static bool animateOf(BuildContext context) =>
      !reducedOf(context) && TickerMode.valuesOf(context).enabled;

  @override
  State<MentiMotionScope> createState() => _MentiMotionScopeState();
}

class _MentiMotionScopeState extends State<MentiMotionScope> {
  late final MentiMotionSettings settings;
  @override
  void initState() {
    super.initState();
    settings = MentiMotionSettings()..load();
  }

  @override
  void dispose() {
    settings.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      _MotionInherited(notifier: settings, child: widget.child);
}

class _MotionInherited extends InheritedNotifier<MentiMotionSettings> {
  const _MotionInherited({required super.notifier, required super.child});
}

class MentiMotionPreference extends StatelessWidget {
  const MentiMotionPreference({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = MentiMotionScope.settingsOf(context);
    if (settings == null) return const SizedBox.shrink();
    final system = MentiMotionScope.systemReducedOf(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SwitchListTile.adaptive(
          key: const ValueKey('menti-reduce-motion'),
          contentPadding: EdgeInsets.zero,
          title: Text(appStrings(context).experienceMotionTitle),
          subtitle: Text(
            system
                ? appStrings(context).experienceMotionSystem
                : appStrings(context).experienceMotionHint,
          ),
          value: settings.manual,
          onChanged: settings.ready && !settings.saving
              ? settings.setReduced
              : null,
        ),
        if (settings.error != null) ...[
          Text(settings.ready ? appStrings(context).experienceMotionSaveError : appStrings(context).experienceMotionLoadError),
          if (!settings.ready)
            TextButton(
              onPressed: settings.load,
              child: Text(appStrings(context).challengeRetry),
            ),
        ],
      ],
    );
  }
}
