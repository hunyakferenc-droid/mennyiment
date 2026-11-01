import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mennyiment/menti_identity/menti_identity.dart';
import 'package:mennyiment/menti_identity/menti_premium_motion.dart';
import 'package:mennyiment/menti_identity/menti_premium_renderer.dart';

void main() {
  testWidgets(
    'blink and wink are finite, preserve identity and stop with accessibility or background',
    (tester) async {
      final profile = MentiIdentityProfile(
        name: 'Stable',
        visual: MentiVisualProfile({
          'family': 'girl',
          'age': 'veteran',
          'future': 'keep',
        }),
      );
      final before = jsonEncode(profile.toJson());
      bool reduced = false, visible = true;
      String? reaction;
      Widget host() => MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: reduced),
          child: TickerMode(
            enabled: visible,
            child: MentiPremiumMotion(profile: profile, reaction: reaction),
          ),
        ),
      );
      MentiPremiumComposition current() =>
          tester.widget<MentiPremiumComposition>(
            find.byType(MentiPremiumComposition),
          );
      await tester.pumpWidget(host());
      await tester.pump(const Duration(seconds: 7));
      expect(current().blink, true);
      await tester.pump(const Duration(milliseconds: 150));
      expect(current().blink, false);
      reaction = 'funny';
      await tester.pumpWidget(host());
      expect(current().wink, true);
      await tester.pump(const Duration(milliseconds: 300));
      expect(current().wink, false);
      reduced = true;
      await tester.pumpWidget(host());
      await tester.pump(const Duration(seconds: 20));
      expect(current().blink, false);
      expect(current().wink, false);
      reduced = false;
      visible = false;
      await tester.pumpWidget(host());
      await tester.pump(const Duration(seconds: 20));
      expect(current().blink, false);
      visible = true;
      await tester.pumpWidget(host());
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump(const Duration(seconds: 20));
      expect(current().blink, false);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump(const Duration(seconds: 7));
      expect(current().blink, true);
      expect(jsonEncode(profile.toJson()), before);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    },
  );
}
