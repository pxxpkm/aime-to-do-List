import 'package:flutter/material.dart';

import 'package:acg_todo/core/theme/app_colors.dart';
import 'package:acg_todo/core/theme/app_shadows.dart';
import 'package:acg_todo/core/theme/app_typography.dart';
import 'package:acg_todo/domain/entities/item.dart';
import 'package:acg_todo/presentation/widgets/poster_card.dart';

/// Horizontal "continue" cards for dashboard (recent progress).
class ContinueStrip extends StatelessWidget {
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
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 200,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, i) {
              final item = items[i];
              return SizedBox(
                width: 118,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: AppShadows.soft,
                  ),
                  child: PosterCard(
                    item: item,
                    density: PosterCardDensity.strip,
                    heroTag: 'continue_${item.id}',
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
        if (items.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
            child: Text(
              '依最近進度排序',
              style: AppTypography.micro.copyWith(color: AppColors.inkMuted),
            ),
          ),
      ],
    );
  }
}
