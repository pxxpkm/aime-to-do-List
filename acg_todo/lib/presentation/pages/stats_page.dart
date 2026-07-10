import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:acg_todo/core/theme/app_colors.dart';
import 'package:acg_todo/domain/entities/item_category.dart';
import 'package:acg_todo/presentation/providers/items_provider.dart';

class StatsPage extends ConsumerWidget {
  const StatsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(itemsNotifierProvider);

    final total = items.length;
    final completed = items.where((i) => i.completedAt != null).length;
    final inProgress = items.where((i) => i.status == 'in_progress').length;

    final byCategory = <String, int>{};
    for (final c in ItemCategory.values) {
      byCategory[c.storageKey] =
          items.where((i) => i.type == c.storageKey).length;
    }

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => context.pop(),
                    ),
                    const Text(
                      '統計',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    // Summary cards
                    Row(
                      children: [
                        _SummaryCard(
                          label: '全部',
                          value: '$total',
                          color: AppColors.textPrimary,
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

                    const SizedBox(height: 32),

                    // Category pie chart
                    const Text(
                      '類別分佈',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
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

                    // Legend
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
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 32),

                    // Completion bar chart
                    const Text(
                      '本週完成',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 160,
                      child: BarChart(
                        BarChartData(
                          alignment: BarChartAlignment.spaceAround,
                          barGroups: _barGroups(),
                          titlesData: FlTitlesData(
                            show: true,
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, meta) {
                                  const days = ['一', '二', '三', '四', '五', '六', '日'];
                                  return Text(
                                    days[value.toInt()],
                                    style: const TextStyle(
                                      color: AppColors.textMuted,
                                      fontSize: 11,
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

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<PieChartSectionData> _pieSections(Map<String, int> byCategory, int total) {
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

  List<BarChartGroupData> _barGroups() {
    // 模擬本週數據（之後可換成真實數據）
    final mockData = [1.0, 0.0, 2.0, 1.0, 3.0, 0.0, 1.0];
    return List.generate(7, (i) {
      return BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(
            toY: mockData[i],
            color: AppColors.anime,
            width: 16,
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
              color: Colors.white.withValues(alpha: 0.2),
            ),
            const SizedBox(height: 8),
            Text(
              '新增項目後即可查看統計',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.4),
              ),
            ),
          ],
        ),
      ),
    );
  }
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
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.2)),
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
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
