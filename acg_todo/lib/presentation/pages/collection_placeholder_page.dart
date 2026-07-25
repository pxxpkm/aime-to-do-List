import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:acg_todo/core/theme/app_colors.dart';
import 'package:acg_todo/core/theme/app_palette.dart';
import 'package:acg_todo/core/theme/app_scaffold.dart';
import 'package:acg_todo/core/theme/app_typography.dart';

/// Phase 1 placeholder — folder management moves here later.
class CollectionPlaceholderPage extends StatelessWidget {
  const CollectionPlaceholderPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('收藏', style: AppTypography.display.copyWith(fontSize: 24)),
              SizedBox(height: 12),
              Text(
                '下階段會把資料夾列表與整理移到這裡。',
                style: AppTypography.body.copyWith(
                  color: context.palette.inkSecondary,
                ),
              ),
              const SizedBox(height: 24),
              FilledButton.tonal(
                onPressed: () => context.go('/'),
                child: const Text('回主頁'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
