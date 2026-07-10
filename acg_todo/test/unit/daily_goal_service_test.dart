import 'package:flutter_test/flutter_test.dart';

import 'package:acg_todo/domain/entities/item.dart';
import 'package:acg_todo/domain/services/daily_goal_service.dart';

void main() {
  const service = DailyGoalService();

  Item item({
    required String id,
    int sortOrder = 0,
    String status = 'in_progress',
    DateTime? deadline,
    DateTime? lastProgressAt,
  }) {
    return Item(
      id: id,
      userId: 'u',
      type: 'anime',
      title: id,
      sortOrder: sortOrder,
      status: status,
      deadline: deadline,
      lastProgressAt: lastProgressAt,
    );
  }

  test('suggest prefers urgent deadline over stale', () {
    final now = DateTime(2026, 7, 10);
    final items = [
      item(
        id: 'stale',
        sortOrder: 0,
        lastProgressAt: now.subtract(const Duration(days: 10)),
      ),
      item(
        id: 'due',
        sortOrder: 5,
        deadline: now.add(const Duration(days: 1)),
        lastProgressAt: now,
      ),
      item(id: 'done', status: 'completed'),
    ];

    final suggestions = service.suggest(items, now: now, limit: 2);
    expect(suggestions.map((e) => e.id).toList(), ['due', 'stale']);
  });

  test('build snapshot progress and complete flag', () {
    final snap = service.build(
      items: [item(id: 'a')],
      goalUnits: 5,
      todayUnits: 5,
    );
    expect(snap.isComplete, isTrue);
    expect(snap.progress, 1.0);
    expect(snap.remaining, 0);
  });

  test('ignores non in_progress for suggestions', () {
    final suggestions = service.suggest([
      item(id: 'p', status: 'paused'),
      item(id: 'c', status: 'completed'),
    ]);
    expect(suggestions, isEmpty);
  });
}
