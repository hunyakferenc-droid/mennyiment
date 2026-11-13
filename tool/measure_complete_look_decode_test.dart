// Run with: MENTI_DECODE_OUTPUT=/absolute/path.json flutter test tool/measure_complete_look_decode_test.dart
// Software decoder measurements, not a physical device benchmark.
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:mennyiment/menti_complete_looks.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('Measure actual full-look PNG reads and bounded RGBA decodes', () async {
    final rows = <Map<String, Object>>[];
    for (final look in CompleteLook.all) {
      for (final requested in [180, 360, 720, 1254]) {
        final watch = Stopwatch()..start();
        final bytes = await File(look.asset).readAsBytes();
        final readUs = watch.elapsedMicroseconds;
        final target = requested.clamp(1, look.sourceSize.width.toInt());
        final codec = await ui.instantiateImageCodec(
          bytes,
          targetWidth: target,
          allowUpscaling: false,
        );
        final frame = await codec.getNextFrame();
        final decodeUs = watch.elapsedMicroseconds - readUs;
        expect(frame.image.width, target);
        rows.add({
          'id': look.id,
          'sourceBytes': bytes.length,
          'requestedWidth': requested,
          'decodedWidth': frame.image.width,
          'decodedHeight': frame.image.height,
          'rgbaBytes': frame.image.width * frame.image.height * 4,
          'fileReadMicroseconds': readUs,
          'codecAndFrameMicroseconds': decodeUs,
        });
        frame.image.dispose();
        codec.dispose();
      }
    }
    final output = Platform.environment['MENTI_DECODE_OUTPUT'];
    if (output != null) {
      await File(output).writeAsString(
        '${jsonEncode({'sourceCommit': Platform.environment['MENTI_SOURCE_COMMIT'], 'environment': 'Linux Flutter test software decoder; one cold pass per width; no physical phone', 'rows': rows})}\n',
      );
    }
  });
}
