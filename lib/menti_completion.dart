/// Read-only evidence for reactions. Missing days are never inferred.
DateTime mentiCalendarDay(DateTime date, [int offset = 0]) =>
    DateTime(date.year, date.month, date.day + offset);

DateTime mentiMonday(DateTime date) =>
    mentiCalendarDay(date, 1 - date.weekday);

String mentiDateKey(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

int recordedGoalDays(Iterable<String> days, DateTime week, DateTime asOf) {
  final start = mentiMonday(week);
  final end = mentiCalendarDay(start, 7);
  final today = mentiCalendarDay(asOf);
  return days.where((value) {
    final parsed = DateTime.tryParse(value);
    // Reject normalized invalid dates, timestamps and offset representations.
    if (parsed == null || mentiDateKey(parsed) != value) return false;
    return !parsed.isBefore(start) && parsed.isBefore(end) &&
        !parsed.isAfter(today);
  }).toSet().length;
}

bool crossedRecordedGoal({required int before, required int after,
    required int previousTarget, required int target}) =>
    target >= 1 && target <= 7 && target == previousTarget &&
    before < target && after >= target && after > before;
