import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:acg_todo/data/local/goal_settings_store.dart';

void main() {
  late Box box;
  late GoalSettingsStore store;

  setUp(() async {
    Hive.init('./.dart_tool/test_hive_goal');
    box = await Hive.openBox('goal_test_${DateTime.now().microsecondsSinceEpoch}');
    store = GoalSettingsStore(box);
  });

  tearDown(() async {
    await box.clear();
    await box.close();
  });

  test('default goal is 5', () {
    expect(store.goalUnits, 5);
  });

  test('addTodayProgress accumulates same day', () async {
    final day = DateTime(2026, 7, 10, 15);
    await store.addTodayProgress(2, day);
    await store.addTodayProgress(3, day);
    expect(store.todayUnits(day), 5);
  });

  test('addTodayProgress resets across days', () async {
    await store.addTodayProgress(4, DateTime(2026, 7, 10));
    expect(store.todayUnits(DateTime(2026, 7, 11)), 0);
    await store.addTodayProgress(1, DateTime(2026, 7, 11));
    expect(store.todayUnits(DateTime(2026, 7, 11)), 1);
  });

  test('setGoalUnits clamps 1-999', () async {
    await store.setGoalUnits(0);
    expect(store.goalUnits, 1);
    await store.setGoalUnits(2000);
    expect(store.goalUnits, 999);
  });
}
