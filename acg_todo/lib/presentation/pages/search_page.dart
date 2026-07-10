import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:acg_todo/core/theme/app_colors.dart';
import 'package:acg_todo/core/utils/poster_url.dart';
import 'package:acg_todo/core/utils/zh_convert.dart';
import 'package:acg_todo/data/models/media_source.dart';
import 'package:acg_todo/data/repositories/bangumi/bangumi_search_result.dart';
import 'package:acg_todo/data/repositories/bangumi/mappers.dart';
import 'package:acg_todo/domain/entities/item_category.dart';
import 'package:acg_todo/presentation/providers/daily_goal_provider.dart';
import 'package:acg_todo/presentation/providers/items_provider.dart';
import 'package:acg_todo/presentation/providers/repository_providers.dart';
import 'package:acg_todo/presentation/widgets/poster_image_widget.dart';
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
    final id = 'bgm_${r.id}';
    if (_justAddedIds.contains(id)) return true;
    return ref.read(itemsNotifierProvider).any((i) => i.id == id);
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(dailyGoalTickProvider);
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => context.pop(),
                    ),
                    const Expanded(
                      child: Text(
                        '搜尋新增',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
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
                padding: const EdgeInsets.symmetric(horizontal: 16),
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
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: ItemCategory.values.map((c) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
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
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: _category == c
                                ? c.color
                                : c.color.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            c.label,
                            style: TextStyle(
                              color: _category == c ? Colors.white : c.color,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 12),
              if (!(_category == ItemCategory.game &&
                  _source == MediaSource.anilist))
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TextField(
                    controller: _searchController,
                    onChanged: _onSearchChanged,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: '搜尋 ${_category.label}...',
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.08),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
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
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white.withValues(alpha: 0.45),
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              Expanded(child: _buildContent()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_category == ItemCategory.game && _source == MediaSource.anilist) {
      return _gameManualPrompt();
    }
    if (_loading) return _shimmerGrid();
    if (_searchController.text.trim().isEmpty) {
      return Center(
        child: Text(
          '輸入關鍵字搜尋\n可連續新增，不會自動返回主頁',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
        ),
      );
    }
    if (_results.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('沒有結果',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.5))),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => context.push('/manual-entry'),
              child: const Text('改手動建立'),
            ),
          ],
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      itemCount: _results.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) {
        final r = _results[i];
        final inList = _isInList(r);
        return Material(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 48,
                height: 64,
                child: PosterImageWidget(
                  posterUrl: r.posterUrl,
                  type: switch (r.type) {
                    2 => 'anime',
                    1 => _category == ItemCategory.lightNovel
                        ? 'light_novel'
                        : 'manga',
                    4 => 'game',
                    _ => 'anime',
                  },
                  fit: BoxFit.cover,
                ),
              ),
            ),
            title: Text(r.displayName, maxLines: 2),
            subtitle: Text(
              [
                if (r.episodes != null) '${r.episodes} 集',
                if (r.chapters != null) '${r.chapters} 章',
                if (r.volumes != null) '${r.volumes} 卷',
                if (r.score != null) '★ ${r.score}',
              ].join(' · '),
              style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
            trailing: inList
                ? const Icon(Icons.check_circle, color: AppColors.success)
                : IconButton(
                    icon: const Icon(Icons.add_circle_outline),
                    color: AppColors.anime,
                    onPressed: () => _addItem(r),
                  ),
          ),
        );
      },
    );
  }

  Widget _gameManualPrompt() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('AniList 不支援遊戲，請用 Bangumi 或手動建立'),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => context.push('/manual-entry'),
            child: const Text('手動建立'),
          ),
        ],
      ),
    );
  }

  Widget _shimmerGrid() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: 6,
      itemBuilder: (_, __) => const Padding(
        padding: EdgeInsets.only(bottom: 10),
        child: ShimmerPlaceholder(height: 72, width: double.infinity),
      ),
    );
  }
}
