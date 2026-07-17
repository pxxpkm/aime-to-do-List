import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:acg_todo/core/theme/app_colors.dart';
import 'package:acg_todo/core/theme/app_typography.dart';
import 'package:acg_todo/domain/services/multi_goal_service.dart';
import 'package:acg_todo/presentation/providers/daily_goal_provider.dart';
import 'package:acg_todo/presentation/providers/repository_providers.dart';

/// Compact pill for immersive hero corner. Tap opens goal sheet.
class HomeGoalPill extends ConsumerWidget {
  const HomeGoalPill({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snap = ref.watch(multiGoalProvider);
    final visible = snap.visible;
    if (visible.isEmpty) return const SizedBox.shrink();

    final primary = visible.first;
    final color =
        primary.isComplete ? AppColors.success : AppColors.anime;
    final pct = (primary.progress * 100).round().clamp(0, 100);

    return Material(
      color: Colors.black.withValues(alpha: 0.48),
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: () => showHomeGoalSheet(context),
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 7, 12, 7),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 22,
                height: 22,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: primary.progress.clamp(0.0, 1.0),
                      strokeWidth: 2.4,
                      backgroundColor: Colors.white24,
                      color: color,
                      strokeCap: StrokeCap.round,
                    ),
                    Text(
                      primary.isComplete ? '✓' : '$pct',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: primary.isComplete ? 10 : 8,
                        fontWeight: FontWeight.w800,
                        height: 1,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '今日 ${primary.current}/${primary.target}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  height: 1.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Full goal details + reset-today. Used by pill and legacy card.
Future<void> showHomeGoalSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: AppColors.paperElevated,
    builder: (ctx) {
      final maxH = MediaQuery.sizeOf(ctx).height * 0.72;
      return SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxH),
          child: const SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 20),
            child: HomeGoalSheetBody(),
          ),
        ),
      );
    },
  );
}

class HomeGoalSheetBody extends ConsumerWidget {
  const HomeGoalSheetBody({super.key});

  Future<void> _resetToday(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('重設今日進度？'),
        content: const Text(
          '會把「今日」累計進度歸零。\n'
          '月 / 滾動 / 年目標不會自動清掉。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('重設'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await ref.read(goalSettingsStoreProvider).setTodayProgress(0);
    ref.invalidate(multiGoalProvider);
    ref.read(dailyGoalTickProvider.notifier).state++;
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('今日進度已歸零'),
        behavior: SnackBarBehavior.floating,
        duration: Duration(milliseconds: 1000),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snap = ref.watch(multiGoalProvider);
    final visible = snap.visible;
    if (visible.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Text('尚未設定目標', style: AppTypography.caption),
      );
    }

    final primary = visible.first;
    final rest =
        visible.length > 1 ? visible.sublist(1) : <GoalPeriodProgress>[];
    final color =
        primary.isComplete ? AppColors.success : AppColors.anime;
    final pct = (primary.progress * 100).round();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '今日進度',
                    style: AppTypography.micro.copyWith(
                      color: AppColors.inkMuted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        '${primary.current}',
                        style: AppTypography.display.copyWith(
                          fontSize: 36,
                          height: 1.0,
                          color: color,
                        ),
                      ),
                      Text(
                        ' / ${primary.target}',
                        style: AppTypography.title.copyWith(
                          fontSize: 16,
                          color: AppColors.inkSecondary,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        primary.isComplete ? '已完成' : '$pct%',
                        style: AppTypography.caption.copyWith(
                          color: color,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            TextButton.icon(
              onPressed:
                  primary.current > 0 ? () => _resetToday(context, ref) : null,
              icon: const Icon(Icons.restart_alt_rounded, size: 18),
              label: const Text('重設今日'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.inkSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: LinearProgressIndicator(
            value: primary.progress.clamp(0.0, 1.0),
            minHeight: 8,
            backgroundColor: AppColors.divider,
            color: color,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          primary.isComplete
              ? '今日目標已完成'
              : '還差 ${primary.remaining}',
          style: AppTypography.micro.copyWith(color: AppColors.inkMuted),
        ),
        if (rest.isNotEmpty) ...[
          const SizedBox(height: 16),
          const Divider(height: 1, color: AppColors.divider),
          const SizedBox(height: 12),
          for (final p in rest) ...[
            _MiniPeriodRow(period: p),
            const SizedBox(height: 10),
          ],
        ],
        if (snap.suggestions.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            '建議接著看',
            style: AppTypography.micro.copyWith(
              color: AppColors.inkMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final item in snap.suggestions)
                ActionChip(
                  visualDensity: VisualDensity.compact,
                  label: Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12),
                  ),
                  backgroundColor:
                      AppColors.getTypeColor(item.type).withValues(alpha: 0.12),
                  side: BorderSide(
                    color: AppColors.getTypeColor(item.type)
                        .withValues(alpha: 0.35),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    context.push('/item/${item.id}');
                  },
                ),
            ],
          ),
        ],
      ],
    );
  }
}

/// Standalone card (kept for reuse outside hero).
class HomeGoalCard extends ConsumerWidget {
  const HomeGoalCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snap = ref.watch(multiGoalProvider);
    if (snap.visible.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 4),
      child: Material(
        color: AppColors.paperElevated,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () => showHomeGoalSheet(context),
          borderRadius: BorderRadius.circular(16),
          child: const Padding(
            padding: EdgeInsets.fromLTRB(4, 4, 4, 4),
            child: HomeGoalSheetBody(),
          ),
        ),
      ),
    );
  }
}

class _MiniPeriodRow extends StatelessWidget {
  final GoalPeriodProgress period;

  const _MiniPeriodRow({required this.period});

  @override
  Widget build(BuildContext context) {
    final color =
        period.isComplete ? AppColors.success : AppColors.inkSecondary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                period.label,
                style: AppTypography.caption.copyWith(
                  color: AppColors.inkPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text(
              '${period.current}/${period.target}',
              style: AppTypography.micro.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: LinearProgressIndicator(
            value: period.progress.clamp(0.0, 1.0),
            minHeight: 4,
            backgroundColor: AppColors.divider,
            color: color,
          ),
        ),
      ],
    );
  }
}
