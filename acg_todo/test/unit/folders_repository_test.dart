import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:acg_todo/data/local/folder_adapter.dart';
import 'package:acg_todo/data/local/goal_settings_store.dart';
import 'package:acg_todo/data/local/hive_cache.dart';
import 'package:acg_todo/data/local/item_adapter.dart';
import 'package:acg_todo/data/repositories/anilist/anilist_client.dart';
import 'package:acg_todo/data/repositories/folders_repository.dart';
import 'package:acg_todo/data/repositories/items_repository.dart';
import 'package:acg_todo/domain/entities/item.dart';

void main() {
  late HiveCache cache;
  late FoldersRepository folders;
  late ItemsRepository items;

  setUp(() async {
    final dir =
        './.dart_tool/test_hive_folders_${DateTime.now().microsecondsSinceEpoch}';
    Hive.init(dir);
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(ItemAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(FolderAdapter());
    }
    cache = HiveCache();
    // Manual open without full init side effects on shared path
    await cache.init();
    folders = FoldersRepository(cache);
    items = ItemsRepository(
      cache,
      AniListClient(),
      GoalSettingsStore(cache.settingsBox),
    );
  });

  tearDown(() async {
    await cache.clearAll();
    await cache.foldersBox.clear();
    await cache.settingsBox.clear();
  });

  test('create folder and move item', () async {
    await items.addItem(const Item(
      id: 'i1',
      userId: 'u',
      type: 'anime',
      title: 'A',
    ));
    final folder = await folders.create('冬番');
    // System「已完成」folder is always present.
    expect(folders.getAll().length, 2);
    expect(folders.getAll().any((f) => f.name == '已完成'), isTrue);

    await items.moveToFolder('i1', folder.id);
    expect(items.getById('i1')?.folderId, folder.id);

    await items.moveToFolder('i1', null);
    expect(items.getById('i1')?.folderId, isNull);
  });

  test('delete folder clears item folderId', () async {
    await items.addItem(const Item(
      id: 'i2',
      userId: 'u',
      type: 'manga',
      title: 'B',
    ));
    final folder = await folders.create('坑中');
    await items.moveToFolder('i2', folder.id);
    await folders.delete(folder.id);

    // User folder gone; system completed folder remains.
    expect(folders.getAll().length, 1);
    expect(folders.getAll().single.name, '已完成');
    expect(items.getById('i2')?.folderId, isNull);
  });
}
