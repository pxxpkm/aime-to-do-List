import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:acg_todo/core/theme/app_colors.dart';
import 'package:acg_todo/domain/entities/folder.dart';
import 'package:acg_todo/domain/entities/item.dart';
import 'package:acg_todo/domain/entities/system_folders.dart';
import 'package:acg_todo/presentation/providers/folders_provider.dart';
import 'package:acg_todo/presentation/providers/items_provider.dart';
import 'package:acg_todo/presentation/widgets/paper_filter_chip.dart';

class FolderChipBar extends ConsumerWidget {
  /// null = all, [kFolderFilterUncategorized] = uncategorized, else folder id
  final String? selectedFolderFilter;
  final ValueChanged<String?> onSelected;
  final String? dropHighlightFolderId;
  final Future<void> Function(Item item, String? folderId)? onItemDropped;
  final ValueChanged<String?>? onDragEnterFolder;
  final VoidCallback? onDragLeaveFolder;

  const FolderChipBar({
    super.key,
    required this.selectedFolderFilter,
    required this.onSelected,
    this.dropHighlightFolderId,
    this.onItemDropped,
    this.onDragEnterFolder,
    this.onDragLeaveFolder,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final folders = ref.watch(foldersNotifierProvider);
    final items = ref.watch(itemsNotifierProvider);

    int countIn(String? folderId) {
      if (folderId == null) return items.length;
      if (folderId == kFolderFilterUncategorized) {
        return items.where((i) => i.folderId == null).length;
      }
      return items.where((i) => i.folderId == folderId).length;
    }

    Widget dropWrap({
      required String? folderId,
      required Widget child,
    }) {
      if (onItemDropped == null) return child;
      return DragTarget<Item>(
        onWillAcceptWithDetails: (d) {
          onDragEnterFolder?.call(folderId);
          if (folderId == kFolderFilterUncategorized) {
            return d.data.folderId != null;
          }
          if (folderId == null) return false;
          return d.data.folderId != folderId;
        },
        onLeave: (_) => onDragLeaveFolder?.call(),
        onAcceptWithDetails: (d) {
          onDragLeaveFolder?.call();
          final target =
              folderId == kFolderFilterUncategorized ? null : folderId;
          onItemDropped!(d.data, target);
        },
        builder: (context, candidate, rejected) {
          final hot = candidate.isNotEmpty ||
              dropHighlightFolderId == folderId;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            decoration: hot
                ? BoxDecoration(
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.anime.withValues(alpha: 0.45),
                        blurRadius: 8,
                      ),
                    ],
                  )
                : null,
            child: child,
          );
        },
      );
    }

    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _FolderChip(
            label: '全部',
            count: countIn(null),
            selected: selectedFolderFilter == null,
            color: AppColors.textPrimary,
            onTap: () => onSelected(null),
          ),
          const SizedBox(width: 8),
          dropWrap(
            folderId: kFolderFilterUncategorized,
            child: _FolderChip(
              label: '未分類',
              count: countIn(kFolderFilterUncategorized),
              selected: selectedFolderFilter == kFolderFilterUncategorized,
              color: AppColors.textSecondary,
              onTap: () => onSelected(kFolderFilterUncategorized),
            ),
          ),
          for (final folder in folders) ...[
            const SizedBox(width: 8),
            dropWrap(
              folderId: folder.id,
              child: _FolderChip(
                label: folder.name,
                count: countIn(folder.id),
                selected: selectedFolderFilter == folder.id,
                color: folder.colorValue != null
                    ? Color(folder.colorValue!)
                    : AppColors.manga,
                onTap: () => onSelected(folder.id),
                onLongPress: () => _showFolderActions(context, ref, folder),
              ),
            ),
          ],
          const SizedBox(width: 8),
          _AddFolderChip(
            onTap: () => _showCreateDialog(context, ref),
          ),
        ],
      ),
    );
  }

  Future<void> _showCreateDialog(BuildContext context, WidgetRef ref) async {
    final name = await showFolderNameDialog(context, title: '新建資料夾');
    if (name == null || name.isEmpty) return;
    await ref.read(foldersNotifierProvider.notifier).create(name);
  }

  Future<void> _showFolderActions(
    BuildContext context,
    WidgetRef ref,
    Folder folder,
  ) async {
    if (folder.id == SystemFolders.completedId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('「已完成」為系統資料夾，不可改名或刪除'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.paperElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('重新命名'),
              onTap: () => Navigator.pop(ctx, 'rename'),
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: AppColors.danger),
              title: const Text('刪除資料夾'),
              subtitle: const Text('作品會回到未分類'),
              onTap: () => Navigator.pop(ctx, 'delete'),
            ),
          ],
        ),
      ),
    );
    if (!context.mounted || action == null) return;

    if (action == 'rename') {
      final name = await showFolderNameDialog(
        context,
        title: '重新命名',
        initial: folder.name,
      );
      if (name != null && name.isNotEmpty) {
        await ref.read(foldersNotifierProvider.notifier).rename(folder.id, name);
      }
    } else if (action == 'delete') {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('刪除資料夾？'),
          content: Text('「${folder.name}」會被刪除，裡面的作品會回到未分類。'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('取消')),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('刪除',
                  style: TextStyle(color: AppColors.danger)),
            ),
          ],
        ),
      );
      if (ok == true) {
        await ref.read(foldersNotifierProvider.notifier).delete(folder.id);
        if (selectedFolderFilter == folder.id) {
          onSelected(null);
        }
      }
    }
  }
}

Future<String?> showFolderNameDialog(
  BuildContext context, {
  required String title,
  String? initial,
}) {
  final controller = TextEditingController(text: initial ?? '');
  return showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: TextField(
        controller: controller,
        autofocus: true,
        maxLength: 20,
        decoration: const InputDecoration(
          hintText: '例如：冬番、通勤漫畫',
          border: OutlineInputBorder(),
        ),
        onSubmitted: (v) => Navigator.pop(ctx, v.trim()),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
        TextButton(
          onPressed: () => Navigator.pop(ctx, controller.text.trim()),
          child: const Text('儲存'),
        ),
      ],
    ),
  );
}

class _FolderChip extends StatelessWidget {
  final String label;
  final int count;
  final bool selected;
  final Color color;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const _FolderChip({
    required this.label,
    required this.count,
    required this.selected,
    required this.color,
    required this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return PaperFilterChip(
      label: label,
      selected: selected,
      accent: color,
      onTap: onTap,
      onLongPress: onLongPress,
      icon: Icons.folder_outlined,
      countLabel: '$count',
    );
  }
}

class _AddFolderChip extends StatelessWidget {
  final VoidCallback onTap;

  const _AddFolderChip({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return PaperFilterChip(
      label: '新建',
      selected: false,
      accent: AppColors.inkMuted,
      onTap: onTap,
      icon: Icons.add,
    );
  }
}
