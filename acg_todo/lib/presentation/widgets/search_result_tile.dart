import 'package:flutter/material.dart';

import 'package:acg_todo/core/theme/app_colors.dart';
import 'package:acg_todo/core/theme/app_palette.dart';
import 'package:acg_todo/core/theme/app_shadows.dart';
import 'package:acg_todo/core/theme/app_typography.dart';
import 'package:acg_todo/presentation/widgets/poster_image_widget.dart';

/// Paper-gallery search result row.
class SearchResultTile extends StatelessWidget {
  final String title;
  final String? posterUrl;
  final String typeKey;
  final String metaLine;
  final bool inList;
  final VoidCallback? onAdd;

  const SearchResultTile({
    super.key,
    required this.title,
    required this.posterUrl,
    required this.typeKey,
    required this.metaLine,
    required this.inList,
    this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.palette.elevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.palette.border),
        boxShadow: AppShadows.soft,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 10, 8, 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 56,
                height: 80,
                child: PosterImageWidget(
                  posterUrl: posterUrl,
                  type: typeKey,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.cardTitle.copyWith(fontSize: 15),
                  ),
                  if (metaLine.isNotEmpty) ...[
                    SizedBox(height: 4),
                    Text(
                      metaLine,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.caption.copyWith(
                        color: context.palette.inkMuted,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            SizedBox(width: 4),
            if (inList)
              Container(
                padding:
                    EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: context.palette.success.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: context.palette.success.withValues(alpha: 0.45),
                  ),
                ),
                child: Text(
                  '在架上',
                  style: AppTypography.micro.copyWith(
                    color: context.palette.success,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              )
            else
              IconButton(
                onPressed: onAdd,
                icon: Icon(Icons.add_circle_outline),
                color: context.palette.anime,
                iconSize: 28,
                tooltip: '新增',
              ),
          ],
        ),
      ),
    );
  }
}

/// Empty / blocked states for search page.
class SearchEmptyPanel extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const SearchEmptyPanel({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: EdgeInsets.all(24),
        padding: EdgeInsets.fromLTRB(24, 28, 24, 24),
        constraints: BoxConstraints(maxWidth: 320),
        decoration: BoxDecoration(
          color: context.palette.elevated,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: context.palette.border),
          boxShadow: AppShadows.soft,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: context.palette.inkMuted),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTypography.title.copyWith(fontSize: 17),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: AppTypography.caption,
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 20),
              FilledButton(
                onPressed: onAction,
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
