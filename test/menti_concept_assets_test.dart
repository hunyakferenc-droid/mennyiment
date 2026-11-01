import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

int _crc32(List<int> bytes) {
  var crc = 0xffffffff;
  for (final byte in bytes) {
    crc ^= byte;
    for (var bit = 0; bit < 8; bit++) {
      crc = (crc >> 1) ^ ((crc & 1) == 1 ? 0xedb88320 : 0);
    }
  }
  return (crc ^ 0xffffffff) & 0xffffffff;
}

int _uint32BigEndian(List<int> bytes, int offset) =>
    (bytes[offset] << 24) |
    (bytes[offset + 1] << 16) |
    (bytes[offset + 2] << 8) |
    bytes[offset + 3];

void main() {
  final inventory = jsonDecode(
    File('test/fixtures/menti_concept_assets.json').readAsStringSync(),
  ) as Map<String, dynamic>;
  final assets = (inventory['assets'] as List).cast<Map<String, dynamic>>();

  test('concept review contains three exact references, concepts and boards', () {
    expect(assets, hasLength(8));
    expect(
      assets.where((item) => (item['path'] as String).contains('/references/')),
      hasLength(3),
    );
    expect(
      assets.where((item) => (item['path'] as String).contains('/concepts/')),
      hasLength(3),
    );
  });

  test('concept review PNG bytes and dimensions match the approved fixture', () {
    for (final item in assets) {
      final path = item['path'] as String;
      final bytes = File(path).readAsBytesSync();
      expect(bytes, hasLength(item['bytes'] as int), reason: path);
      expect(_crc32(bytes), item['crc32'], reason: path);
      expect(
        bytes.take(8),
        [0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a],
        reason: path,
      );
      expect(_uint32BigEndian(bytes, 16), item['width'], reason: path);
      expect(_uint32BigEndian(bytes, 20), item['height'], reason: path);
    }
  });
}
