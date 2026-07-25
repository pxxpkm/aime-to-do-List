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

  test('clearTodayProgress zeros today bucket', () async {
    final day = DateTime(2026, 7, 17, 12);
    await store.addTodayProgress(4, day);
    expect(store.todayUnits(day), 4);
    await store.clearTodayProgress(day);
    expect(store.todayUnits(day), 0);
  });

  test('clearMonthProgress only clears this month', () async {
    await store.addTodayProgress(3, DateTime(2026, 7, 10));
    await store.addTodayProgress(2, DateTime(2026, 6, 20));
    await store.clearMonthProgress(DateTime(2026, 7, 17));
    expect(store.unitsForDayKey(store.dayKey(DateTime(2026, 7, 10))), 0);
    expect(store.unitsForDayKey(store.dayKey(DateTime(2026, 6, 20))), 2);
  });

  test('homeSortAscending default false', () {
    expect(store.homeSortAscending, isFalse);
  });

  test('setGoalUnits clamps 1-999', () async {
    await store.setGoalUnits(0);
    expect(store.goalUnits, 1);
    await store.setGoalUnits(2000);
    expect(store.goalUnits, 999);
  });

  test('posterImageFit defaults cover and accepts contain', () async {
    expect(store.posterImageFit, 'cover');
    await store.setPosterImageFit('contain');
    expect(store.posterImageFit, 'contain');
    await store.setPosterImageFit('nope');
    expect(store.posterImageFit, 'contain');
    await store.setPosterImageFit('cover');
    expect(store.posterImageFit, 'cover');
  });

  test('posterImageFit round-trips in export/backup', () async {
    await store.setPosterImageFit('contain');
    final bundle = store.exportForBackup();
    expect((bundle['ui'] as Map)['poster_image_fit'], 'contain');

    final box2 = await Hive.openBox(
      'goal_test_fit_${DateTime.now().microsecondsSinceEpoch}',
    );
    final store2 = GoalSettingsStore(box2);
    await store2.applyBackupSettings(bundle);
    expect(store2.posterImageFit, 'contain');
    await box2.clear();
    await box2.close();
  });

  test('markBackupExported sets lastBackupAt', () async {
    expect(store.lastBackupAt, isNull);
    final at = DateTime.utc(2026, 7, 25, 10);
    await store.markBackupExported(at);
    expect(store.lastBackupAtIso, at.toIso8601String());
    expect(store.lastBackupAt, at);
  });

  test('theme defaults paper_light and follow_system false', () {
    expect(store.themeId, 'paper_light');
    expect(store.themeFollowSystem, isFalse);
  });

  test('theme id and follow system persist', () async {
    await store.setThemeId('paper_dark');
    await store.setThemeFollowSystem(true);
    expect(store.themeId, 'paper_dark');
    expect(store.themeFollowSystem, isTrue);
    final bundle = store.exportForBackup();
    expect((bundle['ui'] as Map)['theme_id'], 'paper_dark');
    expect((bundle['ui'] as Map)['theme_follow_system'], isTrue);
  });
}
