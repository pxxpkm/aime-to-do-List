import 'package:acg_todo/domain/entities/folder.dart';
import 'package:acg_todo/domain/entities/item.dart';
import 'package:acg_todo/domain/entities/pin_tier.dart';
import 'package:acg_todo/domain/entities/system_folders.dart';

/// Backup format id written into every export file.
const kBackupFormat = 'acg_todo_backup';
const kBackupVersion = 1;

enum BackupImportMode { merge, replace }

class BackupParseException implements Exception {
  final String message;
  BackupParseException(this.message);
  @override
  String toString() => message;
}

/// Parsed backup payload (validated).
class LibraryBackup {
  final int version;
  final DateTime? exportedAt;
  final String? appVersion;
  final List<Folder> folders;
  final List<Item> items;
  final Map<String, dynamic> settings;

  const LibraryBackup({
    required this.version,
    required this.folders,
    required this.items,
    required this.settings,
    this.exportedAt,
    this.appVersion,
  });
}

class MergePlan {
  final List<Folder> foldersToWrite;
  final List<Item> itemsToWrite;
  final Map<String, dynamic>? settingsToApply;
  final int foldersAdded;
  final int itemsAdded;
  final int itemsMerged;
  final int itemsUnchanged;

  const MergePlan({
    required this.foldersToWrite,
    required this.itemsToWrite,
    required this.foldersAdded,
    required this.itemsAdded,
    required this.itemsMerged,
    required this.itemsUnchanged,
    this.settingsToApply,
  });
}

/// Pure backup serialize / parse / merge (no Hive).
class LibraryBackupService {
  Map<String, dynamic> buildExportMap({
    required List<Folder> folders,
    required List<Item> items,
    required Map<String, dynamic> settings,
    String appVersion = '1.0.0',
    DateTime? exportedAt,
  }) {
    return {
      'format': kBackupFormat,
      'version': kBackupVersion,
      'exportedAt': (exportedAt ?? DateTime.now().toUtc()).toIso8601String(),
      'appVersion': appVersion,
      'folders': folders.map((f) => f.toJson()).toList(),
      'items': items.map((i) => i.toJson()).toList(),
      'settings': settings,
    };
  }

  LibraryBackup parse(Map<String, dynamic> raw) {
    final format = raw['format'] as String?;
    if (format != kBackupFormat) {
      throw BackupParseException('不是 ACG To-Do 備份檔（format 不符）');
    }
    final version = (raw['version'] as num?)?.toInt() ?? 0;
    if (version < 1 || version > kBackupVersion) {
      throw BackupParseException('不支援的備份版本：$version');
    }

    final foldersRaw = raw['folders'];
    final itemsRaw = raw['items'];
    if (foldersRaw is! List || itemsRaw is! List) {
      throw BackupParseException('備份缺少 folders / items');
    }

    final folders = <Folder>[];
    for (final e in foldersRaw) {
      if (e is! Map) continue;
      folders.add(Folder.fromJson(Map<String, dynamic>.from(e)));
    }

    final items = <Item>[];
    for (final e in itemsRaw) {
      if (e is! Map) continue;
      items.add(Item.fromJson(Map<String, dynamic>.from(e)));
    }

    final settingsRaw = raw['settings'];
    final settings = settingsRaw is Map
        ? Map<String, dynamic>.from(settingsRaw)
        : <String, dynamic>{};

    DateTime? exportedAt;
    final ea = raw['exportedAt'] as String?;
    if (ea != null) {
      exportedAt = DateTime.tryParse(ea);
    }

    return LibraryBackup(
      version: version,
      folders: folders,
      items: items,
      settings: settings,
      exportedAt: exportedAt,
      appVersion: raw['appVersion'] as String?,
    );
  }

  LibraryBackup parseJsonString(String json) {
    // Caller decodes; this is for typed entry after jsonDecode.
    throw UnimplementedError('Use parse(Map) after jsonDecode');
  }

  /// Build write plan for [mode] without touching storage.
  MergePlan planImport({
    required List<Folder> localFolders,
    required List<Item> localItems,
    required LibraryBackup backup,
    required BackupImportMode mode,
    bool importSettings = true,
  }) {
    if (mode == BackupImportMode.replace) {
      return _planReplace(
        backup: backup,
        importSettings: importSettings,
      );
    }
    return _planMerge(
      localFolders: localFolders,
      localItems: localItems,
      backup: backup,
      importSettings: importSettings,
    );
  }

  MergePlan _planReplace({
    required LibraryBackup backup,
    required bool importSettings,
  }) {
    final folders = <Folder>[];
    final seen = <String>{};
    // Always keep system completed folder shape from backup or default.
    Folder? system;
    for (final f in backup.folders) {
      if (f.id == SystemFolders.completedId) {
        system = f.copyWith(
          name: SystemFolders.completedName,
          sortOrder: 9999,
        );
      }
    }
    system ??= Folder(
      id: SystemFolders.completedId,
      name: SystemFolders.completedName,
      sortOrder: 9999,
      createdAt: DateTime.now(),
    );
    folders.add(system);
    seen.add(system.id);

    for (final f in backup.folders) {
      if (seen.contains(f.id)) continue;
      folders.add(f);
      seen.add(f.id);
    }

    return MergePlan(
      foldersToWrite: folders,
      itemsToWrite: List<Item>.from(backup.items),
      foldersAdded: folders.length,
      itemsAdded: backup.items.length,
      itemsMerged: 0,
      itemsUnchanged: 0,
      settingsToApply: importSettings ? backup.settings : null,
    );
  }

  MergePlan _planMerge({
    required List<Folder> localFolders,
    required List<Item> localItems,
    required LibraryBackup backup,
    required bool importSettings,
  }) {
    final folderRemap = <String, String>{};
    final foldersById = <String, Folder>{
      for (final f in localFolders) f.id: f,
    };
    final foldersByName = <String, Folder>{};
    for (final f in localFolders) {
      if (f.id == SystemFolders.completedId) continue;
      foldersByName[_normName(f.name)] = f;
    }

    var foldersAdded = 0;
    final foldersOut = Map<String, Folder>.from(foldersById);

    // Ensure system folder
    if (!foldersOut.containsKey(SystemFolders.completedId)) {
      foldersOut[SystemFolders.completedId] = Folder(
        id: SystemFolders.completedId,
        name: SystemFolders.completedName,
        sortOrder: 9999,
        createdAt: DateTime.now(),
      );
      foldersAdded++;
    }
    folderRemap[SystemFolders.completedId] = SystemFolders.completedId;

    for (final incoming in backup.folders) {
      if (incoming.id == SystemFolders.completedId) {
        folderRemap[incoming.id] = SystemFolders.completedId;
        continue;
      }
      if (foldersOut.containsKey(incoming.id)) {
        folderRemap[incoming.id] = incoming.id;
        continue;
      }
      final byName = foldersByName[_normName(incoming.name)];
      if (byName != null) {
        folderRemap[incoming.id] = byName.id;
        continue;
      }
      foldersOut[incoming.id] = incoming;
      foldersByName[_normName(incoming.name)] = incoming;
      folderRemap[incoming.id] = incoming.id;
      foldersAdded++;
    }

    final localById = <String, Item>{for (final i in localItems) i.id: i};
    final matchIndex = _buildMatchIndex(localItems);

    var itemsAdded = 0;
    var itemsMerged = 0;
    var itemsUnchanged = 0;
    final resultById = Map<String, Item>.from(localById);
    var nextSort = 0;
    for (final i in localItems) {
      if (i.sortOrder >= nextSort) nextSort = i.sortOrder + 1;
    }

    for (var incoming in backup.items) {
      // Remap folders
      final fid = incoming.folderId;
      final pfid = incoming.previousFolderId;
      incoming = incoming.copyWith(
        folderId: fid == null ? null : (folderRemap[fid] ?? fid),
        previousFolderId: pfid == null ? null : (folderRemap[pfid] ?? pfid),
      );
      // Drop folder link if target missing
      if (incoming.folderId != null &&
          !foldersOut.containsKey(incoming.folderId)) {
        incoming = incoming.copyWith(folderId: null);
      }
      if (incoming.previousFolderId != null &&
          !foldersOut.containsKey(incoming.previousFolderId)) {
        incoming = incoming.copyWith(previousFolderId: null);
      }

      final matchId = _findMatchId(incoming, matchIndex, resultById);
      if (matchId == null) {
        var toAdd = incoming;
        if (resultById.containsKey(toAdd.id)) {
          // Id collision with different work — new id
          toAdd = toAdd.copyWith(
            id: 'import_${DateTime.now().microsecondsSinceEpoch}_${toAdd.id.hashCode.abs()}',
          );
        }
        if (toAdd.sortOrder == 0) {
          toAdd = toAdd.copyWith(sortOrder: nextSort++);
        }
        resultById[toAdd.id] = toAdd;
        _indexItem(matchIndex, toAdd);
        itemsAdded++;
        continue;
      }

      final local = resultById[matchId]!;
      final merged = mergeItems(local, incoming);
      if (merged == local) {
        itemsUnchanged++;
      } else {
        // If preferred id differs from local, rekey
        if (merged.id != local.id) {
          resultById.remove(local.id);
        }
        resultById[merged.id] = merged;
        _reindexAfterMerge(matchIndex, local, merged);
        itemsMerged++;
      }
    }

    Map<String, dynamic>? settingsOut;
    if (importSettings) {
      settingsOut = mergeSettingsProgressOnly(backup.settings);
    }

    return MergePlan(
      foldersToWrite: foldersOut.values.toList()
        ..sort((a, b) {
          final c = a.sortOrder.compareTo(b.sortOrder);
          return c != 0 ? c : a.id.compareTo(b.id);
        }),
      itemsToWrite: resultById.values.toList(),
      foldersAdded: foldersAdded,
      itemsAdded: itemsAdded,
      itemsMerged: itemsMerged,
      itemsUnchanged: itemsUnchanged,
      settingsToApply: settingsOut,
    );
  }

  /// Merge settings: only progressDays (sum). Goals/UI left to destination.
  Map<String, dynamic> mergeSettingsProgressOnly(Map<String, dynamic> incoming) {
    return {
      'progressDays': _asStringIntMap(incoming['progressDays']),
      // flag so repository knows not to overwrite goals/ui
      '_mergeProgressOnly': true,
    };
  }

  Map<String, int> _asStringIntMap(Object? raw) {
    if (raw is! Map) return {};
    final out = <String, int>{};
    raw.forEach((k, v) {
      if (k is! String) return;
      if (v is int) {
        out[k] = v;
      } else if (v is num) {
        out[k] = v.toInt();
      }
    });
    return out;
  }

  /// Field-level merge of two items representing the same work.
  Item mergeItems(Item a, Item b) {
    final preferB = _preferSideB(a, b);
    final keepId = _preferredId(a, b);

    final currentUnits =
        a.currentUnits > b.currentUnits ? a.currentUnits : b.currentUnits;
    final totalUnits = _maxNullableInt(a.totalUnits, b.totalUnits);
    final status = _mergeStatus(a.status, b.status);
    final completedAt = status == 'completed'
        ? _laterDate(a.completedAt, b.completedAt) ??
            a.completedAt ??
            b.completedAt
        : null;

    final userScore = _preferScore(a, b, preferB);
    final remark = _preferNonEmpty(a.remark, b.remark, preferB);
    final tags = {...a.tags, ...b.tags}.toList()..sort();

    final pinTier = _preferPin(a.pinTier, b.pinTier);
    final pinOrder = pinTier == PinTier.none
        ? 0
        : (pinTier == a.pinTier ? a.pinOrder : b.pinOrder);

    final deadline = _mergeDeadline(a, b, preferB);
    final lastProgressAt = _laterDate(a.lastProgressAt, b.lastProgressAt);

    final base = preferB ? b : a;
    final other = preferB ? a : b;

    return base.copyWith(
      id: keepId,
      currentUnits: currentUnits,
      totalUnits: totalUnits,
      status: status,
      completedAt: completedAt,
      userScore: userScore,
      remark: remark,
      tags: tags,
      pinTier: pinTier,
      pinOrder: pinOrder,
      deadline: deadline,
      lastProgressAt: lastProgressAt,
      posterUrl: base.posterUrl ?? other.posterUrl,
      summary: base.summary ?? other.summary,
      originalTitle: base.originalTitle ?? other.originalTitle,
      airDate: base.airDate ?? other.airDate,
      score: base.score ?? other.score,
      scoreCount: base.scoreCount ?? other.scoreCount,
      externalUrl: base.externalUrl ?? other.externalUrl,
      source: base.source ?? other.source,
      anilistId: base.anilistId ?? other.anilistId,
      unitLabel: base.unitLabel.isNotEmpty ? base.unitLabel : other.unitLabel,
      folderId: base.folderId ?? other.folderId,
      previousFolderId: base.previousFolderId ?? other.previousFolderId,
      bookmarkUnits: base.bookmarkUnits ?? other.bookmarkUnits,
      createdAt: _earlierDate(a.createdAt, b.createdAt) ?? base.createdAt,
      sortOrder: a.sortOrder <= b.sortOrder ? a.sortOrder : b.sortOrder,
    );
  }

  // ── matching helpers ──

  Map<String, String> _buildMatchIndex(List<Item> items) {
    final index = <String, String>{};
    for (final i in items) {
      _indexItem(index, i);
    }
    return index;
  }

  void _indexItem(Map<String, String> index, Item i) {
    index['id:${i.id}'] = i.id;
    if (i.anilistId != null) {
      index['al:${i.anilistId}'] = i.id;
    }
    final bgm = parseBangumiSubjectId(i);
    if (bgm != null) {
      index['bgm:$bgm'] = i.id;
    }
  }

  void _reindexAfterMerge(
    Map<String, String> index,
    Item old,
    Item merged,
  ) {
    index.removeWhere((_, v) => v == old.id);
    _indexItem(index, merged);
  }

  String? _findMatchId(
    Item incoming,
    Map<String, String> index,
    Map<String, Item> byId,
  ) {
    final byExact = index['id:${incoming.id}'];
    if (byExact != null && byId.containsKey(byExact)) return byExact;

    if (incoming.anilistId != null) {
      final byAl = index['al:${incoming.anilistId}'];
      if (byAl != null && byId.containsKey(byAl)) return byAl;
    }

    final bgm = parseBangumiSubjectId(incoming);
    if (bgm != null) {
      final byBgm = index['bgm:$bgm'];
      if (byBgm != null && byId.containsKey(byBgm)) return byBgm;
    }
    return null;
  }

  /// Extract Bangumi subject id from id / externalUrl.
  static int? parseBangumiSubjectId(Item item) {
    final id = item.id;
    if (id.startsWith('bgm_')) {
      return int.tryParse(id.substring(4));
    }
    final url = item.externalUrl;
    if (url != null) {
      final m = RegExp(r'bgm\.tv/subject/(\d+)').firstMatch(url);
      if (m != null) return int.tryParse(m.group(1)!);
    }
    return null;
  }

  static String _normName(String name) => name.trim().toLowerCase();

  static bool _preferSideB(Item a, Item b) {
    final al = a.lastProgressAt;
    final bl = b.lastProgressAt;
    if (al == null && bl == null) return false;
    if (al == null) return true;
    if (bl == null) return false;
    return bl.isAfter(al);
  }

  static String _preferredId(Item a, Item b) {
    final aStable = _isStableId(a.id);
    final bStable = _isStableId(b.id);
    if (aStable && !bStable) return a.id;
    if (bStable && !aStable) return b.id;
    if (a.id.startsWith('bgm_')) return a.id;
    if (b.id.startsWith('bgm_')) return b.id;
    if (a.id.startsWith('al_')) return a.id;
    if (b.id.startsWith('al_')) return b.id;
    return a.id;
  }

  static bool _isStableId(String id) =>
      id.startsWith('bgm_') || id.startsWith('al_');

  static int? _maxNullableInt(int? a, int? b) {
    if (a == null) return b;
    if (b == null) return a;
    return a > b ? a : b;
  }

  static String _mergeStatus(String a, String b) {
    if (a == 'completed' || b == 'completed') return 'completed';
    const rank = {
      'in_progress': 3,
      'paused': 2,
      'dropped': 1,
    };
    final ar = rank[a] ?? 0;
    final br = rank[b] ?? 0;
    return ar >= br ? a : b;
  }

  static double? _preferScore(Item a, Item b, bool preferB) {
    if (a.userScore != null && b.userScore != null) {
      return preferB ? b.userScore : a.userScore;
    }
    return a.userScore ?? b.userScore;
  }

  static String? _preferNonEmpty(String? a, String? b, bool preferB) {
    final aOk = a != null && a.isNotEmpty;
    final bOk = b != null && b.isNotEmpty;
    if (aOk && bOk) return preferB ? b : a;
    if (aOk) return a;
    if (bOk) return b;
    return null;
  }

  static PinTier _preferPin(PinTier a, PinTier b) {
    int rank(PinTier t) => switch (t) {
          PinTier.priority => 2,
          PinTier.watching => 1,
          PinTier.none => 0,
        };
    return rank(a) >= rank(b) ? a : b;
  }

  static DateTime? _mergeDeadline(Item a, Item b, bool preferB) {
    if (a.deadline != null && b.deadline != null) {
      return preferB ? b.deadline : a.deadline;
    }
    return a.deadline ?? b.deadline;
  }

  static DateTime? _laterDate(DateTime? a, DateTime? b) {
    if (a == null) return b;
    if (b == null) return a;
    return a.isAfter(b) ? a : b;
  }

  static DateTime? _earlierDate(DateTime? a, DateTime? b) {
    if (a == null) return b;
    if (b == null) return a;
    return a.isBefore(b) ? a : b;
  }
}
