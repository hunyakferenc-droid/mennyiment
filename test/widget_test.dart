import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mennyiment/wellbeing_journal.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('Közérzet-bejegyzés menthető formátuma oda-vissza működik', () {
    final source = WellbeingEntry(
      day: DateTime(2026, 10, 27), mood: 4,
      sleepQuality: 3, hangover: 1, note: 'Teszt',
    );
    final restored = WellbeingEntry.fromJson(source.toJson());
    expect(restored.day, DateTime(2026, 10, 27));
    expect(restored.mood, 4);
    expect(restored.sleepQuality, 3);
    expect(restored.hangover, 1);
    expect(restored.note, 'Teszt');
  });

  testWidgets('Közérzetnapló megnyílik és menthető', (tester) async {
    tester.view.physicalSize = const Size(1100, 2200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: WellbeingJournalPage()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('Hogy érzed magad?'), findsOneWidget);
    await tester.ensureVisible(find.text('Nap mentése'));
    await tester.tap(find.text('Nap mentése'));
    await tester.pump();
    expect(find.text('Bejegyzés frissítése'), findsOneWidget);
  });
}
