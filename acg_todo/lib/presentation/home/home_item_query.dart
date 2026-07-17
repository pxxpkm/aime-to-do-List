import 'package:acg_todo/domain/entities/item.dart';
import 'package:acg_todo/domain/entities/system_folders.dart';
import 'package:acg_todo/domain/services/item_sort_service.dart';
import 'package:acg_todo/presentation/providers/folders_provider.dart';

bool isActiveItem(Item i) =>
    i.status != 'completed' && i.folderId != SystemFolders.completedId;

/// URL query value for uncategorized: `/library?folder=none`.
const kLibraryFolderQueryUncategorized = 'none';

/// Parse `/library?folder=` → internal filter (`null` | [kFolderFilterUncategorized] | id).
String? parseLibraryFolderQuery(String? raw) {
  if (raw == null || raw.isEmpty) return null;
  if (raw == kLibraryFolderQueryUncategorized ||
      raw == kFolderFilterUncategorized) {
    return kFolderFilterUncategorized;
  }
  return raw;
}

/// Internal filter → query param (null means omit `folder`).
String? libraryFolderQueryParam(String? folderFilter) {
  if (folderFilter == null) return null;
  if (folderFilter == kFolderFilterUncategorized) {
    return kLibraryFolderQueryUncategorized;
  }
  return folderFilter;
}

/// Path for library with optional folder filter.
String libraryLocationForFolder(String? folderFilter) {
  final param = libraryFolderQueryParam(folderFilter);
  if (param == null) return '/library';
  return '/library?folder=${Uri.encodeQueryComponent(param)}';
}

/// Mixed folder tiles + uncategorized: only when viewing "all" + manual + no search.
bool useMixedHomeLayout({
  required String? folderFilter,
  required HomeSortMode sortMode,
  String? searchQuery,
}) {
  final q = searchQuery?.trim() ?? '';
  return folderFilter == null && sortMode == HomeSortMode.manual && q.isEmpty;
}

/// Library search: title, originalTitle, tags, remark (case-insensitive contains).
bool itemMatchesQuery(Item item, String query) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return true;
  if (item.title.toLowerCase().contains(q)) return true;
  final orig = item.originalTitle;
  if (orig != null && orig.toLowerCase().contains(q)) return true;
  for (final t in item.tags) {
    if (t.toLowerCase().contains(q)) return true;
  }
  final remark = item.remark;
  if (remark != null && remark.toLowerCase().contains(q)) return true;
  return false;
}

/// Filter + sort items for the home poster grid (flat modes).
List<Item> filterAndSortHomeItems({
  required List<Item> items,
  required HomeSortMode sortMode,
  String? typeKey,
  String? folderFilter,
  String? tagFilter,
  String? searchQuery,
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

  final q = searchQuery?.trim() ?? '';
  if (q.isNotEmpty) {
    list = list.where((i) => itemMatchesQuery(i, q)).toList();
  }

  return sorter.sort(list, sortMode);
}
