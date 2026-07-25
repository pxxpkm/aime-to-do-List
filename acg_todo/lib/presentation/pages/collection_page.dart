import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:acg_todo/core/theme/app_colors.dart';
import 'package:acg_todo/core/theme/app_palette.dart';
import 'package:acg_todo/core/theme/app_scaffold.dart';
import 'package:acg_todo/core/theme/app_typography.dart';
import 'package:acg_todo/domain/entities/folder.dart';
import 'package:acg_todo/domain/entities/item.dart';
import 'package:acg_todo/domain/entities/system_folders.dart';
import 'package:acg_todo/presentation/home/home_item_query.dart';
import 'package:acg_todo/presentation/providers/folders_provider.dart';
import 'package:acg_todo/presentation/providers/items_provider.dart';
import 'package:acg_todo/presentation/widgets/folder_chip_bar.dart';
import 'package:acg_todo/presentation/widgets/folder_tile.dart';
import 'package:acg_todo/presentation/widgets/poster_image_widget.dart';

/// Folder overview → open media library filtered by folder.
class CollectionPage extends ConsumerWidget {
  const CollectionPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final folders = ref.watch(foldersNotifierProvider);
    final items = ref.watch(itemsNotifierProvider);

    final userFolders = folders
        .where((f) => f.id != SystemFolders.completedId)
        .toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    final completedFolder = folders
        .where((f) => f.id == SystemFolders.completedId)
        .firstOrNull;

    final uncategorized = items
        .where((i) => i.folderId == null && isActiveItem(i))
        .toList();
    final completed = items
        .where(
          (i) =>
              i.status == 'completed' ||
              i.folderId == SystemFolders.completedId,
        )
        .toList();

    return AppScaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '收藏',
                        style: AppTypography.display.copyWith(fontSize: 24),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => _createFolder(context, ref),
                      icon: const Icon(Icons.create_new_folder_outlined, size: 18),
                      label: const Text('新增'),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: Text(
                  '點資料夾開啟媒體庫；長按可重新命名或刪除。',
                  style: AppTypography.caption.copyWith(
                    color: context.palette.inkMuted,
                  ),
                ),
              ),
            ),
            if (userFolders.isEmpty &&
                uncategorized.isEmpty &&
                completed.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _EmptyCollection(
                  onCreate: () => _createFolder(context, ref),
                  onSearch: () => context.push('/search'),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 88),
                sliver: SliverLayoutBuilder(
                  builder: (context, constraints) {
                    final cols = _columnsFor(constraints.crossAxisExtent);
                    final tiles = <Widget>[
                      _UncategorizedTile(
                        count: uncategorized.length,
                        previewItems: uncategorized.take(4).toList(),
                        onTap: () => context.go(
                          libraryLocationForFolder(kFolderFilterUncategorized),
                        ),
                      ),
                      for (final folder in userFolders)
                        FolderTile(
                          folder: folder,
                          count: _countInFolder(items, folder.id),
                          previewItems: _previewInFolder(items, folder.id),
                          onTap: () => context.go(
                            libraryLocationForFolder(folder.id),
                          ),
                          onLongPress: () =>
                              _folderActions(context, ref, folder),
                        ),
                      if (completedFolder != null)
                        FolderTile(
                          folder: completedFolder,
                          count: completed.length,
                          previewItems: completed.take(4).toList(),
                          onTap: () => context.go(
                            libraryLocationForFolder(
                              SystemFolders.completedId,
                            ),
                          ),
                          onLongPress: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('「已完成」為系統資料夾，不可改名或刪除'),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                        ),
                    ];

                    return SliverGrid(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: cols,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 0.78,
                      ),
                      delegate: SliverChildListDelegate(tiles),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  static int _columnsFor(double width) {
    if (width >= 1100) return 5;
    if (width >= 800) return 4;
    if (width >= 520) return 3;
    return 2;
  }

  static int _countInFolder(List<Item> items, String folderId) {
    return items
        .where((i) => i.folderId == folderId && isActiveItem(i))
        .length;
  }

  static List<Item> _previewInFolder(List<Item> items, String folderId) {
    return items
        .where((i) => i.folderId == folderId && isActiveItem(i))
        .take(4)
        .toList();
  }

  static Future<void> _createFolder(BuildContext context, WidgetRef ref) async {
    final name = await showFolderNameDialog(context, title: '新增資料夾');
    if (name == null || name.isEmpty) return;
    await ref.read(foldersNotifierProvider.notifier).create(name);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('已建立「$name」'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(milliseconds: 900),
      ),
    );
  }

  static Future<void> _folderActions(
    BuildContext context,
    WidgetRef ref,
    Folder folder,
  ) async {
    if (folder.id == SystemFolders.completedId) return;

    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: context.palette.elevated,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.open_in_new),
              title: const Text('開啟媒體庫'),
              onTap: () => Navigator.pop(ctx, 'open'),
            ),
            ListTile(
              leading: Icon(Icons.edit_outlined),
              title: Text('重新命名'),
              onTap: () => Navigator.pop(ctx, 'rename'),
            ),
            ListTile(
              leading: Icon(Icons.delete_outline, color: context.palette.danger),
              title: const Text('刪除資料夾'),
              subtitle: const Text('作品會回到未分類'),
              onTap: () => Navigator.pop(ctx, 'delete'),
            ),
          ],
        ),
      ),
    );
    if (!context.mounted || action == null) return;

    if (action == 'open') {
      context.go(libraryLocationForFolder(folder.id));
      return;
    }
    if (action == 'rename') {
      final name = await showFolderNameDialog(
        context,
        title: '重新命名',
        initial: folder.name,
      );
      if (name != null && name.isNotEmpty) {
        await ref.read(foldersNotifierProvider.notifier).rename(folder.id, name);
      }
      return;
    }
    if (action == 'delete') {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('刪除資料夾？'),
          content: Text('「${folder.name}」會被刪除，裡面的作品會回到未分類。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('取消'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: TextButton.styleFrom(foregroundColor: context.palette.danger),
              child: const Text('刪除'),
            ),
          ],
        ),
      );
      if (ok == true) {
        await ref.read(foldersNotifierProvider.notifier).delete(folder.id);
      }
    }
  }
}

class _UncategorizedTile extends StatelessWidget {
  final int count;
  final List<Item> previewItems;
  final VoidCallback onTap;

  const _UncategorizedTile({
    required this.count,
    required this.previewItems,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Synthetic folder for FolderTile-compatible look without system entity.
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: context.palette.elevated,
            border: Border.all(color: context.palette.border),
            boxShadow: const [
              BoxShadow(
                color: Color(0x1A2C2416),
                blurRadius: 16,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(10, 10, 10, 4),
                  child: previewItems.isEmpty
                      ? Center(
                          child: Icon(
                            Icons.inbox_outlined,
                            size: 36,
                            color: context.palette.inkMuted.withValues(alpha: 0.55),
                          ),
                        )
                      : _PreviewGrid(items: previewItems),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(12, 4, 12, 12),
                child: Row(
                  children: [
                    Icon(
                      Icons.folder_off_outlined,
                      size: 16,
                      color: context.palette.inkSecondary,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '未分類',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.caption.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Text(
                      '$count',
                      style: AppTypography.micro.copyWith(
                        color: context.palette.inkMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PreviewGrid extends StatelessWidget {
  final List<Item> items;

  const _PreviewGrid({required this.items});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: GridView.count(
        crossAxisCount: 2,
        mainAxisSpacing: 3,
        crossAxisSpacing: 3,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          for (var i = 0; i < 4; i++)
            if (i < items.length)
              PosterImageWidget(
                posterUrl: items[i].posterUrl,
                type: items[i].type,
                fit: BoxFit.cover,
              )
            else
              ColoredBox(color: context.palette.surface),
        ],
      ),
    );
  }
}

class _EmptyCollection extends StatelessWidget {
  final VoidCallback onCreate;
  final VoidCallback onSearch;

  const _EmptyCollection({
    required this.onCreate,
    required this.onSearch,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.folder_open_outlined,
              size: 48,
              color: context.palette.inkMuted.withValues(alpha: 0.6),
            ),
            const SizedBox(height: 16),
            Text('還沒有資料夾', style: AppTypography.title.copyWith(fontSize: 18)),
            const SizedBox(height: 8),
            Text(
              '建立資料夾整理作品，或先去搜尋加入。',
              style: AppTypography.caption,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onCreate,
              icon: const Icon(Icons.create_new_folder_outlined, size: 18),
              label: const Text('新增資料夾'),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: onSearch,
              child: const Text('搜尋並加入'),
            ),
          ],
        ),
      ),
    );
  }
}
