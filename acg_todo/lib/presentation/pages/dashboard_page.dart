import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:acg_todo/core/theme/app_colors.dart';
import 'package:acg_todo/core/theme/app_palette.dart';
import 'package:acg_todo/core/theme/app_scaffold.dart';
import 'package:acg_todo/core/theme/app_typography.dart';
import 'package:acg_todo/domain/entities/item.dart';
import 'package:acg_todo/domain/entities/pin_tier.dart';
import 'package:acg_todo/presentation/providers/daily_goal_provider.dart';
import 'package:acg_todo/presentation/providers/items_provider.dart';
import 'package:acg_todo/presentation/widgets/continue_strip.dart';
import 'package:acg_todo/presentation/widgets/home_hero_stage.dart';
import 'package:acg_todo/presentation/widgets/storage_mode_banner.dart';

/// Gallery homepage: immersive poster (goal pill) → 接下來 strip.
class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(dailyGoalTickProvider);
    final items = ref.watch(itemsNotifierProvider);
    final nextUp = _nextUpPool(items);

    return AppScaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const StorageModeBanner(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(bottom: 88),
                children: [
                  const SizedBox(height: 4),
                  // 1. Immersive hero (poster + goal pill + CTAs)
                  HomeHeroStage(
                    items: items,
                    onOpenItem: (item) => context.push('/item/${item.id}'),
                    onIncrement: (item) =>
                        _onIncrement(context, ref, item),
                  ),
                  // 2. Single "接下來" stream (continue + pins)
                  if (nextUp.isNotEmpty) ...[
                    Padding(
                      padding: EdgeInsets.fromLTRB(20, 12, 12, 6),
                      child: Row(
                        children: [
                          Text(
                            '接下來',
                            style: AppTypography.title.copyWith(
                              fontSize: 17,
                              color: context.palette.ink,
                            ),
                          ),
                          Spacer(),
                          TextButton(
                            onPressed: () => context.go('/library'),
                            style: TextButton.styleFrom(
                              foregroundColor: context.palette.inkSecondary,
                              visualDensity: VisualDensity.compact,
                            ),
                            child: const Text('媒體庫'),
                          ),
                        ],
                      ),
                    ),
                    // Pin summary chips (compact, not dual board)
                    if (_pinCount(items) > 0)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                        child: Wrap(
                          spacing: 8,
                          children: [
                            if (items.any((i) => i.pinTier == PinTier.watching))
                              ActionChip(
                                avatar: const Icon(Icons.push_pin, size: 16),
                                label: Text(
                                  '正在追 ${_countTier(items, PinTier.watching)}',
                                ),
                                onPressed: () =>
                                    context.push('/pin/watching'),
                              ),
                            if (items.any((i) => i.pinTier == PinTier.priority))
                              ActionChip(
                                avatar: Icon(
                                  Icons.star,
                                  size: 16,
                                  color: context.palette.lightNovel,
                                ),
                                label: Text(
                                  '優先 ${_countTier(items, PinTier.priority)}',
                                ),
                                onPressed: () =>
                                    context.push('/pin/priority'),
                              ),
                          ],
                        ),
                      ),
                    ContinueStrip(
                      items: nextUp,
                      onTap: (item) => context.push('/item/${item.id}'),
                      onIncrement: (item) =>
                          _onIncrement(context, ref, item),
                    ),
                  ] else if (items.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
                      child: Text(
                        '沒有進行中的作品 · 去媒體庫逛逛',
                        style: AppTypography.caption,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Center(
                      child: TextButton(
                        onPressed: () => context.go('/library'),
                        child: const Text('打開媒體庫'),
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/search'),
        backgroundColor: context.palette.anime,
        foregroundColor: Colors.white,
        tooltip: '加入作品',
        child: const Icon(Icons.add),
      ),
    );
  }

  static int _countTier(List<Item> items, PinTier tier) =>
      items.where((i) => i.pinTier == tier).length;

  static int _pinCount(List<Item> items) =>
      items.where((i) => i.isPinned).length;

  /// Continue stream: recent progress first, then fill with pins.
  static List<Item> _nextUpPool(List<Item> items) {
    final seen = <String>{};
    final out = <Item>[];

    final recent = items.where((i) => i.status == 'in_progress').toList()
      ..sort((a, b) {
        final at = a.lastProgressAt ?? a.createdAt;
        final bt = b.lastProgressAt ?? b.createdAt;
        if (at == null && bt == null) return 0;
        if (at == null) return 1;
        if (bt == null) return -1;
        return bt.compareTo(at);
      });

    for (final i in recent) {
      if (seen.add(i.id)) out.add(i);
      if (out.length >= 10) return out;
    }

    final pins = items.where((i) => i.isPinned).toList()
      ..sort((a, b) {
        final tr = a.pinTier.sortRank.compareTo(b.pinTier.sortRank);
        if (tr != 0) return tr;
        return a.pinOrder.compareTo(b.pinOrder);
      });
    for (final i in pins) {
      if (seen.add(i.id)) out.add(i);
      if (out.length >= 10) break;
    }
    return out;
  }

  static Future<void> _onIncrement(
    BuildContext context,
    WidgetRef ref,
    Item item,
  ) async {
    await ref.read(itemsNotifierProvider.notifier).incrementProgress(item.id);
    if (!context.mounted) return;
    final updated = ref
        .read(itemsNotifierProvider)
        .where((i) => i.id == item.id)
        .firstOrNull;
    final label = updated != null
        ? '${updated.currentUnits}/${updated.totalUnits ?? '?'} ${updated.unitLabel}'
        : '+1';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${item.title} → $label'),
        duration: const Duration(milliseconds: 900),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
