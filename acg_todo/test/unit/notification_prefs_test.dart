import 'package:flutter_test/flutter_test.dart';

import 'package:acg_todo/data/local/notification_store.dart';
import 'package:acg_todo/domain/entities/notification.dart';

void main() {
  test('parseNotificationPrefs defaults and roundtrip', () {
    final empty = parseNotificationPrefs(null);
    expect(empty.enabled, isTrue);
    expect(empty.staleDays, 7);
    expect(empty.types, isEmpty);
    expect(empty.lastSeenAt, isNull);

    final raw = encodeNotificationPrefs(
      enabled: false,
      types: {'deadline': false, 'stale': true},
      staleDays: 12,
      lastSeenAt: DateTime.utc(2026, 7, 1, 8),
    );
    final p = parseNotificationPrefs(raw);
    expect(p.enabled, isFalse);
    expect(p.types['deadline'], isFalse);
    expect(p.types['stale'], isTrue);
    expect(p.staleDays, 12);
    expect(p.lastSeenAt?.toUtc(), DateTime.utc(2026, 7, 1, 8));
  });

  test('parseNotificationPrefs clamps staleDays', () {
    final p = parseNotificationPrefs({'staleDays': 99});
    expect(p.staleDays, 30);
  });

  test('notificationWasToday same calendar day only', () {
    final day = DateTime(2026, 7, 17, 10);
    final items = [
      AppNotification(
        id: 'n1',
        itemId: 'i1',
        type: 'stale_7day',
        scheduledAt: day,
        createdAt: day,
        sentAt: day,
      ),
    ];
    expect(notificationWasToday(items, 'i1', 'stale_7day', day), isTrue);
    expect(
      notificationWasToday(
        items,
        'i1',
        'stale_7day',
        day.add(const Duration(days: 1)),
      ),
      isFalse,
    );
    expect(notificationWasToday(items, 'other', 'stale_7day', day), isFalse);
  });
}
