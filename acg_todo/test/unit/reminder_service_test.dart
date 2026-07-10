import 'package:flutter_test/flutter_test.dart';

import 'package:acg_todo/domain/entities/item.dart';
import 'package:acg_todo/domain/services/reminder_service.dart';
import 'package:acg_todo/domain/services/reminder_types.dart';

void main() {
  const service = ReminderService();

  Item item({
    required String id,
    String status = 'in_progress',
    DateTime? deadline,
    DateTime? lastProgressAt,
    DateTime? createdAt,
    String deadlineRemindMode = 'global',
    String? customDeadlineOffsets,
  }) {
    return Item(
      id: id,
      userId: 'u',
      type: 'anime',
      title: id,
      status: status,
      deadline: deadline,
      lastProgressAt: lastProgressAt,
      createdAt: createdAt,
      deadlineRemindMode: deadlineRemindMode,
      customDeadlineOffsets: customDeadlineOffsets,
    );
  }

  test('collects deadline, stale, and daily goal', () {
    final now = DateTime(2026, 7, 10, 12);
    final items = [
      item(
        id: 'due',
        deadline: DateTime(2026, 7, 13), // 3 days
      ),
      item(
        id: 'stale',
        lastProgressAt: now.subtract(const Duration(days: 10)),
      ),
      item(
        id: 'fresh',
        lastProgressAt: now.subtract(const Duration(days: 1)),
      ),
    ];

    final list = service.collect(
      items: items,
      goalUnits: 5,
      todayUnits: 1,
      staleDays: 7,
      globalDeadlineOffsets: const [3, 1, 0],
      includeOverdue: true,
      enabled: (_) => true,
      now: now,
    );

    final types = list.map((e) => e.type).toSet();
    expect(types.contains('deadline_d3'), isTrue);
    expect(types.contains(ReminderTypes.stale), isTrue);
    expect(types.contains(ReminderTypes.dailyGoal), isTrue);
    expect(list.any((e) => e.itemId == 'fresh'), isFalse);
  });

  test('respects enabled flags', () {
    final now = DateTime(2026, 7, 10);
    final items = [
      item(id: 'due', deadline: DateTime(2026, 7, 13)),
      item(
        id: 'stale',
        lastProgressAt: now.subtract(const Duration(days: 10)),
      ),
    ];

    final list = service.collect(
      items: items,
      goalUnits: 5,
      todayUnits: 0,
      staleDays: 7,
      globalDeadlineOffsets: const [3, 1, 0],
      includeOverdue: true,
      enabled: (key) => key == ReminderTypes.settingDailyGoal,
      now: now,
    );

    expect(list.length, 1);
    expect(list.first.type, ReminderTypes.dailyGoal);
  });

  test('no daily goal when already complete', () {
    final list = service.collect(
      items: [],
      goalUnits: 5,
      todayUnits: 5,
      staleDays: 7,
      globalDeadlineOffsets: const [3, 1, 0],
      includeOverdue: true,
      enabled: (_) => true,
    );
    expect(list.where((e) => e.type == ReminderTypes.dailyGoal), isEmpty);
  });
}
