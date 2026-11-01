import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
// ignore: depend_on_referenced_packages
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';
import 'package:mennyiment/menti_access.dart';
import 'package:mennyiment/wellbeing_journal.dart';
import 'package:mennyiment/l10n/generated/app_localizations.dart';

class _RejectWrites extends InMemorySharedPreferencesStore {
  _RejectWrites(super.data) : super.withData();
  @override
  Future<bool> setValue(String type, String key, Object value) async =>
      key == 'flutter.mennyiment_wellbeing_v1'
      ? false
      : super.setValue(type, key, value);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const key = 'mennyiment_wellbeing_v1';
  Future<void> show(WidgetTester tester, {MentiAccessSettings? access}) async {
    tester.view.physicalSize = const Size(800, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: access == null
            ? const WellbeingJournalPage()
            : MentiAccessScope(
                settings: access,
                child: const WellbeingJournalPage(),
              ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'minor wellbeing hides alcohol fields while preserving saved symptoms and unknown fields',
    (tester) async {
      final now = DateTime.now();
      final original = {
        'day': DateTime(now.year, now.month, now.day).toIso8601String(),
        'mood': 3,
        'sleep': 4,
        'hangover': 2,
        'note': 'Old note',
        'future': {'preserve': true},
      };
      SharedPreferences.setMockInitialValues({
        key: jsonEncode([original]),
        MentiAccessSettings.key:
            '{"version":1,"audience":"minor","complete":true}',
      });
      final access = MentiAccessSettings();
      await access.load();
      await show(tester, access: access);
      expect(find.text('Hangover symptoms'), findsNothing);
      await tester.enterText(find.byType(TextField), 'Changed note');
      await tester.tap(find.text('Update entry'));
      await tester.pumpAndSettle();
      final saved =
          (jsonDecode(
                (await SharedPreferences.getInstance()).getString(key)!,
              ) as List).single
              as Map;
      expect(saved['hangover'], 2);
      expect(saved['future'], {'preserve': true});
      expect(saved['note'], 'Changed note');
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      access.dispose();
    },
  );
  testWidgets(
    'a rejected wellbeing write keeps storage and does not report success',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      SharedPreferencesStorePlatform.instance = _RejectWrites({});
      await show(tester);
      await tester.tap(find.text('Save day'));
      await tester.pumpAndSettle();
      expect((await SharedPreferences.getInstance()).containsKey(key), false);
      expect(find.text('Your daily wellbeing has been saved.'), findsNothing);
      expect(find.text('Update entry'), findsNothing);
      expect(find.textContaining('couldn’t finish safely'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    },
  );
  testWidgets('corrupt wellbeing remains unchanged with writes disabled', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({key: '{broken'});
    await show(tester);
    final button = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Save day'),
    );
    expect(button.onPressed, isNull);
    expect((await SharedPreferences.getInstance()).getString(key), '{broken');
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
}
