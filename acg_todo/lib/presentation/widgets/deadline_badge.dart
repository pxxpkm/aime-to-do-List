import 'package:flutter/material.dart' hide DateUtils;

import 'package:acg_todo/core/theme/app_colors.dart';
import 'package:acg_todo/core/utils/date_utils.dart';

class DeadlineBadge extends StatelessWidget {
  final DateTime deadline;

  const DeadlineBadge({super.key, required this.deadline});

  @override
  Widget build(BuildContext context) {
    final days = DateUtils.daysUntil(deadline);
    final color = _colorForDays(days);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        DateUtils.formatCountdown(deadline),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Color _colorForDays(int days) {
    if (days < 0) return AppColors.danger;
    if (days <= 1) return AppColors.warning;
    if (days <= 3) return AppColors.warning;
    return AppColors.success;
  }
}
