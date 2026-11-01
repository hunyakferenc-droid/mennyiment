import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mennyiment/dashboard_v2.dart';
import 'package:mennyiment/finance_center.dart';
import 'package:mennyiment/lifestyle_insights.dart';
import 'package:mennyiment/savings_goals.dart';
import 'package:mennyiment/menti_week_report.dart';
import 'package:mennyiment/menti_goal_world.dart';
import 'package:mennyiment/l10n/generated/app_localizations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  for (final locale in ['hu', 'en']) {
    for (final scale in [1.0, 2.0]) {
      for (final width in [320.0, 1024.0]) {
        testWidgets(
          '$locale legacy feature pages fit ${width}px at ${scale}x without changing stored data',
          (tester) async {
            tester.view.physicalSize = Size(width, 1000);
            tester.view.devicePixelRatio = 1;
            tester.binding.platformDispatcher.textScaleFactorTestValue = scale;
            addTearDown(tester.view.resetPhysicalSize);
            addTearDown(tester.view.resetDevicePixelRatio);
            addTearDown(
              tester.binding.platformDispatcher.clearTextScaleFactorTestValue,
            );
            final now = DateTime.now();
            final original = <String, Object>{
              'mennyiment_finance_baseline_v1': 40000,
              'mennyiment_budget_v2': 50000,
              'mennyiment_savings_baseline_v1': 40000,
              'mennyiment_savings_goals_v1': jsonEncode([
                {
                  'id': 'one',
                  'title': 'A personal goal with a longer name',
                  'emoji': '🌱',
                  'savedFt': 5000,
                  'targetFt': 100000,
                  'future': {'keep': true},
                },
              ]),
              'mennyiment_wellbeing_v1': jsonEncode([
                {
                  'day': DateTime(
                    now.year,
                    now.month,
                    now.day,
                  ).toIso8601String(),
                  'mood': 4,
                  'sleep': 3,
                  'hangover': 1,
                  'note': 'Saved note',
                  'future': 'keep',
                },
              ]),
            };
            SharedPreferences.setMockInitialValues(original);
            for (final page in <Widget>[
              DashboardV2Page(
                drinks: [
                  V2Drink(name: 'Entry', time: now, grams: 4, priceFt: 12345),
                ],
              ),
              FinanceCenterPage(
                drinks: [
                  V2Drink(name: 'Entry', time: now, grams: 4, priceFt: 12345),
                ],
              ),
              LifestyleInsightsPage(
                drinks: [InsightDrink(time: now, grams: 4, priceFt: 12345)],
              ),
              SavingsGoalsPage(
                drinks: [SavingsDrink(time: now, priceFt: 12345)],
              ),
              MentiWeekReportPage(
                drinks: [MentiWeekDrink(time: now, grams: 4, priceFt: 12345)],
              ),
              const MentiGoalWorldPage(
                goals: [
                  MentiWorldGoal(
                    title: 'A personal goal',
                    emoji: '🌱',
                    savedFt: 5000,
                    targetFt: 10000,
                  ),
                ],
              ),
            ]) {
              await tester.pumpWidget(
                MaterialApp(
                  locale: Locale(locale),
                  supportedLocales: AppLocalizations.supportedLocales,
                  localizationsDelegates:
                      AppLocalizations.localizationsDelegates,
                  home: page,
                ),
              );
              await tester.pumpAndSettle();
              expect(
                tester.takeException(),
                isNull,
                reason: '${page.runtimeType} initial',
              );
              final scroll = find.byType(Scrollable).first;
              for (var i = 0; i < 14; i++) {
                await tester.drag(scroll, const Offset(0, -450));
                await tester.pumpAndSettle();
                expect(
                  tester.takeException(),
                  isNull,
                  reason: '${page.runtimeType} scroll $i',
                );
              }
              final p = await SharedPreferences.getInstance();
              for (final entry in original.entries) {
                expect(
                  p.get(entry.key),
                  entry.value,
                  reason: '${page.runtimeType}: ${entry.key}',
                );
              }
              await tester.pumpWidget(const SizedBox.shrink());
              await tester.pump();
            }
          },
        );
      }
    }
  }
}
