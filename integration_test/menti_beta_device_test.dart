// Runs only on a disposable CI emulator. Real platform preferences; no mocks.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mennyiment/main.dart';
import 'package:mennyiment/app_language.dart';
import 'package:mennyiment/data_backup.dart';
import 'package:mennyiment/data_restore.dart';
import 'package:mennyiment/menti_collection_store.dart';
import 'package:mennyiment/menti_xp_store.dart';

Future<void> reach(WidgetTester t, Finder f) async {
  for (var i = 0; i < 60; i++) {
    if (f.evaluate().isNotEmpty) {
      await t.ensureVisible(f);
      await t.pumpAndSettle();
      return;
    }
    await t.drag(find.byType(Scrollable).first, const Offset(0, -200));
    await t.pumpAndSettle();
  }
  fail('Unreachable native control: $f');
}

Future<void> tap(WidgetTester t, String key) async {
  final f = find.byKey(ValueKey(key));
  await reach(t, f);
  await t.tap(f);
  await t.pumpAndSettle();
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'Android real onboarding, journal edit, durable XP, file round-trip and corrupt backup',
    (t) async {
      final p = await SharedPreferences.getInstance();
      // The workflow creates a new emulator. Never clear data to make a test pass.
      expect(p.getKeys().where((k) => k.startsWith('mennyiment_')), isEmpty);
      await p.setBool('mennyiment_reduce_motion_v1', true);
      await t.pumpWidget(const MennyiMentApp());
      await t.pumpAndSettle();
      await tap(t, 'start-language-hu');
      await tap(t, 'start-next');
      await tap(t, 'start-adult');
      await tap(t, 'start-next');
      await tap(t, 'start-family-girl');
      await tap(t, 'start-look-girl-party-v1');
      await tap(t, 'start-next');
      final name = find.byKey(const ValueKey('start-name'));
      await reach(t, name);
      await t.enterText(name, 'Android Beta');
      await tap(t, 'start-next');
      expect(find.byType(HomePage), findsOneWidget);
      expect(
        jsonDecode(p.getString(CompleteLookStore.key)!)['look'],
        'girl-party-v1',
      );
      await tap(t, 'home-primary-log');
      await t.tap(find.byType(ListTile).first);
      await t.pumpAndSettle();
      final ctx = t.element(find.byType(HomePage));
      final s = appStrings(ctx);
      final price = find.widgetWithText(TextFormField, s.journalOptionalPrice);
      await reach(t, price);
      await t.enterText(price, '0');
      await t.testTextInput.receiveAction(TextInputAction.done);
      await t.pumpAndSettle();
      final save = find.text(s.journalSave);
      await reach(t, save);
      await t.tap(save);
      await t.pumpAndSettle();
      await p.reload();
      final added = jsonDecode(p.getString('mennyiment_drinks_v1')!) as List;
      expect(added.length, 1);
      expect(added.first['priceFt'], 0);
      await t.tap(find.byKey(const ValueKey('nav-journal')));
      await t.pumpAndSettle();
      await tap(t, 'journal-edit-0');
      final edit = find.byKey(const ValueKey('entry-field-0'));
      await reach(t, edit);
      await t.enterText(edit, 'Native edited');
      await t.testTextInput.receiveAction(TextInputAction.done);
      await t.pumpAndSettle();
      await tap(t, 'entry-save');
      await p.reload();
      expect(
        jsonDecode(p.getString('mennyiment_drinks_v1')!)[0]['name'],
        'Native edited',
      );
      final state = await MentiXpStore.checkInToday();
      expect(state.xp, 10);
      expect((await MentiXpStore.checkInToday()).xp, 10);
      // Real Android filesystem plus the same transactional exporter/restorer.
      final before = p.getString('mennyiment_drinks_v1');
      final doc = await BackupExporter().capture();
      final file = File('${Directory.systemTemp.path}/${doc.fileName}');
      await file.writeAsBytes(doc.bytes, flush: true);
      final restorer = BackupRestorer();
      final plan = await restorer.prepare(await file.readAsString());
      await restorer.restore(plan, confirmed: true);
      await p.reload();
      expect(p.getString('mennyiment_drinks_v1'), before);
      expect((await MentiXpStore.load()).xp, 10);
      await expectLater(restorer.prepare('{broken'), throwsFormatException);
      await p.reload();
      expect(p.getString('mennyiment_drinks_v1'), before);
      // A synthetic older XP snapshot on this disposable device exercises durable unlocks.
      await p.setString(
        MentiXpStore.currentKey,
        jsonEncode({'xp': 190, 'days': [], 'completed': []}),
      );
      final older = await BackupExporter().capture();
      expect((await MentiXpStore.checkInToday()).xp, 200);
      expect((await MentiXpStore.checkInToday()).xp, 200);
      await t.pumpAndSettle();
      final collection = CompleteLookStore();
      await collection.load();
      for (final id in [
        'boy-legendary-v1',
        'girl-legendary-v1',
        'neutral-legendary-v1',
      ]) {
        expect(collection.selection.acquired, contains(id));
      }
      final olderPlan = await restorer.prepare(older.json);
      await restorer.restore(olderPlan, confirmed: true);
      await collection.load();
      expect((await MentiXpStore.load()).xp, 190);
      for (final id in [
        'boy-legendary-v1',
        'girl-legendary-v1',
        'neutral-legendary-v1',
      ]) {
        expect(collection.selection.acquired, contains(id));
      }
      collection.dispose();
      // Reload the real app from persisted state; do not reseed preferences.
      await t.pumpWidget(const SizedBox.shrink());
      await t.pumpAndSettle();
      await t.pumpWidget(const MennyiMentApp());
      await t.pumpAndSettle();
      expect(find.byKey(const ValueKey('start-next')), findsNothing);
      expect(find.byType(HomePage), findsOneWidget);
      expect(t.takeException(), isNull);
      // ignore: avoid_print
      print(
        'MENTI_BETA_NATIVE: onboarding/girl/journal/create-edit-zero/native-file-restore/corrupt-rejection/XP-once/190-to-200/all-three-legendary/older-restore/reload passed; file picker and physical phone still manual.',
      );
    },
  );
}
