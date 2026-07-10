import 'package:acg_todo/domain/entities/item.dart';

enum DeadlineStatus {
  onTrack,
  atRisk,
  overdue,
  noDeadline,
}

class DeadlineInfo {
  final DateTime? deadline;
  final int? daysRemaining;
  final DeadlineStatus status;
  final String label;
  final double? estimatedCompletionPct;

  const DeadlineInfo({
    required this.deadline,
    required this.daysRemaining,
    required this.status,
    required this.label,
    this.estimatedCompletionPct,
  });
}

class DeadlineService {
  const DeadlineService();

  /// Classify deadline status for an item
  DeadlineInfo analyze(Item item) {
    final deadline = item.deadline;
    if (deadline == null) {
      return const DeadlineInfo(
        deadline: null,
        daysRemaining: null,
        status: DeadlineStatus.noDeadline,
        label: '無期限',
      );
    }

    final now = DateTime.now();
    final daysRemaining = deadline.difference(now).inDays;

    if (daysRemaining < 0) {
      return DeadlineInfo(
        deadline: deadline,
        daysRemaining: daysRemaining,
        status: DeadlineStatus.overdue,
        label: '逾期 ${-daysRemaining} 天',
      );
    }

    final total = item.totalUnits;
    double? estimated;
    if (total != null && total > 0) {
      estimated = item.currentUnits / total;
    }

    if (daysRemaining == 0) {
      return DeadlineInfo(
        deadline: deadline,
        daysRemaining: 0,
        status: DeadlineStatus.atRisk,
        label: '今天到期',
        estimatedCompletionPct: estimated,
      );
    }

    if (daysRemaining <= 1) {
      return DeadlineInfo(
        deadline: deadline,
        daysRemaining: daysRemaining,
        status: DeadlineStatus.atRisk,
        label: '明天到期',
        estimatedCompletionPct: estimated,
      );
    }

    if (daysRemaining <= 3) {
      return DeadlineInfo(
        deadline: deadline,
        daysRemaining: daysRemaining,
        status: DeadlineStatus.atRisk,
        label: '還有 $daysRemaining 天',
        estimatedCompletionPct: estimated,
      );
    }

    return DeadlineInfo(
      deadline: deadline,
      daysRemaining: daysRemaining,
      status: DeadlineStatus.onTrack,
      label: '還有 $daysRemaining 天',
      estimatedCompletionPct: estimated,
    );
  }

  /// Days until deadline (calendar). Null if no deadline.
  int? daysUntilDeadline(Item item, [DateTime? now]) {
    final deadline = item.deadline;
    if (deadline == null) return null;
    final n = now ?? DateTime.now();
    final today = DateTime(n.year, n.month, n.day);
    final due = DateTime(deadline.year, deadline.month, deadline.day);
    return due.difference(today).inDays;
  }

  /// Returns type `deadline_d{n}`, `overdue`, or null.
  /// [offsets] = remaining-day values that should fire (e.g. [7,3,1,0]).
  String? shouldRemind(
    Item item, {
    List<int> offsets = const [3, 1, 0],
    bool includeOverdue = true,
    DateTime? now,
  }) {
    final days = daysUntilDeadline(item, now);
    if (days == null) return null;

    if (days < 0) {
      return includeOverdue ? 'overdue' : null;
    }
    if (offsets.contains(days)) {
      return 'deadline_d$days';
    }
    return null;
  }

  /// Stale = no progress for [staleDays]. Uses lastProgressAt, else createdAt.
  bool isStale(Item item, {int staleDays = 7, DateTime? now}) {
    if (item.status != 'in_progress') return false;
    final anchor = item.lastProgressAt ?? item.createdAt;
    if (anchor == null) return false;
    final n = now ?? DateTime.now();
    return n.difference(anchor).inDays >= staleDays;
  }
}
