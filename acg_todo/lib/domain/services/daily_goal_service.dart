import 'package:acg_todo/domain/entities/item.dart';

class DailyGoalSnapshot {
  final int goalUnits;
  final int todayUnits;
  final List<Item> suggestions;

  const DailyGoalSnapshot({
    required this.goalUnits,
    required this.todayUnits,
    required this.suggestions,
  });

  double get progress =>
      goalUnits <= 0 ? 0 : (todayUnits / goalUnits).clamp(0.0, 1.0);

  bool get isComplete => todayUnits >= goalUnits;

  int get remaining => (goalUnits - todayUnits).clamp(0, goalUnits);
}

class DailyGoalService {
  const DailyGoalService();

  DailyGoalSnapshot build({
    required List<Item> items,
    required int goalUnits,
    required int todayUnits,
    DateTime? now,
  }) {
    return DailyGoalSnapshot(
      goalUnits: goalUnits,
      todayUnits: todayUnits,
      suggestions: suggest(items, now: now, limit: 2),
    );
  }

  /// Priority: urgent deadline → stale progress → sortOrder.
  List<Item> suggest(
    List<Item> items, {
    DateTime? now,
    int limit = 2,
  }) {
    final n = now ?? DateTime.now();
    final active = items
        .where((i) => i.status == 'in_progress')
        .toList();

    active.sort((a, b) {
      final sa = _score(a, n);
      final sb = _score(b, n);
      final c = sb.compareTo(sa);
      if (c != 0) return c;
      return a.sortOrder.compareTo(b.sortOrder);
    });

    if (active.length <= limit) return active;
    return active.sublist(0, limit);
  }

  double _score(Item item, DateTime now) {
    var score = 0.0;

    final deadline = item.deadline;
    if (deadline != null) {
      final days = DateTime(deadline.year, deadline.month, deadline.day)
          .difference(DateTime(now.year, now.month, now.day))
          .inDays;
      if (days <= 0) {
        score += 1000;
      } else if (days <= 3) {
        score += 500 - days * 50;
      }
    }

    final last = item.lastProgressAt;
    if (last == null) {
      score += 80;
    } else {
      final staleDays = now.difference(last).inDays;
      if (staleDays >= 7) {
        score += 120;
      } else if (staleDays >= 3) {
        score += 60;
      }
    }

    // Prefer earlier shelf order slightly
    score += (1000 - item.sortOrder).clamp(0, 100) * 0.01;
    return score;
  }
}
