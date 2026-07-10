import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:acg_todo/core/theme/app_colors.dart';
import 'package:acg_todo/core/utils/score_utils.dart';
import 'package:acg_todo/domain/entities/item.dart';
import 'package:acg_todo/domain/entities/item_category.dart';
import 'package:acg_todo/presentation/providers/items_provider.dart';
import 'package:acg_todo/presentation/providers/repository_providers.dart';
import 'package:acg_todo/presentation/widgets/tags_editor.dart';

Future<void> showItemEditorSheet(
  BuildContext context,
  WidgetRef ref, {
  required Item item,
}) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) => _ItemEditorBody(itemId: item.id),
  );
}

class _ItemEditorBody extends ConsumerStatefulWidget {
  final String itemId;
  const _ItemEditorBody({required this.itemId});

  @override
  ConsumerState<_ItemEditorBody> createState() => _ItemEditorBodyState();
}

class _ItemEditorBodyState extends ConsumerState<_ItemEditorBody> {
  late TextEditingController _title;
  late TextEditingController _unit;
  late String _type;
  late String _status;
  late List<String> _tags;
  double? _userScore;
  bool _inited = false;

  @override
  void dispose() {
    if (_inited) {
      _title.dispose();
      _unit.dispose();
    }
    super.dispose();
  }

  void _ensureFrom(Item item) {
    if (_inited) return;
    _title = TextEditingController(text: item.title);
    _unit = TextEditingController(text: item.unitLabel);
    _type = item.type;
    _status = item.status;
    _tags = List<String>.from(item.tags);
    _userScore = item.userScore;
    _inited = true;
  }

  Future<void> _save() async {
    final notifier = ref.read(itemsNotifierProvider.notifier);
    final ok = await notifier.updateTitle(widget.itemId, _title.text);
    if (!ok) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('標題不可為空')),
        );
      }
      return;
    }
    await notifier.updateType(widget.itemId, _type);
    await notifier.updateUnitLabel(widget.itemId, _unit.text);
    await notifier.setTags(widget.itemId, _tags);
    await notifier.setUserScore(widget.itemId, _userScore);
    await notifier.setStatus(widget.itemId, _status);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final item = ref
        .watch(itemsNotifierProvider)
        .where((i) => i.id == widget.itemId)
        .firstOrNull;
    if (item == null) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Text('項目不存在'),
      );
    }
    _ensureFrom(item);
    final suggestions = ref.read(itemsRepositoryProvider).allTags();
    final bottom = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 16 + bottom),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '編輯項目',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _title,
              decoration: const InputDecoration(
                labelText: '標題',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _type,
              decoration: const InputDecoration(
                labelText: '類型',
                border: OutlineInputBorder(),
              ),
              items: [
                for (final c in ItemCategory.values)
                  DropdownMenuItem(
                    value: c.storageKey,
                    child: Text(c.label),
                  ),
              ],
              onChanged: (v) {
                if (v == null) return;
                setState(() => _type = v);
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _unit,
              decoration: const InputDecoration(
                labelText: '單位（集/卷/章…）',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _status,
              decoration: const InputDecoration(
                labelText: '狀態',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'in_progress', child: Text('進行中')),
                DropdownMenuItem(value: 'paused', child: Text('暫停')),
                DropdownMenuItem(value: 'dropped', child: Text('棄坑')),
                DropdownMenuItem(value: 'completed', child: Text('已完成')),
              ],
              onChanged: (v) {
                if (v == null) return;
                setState(() => _status = v);
              },
            ),
            const SizedBox(height: 12),
            Text(
              '我的評分${_userScore != null ? '：${formatUserScore(_userScore!)}' : '：未評'}',
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            Slider(
              value: _userScore ?? 7.0,
              min: 0,
              max: 10,
              divisions: 100,
              activeColor: AppColors.lightNovel,
              onChanged: (v) => setState(() => _userScore = roundUserScore(v)),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: () => setState(() => _userScore = null),
                child: const Text('清除評分'),
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              '標籤',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 6),
            TagsEditor(
              tags: _tags,
              suggestions: suggestions,
              onChanged: (t) => setState(() => _tags = t),
            ),
            if (item.score != null) ...[
              const SizedBox(height: 12),
              Text(
                '站點評分 ★ ${item.score!.toStringAsFixed(1)}（唯讀）',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textMuted,
                ),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('取消'),
                ),
                const Spacer(),
                FilledButton(
                  onPressed: _save,
                  child: const Text('儲存'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
