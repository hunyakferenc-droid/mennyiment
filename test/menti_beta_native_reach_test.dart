import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../integration_test/menti_beta_device_test.dart' as native;

void main() {
  testWidgets('Native reach waits for a lazy control after viewport rebuild', (
    t,
  ) async {
    final shown = ValueNotifier(true);
    addTearDown(shown.dispose);
    const key = ValueKey('native-reach-save');
    await t.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ValueListenableBuilder(
            valueListenable: shown,
            builder: (context, visible, _) => ListView(
              children: [
                const SizedBox(height: 400),
                if (visible)
                  FilledButton(
                    key: key,
                    onPressed: () {},
                    child: const Text('Save'),
                  ),
                const SizedBox(height: 400),
              ],
            ),
          ),
        ),
      ),
    );
    final hide = Timer(
      const Duration(milliseconds: 150),
      () => shown.value = false,
    );
    final restore = Timer(
      const Duration(milliseconds: 750),
      () => shown.value = true,
    );
    addTearDown(hide.cancel);
    addTearDown(restore.cancel);
    await native.reach(t, find.byKey(key));
    expect(find.byKey(key).hitTestable(), findsOneWidget);
    expect(t.takeException(), isNull);
  });
}
