// Run with flutter test tool/render_character_quality.dart --concurrency=1.
// Exporting real Flutter canvases; no pixel editing or golden replacement.
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mennyiment/l10n/generated/app_localizations.dart';
import 'package:mennyiment/menti_identity/menti_identity.dart';
import 'package:mennyiment/menti_identity/menti_visual_catalog.dart';
import 'package:mennyiment/menti_identity/menti_avatar_renderer.dart';
import 'package:mennyiment/menti_identity/menti_premium_renderer.dart';

void main() {
  testWidgets('export configuration-labelled nine-character contact sheets', (
    t,
  ) async {
    final output = Directory(
      Platform.environment['MENTI_RENDER_DIR'] ??
          '.agent-workspace/character-before',
    )..createSync(recursive: true);
    await t.binding.setSurfaceSize(const Size(720, 960));
    addTearDown(() => t.binding.setSurfaceSize(null));
    final cases = <Map<String, dynamic>>[];
    final fields = MentiVisualCatalog.options
        .map((o) => o.field)
        .toSet()
        .toList();
    final inventory = {
      for (final f in fields)
        f: MentiVisualCatalog.options
            .where((o) => o.field == f)
            .map((o) => o.id)
            .toList(),
    };
    final configurations = <String, Map<String, String>>{'baseline': {}};
    for (final f in fields.where(
      (f) => !['family', 'age', 'hair'].contains(f),
    )) {
      for (final id in inventory[f]!) {
        configurations['$f-$id'] = {f: id};
      }
    }
    for (final hair in ['crop', 'waves', 'curls', 'braid', 'bob', 'crest']) {
      for (final hat in inventory['headwear']!) {
        configurations['hair-$hair--headwear-$hat'] = {
          'hair': hair,
          'headwear': hat,
        };
      }
    }
    for (final outfit in inventory['outfit']!) {
      for (final neck in inventory['neck']!) {
        configurations['outfit-$outfit--neck-$neck'] = {
          'outfit': outfit,
          'neck': neck,
        };
      }
    }
    for (final entry in configurations.entries.where(
      (e) =>
          RegExp(Platform.environment['MENTI_CASE_FILTER'] ?? '.*')
              .hasMatch(e.key),
    )) {
      final profiles = <MentiIdentityProfile>[];
      for (final family in inventory['family']!) {
        for (final age in inventory['age']!) {
          final options = <String, String>{
            'family': family,
            'age': age,
            'hair': '$family-crop',
            ...entry.value,
          };
          if (entry.value.containsKey('hair')) {
            options['hair'] = '$family-${entry.value['hair']}';
          }
          final reaction = options.remove('reaction');
          profiles.add(
            MentiIdentityProfile(
              name: '$family/$age',
              visual: MentiVisualProfile(options),
            ),
          );
          cases.add({
            'sheet': '${entry.key}.png',
            'family': family,
            'age': age,
            'visual': options,
            'reaction': reaction,
          });
        }
      }
      await t.pumpWidget(const SizedBox.shrink());
      await t.pumpAndSettle();
      await t.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            backgroundColor: const Color(0xFF17101F),
            body: RepaintBoundary(
              key: const ValueKey('sheet'),
              child: Column(
                children: [
                  for (var row = 0; row < 3; row++)
                    Row(
                      children: [
                        for (var col = 0; col < 3; col++)
                          SizedBox(
                            width: 240,
                            height: 320,
                            child: Column(
                              children: [
                                MentiAvatarRenderer(
                                  profile: profiles[row * 3 + col],
                                  size: 224,
                                  reaction: entry.value['reaction'],
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ),
      );
      final ctx = t.element(find.byKey(const ValueKey('sheet')));
      await t.runAsync(() async {
        for (final asset in MentiPremiumComposition.assets) {
          await precacheImage(AssetImage(asset), ctx);
        }
      });
      await t.pumpAndSettle();
      expect(t.takeException(), isNull, reason: entry.key);
      final boundary = t.renderObject<RenderRepaintBoundary>(
        find.byKey(const ValueKey('sheet')),
      );
      await t.runAsync(() async {
        final image = await boundary.toImage();
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        File('${output.path}/${entry.key}.png')
            .writeAsBytesSync(bytes!.buffer.asUint8List());
        image.dispose();
      });
    }
    File('${output.path}/inventory.json').writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert({
        'inventory': inventory,
        'cases': cases,
        'sheets': configurations.length,
        'scope': 'All single options across nine identities, hair/headwear and outfit/neck pairs. Other pair combinations are not yet covered.',
      }),
    );
    await t.pumpWidget(const SizedBox.shrink());
  }, timeout: const Timeout(Duration(minutes: 20)));
}
