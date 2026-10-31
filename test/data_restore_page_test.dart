import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mennyiment/data_backup.dart';
import 'package:mennyiment/data_backup_page.dart';
import 'package:mennyiment/l10n/generated/app_localizations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  for (final locale in ['hu', 'en']) {
    testWidgets('$locale validated preview, cancel, confirm and one restore in a narrow viewport', (tester) async {
      SharedPreferences.setMockInitialValues({'mennyiment_locale_v1': 'en',
        'mennyiment_menti_xp_v2': '{"xp":90,"days":[],"completed":[]}'});
      final text = (await BackupExporter().capture()).json;
      SharedPreferences.setMockInitialValues({'mennyiment_locale_v1': 'hu'});
      tester.view.physicalSize = const Size(320, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var completions = 0;
      await tester.pumpWidget(MaterialApp(locale: Locale(locale),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: DataBackupPage(pick: () async => text, onRestored: () => completions++)));
      final pick = find.byKey(const ValueKey('restore-pick'));
      final apply = find.byKey(const ValueKey('restore-apply'));
      final p = await SharedPreferences.getInstance();
      await tester.ensureVisible(pick);
      await tester.tap(pick);
      await tester.pumpAndSettle();
      expect(find.text('mennyiment_locale_v1'), findsOneWidget);
      expect(p.getString('mennyiment_locale_v1'), 'hu');
      await tester.ensureVisible(apply);
      await tester.tap(apply);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('restore-cancel')));
      await tester.pumpAndSettle();
      expect(p.getString('mennyiment_locale_v1'), 'hu');
      await tester.tap(apply);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('restore-confirm')));
      await tester.pumpAndSettle();
      expect(p.getString('mennyiment_locale_v1'), 'en');
      expect(p.getString('mennyiment_menti_xp_v2'), '{"xp":90,"days":[],"completed":[]}');
      expect(completions, 1);
      expect(apply, findsNothing);
      expect(tester.takeException(), isNull);
    });
    testWidgets('$locale invalid or cancelled file never offers restore or changes data', (tester) async {
      SharedPreferences.setMockInitialValues({'mennyiment_locale_v1': 'hu'});
      String? file = '{bad';
      await tester.pumpWidget(MaterialApp(locale: Locale(locale),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: DataBackupPage(pick: () async => file)));
      final pick = find.byKey(const ValueKey('restore-pick'));
      await tester.ensureVisible(pick);
      await tester.tap(pick);
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('restore-apply')), findsNothing);
      expect((await SharedPreferences.getInstance()).getString('mennyiment_locale_v1'), 'hu');
      file = null;
      await tester.tap(pick);
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('restore-apply')), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }
}
