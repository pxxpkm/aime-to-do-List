import 'package:acg_todo/core/utils/logger.dart';
import 'package:acg_todo/data/local/notification_adapter.dart';
import 'package:acg_todo/data/local/notification_store.dart';
import 'package:acg_todo/domain/entities/notification.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Hive / IndexedDB implementation (browser fallback).
class HiveNotificationStore implements NotificationStore {
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
    Logger().i('Hive notification store initialized');
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

  @override
  List<AppNotification> getAll() {
    final list = _box.values.toList();
    list.sort((a, b) {
      final ac = a.createdAt ?? a.scheduledAt;
      final bc = b.createdAt ?? b.scheduledAt;
      return bc.compareTo(ac);
    });
    return list;
  }

  @override
  List<AppNotification> getUnsent() =>
      _box.values.where((n) => n.sentAt == null).toList();

  @override
  List<AppNotification> getByType(String type) =>
      _box.values.where((n) => n.type == type).toList();

  @override
  Future<void> put(AppNotification notification) async {
    await _box.put(notification.id, notification);
  }

  @override
  Future<void> markSent(String id) async {
    final n = _box.get(id);
    if (n != null) {
      await _box.put(id, n.copyWith(sentAt: DateTime.now()));
    }
  }

  @override
  Future<void> clearAll() async {
    await _box.clear();
  }

  @override
  bool wasNotifiedToday(String itemId, String type, [DateTime? now]) =>
      notificationWasToday(_box.values, itemId, type, now);

  @override
  bool getNotificationEnabled(String type) {
    return _settingsBox.get('notif_$type', defaultValue: true) as bool;
  }

  @override
  Future<void> setNotificationEnabled(String type, bool enabled) async {
    await _settingsBox.put('notif_$type', enabled);
  }

  @override
  bool get notificationsEnabled =>
      _settingsBox.get('notifications_enabled', defaultValue: true) as bool;

  @override
  Future<void> setNotificationsEnabled(bool enabled) async {
    await _settingsBox.put('notifications_enabled', enabled);
  }

  @override
  int get staleDays {
    final v = _settingsBox.get(_staleDaysKey);
    if (v is int && v >= 1 && v <= 30) return v;
    return 7;
  }

  @override
  Future<void> setStaleDays(int days) async {
    await _settingsBox.put(_staleDaysKey, days.clamp(1, 30));
  }

  @override
  DateTime? get lastSeenAt {
    final raw = _settingsBox.get(_lastSeenKey) as String?;
    if (raw == null) return null;
    return DateTime.tryParse(raw);
  }

  @override
  Future<void> setLastSeenNow([DateTime? now]) async {
    await _settingsBox.put(
      _lastSeenKey,
      (now ?? DateTime.now()).toIso8601String(),
    );
  }

  @override
  int unreadCount([DateTime? now]) {
    final seen = lastSeenAt;
    if (seen == null) return _box.length;
    return _box.values.where((n) {
      final t = n.createdAt ?? n.scheduledAt;
      return t.isAfter(seen);
    }).length;
  }

  @override
  Map<String, dynamic> exportPrefs() {
    final types = <String, bool>{};
    for (final key in _settingsBox.keys) {
      if (key is! String || !key.startsWith('notif_')) continue;
      final v = _settingsBox.get(key);
      if (v is bool) types[key.substring(6)] = v;
    }
    return encodeNotificationPrefs(
      enabled: notificationsEnabled,
      types: types,
      staleDays: staleDays,
      lastSeenAt: lastSeenAt,
    );
  }

  @override
  void loadPrefs(Map<String, dynamic>? raw) {
    final p = parseNotificationPrefs(raw);
    _settingsBox.put('notifications_enabled', p.enabled);
    for (final e in p.types.entries) {
      _settingsBox.put('notif_${e.key}', e.value);
    }
    _settingsBox.put(_staleDaysKey, p.staleDays);
    if (p.lastSeenAt != null) {
      _settingsBox.put(_lastSeenKey, p.lastSeenAt!.toIso8601String());
    }
  }

  @override
  bool get isEmptyForMigrate =>
      _box.isEmpty &&
      notificationsEnabled &&
      staleDays == 7 &&
      lastSeenAt == null;
}

/// Backward-compatible name used across the app.
typedef NotificationCache = HiveNotificationStore;
