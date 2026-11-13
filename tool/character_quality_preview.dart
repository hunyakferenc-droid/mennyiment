// Isolated rendering harness. Not routed from the application or shipped build.
import 'package:flutter/material.dart';

import 'dart:js_interop';
import 'dart:convert';

import 'package:mennyiment/l10n/generated/app_localizations.dart';
import 'package:mennyiment/menti_design.dart';
import 'package:mennyiment/menti_identity/menti_identity.dart';
import 'package:mennyiment/menti_identity/menti_avatar_renderer.dart';
import 'package:mennyiment/menti_identity/menti_head_geometry.dart';
import 'package:mennyiment/menti_identity/menti_reference_rig.dart';

@JS('window.addEventListener')
external void listenPreview(String event, JSFunction listener);
@JS('window.location.href')
external JSString get previewLocation;

@JS('window.mentiGuardSamples')
external set guardSamples(JSString value);

void main() {
  final keys = {
    for (final r in MentiReferenceRig.all) '${r.family}/${r.age}': GlobalKey(),
  };
  void publishGuardRegions() {
    final result = <Map<String, Object>>[];
    for (final r in MentiReferenceRig.all) {
      final key = '${r.family}/${r.age}';
      final box = keys[key]!.currentContext?.findRenderObject() as RenderBox?;
      if (box == null || !box.hasSize) return;
      final origin = box.localToGlobal(Offset.zero),
          scale = box.size.width / 320;
      final g = MentiHeadGeometry(
        r,
        clean: true,
        hair: '${r.family}-braid',
        hairVisible: true,
      );
      for (final rect in [g.leftEye, g.rightEye, g.mouth]) {
        final sample = Rect.fromLTRB(
          origin.dx + rect.left * scale,
          origin.dy + rect.top * scale,
          origin.dx + rect.right * scale,
          origin.dy + rect.bottom * scale,
        ).deflate(2);
        result.add({
          'identity': key,
          'rect': [
            sample.left.ceil(),
            sample.top.ceil(),
            sample.right.floor(),
            sample.bottom.floor(),
          ],
        });
      }
    }
    guardSamples = jsonEncode(result).toJS;
  }

  final parameters = ValueNotifier(Uri.base.queryParameters);
  listenPreview(
    'menti-preview-config',
    ((JSAny? event) {
      parameters.value = Uri.parse(previewLocation.toDart).queryParameters;
    }).toJS,
  );
  runApp(
    ValueListenableBuilder<Map<String, String>>(
      valueListenable: parameters,
      builder: (context, query, _) {
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => publishGuardRegions(),
        );
        return MaterialApp(
          theme: MentiDesign.theme,
          locale: const Locale('en'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: Scaffold(
            body: SingleChildScrollView(
              child: Column(
                children: [
                  for (final family in ['boy', 'girl', 'neutral'])
                    Row(
                      children: [
                        for (final age in ['young', 'adult', 'veteran'])
                          Expanded(
                            child: Column(
                              children: [
                                Text('$family/$age'),
                                MentiAvatarRenderer(
                                  key: keys['$family/$age'],
                                  size: 224,
                                  reaction: query['reaction'],
                                  profile: MentiIdentityProfile(
                                    name: '$family/$age',
                                    visual: MentiVisualProfile({
                                      'family': family,
                                      'age': age,
                                      'hair':
                                          '$family-${query['hair'] ?? 'crop'}',
                                      'hairVisible':
                                          query['hairVisible'] != 'false',
                                      ...Map.of(query)
                                        ..remove('reaction')
                                        ..remove('hair')
                                        ..remove('hairVisible'),
                                    }),
                                  ),
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
        );
      },
    ),
  );
}
