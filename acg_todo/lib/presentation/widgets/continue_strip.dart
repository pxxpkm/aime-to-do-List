import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:acg_todo/core/theme/app_colors.dart';
import 'package:acg_todo/core/theme/app_shadows.dart';
import 'package:acg_todo/core/theme/app_typography.dart';
import 'package:acg_todo/domain/entities/item.dart';
import 'package:acg_todo/presentation/home/continue_item_badges.dart';
import 'package:acg_todo/presentation/providers/notification_providers.dart';
import 'package:acg_todo/presentation/widgets/poster_card.dart';

/// Horizontal "continue" cards for dashboard (recent progress).
class ContinueStrip extends ConsumerWidget {
  final List<Item> items;
  final void Function(Item item) onTap;
  final void Function(Item item)? onIncrement;

  const ContinueStrip({
    super.key,
    required this.items,
    required this.onTap,
    this.onIncrement,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (items.isEmpty) return const SizedBox.shrink();

    final staleDays = ref.watch(notificationSettingsProvider).staleDays;
    final hasPinnedFill = items.any((i) => i.isPinned);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 220,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, i) {
              final item = items[i];
              final badges = ContinueItemBadges.forItem(
                item,
                staleDays: staleDays,
              );
              return SizedBox(
                width: 128,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: AppShadows.soft,
                  ),
                  child: PosterCard(
                    item: item,
                    density: PosterCardDensity.strip,
                    heroTag: 'continue_${item.id}',
                    showStale: badges.isStale,
                    continueRisk: badges.risk,
                    onTap: () => onTap(item),
                    onIncrement: onIncrement != null
                        ? () => onIncrement!(item)
                        : null,
                    showIncrement: onIncrement != null,
                    longPressOpensMenu: false,
                  ),
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
          child: Text(
            hasPinnedFill ? '最近進度 · 含釘選' : '依最近進度排序',
            style: AppTypography.micro.copyWith(color: AppColors.inkMuted),
          ),
        ),
      ],
    );
  }
}
