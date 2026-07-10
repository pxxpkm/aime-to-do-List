import 'package:flutter_test/flutter_test.dart';

import 'package:acg_todo/domain/entities/item.dart';
import 'package:acg_todo/domain/services/deadline_service.dart';

void main() {
  group('DeadlineService', () {
    late DeadlineService service;

    setUp(() {
      service = DeadlineService();
    });

    final baseItem = Item(
      id: 'test_1',
      userId: 'user_1',
      type: 'anime',
      title: 'Test',
      totalUnits: 12,
      currentUnits: 6,
      unitLabel: '集',
    );

    test('returns noDeadline when deadline is null', () {
      final item = baseItem.copyWith(deadline: null);
      final info = service.analyze(item);

      expect(info.status, DeadlineStatus.noDeadline);
      expect(info.daysRemaining, isNull);
      expect(info.label, '無期限');
    });

    test('returns overdue when deadline is in the past', () {
      final item = baseItem.copyWith(
        deadline: DateTime.now().subtract(const Duration(days: 2)),
      );
      final info = service.analyze(item);

      expect(info.status, DeadlineStatus.overdue);
      expect(info.label, contains('逾期'));
    });

    test('returns atRisk when deadline is within 3 days', () {
      final item = baseItem.copyWith(
        deadline: DateTime.now().add(const Duration(days: 2)),
      );
      final info = service.analyze(item);

      expect(info.status, DeadlineStatus.atRisk);
    });

    test('returns onTrack when deadline is more than 3 days away', () {
      final item = baseItem.copyWith(
        deadline: DateTime.now().add(const Duration(days: 10)),
      );
      final info = service.analyze(item);

      expect(info.status, DeadlineStatus.onTrack);
    });

    test('shouldRemind returns correct notification type', () {
      // Use noon anchors so inDays is stable vs wall-clock drift.
      final todayNoon = DateTime(
        DateTime.now().year,
        DateTime.now().month,
        DateTime.now().day,
        12,
      );
      expect(
        service.shouldRemind(baseItem.copyWith(
          deadline: todayNoon.add(const Duration(days: 3)),
        )),
        'deadline_d3',
      );
      expect(
        service.shouldRemind(baseItem.copyWith(
          deadline: todayNoon.add(const Duration(days: 1)),
        )),
        'deadline_d1',
      );
      expect(
        service.shouldRemind(baseItem.copyWith(
          deadline: todayNoon,
        )),
        'deadline_d0',
      );
      expect(
        service.shouldRemind(baseItem.copyWith(deadline: null)),
        isNull,
      );
      expect(
        service.shouldRemind(baseItem.copyWith(
          deadline: DateTime.now().add(const Duration(days: 7)),
        )),
        isNull,
      );
    });

    test('isStale returns true when item is old and in_progress', () {
      final item = baseItem.copyWith(
        createdAt: DateTime.now().subtract(const Duration(days: 10)),
        status: 'in_progress',
      );

      expect(service.isStale(item), isTrue);
    });

    test('isStale returns false when item is recently created', () {
      final item = baseItem.copyWith(
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        status: 'in_progress',
      );

      expect(service.isStale(item), isFalse);
    });

    test('isStale uses lastProgressAt over createdAt', () {
      final item = baseItem.copyWith(
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
        lastProgressAt: DateTime.now().subtract(const Duration(days: 1)),
        status: 'in_progress',
      );
      expect(service.isStale(item), isFalse);
    });

    test('isStale false when completed', () {
      final item = baseItem.copyWith(
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
        status: 'completed',
      );
      expect(service.isStale(item), isFalse);
    });
  });
}
