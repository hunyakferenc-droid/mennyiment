import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mennyiment/menti_animation_catalog.dart';
import 'package:mennyiment/menti_animation_controller.dart';

import 'menti_life_engine_test.dart' show clipJson;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  tearDown(() => messenger.setMockMessageHandler('flutter/assets', null));

  test('Actual asset verifier checks both byte length and SHA-256 before decoder use', () async {
    final bytes = Uint8List.fromList([1, 2, 3, 4]);
    messenger.setMockMessageHandler(
      'flutter/assets',
      (_) async => ByteData.sublistView(bytes),
    );
    final json = clipJson()
      ..['bytes'] = bytes.length
      ..['sha256'] = sha256.convert(bytes).toString();
    await verifyMentiAnimationAsset(MentiAnimationClip.fromJson(json));
    await expectLater(
      verifyMentiAnimationAsset(
        MentiAnimationClip.fromJson({...json, 'bytes': 5}),
      ),
      throwsStateError,
    );
    await expectLater(
      verifyMentiAnimationAsset(
        MentiAnimationClip.fromJson({...json, 'sha256': 'a' * 64}),
      ),
      throwsStateError,
    );
  });

  test(
    'Missing actual bundled asset fails before a video handle can be created',
    () async {
      messenger.setMockMessageHandler('flutter/assets', (_) async => null);
      await expectLater(
        verifyMentiAnimationAsset(MentiAnimationClip.fromJson(clipJson())),
        throwsA(isA<FlutterError>()),
      );
    },
  );
}
