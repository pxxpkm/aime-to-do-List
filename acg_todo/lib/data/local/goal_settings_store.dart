import 'package:acg_todo/domain/services/item_sort_service.dart';
import 'package:acg_todo/domain/services/reminder_types.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Goals, layout, search prefs, and per-day progress buckets.
class GoalSettingsStore {
  static const _goalKey = 'daily_goal_units';
  static const _progressDateKey = 'daily_progress_date';
  static const _progressUnitsKey = 'daily_progress_units';
  static const _deadlineOffsetsKey = 'deadline_reminder_days';
  static const _deadlineOverdueKey = 'deadline_remind_overdue';
  static const _homeDensityKey = 'home_grid_density';
  static const _homeSortKey = 'home_sort_mode';
  static const _searchT2sKey = 'search_trad_to_simp';
  static const _rollingDaysKey = 'goal_rolling_days';
  static const _rollingTargetKey = 'goal_rolling_target';
  static const _monthTargetKey = 'goal_month_target';
  static const _yearTargetKey = 'goal_year_target';
  static const _rollingEnabledKey = 'goal_rolling_enabled';
  static const _monthEnabledKey = 'goal_month_enabled';
  static const _yearEnabledKey = 'goal_year_enabled';
  static const _dayBucketPrefix = 'pd_';
  static const defaultGoalUnits = 5;

  final Box _box;

  GoalSettingsStore(this._box);

  int get goalUnits {
    final v = _box.get(_goalKey);
    if (v is int && v > 0) return v;
    return defaultGoalUnits;
  }

  Future<void> setGoalUnits(int units) async {
    await _box.put(_goalKey, units.clamp(1, 999));
  }

  int get rollingDays {
    final v = _box.get(_rollingDaysKey);
    if (v is int && v >= 2 && v <= 31) return v;
    return 5;
  }

  Future<void> setRollingDays(int n) async {
    await _box.put(_rollingDaysKey, n.clamp(2, 31));
  }

  int get rollingTarget {
    final v = _box.get(_rollingTargetKey);
    if (v is int && v > 0) return v;
    return 20;
  }

  Future<void> setRollingTarget(int n) async {
    await _box.put(_rollingTargetKey, n.clamp(1, 9999));
  }

  int get monthTarget {
    final v = _box.get(_monthTargetKey);
    if (v is int && v > 0) return v;
    return 60;
  }

  Future<void> setMonthTarget(int n) async {
    await _box.put(_monthTargetKey, n.clamp(1, 99999));
  }

  int get yearTarget {
    final v = _box.get(_yearTargetKey);
    if (v is int && v > 0) return v;
    return 500;
  }

  Future<void> setYearTarget(int n) async {
    await _box.put(_yearTargetKey, n.clamp(1, 999999));
  }

  bool get rollingEnabled =>
      _box.get(_rollingEnabledKey, defaultValue: true) as bool;
  bool get monthEnabled =>
      _box.get(_monthEnabledKey, defaultValue: true) as bool;
  bool get yearEnabled =>
      _box.get(_yearEnabledKey, defaultValue: true) as bool;

  Future<void> setRollingEnabled(bool v) async =>
      _box.put(_rollingEnabledKey, v);
  Future<void> setMonthEnabled(bool v) async => _box.put(_monthEnabledKey, v);
  Future<void> setYearEnabled(bool v) async => _box.put(_yearEnabledKey, v);

  List<int> get deadlineReminderDays =>
      ReminderTypes.parseOffsets(_box.get(_deadlineOffsetsKey) as String?);

  Future<void> setDeadlineReminderDays(List<int> days) async {
    await _box.put(
      _deadlineOffsetsKey,
      ReminderTypes.encodeOffsets(days),
    );
  }

  bool get deadlineRemindOverdue =>
      _box.get(_deadlineOverdueKey, defaultValue: true) as bool;

  Future<void> setDeadlineRemindOverdue(bool v) async {
    await _box.put(_deadlineOverdueKey, v);
  }

  String get homeGridDensity {
    final v = _box.get(_homeDensityKey) as String?;
    if (v == 'comfortable' || v == 'large' || v == 'compact') return v!;
    return 'compact';
  }

  Future<void> setHomeGridDensity(String density) async {
    if (density != 'compact' &&
        density != 'comfortable' &&
        density != 'large') {
      return;
    }
    await _box.put(_homeDensityKey, density);
  }

  HomeSortMode get homeSortMode =>
      HomeSortMode.fromStorage(_box.get(_homeSortKey) as String?);

  Future<void> setHomeSortMode(HomeSortMode mode) async {
    await _box.put(_homeSortKey, mode.name);
  }

  bool get searchTradToSimp =>
      _box.get(_searchT2sKey, defaultValue: true) as bool;

  Future<void> setSearchTradToSimp(bool enabled) async {
    await _box.put(_searchT2sKey, enabled);
  }

  String dayKey([DateTime? now]) {
    final d = now ?? DateTime.now();
    final local = DateTime(d.year, d.month, d.day);
    return '${local.year.toString().padLeft(4, '0')}-'
        '${local.month.toString().padLeft(2, '0')}-'
        '${local.day.toString().padLeft(2, '0')}';
  }

  int unitsForDayKey(String key) {
    final u = _box.get('$_dayBucketPrefix$key');
    if (u is int) return u;
    // legacy single-day keys
    final stored = _box.get(_progressDateKey) as String?;
    if (stored == key) {
      final legacy = _box.get(_progressUnitsKey);
      if (legacy is int) return legacy;
    }
    return 0;
  }

  int todayUnits([DateTime? now]) => unitsForDayKey(dayKey(now));

  /// Prefer [addProgressDelta]; kept for tests / compat.
  Future<void> addTodayProgress(int delta, [DateTime? now]) =>
      addProgressDelta(delta, now);

  Future<void> addProgressDelta(int delta, [DateTime? now]) async {
    if (delta <= 0) return;
    final key = dayKey(now);
    final current = unitsForDayKey(key);
    await _box.put('$_dayBucketPrefix$key', current + delta);
    // keep legacy keys in sync for old readers
    await _box.put(_progressDateKey, key);
    await _box.put(_progressUnitsKey, current + delta);
  }

  Future<void> setTodayProgress(int units, [DateTime? now]) async {
    final key = dayKey(now);
    await _box.put('$_dayBucketPrefix$key', units);
    await _box.put(_progressDateKey, key);
    await _box.put(_progressUnitsKey, units);
  }

  int rollingUnits(int days, [DateTime? now]) {
    final n = now ?? DateTime.now();
    var sum = 0;
    for (var i = 0; i < days; i++) {
      final d = n.subtract(Duration(days: i));
      sum += unitsForDayKey(dayKey(d));
    }
    return sum;
  }

  int monthUnits([DateTime? now]) {
    final n = now ?? DateTime.now();
    var sum = 0;
    for (var day = 1; day <= n.day; day++) {
      sum += unitsForDayKey(dayKey(DateTime(n.year, n.month, day)));
    }
    return sum;
  }

  int yearUnits([DateTime? now]) {
    final n = now ?? DateTime.now();
    var sum = 0;
    // Sum day buckets for year — scan keys with prefix for this year
    final prefix = '$_dayBucketPrefix${n.year.toString().padLeft(4, '0')}-';
    for (final key in _box.keys) {
      if (key is! String || !key.startsWith(prefix)) continue;
      final u = _box.get(key);
      if (u is int) sum += u;
    }
    // include legacy if same year
    final legacyDate = _box.get(_progressDateKey) as String?;
    if (legacyDate != null &&
        legacyDate.startsWith('${n.year}') &&
        _box.get('$_dayBucketPrefix$legacyDate') == null) {
      final legacy = _box.get(_progressUnitsKey);
      if (legacy is int) sum += legacy;
    }
    return sum;
  }
}
