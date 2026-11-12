import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mennyiment/menti_identity/menti_avatar_renderer.dart';
import 'package:mennyiment/menti_identity/menti_identity.dart';
import 'package:mennyiment/menti_identity/menti_identity_controller.dart';
import 'package:mennyiment/menti_identity/menti_identity_store.dart';
import 'package:mennyiment/menti_identity/menti_visual_catalog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  for (final family in ['girl', 'boy', 'neutral']) {
    for (final age in ['young', 'adult', 'veteran']) {
      test(
        '$family/$age selected family and style cards retain custom hair, outfit and visibility',
        () async {
          final profile = MentiIdentityProfile(
            name: 'Saved Menti',
            visual: MentiVisualProfile({
              'family': family,
              'age': age,
              'style': 'classic',
              'hair': MentiVisualCatalog.forField(
                'hair',
                family: family,
              ).last.id,
              'hairVisible': false,
              'outfit': 'business',
              'neck': 'scarf',
              'glasses': 'round-glasses',
              'held': 'notebook',
              'future': 'keep',
            }),
          );
          final original = MentiIdentityDocument(profile: profile).encode();
          SharedPreferences.setMockInitialValues({
            MentiIdentityStore.key: original,
          });
          final controller = MentiIdentityController();
          addTearDown(controller.dispose);
          await controller.load();
          for (final field in ['family', 'style']) {
            final option = MentiVisualCatalog.resolve(
              field,
              profile.visual.value(field),
            );
            expect(
              MentiPreviewRenderer.previewProfile(profile, option).toJson(),
              profile.toJson(),
            );
            controller.choose(option);
            expect(controller.draft.profile.toJson(), profile.toJson());
            expect(controller.dirty, false);
            expect(
              (await SharedPreferences.getInstance()).get(
                MentiIdentityStore.key,
              ),
              original,
            );
          }
        },
      );
    }
  }
}
