import 'package:acg_todo/data/local/goal_settings_store.dart';
import 'package:acg_todo/domain/entities/item.dart';
import 'package:acg_todo/domain/services/daily_goal_service.dart';

class GoalPeriodProgress {
  final String id;
  final String label;
  final int current;
  final int target;
  final bool enabled;

  const GoalPeriodProgress({
    required this.id,
    required this.label,
    required this.current,
    required this.target,
    required this.enabled,
  });

  double get progress =>
      target <= 0 ? 0 : (current / target).clamp(0.0, 1.0);

  bool get isComplete => current >= target;

  int get remaining => (target - current).clamp(0, target);
}

class MultiGoalSnapshot {
  final List<GoalPeriodProgress> periods;
  final List<Item> suggestions;

  const MultiGoalSnapshot({
    required this.periods,
    required this.suggestions,
  });

  /// Enabled periods only, for UI.
  List<GoalPeriodProgress> get visible =>
      periods.where((p) => p.enabled).toList();
}

class MultiGoalService {
  const MultiGoalService();

  MultiGoalSnapshot build({
    required List<Item> items,
    required GoalSettingsStore store,
    DateTime? now,
  }) {
    final n = now ?? DateTime.now();
    final day = store.todayUnits(n);
    final rollingN = store.rollingDays;
    final periods = <GoalPeriodProgress>[
      GoalPeriodProgress(
        id: 'day',
        label: '今日',
        current: day,
        target: store.goalUnits,
        enabled: true,
      ),
      GoalPeriodProgress(
        id: 'rolling',
        label: '近$rollingN日',
        current: store.rollingUnits(rollingN, n),
        target: store.rollingTarget,
        enabled: store.rollingEnabled,
      ),
      GoalPeriodProgress(
        id: 'month',
        label: '本月',
        current: store.monthUnits(n),
        target: store.monthTarget,
        enabled: store.monthEnabled,
      ),
      GoalPeriodProgress(
        id: 'year',
        label: '今年',
        current: store.yearUnits(n),
        target: store.yearTarget,
        enabled: store.yearEnabled,
      ),
    ];

    return MultiGoalSnapshot(
      periods: periods,
      suggestions: const DailyGoalService().suggest(items, now: n, limit: 2),
    );
  }
}
