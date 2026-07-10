import 'package:acg_todo/core/utils/logger.dart';
import 'package:acg_todo/core/utils/poster_url.dart';
import 'package:acg_todo/domain/entities/folder.dart';
import 'package:acg_todo/domain/entities/item.dart';
import 'package:acg_todo/domain/entities/system_folders.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'folder_adapter.dart';
import 'item_adapter.dart';

class HiveCache {
  static const String itemsBoxName = 'items';
  static const String settingsBoxName = 'settings';
  static const String foldersBoxName = 'folders';

  late Box<Item> _itemsBox;
  late Box _settingsBox;
  late Box<Folder> _foldersBox;

  Future<void> init() async {
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(ItemAdapter());
    }
    // FolderAdapter.typeId = 2 (1 is NotificationAdapter)
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(FolderAdapter());
    }
    _itemsBox = await Hive.openBox<Item>(itemsBoxName);
    _settingsBox = await Hive.openBox(settingsBoxName);
    _foldersBox = await _openFoldersBoxSafe();
    await repairPosterUrls();
    await ensureSortOrders();
    await ensureSystemFolders();
    Logger().i('Hive cache initialized');
  }

  Future<void> ensureSystemFolders() async {
    final id = SystemFolders.completedId;
    if (_foldersBox.get(id) != null) return;
    await _foldersBox.put(
      id,
      Folder(
        id: id,
        name: SystemFolders.completedName,
        sortOrder: 9999,
        colorValue: 0xFF4ade80,
        createdAt: DateTime.now(),
      ),
    );
    Logger().i('System folder created: ${SystemFolders.completedName}');
  }

  /// Old builds stored Folder with typeId=1; reading throws unknown typeId.
  /// Recreate empty folders box so the app still starts (items kept).
  Future<Box<Folder>> _openFoldersBoxSafe() async {
    try {
      final box = await Hive.openBox<Folder>(foldersBoxName);
      // Touch values so corrupt typeIds fail here, not later in UI.
      box.values.toList();
      return box;
    } catch (e, st) {
      Logger().w('Folders box unreadable ($e), recreating empty box');
      Logger().w('$st');
      try {
        if (Hive.isBoxOpen(foldersBoxName)) {
          await Hive.box(foldersBoxName).close();
        }
      } catch (_) {}
      try {
        await Hive.deleteBoxFromDisk(foldersBoxName);
      } catch (e2) {
        Logger().w('deleteBoxFromDisk folders failed: $e2');
      }
      return Hive.openBox<Folder>(foldersBoxName);
    }
  }

  Future<int> repairPosterUrls() async {
    var fixed = 0;
    for (final item in _itemsBox.values.toList()) {
      final normalized = normalizePosterUrl(item.posterUrl);
      if (normalized != item.posterUrl) {
        await _itemsBox.put(item.id, item.copyWith(posterUrl: normalized));
        fixed++;
      }
    }
    if (fixed > 0) {
      Logger().i('Repaired $fixed poster URL(s) (https / large cover)');
    }
    return fixed;
  }

  Future<int> ensureSortOrders() async {
    final items = _itemsBox.values.toList();
    if (items.isEmpty) return 0;
    if (items.any((i) => i.sortOrder != 0)) return 0;

    items.sort((a, b) {
      final ac = a.createdAt;
      final bc = b.createdAt;
      if (ac == null && bc == null) return a.id.compareTo(b.id);
      if (ac == null) return 1;
      if (bc == null) return -1;
      return ac.compareTo(bc);
    });

    for (var i = 0; i < items.length; i++) {
      await _itemsBox.put(items[i].id, items[i].copyWith(sortOrder: i));
    }
    Logger().i('Assigned sortOrder for ${items.length} item(s)');
    return items.length;
  }

  // ── Items CRUD ──

  List<Item> getAllItems() {
    final list = _itemsBox.values.toList();
    list.sort((a, b) {
      final c = a.sortOrder.compareTo(b.sortOrder);
      if (c != 0) return c;
      return a.id.compareTo(b.id);
    });
    return list;
  }

  List<Item> getItemsByType(String type) =>
      getAllItems().where((i) => i.type == type).toList();

  Item? getItem(String id) => _itemsBox.get(id);

  int nextSortOrder() {
    if (_itemsBox.isEmpty) return 0;
    var max = 0;
    for (final item in _itemsBox.values) {
      if (item.sortOrder > max) max = item.sortOrder;
    }
    return max + 1;
  }

  Future<void> putItem(Item item) async {
    final stored = item.copyWith(posterUrl: normalizePosterUrl(item.posterUrl));
    await _itemsBox.put(stored.id, stored);
    Logger().d('Item cached: ${stored.id}');
  }

  Future<void> putItems(List<Item> items) async {
    final map = {
      for (var i in items)
        i.id: i.copyWith(posterUrl: normalizePosterUrl(i.posterUrl)),
    };
    await _itemsBox.putAll(map);
  }

  Future<void> deleteItem(String id) async {
    await _itemsBox.delete(id);
  }

  Future<void> clearAll() async {
    await _itemsBox.clear();
  }

  // ── Folders CRUD ──

  List<Folder> getAllFolders() {
    final list = _foldersBox.values.toList();
    list.sort((a, b) {
      final c = a.sortOrder.compareTo(b.sortOrder);
      if (c != 0) return c;
      return a.id.compareTo(b.id);
    });
    return list;
  }

  Folder? getFolder(String id) => _foldersBox.get(id);

  int nextFolderSortOrder() {
    if (_foldersBox.isEmpty) return 0;
    var max = 0;
    for (final f in _foldersBox.values) {
      if (f.sortOrder > max) max = f.sortOrder;
    }
    return max + 1;
  }

  Future<void> putFolder(Folder folder) async {
    await _foldersBox.put(folder.id, folder);
  }

  Future<void> deleteFolder(String id) async {
    await _foldersBox.delete(id);
  }

  Box<Item> get itemsBox => _itemsBox;
  Box get settingsBox => _settingsBox;
  Box<Folder> get foldersBox => _foldersBox;
}

final hiveCacheProvider = Provider<HiveCache>((ref) {
  throw UnimplementedError('Override in ProviderScope');
});
