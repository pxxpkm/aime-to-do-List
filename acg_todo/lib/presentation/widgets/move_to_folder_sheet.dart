import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:acg_todo/core/theme/app_colors.dart';
import 'package:acg_todo/presentation/providers/folders_provider.dart';
import 'package:acg_todo/presentation/providers/items_provider.dart';
import 'package:acg_todo/presentation/widgets/folder_chip_bar.dart';

/// Bottom sheet: move item to a folder or uncategorized.
Future<void> showMoveToFolderSheet(
  BuildContext context,
  WidgetRef ref, {
  required String itemId,
  String? currentFolderId,
}) async {
  final folders = ref.read(foldersNotifierProvider);

  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) {
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Text(
                '移到資料夾',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            ListTile(
              leading: Icon(
                currentFolderId == null
                    ? Icons.radio_button_checked
                    : Icons.radio_button_off,
                color: AppColors.textSecondary,
              ),
              title: const Text('未分類'),
              onTap: () async {
                await ref
                    .read(itemsNotifierProvider.notifier)
                    .moveToFolder(itemId, null);
                if (ctx.mounted) Navigator.pop(ctx);
              },
            ),
            for (final folder in folders)
              ListTile(
                leading: Icon(
                  currentFolderId == folder.id
                      ? Icons.radio_button_checked
                      : Icons.folder_outlined,
                  color: folder.colorValue != null
                      ? Color(folder.colorValue!)
                      : AppColors.manga,
                ),
                title: Text(folder.name),
                onTap: () async {
                  await ref
                      .read(itemsNotifierProvider.notifier)
                      .moveToFolder(itemId, folder.id);
                  if (ctx.mounted) Navigator.pop(ctx);
                },
              ),
            ListTile(
              leading: const Icon(Icons.create_new_folder_outlined,
                  color: AppColors.anime),
              title: const Text('新建並移入'),
              onTap: () async {
                Navigator.pop(ctx);
                final name = await showFolderNameDialog(
                  context,
                  title: '新建資料夾',
                );
                if (name == null || name.isEmpty) return;
                final folder = await ref
                    .read(foldersNotifierProvider.notifier)
                    .create(name);
                await ref
                    .read(itemsNotifierProvider.notifier)
                    .moveToFolder(itemId, folder.id);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      );
    },
  );
}
