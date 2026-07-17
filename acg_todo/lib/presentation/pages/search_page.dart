import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:acg_todo/core/theme/app_colors.dart';
import 'package:acg_todo/core/theme/app_scaffold.dart';
import 'package:acg_todo/core/theme/app_typography.dart';
import 'package:acg_todo/core/utils/item_display.dart';
import 'package:acg_todo/core/utils/poster_url.dart';
import 'package:acg_todo/core/utils/zh_convert.dart';
import 'package:acg_todo/data/models/media_source.dart';
import 'package:acg_todo/data/repositories/bangumi/bangumi_search_result.dart';
import 'package:acg_todo/data/repositories/bangumi/mappers.dart';
import 'package:acg_todo/domain/entities/item_category.dart';
import 'package:acg_todo/presentation/providers/daily_goal_provider.dart';
import 'package:acg_todo/presentation/providers/items_provider.dart';
import 'package:acg_todo/presentation/providers/repository_providers.dart';
import 'package:acg_todo/presentation/widgets/category_chip.dart';
import 'package:acg_todo/presentation/widgets/search_result_tile.dart';
import 'package:acg_todo/presentation/widgets/shimmer_placeholder.dart';

class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  final _searchController = TextEditingController();
  Timer? _debounce;
  ItemCategory _category = ItemCategory.anime;
  MediaSource _source = MediaSource.bangumi;
  bool _loading = false;
  List<BangumiSearchResult> _results = [];
  String? _convertedQuery;
  final Set<String> _justAddedIds = {};

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    if (query.trim().isEmpty) {
      setState(() {
        _results = [];
        _convertedQuery = null;
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _search(query);
    });
  }

  String _effectiveQuery(String raw) {
    final q = raw.trim();
    if (q.isEmpty) return q;
    final useT2s = _source == MediaSource.bangumi &&
        ref.read(goalSettingsStoreProvider).searchTradToSimp;
    if (!useT2s) {
      _convertedQuery = null;
      return q;
    }
    final simp = traditionalToSimplified(q);
    _convertedQuery = didConvertToSimplified(q, simp) ? simp : null;
    return simp;
  }

  Future<void> _search(String query) async {
    if (_category == ItemCategory.game && _source == MediaSource.anilist) {
      return;
    }
    setState(() => _loading = true);
    final q = _effectiveQuery(query);
    final results =
        await ref.read(searchMediaProvider(q, _category, _source).future);
    if (mounted) {
      setState(() {
        _results = results;
        _loading = false;
      });
    }
  }

  Future<void> _addItem(BangumiSearchResult result) async {
    var item = result.toItem(
      'local_user',
      preferredCategory: _category,
    );
    item = item.copyWith(posterUrl: normalizePosterUrl(item.posterUrl));
    final ok = await ref.read(itemsNotifierProvider.notifier).addItem(item);
    if (!mounted) return;
    if (ok) {
      setState(() => _justAddedIds.add(item.id));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('已新增「${item.title}」'),
          duration: const Duration(milliseconds: 1200),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('「${item.title}」已在清單中'),
          duration: const Duration(milliseconds: 1200),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  bool _isInList(BangumiSearchResult r) {
    final candidates = <String>{
      'bgm_${r.id}',
      'anilist_${r.id}',
      '${r.id}',
    };
    if (_justAddedIds.any(candidates.contains)) return true;
    return ref.read(itemsNotifierProvider).any(
          (i) =>
              candidates.contains(i.id) ||
              (i.anilistId != null && i.anilistId == r.id),
        );
  }

  String _typeKeyFor(BangumiSearchResult r) {
    return switch (r.type) {
      2 => 'anime',
      1 => _category == ItemCategory.lightNovel ? 'light_novel' : 'manga',
      4 => 'game',
      _ => _category.storageKey,
    };
  }

  String _metaLine(BangumiSearchResult r) {
    return [
      if (r.episodes != null) '${r.episodes} 集',
      if (r.chapters != null) '${r.chapters} 章',
      if (r.volumes != null) '${r.volumes} 卷',
      if (r.score != null) '★ ${r.score}',
    ].join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(dailyGoalTickProvider);
    return AppScaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 8, 8, 4),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => context.pop(),
                  ),
                  Expanded(
                    child: Text(
                      '搜尋新增',
                      style: AppTypography.title,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => context.push('/batch-add'),
                    icon: const Icon(Icons.playlist_add, size: 18),
                    label: const Text('批量'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.manga,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => context.push('/manual-entry'),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('手動'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.lightNovel,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SegmentedButton<MediaSource>(
                segments: const [
                  ButtonSegment(
                    value: MediaSource.anilist,
                    label: Text('AniList'),
                  ),
                  ButtonSegment(
                    value: MediaSource.bangumi,
                    label: Text('Bangumi'),
                  ),
                ],
                selected: {_source},
                style: ButtonStyle(
                  visualDensity: VisualDensity.compact,
                  side: WidgetStatePropertyAll(
                    BorderSide(color: AppColors.borderSubtle),
                  ),
                ),
                onSelectionChanged: (s) {
                  setState(() => _source = s.first);
                  if (_category == ItemCategory.game &&
                      _source == MediaSource.anilist) {
                    setState(() => _source = MediaSource.bangumi);
                  }
                  if (_searchController.text.isNotEmpty) {
                    _search(_searchController.text);
                  }
                },
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  for (final c in ItemCategory.values) ...[
                    CategoryChip(
                      category: c,
                      selected: _category == c,
                      onTap: () {
                        setState(() {
                          _category = c;
                          _results = [];
                        });
                        if (c == ItemCategory.game &&
                            _source == MediaSource.anilist) {
                          return;
                        }
                        if (_searchController.text.isNotEmpty) {
                          _search(_searchController.text);
                        }
                      },
                    ),
                    const SizedBox(width: 8),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),
            if (!(_category == ItemCategory.game &&
                _source == MediaSource.anilist))
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: TextField(
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  autofocus: true,
                  style: AppTypography.body,
                  decoration: InputDecoration(
                    hintText: '搜尋 ${_category.label}...',
                    hintStyle: AppTypography.body.copyWith(
                      color: AppColors.inkMuted,
                    ),
                    prefixIcon: const Icon(
                      Icons.search,
                      color: AppColors.inkSecondary,
                    ),
                    filled: true,
                    fillColor: AppColors.paperElevated,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide:
                          const BorderSide(color: AppColors.borderSubtle),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide:
                          const BorderSide(color: AppColors.borderSubtle),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: _category.color,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
              ),
            if (_convertedQuery != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 6, 20, 0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '已轉簡體搜尋：$_convertedQuery',
                    style: AppTypography.micro.copyWith(
                      color: AppColors.inkMuted,
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 16),
            Expanded(child: _buildContent()),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_category == ItemCategory.game && _source == MediaSource.anilist) {
      return SearchEmptyPanel(
        icon: Icons.sports_esports_outlined,
        title: 'AniList 不支援遊戲',
        subtitle: '請切換 Bangumi，或改用手動建立',
        actionLabel: '手動建立',
        onAction: () => context.push('/manual-entry'),
      );
    }
    if (_loading) return _shimmerList();
    if (_searchController.text.trim().isEmpty) {
      return const SearchEmptyPanel(
        icon: Icons.search,
        title: '輸入關鍵字搜尋',
        subtitle: '可連續新增，不會自動返回主頁',
      );
    }
    if (_results.isEmpty) {
      return SearchEmptyPanel(
        icon: Icons.inbox_outlined,
        title: '沒有結果',
        subtitle: '試試其他關鍵字，或手動建立',
        actionLabel: '手動建立',
        onAction: () => context.push('/manual-entry'),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      itemCount: _results.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (_, i) {
        final r = _results[i];
        final inList = _isInList(r);
        final s2t = ref.read(goalSettingsStoreProvider).titleSimpToTrad;
        return SearchResultTile(
          title: displayTitle(r.displayName, simpToTrad: s2t),
          posterUrl: r.posterUrl,
          typeKey: _typeKeyFor(r),
          metaLine: _metaLine(r),
          inList: inList,
          onAdd: inList ? null : () => _addItem(r),
        );
      },
    );
  }

  Widget _shimmerList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: 6,
      itemBuilder: (_, _) => const Padding(
        padding: EdgeInsets.only(bottom: 12),
        child: ShimmerPlaceholder(
          height: 100,
          width: double.infinity,
          borderRadius: 16,
        ),
      ),
    );
  }
}
