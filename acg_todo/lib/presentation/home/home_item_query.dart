import 'package:acg_todo/domain/entities/item.dart';
import 'package:acg_todo/domain/entities/system_folders.dart';
import 'package:acg_todo/domain/services/item_sort_service.dart';
import 'package:acg_todo/presentation/providers/folders_provider.dart';

bool isActiveItem(Item i) =>
    i.status != 'completed' && i.folderId != SystemFolders.completedId;

/// Mixed folder tiles + uncategorized: only when viewing "all" + manual sort.
bool useMixedHomeLayout({
  required String? folderFilter,
  required HomeSortMode sortMode,
}) =>
    folderFilter == null && sortMode == HomeSortMode.manual;

/// Filter + sort items for the home poster grid (flat modes).
List<Item> filterAndSortHomeItems({
  required List<Item> items,
  required HomeSortMode sortMode,
  String? typeKey,
  String? folderFilter,
  String? tagFilter,
  ItemSortService sorter = const ItemSortService(),
}) {
  var list = List<Item>.from(items);

  if (typeKey != null) {
    list = list.where((i) => i.type == typeKey).toList();
  }

  if (folderFilter == SystemFolders.completedId) {
    list = list
        .where(
          (i) =>
              i.status == 'completed' ||
              i.folderId == SystemFolders.completedId,
        )
        .toList();
  } else if (folderFilter == kFolderFilterUncategorized) {
    list = list
        .where((i) => i.folderId == null && isActiveItem(i))
        .toList();
  } else if (folderFilter != null) {
    list = list
        .where((i) => i.folderId == folderFilter && isActiveItem(i))
        .toList();
  } else {
    // "全部" flat mode: all active items (any folder)
    list = list.where(isActiveItem).toList();
  }

  if (tagFilter != null) {
    if (tagFilter.isEmpty) {
      list = list.where((i) => i.tags.isEmpty).toList();
    } else {
      list = list.where((i) => i.tags.contains(tagFilter)).toList();
    }
  }

  return sorter.sort(list, sortMode);
}
