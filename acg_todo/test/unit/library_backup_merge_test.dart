import 'package:acg_todo/domain/entities/folder.dart';
import 'package:acg_todo/domain/entities/item.dart';
import 'package:acg_todo/domain/entities/pin_tier.dart';
import 'package:acg_todo/domain/entities/system_folders.dart';
import 'package:acg_todo/domain/services/library_backup_service.dart';
import 'package:flutter_test/flutter_test.dart';

Item _item({
  required String id,
  String title = 'T',
  int current = 0,
  int? total,
  String status = 'in_progress',
  int? anilistId,
  String? source,
  String? folderId,
  String? externalUrl,
  PinTier pin = PinTier.none,
  List<String> tags = const [],
  double? userScore,
  DateTime? lastProgressAt,
}) {
  return Item(
    id: id,
    userId: 'local_user',
    type: 'anime',
    title: title,
    currentUnits: current,
    totalUnits: total,
    status: status,
    anilistId: anilistId,
    source: source,
    folderId: folderId,
    externalUrl: externalUrl,
    pinTier: pin,
    tags: tags,
    userScore: userScore,
    lastProgressAt: lastProgressAt,
    createdAt: DateTime(2026, 1, 1),
  );
}

void main() {
  final service = LibraryBackupService();

  group('parse', () {
    test('rejects wrong format', () {
      expect(
        () => service.parse({'format': 'x', 'version': 1}),
        throwsA(isA<BackupParseException>()),
      );
    });

    test('roundtrip export map', () {
      final folders = [
        Folder(
          id: SystemFolders.completedId,
          name: SystemFolders.completedName,
          sortOrder: 9999,
        ),
      ];
      final items = [_item(id: 'bgm_1', title: 'A', current: 3)];
      final map = service.buildExportMap(
        folders: folders,
        items: items,
        settings: {
          'progressDays': {'2026-07-01': 2},
        },
      );
      final backup = service.parse(map);
      expect(backup.items, hasLength(1));
      expect(backup.items.first.currentUnits, 3);
      expect(backup.folders.first.id, SystemFolders.completedId);
    });
  });

  group('mergeItems', () {
    test('progress takes max', () {
      final a = _item(id: 'bgm_1', current: 5, total: 12);
      final b = _item(id: 'bgm_1', current: 8, total: 10);
      final m = service.mergeItems(a, b);
      expect(m.currentUnits, 8);
      expect(m.totalUnits, 12);
    });

    test('completed wins status', () {
      final a = _item(id: 'bgm_1', status: 'in_progress', current: 2);
      final b = _item(id: 'bgm_1', status: 'completed', current: 12, total: 12);
      final m = service.mergeItems(a, b);
      expect(m.status, 'completed');
      expect(m.currentUnits, 12);
    });

    test('tags union and pin prefer priority', () {
      final a = _item(
        id: 'bgm_1',
        tags: const ['a'],
        pin: PinTier.watching,
      );
      final b = _item(
        id: 'bgm_1',
        tags: const ['b'],
        pin: PinTier.priority,
      );
      final m = service.mergeItems(a, b);
      expect(m.tags, containsAll(['a', 'b']));
      expect(m.pinTier, PinTier.priority);
    });

    test('prefer stable bgm id over manual', () {
      final a = _item(id: 'manual_1', title: 'X', current: 1);
      final b = _item(id: 'bgm_99', title: 'X', current: 2);
      final m = service.mergeItems(a, b);
      expect(m.id, 'bgm_99');
      expect(m.currentUnits, 2);
    });
  });

  group('planImport merge', () {
    test('same bgm id merges progress', () {
      final local = [_item(id: 'bgm_1', current: 3)];
      final backup = LibraryBackup(
        version: 1,
        folders: const [],
        items: [_item(id: 'bgm_1', current: 7)],
        settings: const {},
      );
      final plan = service.planImport(
        localFolders: const [],
        localItems: local,
        backup: backup,
        mode: BackupImportMode.merge,
      );
      expect(plan.itemsAdded, 0);
      expect(plan.itemsMerged, 1);
      expect(plan.itemsToWrite.single.currentUnits, 7);
    });

    test('match by anilistId across ids', () {
      final local = [
        _item(id: 'al_100', anilistId: 100, current: 1, source: 'anilist'),
      ];
      final backup = LibraryBackup(
        version: 1,
        folders: const [],
        items: [
          _item(
            id: 'import_x',
            anilistId: 100,
            current: 5,
            source: 'anilist',
          ),
        ],
        settings: const {},
      );
      final plan = service.planImport(
        localFolders: const [],
        localItems: local,
        backup: backup,
        mode: BackupImportMode.merge,
      );
      expect(plan.itemsAdded, 0);
      expect(plan.itemsMerged, 1);
      expect(plan.itemsToWrite.single.currentUnits, 5);
      expect(plan.itemsToWrite.single.id, 'al_100');
    });

    test('new item is added', () {
      final local = [_item(id: 'bgm_1', current: 1)];
      final backup = LibraryBackup(
        version: 1,
        folders: const [],
        items: [_item(id: 'bgm_2', title: 'B', current: 0)],
        settings: const {},
      );
      final plan = service.planImport(
        localFolders: const [],
        localItems: local,
        backup: backup,
        mode: BackupImportMode.merge,
      );
      expect(plan.itemsAdded, 1);
      expect(plan.itemsToWrite, hasLength(2));
    });

    test('folder remap by name', () {
      final localFolders = [
        Folder(id: 'folder_local', name: '冬番', sortOrder: 0),
      ];
      final backup = LibraryBackup(
        version: 1,
        folders: [
          Folder(id: 'folder_remote', name: '冬番', sortOrder: 0),
        ],
        items: [
          _item(id: 'bgm_1', folderId: 'folder_remote', current: 1),
        ],
        settings: const {},
      );
      final plan = service.planImport(
        localFolders: localFolders,
        localItems: const [],
        backup: backup,
        mode: BackupImportMode.merge,
      );
      // system completed folder may be auto-added; 冬番 must remap not duplicate
      expect(
        plan.foldersToWrite.where((f) => f.name == '冬番'),
        hasLength(1),
      );
      final item = plan.itemsToWrite.single;
      expect(item.folderId, 'folder_local');
    });

    test('parseBangumiSubjectId from url', () {
      final item = _item(
        id: 'x',
        externalUrl: 'https://bgm.tv/subject/12345',
      );
      expect(LibraryBackupService.parseBangumiSubjectId(item), 12345);
    });
  });
}
