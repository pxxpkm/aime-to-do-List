import 'package:acg_todo/data/local/library_store.dart';
import 'package:acg_todo/domain/services/item_sort_service.dart';
import 'package:acg_todo/domain/services/reminder_types.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Goals, layout, search prefs, and per-day progress buckets.
///
/// [GoalSettingsStore.hive] — browser Hive box.
/// [GoalSettingsStore.server] — memory + [LibraryStore.putSettingsBundle] (SQLite).
class GoalSettingsStore {
  static const _goalKey = 'daily_goal_units';
  static const _progressDateKey = 'daily_progress_date';
  static const _progressUnitsKey = 'daily_progress_units';
  static const _deadlineOffsetsKey = 'deadline_reminder_days';
  static const _deadlineOverdueKey = 'deadline_remind_overdue';
  static const _homeDensityKey = 'home_grid_density';
  static const _homeSortKey = 'home_sort_mode';
  static const _searchT2sKey = 'search_trad_to_simp';
  static const _titleS2tKey = 'title_simp_to_trad';
  static const _homeHeroModeKey = 'home_hero_mode';
  static const _homeHeroItemIdKey = 'home_hero_item_id';
  static const _rollingDaysKey = 'goal_rolling_days';
  static const _rollingTargetKey = 'goal_rolling_target';
  static const _monthTargetKey = 'goal_month_target';
  static const _yearTargetKey = 'goal_year_target';
  static const _rollingEnabledKey = 'goal_rolling_enabled';
  static const _monthEnabledKey = 'goal_month_enabled';
  static const _yearEnabledKey = 'goal_year_enabled';
  static const _dayBucketPrefix = 'pd_';
  static const defaultGoalUnits = 5;

  final _SettingsKv _kv;

  GoalSettingsStore._(this._kv);

  /// Hive / IndexedDB (default constructor for tests).
  factory GoalSettingsStore(Box box) => GoalSettingsStore.hive(box);

  factory GoalSettingsStore.hive(Box box) =>
      GoalSettingsStore._(_HiveSettingsKv(box));

  /// Disk library via local SQLite API.
  factory GoalSettingsStore.server(LibraryStore store) {
    final mem = <String, dynamic>{};
    late final GoalSettingsStore goals;
    final kv = _MemorySettingsKv(mem, null);
    goals = GoalSettingsStore._(kv);
    kv.onFlush = () async {
      // Preserve non-goal top-level keys (e.g. notifications prefs).
      final next = goals.exportForBackup();
      final prev = store.getSettingsBundle();
      for (final e in prev.entries) {
        if (!next.containsKey(e.key)) {
          next[e.key] = e.value;
        }
      }
      await store.putSettingsBundle(next);
    };
    goals.loadFromBundle(store.getSettingsBundle());
    return goals;
  }

  /// One-shot load without flushing (server hydrate / migrate).
  void loadFromBundle(Map<String, dynamic> settings) {
    final goals = settings['goals'];
    if (goals is Map) {
      final g = Map<String, dynamic>.from(goals);
      _putLocal(_goalKey, g['daily_goal_units']);
      _putLocal(_rollingDaysKey, g['goal_rolling_days']);
      _putLocal(_rollingTargetKey, g['goal_rolling_target']);
      _putLocal(_monthTargetKey, g['goal_month_target']);
      _putLocal(_yearTargetKey, g['goal_year_target']);
      _putLocal(_rollingEnabledKey, g['goal_rolling_enabled']);
      _putLocal(_monthEnabledKey, g['goal_month_enabled']);
      _putLocal(_yearEnabledKey, g['goal_year_enabled']);
      _putLocal(_deadlineOffsetsKey, g['deadline_reminder_days']);
      _putLocal(_deadlineOverdueKey, g['deadline_remind_overdue']);
    }
    final ui = settings['ui'];
    if (ui is Map) {
      final u = Map<String, dynamic>.from(ui);
      _putLocal(_homeDensityKey, u['home_grid_density']);
      _putLocal(_homeSortKey, u['home_sort_mode']);
      _putLocal(_searchT2sKey, u['search_trad_to_simp']);
      _putLocal(_titleS2tKey, u['title_simp_to_trad']);
      _putLocal(_homeHeroModeKey, u['home_hero_mode']);
      _putLocal(_homeHeroItemIdKey, u['home_hero_item_id']);
    }
    final days = settings['progressDays'];
    if (days is Map) {
      for (final e in days.entries) {
        if (e.key is! String) continue;
        final v = e.value;
        final units = v is int ? v : (v is num ? v.toInt() : null);
        if (units == null) continue;
        _putLocal('$_dayBucketPrefix${e.key}', units);
      }
    }
  }

  void _putLocal(String key, dynamic value) {
    if (value == null) return;
    _kv.putSync(key, value);
  }

  bool get isEmptyBundle {
    return _kv.get(_goalKey) == null &&
        !_kv.keys.any((k) => k is String && k.startsWith(_dayBucketPrefix));
  }

  int get goalUnits {
    final v = _kv.get(_goalKey);
    if (v is int && v > 0) return v;
    return defaultGoalUnits;
  }

  Future<void> setGoalUnits(int units) async {
    await _kv.put(_goalKey, units.clamp(1, 999));
  }

  int get rollingDays {
    final v = _kv.get(_rollingDaysKey);
    if (v is int && v >= 2 && v <= 31) return v;
    return 5;
  }

  Future<void> setRollingDays(int n) async {
    await _kv.put(_rollingDaysKey, n.clamp(2, 31));
  }

  int get rollingTarget {
    final v = _kv.get(_rollingTargetKey);
    if (v is int && v > 0) return v;
    return 20;
  }

  Future<void> setRollingTarget(int n) async {
    await _kv.put(_rollingTargetKey, n.clamp(1, 9999));
  }

  int get monthTarget {
    final v = _kv.get(_monthTargetKey);
    if (v is int && v > 0) return v;
    return 60;
  }

  Future<void> setMonthTarget(int n) async {
    await _kv.put(_monthTargetKey, n.clamp(1, 99999));
  }

  int get yearTarget {
    final v = _kv.get(_yearTargetKey);
    if (v is int && v > 0) return v;
    return 500;
  }

  Future<void> setYearTarget(int n) async {
    await _kv.put(_yearTargetKey, n.clamp(1, 999999));
  }

  bool get rollingEnabled =>
      _kv.get(_rollingEnabledKey, defaultValue: true) as bool;
  bool get monthEnabled =>
      _kv.get(_monthEnabledKey, defaultValue: true) as bool;
  bool get yearEnabled =>
      _kv.get(_yearEnabledKey, defaultValue: true) as bool;

  Future<void> setRollingEnabled(bool v) async =>
      _kv.put(_rollingEnabledKey, v);
  Future<void> setMonthEnabled(bool v) async => _kv.put(_monthEnabledKey, v);
  Future<void> setYearEnabled(bool v) async => _kv.put(_yearEnabledKey, v);

  List<int> get deadlineReminderDays =>
      ReminderTypes.parseOffsets(_kv.get(_deadlineOffsetsKey) as String?);

  Future<void> setDeadlineReminderDays(List<int> days) async {
    await _kv.put(
      _deadlineOffsetsKey,
      ReminderTypes.encodeOffsets(days),
    );
  }

  bool get deadlineRemindOverdue =>
      _kv.get(_deadlineOverdueKey, defaultValue: true) as bool;

  Future<void> setDeadlineRemindOverdue(bool v) async {
    await _kv.put(_deadlineOverdueKey, v);
  }

  String get homeGridDensity {
    final v = _kv.get(_homeDensityKey) as String?;
    if (v == 'comfortable' || v == 'large' || v == 'compact') return v!;
    return 'large';
  }

  Future<void> setHomeGridDensity(String density) async {
    if (density != 'compact' &&
        density != 'comfortable' &&
        density != 'large') {
      return;
    }
    await _kv.put(_homeDensityKey, density);
  }

  HomeSortMode get homeSortMode =>
      HomeSortMode.fromStorage(_kv.get(_homeSortKey) as String?);

  Future<void> setHomeSortMode(HomeSortMode mode) async {
    await _kv.put(_homeSortKey, mode.name);
  }

  bool get searchTradToSimp =>
      _kv.get(_searchT2sKey, defaultValue: true) as bool;

  Future<void> setSearchTradToSimp(bool enabled) async {
    await _kv.put(_searchT2sKey, enabled);
  }

  /// Convert simplified Chinese titles to traditional on add/display.
  bool get titleSimpToTrad =>
      _kv.get(_titleS2tKey, defaultValue: true) as bool;

  Future<void> setTitleSimpToTrad(bool enabled) async {
    await _kv.put(_titleS2tKey, enabled);
  }

  /// daily | pinned | off
  String get homeHeroMode {
    final v = _kv.get(_homeHeroModeKey) as String?;
    if (v == 'pinned' || v == 'off' || v == 'daily') return v!;
    return 'daily';
  }

  Future<void> setHomeHeroMode(String mode) async {
    if (mode != 'daily' && mode != 'pinned' && mode != 'off') return;
    await _kv.put(_homeHeroModeKey, mode);
  }

  String? get homeHeroItemId {
    final v = _kv.get(_homeHeroItemIdKey) as String?;
    if (v == null || v.isEmpty) return null;
    return v;
  }

  Future<void> setHomeHeroItemId(String? id) async {
    if (id == null || id.isEmpty) {
      await _kv.put(_homeHeroItemIdKey, '');
      return;
    }
    await _kv.put(_homeHeroItemIdKey, id);
  }

  /// Pin item as home hero poster (does not change pin tiers).
  Future<void> pinHomeHero(String itemId) async {
    await setHomeHeroItemId(itemId);
    await setHomeHeroMode('pinned');
  }

  String dayKey([DateTime? now]) {
    final d = now ?? DateTime.now();
    final local = DateTime(d.year, d.month, d.day);
    return '${local.year.toString().padLeft(4, '0')}-'
        '${local.month.toString().padLeft(2, '0')}-'
        '${local.day.toString().padLeft(2, '0')}';
  }

  int unitsForDayKey(String key) {
    final u = _kv.get('$_dayBucketPrefix$key');
    if (u is int) return u;
    final stored = _kv.get(_progressDateKey) as String?;
    if (stored == key) {
      final legacy = _kv.get(_progressUnitsKey);
      if (legacy is int) return legacy;
    }
    return 0;
  }

  int todayUnits([DateTime? now]) => unitsForDayKey(dayKey(now));

  Future<void> addTodayProgress(int delta, [DateTime? now]) =>
      addProgressDelta(delta, now);

  Future<void> addProgressDelta(int delta, [DateTime? now]) async {
    if (delta <= 0) return;
    final key = dayKey(now);
    final current = unitsForDayKey(key);
    _kv.putSync('$_dayBucketPrefix$key', current + delta);
    _kv.putSync(_progressDateKey, key);
    _kv.putSync(_progressUnitsKey, current + delta);
    await _kv.flush();
  }

  Future<void> setTodayProgress(int units, [DateTime? now]) async {
    final key = dayKey(now);
    _kv.putSync('$_dayBucketPrefix$key', units);
    _kv.putSync(_progressDateKey, key);
    _kv.putSync(_progressUnitsKey, units);
    await _kv.flush();
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
    final prefix = '$_dayBucketPrefix${n.year.toString().padLeft(4, '0')}-';
    for (final key in _kv.keys) {
      if (key is! String || !key.startsWith(prefix)) continue;
      final u = _kv.get(key);
      if (u is int) sum += u;
    }
    final legacyDate = _kv.get(_progressDateKey) as String?;
    if (legacyDate != null &&
        legacyDate.startsWith('${n.year}') &&
        _kv.get('$_dayBucketPrefix$legacyDate') == null) {
      final legacy = _kv.get(_progressUnitsKey);
      if (legacy is int) sum += legacy;
    }
    return sum;
  }

  Map<String, dynamic> exportForBackup() {
    final progressDays = <String, int>{};
    for (final key in _kv.keys) {
      if (key is! String || !key.startsWith(_dayBucketPrefix)) continue;
      final day = key.substring(_dayBucketPrefix.length);
      final u = _kv.get(key);
      if (u is int && u > 0) progressDays[day] = u;
    }
    final legacyDate = _kv.get(_progressDateKey) as String?;
    if (legacyDate != null && !progressDays.containsKey(legacyDate)) {
      final legacy = _kv.get(_progressUnitsKey);
      if (legacy is int && legacy > 0) progressDays[legacyDate] = legacy;
    }

    return {
      'goals': {
        'daily_goal_units': goalUnits,
        'goal_rolling_days': rollingDays,
        'goal_rolling_target': rollingTarget,
        'goal_month_target': monthTarget,
        'goal_year_target': yearTarget,
        'goal_rolling_enabled': rollingEnabled,
        'goal_month_enabled': monthEnabled,
        'goal_year_enabled': yearEnabled,
        'deadline_reminder_days': ReminderTypes.encodeOffsets(
          deadlineReminderDays,
        ),
        'deadline_remind_overdue': deadlineRemindOverdue,
      },
      'ui': {
        'home_grid_density': homeGridDensity,
        'home_sort_mode': homeSortMode.name,
        'search_trad_to_simp': searchTradToSimp,
        'title_simp_to_trad': titleSimpToTrad,
        'home_hero_mode': homeHeroMode,
        'home_hero_item_id': homeHeroItemId ?? '',
      },
      'progressDays': progressDays,
    };
  }

  Future<void> applyBackupSettings(
    Map<String, dynamic> settings, {
    bool progressOnly = false,
    bool replaceProgress = false,
  }) async {
    final days = settings['progressDays'];
    if (days is Map) {
      for (final e in days.entries) {
        final key = e.key;
        if (key is! String) continue;
        final v = e.value;
        final units = v is int ? v : (v is num ? v.toInt() : null);
        if (units == null || units < 0) continue;
        final boxKey = '$_dayBucketPrefix$key';
        if (replaceProgress) {
          await _kv.put(boxKey, units);
        } else {
          final current = unitsForDayKey(key);
          await _kv.put(boxKey, current + units);
        }
      }
    }

    if (progressOnly || settings['_mergeProgressOnly'] == true) return;

    final goals = settings['goals'];
    if (goals is Map) {
      final g = Map<String, dynamic>.from(goals);
      final daily = g['daily_goal_units'];
      if (daily is int) await setGoalUnits(daily);
      final rd = g['goal_rolling_days'];
      if (rd is int) await setRollingDays(rd);
      final rt = g['goal_rolling_target'];
      if (rt is int) await setRollingTarget(rt);
      final mt = g['goal_month_target'];
      if (mt is int) await setMonthTarget(mt);
      final yt = g['goal_year_target'];
      if (yt is int) await setYearTarget(yt);
      if (g['goal_rolling_enabled'] is bool) {
        await setRollingEnabled(g['goal_rolling_enabled'] as bool);
      }
      if (g['goal_month_enabled'] is bool) {
        await setMonthEnabled(g['goal_month_enabled'] as bool);
      }
      if (g['goal_year_enabled'] is bool) {
        await setYearEnabled(g['goal_year_enabled'] as bool);
      }
      final offsets = g['deadline_reminder_days'];
      if (offsets is String) {
        await setDeadlineReminderDays(ReminderTypes.parseOffsets(offsets));
      }
      if (g['deadline_remind_overdue'] is bool) {
        await setDeadlineRemindOverdue(g['deadline_remind_overdue'] as bool);
      }
    }

    final ui = settings['ui'];
    if (ui is Map) {
      final u = Map<String, dynamic>.from(ui);
      final dens = u['home_grid_density'];
      if (dens is String) await setHomeGridDensity(dens);
      final sort = u['home_sort_mode'];
      if (sort is String) {
        await setHomeSortMode(HomeSortMode.fromStorage(sort));
      }
      if (u['search_trad_to_simp'] is bool) {
        await setSearchTradToSimp(u['search_trad_to_simp'] as bool);
      }
      if (u['title_simp_to_trad'] is bool) {
        await setTitleSimpToTrad(u['title_simp_to_trad'] as bool);
      }
      final heroMode = u['home_hero_mode'];
      if (heroMode is String) await setHomeHeroMode(heroMode);
      final heroId = u['home_hero_item_id'];
      if (heroId is String) {
        await setHomeHeroItemId(heroId.isEmpty ? null : heroId);
      }
    }
  }
}

abstract class _SettingsKv {
  dynamic get(String key, {dynamic defaultValue});
  Future<void> put(String key, dynamic value);
  void putSync(String key, dynamic value);
  Future<void> flush();
  Iterable get keys;
}

class _HiveSettingsKv implements _SettingsKv {
  final Box box;
  _HiveSettingsKv(this.box);

  @override
  dynamic get(String key, {dynamic defaultValue}) =>
      box.get(key, defaultValue: defaultValue);

  @override
  Future<void> put(String key, dynamic value) => box.put(key, value);

  @override
  void putSync(String key, dynamic value) {
    box.put(key, value);
  }

  @override
  Future<void> flush() async {}

  @override
  Iterable get keys => box.keys;
}

class _MemorySettingsKv implements _SettingsKv {
  final Map<String, dynamic> data;
  Future<void> Function()? onFlush;

  _MemorySettingsKv(this.data, Future<void> Function()? onFlush)
      : onFlush = onFlush;

  @override
  dynamic get(String key, {dynamic defaultValue}) {
    if (!data.containsKey(key)) return defaultValue;
    return data[key];
  }

  @override
  Future<void> put(String key, dynamic value) async {
    data[key] = value;
    await flush();
  }

  @override
  void putSync(String key, dynamic value) {
    data[key] = value;
  }

  @override
  Future<void> flush() async {
    final f = onFlush;
    if (f != null) await f();
  }

  @override
  Iterable get keys => data.keys;
}
