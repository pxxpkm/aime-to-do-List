import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:acg_todo/core/theme/app_colors.dart';
import 'package:acg_todo/core/theme/app_palette.dart';
import 'package:acg_todo/core/theme/app_shadows.dart';
import 'package:acg_todo/domain/services/multi_goal_service.dart';
import 'package:acg_todo/presentation/providers/daily_goal_provider.dart';

/// Compact by default: primary goal only; expand for rest + suggestions.
class DailyGoalBar extends ConsumerStatefulWidget {
  const DailyGoalBar({super.key});

  @override
  ConsumerState<DailyGoalBar> createState() => _DailyGoalBarState();
}

class _DailyGoalBarState extends ConsumerState<DailyGoalBar> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final snap = ref.watch(multiGoalProvider);
    final visible = snap.visible;
    if (visible.isEmpty) return const SizedBox.shrink();

    final primary = visible.first;
    final rest =
        visible.length > 1 ? visible.sublist(1) : <GoalPeriodProgress>[];
    final hasMore = rest.isNotEmpty || snap.suggestions.isNotEmpty;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 2, 16, 6),
      child: Container(
        padding: EdgeInsets.fromLTRB(12, 8, 8, 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: context.palette.elevated,
          border: Border.all(
            color: (primary.isComplete ? context.palette.success : context.palette.anime)
                .withValues(alpha: 0.35),
          ),
          boxShadow: AppShadows.soft,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: _PeriodRow(period: primary, large: true)),
                if (hasMore)
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                    icon: Icon(
                      _expanded
                          ? Icons.expand_less
                          : Icons.expand_more,
                      color: context.palette.inkMuted,
                    ),
                    onPressed: () => setState(() => _expanded = !_expanded),
                  ),
              ],
            ),
            if (_expanded && rest.isNotEmpty) ...[
              const SizedBox(height: 8),
              ...rest.map(
                (p) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: _PeriodRow(period: p, large: false),
                ),
              ),
            ],
            if (_expanded && snap.suggestions.isNotEmpty) ...[
              SizedBox(height: 4),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    '建議',
                    style: TextStyle(fontSize: 12, color: context.palette.inkMuted),
                  ),
                  for (final item in snap.suggestions)
                    ActionChip(
                      visualDensity: VisualDensity.compact,
                      label: Text(
                        item.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 11),
                      ),
                      backgroundColor: context.palette.typeColor(item.type)
                          .withValues(alpha: 0.2),
                      side: BorderSide(
                        color: context.palette.typeColor(item.type)
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

  _PeriodRow({required this.period, required this.large});

  @override
  Widget build(BuildContext context) {
    final color = period.isComplete ? context.palette.success : context.palette.anime;
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
                size: 16,
                color: color,
              ),
            if (large) const SizedBox(width: 6),
            Flexible(
              child: Text(
                period.label,
                style: TextStyle(
                  fontWeight: large ? FontWeight.w700 : FontWeight.w600,
                  fontSize: large ? 13 : 12,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            SizedBox(width: 8),
            Text(
              '${period.current}/${period.target}',
              style: TextStyle(
                fontSize: large ? 12 : 11,
                fontWeight: FontWeight.w600,
                color: period.isComplete
                    ? context.palette.success
                    : context.palette.inkSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: period.progress),
          duration: Duration(milliseconds: 400),
          curve: Curves.easeOutCubic,
          builder: (context, value, _) {
            return ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: value,
                minHeight: large ? 6 : 4,
                backgroundColor: context.palette.divider,
                color: color,
              ),
            );
          },
        ),
      ],
    );
  }
}
