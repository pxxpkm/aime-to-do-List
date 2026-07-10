/// Reminder / notification type string constants.
abstract final class ReminderTypes {
  static const overdue = 'overdue';
  static const stale = 'stale_7day';
  static const dailyGoal = 'daily_goal';

  /// Prefix for dynamic deadline types: deadline_d{n}
  static const deadlinePrefix = 'deadline_d';

  /// Synthetic item id for daily-goal reminders.
  static const dailyGoalItemId = '__daily__';

  /// Settings key groups.
  static const settingDeadline = 'deadline';
  static const settingStale = 'stale';
  static const settingDailyGoal = 'daily_goal';

  static String deadlineDays(int n) => '$deadlinePrefix$n';

  static bool isDeadlineType(String type) =>
      type == overdue || type.startsWith(deadlinePrefix);

  static int? parseDeadlineDays(String type) {
    if (!type.startsWith(deadlinePrefix)) return null;
    return int.tryParse(type.substring(deadlinePrefix.length));
  }

  static String settingKeyForType(String type) {
    if (isDeadlineType(type)) return settingDeadline;
    if (type == stale) return settingStale;
    if (type == dailyGoal) return settingDailyGoal;
    return type;
  }

  /// Default global offsets (legacy behaviour).
  static const List<int> defaultDeadlineOffsets = [3, 1, 0];

  static List<int> parseOffsets(String? raw, {List<int>? fallback}) {
    final fb = fallback ?? defaultDeadlineOffsets;
    if (raw == null || raw.trim().isEmpty) return List<int>.from(fb);
    final parts = raw.split(RegExp(r'[,，\s]+'));
    final set = <int>{};
    for (final p in parts) {
      final n = int.tryParse(p.trim());
      if (n != null && n >= 0 && n <= 90) set.add(n);
    }
    if (set.isEmpty) return List<int>.from(fb);
    final list = set.toList()..sort((a, b) => b.compareTo(a));
    if (list.length > 8) return list.sublist(0, 8);
    return list;
  }

  static String encodeOffsets(List<int> offsets) {
    final cleaned = offsets
        .where((n) => n >= 0 && n <= 90)
        .toSet()
        .toList()
      ..sort((a, b) => b.compareTo(a));
    return cleaned.join(',');
  }
}
