import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mennyiment/main.dart';
import 'package:mennyiment/menti_club_store.dart';
import 'package:mennyiment/menti_xp_store.dart';

import '../tool/menti_home_review.dart' as review;
import 'menti_home_review_test.dart' show clubTap;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    '3.3 reads real #50 data after replacement and does not write on open',
    (t) async {
      final p = await SharedPreferences.getInstance();
      await p.reload();
      final before = {for (final k in p.getKeys()) k: p.get(k)};
      expect(
        (jsonDecode(
          p.getString('mennyiment_drinks_v1')!,
        ) as List).single['priceFt'],
        0,
      );
      expect(p.getStringList('mennyiment_favorites_v1'), hasLength(1));
      expect((await MentiXpStore.load()).xp, 10);
      expect(MentiClubRecord.decode(p.get(MentiClubStore.normalKey)).best, 5);
      await review.main();
      await t.pumpAndSettle();
      expect(find.byType(HomePage), findsOneWidget);
      await clubTap(t, 'home-primary-log');
      expect(find.byIcon(Icons.star), findsOneWidget);
      await t.binding.handlePopRoute();
      await t.pumpAndSettle();
      await clubTap(t, 'home-fitness');
      await t.tap(find.byType(BackButton));
      await t.pumpAndSettle();
      await p.reload();
      expect({for (final k in p.getKeys()) k: p.get(k)}, before);
      // ignore: avoid_print
      print(
        'ANDROID33_UPGRADE_READ passed: all persisted values exactly equal after app replacement/relaunch',
      );
    },
  );
}
