import 'package:acg_todo/domain/entities/notification.dart';

/// Whether [items] already has a same-day notification for [itemId]+[type].
bool notificationWasToday(
  Iterable<AppNotification> items,
  String itemId,
  String type, [
  DateTime? now,
]) {
  final n = now ?? DateTime.now();
  final today = DateTime(n.year, n.month, n.day);
  return items.any((notif) {
    if (notif.itemId != itemId || notif.type != type) return false;
    final t = notif.sentAt ?? notif.createdAt ?? notif.scheduledAt;
    final d = DateTime(t.year, t.month, t.day);
    return d == today;
  });
}

/// Parse settings.bundle `notifications` prefs map.
({
  bool enabled,
  Map<String, bool> types,
  int staleDays,
  DateTime? lastSeenAt,
}) parseNotificationPrefs(Map<String, dynamic>? raw) {
  var enabled = true;
  final types = <String, bool>{};
  var staleDays = 7;
  DateTime? lastSeenAt;
  if (raw == null) {
    return (
      enabled: enabled,
      types: types,
      staleDays: staleDays,
      lastSeenAt: lastSeenAt,
    );
  }
  final e = raw['enabled'];
  if (e is bool) enabled = e;
  final t = raw['types'];
  if (t is Map) {
    for (final entry in t.entries) {
      final k = entry.key;
      final v = entry.value;
      if (k is String && v is bool) types[k] = v;
    }
  }
  final sd = raw['staleDays'];
  if (sd is int) staleDays = sd.clamp(1, 30);
  final seen = raw['lastSeenAt'];
  if (seen is String && seen.isNotEmpty) {
    lastSeenAt = DateTime.tryParse(seen);
  }
  return (
    enabled: enabled,
    types: types,
    staleDays: staleDays,
    lastSeenAt: lastSeenAt,
  );
}

Map<String, dynamic> encodeNotificationPrefs({
  required bool enabled,
  required Map<String, bool> types,
  required int staleDays,
  DateTime? lastSeenAt,
}) {
  return {
    'enabled': enabled,
    'types': Map<String, bool>.from(types),
    'staleDays': staleDays,
    'lastSeenAt': lastSeenAt?.toIso8601String(),
  };
}

/// Local notification events + prefs (Hive or SQLite server).
abstract class NotificationStore {
  List<AppNotification> getAll();

  List<AppNotification> getUnsent();

  List<AppNotification> getByType(String type);

  Future<void> put(AppNotification notification);

  Future<void> markSent(String id);

  Future<void> clearAll();

  bool wasNotifiedToday(String itemId, String type, [DateTime? now]);

  bool getNotificationEnabled(String type);

  Future<void> setNotificationEnabled(String type, bool enabled);

  bool get notificationsEnabled;

  Future<void> setNotificationsEnabled(bool enabled);

  int get staleDays;

  Future<void> setStaleDays(int days);

  DateTime? get lastSeenAt;

  Future<void> setLastSeenNow([DateTime? now]);

  int unreadCount([DateTime? now]);

  /// Export prefs map for settings.bundle `notifications` key / migrate.
  Map<String, dynamic> exportPrefs();

  /// Load prefs from settings.bundle `notifications` map.
  void loadPrefs(Map<String, dynamic>? raw);

  /// True when no events and prefs are still defaults (for migrate gate).
  bool get isEmptyForMigrate;
}
