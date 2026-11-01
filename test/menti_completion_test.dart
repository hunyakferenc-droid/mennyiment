import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mennyiment/menti_completion.dart';

void main() {
  test('Only canonical, distinct, recorded dates in the observed week count', () {
    final sunday = DateTime(2026, 10, 25, 12);
    expect(recordedGoalDays(['2026-10-19', '2026-10-19', '2026-10-25',
      '2026-10-26', '2026-10-18', '2026-10-32', 'unknown',
      '2026-10-20T00:00:00.000', '2026-02-31'], sunday, sunday), 2);
    expect(recordedGoalDays([], sunday, sunday), 0);
    expect(recordedGoalDays(['2026-10-25'], sunday, DateTime(2026, 10, 24)), 0);
  });
  test('Celebration requires new evidence crossing an unchanged valid target', () {
    expect(crossedRecordedGoal(before: 2, after: 3, previousTarget: 3, target: 3), true);
    for (final values in [(3, 3, 3, 3), (3, 4, 3, 3), (2, 2, 3, 2),
      (1, 2, 3, 2), (0, 0, 1, 1), (2, 1, 3, 3), (0, 1, 0, 0)]) {
      expect(crossedRecordedGoal(before: values.$1, after: values.$2,
        previousTarget: values.$3, target: values.$4), false);
    }
  });
  test('Both DST weeks contain all seven local dates, and exclude next Monday', () {
    for (final day in [DateTime(2026, 3, 29, 23), DateTime(2026, 10, 25, 23)]) {
      final monday = mentiMonday(day);
      final days = [for (var i = 0; i < 8; i++) mentiDateKey(mentiCalendarDay(monday, i))];
      expect(recordedGoalDays(days, monday, day), 7);
      if (Platform.environment['TZ'] == 'Europe/Budapest') {
        expect(mentiCalendarDay(monday, 7).difference(monday).inHours,
          day.month == 3 ? 167 : 169);
      }
    }
  });
}
