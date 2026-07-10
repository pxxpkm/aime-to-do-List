import 'package:acg_todo/data/repositories/folders_repository.dart';
import 'package:acg_todo/domain/entities/folder.dart';
import 'package:acg_todo/presentation/providers/items_provider.dart';
import 'package:acg_todo/presentation/providers/repository_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'folders_provider.g.dart';

/// Sentinel for "uncategorized" filter on home (not a real folder id).
const kFolderFilterUncategorized = '__none__';

@riverpod
class FoldersNotifier extends _$FoldersNotifier {
  @override
  List<Folder> build() {
    return ref.read(foldersRepositoryProvider).getAll();
  }

  FoldersRepository get _repo => ref.read(foldersRepositoryProvider);

  void _refresh() {
    state = _repo.getAll();
  }

  Future<Folder> create(String name, {int? colorValue}) async {
    final folder = await _repo.create(name, colorValue: colorValue);
    _refresh();
    return folder;
  }

  Future<void> rename(String id, String name) async {
    await _repo.rename(id, name);
    _refresh();
  }

  Future<void> delete(String id) async {
    await _repo.delete(id);
    _refresh();
    // Items lost folderId — refresh shelf
    ref.invalidate(itemsNotifierProvider);
  }
}
