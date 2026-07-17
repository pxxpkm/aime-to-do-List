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

  // Pin tiers drawn in HomePriorityBoard — exclude from mixed wall.
  bool notPinned(Item i) => !i.isPinned;

  for (final folder in folders) {
    if (folder.id == SystemFolders.completedId) {
      completedFolder = folder;
      continue;
    }
    final inFolder = typed(
      allItems.where(
        (i) =>
            i.folderId == folder.id && _isActive(i) && notPinned(i),
      ),
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
    allItems.where(
      (i) => i.folderId == null && _isActive(i) && notPinned(i),
    ),
  )) {
    cells.add(ItemHomeCell(item));
  }
  return cells;
}

/// Grid layout for library poster wall.
/// Uses min card width so column count tracks window size continuously.
({int Function(double width) columns, double aspectRatio}) homeGridLayout(
  String density,
) {
  // Poster-first cards use ~2:3 cover ratio.
  const posterRatio = 0.67;

  switch (density) {
    case 'large':
      // Gallery: larger cards, fewer columns
      return (
        columns: (w) => _columnsForMinWidth(w, minCard: 220, maxCols: 6),
        aspectRatio: posterRatio,
      );
    case 'comfortable':
      return (
        columns: (w) => _columnsForMinWidth(w, minCard: 180, maxCols: 8),
        aspectRatio: posterRatio,
      );
    case 'compact':
    default:
      return (
        columns: (w) => _columnsForMinWidth(w, minCard: 140, maxCols: 10),
        aspectRatio: posterRatio,
      );
  }
}

int _columnsForMinWidth(
  double width, {
  required double minCard,
  required int maxCols,
}) {
  if (width <= 0 || !width.isFinite) return 2;
  final n = (width / minCard).floor();
  if (n < 2) return 2;
  if (n > maxCols) return maxCols;
  return n;
}
