import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

import 'l10n/generated/app_localizations.dart';
import 'l10n/generated/app_localizations_hu.dart';

AppLocalizations appStrings(BuildContext context) =>
    AppLocalizations.of(context) ?? AppLocalizationsHu();

String localeCurrency(num value, String locale) => NumberFormat.currency(
  locale: locale,
  name: 'HUF',
  symbol: locale == 'hu' ? 'Ft' : 'HUF',
  decimalDigits: 0,
).format(value);

class AppLanguage extends ChangeNotifier {
  AppLanguage({Future<SharedPreferences> Function()? openPreferences})
    : _openPreferences = openPreferences ?? SharedPreferences.getInstance;
  final Future<SharedPreferences> Function() _openPreferences;
  static const preferenceKey = 'mennyiment_locale_v1';
  String selection = 'hu';
  bool saving = false;
  bool _disposed = false;
  Locale? get locale => selection == 'auto' ? null : Locale(selection);
  void _notify() {
    if (!_disposed) notifyListeners();
  }

  Future<void> load() async {
    try {
      final prefs = await _openPreferences();
      final saved = prefs.get(preferenceKey);
      if (saved == 'hu' || saved == 'en' || saved == 'auto') {
        selection = saved as String;
      }
    } catch (_) {
      /* Keep Hungarian without rewriting an unreadable value. */
    }
    _notify();
  }

  Future<bool> select(String value) async {
    if (saving || !['hu', 'en', 'auto'].contains(value)) return false;
    saving = true;
    _notify();
    try {
      final prefs = await _openPreferences();
      if (!await prefs.setString(preferenceKey, value)) return false;
      selection = value;
      return true;
    } catch (_) {
      return false;
    } finally {
      saving = false;
      _notify();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

class AppLanguageScope extends InheritedNotifier<AppLanguage> {
  const AppLanguageScope({
    super.key,
    required AppLanguage language,
    required super.child,
  }) : super(notifier: language);
  static AppLanguage? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppLanguageScope>()?.notifier;
}

class LanguageMenu extends StatelessWidget {
  const LanguageMenu({super.key});
  @override
  Widget build(BuildContext context) {
    final language = AppLanguageScope.of(context);
    final strings = appStrings(context);
    if (language == null) return const SizedBox.shrink();
    return PopupMenuButton<String>(
      key: const ValueKey('language-menu'),
      tooltip: strings.language,
      icon: const Icon(Icons.language),
      enabled: !language.saving,
      initialValue: language.selection,
      onSelected: (value) async {
        final saved = await language.select(value);
        if (!saved && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(appStrings(context).languageError)),
          );
        }
      },
      itemBuilder: (_) => [
        CheckedPopupMenuItem(
          value: 'auto',
          checked: language.selection == 'auto',
          child: Text(strings.automatic),
        ),
        CheckedPopupMenuItem(
          value: 'hu',
          checked: language.selection == 'hu',
          child: Text(strings.hungarian),
        ),
        CheckedPopupMenuItem(
          value: 'en',
          checked: language.selection == 'en',
          child: Text(strings.english),
        ),
      ],
    );
  }
}
