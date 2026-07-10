import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:acg_todo/core/theme/app_colors.dart';
import 'package:acg_todo/domain/services/multi_goal_service.dart';
import 'package:acg_todo/presentation/providers/daily_goal_provider.dart';

class DailyGoalBar extends ConsumerWidget {
  const DailyGoalBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snap = ref.watch(multiGoalProvider);
    final visible = snap.visible;
    if (visible.isEmpty) return const SizedBox.shrink();

    final primary = visible.first;
    final rest = visible.length > 1 ? visible.sublist(1) : <GoalPeriodProgress>[];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: AppColors.surface.withValues(alpha: 0.75),
          border: Border.all(
            color: (primary.isComplete ? AppColors.success : AppColors.anime)
                .withValues(alpha: 0.35),
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.anime.withValues(alpha: 0.12),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _PeriodRow(period: primary, large: true),
            if (rest.isNotEmpty) ...[
              const SizedBox(height: 10),
              ...rest.map((p) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: _PeriodRow(period: p, large: false),
                  )),
            ],
            if (snap.suggestions.isNotEmpty) ...[
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  const Text(
                    '建議',
                    style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                  ),
                  for (final item in snap.suggestions)
                    ActionChip(
                      visualDensity: VisualDensity.compact,
                      label: Text(
                        item.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 11),
                      ),
                      backgroundColor: AppColors.getTypeColor(item.type)
                          .withValues(alpha: 0.2),
                      side: BorderSide(
                        color: AppColors.getTypeColor(item.type)
                            .withValues(alpha: 0.4),
                      ),
                      onPressed: () => context.push('/item/${item.id}'),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PeriodRow extends StatelessWidget {
  final GoalPeriodProgress period;
  final bool large;

  const _PeriodRow({required this.period, required this.large});

  @override
  Widget build(BuildContext context) {
    final color =
        period.isComplete ? AppColors.success : AppColors.anime;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (large)
              Icon(
                period.isComplete
                    ? Icons.emoji_events_outlined
                    : Icons.flag_outlined,
                size: 18,
                color: color,
              ),
            if (large) const SizedBox(width: 8),
            Text(
              period.label,
              style: TextStyle(
                fontWeight: large ? FontWeight.w700 : FontWeight.w600,
                fontSize: large ? 14 : 12,
              ),
            ),
            const Spacer(),
            Text(
              '${period.current} / ${period.target} 集',
              style: TextStyle(
                fontSize: large ? 13 : 11,
                fontWeight: FontWeight.w600,
                color: period.isComplete
                    ? AppColors.success
                    : AppColors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: period.progress,
            minHeight: large ? 8 : 5,
            backgroundColor: Colors.white.withValues(alpha: 0.08),
            color: color,
          ),
        ),
      ],
    );
  }
}
