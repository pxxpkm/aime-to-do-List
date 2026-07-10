import 'package:flutter_test/flutter_test.dart';

import 'package:acg_todo/domain/entities/item.dart';
import 'package:acg_todo/domain/entities/system_folders.dart';
import 'package:acg_todo/domain/services/item_sort_service.dart';
import 'package:acg_todo/presentation/home/home_item_query.dart';
import 'package:acg_todo/presentation/providers/folders_provider.dart';

Item _i({
  required String id,
  String title = 't',
  String status = 'in_progress',
  String? folderId,
  int sortOrder = 0,
  DateTime? deadline,
}) {
  return Item(
    id: id,
    userId: 'u',
    type: 'anime',
    title: title,
    status: status,
    folderId: folderId,
    sortOrder: sortOrder,
    deadline: deadline,
  );
}

void main() {
  test('useMixedHomeLayout only all+manual', () {
    expect(
      useMixedHomeLayout(
        folderFilter: null,
        sortMode: HomeSortMode.manual,
      ),
      isTrue,
    );
    expect(
      useMixedHomeLayout(
        folderFilter: null,
        sortMode: HomeSortMode.title,
      ),
      isFalse,
    );
    expect(
      useMixedHomeLayout(
        folderFilter: 'f1',
        sortMode: HomeSortMode.manual,
      ),
      isFalse,
    );
  });

  test('all folders + title sorts active across folders', () {
    final items = [
      _i(id: '1', title: 'Zoo', folderId: 'f1', sortOrder: 0),
      _i(id: '2', title: 'Apple', folderId: null, sortOrder: 1),
      _i(
        id: '3',
        title: 'Done',
        status: 'completed',
        folderId: SystemFolders.completedId,
      ),
    ];
    final out = filterAndSortHomeItems(
      items: items,
      sortMode: HomeSortMode.title,
      folderFilter: null,
    );
    expect(out.map((e) => e.id), ['2', '1']);
  });

  test('folder filter + deadline sort', () {
    final items = [
      _i(
        id: 'late',
        folderId: 'f1',
        deadline: DateTime(2026, 12, 1),
        sortOrder: 0,
      ),
      _i(
        id: 'soon',
        folderId: 'f1',
        deadline: DateTime(2026, 7, 11),
        sortOrder: 1,
      ),
      _i(id: 'other', folderId: 'f2', deadline: DateTime(2026, 1, 1)),
    ];
    final out = filterAndSortHomeItems(
      items: items,
      sortMode: HomeSortMode.deadline,
      folderFilter: 'f1',
    );
    expect(out.map((e) => e.id), ['soon', 'late']);
  });

  test('uncategorized filter excludes folder items', () {
    final items = [
      _i(id: 'a', folderId: null),
      _i(id: 'b', folderId: 'f1'),
    ];
    final out = filterAndSortHomeItems(
      items: items,
      sortMode: HomeSortMode.manual,
      folderFilter: kFolderFilterUncategorized,
    );
    expect(out.map((e) => e.id), ['a']);
  });
}
