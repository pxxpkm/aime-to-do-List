import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:acg_todo/core/theme/app_colors.dart';
import 'package:acg_todo/core/theme/app_scaffold.dart';
import 'package:acg_todo/core/theme/app_typography.dart';
import 'package:acg_todo/data/local/goal_settings_store.dart';
import 'package:acg_todo/domain/entities/item_category.dart';
import 'package:acg_todo/domain/services/multi_goal_service.dart';
import 'package:acg_todo/presentation/providers/daily_goal_provider.dart';
import 'package:acg_todo/presentation/providers/items_provider.dart';
import 'package:acg_todo/presentation/providers/repository_providers.dart';

class StatsPage extends ConsumerWidget {
  const StatsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(itemsNotifierProvider);
    final snap = ref.watch(multiGoalProvider);
    final store = ref.watch(goalSettingsStoreProvider);

    final total = items.length;
    final completed = items.where((i) => i.completedAt != null).length;
    final inProgress = items.where((i) => i.status == 'in_progress').length;

    final byCategory = <String, int>{};
    for (final c in ItemCategory.values) {
      byCategory[c.storageKey] =
          items.where((i) => i.type == c.storageKey).length;
    }

    return AppScaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 16, 4),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => context.pop(),
                  ),
                  Text(
                    '統計',
                    style: AppTypography.display.copyWith(fontSize: 22),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
                children: [
                  Row(
                    children: [
                      _SummaryCard(
                        label: '全部',
                        value: '$total',
                        color: AppColors.inkPrimary,
                      ),
                      const SizedBox(width: 12),
                      _SummaryCard(
                        label: '進行中',
                        value: '$inProgress',
                        color: AppColors.manga,
                      ),
                      const SizedBox(width: 12),
                      _SummaryCard(
                        label: '已完成',
                        value: '$completed',
                        color: AppColors.success,
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  Text(
                    '目標進度',
                    style: AppTypography.title.copyWith(fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '只清目標累計（今日/滾動/月/年），不會改作品集數。',
                    style: AppTypography.micro.copyWith(
                      color: AppColors.inkMuted,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _GoalProgressSection(periods: snap.periods),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () => _confirmReset(
                        context,
                        ref,
                        title: '重設全部目標進度？',
                        body: '會清空所有日期的目標累計。作品進度不受影響。',
                        onConfirm: () => store.clearAllProgressDays(),
                      ),
                      icon: const Icon(Icons.restart_alt, size: 18),
                      label: const Text('全部重設'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.danger,
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  Text(
                    '類別分佈',
                    style: AppTypography.title.copyWith(fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  if (total > 0)
                    SizedBox(
                      height: 200,
                      child: PieChart(
                        PieChartData(
                          sections: _pieSections(byCategory, total),
                          centerSpaceRadius: 40,
                          sectionsSpace: 2,
                        ),
                      ),
                    )
                  else
                    _emptyChart(),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 16,
                    runSpacing: 8,
                    children: ItemCategory.values.map((c) {
                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: c.color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${c.label} (${byCategory[c.storageKey]})',
                            style: AppTypography.caption.copyWith(
                              color: AppColors.inkSecondary,
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 28),
                  Text(
                    '近 14 日進度',
                    style: AppTypography.title.copyWith(fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 160,
                    child: BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        barGroups: _progressBarGroups(store),
                        titlesData: FlTitlesData(
                          show: true,
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 22,
                              getTitlesWidget: (value, meta) {
                                final i = value.toInt();
                                if (i < 0 || i > 13) {
                                  return const SizedBox.shrink();
                                }
                                final d = DateTime.now()
                                    .subtract(Duration(days: 13 - i));
                                return Text(
                                  '${d.month}/${d.day}',
                                  style: AppTypography.micro.copyWith(
                                    color: AppColors.inkMuted,
                                    fontSize: 9,
                                  ),
                                );
                              },
                            ),
                          ),
                          leftTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                        ),
                        gridData: const FlGridData(show: false),
                        borderData: FlBorderData(show: false),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<PieChartSectionData> _pieSections(
    Map<String, int> byCategory,
    int total,
  ) {
    return ItemCategory.values.map((c) {
      final count = byCategory[c.storageKey] ?? 0;
      final pct = total > 0 ? (count / total * 100) : 0.0;
      return PieChartSectionData(
        value: count.toDouble(),
        title: count > 0 ? '${pct.toInt()}%' : '',
        color: c.color,
        radius: 50,
        titleStyle: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();
  }

  List<BarChartGroupData> _progressBarGroups(GoalSettingsStore store) {
    final now = DateTime.now();
    return List.generate(14, (i) {
      final d = now.subtract(Duration(days: 13 - i));
      final units = store.unitsForDayKey(store.dayKey(d));
      return BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(
            toY: units.toDouble(),
            color: AppColors.anime,
            width: 10,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      );
    });
  }

  Widget _emptyChart() {
    return SizedBox(
      height: 200,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.pie_chart_outline,
              size: 48,
              color: AppColors.inkMuted.withValues(alpha: 0.6),
            ),
            const SizedBox(height: 8),
            Text(
              '新增項目後即可查看統計',
              style: AppTypography.caption.copyWith(color: AppColors.inkMuted),
            ),
          ],
        ),
      ),
    );
  }
}

class _GoalProgressSection extends ConsumerWidget {
  final List<GoalPeriodProgress> periods;

  const _GoalProgressSection({required this.periods});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final store = ref.watch(goalSettingsStoreProvider);
    final visible = periods.where((p) => p.enabled).toList();
    if (visible.isEmpty) {
      return Text('尚未啟用目標', style: AppTypography.caption);
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 8, 8),
      decoration: BoxDecoration(
        color: AppColors.paperElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        children: [
          for (final p in visible) ...[
            _GoalPeriodRow(
              period: p,
              onReset: () => _confirmReset(
                context,
                ref,
                title: '重設${p.label}進度？',
                body: '只會清掉「${p.label}」相關的目標累計，作品集數不會變。',
                onConfirm: () => _resetPeriod(store, p.id),
              ),
            ),
            if (p != visible.last)
              const Divider(height: 16, color: AppColors.divider),
          ],
        ],
      ),
    );
  }

  Future<void> _resetPeriod(GoalSettingsStore store, String id) async {
    switch (id) {
      case 'day':
        await store.clearTodayProgress();
      case 'rolling':
        await store.clearRollingProgress(store.rollingDays);
      case 'month':
        await store.clearMonthProgress();
      case 'year':
        await store.clearYearProgress();
    }
  }
}

class _GoalPeriodRow extends StatelessWidget {
  final GoalPeriodProgress period;
  final VoidCallback onReset;

  const _GoalPeriodRow({
    required this.period,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    final color =
        period.isComplete ? AppColors.success : AppColors.anime;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                period.label,
                style: AppTypography.caption.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.inkPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text(
                    '${period.current}',
                    style: AppTypography.title.copyWith(
                      fontSize: 20,
                      color: color,
                      height: 1,
                    ),
                  ),
                  Text(
                    ' / ${period.target}',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.inkSecondary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    period.isComplete
                        ? '完成'
                        : '${(period.progress * 100).round()}%',
                    style: AppTypography.micro.copyWith(
                      color: color,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: LinearProgressIndicator(
                  value: period.progress.clamp(0.0, 1.0),
                  minHeight: 5,
                  backgroundColor: AppColors.divider,
                  color: color,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: '重設${period.label}',
          onPressed: period.current > 0 ? onReset : null,
          icon: Icon(
            Icons.restart_alt_rounded,
            color: period.current > 0
                ? AppColors.inkSecondary
                : AppColors.inkMuted.withValues(alpha: 0.35),
          ),
        ),
      ],
    );
  }
}

Future<void> _confirmReset(
  BuildContext context,
  WidgetRef ref, {
  required String title,
  required String body,
  required Future<void> Function() onConfirm,
}) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(body),
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
  await onConfirm();
  ref.invalidate(multiGoalProvider);
  ref.read(dailyGoalTickProvider.notifier).state++;
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('目標進度已重設'),
      behavior: SnackBarBehavior.floating,
      duration: Duration(milliseconds: 1000),
    ),
  );
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _SummaryCard({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.paperElevated,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.25)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x122C2416),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: AppTypography.caption.copyWith(
                color: AppColors.inkSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
