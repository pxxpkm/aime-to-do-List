import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:acg_todo/core/utils/zh_convert.dart';
import 'package:acg_todo/data/metadata/source_candidate.dart';
import 'package:acg_todo/data/metadata/source_registry.dart';
import 'package:acg_todo/data/models/media_source.dart';
import 'package:acg_todo/domain/entities/item_category.dart';
import 'package:acg_todo/presentation/providers/items_provider.dart';
import 'package:acg_todo/presentation/providers/repository_providers.dart';

/// UI-facing search session: query / source / category / results.
class SearchFacadeState {
  final String query;
  final ItemCategory category;
  final MediaSource source;
  final bool loading;
  final List<SourceCandidate> results;
  final String? convertedQuery;
  final Set<String> justAddedIds;
  final String? error;

  const SearchFacadeState({
    this.query = '',
    this.category = ItemCategory.anime,
    this.source = MediaSource.bangumi,
    this.loading = false,
    this.results = const [],
    this.convertedQuery,
    this.justAddedIds = const {},
    this.error,
  });

  SearchFacadeState copyWith({
    String? query,
    ItemCategory? category,
    MediaSource? source,
    bool? loading,
    List<SourceCandidate>? results,
    String? convertedQuery,
    bool clearConverted = false,
    Set<String>? justAddedIds,
    String? error,
    bool clearError = false,
  }) {
    return SearchFacadeState(
      query: query ?? this.query,
      category: category ?? this.category,
      source: source ?? this.source,
      loading: loading ?? this.loading,
      results: results ?? this.results,
      convertedQuery:
          clearConverted ? null : (convertedQuery ?? this.convertedQuery),
      justAddedIds: justAddedIds ?? this.justAddedIds,
      error: clearError ? null : (error ?? this.error),
    );
  }

  String get sourceKey => switch (source) {
        MediaSource.bangumi => 'bangumi',
        MediaSource.anilist => 'anilist',
      };
}

class SearchFacade extends Notifier<SearchFacadeState> {
  Timer? _debounce;

  @override
  SearchFacadeState build() {
    ref.onDispose(() => _debounce?.cancel());
    return const SearchFacadeState();
  }

  SourceRegistry get _registry => ref.read(sourceRegistryProvider);

  void setCategory(ItemCategory category) {
    var source = state.source;
    if (category == ItemCategory.game && source == MediaSource.anilist) {
      source = MediaSource.bangumi;
    }
    state = state.copyWith(category: category, source: source);
    if (state.query.trim().isNotEmpty) {
      scheduleSearch(state.query);
    }
  }

  void setSource(MediaSource source) {
    if (state.category == ItemCategory.game &&
        source == MediaSource.anilist) {
      return;
    }
    state = state.copyWith(source: source);
    if (state.query.trim().isNotEmpty) {
      scheduleSearch(state.query);
    }
  }

  void onQueryChanged(String raw) {
    _debounce?.cancel();
    final q = raw.trim();
    if (q.isEmpty) {
      state = state.copyWith(
        query: '',
        results: const [],
        loading: false,
        clearConverted: true,
        clearError: true,
      );
      return;
    }
    state = state.copyWith(query: raw);
    _debounce = Timer(const Duration(milliseconds: 500), () {
      scheduleSearch(raw);
    });
  }

  String _effectiveQuery(String raw) {
    final q = raw.trim();
    if (q.isEmpty) return q;
    final useT2s = state.source == MediaSource.bangumi &&
        ref.read(goalSettingsStoreProvider).searchTradToSimp;
    if (!useT2s) {
      state = state.copyWith(clearConverted: true);
      return q;
    }
    final simp = traditionalToSimplified(q);
    final converted = didConvertToSimplified(q, simp) ? simp : null;
    state = state.copyWith(
      convertedQuery: converted,
      clearConverted: converted == null,
    );
    return simp;
  }

  Future<void> scheduleSearch(String raw) async {
    if (state.category == ItemCategory.game &&
        state.source == MediaSource.anilist) {
      state = state.copyWith(
        loading: false,
        results: const [],
        error: 'AniList 不支援遊戲',
      );
      return;
    }
    final q = _effectiveQuery(raw);
    if (q.isEmpty) return;

    state = state.copyWith(loading: true, clearError: true);
    try {
      final token = ref.read(bangumiTokenStoreProvider).token;
      final results = await _registry.search(
        state.sourceKey,
        q,
        state.category,
        token: token,
      );
      state = state.copyWith(loading: false, results: results);
    } catch (e) {
      state = state.copyWith(
        loading: false,
        results: const [],
        error: '$e',
      );
    }
  }

  bool isInLibrary(SourceCandidate c) {
    if (state.justAddedIds.intersection(c.matchIds).isNotEmpty) return true;
    final items = ref.read(itemsNotifierProvider);
    return items.any(
      (i) =>
          c.matchIds.contains(i.id) ||
          (i.anilistId != null &&
              c.sourceKey == 'anilist' &&
              '${i.anilistId}' == c.externalId),
    );
  }

  /// Returns added item id, or null if duplicate / failed.
  Future<String?> addCandidate(SourceCandidate c) async {
    final item = c.toItem('local_user', preferredCategory: state.category);
    final ok = await ref.read(itemsNotifierProvider.notifier).addItem(item);
    if (ok) {
      state = state.copyWith(
        justAddedIds: {...state.justAddedIds, item.id},
      );
      return item.id;
    }
    return null;
  }
}

final searchFacadeProvider =
    NotifierProvider<SearchFacade, SearchFacadeState>(SearchFacade.new);
