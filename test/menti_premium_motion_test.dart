import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mennyiment/menti_identity/menti_identity.dart';
import 'package:mennyiment/menti_identity/menti_premium_motion.dart';
import 'package:mennyiment/menti_identity/menti_premium_renderer.dart';
import 'package:mennyiment/menti_identity/menti_reference_rig.dart';

void main() {
  testWidgets(
    'profile replacement and neutral reactions cancel stale expressions without preference writes',
    (t) async {
      var profile = MentiIdentityProfile(
        visual: MentiVisualProfile({
          'family': 'boy',
          'face': 'calm',
          'future': 'keep',
        }),
      );
      String? reaction = 'funny';
      Widget host() => MaterialApp(
        home: MentiPremiumMotion(profile: profile, reaction: reaction),
      );
      MentiPremiumComposition frame() =>
          t.widget(find.byType(MentiPremiumComposition));
      await t.pumpWidget(host());
      expect(frame().wink, isTrue);
      profile = profile.copyWith(
        visual: profile.visual.withValues({'family': 'girl', 'face': 'sleepy'}),
      );
      await t.pumpWidget(host());
      expect(frame().wink, isFalse);
      expect(frame().smile, isFalse);
      expect(frame().profile.visual.value('face'), 'sleepy');
      reaction = 'proud';
      await t.pumpWidget(host());
      expect(frame().smile, isTrue);
      reaction = null;
      await t.pumpWidget(host());
      expect(frame().smile, isFalse);
      expect(profile.visual.toJson()['future'], 'keep');
      await t.pump(const Duration(seconds: 7));
      expect(frame().blink, isTrue);
      await t.pumpWidget(const SizedBox.shrink());
    },
  );
  testWidgets(
    'blink, wink and positive smiles are finite, preserve identity and stop with accessibility or background',
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
      reaction = 'celebrating';
      await tester.pumpWidget(host());
      expect(current().smile, true);
      await tester.pump(const Duration(milliseconds: 950));
      expect(current().smile, false);
      reaction = 'proud';
      await tester.pumpWidget(host());
      expect(current().smile, true);
      reaction = 'focused';
      await tester.pumpWidget(host());
      expect(current().smile, false);
      expect(
        tester
            .widgetList<MentiReferencePlate>(find.byType(MentiReferencePlate))
            .first
            .eyeStyle,
        'attentive',
      );
      reduced = true;
      await tester.pumpWidget(host());
      await tester.pump(const Duration(seconds: 20));
      expect(current().blink, false);
      expect(current().wink, false);
      expect(
        tester
            .widgetList<MentiReferencePlate>(find.byType(MentiReferencePlate))
            .first
            .eyeStyle,
        'attentive',
      );
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
      await tester.pump(const Duration(milliseconds: 150));
      expect(
        tester
            .widgetList<MentiReferencePlate>(find.byType(MentiReferencePlate))
            .first
            .eyeStyle,
        'attentive',
      );
      expect(jsonEncode(profile.toJson()), before);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    },
  );
}
