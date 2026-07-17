import 'dart:convert';

import 'package:acg_todo/core/utils/logger.dart';
import 'package:acg_todo/data/local/goal_settings_store.dart';
import 'package:acg_todo/data/local/hive_cache.dart';
import 'package:acg_todo/data/local/library_store.dart';
import 'package:acg_todo/domain/services/library_backup_service.dart';

class ImportResult {
  final int foldersAdded;
  final int itemsAdded;
  final int itemsMerged;
  final BackupImportMode mode;

  const ImportResult({
    required this.foldersAdded,
    required this.itemsAdded,
    required this.itemsMerged,
    required this.mode,
  });
}

class HiveSnapshotCounts {
  final int itemCount;
  final int folderCount;

  const HiveSnapshotCounts({
    required this.itemCount,
    required this.folderCount,
  });

  bool get isEmpty => itemCount == 0 && folderCount == 0;
}

class LibraryBackupRepository {
  final LibraryStore _store;
  final GoalSettingsStore _goals;
  final LibraryBackupService _service;

  LibraryBackupRepository(
    this._store,
    this._goals, {
    LibraryBackupService? service,
  }) : _service = service ?? LibraryBackupService();

  LibraryBackupService get service => _service;

  /// Pretty-printed JSON backup of the full local library.
  String exportJsonString({String appVersion = '1.0.0'}) {
    final map = _service.buildExportMap(
      folders: _store.getAllFolders(),
      items: _store.getAllItems(),
      settings: _goals.exportForBackup(),
      appVersion: appVersion,
    );
    return const JsonEncoder.withIndent('  ').convert(map);
  }

  LibraryBackup parseJsonString(String json) {
    late final Object? decoded;
    try {
      decoded = jsonDecode(json);
    } catch (_) {
      throw BackupParseException('JSON 無法解析');
    }
    if (decoded is! Map) {
      throw BackupParseException('備份根節點必須是物件');
    }
    return _service.parse(Map<String, dynamic>.from(decoded));
  }

  /// Counts non-system folders in Hive for migrate UI.
  HiveSnapshotCounts hiveSnapshotCounts(HiveCache hive) {
    final items = hive.getAllItems();
    final folders = hive
        .getAllFolders()
        .where((f) => f.id != 'folder_system_completed')
        .toList();
    return HiveSnapshotCounts(
      itemCount: items.length,
      folderCount: folders.length,
    );
  }

  /// Build [LibraryBackup] from browser Hive (migration source).
  LibraryBackup backupFromHive(
    HiveCache hive,
    GoalSettingsStore hiveGoals,
  ) {
    final map = _service.buildExportMap(
      folders: hive.getAllFolders(),
      items: hive.getAllItems(),
      settings: hiveGoals.exportForBackup(),
      appVersion: 'hive-migrate',
    );
    return _service.parse(map);
  }

  MergePlan previewBackup(
    LibraryBackup backup, {
    BackupImportMode mode = BackupImportMode.merge,
    bool importSettings = true,
  }) {
    return _service.planImport(
      localFolders: _store.getAllFolders(),
      localItems: _store.getAllItems(),
      backup: backup,
      mode: mode,
      importSettings: importSettings,
    );
  }

  /// Dry-run merge/replace plan for UI preview.
  MergePlan previewImport(
    String json, {
    BackupImportMode mode = BackupImportMode.merge,
    bool importSettings = true,
  }) {
    final backup = parseJsonString(json);
    return previewBackup(
      backup,
      mode: mode,
      importSettings: importSettings,
    );
  }

  Future<ImportResult> importFromBackup(
    LibraryBackup backup, {
    BackupImportMode mode = BackupImportMode.merge,
    bool importSettings = true,
  }) async {
    final plan = _service.planImport(
      localFolders: _store.getAllFolders(),
      localItems: _store.getAllItems(),
      backup: backup,
      mode: mode,
      importSettings: importSettings,
    );

    await _applyPlan(plan, mode: mode, importSettings: importSettings);
    return ImportResult(
      foldersAdded: plan.foldersAdded,
      itemsAdded: plan.itemsAdded,
      itemsMerged: plan.itemsMerged,
      mode: mode,
    );
  }

  Future<ImportResult> importJson(
    String json, {
    BackupImportMode mode = BackupImportMode.merge,
    bool importSettings = true,
  }) async {
    final backup = parseJsonString(json);
    return importFromBackup(
      backup,
      mode: mode,
      importSettings: importSettings,
    );
  }

  Future<void> _applyPlan(
    MergePlan plan, {
    required BackupImportMode mode,
    required bool importSettings,
  }) async {
    if (mode == BackupImportMode.replace) {
      await _store.replaceLibrary(
        folders: plan.foldersToWrite,
        items: plan.itemsToWrite,
      );
    } else {
      await _store.putFolders(plan.foldersToWrite);
      await _store.putItems(plan.itemsToWrite);
    }

    if (importSettings && plan.settingsToApply != null) {
      final progressOnly = mode == BackupImportMode.merge ||
          plan.settingsToApply!['_mergeProgressOnly'] == true;
      await _goals.applyBackupSettings(
        plan.settingsToApply!,
        progressOnly: progressOnly && mode == BackupImportMode.merge,
        replaceProgress: mode == BackupImportMode.replace,
      );
    }

    Logger().i(
      'Backup import ($mode): +${plan.itemsAdded} items, '
      '~${plan.itemsMerged} merged, +${plan.foldersAdded} folders',
    );
  }

  Future<void> clearLibraryItems() async {
    await _store.clearAllItems();
    Logger().i('Library items cleared');
  }
}
