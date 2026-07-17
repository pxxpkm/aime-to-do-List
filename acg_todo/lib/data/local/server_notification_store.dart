import 'dart:convert';

import 'package:acg_todo/core/utils/logger.dart';
import 'package:acg_todo/data/local/library_store.dart';
import 'package:acg_todo/data/local/notification_store.dart';
import 'package:acg_todo/domain/entities/notification.dart';
import 'package:http/http.dart' as http;

/// In-memory notifications synced to SQLite API + settings.bundle prefs.
class ServerNotificationStore implements NotificationStore {
  final String baseUrl;
  final LibraryStore libraryStore;
  final http.Client _client;

  final Map<String, AppNotification> _byId = {};
  bool _notificationsEnabled = true;
  final Map<String, bool> _typeEnabled = {};
  int _staleDays = 7;
  DateTime? _lastSeenAt;

  ServerNotificationStore({
    required this.baseUrl,
    required this.libraryStore,
    http.Client? client,
  }) : _client = client ?? http.Client();

  Uri _u(String path) => Uri.parse(baseUrl).resolve(path);

  Future<Map<String, dynamic>> _jsonMap(
    String method,
    String path, {
    Object? body,
  }) async {
    final uri = _u(path);
    late final http.Response res;
    final headers = {'Content-Type': 'application/json; charset=utf-8'};
    final encoded = body == null ? null : jsonEncode(body);
    switch (method) {
      case 'GET':
        res = await _client.get(uri).timeout(const Duration(seconds: 15));
      case 'PUT':
        res = await _client
            .put(uri, headers: headers, body: encoded)
            .timeout(const Duration(seconds: 15));
      case 'DELETE':
        res = await _client.delete(uri).timeout(const Duration(seconds: 15));
      default:
        throw StateError('Unsupported method $method');
    }
    if (res.statusCode >= 400) {
      var msg = 'HTTP ${res.statusCode} $path';
      try {
        final err = jsonDecode(res.body);
        if (err is Map && err['error'] != null) {
          msg = err['error'].toString();
        }
      } catch (_) {}
      throw StateError(msg);
    }
    if (res.body.isEmpty) return {};
    final decoded = jsonDecode(res.body);
    if (decoded is Map<String, dynamic>) return decoded;
    if (decoded is Map) return Map<String, dynamic>.from(decoded);
    return {};
  }

  Future<void> hydrate() async {
    final data = await _jsonMap('GET', '/api/v1/notifications');
    _byId.clear();
    final list = data['notifications'];
    if (list is List) {
      for (final e in list) {
        if (e is! Map) continue;
        try {
          final n = AppNotification.fromJson(Map<String, dynamic>.from(e));
          _byId[n.id] = n;
        } catch (err) {
          Logger().w('Skip bad notification payload: $err');
        }
      }
    }
    final bundle = libraryStore.getSettingsBundle();
    final prefs = bundle['notifications'];
    if (prefs is Map) {
      loadPrefs(Map<String, dynamic>.from(prefs));
    }
    Logger().i('Server notifications hydrated (${_byId.length})');
  }

  Future<void> _flushEvents() async {
    final items = getAll().map((n) => n.toJson()).toList();
    await _jsonMap(
      'PUT',
      '/api/v1/notifications',
      body: {'notifications': items},
    );
  }

  Future<void> _flushPrefs() async {
    final bundle = Map<String, dynamic>.from(libraryStore.getSettingsBundle());
    bundle['notifications'] = exportPrefs();
    await libraryStore.putSettingsBundle(bundle);
  }

  @override
  List<AppNotification> getAll() {
    final list = _byId.values.toList();
    list.sort((a, b) {
      final ac = a.createdAt ?? a.scheduledAt;
      final bc = b.createdAt ?? b.scheduledAt;
      return bc.compareTo(ac);
    });
    return list;
  }

  @override
  List<AppNotification> getUnsent() =>
      _byId.values.where((n) => n.sentAt == null).toList();

  @override
  List<AppNotification> getByType(String type) =>
      _byId.values.where((n) => n.type == type).toList();

  @override
  Future<void> put(AppNotification notification) async {
    _byId[notification.id] = notification;
    await _flushEvents();
  }

  @override
  Future<void> markSent(String id) async {
    final n = _byId[id];
    if (n == null) return;
    _byId[id] = n.copyWith(sentAt: DateTime.now());
    await _flushEvents();
  }

  @override
  Future<void> clearAll() async {
    _byId.clear();
    await _jsonMap('DELETE', '/api/v1/notifications');
  }

  @override
  bool wasNotifiedToday(String itemId, String type, [DateTime? now]) =>
      notificationWasToday(_byId.values, itemId, type, now);

  @override
  bool getNotificationEnabled(String type) => _typeEnabled[type] ?? true;

  @override
  Future<void> setNotificationEnabled(String type, bool enabled) async {
    _typeEnabled[type] = enabled;
    await _flushPrefs();
  }

  @override
  bool get notificationsEnabled => _notificationsEnabled;

  @override
  Future<void> setNotificationsEnabled(bool enabled) async {
    _notificationsEnabled = enabled;
    await _flushPrefs();
  }

  @override
  int get staleDays => _staleDays;

  @override
  Future<void> setStaleDays(int days) async {
    _staleDays = days.clamp(1, 30);
    await _flushPrefs();
  }

  @override
  DateTime? get lastSeenAt => _lastSeenAt;

  @override
  Future<void> setLastSeenNow([DateTime? now]) async {
    _lastSeenAt = now ?? DateTime.now();
    await _flushPrefs();
  }

  @override
  int unreadCount([DateTime? now]) {
    final seen = _lastSeenAt;
    if (seen == null) return _byId.length;
    return _byId.values.where((n) {
      final t = n.createdAt ?? n.scheduledAt;
      return t.isAfter(seen);
    }).length;
  }

  @override
  Map<String, dynamic> exportPrefs() => encodeNotificationPrefs(
        enabled: _notificationsEnabled,
        types: _typeEnabled,
        staleDays: _staleDays,
        lastSeenAt: _lastSeenAt,
      );

  @override
  void loadPrefs(Map<String, dynamic>? raw) {
    final p = parseNotificationPrefs(raw);
    _notificationsEnabled = p.enabled;
    _typeEnabled
      ..clear()
      ..addAll(p.types);
    _staleDays = p.staleDays;
    _lastSeenAt = p.lastSeenAt;
  }

  @override
  bool get isEmptyForMigrate =>
      _byId.isEmpty &&
      _notificationsEnabled &&
      _typeEnabled.isEmpty &&
      _staleDays == 7 &&
      _lastSeenAt == null;

  /// Replace all events (used by Hive → disk migrate).
  Future<void> replaceAll(List<AppNotification> items) async {
    _byId
      ..clear()
      ..addEntries(items.map((n) => MapEntry(n.id, n)));
    await _flushEvents();
  }
}
