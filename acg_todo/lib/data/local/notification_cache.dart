import 'package:acg_todo/core/utils/logger.dart';
import 'package:acg_todo/domain/entities/notification.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'notification_adapter.dart';

class NotificationCache {
  static const String boxName = 'notifications';
  static const String settingsBoxName = 'settings';

  static const _staleDaysKey = 'stale_days';
  static const _lastSeenKey = 'last_notifications_seen_at';

  late Box<AppNotification> _box;
  late Box _settingsBox;

  Future<void> init() async {
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(NotificationAdapter());
    }
    _box = await _openNotificationsBoxSafe();
    _settingsBox = await Hive.openBox(settingsBoxName);
    Logger().i('Notification cache initialized');
  }

  Future<Box<AppNotification>> _openNotificationsBoxSafe() async {
    try {
      final box = await Hive.openBox<AppNotification>(boxName);
      box.values.toList();
      return box;
    } catch (e, st) {
      Logger().w('Notifications box unreadable ($e), recreating');
      Logger().w('$st');
      try {
        if (Hive.isBoxOpen(boxName)) {
          await Hive.box(boxName).close();
        }
      } catch (_) {}
      try {
        await Hive.deleteBoxFromDisk(boxName);
      } catch (_) {}
      return Hive.openBox<AppNotification>(boxName);
    }
  }

  List<AppNotification> getAll() {
    final list = _box.values.toList();
    list.sort((a, b) {
      final ac = a.createdAt ?? a.scheduledAt;
      final bc = b.createdAt ?? b.scheduledAt;
      return bc.compareTo(ac);
    });
    return list;
  }

  List<AppNotification> getUnsent() =>
      _box.values.where((n) => n.sentAt == null).toList();

  List<AppNotification> getByType(String type) =>
      _box.values.where((n) => n.type == type).toList();

  Future<void> put(AppNotification notification) async {
    await _box.put(notification.id, notification);
  }

  Future<void> markSent(String id) async {
    final n = _box.get(id);
    if (n != null) {
      await _box.put(id, n.copyWith(sentAt: DateTime.now()));
    }
  }

  Future<void> clearAll() async {
    await _box.clear();
  }

  bool wasNotifiedToday(String itemId, String type, [DateTime? now]) {
    final n = now ?? DateTime.now();
    final today = DateTime(n.year, n.month, n.day);
    return _box.values.any((notif) {
      if (notif.itemId != itemId || notif.type != type) return false;
      final t = notif.sentAt ?? notif.createdAt ?? notif.scheduledAt;
      final d = DateTime(t.year, t.month, t.day);
      return d == today;
    });
  }

  // ── Settings ──

  bool getNotificationEnabled(String type) {
    return _settingsBox.get('notif_$type', defaultValue: true) as bool;
  }

  Future<void> setNotificationEnabled(String type, bool enabled) async {
    await _settingsBox.put('notif_$type', enabled);
  }

  bool get notificationsEnabled =>
      _settingsBox.get('notifications_enabled', defaultValue: true) as bool;

  Future<void> setNotificationsEnabled(bool enabled) async {
    await _settingsBox.put('notifications_enabled', enabled);
  }

  int get staleDays {
    final v = _settingsBox.get(_staleDaysKey);
    if (v is int && v >= 1 && v <= 30) return v;
    return 7;
  }

  Future<void> setStaleDays(int days) async {
    await _settingsBox.put(_staleDaysKey, days.clamp(1, 30));
  }

  DateTime? get lastSeenAt {
    final raw = _settingsBox.get(_lastSeenKey) as String?;
    if (raw == null) return null;
    return DateTime.tryParse(raw);
  }

  Future<void> setLastSeenNow([DateTime? now]) async {
    await _settingsBox.put(
      _lastSeenKey,
      (now ?? DateTime.now()).toIso8601String(),
    );
  }

  int unreadCount([DateTime? now]) {
    final seen = lastSeenAt;
    if (seen == null) return _box.length;
    return _box.values.where((n) {
      final t = n.createdAt ?? n.scheduledAt;
      return t.isAfter(seen);
    }).length;
  }
}
