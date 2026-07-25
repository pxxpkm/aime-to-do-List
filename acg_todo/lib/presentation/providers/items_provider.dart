import 'package:acg_todo/core/utils/item_display.dart';
import 'package:acg_todo/core/utils/logger.dart';
import 'package:acg_todo/core/utils/poster_url.dart';
import 'package:acg_todo/data/metadata/source_candidate.dart';
import 'package:acg_todo/data/models/media_source.dart';
import 'package:acg_todo/data/repositories/items_repository.dart';
import 'package:acg_todo/domain/entities/item.dart';
import 'package:acg_todo/domain/entities/item_category.dart';
import 'package:acg_todo/domain/entities/pin_tier.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'daily_goal_provider.dart';
import 'repository_providers.dart';

part 'items_provider.g.dart';

@riverpod
class ItemsNotifier extends _$ItemsNotifier {
  @override
  List<Item> build() {
    final repo = ref.read(itemsRepositoryProvider);
    return repo.getAll();
  }

  ItemsRepository get _repo => ref.read(itemsRepositoryProvider);

  /// Full rebuild — reorders, multi-item pin reindex, bulk import.
  void _refreshFull() {
    state = _repo.getAll();
    ref.invalidate(multiGoalProvider);
  }

  /// Upsert / remove a single id from [state] without scanning the whole DB list
  /// when only that row changed.
  void _patchId(String id) {
    final item = _repo.getById(id);
    if (item == null) {
      state = [for (final e in state) if (e.id != id) e];
    } else {
      final idx = state.indexWhere((e) => e.id == id);
      if (idx < 0) {
        state = [...state, item];
      } else {
        final next = List<Item>.of(state);
        next[idx] = item;
        state = next;
      }
    }
    ref.invalidate(multiGoalProvider);
  }

  void _removeIds(Iterable<String> ids) {
    final set = ids.toSet();
    if (set.isEmpty) return;
    state = [for (final e in state) if (!set.contains(e.id)) e];
    ref.invalidate(multiGoalProvider);
  }

  Item _prepareForStore(Item item) {
    final s2t = ref.read(goalSettingsStoreProvider).titleSimpToTrad;
    return applyTitleS2t(
      item.copyWith(posterUrl: normalizePosterUrl(item.posterUrl)),
      enabled: s2t,
    );
  }

  /// Returns false if duplicate id.
  Future<bool> addItem(Item item) async {
    final stored = _prepareForStore(item);
    final ok = await _repo.addItem(stored);
    if (ok) _patchId(stored.id);
    return ok;
  }

  Future<int> addItems(List<Item> items) async {
    final stored = items.map(_prepareForStore).toList();
    final n = await _repo.addItemsSkipExisting(stored);
    if (n > 0) _refreshFull();
    return n;
  }

  Future<void> setTotalUnits(String id, int? total) async {
    await _repo.setTotalUnits(id, total);
    _patchId(id);
  }

  Future<void> updateProgress(String id, int progress) async {
    await _repo.updateProgress(id, progress);
    _patchId(id);
  }

  Future<void> incrementProgress(String id) async {
    await _repo.incrementUnit(id);
    _patchId(id);
  }

  Future<void> reorderItems(List<Item> ordered) async {
    await _repo.reorder(ordered.map((e) => e.id).toList());
    _refreshFull();
  }

  /// Reorder only the visible subset; other items keep relative order after.
  Future<void> reorderVisibleItems(List<Item> visibleOrdered) async {
    await _repo.reorderVisible(visibleOrdered.map((e) => e.id).toList());
    _refreshFull();
  }

  Future<void> moveToFolder(String itemId, String? folderId) async {
    await _repo.moveToFolder(itemId, folderId);
    _patchId(itemId);
  }

  Future<void> setDeadline(String itemId, DateTime? deadline) async {
    await _repo.setDeadline(itemId, deadline);
    _patchId(itemId);
  }

  Future<void> setDeadlineRemindMode(
    String itemId, {
    required String mode,
    String? customOffsets,
  }) async {
    await _repo.setDeadlineRemindMode(
      itemId,
      mode: mode,
      customOffsets: customOffsets,
    );
    _patchId(itemId);
  }

  Future<void> updateRemark(String id, String? remark) async {
    await _repo.updateRemark(id, remark);
    _patchId(id);
  }

  Future<bool> updateTitle(String id, String title) async {
    final ok = await _repo.updateTitle(id, title);
    if (ok) _patchId(id);
    return ok;
  }

  Future<void> updateType(String id, String type,
      {bool syncUnitLabel = false}) async {
    await _repo.updateType(id, type, syncUnitLabel: syncUnitLabel);
    _patchId(id);
  }

  Future<void> updateUnitLabel(String id, String unitLabel) async {
    await _repo.updateUnitLabel(id, unitLabel);
    _patchId(id);
  }

  Future<void> setUserScore(String id, double? score) async {
    await _repo.setUserScore(id, score);
    _patchId(id);
  }

  Future<void> setTags(String id, List<String> tags) async {
    await _repo.setTags(id, tags);
    _patchId(id);
  }

  Future<void> setStatus(String id, String status) async {
    await _repo.setStatus(id, status);
    _patchId(id);
  }

  Future<void> setPinned(String id, bool pinned) async {
    await _repo.setPinned(id, pinned);
    // May reindex peers in tier.
    _refreshFull();
  }

  Future<void> setPinTier(String id, PinTier tier) async {
    await _repo.setPinTier(id, tier);
    _refreshFull();
  }

  Future<void> reorderPinnedItems(List<Item> ordered) async {
    await _repo.reorderPinned(ordered.map((e) => e.id).toList());
    _refreshFull();
  }

  Future<void> reorderPinTierItems(PinTier tier, List<Item> ordered) async {
    await _repo.reorderPinTier(tier, ordered.map((e) => e.id).toList());
    _refreshFull();
  }

  Future<void> deleteItem(String id) async {
    await _repo.deleteItem(id);
    _removeIds([id]);
  }

  Future<void> deleteItems(List<String> ids) async {
    await _repo.deleteItems(ids);
    _removeIds(ids);
  }

  Future<void> markComplete(String id) async {
    await _repo.markComplete(id);
    _patchId(id);
  }

  Future<void> uncomplete(String id) async {
    await _repo.uncomplete(id);
    _patchId(id);
  }

  Future<void> bookmarkItem(String id, int progress) async {
    await _repo.bookmarkItem(id, progress);
    _patchId(id);
  }

  Future<void> clearBookmark(String id) async {
    await _repo.clearBookmark(id);
    _patchId(id);
  }

  static final Set<String> _posterFetchingIds = {};

  Future<void> ensureBangumiPoster(String itemId) async {
    final item = _repo.getById(itemId);
    if (item == null) return;
    if (item.posterUrl != null && item.posterUrl!.isNotEmpty) return;
    if (!itemId.startsWith('bgm_')) return;
    if (_posterFetchingIds.contains(itemId)) return;

    _posterFetchingIds.add(itemId);
    try {
      final id = int.tryParse(itemId.replaceFirst('bgm_', ''));
      if (id == null) return;

      final client = ref.read(bangumiClientProvider);
      final token = ref.read(bangumiTokenStoreProvider).token;
      final detail = await client.getSubject(id, token: token);
      final url = normalizePosterUrl(detail?.posterUrl);
      if (url == null) return;

      final updated = item.copyWith(posterUrl: url);
      await _repo.updateItem(updated);
      _patchId(itemId);
    } catch (e) {
      Logger().w('ensureBangumiPoster: failed $e');
    } finally {
      _posterFetchingIds.remove(itemId);
    }
  }
}

@riverpod
Future<List<SourceCandidate>> searchMedia(
  SearchMediaRef ref,
  String query,
  ItemCategory category,
  MediaSource source,
) async {
  if (query.trim().isEmpty) return [];
  final key = switch (source) {
    MediaSource.bangumi => 'bangumi',
    MediaSource.anilist => 'anilist',
  };
  final token = ref.read(bangumiTokenStoreProvider).token;
  return ref.read(sourceRegistryProvider).search(
        key,
        query,
        category,
        token: token,
      );
}
