import 'package:flutter_test/flutter_test.dart';

import 'package:acg_todo/domain/entities/item.dart';
import 'package:acg_todo/presentation/home/continue_item_badges.dart';

Item _i({
  required String id,
  String status = 'in_progress',
  DateTime? deadline,
  DateTime? lastProgressAt,
  DateTime? createdAt,
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
  );
}

void main() {
  final now = DateTime(2026, 7, 25, 12);

  test('stale when no progress for >= staleDays', () {
    final item = _i(
      id: 's',
      lastProgressAt: now.subtract(const Duration(days: 8)),
    );
    final b = ContinueItemBadges.forItem(item, staleDays: 7, now: now);
    expect(b.isStale, isTrue);
  });

  test('not stale within window', () {
    final item = _i(
      id: 'f',
      lastProgressAt: now.subtract(const Duration(days: 2)),
    );
    final b = ContinueItemBadges.forItem(item, staleDays: 7, now: now);
    expect(b.isStale, isFalse);
  });

  test('overdue risk', () {
    final item = _i(
      id: 'o',
      deadline: now.subtract(const Duration(days: 2)),
      lastProgressAt: now,
    );
    final b = ContinueItemBadges.forItem(item, now: now);
    expect(b.risk, ContinueRisk.overdue);
  });

  test('atRisk within 3 days', () {
    final item = _i(
      id: 'r',
      deadline: now.add(const Duration(days: 2)),
      lastProgressAt: now,
    );
    final b = ContinueItemBadges.forItem(item, now: now);
    expect(b.risk, ContinueRisk.atRisk);
  });

  test('no risk without deadline and not stale', () {
    final item = _i(
      id: 'ok',
      lastProgressAt: now.subtract(const Duration(days: 1)),
    );
    final b = ContinueItemBadges.forItem(item, staleDays: 7, now: now);
    expect(b.risk, isNull);
    expect(b.isStale, isFalse);
  });
}
