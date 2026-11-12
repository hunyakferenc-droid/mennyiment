import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mennyiment/data_backup.dart';
import 'package:mennyiment/data_restore.dart';
import 'package:mennyiment/menti_access.dart';
import 'package:mennyiment/menti_identity/menti_identity.dart';
import 'package:mennyiment/menti_identity/menti_identity_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  Future<String> backup(Map<String, Object> values) async {
    SharedPreferences.setMockInitialValues(values);
    return (await BackupExporter().capture()).json;
  }

  test('older Studio backup retains permanent and future unlocks, without awarding XP', () async {
    final incoming = MentiIdentityDocument(
      profile: MentiIdentityProfile(name: 'Restored'),
      unlocks: MentiUnlockState(unlocked: {'outfit:sport'}),
      extras: {'future': 'backup-extension'},
    );
    final text = await backup({MentiIdentityStore.key: incoming.encode()});
    final current = MentiIdentityDocument(
      profile: MentiIdentityProfile(name: 'Current'),
      unlocks: MentiUnlockState(
        unlocked: {'outfit:legendary', 'future:reward'},
        seen: {'outfit:legendary'},
        extras: {'future-unlock-field': 42},
      ),
    );
    const xp = '{"xp":450,"days":[],"completed":[]}';
    const journal = '[]';
    SharedPreferences.setMockInitialValues({
      MentiIdentityStore.key: current.encode(),
      'mennyiment_menti_xp_v2': xp,
      'mennyiment_drinks_v1': journal,
    });
    final restorer = BackupRestorer();
    final plan = await restorer.prepare(text);
    final p = await SharedPreferences.getInstance();
    expect(p.get(MentiIdentityStore.key), current.encode());
    await restorer.restore(plan, confirmed: true);
    final actual = MentiIdentityDocument.decode(p.get(MentiIdentityStore.key));
    expect(actual.profile.name, 'Restored');
    expect(actual.unlocks.unlocked, {
      'outfit:sport',
      'outfit:legendary',
      'future:reward',
    });
    expect(actual.unlocks.seen, {'outfit:legendary'});
    expect(actual.unlocks.toJson()['future-unlock-field'], 42);
    expect(actual.toJson()['future'], 'backup-extension');
    expect(p.get('mennyiment_menti_xp_v2'), xp);
    expect(p.get('mennyiment_drinks_v1'), journal);
    final reloaded = MentiIdentityStore();
    await reloaded.load();
    expect(reloaded.document.toJson(), actual.toJson());
  });

  for (final raw in <Object>[
    '{broken',
    42,
    '{"version":2,"profile":{}}',
    '{"version":1,"version":1,"profile":{}}',
  ]) {
    test(
      'invalid incoming identity $raw is rejected without touching local data',
      () async {
        final text = await backup({MentiIdentityStore.key: raw});
        final valid = MentiIdentityDocument(profile: MentiIdentityProfile())
            .encode();
        SharedPreferences.setMockInitialValues({MentiIdentityStore.key: valid});
        await expectLater(
          BackupRestorer().prepare(text),
          throwsFormatException,
        );
        expect(
          (await SharedPreferences.getInstance()).get(MentiIdentityStore.key),
          valid,
        );
      },
    );
    test(
      'unreadable local identity $raw changes only after an explicit recovery confirmation',
      () async {
        final valid = MentiIdentityDocument(profile: MentiIdentityProfile())
            .encode();
        final text = await backup({MentiIdentityStore.key: valid});
        SharedPreferences.setMockInitialValues({MentiIdentityStore.key: raw});
        final restorer = BackupRestorer();
        final plan = await restorer.prepare(text);
        expect(plan.profileRecovery, true);
        expect(
          (await SharedPreferences.getInstance()).get(MentiIdentityStore.key),
          raw,
        );
        await expectLater(
          restorer.restore(plan, confirmed: false),
          throwsStateError,
        );
        expect(
          (await SharedPreferences.getInstance()).get(MentiIdentityStore.key),
          raw,
        );
        await restorer.restore(plan, confirmed: true);
        expect(
          (await SharedPreferences.getInstance()).get(MentiIdentityStore.key),
          valid,
        );
      },
    );
  }

  test(
    'adult backup cannot lift a locally declared minor restriction',
    () async {
      final text = await backup({
        MentiAccessSettings.key: jsonEncode({
          'version': 1,
          'audience': 'adult',
          'complete': true,
        }),
      });
      final minor = jsonEncode({
        'version': 1,
        'audience': 'minor',
        'complete': true,
        'future': 'keep',
      });
      SharedPreferences.setMockInitialValues({MentiAccessSettings.key: minor});
      final restorer = BackupRestorer();
      final plan = await restorer.prepare(text);
      expect(plan.unchanged, 1);
      await restorer.restore(plan, confirmed: true);
      final settings = MentiAccessSettings();
      await settings.load();
      expect(settings.adult, false);
      expect(settings.complete, true);
      expect(
        (await SharedPreferences.getInstance()).get(MentiAccessSettings.key),
        minor,
      );
    },
  );
  test(
    'ambiguous age declaration is rejected and remains restricted',
    () async {
      const raw =
          '{"version":1,"audience":"minor","audience":"adult","complete":true}';
      final text = await backup({MentiAccessSettings.key: raw});
      SharedPreferences.setMockInitialValues({MentiAccessSettings.key: raw});
      final settings = MentiAccessSettings();
      await settings.load();
      expect(settings.adult, false);
      expect(settings.writable, false);
      await expectLater(BackupRestorer().prepare(text), throwsFormatException);
      expect(
        (await SharedPreferences.getInstance()).get(MentiAccessSettings.key),
        raw,
      );
    },
  );
}
