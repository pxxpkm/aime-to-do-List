import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:acg_todo/core/theme/app_colors.dart';
import 'package:acg_todo/core/theme/app_palette.dart';
import 'package:acg_todo/core/theme/app_typography.dart';
import 'package:acg_todo/data/local/goal_settings_store.dart';
import 'package:acg_todo/data/local/hive_cache.dart';
import 'package:acg_todo/data/repositories/library_backup_repository.dart';
import 'package:acg_todo/domain/services/library_backup_service.dart';
import 'package:acg_todo/presentation/providers/daily_goal_provider.dart';
import 'package:acg_todo/presentation/providers/folders_provider.dart';
import 'package:acg_todo/presentation/providers/items_provider.dart';
import 'package:acg_todo/presentation/providers/repository_providers.dart';

Future<void> showHiveToServerMigrateSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: context.palette.elevated,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => const HiveToServerMigrateSheet(),
  );
}

class HiveToServerMigrateSheet extends ConsumerStatefulWidget {
  const HiveToServerMigrateSheet({super.key});

  @override
  ConsumerState<HiveToServerMigrateSheet> createState() =>
      _HiveToServerMigrateSheetState();
}

class _HiveToServerMigrateSheetState
    extends ConsumerState<HiveToServerMigrateSheet> {
  BackupImportMode _mode = BackupImportMode.merge;
  bool _importProgress = true;
  bool _overwriteGoalsUi = false;
  bool _busy = false;
  String? _error;
  MergePlan? _preview;
  HiveSnapshotCounts? _hiveCounts;
  int _diskItems = 0;
  int _diskFolders = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refreshPreview());
  }

  LibraryBackupRepository get _repo =>
      ref.read(libraryBackupRepositoryProvider);

  void _refreshPreview() {
    try {
      final hive = ref.read(hiveCacheProvider);
      final hiveGoals = GoalSettingsStore.hive(hive.settingsBox);
      final counts = _repo.hiveSnapshotCounts(hive);
      final diskItems = ref.read(itemsRepositoryProvider).getAll().length;
      final diskFolders = ref
          .read(foldersRepositoryProvider)
          .getAll()
          .where((f) => f.id != 'folder_system_completed')
          .length;

      if (counts.isEmpty) {
        setState(() {
          _hiveCounts = counts;
          _diskItems = diskItems;
          _diskFolders = diskFolders;
          _preview = null;
          _error = '瀏覽器（Hive）沒有可遷移的作品或資料夾';
        });
        return;
      }

      final backup = _repo.backupFromHive(hive, hiveGoals);
      final importSettings = _importProgress || _overwriteGoalsUi;
      final plan = _repo.previewBackup(
        backup,
        mode: _mode,
        importSettings: importSettings,
      );
      setState(() {
        _hiveCounts = counts;
        _diskItems = diskItems;
        _diskFolders = diskFolders;
        _preview = plan;
        _error = null;
      });
    } catch (e) {
      setState(() {
        _error = '無法讀取瀏覽器資料：$e';
        _preview = null;
      });
    }
  }

  Future<void> _confirm() async {
    if (_preview == null || _hiveCounts == null || _hiveCounts!.isEmpty) {
      return;
    }

    if (_mode == BackupImportMode.replace) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('取代磁碟庫？'),
          content: const Text(
            '將以瀏覽器資料覆寫磁碟庫作品，無法復原。建議先匯出備份。',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('取消'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: TextButton.styleFrom(foregroundColor: context.palette.danger),
              child: const Text('確定取代'),
            ),
          ],
        ),
      );
      if (ok != true) return;
    }

    setState(() => _busy = true);
    try {
      final hive = ref.read(hiveCacheProvider);
      final hiveGoals = GoalSettingsStore.hive(hive.settingsBox);
      final backup = _repo.backupFromHive(hive, hiveGoals);

      // Build settings apply: progress-only merge unless overwrite goals.
      LibraryBackup toApply = backup;
      if (_mode == BackupImportMode.merge &&
          _importProgress &&
          !_overwriteGoalsUi) {
        // planImport already uses progress-only when importSettings true via
        // mergeSettingsProgressOnly — pass importSettings true.
      }

      final result = await _repo.importFromBackup(
        toApply,
        mode: _mode,
        importSettings: _importProgress || _overwriteGoalsUi,
      );

      // If merge + overwrite goals UI, re-apply full settings from hive.
      if (_mode == BackupImportMode.merge && _overwriteGoalsUi) {
        await ref.read(goalSettingsStoreProvider).applyBackupSettings(
              hiveGoals.exportForBackup(),
              progressOnly: false,
              replaceProgress: false,
            );
      }

      ref.invalidate(itemsNotifierProvider);
      ref.invalidate(foldersNotifierProvider);
      ref.invalidate(multiGoalProvider);

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _mode == BackupImportMode.replace
                ? '已取代磁碟庫：${result.itemsAdded} 部作品'
                : '已合併：新增 ${result.itemsAdded}、更新 ${result.itemsMerged}',
          ),
        ),
      );
    } catch (e) {
      setState(() {
        _busy = false;
        _error = '遷移失敗：$e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 16 + bottom),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: context.palette.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('上傳瀏覽器資料到磁碟庫', style: AppTypography.title),
            const SizedBox(height: 8),
            Text(
              '把 IndexedDB（Hive）裡的作品合併進 library.db。',
              style: AppTypography.caption,
            ),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: context.palette.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: context.palette.border),
              ),
              child: Text(
                '瀏覽器：作品 ${_hiveCounts?.itemCount ?? '…'} · '
                '資料夾 ${_hiveCounts?.folderCount ?? '…'}\n'
                '磁碟庫：作品 $_diskItems · 資料夾 $_diskFolders',
                style: AppTypography.body.copyWith(fontSize: 13),
              ),
            ),
            const SizedBox(height: 12),
            Text('模式', style: AppTypography.caption),
            const SizedBox(height: 4),
            SegmentedButton<BackupImportMode>(
              segments: const [
                ButtonSegment(
                  value: BackupImportMode.merge,
                  label: Text('合併'),
                  icon: Icon(Icons.merge_type, size: 16),
                ),
                ButtonSegment(
                  value: BackupImportMode.replace,
                  label: Text('取代'),
                  icon: Icon(Icons.warning_amber, size: 16),
                ),
              ],
              selected: {_mode},
              onSelectionChanged: _busy
                  ? null
                  : (s) {
                      setState(() => _mode = s.first);
                      _refreshPreview();
                    },
            ),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              value: _importProgress,
              onChanged: _busy
                  ? null
                  : (v) {
                      setState(() => _importProgress = v ?? true);
                      _refreshPreview();
                    },
              title: Text(
                '一併合併每日進度',
                style: AppTypography.caption.copyWith(
                  color: context.palette.ink,
                ),
              ),
              controlAffinity: ListTileControlAffinity.leading,
            ),
            if (_mode == BackupImportMode.merge)
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                value: _overwriteGoalsUi,
                onChanged: _busy
                    ? null
                    : (v) {
                        setState(() => _overwriteGoalsUi = v ?? false);
                        _refreshPreview();
                      },
                title: Text(
                  '覆寫目標 / 外觀設定（用瀏覽器那份）',
                  style: AppTypography.caption.copyWith(
                    color: context.palette.ink,
                  ),
                ),
                controlAffinity: ListTileControlAffinity.leading,
              ),
            if (_preview != null) ...[
              const SizedBox(height: 8),
              Text(
                _mode == BackupImportMode.replace
                    ? '將寫入 ${_preview!.itemsToWrite.length} 部作品'
                    : '新增 ${_preview!.itemsAdded} · '
                        '合併更新 ${_preview!.itemsMerged} · '
                        '新資料夾 ${_preview!.foldersAdded}',
                style: AppTypography.body.copyWith(fontSize: 13),
              ),
            ],
            if (_error != null) ...[
              SizedBox(height: 8),
              Text(
                _error!,
                style: AppTypography.caption.copyWith(color: context.palette.danger),
              ),
            ],
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _busy || _preview == null ? null : _confirm,
              child: _busy
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('確認遷移'),
            ),
            TextButton(
              onPressed: _busy ? null : () => Navigator.pop(context),
              child: const Text('取消'),
            ),
          ],
        ),
      ),
    );
  }
}
