import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:acg_todo/core/theme/app_colors.dart';
import 'package:acg_todo/core/theme/app_palette.dart';
import 'package:acg_todo/core/theme/app_scaffold.dart';
import 'package:acg_todo/core/theme/app_typography.dart';
import 'package:acg_todo/core/utils/item_display.dart';
import 'package:acg_todo/data/metadata/source_candidate.dart';
import 'package:acg_todo/data/models/media_source.dart';
import 'package:acg_todo/domain/entities/item_category.dart';
import 'package:acg_todo/presentation/providers/daily_goal_provider.dart';
import 'package:acg_todo/presentation/providers/repository_providers.dart';
import 'package:acg_todo/presentation/providers/search_facade.dart';
import 'package:acg_todo/presentation/widgets/category_chip.dart';
import 'package:acg_todo/presentation/widgets/search_result_tile.dart';
import 'package:acg_todo/presentation/widgets/shimmer_placeholder.dart';

/// Search → add. Business logic lives in [searchFacadeProvider].
class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _addItem(SourceCandidate c) async {
    final id =
        await ref.read(searchFacadeProvider.notifier).addCandidate(c);
    if (!mounted) return;
    final title = displayTitle(
      c.displayName,
      simpToTrad: ref.read(goalSettingsStoreProvider).titleSimpToTrad,
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(id != null ? '已新增「$title」' : '「$title」已在清單中'),
        duration: const Duration(milliseconds: 1200),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(dailyGoalTickProvider);
    final facade = ref.watch(searchFacadeProvider);
    final facadeN = ref.read(searchFacadeProvider.notifier);

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
                    icon: Icon(Icons.playlist_add, size: 18),
                    label: Text('批量'),
                    style: TextButton.styleFrom(
                      foregroundColor: context.palette.manga,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => context.push('/manual-entry'),
                    icon: Icon(Icons.add, size: 18),
                    label: Text('手動'),
                    style: TextButton.styleFrom(
                      foregroundColor: context.palette.lightNovel,
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
                selected: {facade.source},
                onSelectionChanged: (s) {
                  facadeN.setSource(s.first);
                  if (_searchController.text.trim().isNotEmpty) {
                    // facade already re-searches
                  }
                },
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  for (final c in ItemCategory.values) ...[
                    CategoryChip(
                      category: c,
                      selected: facade.category == c,
                      onTap: () {
                        facadeN.setCategory(c);
                      },
                    ),
                    const SizedBox(width: 6),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),
            if (!(facade.category == ItemCategory.game &&
                facade.source == MediaSource.anilist))
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: TextField(
                  controller: _searchController,
                  onChanged: facadeN.onQueryChanged,
                  autofocus: true,
                  style: AppTypography.body,
                  decoration: InputDecoration(
                    hintText: '搜尋 ${facade.category.label}...',
                    hintStyle: AppTypography.body.copyWith(
                      color: context.palette.inkMuted,
                    ),
                    prefixIcon: Icon(
                      Icons.search,
                      color: context.palette.inkSecondary,
                    ),
                    filled: true,
                    fillColor: context.palette.elevated,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide:
                          BorderSide(color: context.palette.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide:
                          BorderSide(color: context.palette.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: facade.category.color,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
              ),
            if (facade.convertedQuery != null)
              Padding(
                padding: EdgeInsets.fromLTRB(20, 6, 20, 0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '已轉簡體搜尋：${facade.convertedQuery}',
                    style: AppTypography.micro.copyWith(
                      color: context.palette.inkMuted,
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 16),
            Expanded(child: _buildContent(facade, facadeN)),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(SearchFacadeState facade, SearchFacade facadeN) {
    if (facade.category == ItemCategory.game &&
        facade.source == MediaSource.anilist) {
      return SearchEmptyPanel(
        icon: Icons.sports_esports_outlined,
        title: 'AniList 不支援遊戲',
        subtitle: '請切換 Bangumi，或改用手動建立',
        actionLabel: '手動建立',
        onAction: () => context.push('/manual-entry'),
      );
    }
    if (facade.loading) return _shimmerList();
    if (_searchController.text.trim().isEmpty) {
      return const SearchEmptyPanel(
        icon: Icons.search,
        title: '輸入關鍵字搜尋',
        subtitle: '可連續新增，不會自動返回主頁',
      );
    }
    if (facade.results.isEmpty) {
      return SearchEmptyPanel(
        icon: Icons.inbox_outlined,
        title: '沒有結果',
        subtitle: facade.error ?? '試試其他關鍵字，或手動建立',
        actionLabel: '手動建立',
        onAction: () => context.push('/manual-entry'),
      );
    }
    final s2t = ref.read(goalSettingsStoreProvider).titleSimpToTrad;
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      itemCount: facade.results.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (_, i) {
        final r = facade.results[i];
        final inList = facadeN.isInLibrary(r);
        return SearchResultTile(
          title: displayTitle(r.displayName, simpToTrad: s2t),
          posterUrl: r.posterUrl,
          typeKey: r.categoryHint.storageKey,
          metaLine: r.metaLine(),
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
          width: double.infinity,
          height: 96,
          borderRadius: 16,
        ),
      ),
    );
  }
}
