import 'package:acg_todo/core/utils/logger.dart';
import 'package:acg_todo/core/utils/score_utils.dart';
import 'package:acg_todo/core/utils/tag_utils.dart';
import 'package:acg_todo/data/local/hive_cache.dart';
import 'package:acg_todo/data/local/goal_settings_store.dart';
import 'package:acg_todo/domain/entities/item.dart';
import 'package:acg_todo/domain/entities/item_category.dart';
import 'package:acg_todo/domain/entities/system_folders.dart';
import 'package:acg_todo/data/repositories/anilist/anilist_client.dart';

class ItemsRepository {
  final HiveCache _cache;
  final AniListClient _anilistClient;
  final GoalSettingsStore _goalSettings;

  ItemsRepository(this._cache, this._anilistClient, this._goalSettings);

  List<Item> getAll() => _cache.getAllItems();

  List<Item> getByType(String type) => _cache.getItemsByType(type);

  Item? getById(String id) => _cache.getItem(id);

  /// Returns false if an item with the same id already exists.
  Future<bool> addItem(Item item) async {
    if (_cache.getItem(item.id) != null) {
      Logger().i('Item already exists, skip: ${item.id}');
      return false;
    }
    final withOrder = item.sortOrder == 0
        ? item.copyWith(sortOrder: _cache.nextSortOrder())
        : item;
    await _cache.putItem(withOrder);
    Logger().i('Item added: ${withOrder.title}');
    return true;
  }

  Future<int> addItemsSkipExisting(List<Item> items) async {
    var n = 0;
    for (final item in items) {
      if (await addItem(item)) n++;
    }
    return n;
  }

  Future<void> setTotalUnits(String id, int? total) async {
    final item = _cache.getItem(id);
    if (item == null) return;
    final t = total != null && total > 0 ? total : null;
    var current = item.currentUnits;
    if (t != null && current > t) current = t;
    final becomingComplete = t != null && current >= t;
    await _cache.putItem(_applyCompletionState(
      item.copyWith(totalUnits: t, currentUnits: current),
      complete: becomingComplete,
    ));
    Logger().d('Item $id totalUnits → $t');
  }

  Item _applyCompletionState(Item item, {required bool complete}) {
    if (complete) {
      final prev = item.folderId == SystemFolders.completedId
          ? item.previousFolderId
          : item.folderId;
      return item.copyWith(
        status: 'completed',
        completedAt: item.completedAt ?? DateTime.now(),
        previousFolderId: prev,
        folderId: SystemFolders.completedId,
      );
    }
    return item;
  }

  Future<void> updateItem(Item item) async {
    await _cache.putItem(item);
    Logger().d('Item updated: ${item.id}');
  }

  Future<void> deleteItem(String id) async {
    await _cache.deleteItem(id);
    Logger().d('Item deleted: $id');
  }

  Future<void> deleteItems(List<String> ids) async {
    for (final id in ids) {
      await _cache.deleteItem(id);
    }
    Logger().d('Deleted ${ids.length} items');
  }

  /// Returns units actually added (0 if no change).
  Future<int> updateProgress(String id, int newProgress) async {
    final item = _cache.getItem(id);
    if (item == null || item.currentUnits == newProgress) return 0;

    final total = item.totalUnits;
    final clamped = total != null && newProgress > total ? total : newProgress;
    if (clamped == item.currentUnits) return 0;

    final delta = clamped - item.currentUnits;
    final becomingComplete = total != null && clamped >= total;
    var updated = item.copyWith(
      currentUnits: clamped,
      lastProgressAt: delta > 0 ? DateTime.now() : item.lastProgressAt,
    );
    if (becomingComplete) {
      updated = _applyCompletionState(updated, complete: true);
    } else if (item.status == 'completed' && !becomingComplete) {
      // Progress reduced below total — leave status; user can uncomplete explicitly
      updated = updated.copyWith(status: item.status, completedAt: item.completedAt);
    }
    await _cache.putItem(updated);

    if (delta > 0) {
      await _goalSettings.addProgressDelta(delta);
    }
    Logger().d('Progress updated: $id → $clamped (delta $delta)');
    return delta > 0 ? delta : 0;
  }

  Future<void> markComplete(String id) async {
    final item = _cache.getItem(id);
    if (item == null) return;
    final total = item.totalUnits ?? item.currentUnits;
    final current = total > item.currentUnits ? total : item.currentUnits;
    final updated = _applyCompletionState(
      item.copyWith(currentUnits: current, totalUnits: item.totalUnits ?? current),
      complete: true,
    );
    await _cache.putItem(updated);
    Logger().d('Item marked complete: $id');
  }

  Future<void> uncomplete(String id) async {
    final item = _cache.getItem(id);
    if (item == null) return;
    final restore = item.previousFolderId == SystemFolders.completedId
        ? null
        : item.previousFolderId;
    await _cache.putItem(item.copyWith(
      status: 'in_progress',
      completedAt: null,
      folderId: restore,
      previousFolderId: null,
    ));
    Logger().d('Item uncompleted: $id → folder $restore');
  }

  Future<void> moveToFolder(String itemId, String? folderId) async {
    final item = _cache.getItem(itemId);
    if (item == null) return;
    if (item.folderId == folderId) return;

    // Drag into completed folder = mark complete
    if (folderId == SystemFolders.completedId) {
      await markComplete(itemId);
      return;
    }

    // Drag out of completed = uncomplete into target
    if (item.folderId == SystemFolders.completedId ||
        item.status == 'completed') {
      await _cache.putItem(item.copyWith(
        status: 'in_progress',
        completedAt: null,
        folderId: folderId,
        previousFolderId: null,
      ));
      Logger().d('Item $itemId uncompleted via move → $folderId');
      return;
    }

    await _cache.putItem(item.copyWith(folderId: folderId));
    Logger().d('Item $itemId → folder $folderId');
  }

  Future<int> incrementUnit(String id) async {
    final item = _cache.getItem(id);
    if (item == null) return 0;
    return updateProgress(id, item.currentUnits + 1);
  }

  /// Persist new order; [orderedIds] is full list front-to-back (sortOrder 0..n-1).
  Future<void> reorder(List<String> orderedIds) async {
    for (var i = 0; i < orderedIds.length; i++) {
      final item = _cache.getItem(orderedIds[i]);
      if (item == null) continue;
      if (item.sortOrder == i) continue;
      await _cache.putItem(item.copyWith(sortOrder: i));
    }
    Logger().d('Reordered ${orderedIds.length} items');
  }

  /// Rebuild full sortOrder: [visibleOrderedIds] first (new relative order),
  /// then remaining items keep previous relative order.
  Future<void> reorderVisible(List<String> visibleOrderedIds) async {
    final all = _cache.getAllItems();
    final visibleSet = visibleOrderedIds.toSet();
    final rest = all
        .where((i) => !visibleSet.contains(i.id))
        .map((i) => i.id)
        .toList();
    await reorder([...visibleOrderedIds, ...rest]);
  }

  Future<void> setDeadline(String itemId, DateTime? deadline) async {
    final item = _cache.getItem(itemId);
    if (item == null) return;
    await _cache.putItem(item.copyWith(deadline: deadline));
    Logger().d('Item $itemId deadline → $deadline');
  }

  Future<void> setDeadlineRemindMode(
    String itemId, {
    required String mode,
    String? customOffsets,
  }) async {
    final item = _cache.getItem(itemId);
    if (item == null) return;
    await _cache.putItem(item.copyWith(
      deadlineRemindMode: mode,
      customDeadlineOffsets: customOffsets,
    ));
  }

  Future<void> updateRemark(String id, String? remark) async {
    final item = _cache.getItem(id);
    if (item == null) return;
    final t = remark?.trim();
    await _cache.putItem(item.copyWith(
      remark: (t == null || t.isEmpty) ? null : t,
    ));
    Logger().d('Item $id remark updated');
  }

  /// Returns false if title empty after trim.
  Future<bool> updateTitle(String id, String title) async {
    final item = _cache.getItem(id);
    if (item == null) return false;
    final t = title.trim();
    if (t.isEmpty) return false;
    await _cache.putItem(item.copyWith(title: t));
    return true;
  }

  Future<void> updateType(String id, String type, {bool syncUnitLabel = false}) async {
    final item = _cache.getItem(id);
    if (item == null) return;
    final cat = ItemCategory.fromStorageKey(type);
    await _cache.putItem(item.copyWith(
      type: cat.storageKey,
      unitLabel: syncUnitLabel ? cat.unitLabel : item.unitLabel,
    ));
  }

  Future<void> updateUnitLabel(String id, String unitLabel) async {
    final item = _cache.getItem(id);
    if (item == null) return;
    final t = unitLabel.trim();
    if (t.isEmpty) return;
    await _cache.putItem(item.copyWith(unitLabel: t));
  }

  Future<void> setUserScore(String id, double? score) async {
    final item = _cache.getItem(id);
    if (item == null) return;
    await _cache.putItem(item.copyWith(userScore: roundUserScore(score)));
  }

  Future<void> setTags(String id, List<String> tags) async {
    final item = _cache.getItem(id);
    if (item == null) return;
    await _cache.putItem(item.copyWith(tags: normalizeTags(tags)));
  }

  /// Status: in_progress | paused | dropped | completed.
  Future<void> setStatus(String id, String status) async {
    final item = _cache.getItem(id);
    if (item == null) return;
    switch (status) {
      case 'completed':
        await markComplete(id);
        return;
      case 'in_progress':
        if (item.status == 'completed') {
          await uncomplete(id);
          return;
        }
        await _cache.putItem(item.copyWith(
          status: 'in_progress',
          completedAt: null,
        ));
        return;
      case 'paused':
      case 'dropped':
        if (item.status == 'completed' ||
            item.folderId == SystemFolders.completedId) {
          final restore = item.previousFolderId == SystemFolders.completedId
              ? null
              : item.previousFolderId;
          await _cache.putItem(item.copyWith(
            status: status,
            completedAt: null,
            folderId: restore ?? item.folderId,
            previousFolderId: null,
          ));
        } else {
          await _cache.putItem(item.copyWith(
            status: status,
            completedAt: null,
          ));
        }
        return;
      default:
        return;
    }
  }

  List<String> allTags() {
    final counts = <String, int>{};
    for (final item in _cache.getAllItems()) {
      for (final t in item.tags) {
        counts[t] = (counts[t] ?? 0) + 1;
      }
    }
    final keys = counts.keys.toList()
      ..sort((a, b) {
        final c = (counts[b] ?? 0).compareTo(counts[a] ?? 0);
        if (c != 0) return c;
        return a.compareTo(b);
      });
    return keys;
  }

  Future<void> bookmarkItem(String id, int progress) async {
    final item = _cache.getItem(id);
    if (item == null) return;
    final updated = item.copyWith(bookmarkUnits: progress);
    await _cache.putItem(updated);
    Logger().d('Bookmark set: $id → $progress');
  }

  Future<void> clearBookmark(String id) async {
    final item = _cache.getItem(id);
    if (item == null) return;
    final updated = item.copyWith(bookmarkUnits: null);
    await _cache.putItem(updated);
    Logger().d('Bookmark cleared: $id');
  }

  Future<List<AniListSearchResult>> searchAniList(
    String query,
    String type,
  ) async {
    return _anilistClient.search(query, type);
  }
}
