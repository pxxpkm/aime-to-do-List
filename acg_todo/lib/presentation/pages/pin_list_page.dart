import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:reorderable_grid_view/reorderable_grid_view.dart';

import 'package:acg_todo/core/theme/app_colors.dart';
import 'package:acg_todo/core/theme/app_scaffold.dart';
import 'package:acg_todo/core/theme/app_shadows.dart';
import 'package:acg_todo/core/theme/app_typography.dart';
import 'package:acg_todo/domain/entities/item.dart';
import 'package:acg_todo/domain/entities/pin_tier.dart';
import 'package:acg_todo/presentation/home/home_item_query.dart';
import 'package:acg_todo/presentation/home/home_layout.dart';
import 'package:acg_todo/presentation/providers/daily_goal_provider.dart';
import 'package:acg_todo/presentation/providers/items_provider.dart';
import 'package:acg_todo/presentation/providers/repository_providers.dart';
import 'package:acg_todo/presentation/widgets/poster_card.dart';

/// Full list for a pin tier (正在追 / 優先追).
class PinListPage extends ConsumerStatefulWidget {
  final PinTier tier;

  const PinListPage({super.key, required this.tier});

  static PinTier? parseTier(String? raw) {
    if (raw == null) return null;
    if (raw == PinTier.watching.name) return PinTier.watching;
    if (raw == PinTier.priority.name) return PinTier.priority;
    return null;
  }

  @override
  ConsumerState<PinListPage> createState() => _PinListPageState();
}

class _PinListPageState extends ConsumerState<PinListPage> {
  List<Item> _tierItems(List<Item> all) {
    final list = all
        .where((i) => i.pinTier == widget.tier && isActiveItem(i))
        .toList()
      ..sort((a, b) {
        final o = a.pinOrder.compareTo(b.pinOrder);
        if (o != 0) return o;
        return a.sortOrder.compareTo(b.sortOrder);
      });
    return list;
  }

  Future<void> _onReorder(int oldIndex, int newIndex, List<Item> items) async {
    if (oldIndex == newIndex) return;
    final list = List<Item>.from(items);
    if (oldIndex < 0 || oldIndex >= list.length) return;
    final item = list.removeAt(oldIndex);
    final insertAt = newIndex.clamp(0, list.length);
    list.insert(insertAt, item);
    await ref
        .read(itemsNotifierProvider.notifier)
        .reorderPinTierItems(widget.tier, list);
  }

  Future<void> _onIncrement(Item item) async {
    await ref.read(itemsNotifierProvider.notifier).incrementProgress(item.id);
  }

  Future<void> _setPinTier(Item item, PinTier tier) async {
    await ref.read(itemsNotifierProvider.notifier).setPinTier(item.id, tier);
    if (!mounted) return;
    final msg = switch (tier) {
      PinTier.watching => '已移到正在追',
      PinTier.priority => '已移到優先追',
      PinTier.none => '已取消置頂',
    };
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        duration: const Duration(milliseconds: 900),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _deleteItem(Item item) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('刪除作品'),
        content: Text('確定刪除「${item.title}」？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('刪除', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    await ref.read(itemsNotifierProvider.notifier).deleteItem(item.id);
  }

  void _showMenu(Item item) {
    final other = widget.tier == PinTier.watching
        ? PinTier.priority
        : PinTier.watching;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.paperElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.open_in_new),
                title: const Text('開啟詳情'),
                onTap: () {
                  Navigator.pop(ctx);
                  context.push('/item/${item.id}');
                },
              ),
              ListTile(
                leading: Icon(
                  other == PinTier.watching
                      ? Icons.play_circle_outline
                      : Icons.star_outline,
                  color: other == PinTier.watching
                      ? AppColors.anime
                      : AppColors.lightNovel,
                ),
                title: Text('移到${other.label}'),
                onTap: () {
                  Navigator.pop(ctx);
                  _setPinTier(item, other);
                },
              ),
              ListTile(
                leading: const Icon(Icons.push_pin_outlined),
                title: const Text('取消置頂'),
                onTap: () {
                  Navigator.pop(ctx);
                  _setPinTier(item, PinTier.none);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline, color: AppColors.danger),
                title: const Text(
                  '刪除',
                  style: TextStyle(color: AppColors.danger),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _deleteItem(item);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.tier != PinTier.watching &&
        widget.tier != PinTier.priority) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) context.go('/');
      });
      return const AppScaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final all = ref.watch(itemsNotifierProvider);
    final items = _tierItems(all);
    ref.watch(dailyGoalTickProvider);
    final density = ref.watch(goalSettingsStoreProvider).homeGridDensity;
    final layout = homeGridLayout(density);
    final accent = widget.tier == PinTier.watching
        ? AppColors.anime
        : AppColors.lightNovel;

    return AppScaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 8, 12, 4),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => context.pop(),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.tier.label,
                          style: AppTypography.title.copyWith(color: accent),
                        ),
                        Text(
                          items.isEmpty
                              ? '尚無作品'
                              : '${items.length} 本 · 長按拖曳排序',
                          style: AppTypography.caption,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: items.isEmpty
                  ? _emptyState(accent)
                  : LayoutBuilder(
                      builder: (context, constraints) {
                        final cols = layout.columns(constraints.maxWidth);
                        if (items.length > 1) {
                          return ReorderableGridView.count(
                            key: ValueKey(
                              'pin_${widget.tier.name}_${items.map((e) => e.id).join(',')}',
                            ),
                            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                            crossAxisCount: cols,
                            childAspectRatio: layout.aspectRatio,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            dragStartDelay: const Duration(milliseconds: 280),
                            onReorder: (o, n) => _onReorder(o, n, items),
                            children: [
                              for (final item in items)
                                PosterCard(
                                  key: ValueKey(item.id),
                                  item: item,
                                  heroTag: '',
                                  onTap: () =>
                                      context.push('/item/${item.id}'),
                                  onIncrement: () => _onIncrement(item),
                                  onMenu: () => _showMenu(item),
                                  longPressOpensMenu: false,
                                ),
                            ],
                          );
                        }
                        return GridView.builder(
                          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: cols,
                            childAspectRatio: layout.aspectRatio,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                          ),
                          itemCount: items.length,
                          itemBuilder: (_, i) {
                            final item = items[i];
                            return PosterCard(
                              item: item,
                              heroTag: '',
                              onTap: () => context.push('/item/${item.id}'),
                              onIncrement: () => _onIncrement(item),
                              onMenu: () => _showMenu(item),
                              longPressOpensMenu: true,
                            );
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyState(Color accent) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
        constraints: const BoxConstraints(maxWidth: 300),
        decoration: BoxDecoration(
          color: AppColors.paperElevated,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.borderSubtle),
          boxShadow: AppShadows.soft,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.push_pin_outlined, size: 48, color: accent),
            const SizedBox(height: 16),
            Text(
              '還沒有${widget.tier.label}的作品',
              textAlign: TextAlign.center,
              style: AppTypography.title.copyWith(fontSize: 17),
            ),
            const SizedBox(height: 8),
            Text(
              '在作品選單用 ⋮ 釘選到${widget.tier.label}',
              textAlign: TextAlign.center,
              style: AppTypography.caption,
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () => context.pop(),
              child: const Text('回主頁'),
            ),
          ],
        ),
      ),
    );
  }
}
