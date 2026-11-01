import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mennyiment/app_language.dart';
import 'package:mennyiment/l10n/generated/app_localizations.dart';
import 'package:mennyiment/menti_identity/menti_identity.dart';
import 'package:mennyiment/menti_identity/menti_avatar_renderer.dart';
import 'package:mennyiment/menti_identity/menti_identity_controller.dart';
import 'package:mennyiment/menti_identity/menti_identity_store.dart';
import 'package:mennyiment/menti_identity/menti_studio_page.dart';
import 'package:mennyiment/menti_identity/menti_visual_catalog.dart';

void main() {
  for (final locale in ['hu', 'en']) {
    for (final width in [320.0, 360.0, 390.0, 430.0]) {
      for (final scale in [1.0, 2.0]) {
        testWidgets(
          '2.2.1 $locale ${width}px ${scale}x persistent save, discard and back protection',
          (tester) async {
            tester.view.physicalSize = Size(width, 740);
            tester.view.devicePixelRatio = 1;
            addTearDown(tester.view.resetPhysicalSize);
            addTearDown(tester.view.resetViewInsets);
            addTearDown(tester.view.resetDevicePixelRatio);
            final profile = MentiIdentityProfile(
              name: 'Mira',
              visual: MentiVisualProfile({
                'family': 'girl',
                'hair': 'girl-waves',
                'headwear': 'none',
                'outfit': 'basic',
                'future-hair': 'keep',
              }),
              extras: {
                'future-face': {'preserve': true},
              },
            );
            final doc = MentiIdentityDocument(
              profile: profile,
              presets: [
                MentiPreset(
                  id: 'saved-one',
                  name: 'Favorite',
                  profile: profile,
                  favorite: true,
                ),
              ],
              extras: {
                'future-document': [1, 2, 3],
              },
            );
            const xp = '{"xp":150,"days":[],"completed":[],"future":true}';
            const journal =
                '[{"name":"Keep","ml":200,"percent":0,"time":"2026-10-25T12:00:00","future":true}]';
            SharedPreferences.setMockInitialValues({
              MentiIdentityStore.key: doc.encode(),
              'mennyiment_menti_xp_v2': xp,
              'mennyiment_drinks_v1': journal,
            });
            final c = MentiIdentityController();
            addTearDown(c.dispose);
            await c.load();
            await tester.pumpWidget(
              MaterialApp(
                locale: Locale(locale),
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
                builder: (context, child) => MediaQuery(
                  data: MediaQuery.of(context).copyWith(
                    textScaler: TextScaler.linear(scale),
                    disableAnimations: true,
                  ),
                  child: child!,
                ),
                home: Builder(
                  builder: (context) => Scaffold(
                    body: TextButton(
                      child: const Text('Open'),
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => MentiStudioPage(controller: c),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
            await tester.tap(find.text('Open'));
            await tester.pumpAndSettle();
            c.choose(MentiVisualCatalog.resolve('eyes', 'relaxed'));
            await tester.pumpAndSettle();
            await tester.tap(
              find.byKey(const ValueKey('studio-enlarge-preview')),
            );
            await tester.pumpAndSettle();
            final enlarged = tester.widget<MentiAvatarRenderer>(
              find.byKey(const ValueKey('studio-large-preview')),
            );
            expect(enlarged.profile.toJson(), c.draft.profile.toJson());
            final close = appStrings(tester.element(find.byType(Dialog)))
                .avatarClosePreview;
            await tester.tap(find.byTooltip(close));
            await tester.pumpAndSettle();
            expect(c.dirty, isTrue);
            // Naming remains usable with the Android-sized keyboard inset.
            await tester.tap(find.widgetWithText(TextButton, 'Mira'));
            await tester.pumpAndSettle();
            tester.view.viewInsets = const FakeViewPadding(bottom: 260);
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
            expect(find.byType(TextField), findsOneWidget);
            final dialogStrings = appStrings(
              tester.element(find.byType(AlertDialog)),
            );
            final cancel = find.descendant(
              of: find.byType(AlertDialog),
              matching: find.widgetWithText(
                TextButton,
                dialogStrings.avatarCancel,
              ),
            );
            await tester.ensureVisible(cancel);
            await tester.tap(cancel);
            await tester.pumpAndSettle();
            tester.view.resetViewInsets();
            await tester.pumpAndSettle();
            expect(
              find.byKey(const ValueKey('studio-save')).hitTestable(),
              findsOneWidget,
            );
            expect(
              find.byKey(const ValueKey('studio-revert')).hitTestable(),
              findsOneWidget,
            );
            expect(
              c.profile.toJson(),
              profile.toJson(),
              reason: 'Preview is not the saved state',
            );
            await tester.tap(
              find.byKey(const ValueKey('studio-preview-toggle')),
            );
            await tester.pumpAndSettle();
            expect(
              find.byKey(const ValueKey('studio-live-preview')),
              findsNothing,
            );
            await tester.tap(find.byType(BackButton));
            await tester.pumpAndSettle();
            final s = appStrings(tester.element(find.byType(MentiStudioPage)));
            expect(
              find.descendant(
                of: find.byType(AlertDialog),
                matching: find.text(s.avatarUnsaved),
              ),
              findsOneWidget,
            );
            await tester.tap(find.widgetWithText(TextButton, s.avatarCancel));
            await tester.pumpAndSettle();
            expect(c.dirty, isTrue);
            await tester.tap(find.byKey(const ValueKey('studio-revert')));
            await tester.pumpAndSettle();
            expect(c.draft.toJson(), doc.toJson());
            c.rename('Mira 2');
            c.choose(MentiVisualCatalog.resolve('eyes', 'wide'));
            await tester.pumpAndSettle();
            await tester.tap(find.byKey(const ValueKey('studio-save')));
            await tester.pumpAndSettle();
            expect(c.profile.name, 'Mira 2');
            expect(c.dirty, isFalse);
            final prefs = await SharedPreferences.getInstance();
            expect(prefs.getString('mennyiment_menti_xp_v2'), xp);
            expect(prefs.getString('mennyiment_drinks_v1'), journal);
            final saved = MentiIdentityDocument.decode(
              prefs.getString(MentiIdentityStore.key),
            );
            expect(saved.profile.toJson()['future-face'], {'preserve': true});
            expect(saved.profile.visual.toJson()['future-hair'], 'keep');
            expect(saved.presets.single.favorite, isTrue);
            expect(saved.toJson()['future-document'], [1, 2, 3]);
            expect(
              jsonDecode(prefs.getString(MentiIdentityStore.key)!),
              isNotNull,
            );
            expect(tester.takeException(), isNull);
            await tester.pumpWidget(const SizedBox.shrink());
            await tester.pump();
          },
        );
      }
    }
  }
}
