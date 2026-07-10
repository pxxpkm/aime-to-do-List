import 'package:flutter_test/flutter_test.dart';

import 'package:acg_todo/domain/entities/item.dart';
import 'package:acg_todo/presentation/providers/folders_provider.dart';

/// Pure filter logic used by HomePage (mirrored for unit tests).
List<Item> filterItems(
  List<Item> items, {
  String? typeKey,
  String? folderFilter,
}) {
  var list = items;
  if (typeKey != null) {
    list = list.where((i) => i.type == typeKey).toList();
  }
  if (folderFilter == kFolderFilterUncategorized) {
    list = list.where((i) => i.folderId == null).toList();
  } else if (folderFilter != null) {
    list = list.where((i) => i.folderId == folderFilter).toList();
  }
  return list;
}

void main() {
  Item item(String id, {String type = 'anime', String? folderId}) {
    return Item(
      id: id,
      userId: 'u',
      type: type,
      title: id,
      folderId: folderId,
    );
  }

  test('folder filter all / none / id', () {
    final items = [
      item('a', folderId: null),
      item('b', folderId: 'folder_1'),
      item('c', folderId: 'folder_1'),
      item('d', folderId: 'folder_2'),
    ];

    expect(filterItems(items).map((e) => e.id), ['a', 'b', 'c', 'd']);
    expect(
      filterItems(items, folderFilter: kFolderFilterUncategorized)
          .map((e) => e.id),
      ['a'],
    );
    expect(
      filterItems(items, folderFilter: 'folder_1').map((e) => e.id),
      ['b', 'c'],
    );
  });

  test('type and folder intersect', () {
    final items = [
      item('a', type: 'anime', folderId: 'f1'),
      item('b', type: 'manga', folderId: 'f1'),
      item('c', type: 'anime', folderId: null),
    ];
    final r = filterItems(
      items,
      typeKey: 'anime',
      folderFilter: 'f1',
    );
    expect(r.map((e) => e.id), ['a']);
  });
}
