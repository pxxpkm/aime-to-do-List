import 'package:acg_todo/domain/entities/item.dart';
import 'package:acg_todo/domain/services/deadline_service.dart';
import 'package:acg_todo/domain/services/reminder_types.dart';

class ReminderCandidate {
  final String itemId;
  final String type;
  final String title;
  final String body;

  const ReminderCandidate({
    required this.itemId,
    required this.type,
    required this.title,
    required this.body,
  });
}

class ReminderService {
  final DeadlineService _deadline;

  const ReminderService({
    DeadlineService deadlineService = const DeadlineService(),
  }) : _deadline = deadlineService;

  List<ReminderCandidate> collect({
    required List<Item> items,
    required int goalUnits,
    required int todayUnits,
    required int staleDays,
    required List<int> globalDeadlineOffsets,
    required bool includeOverdue,
    required bool Function(String settingKey) enabled,
    DateTime? now,
  }) {
    final n = now ?? DateTime.now();
    final out = <ReminderCandidate>[];

    if (enabled(ReminderTypes.settingDeadline)) {
      for (final item in items) {
        final offsets = _effectiveOffsets(item, globalDeadlineOffsets);
        if (offsets.isEmpty && item.deadlineRemindMode == 'off') continue;

        final type = _deadline.shouldRemind(
          item,
          offsets: offsets,
          includeOverdue:
              item.deadlineRemindMode == 'off' ? false : includeOverdue,
          now: n,
        );
        if (type == null) continue;
        if (item.deadlineRemindMode == 'off') continue;

        out.add(ReminderCandidate(
          itemId: item.id,
          type: type,
          title: deadlineTitle(type, item.title),
          body: deadlineBody(type),
        ));
      }
    }

    if (enabled(ReminderTypes.settingStale)) {
      for (final item in items) {
        if (!_deadline.isStale(item, staleDays: staleDays, now: n)) continue;
        out.add(ReminderCandidate(
          itemId: item.id,
          type: ReminderTypes.stale,
          title: '${item.title} — 好久沒動了',
          body: '已經 $staleDays 天以上沒更新進度，看一集？',
        ));
      }
    }

    if (enabled(ReminderTypes.settingDailyGoal) && todayUnits < goalUnits) {
      final remaining = goalUnits - todayUnits;
      out.add(ReminderCandidate(
        itemId: ReminderTypes.dailyGoalItemId,
        type: ReminderTypes.dailyGoal,
        title: '今日目標未完成',
        body: '還差 $remaining 集達標（$todayUnits / $goalUnits）',
      ));
    }

    return out;
  }

  List<int> _effectiveOffsets(Item item, List<int> global) {
    switch (item.deadlineRemindMode) {
      case 'off':
        return const [];
      case 'custom':
        return ReminderTypes.parseOffsets(
          item.customDeadlineOffsets,
          fallback: global,
        );
      default:
        return global;
    }
  }

  static String deadlineTitle(String type, String title) {
    if (type == ReminderTypes.overdue) return '$title — 已逾期';
    final n = ReminderTypes.parseDeadlineDays(type);
    if (n == null) return 'ACG To-Do 提醒';
    if (n == 0) return '$title — 今天到期';
    if (n == 1) return '$title — 明天到期';
    return '$title — 還有 $n 天到期';
  }

  static String deadlineBody(String type) {
    if (type == ReminderTypes.overdue) return '已經逾期了，要繼續嗎？';
    final n = ReminderTypes.parseDeadlineDays(type);
    if (n == null) return '';
    if (n == 0) return '今天到期，別忘了更新進度';
    if (n == 1) return '明天就是期限了！';
    return '還有 $n 天，加緊腳步！';
  }
}
