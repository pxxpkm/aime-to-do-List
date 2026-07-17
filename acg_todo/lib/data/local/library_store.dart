import 'package:acg_todo/domain/entities/folder.dart';
import 'package:acg_todo/domain/entities/item.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Backend id for UI / diagnostics.
abstract class LibraryBackendIds {
  static const hive = 'hive';
  static const server = 'server';
}

/// Item + folder persistence. Reads are sync after [hydrate].
abstract class LibraryStore {
  String get backendId;

  Future<void> hydrate();

  List<Item> getAllItems();
  Item? getItem(String id);
  int nextSortOrder();
  Future<void> putItem(Item item);
  Future<void> putItems(List<Item> items);
  Future<void> deleteItem(String id);
  Future<void> clearAllItems();

  List<Folder> getAllFolders();
  Folder? getFolder(String id);
  int nextFolderSortOrder();
  Future<void> putFolder(Folder folder);
  Future<void> putFolders(List<Folder> folders);
  Future<void> deleteFolder(String id);

  /// Full replace of items + folders (import replace / server PUT library).
  Future<void> replaceLibrary({
    required List<Folder> folders,
    required List<Item> items,
  });

  /// Goals/UI/progressDays bundle (server mode). Hive store may return {}.
  Map<String, dynamic> getSettingsBundle();

  Future<void> putSettingsBundle(Map<String, dynamic> bundle);
}

class LibraryStoreException implements Exception {
  final String message;
  LibraryStoreException(this.message);
  @override
  String toString() => message;
}

final libraryStoreProvider = Provider<LibraryStore>((ref) {
  throw UnimplementedError('Override libraryStoreProvider in ProviderScope');
});
