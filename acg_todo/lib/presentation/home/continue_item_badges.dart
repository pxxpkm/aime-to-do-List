import 'package:acg_todo/domain/entities/item.dart';
import 'package:acg_todo/domain/services/deadline_service.dart';

/// Visual risk for continue-strip left accent (null = no accent).
enum ContinueRisk { overdue, atRisk }

/// Pure helpers for continue-strip badges (stale + deadline risk).
class ContinueItemBadges {
  final bool isStale;
  final ContinueRisk? risk;

  const ContinueItemBadges({required this.isStale, this.risk});

  factory ContinueItemBadges.forItem(
    Item item, {
    int staleDays = 7,
    DateTime? now,
    DeadlineService deadline = const DeadlineService(),
  }) {
    final info = deadline.analyze(item);
    ContinueRisk? risk;
    switch (info.status) {
      case DeadlineStatus.overdue:
        risk = ContinueRisk.overdue;
      case DeadlineStatus.atRisk:
        risk = ContinueRisk.atRisk;
      case DeadlineStatus.onTrack:
      case DeadlineStatus.noDeadline:
        risk = null;
    }
    final stale = deadline.isStale(item, staleDays: staleDays, now: now);
    return ContinueItemBadges(isStale: stale, risk: risk);
  }
}
