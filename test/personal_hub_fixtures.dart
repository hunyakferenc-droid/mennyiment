import 'dart:convert';

import 'package:mennyiment/daily_menti_store.dart';
import 'package:mennyiment/menti_completion.dart';
import 'package:mennyiment/menti_xp_store.dart';
import 'package:mennyiment/personal_goal_store.dart';
import 'package:mennyiment/weekly_challenges.dart';

Map<String, Object> hubValues(DateTime now) {
  final yesterday = mentiDateKey(mentiCalendarDay(now, -1));
  final today = mentiDateKey(now);
  final week = mentiDateKey(mentiMonday(now));
  return {
    'mennyiment_character_style_v2': 'girl',
    'mennyiment_outfit_v2': 'legendary',
    'mennyiment_character_name_v1': 'Menti',
    'mennyiment_character_setup_complete_v1': true,
    'mennyiment_reduce_motion_v1': true,
    'mennyiment_menti_rewards_v1': <String>['outfit:legendary', 'future:hat'],
    MentiXpStore.currentKey: jsonEncode({'xp': 150, 'days': [yesterday, today],
      'completed': ['$week:goal'], 'future': {'keep': true}}),
    DailyMentiStore.key(now): jsonEncode({'mood': 3, 'energy': 4,
      'goal': 'Séta', 'evening': '', 'future': 42}),
    PersonalGoalStore.key: jsonEncode({'reflectionGoal': 2, 'weeklyBudget': 0,
      'reflectionDays': [yesterday], 'future': {'nested': [true, 42]}}),
    ChallengeStore.key: jsonEncode({'version': 1, 'future': true, 'weeks': {
      week: {
        'custom': {'title': 'Séta / walk', 'goal': 2, 'days': [yesterday], 'status': 'active', 'future': 42},
        'journal': {'title': '', 'goal': 1, 'days': [], 'status': 'active'},
        'habit': {'title': '', 'goal': 1, 'days': [yesterday], 'status': 'stopped'},
      },
    }}),
    'mennyiment_wellbeing_v1': jsonEncode([{'day': mentiCalendarDay(now, -1).toIso8601String(),
      'mood': 3, 'sleep': 3, 'hangover': 0, 'note': 'private note'}]),
    'mennyiment_drinks_v1': jsonEncode([
      {'name': 'Recorded zero', 'ml': 250, 'percent': 0, 'time': now.toIso8601String(), 'priceFt': 0, 'future': 'keep'},
      {'name': 'Unknown price', 'ml': 250, 'percent': 5, 'time': now.toIso8601String()},
      {'name': 'Previous week', 'ml': 250, 'percent': 5,
        'time': mentiCalendarDay(mentiMonday(now), -1).toIso8601String(), 'priceFt': 100},
      {'name': 'Future entry', 'ml': 250, 'percent': 5,
        'time': now.add(const Duration(hours: 1)).toIso8601String(), 'priceFt': 1000},
    ]),
    'mennyiment_custom_drinks_v1': '[]',
    'mennyiment_favorites_v1': <String>['legacy:keep'],
    'mennyiment_future_key': '{ "unknown": [1,2,3] }',
    'foreign': true,
  };
}
