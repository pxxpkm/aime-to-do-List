import 'package:acg_todo/core/utils/logger.dart';
import 'package:acg_todo/data/local/hive_cache.dart';
import 'package:acg_todo/domain/entities/folder.dart';
import 'package:acg_todo/domain/entities/system_folders.dart';

class FoldersRepository {
  final HiveCache _cache;

  FoldersRepository(this._cache);

  List<Folder> getAll() => _cache.getAllFolders();

  Folder? getById(String id) => _cache.getFolder(id);

  bool isSystemFolder(String id) => id == SystemFolders.completedId;

  Future<Folder> create(String name, {int? colorValue}) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError('Folder name cannot be empty');
    }
    final folder = Folder(
      id: 'folder_${DateTime.now().microsecondsSinceEpoch}',
      name: trimmed.length > 20 ? trimmed.substring(0, 20) : trimmed,
      sortOrder: _cache.nextFolderSortOrder(),
      colorValue: colorValue,
      createdAt: DateTime.now(),
    );
    await _cache.putFolder(folder);
    Logger().i('Folder created: ${folder.name}');
    return folder;
  }

  Future<void> rename(String id, String name) async {
    if (isSystemFolder(id)) {
      Logger().w('Cannot rename system folder: $id');
      return;
    }
    final folder = _cache.getFolder(id);
    if (folder == null) return;
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    final next = trimmed.length > 20 ? trimmed.substring(0, 20) : trimmed;
    await _cache.putFolder(folder.copyWith(name: next));
    Logger().d('Folder renamed: $id → $next');
  }

  /// Deletes folder and clears folderId on all items that used it.
  Future<void> delete(String id) async {
    if (isSystemFolder(id)) {
      Logger().w('Cannot delete system folder: $id');
      return;
    }
    final items = _cache.getAllItems();
    for (final item in items) {
      if (item.folderId == id) {
        await _cache.putItem(item.copyWith(folderId: null));
      }
    }
    await _cache.deleteFolder(id);
    Logger().i('Folder deleted: $id (items uncategorized)');
  }

  Future<void> reorder(List<String> orderedIds) async {
    for (var i = 0; i < orderedIds.length; i++) {
      final folder = _cache.getFolder(orderedIds[i]);
      if (folder == null) continue;
      if (folder.sortOrder == i) continue;
      await _cache.putFolder(folder.copyWith(sortOrder: i));
    }
  }
}
