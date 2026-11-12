import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';
import 'package:mennyiment/app_language.dart';
import 'package:mennyiment/l10n/generated/app_localizations.dart';
import 'package:mennyiment/menti_identity/menti_identity_controller.dart';
import 'package:mennyiment/menti_identity/menti_identity_store.dart';
import 'package:mennyiment/menti_identity/menti_studio_page.dart';

class DelayedIdentityWrite extends InMemorySharedPreferencesStore {
  DelayedIdentityWrite(super.data) : super.withData();
  final gate = Completer<void>();
  int writes = 0;
  @override
  Future<bool> setValue(String type, String key, Object value) async {
    if (key == 'flutter.${MentiIdentityStore.key}') {
      writes++;
      await gate.future;
    }
    return super.setValue(type, key, value);
  }
}

void main() {
  Future<MentiIdentityController> open(
    WidgetTester tester, {
    DelayedIdentityWrite? backend,
  }) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({});
    if (backend != null) SharedPreferencesStorePlatform.instance = backend;
    final c = MentiIdentityController();
    addTearDown(c.dispose);
    await c.load();
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => MentiStudioPage(controller: c),
                ),
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    return c;
  }

  testWidgets(
    'rapid preview activation opens one dialog and one close returns to Studio',
    (tester) async {
      final c = await open(tester);
      final enlarge = tester
          .widget<IconButton>(
            find.byKey(const ValueKey('studio-enlarge-preview')),
          )
          .onPressed!;
      enlarge();
      enlarge();
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('studio-large-preview'), skipOffstage: false),
        findsOneWidget,
      );
      final s = appStrings(tester.element(find.byType(Dialog)));
      await tester.tap(find.byTooltip(s.avatarClosePreview));
      await tester.pumpAndSettle();
      expect(find.byType(Dialog, skipOffstage: false), findsNothing);
      expect(find.byType(MentiStudioPage), findsOneWidget);
      expect(c.dirty, false);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    },
  );

  testWidgets('rapid rename opens one input and preserves the saved identity', (
    tester,
  ) async {
    final c = await open(tester);
    final rename = tester
        .widget<TextButton>(find.widgetWithText(TextButton, 'Menti'))
        .onPressed!;
    rename();
    rename();
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog, skipOffstage: false), findsOneWidget);
    final s = appStrings(tester.element(find.byType(AlertDialog)));
    await tester.enterText(
      find.byKey(const ValueKey('preset-name')),
      'Renamed',
    );
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.widgetWithText(FilledButton, s.avatarSave),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog, skipOffstage: false), findsNothing);
    expect(c.draft.profile.name, 'Renamed');
    expect(c.profile.name, 'Menti');
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });

  testWidgets(
    'rapid back requests show one confirmation; cancel and discard remain usable',
    (tester) async {
      final c = await open(tester);
      c.rename('Draft');
      await tester.pumpAndSettle();
      final scope = tester.widget<PopScope<dynamic>>(
        find
            .descendant(
              of: find.byType(MentiStudioPage),
              matching: find.byWidgetPredicate((w) => w is PopScope),
            )
            .first,
      );
      scope.onPopInvokedWithResult!(false, null);
      scope.onPopInvokedWithResult!(false, null);
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog, skipOffstage: false), findsOneWidget);
      final s = appStrings(tester.element(find.byType(AlertDialog)));
      await tester.tap(find.widgetWithText(TextButton, s.avatarCancel));
      await tester.pumpAndSettle();
      expect(c.dirty, true);
      scope.onPopInvokedWithResult!(false, null);
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, s.avatarDiscard));
      await tester.pumpAndSettle();
      expect(find.byType(MentiStudioPage), findsNothing);
      expect(c.dirty, false);
      expect(c.profile.name, 'Menti');
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'double save while storage is pending writes once without a false failure message',
    (tester) async {
      final backend = DelayedIdentityWrite({});
      final c = await open(tester, backend: backend);
      c.rename('Saved once');
      await tester.pumpAndSettle();
      final s = appStrings(tester.element(find.byType(MentiStudioPage)));
      final save = tester
          .widget<FilledButton>(find.byKey(const ValueKey('studio-save')))
          .onPressed!;
      save();
      save();
      await tester.pump();
      expect(find.text(s.avatarSaveError), findsNothing);
      expect(backend.writes, 1);
      backend.gate.complete();
      await tester.pumpAndSettle();
      expect(c.profile.name, 'Saved once');
      expect(find.text(s.avatarSaved), findsOneWidget);
      expect(find.text(s.avatarSaveError), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    },
  );
}
