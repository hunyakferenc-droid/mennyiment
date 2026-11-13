import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mennyiment/l10n/generated/app_localizations.dart';
import 'package:mennyiment/menti_identity/menti_identity.dart';
import 'package:mennyiment/menti_identity/menti_identity_store.dart';
import 'package:mennyiment/menti_identity/menti_identity_controller.dart';
import 'package:mennyiment/menti_identity/menti_visual_catalog.dart';
import 'package:mennyiment/menti_identity/menti_avatar_renderer.dart';
import 'package:mennyiment/menti_identity/menti_studio_page.dart';

void main() {
  for (final locale in ['hu', 'en']) {
    testWidgets(
      '$locale: reaction cards, draft, zoom and saved reload use the same selected expression',
      (t) async {
        t.view.physicalSize = const Size(390, 900);
        t.view.devicePixelRatio = 1;
        addTearDown(t.view.resetPhysicalSize);
        addTearDown(t.view.resetDevicePixelRatio);
        final raw = MentiIdentityDocument(
          profile: MentiIdentityProfile(
            visual: MentiVisualProfile({
              'family': 'girl',
              'age': 'adult',
              'face': 'calm',
              'eyes': 'sharp',
              'future': 'keep',
            }),
          ),
        ).encode();
        SharedPreferences.setMockInitialValues({MentiIdentityStore.key: raw});
        final c = MentiIdentityController();
        await c.load();
        await t.pumpWidget(
          MaterialApp(
            locale: Locale(locale),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: MentiStudioPage(controller: c),
          ),
        );
        await t.pumpAndSettle();
        MentiAvatarRenderer preview() =>
            t.widget(find.byKey(const ValueKey('studio-live-preview')));
        expect(preview().reaction, isNull);
        await t.ensureVisible(find.byKey(const ValueKey('studio-tab-4')));
        await t.pumpAndSettle();
        await t.tap(find.byKey(const ValueKey('studio-tab-4')));
        await t.pumpAndSettle();
        c.choose(
          MentiVisualCatalog.forField('reaction')
              .firstWhere((o) => o.id == 'focused'),
        );
        await t.pumpAndSettle();
        expect(preview().reaction, 'focused');
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getString(MentiIdentityStore.key), raw);
        await t.tap(find.byKey(const ValueKey('studio-enlarge-preview')));
        await t.pumpAndSettle();
        final zoom = t.widget<MentiAvatarRenderer>(
          find.byKey(const ValueKey('studio-large-preview')),
        );
        expect(zoom.profile.toJson(), preview().profile.toJson());
        expect(zoom.reaction, 'focused');
        final s = lookupAppLocalizations(Locale(locale));
        await t.tap(find.byTooltip(s.avatarClosePreview));
        await t.pumpAndSettle();
        await t.ensureVisible(find.byKey(const ValueKey('studio-tab-1')));
        await t.pumpAndSettle();
        await t.tap(find.byKey(const ValueKey('studio-tab-1')));
        await t.pumpAndSettle();
        expect(preview().reaction, isNull);
        expect(preview().profile.visual.value('face'), 'calm');
        expect(prefs.getString(MentiIdentityStore.key), raw);
        expect(await c.save(), isTrue);
        final reloaded = MentiIdentityController();
        await reloaded.load();
        expect(reloaded.profile.reaction.style, 'focused');
        expect(reloaded.profile.visual.toJson()['future'], 'keep');
        expect(t.takeException(), isNull);
        await t.pumpWidget(const SizedBox.shrink());
        c.dispose();
        reloaded.dispose();
      },
    );
  }
}
