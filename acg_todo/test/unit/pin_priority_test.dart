import 'package:flutter_test/flutter_test.dart';

import 'package:acg_todo/domain/entities/folder.dart';
import 'package:acg_todo/domain/entities/item.dart';
import 'package:acg_todo/domain/entities/pin_tier.dart';
import 'package:acg_todo/domain/entities/system_folders.dart';
import 'package:acg_todo/domain/services/item_sort_service.dart';
import 'package:acg_todo/presentation/home/home_layout.dart';

Item _i({
  required String id,
  String title = 't',
  PinTier tier = PinTier.none,
  int pinOrder = 0,
  int sortOrder = 0,
  String? folderId,
}) {
  return Item(
    id: id,
    userId: 'u',
    type: 'anime',
    title: title,
    pinTier: tier,
    pinOrder: pinOrder,
    sortOrder: sortOrder,
    folderId: folderId,
  );
}

void main() {
  const sorter = ItemSortService();

  test('sort watching then priority then rest', () {
    final list = sorter.sort([
      _i(id: 'u', sortOrder: 0),
      _i(id: 'pr', tier: PinTier.priority, pinOrder: 0),
      _i(id: 'w1', tier: PinTier.watching, pinOrder: 1),
      _i(id: 'w0', tier: PinTier.watching, pinOrder: 0),
    ], HomeSortMode.manual);
    expect(list.map((e) => e.id), ['w0', 'w1', 'pr', 'u']);
  });

  test('legacy pin migration string', () {
    expect(PinTier.fromStorage('watching'), PinTier.watching);
    expect(PinTier.fromStorage(null, legacyIsPinned: true), PinTier.watching);
    expect(PinTier.fromStorage(null, legacyIsPinned: false), PinTier.none);
  });

  test('buildHomeCells excludes pinned from wall', () {
    final folders = [
      Folder(id: 'f1', name: '冬番', sortOrder: 0),
      Folder(
        id: SystemFolders.completedId,
        name: SystemFolders.completedName,
        sortOrder: 9999,
      ),
    ];
    final items = [
      _i(id: 'loose'),
      _i(id: 'inF', folderId: 'f1'),
      _i(id: 'pin', tier: PinTier.watching, folderId: 'f1'),
    ];
    final cells = buildHomeCells(allItems: items, folders: folders);
    expect(cells.whereType<ItemHomeCell>().map((e) => e.item.id), ['loose']);
    final f1 =
        cells.whereType<FolderHomeCell>().firstWhere((c) => c.folder.id == 'f1');
    expect(f1.count, 1);
  });
}
