// Isolated rendering harness. Not routed from the application or shipped build.
import 'package:flutter/material.dart';

import 'dart:js_interop';

import 'package:mennyiment/l10n/generated/app_localizations.dart';
import 'package:mennyiment/menti_design.dart';
import 'package:mennyiment/menti_identity/menti_identity.dart';
import 'package:mennyiment/menti_identity/menti_avatar_renderer.dart';

@JS('window.addEventListener')
external void listenPreview(String event, JSFunction listener);
@JS('window.location.href')
external JSString get previewLocation;

void main() {
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
      builder: (context, query, _) => MaterialApp(
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
      ),
    ),
  );
}
