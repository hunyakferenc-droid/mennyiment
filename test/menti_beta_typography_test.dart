import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mennyiment/menti_design.dart';

void main() {
  for (final platform in [
    TargetPlatform.windows,
    TargetPlatform.android,
    TargetPlatform.linux,
  ]) {
    test('$platform uses bundled Roboto for readable offline text', () {
      debugDefaultTargetPlatformOverride = platform;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      final theme = MentiDesign.theme;
      expect(theme.textTheme.bodyMedium!.fontFamily, 'Roboto');
      expect(theme.textTheme.titleLarge!.fontFamily, 'Roboto');
      expect(
        theme.textTheme.bodyMedium!.fontFamilyFallback,
        contains('MentiEmoji'),
      );
    });
  }
}
