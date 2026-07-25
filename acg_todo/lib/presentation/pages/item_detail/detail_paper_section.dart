import 'package:flutter/material.dart';

import 'package:acg_todo/core/theme/app_colors.dart';
import 'package:acg_todo/core/theme/app_palette.dart';
import 'package:acg_todo/core/theme/app_shadows.dart';
import 'package:acg_todo/core/theme/app_typography.dart';

/// Shared paper shell for detail meta sections (S3-3).
class DetailPaperSection extends StatelessWidget {
  final String? title;
  final Widget child;
  final EdgeInsetsGeometry padding;

  const DetailPaperSection({
    super.key,
    this.title,
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(16, 14, 16, 16),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: context.palette.elevated,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.palette.border),
        boxShadow: AppShadows.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (title != null) ...[
            Text(
              title!,
              style: AppTypography.title.copyWith(fontSize: 16),
            ),
            const SizedBox(height: 12),
          ],
          child,
        ],
      ),
    );
  }
}

/// Small label above a field inside [DetailPaperSection].
class DetailSectionLabel extends StatelessWidget {
  final String text;

  const DetailSectionLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTypography.caption.copyWith(
        fontWeight: FontWeight.w600,
        color: context.palette.inkSecondary,
      ),
    );
  }
}
