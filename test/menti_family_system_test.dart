import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mennyiment/menti_identity/menti_avatar_renderer.dart';
import 'package:mennyiment/menti_identity/menti_family_layout.dart';
import 'package:mennyiment/menti_identity/menti_identity.dart';
import 'package:mennyiment/menti_identity/menti_visual_catalog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final inventory = jsonDecode(File('test/fixtures/menti_family_inventory.json').readAsStringSync()) as Map;
  final measured = (jsonDecode(File('test/fixtures/menti_family_bounds.json').readAsStringSync()) as List).cast<Map>();
  test('nine independent cores have different normalized silhouettes, not recolored copies', () {
    expect((inventory['identities'] as Map).length, 9);
    expect((inventory['silhouettePairs'] as List).length, 36);
    for (final pair in (inventory['silhouettePairs'] as List).cast<Map>()) {
      expect(pair['normalizedSilhouetteIoU'], lessThan(.98), reason: '${pair['a']} vs ${pair['b']}');
    }
    final checksums = <Object>{};
    for (final entry in (inventory['identities'] as Map).entries) {
      final item = entry.value as Map;
      final bytes = File('${MentiVisualCatalog.root}${item['asset']}').readAsBytesSync();
      var crc = 0xffffffff;
      for (final byte in bytes) {
        crc ^= byte;
        for (var i=0;i<8;i++) { crc = (crc >> 1) ^ ((crc & 1) == 1 ? 0xedb88320 : 0); }
      }
      expect((crc ^ 0xffffffff) & 0xffffffff, item['crc32'], reason: entry.key as String);
      expect(bytes.length, item['bytes']);
      checksums.add(item['crc32']!);
    }
    expect(checksums.length, 9);
  });
  test('uncovered and classic proof matrices match the real composition paths', () {
    final cases = (jsonDecode(File('test/fixtures/menti_family_render_cases.json').readAsStringSync()) as List).cast<Map>();
    expect(cases.length, 18);
    for (final item in cases) {
      final p = MentiIdentityProfile(visual: MentiVisualProfile(Map<String,dynamic>.from(item['visual'] as Map)));
      expect(MentiAvatarRenderer.layers(p), item['layers'], reason: item['name'] as String);
    }
  });
  for (final key in MentiFamilyLayout.fits.keys) {
    test('$key: all measured compatible option drawings fit the artboard', () {
      final layout = MentiFamilyLayout(key);
      final rows = measured.where((row) => row['identity'] == key).toList();
      expect(rows.length, greaterThan(90));
      for (final row in rows) {
        final source = (row['source'] as List).cast<num>();
        final actual = layout.forField(row['field'] as String).mapRect(Rect.fromLTWH(
          source[0].toDouble(),source[1].toDouble(),source[2].toDouble(),source[3].toDouble()));
        final expected = (row['fitted'] as List).cast<num>();
        for (final pair in [(actual.left,expected[0]),(actual.top,expected[1]),
          (actual.width,expected[2]),(actual.height,expected[3])]) {
          expect(pair.$1, closeTo(pair.$2, .001), reason: '${row['field']}:${row['id']}');
        }
        expect(actual.left, greaterThanOrEqualTo(-.05));
        expect(actual.top, greaterThanOrEqualTo(-.05));
        expect(actual.right, lessThanOrEqualTo(320.05));
        expect(actual.bottom, lessThanOrEqualTo(400.05));
      }
    });
  }
  test('all 115 previews use the current family, age and immutable draft data', () {
    final base = MentiIdentityProfile(name:'Test',visual:MentiVisualProfile({
      'family':'girl','age':'veteran','hair':'girl-braid','future':{'keep':true}}));
    final before = jsonEncode(base.toJson());
    for (final option in MentiVisualCatalog.options) {
      final candidate = MentiPreviewRenderer.previewProfile(base,option);
      if (option.field!='family') expect(candidate.visual.value('family'),'girl');
      if (option.field!='age') expect(candidate.visual.value('age'),'veteran');
      expect(candidate.visual.toJson()['future'],{'keep':true});
      expect(MentiFamilyLayout.of(candidate).core, contains(candidate.visual.value('family')));
      final crop = MentiPreviewRenderer.cropFor(option,profile:candidate);
      expect(crop.width,greaterThan(0)); expect(crop.height,greaterThan(0));
      expect(crop.left,greaterThanOrEqualTo(0)); expect(crop.right,lessThanOrEqualTo(320));
    }
    expect(jsonEncode(base.toJson()),before);
  });
  test('unknown future family and age render a safe core without rewriting IDs', () {
    final p = MentiIdentityProfile(visual:MentiVisualProfile({'family':'future-family','age':'future-age'}));
    expect(MentiFamilyLayout.of(p).core,endsWith('identities/boy-young.png'));
    expect(p.visual.value('family'),'future-family'); expect(p.visual.value('age'),'future-age');
  });
  test('every explicit accessory slot receives the same registration used by its owner', () {
    for (final layout in MentiFamilyLayout.fits.keys.map(MentiFamilyLayout.new)) {
      for (final field in ['glasses','neck','held','detail','back']) {
        for (final o in MentiVisualCatalog.forField(field).where((o)=>o.id!='none')) {
          final fit = layout.forPath(MentiVisualCatalog.root+o.asset);
          final expected = layout.forField(field);
          expect(fit.map(const Offset(160,200)),expected.map(const Offset(160,200)));
        }
      }
    }
  });
}
