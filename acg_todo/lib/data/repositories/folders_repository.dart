import 'package:acg_todo/core/utils/logger.dart';
import 'package:acg_todo/data/local/library_store.dart';
import 'package:acg_todo/domain/entities/folder.dart';
import 'package:acg_todo/domain/entities/system_folders.dart';

class FoldersRepository {
  final LibraryStore _store;

  FoldersRepository(this._store);

  List<Folder> getAll() => _store.getAllFolders();

  Folder? getById(String id) => _store.getFolder(id);

  bool isSystemFolder(String id) => id == SystemFolders.completedId;

  Future<Folder> create(String name, {int? colorValue}) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError('Folder name cannot be empty');
    }
    final folder = Folder(
      id: 'folder_${DateTime.now().microsecondsSinceEpoch}',
      name: trimmed.length > 20 ? trimmed.substring(0, 20) : trimmed,
      sortOrder: _store.nextFolderSortOrder(),
      colorValue: colorValue,
      createdAt: DateTime.now(),
    );
    await _store.putFolder(folder);
    Logger().i('Folder created: ${folder.name}');
    return folder;
  }

  Future<void> rename(String id, String name) async {
    if (isSystemFolder(id)) {
      Logger().w('Cannot rename system folder: $id');
      return;
    }
    final folder = _store.getFolder(id);
    if (folder == null) return;
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    final next = trimmed.length > 20 ? trimmed.substring(0, 20) : trimmed;
    await _store.putFolder(folder.copyWith(name: next));
    Logger().d('Folder renamed: $id → $next');
  }

  /// Deletes folder and clears folderId on all items that used it.
  Future<void> delete(String id) async {
    if (isSystemFolder(id)) {
      Logger().w('Cannot delete system folder: $id');
      return;
    }
    final items = _store.getAllItems();
    for (final item in items) {
      if (item.folderId == id) {
        await _store.putItem(item.copyWith(folderId: null));
      }
    }
    await _store.deleteFolder(id);
    Logger().i('Folder deleted: $id (items uncategorized)');
  }

  Future<void> reorder(List<String> orderedIds) async {
    for (var i = 0; i < orderedIds.length; i++) {
      final folder = _store.getFolder(orderedIds[i]);
      if (folder == null) continue;
      if (folder.sortOrder == i) continue;
      await _store.putFolder(folder.copyWith(sortOrder: i));
    }
  }
}
