import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:acg_todo/core/theme/app_colors.dart';
import 'package:acg_todo/core/theme/app_palette.dart';
import 'package:acg_todo/core/theme/app_typography.dart';
import 'package:acg_todo/core/utils/web_file_io.dart';
import 'package:acg_todo/data/repositories/library_backup_repository.dart';
import 'package:acg_todo/domain/services/library_backup_service.dart';
import 'package:acg_todo/presentation/providers/daily_goal_provider.dart';
import 'package:acg_todo/presentation/providers/folders_provider.dart';
import 'package:acg_todo/presentation/providers/items_provider.dart';
import 'package:acg_todo/presentation/providers/repository_providers.dart';

Future<void> showBackupImportSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: context.palette.elevated,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => const BackupImportSheet(),
  );
}

class BackupImportSheet extends ConsumerStatefulWidget {
  const BackupImportSheet({super.key});

  @override
  ConsumerState<BackupImportSheet> createState() => _BackupImportSheetState();
}

class _BackupImportSheetState extends ConsumerState<BackupImportSheet> {
  final _pasteController = TextEditingController();
  BackupImportMode _mode = BackupImportMode.merge;
  bool _importSettings = true;
  bool _busy = false;
  String? _error;
  MergePlan? _preview;
  String? _jsonSource;

  @override
  void dispose() {
    _pasteController.dispose();
    super.dispose();
  }

  LibraryBackupRepository get _repo =>
      ref.read(libraryBackupRepositoryProvider);

  void _previewFrom(String json) {
    try {
      final plan = _repo.previewImport(
        json,
        mode: _mode,
        importSettings: _importSettings,
      );
      setState(() {
        _jsonSource = json;
        _preview = plan;
        _error = null;
      });
    } on BackupParseException catch (e) {
      setState(() {
        _jsonSource = null;
        _preview = null;
        _error = e.message;
      });
    } catch (e) {
      setState(() {
        _jsonSource = null;
        _preview = null;
        _error = '無法讀取備份：$e';
      });
    }
  }

  Future<void> _pickFile() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final text = await pickTextFile();
      if (text == null || text.trim().isEmpty) {
        setState(() => _busy = false);
        return;
      }
      _pasteController.text = text;
      _previewFrom(text);
    } catch (e) {
      setState(() => _error = '選檔失敗：$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _fromPaste() {
    final t = _pasteController.text.trim();
    if (t.isEmpty) {
      setState(() => _error = '請先貼上 JSON 內容');
      return;
    }
    _previewFrom(t);
  }

  Future<void> _confirmImport() async {
    final json = _jsonSource;
    if (json == null) return;

    if (_mode == BackupImportMode.replace) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('取代本機資料？'),
          content: const Text(
            '將清除本機全部作品後寫入備份，無法復原。確定繼續？',
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
      final result = await _repo.importJson(
        json,
        mode: _mode,
        importSettings: _importSettings,
      );
      ref.invalidate(itemsNotifierProvider);
      ref.invalidate(foldersNotifierProvider);
      ref.invalidate(multiGoalProvider);
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _mode == BackupImportMode.replace
                ? '已還原：${result.itemsAdded} 部作品'
                : '已合併：新增 ${result.itemsAdded}、更新 ${result.itemsMerged}',
          ),
        ),
      );
    } catch (e) {
      setState(() {
        _busy = false;
        _error = '匯入失敗：$e';
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
            Text('匯入備份', style: AppTypography.title),
            const SizedBox(height: 8),
            Text(
              '用於合併另一個瀏覽器網址（port）的庫，或還原 JSON 備份。',
              style: AppTypography.caption,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _busy ? null : _pickFile,
                    icon: const Icon(Icons.upload_file, size: 18),
                    label: const Text('選擇 JSON 檔'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _busy ? null : _fromPaste,
                    icon: const Icon(Icons.content_paste, size: 18),
                    label: const Text('解析貼上內容'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _pasteController,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: '或在此貼上備份 JSON…',
                alignLabelWithHint: true,
              ),
              style: AppTypography.micro.copyWith(
                fontFamily: 'monospace',
                color: context.palette.ink,
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
                      if (_jsonSource != null) _previewFrom(_jsonSource!);
                    },
            ),
            const SizedBox(height: 8),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              value: _importSettings,
              onChanged: _busy
                  ? null
                  : (v) {
                      setState(() => _importSettings = v ?? true);
                      if (_jsonSource != null) _previewFrom(_jsonSource!);
                    },
              title: Text(
                _mode == BackupImportMode.merge
                    ? '一併合併每日進度（目標設定保留本機）'
                    : '一併還原目標與進度設定',
                style: AppTypography.caption.copyWith(
                  color: context.palette.ink,
                ),
              ),
              controlAffinity: ListTileControlAffinity.leading,
            ),
            if (_error != null) ...[
              SizedBox(height: 8),
              Text(
                _error!,
                style: AppTypography.caption.copyWith(color: context.palette.danger),
              ),
            ],
            if (_preview != null) ...[
              SizedBox(height: 12),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: context.palette.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: context.palette.border),
                ),
                child: Text(
                  _mode == BackupImportMode.replace
                      ? '將寫入 ${_preview!.itemsToWrite.length} 部作品、'
                          '${_preview!.foldersToWrite.length} 個資料夾'
                      : '新增 ${_preview!.itemsAdded} · '
                          '合併更新 ${_preview!.itemsMerged} · '
                          '未變 ${_preview!.itemsUnchanged} · '
                          '新資料夾 ${_preview!.foldersAdded}',
                  style: AppTypography.body.copyWith(fontSize: 13),
                ),
              ),
            ],
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _busy || _preview == null ? null : _confirmImport,
              child: _busy
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('確認匯入'),
            ),
            const SizedBox(height: 8),
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

/// Export helpers used from settings.
Future<void> exportLibraryBackup(WidgetRef ref, BuildContext context) async {
  final repo = ref.read(libraryBackupRepositoryProvider);
  final json = repo.exportJsonString();
  final stamp = DateTime.now()
      .toIso8601String()
      .replaceAll(':', '-')
      .split('.')
      .first;
  final name = 'acg-todo-backup-$stamp.json';
  try {
    await downloadTextFile(name, json);
    await ref.read(goalSettingsStoreProvider).markBackupExported();
    ref.read(dailyGoalTickProvider.notifier).state++;
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('已下載 $name')),
      );
    }
  } catch (_) {
    await Clipboard.setData(ClipboardData(text: json));
    await ref.read(goalSettingsStoreProvider).markBackupExported();
    ref.read(dailyGoalTickProvider.notifier).state++;
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('無法下載檔案，已複製完整 JSON 到剪貼簿'),
        ),
      );
    }
  }
}
