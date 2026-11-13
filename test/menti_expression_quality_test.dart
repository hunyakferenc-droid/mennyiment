import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mennyiment/menti_identity/menti_identity.dart';
import 'package:mennyiment/menti_identity/menti_premium_renderer.dart';
import 'package:mennyiment/menti_identity/menti_reference_rig.dart';

void main() {
  for (final family in ['boy', 'girl', 'neutral']) {
    for (final age in ['young', 'adult', 'veteran']) {
      testWidgets(
        '$family/$age reactions reach the real face without rewriting the personal selection',
        (t) async {
          final profile = MentiIdentityProfile(
            visual: MentiVisualProfile({
              'family': family,
              'age': age,
              'hair': '$family-crop',
              'face': 'determined',
              'eyes': 'sharp',
              'future': {'keep': true},
            }),
          );
          final before = jsonEncode(profile.toJson());
          for (final state in [
            'proud',
            'focused',
            'calming',
            'celebrating',
            'sleepy',
            null,
            'future-reaction',
          ]) {
            await t.pumpWidget(
              MaterialApp(
                home: SizedBox(
                  width: 160,
                  height: 200,
                  child: MentiPremiumComposition(
                    profile: profile,
                    reaction: state,
                  ),
                ),
              ),
            );
            await t.pumpAndSettle();
            final plate = t
                .widgetList<MentiReferencePlate>(
                  find.byType(MentiReferencePlate),
                )
                .first;
            if (state == 'proud' || state == 'celebrating') {
              expect(plate.eyeStyle, 'joyful');
              expect(plate.faceStyle, 'cheerful');
            } else if (state == 'focused') {
              expect(plate.eyeStyle, 'attentive');
              expect(plate.faceStyle, 'confident');
            } else if (state == 'calming' || state == 'sleepy') {
              expect(plate.eyeStyle, 'supportive');
              expect(plate.faceStyle, 'calm');
            } else {
              expect(plate.eyeStyle, 'sharp');
              expect(plate.faceStyle, 'determined');
            }
            expect(jsonEncode(profile.toJson()), before);
            expect(t.takeException(), isNull);
          }
          await t.pumpWidget(const SizedBox.shrink());
        },
      );
    }
  }
}
