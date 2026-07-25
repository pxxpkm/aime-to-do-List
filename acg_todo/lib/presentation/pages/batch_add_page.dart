import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:acg_todo/core/theme/app_colors.dart';
import 'package:acg_todo/core/theme/app_scaffold.dart';
import 'package:acg_todo/core/utils/poster_url.dart';
import 'package:acg_todo/core/utils/zh_convert.dart';
import 'package:acg_todo/data/metadata/source_candidate.dart';
import 'package:acg_todo/domain/entities/item.dart';
import 'package:acg_todo/domain/entities/item_category.dart';
import 'package:acg_todo/presentation/providers/items_provider.dart';
import 'package:acg_todo/presentation/providers/repository_providers.dart';
import 'package:acg_todo/presentation/widgets/poster_image_widget.dart';

class _BatchRow {
  final String query;
  final String searchQuery;
  List<SourceCandidate> candidates;
  SourceCandidate? selected;
  bool loading;
  bool checked;
  String? error;

  _BatchRow({
    required this.query,
    required this.searchQuery,
  })  : candidates = const [],
        selected = null,
        loading = true,
        checked = true,
        error = null;
}

/// Multi-line title → search Bangumi → confirm → add.
class BatchAddPage extends ConsumerStatefulWidget {
  const BatchAddPage({super.key});

  @override
  ConsumerState<BatchAddPage> createState() => _BatchAddPageState();
}

class _BatchAddPageState extends ConsumerState<BatchAddPage> {
  final _controller = TextEditingController();
  ItemCategory _category = ItemCategory.lightNovel;
  List<_BatchRow>? _rows;
  bool _searching = false;
  bool _adding = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _preview() async {
    final lines = _controller.text
        .split(RegExp(r'[\r\n]+'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .take(30)
        .toList();
    if (lines.isEmpty) return;

    final t2s = ref.read(goalSettingsStoreProvider).searchTradToSimp;
    final registry = ref.read(sourceRegistryProvider);
    final existing = ref.read(itemsNotifierProvider).map((e) => e.id).toSet();

    setState(() {
      _searching = true;
      _rows = lines
          .map((q) => _BatchRow(
                query: q,
                searchQuery: t2s ? traditionalToSimplified(q) : q,
              ))
          .toList();
    });

    for (var i = 0; i < _rows!.length; i++) {
      final row = _rows![i];
      try {
        final results = await registry.search(
          'bangumi',
          row.searchQuery,
          _category,
        );
        if (!mounted) return;
        final first = results.isNotEmpty ? results.first : null;
        final id = first?.libraryId;
        setState(() {
          row.candidates = results;
          row.selected = first;
          row.loading = false;
          row.checked = first != null && id != null && !existing.contains(id);
          if (first == null) {
            row.error = '無結果';
            row.checked = false;
          } else if (id != null && existing.contains(id)) {
            row.error = '已在清單';
            row.checked = false;
          }
        });
      } catch (e) {
        if (!mounted) return;
        setState(() {
          row.loading = false;
          row.error = '搜尋失敗';
          row.checked = false;
        });
      }
      await Future<void>.delayed(const Duration(milliseconds: 150));
    }

    if (mounted) setState(() => _searching = false);
  }

  Future<void> _confirmAdd() async {
    final rows = _rows;
    if (rows == null) return;
    final toAdd = <Item>[];
    for (final row in rows) {
      if (!row.checked || row.selected == null) continue;
      var item = row.selected!.toItem(
        'local_user',
        preferredCategory: _category,
      );
      item = item.copyWith(posterUrl: normalizePosterUrl(item.posterUrl));
      toAdd.add(item);
    }
    if (toAdd.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('沒有可新增的項目'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _adding = true);
    final n = await ref.read(itemsNotifierProvider.notifier).addItems(toAdd);
    if (!mounted) return;
    setState(() => _adding = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('已新增 $n 部（略過重複）'),
        behavior: SnackBarBehavior.floating,
      ),
    );
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final rows = _rows;
    return AppScaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => context.pop(),
                  ),
                  const Expanded(
                    child: Text(
                      '批量新增',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
              if (rows == null) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Wrap(
                    spacing: 8,
                    children: ItemCategory.values
                        .where((c) => c != ItemCategory.game)
                        .map((c) {
                      final sel = _category == c;
                      return ChoiceChip(
                        label: Text(c.label),
                        selected: sel,
                        onSelected: (_) => setState(() => _category = c),
                        selectedColor: c.color,
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: TextField(
                      controller: _controller,
                      maxLines: null,
                      expands: true,
                      textAlignVertical: TextAlignVertical.top,
                      decoration: InputDecoration(
                        hintText: '每行一個標題，最多 30 行\n例如：\n無職轉生\n藥屋少女的呢喃\n…',
                        filled: true,
                        fillColor: AppColors.paperElevated,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: ElevatedButton(
                    onPressed: _searching ? null : _preview,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.anime,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text(_searching ? '搜尋中…' : '預覽搜尋'),
                  ),
                ),
              ] else ...[
                if (_searching)
                  const LinearProgressIndicator(minHeight: 2),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                    itemCount: rows.length,
                    itemBuilder: (_, i) {
                      final row = rows[i];
                      return Card(
                        color: AppColors.paperElevated,
                        child: CheckboxListTile(
                          value: row.checked,
                          onChanged: row.selected == null || row.loading
                              ? null
                              : (v) =>
                                  setState(() => row.checked = v ?? false),
                          title: Text(row.query, maxLines: 1),
                          subtitle: row.loading
                              ? const Text('搜尋中…')
                              : row.error != null && row.selected == null
                                  ? Text(row.error!,
                                      style: const TextStyle(
                                          color: AppColors.danger))
                                  : Text(
                                      row.selected?.displayName ?? '',
                                      maxLines: 2,
                                    ),
                          secondary: row.selected != null
                              ? SizedBox(
                                  width: 40,
                                  height: 56,
                                  child: PosterImageWidget(
                                    posterUrl: row.selected!.posterUrl,
                                    type: _category.storageKey,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : null,
                          controlAffinity: ListTileControlAffinity.leading,
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _adding
                              ? null
                              : () => setState(() => _rows = null),
                          child: const Text('返回編輯'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _adding || _searching ? null : _confirmAdd,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.anime,
                            foregroundColor: Colors.white,
                          ),
                          child: Text(
                            _adding
                                ? '新增中…'
                                : '新增 ${rows.where((r) => r.checked).length} 部',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
    );
  }
}
