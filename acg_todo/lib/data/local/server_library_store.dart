import 'dart:convert';

import 'package:acg_todo/core/utils/logger.dart';
import 'package:acg_todo/core/utils/poster_url.dart';
import 'package:acg_todo/data/local/library_store.dart';
import 'package:acg_todo/domain/entities/folder.dart';
import 'package:acg_todo/domain/entities/item.dart';
import 'package:acg_todo/domain/entities/system_folders.dart';
import 'package:http/http.dart' as http;

/// In-memory library synced to local SQLite API (S1).
class ServerLibraryStore implements LibraryStore {
  final String baseUrl;
  final http.Client _client;

  final Map<String, Item> _items = {};
  final Map<String, Folder> _folders = {};
  Map<String, dynamic> _settings = {};
  bool _hydrated = false;

  ServerLibraryStore({
    required this.baseUrl,
    http.Client? client,
  }) : _client = client ?? http.Client();

  @override
  String get backendId => LibraryBackendIds.server;

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
        throw LibraryStoreException('Unsupported method $method');
    }
    if (res.statusCode >= 400) {
      var msg = 'HTTP ${res.statusCode} $path';
      try {
        final err = jsonDecode(res.body);
        if (err is Map && err['error'] != null) {
          msg = err['error'].toString();
        }
      } catch (_) {}
      throw LibraryStoreException(msg);
    }
    if (res.body.isEmpty) return {};
    final decoded = jsonDecode(res.body);
    if (decoded is Map<String, dynamic>) return decoded;
    if (decoded is Map) return Map<String, dynamic>.from(decoded);
    return {};
  }

  @override
  Future<void> hydrate() async {
    final data = await _jsonMap('GET', '/api/v1/library');
    _items.clear();
    _folders.clear();

    final folders = data['folders'];
    if (folders is List) {
      for (final e in folders) {
        if (e is! Map) continue;
        final f = Folder.fromJson(Map<String, dynamic>.from(e));
        _folders[f.id] = f;
      }
    }
    final items = data['items'];
    if (items is List) {
      for (final e in items) {
        if (e is! Map) continue;
        final item = Item.fromJson(Map<String, dynamic>.from(e));
        final normalized = item.copyWith(
          posterUrl: normalizePosterUrl(item.posterUrl),
        );
        _items[normalized.id] = normalized;
      }
    }
    if (!_folders.containsKey(SystemFolders.completedId)) {
      _folders[SystemFolders.completedId] = Folder(
        id: SystemFolders.completedId,
        name: SystemFolders.completedName,
        sortOrder: 9999,
        colorValue: 0xFF4ade80,
        createdAt: DateTime.now(),
      );
    }
    final settings = data['settings'];
    if (settings is Map) {
      _settings = Map<String, dynamic>.from(settings);
    } else {
      _settings = {};
    }
    _hydrated = true;
    Logger().i(
      'ServerLibraryStore hydrated: ${_items.length} items, '
      '${_folders.length} folders @ $baseUrl',
    );
  }

  void _ensureHydrated() {
    if (!_hydrated) {
      throw LibraryStoreException('ServerLibraryStore not hydrated');
    }
  }

  @override
  List<Item> getAllItems() {
    _ensureHydrated();
    final list = _items.values.toList();
    list.sort((a, b) {
      final c = a.sortOrder.compareTo(b.sortOrder);
      if (c != 0) return c;
      return a.id.compareTo(b.id);
    });
    return list;
  }

  @override
  Item? getItem(String id) {
    _ensureHydrated();
    return _items[id];
  }

  @override
  int nextSortOrder() {
    _ensureHydrated();
    if (_items.isEmpty) return 0;
    var max = 0;
    for (final i in _items.values) {
      if (i.sortOrder > max) max = i.sortOrder;
    }
    return max + 1;
  }

  @override
  Future<void> putItem(Item item) async {
    _ensureHydrated();
    final stored = item.copyWith(posterUrl: normalizePosterUrl(item.posterUrl));
    await _jsonMap('PUT', '/api/v1/items/${Uri.encodeComponent(stored.id)}',
        body: stored.toJson());
    _items[stored.id] = stored;
  }

  @override
  Future<void> putItems(List<Item> items) async {
    _ensureHydrated();
    if (items.isEmpty) return;
    final normalized = items
        .map((i) => i.copyWith(posterUrl: normalizePosterUrl(i.posterUrl)))
        .toList();
    await _jsonMap(
      'PUT',
      '/api/v1/items:batch',
      body: {
        'items': normalized.map((i) => i.toJson()).toList(),
      },
    );
    for (final i in normalized) {
      _items[i.id] = i;
    }
  }

  @override
  Future<void> putFolders(List<Folder> folders) async {
    _ensureHydrated();
    if (folders.isEmpty) return;
    await _jsonMap(
      'PUT',
      '/api/v1/folders:batch',
      body: {
        'folders': folders.map((f) => f.toJson()).toList(),
      },
    );
    for (final f in folders) {
      _folders[f.id] = f;
    }
  }

  @override
  Future<void> deleteItem(String id) async {
    _ensureHydrated();
    await _jsonMap('DELETE', '/api/v1/items/${Uri.encodeComponent(id)}');
    _items.remove(id);
  }

  @override
  Future<void> clearAllItems() async {
    _ensureHydrated();
    final ids = _items.keys.toList();
    for (final id in ids) {
      await deleteItem(id);
    }
  }

  @override
  List<Folder> getAllFolders() {
    _ensureHydrated();
    final list = _folders.values.toList();
    list.sort((a, b) {
      final c = a.sortOrder.compareTo(b.sortOrder);
      if (c != 0) return c;
      return a.id.compareTo(b.id);
    });
    return list;
  }

  @override
  Folder? getFolder(String id) {
    _ensureHydrated();
    return _folders[id];
  }

  @override
  int nextFolderSortOrder() {
    _ensureHydrated();
    if (_folders.isEmpty) return 0;
    var max = 0;
    for (final f in _folders.values) {
      if (f.sortOrder > max) max = f.sortOrder;
    }
    return max + 1;
  }

  @override
  Future<void> putFolder(Folder folder) async {
    _ensureHydrated();
    await _jsonMap(
      'PUT',
      '/api/v1/folders/${Uri.encodeComponent(folder.id)}',
      body: folder.toJson(),
    );
    _folders[folder.id] = folder;
  }

  @override
  Future<void> deleteFolder(String id) async {
    _ensureHydrated();
    await _jsonMap('DELETE', '/api/v1/folders/${Uri.encodeComponent(id)}');
    _folders.remove(id);
    // Mirror server: clear folderId on items in memory
    for (final e in _items.entries.toList()) {
      final item = e.value;
      if (item.folderId == id || item.previousFolderId == id) {
        _items[e.key] = item.copyWith(
          folderId: item.folderId == id ? null : item.folderId,
          previousFolderId:
              item.previousFolderId == id ? null : item.previousFolderId,
        );
      }
    }
  }

  @override
  Future<void> replaceLibrary({
    required List<Folder> folders,
    required List<Item> items,
  }) async {
    _ensureHydrated();
    final body = {
      'format': 'acg_todo_backup',
      'version': 1,
      'folders': folders.map((f) => f.toJson()).toList(),
      'items': items
          .map((i) => i
              .copyWith(posterUrl: normalizePosterUrl(i.posterUrl))
              .toJson())
          .toList(),
    };
    await _jsonMap('PUT', '/api/v1/library', body: body);
    await hydrate();
  }

  @override
  Map<String, dynamic> getSettingsBundle() {
    _ensureHydrated();
    return Map<String, dynamic>.from(_settings);
  }

  @override
  Future<void> putSettingsBundle(Map<String, dynamic> bundle) async {
    _ensureHydrated();
    await _jsonMap('PUT', '/api/v1/settings', body: bundle);
    _settings = Map<String, dynamic>.from(bundle);
  }
}
