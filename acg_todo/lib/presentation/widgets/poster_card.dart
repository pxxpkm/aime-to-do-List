import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:acg_todo/core/theme/app_colors.dart';
import 'package:acg_todo/core/utils/score_utils.dart';
import 'package:acg_todo/domain/entities/item.dart';
import 'package:acg_todo/presentation/widgets/deadline_badge.dart';
import 'package:acg_todo/presentation/widgets/poster_image_widget.dart';

class PosterCard extends ConsumerWidget {
  final Item item;
  final VoidCallback? onTap;
  final VoidCallback? onIncrement;
  final VoidCallback? onMenu;
  final bool showIncrement;
  /// When false (reorder mode), long-press is left for drag; use ⋮ only.
  final bool longPressOpensMenu;

  const PosterCard({
    super.key,
    required this.item,
    this.onTap,
    this.onIncrement,
    this.onMenu,
    this.showIncrement = true,
    this.longPressOpensMenu = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = AppColors.getTypeColor(item.type);
    final progress = item.totalUnits != null && item.totalUnits! > 0
        ? (item.currentUnits / item.totalUnits!).clamp(0.0, 1.0)
        : 0.0;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        onLongPress: longPressOpensMenu ? onMenu : null,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: AppColors.surface.withValues(alpha: 0.88),
            border: Border.all(
              color: color.withValues(alpha: 0.35),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.22),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Hero(
                  tag: item.id,
                  child: PosterImageWidget(
                    key: ValueKey('poster_${item.id}'),
                    posterUrl: item.posterUrl,
                    type: item.type,
                    fit: BoxFit.cover,
                  ),
                ),
                // Bottom gradient + meta
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(8, 28, 8, 8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.85),
                        ],
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          item.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            height: 1.15,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(3),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 3,
                            backgroundColor:
                                Colors.white.withValues(alpha: 0.15),
                            color: color,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${item.currentUnits}/${item.totalUnits ?? '?'} ${item.unitLabel}',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.white.withValues(alpha: 0.75),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (showIncrement && onIncrement != null)
                              _PlusButton(
                                color: color,
                                onPressed: onIncrement!,
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                if (item.deadline != null)
                  Positioned(
                    top: 6,
                    right: 6,
                    child: DeadlineBadge(deadline: item.deadline!),
                  ),
                if (item.userScore != null || item.score != null)
                  Positioned(
                    top: item.deadline != null ? 34 : 6,
                    right: 6,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (item.userScore != null)
                          Container(
                            margin: const EdgeInsets.only(bottom: 4),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.lightNovel.withValues(alpha: 0.9),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '我 ${formatUserScore(item.userScore!)}',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        if (item.score != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.55),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '★ ${item.score!.toStringAsFixed(1)}',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFFfbbf24),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                if (item.tags.isNotEmpty)
                  Positioned(
                    bottom: 72,
                    left: 6,
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 90),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.55),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        item.tags.length == 1
                            ? item.tags.first
                            : '${item.tags.first}+${item.tags.length - 1}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 9,
                          color: Colors.white70,
                        ),
                      ),
                    ),
                  ),
                if (item.remark != null && item.remark!.isNotEmpty)
                  Positioned(
                    bottom: 72,
                    right: 6,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(
                        Icons.sticky_note_2_outlined,
                        size: 14,
                        color: Colors.white70,
                      ),
                    ),
                  ),
                if (onMenu != null)
                  Positioned(
                    top: 4,
                    left: 4,
                    child: Material(
                      color: Colors.black.withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(8),
                      child: InkWell(
                        onTap: onMenu,
                        borderRadius: BorderRadius.circular(8),
                        child: const SizedBox(
                          width: 28,
                          height: 28,
                          child: Icon(
                            Icons.more_vert,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PlusButton extends StatelessWidget {
  final Color color;
  final VoidCallback onPressed;

  const _PlusButton({required this.color, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.9),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: const SizedBox(
          width: 28,
          height: 28,
          child: Icon(Icons.add, size: 18, color: Colors.white),
        ),
      ),
    );
  }
}
