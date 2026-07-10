import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:acg_todo/data/local/goal_settings_store.dart';
import 'package:acg_todo/domain/entities/folder.dart';
import 'package:acg_todo/domain/entities/item.dart';
import 'package:acg_todo/domain/entities/system_folders.dart';
import 'package:acg_todo/presentation/home/home_layout.dart';

void main() {
  group('home cells hide completed from wall', () {
    test('completed only in completed folder tile', () {
      final folders = [
        Folder(id: 'f1', name: '冬番', sortOrder: 0),
        Folder(
          id: SystemFolders.completedId,
          name: SystemFolders.completedName,
          sortOrder: 9999,
        ),
      ];
      final items = [
        Item(
          id: 'a',
          userId: 'u',
          type: 'anime',
          title: 'Active',
          status: 'in_progress',
        ),
        Item(
          id: 'b',
          userId: 'u',
          type: 'anime',
          title: 'Done',
          status: 'completed',
          folderId: SystemFolders.completedId,
        ),
        Item(
          id: 'c',
          userId: 'u',
          type: 'anime',
          title: 'InFolder',
          status: 'in_progress',
          folderId: 'f1',
        ),
      ];
      final cells = buildHomeCells(allItems: items, folders: folders);
      // f1 folder + completed folder + uncategorized active
      expect(cells.length, 3);
      final folderCells = cells.whereType<FolderHomeCell>().toList();
      expect(folderCells.any((c) => c.folder.id == SystemFolders.completedId),
          isTrue);
      expect(
        cells.whereType<ItemHomeCell>().map((e) => e.item.id),
        ['a'],
      );
    });
  });

  group('progress buckets', () {
    late Box box;
    late GoalSettingsStore store;

    setUp(() async {
      Hive.init(
        './.dart_tool/test_hive_goals_${DateTime.now().microsecondsSinceEpoch}',
      );
      box = await Hive.openBox(
        'g_${DateTime.now().microsecondsSinceEpoch}',
      );
      store = GoalSettingsStore(box);
    });

    tearDown(() async {
      await box.clear();
      await box.close();
    });

    test('rolling sums last n days', () async {
      final now = DateTime(2026, 7, 10);
      await store.addProgressDelta(3, now);
      await store.addProgressDelta(2, now.subtract(const Duration(days: 1)));
      await store.addProgressDelta(5, now.subtract(const Duration(days: 2)));
      expect(store.rollingUnits(3, now), 10);
      expect(store.todayUnits(now), 3);
      expect(store.monthUnits(now), 10);
    });
  });
}
