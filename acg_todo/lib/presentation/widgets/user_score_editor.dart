import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:acg_todo/core/theme/app_colors.dart';
import 'package:acg_todo/core/utils/score_utils.dart';
import 'package:acg_todo/domain/entities/item.dart';
import 'package:acg_todo/presentation/providers/items_provider.dart';

Future<void> showUserScoreEditor(
  BuildContext context,
  WidgetRef ref, {
  required Item item,
}) async {
  var value = item.userScore ?? 7.0;
  var hasScore = item.userScore != null;

  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.paperElevated,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx, setLocal) {
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    '我的評分',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    hasScore ? formatUserScore(value) : '未評分',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: hasScore
                          ? AppColors.lightNovel
                          : AppColors.textMuted,
                    ),
                  ),
                  Slider(
                    value: value,
                    min: 0,
                    max: 10,
                    divisions: 100,
                    label: formatUserScore(value),
                    activeColor: AppColors.lightNovel,
                    onChanged: (v) => setLocal(() {
                      hasScore = true;
                      value = roundUserScore(v) ?? v;
                    }),
                  ),
                  Row(
                    children: [
                      TextButton(
                        onPressed: () async {
                          await ref
                              .read(itemsNotifierProvider.notifier)
                              .setUserScore(item.id, null);
                          if (ctx.mounted) Navigator.pop(ctx);
                        },
                        child: const Text('清除'),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('取消'),
                      ),
                      FilledButton(
                        onPressed: () async {
                          await ref
                              .read(itemsNotifierProvider.notifier)
                              .setUserScore(item.id, value);
                          if (ctx.mounted) Navigator.pop(ctx);
                        },
                        child: const Text('儲存'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}
