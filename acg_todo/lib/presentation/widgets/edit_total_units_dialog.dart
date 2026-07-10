import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:acg_todo/domain/entities/item.dart';
import 'package:acg_todo/presentation/providers/items_provider.dart';

Future<void> showEditTotalUnitsDialog(
  BuildContext context,
  WidgetRef ref, {
  required Item item,
}) async {
  final controller = TextEditingController(
    text: item.totalUnits != null && item.totalUnits! > 0
        ? '${item.totalUnits}'
        : '',
  );
  final result = await showDialog<int?>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text('設定總${item.unitLabel}數'),
      content: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        autofocus: true,
        decoration: InputDecoration(
          hintText: '例如 12（留空=未知）',
          suffixText: item.unitLabel,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, -1),
          child: const Text('取消'),
        ),
        TextButton(
          onPressed: () {
            final t = controller.text.trim();
            if (t.isEmpty) {
              Navigator.pop(ctx, 0);
            } else {
              Navigator.pop(ctx, int.tryParse(t));
            }
          },
          child: const Text('儲存'),
        ),
      ],
    ),
  );
  controller.dispose();
  if (result == null || result == -1) return;
  final total = result == 0 ? null : result;
  if (total != null && total < 0) return;
  await ref.read(itemsNotifierProvider.notifier).setTotalUnits(item.id, total);
}
