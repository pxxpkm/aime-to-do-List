import 'package:acg_todo/core/utils/logger.dart';
import 'package:acg_todo/data/local/hive_cache.dart';
import 'package:acg_todo/data/local/library_store.dart';
import 'package:acg_todo/domain/entities/folder.dart';
import 'package:acg_todo/domain/entities/item.dart';

/// Hive-backed [LibraryStore] (browser IndexedDB on web).
class HiveLibraryStore implements LibraryStore {
  final HiveCache _cache;

  HiveLibraryStore(this._cache);

  @override
  String get backendId => LibraryBackendIds.hive;

  @override
  Future<void> hydrate() async {
    // HiveCache.init already loaded boxes.
    Logger().d('HiveLibraryStore ready (${_cache.getAllItems().length} items)');
  }

  @override
  List<Item> getAllItems() => _cache.getAllItems();

  @override
  Item? getItem(String id) => _cache.getItem(id);

  @override
  int nextSortOrder() => _cache.nextSortOrder();

  @override
  Future<void> putItem(Item item) => _cache.putItem(item);

  @override
  Future<void> putItems(List<Item> items) => _cache.putItems(items);

  @override
  Future<void> deleteItem(String id) => _cache.deleteItem(id);

  @override
  Future<void> clearAllItems() => _cache.clearAll();

  @override
  List<Folder> getAllFolders() => _cache.getAllFolders();

  @override
  Folder? getFolder(String id) => _cache.getFolder(id);

  @override
  int nextFolderSortOrder() => _cache.nextFolderSortOrder();

  @override
  Future<void> putFolder(Folder folder) => _cache.putFolder(folder);

  @override
  Future<void> putFolders(List<Folder> folders) async {
    for (final f in folders) {
      await _cache.putFolder(f);
    }
  }

  @override
  Future<void> deleteFolder(String id) => _cache.deleteFolder(id);

  @override
  Future<void> replaceLibrary({
    required List<Folder> folders,
    required List<Item> items,
  }) async {
    await _cache.clearAll();
    final existing = _cache.getAllFolders();
    for (final f in existing) {
      if (f.id != 'folder_system_completed') {
        await _cache.deleteFolder(f.id);
      }
    }
    for (final f in folders) {
      await _cache.putFolder(f);
    }
    await _cache.putItems(items);
    await _cache.ensureSystemFolders();
  }

  @override
  Map<String, dynamic> getSettingsBundle() => {};

  @override
  Future<void> putSettingsBundle(Map<String, dynamic> bundle) async {
    // Goals stay in GoalSettingsStore.hive (Box) for this backend.
  }
}
