import 'package:acg_todo/domain/entities/folder.dart';
import 'package:acg_todo/domain/entities/item.dart';
import 'package:acg_todo/domain/entities/system_folders.dart';

/// Unified home grid cell for "all folders" view.
sealed class HomeCell {
  const HomeCell();
}

class FolderHomeCell extends HomeCell {
  final Folder folder;
  final List<Item> previewItems;
  final int count;

  const FolderHomeCell({
    required this.folder,
    required this.previewItems,
    required this.count,
  });
}

class ItemHomeCell extends HomeCell {
  final Item item;

  const ItemHomeCell(this.item);
}

bool _isActive(Item i) =>
    i.status != 'completed' && i.folderId != SystemFolders.completedId;

/// Build home cells: user folders (active only) + completed folder + uncategorized active.
List<HomeCell> buildHomeCells({
  required List<Item> allItems,
  required List<Folder> folders,
  String? typeKey,
}) {
  Iterable<Item> typed(Iterable<Item> src) {
    if (typeKey == null) return src;
    return src.where((i) => i.type == typeKey);
  }

  final cells = <HomeCell>[];
  Folder? completedFolder;

  for (final folder in folders) {
    if (folder.id == SystemFolders.completedId) {
      completedFolder = folder;
      continue;
    }
    final inFolder = typed(
      allItems.where((i) => i.folderId == folder.id && _isActive(i)),
    ).toList();
    if (inFolder.isEmpty) continue;
    cells.add(FolderHomeCell(
      folder: folder,
      previewItems: inFolder.take(4).toList(),
      count: inFolder.length,
    ));
  }

  // Completed system folder (always show if any completed)
  final completed = typed(
    allItems.where(
      (i) =>
          i.status == 'completed' ||
          i.folderId == SystemFolders.completedId,
    ),
  ).toList();
  if (completedFolder != null && completed.isNotEmpty) {
    cells.add(FolderHomeCell(
      folder: completedFolder,
      previewItems: completed.take(4).toList(),
      count: completed.length,
    ));
  }

  for (final item in typed(
    allItems.where((i) => i.folderId == null && _isActive(i)),
  )) {
    cells.add(ItemHomeCell(item));
  }
  return cells;
}

({int Function(double width) columns, double aspectRatio}) homeGridLayout(
  String density,
) {
  switch (density) {
    case 'large':
      return (
        columns: (w) {
          if (w < 520) return 2;
          if (w < 900) return 3;
          return 4;
        },
        aspectRatio: 0.58,
      );
    case 'comfortable':
      return (
        columns: (w) {
          if (w < 520) return 2;
          if (w < 720) return 3;
          if (w < 1000) return 4;
          return 5;
        },
        aspectRatio: 0.64,
      );
    case 'compact':
    default:
      return (
        columns: (w) {
          if (w < 520) return 3;
          if (w < 720) return 4;
          if (w < 1000) return 5;
          return 6;
        },
        aspectRatio: 0.72,
      );
  }
}
