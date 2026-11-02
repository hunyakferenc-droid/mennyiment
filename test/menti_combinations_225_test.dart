import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mennyiment/menti_identity/menti_accessory_rig.dart';
import 'package:mennyiment/menti_identity/menti_head_geometry.dart';
import 'package:mennyiment/menti_identity/menti_wardrobe_geometry.dart';
import 'package:mennyiment/menti_identity/menti_reference_rig.dart';
import 'package:mennyiment/menti_identity/menti_identity.dart';
import 'package:mennyiment/menti_identity/menti_premium_renderer.dart';

void main() {
  final fixture = jsonDecode(
    File('test/fixtures/menti_pairwise_225.json').readAsStringSync(),
  ) as Map;
  final rows = (fixture['rows'] as List).cast<Map>();
  test(
    'covering cases contain every pair, not just every individual option',
    () {
      final fields = fixture['fields'] as Map;
      final names = fields.keys.toList();
      var covered = 0;
      for (var i = 0; i < names.length; i++) {
        for (var j = i + 1; j < names.length; j++) {
          for (final a in fields[names[i]] as List) {
            for (final b in fields[names[j]] as List) {
              expect(
                rows.any((r) => r[names[i]] == a && r[names[j]] == b),
                isTrue,
                reason: '${names[i]}=$a / ${names[j]}=$b',
              );
              covered++;
            }
          }
        }
      }
      expect(covered, fixture['pairs']);
    },
  );
  test('future outfit identifiers use a safe graphic without rewriting profile data', () {
    final p = MentiVisualProfile({
      'family': 'girl',
      'outfit': 'future-cut',
      'future': 42,
    });
    final r = MentiReferenceRig.of('girl', 'adult');
    final w = MentiWardrobeGeometry(
      MentiHeadGeometry(r, clean: true, hair: r.hairId, hairVisible: true),
      p.value('outfit'),
    );
    expect(w.outfit, 'basic');
    expect(w.garment.width, greaterThan(0));
    expect(p.value('outfit'), 'future-cut');
    expect(p.toJson()['future'], 42);
  });
  testWidgets(
    'all nine rigs render every covering case with stable lenses, safe collars and grips',
    (t) async {
      await t.pumpWidget(const MaterialApp(home: Scaffold()));
      await t.runAsync(() async {
        for (final asset in MentiPremiumComposition.assets) {
          await precacheImage(
            AssetImage(asset),
            t.element(find.byType(Scaffold)),
          );
        }
      });
      for (final r in MentiReferenceRig.all) {
        for (final row in rows) {
          final v = Map<String, dynamic>.from(row)
            ..['family'] = r.family
            ..['age'] = r.age
            ..['hair'] = '${r.family}-${row['hair']}';
          final h = MentiHeadGeometry(
            r,
            clean: true,
            hair: v['hair'],
            hairVisible: v['hairVisible'],
          );
          final w = MentiWardrobeGeometry(h, v['outfit']);
          final a = MentiAccessoryRig(h, w);
          expect(
            (a.lens(false).center - h.leftEye.center).distance,
            lessThan(1e-8),
          );
          expect(
            (a.lens(true).center - h.rightEye.center).distance,
            lessThan(1e-8),
          );
          expect(a.collar.top, greaterThan(h.mouth.bottom));
          expect(a.glasses.left, greaterThan(0));
          expect(a.glasses.right, lessThan(320));
          if (v['held'] != 'none') {
            expect(
              w
                  .held(v['held'])
                  .contains(w.hand(v['held'] != 'notebook').center),
              isTrue,
            );
          }
          await t.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: SizedBox(
                  width: 100,
                  height: 125,
                  child: MentiPremiumComposition(
                    profile: MentiIdentityProfile(
                      visual: MentiVisualProfile(v),
                    ),
                  ),
                ),
              ),
            ),
          );
          await t.pump();
          expect(
            t.takeException(),
            isNull,
            reason: '${r.family}/${r.age} $row',
          );
        }
      }
      await t.pumpWidget(const SizedBox.shrink());
    },
  );
}
