import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:acg_todo/core/theme/app_colors.dart';
import 'package:acg_todo/domain/services/reminder_types.dart';
import 'package:acg_todo/presentation/providers/daily_goal_provider.dart';
import 'package:acg_todo/presentation/providers/items_provider.dart';
import 'package:acg_todo/presentation/providers/repository_providers.dart';

/// Pick deadline date and optional remind mode for an item.
Future<void> showDeadlineEditor(
  BuildContext context,
  WidgetRef ref, {
  required String itemId,
  DateTime? currentDeadline,
  String remindMode = 'global',
  String? customOffsets,
}) async {
  final store = ref.read(goalSettingsStoreProvider);
  final global = store.deadlineReminderDays;

  DateTime? deadline = currentDeadline;
  var mode = remindMode;
  var selected = ReminderTypes.parseOffsets(
    customOffsets,
    fallback: global,
  ).toSet();

  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx, setModal) {
          return Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 16,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  '限期與提醒',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.event),
                  title: Text(
                    deadline == null
                        ? '未設定限期'
                        : '${deadline!.year}/${deadline!.month}/${deadline!.day}',
                  ),
                  trailing: TextButton(
                    onPressed: () async {
                      final now = DateTime.now();
                      final picked = await showDatePicker(
                        context: ctx,
                        initialDate: deadline ?? now,
                        firstDate: DateTime(now.year - 1),
                        lastDate: DateTime(now.year + 5),
                      );
                      if (picked != null) {
                        setModal(() => deadline = picked);
                      }
                    },
                    child: Text(deadline == null ? '選擇' : '變更'),
                  ),
                ),
                if (deadline != null)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      onPressed: () => setModal(() => deadline = null),
                      child: const Text('清除限期'),
                    ),
                  ),
                const Divider(),
                const Text('提醒（距到期還剩幾天）',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                RadioListTile<String>(
                  dense: true,
                  title: Text(
                    '使用全域設定（${store.deadlineReminderDays.join(', ')} 天）',
                    style: const TextStyle(fontSize: 13),
                  ),
                  value: 'global',
                  groupValue: mode,
                  onChanged: (v) => setModal(() => mode = v!),
                ),
                RadioListTile<String>(
                  dense: true,
                  title: const Text('自訂提醒日', style: TextStyle(fontSize: 13)),
                  value: 'custom',
                  groupValue: mode,
                  onChanged: (v) => setModal(() => mode = v!),
                ),
                if (mode == 'custom')
                  Wrap(
                    spacing: 6,
                    children: [
                      for (final d in [14, 7, 5, 3, 2, 1, 0])
                        FilterChip(
                          label: Text(d == 0 ? '當天' : '$d 天'),
                          selected: selected.contains(d),
                          onSelected: (on) {
                            setModal(() {
                              if (on) {
                                selected.add(d);
                              } else {
                                selected.remove(d);
                              }
                            });
                          },
                        ),
                    ],
                  ),
                RadioListTile<String>(
                  dense: true,
                  title: const Text('此作品不提醒', style: TextStyle(fontSize: 13)),
                  value: 'off',
                  groupValue: mode,
                  onChanged: (v) => setModal(() => mode = v!),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('儲存'),
                ),
              ],
            ),
          );
        },
      );
    },
  );

  if (result != true) return;

  await ref.read(itemsNotifierProvider.notifier).setDeadline(itemId, deadline);
  await ref.read(itemsNotifierProvider.notifier).setDeadlineRemindMode(
        itemId,
        mode: mode,
        customOffsets: mode == 'custom'
            ? ReminderTypes.encodeOffsets(selected.toList())
            : null,
      );
  ref.read(dailyGoalTickProvider.notifier).state++;
}
