import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:acg_todo/core/theme/app_colors.dart';
import 'package:acg_todo/core/theme/app_scaffold.dart';
import 'package:acg_todo/data/repositories/bangumi/bangumi_collection.dart';
import 'package:acg_todo/data/repositories/bangumi/mappers.dart';
import 'package:acg_todo/domain/entities/item_category.dart';
import 'package:acg_todo/presentation/providers/items_provider.dart';
import 'package:acg_todo/presentation/providers/repository_providers.dart';
import 'package:acg_todo/presentation/widgets/poster_image_widget.dart';

class ImportCollectionPage extends ConsumerStatefulWidget {
  const ImportCollectionPage({super.key});

  @override
  ConsumerState<ImportCollectionPage> createState() =>
      _ImportCollectionPageState();
}

class _ImportCollectionPageState extends ConsumerState<ImportCollectionPage> {
  ItemCategory _category = ItemCategory.anime;
  List<BangumiCollection> _collections = [];
  final Set<int> _selected = {};
  bool _loading = false;
  bool _importing = false;
  String? _error;

  Future<void> _loadCollections() async {
    setState(() {
      _loading = true;
      _error = null;
      _selected.clear();
    });

    try {
      final token =
          ref.read(bangumiTokenStoreProvider).token;
      if (token == null) {
        setState(() {
          _loading = false;
          _error = '未取得 Token';
        });
        return;
      }

      final collections = await ref
          .read(bangumiClientProvider)
          .getAllCollections(token, _category.bangumiType);

      setState(() {
        _collections = collections;
        _loading = false;
        // 預設勾選「在看」和「想看」
        _selected.addAll(
          collections
              .where((c) => c.status == 1 || c.status == 2)
              .map((c) => c.subjectId),
        );
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = '載入失敗：$e';
      });
    }
  }

  Future<void> _importSelected() async {
    if (_selected.isEmpty) return;

    setState(() => _importing = true);

    try {
      final items = _collections
          .where((c) => _selected.contains(c.subjectId))
          .map((c) => c.toItem('local_user'))
          .toList();

      final existingIds =
          ref.read(itemsNotifierProvider).map((i) => i.id).toSet();
      final newItems = items.where((i) => !existingIds.contains(i.id)).toList();

      await ref.read(itemsNotifierProvider.notifier).addItems(newItems);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('已匯入 ${newItems.length} 個項目'),
            backgroundColor: AppColors.success,
          ),
        );
        context.pop();
      }
    } catch (e) {
      setState(() => _error = '匯入失敗：$e');
    } finally {
      setState(() => _importing = false);
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadCollections());
  }

  @override
  Widget build(BuildContext context) {
    final grouped = <int, List<BangumiCollection>>{};
    for (final c in _collections) {
      grouped.putIfAbsent(c.status, () => []).add(c);
    }

    return AppScaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => context.pop(),
                  ),
                  const Expanded(
                    child: Text(
                      '匯入收藏列表',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (_selected.isNotEmpty)
                    TextButton(
                      onPressed: _importing ? null : _importSelected,
                      child: Text('匯入(${_selected.length})'),
                    ),
                ],
              ),
            ),

            // Category selector
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: DropdownButtonFormField<ItemCategory>(
                initialValue: _category,
                dropdownColor: AppColors.paperElevated,
                decoration: InputDecoration(
                  labelText: '分類',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: AppColors.paperElevated,
                ),
                items: ItemCategory.values
                    .map((c) => DropdownMenuItem(
                          value: c,
                          child: Text(c.label),
                        ))
                    .toList(),
                onChanged: (c) {
                  if (c != null) {
                    setState(() => _category = c);
                    _loadCollections();
                  }
                },
              ),
            ),

            const SizedBox(height: 12),

            // Content
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? Center(
                          child: Text(_error!,
                              style: const TextStyle(color: AppColors.danger)),
                        )
                      : _collections.isEmpty
                          ? const Center(
                              child: Text(
                                '此分類暫無收藏',
                                style: TextStyle(color: AppColors.inkMuted),
                              ),
                            )
                          : ListView(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              children: [
                                ..._buildGroup(
                                    grouped, 2, '在看', AppColors.anime),
                                ..._buildGroup(
                                    grouped, 1, '想看', AppColors.lightNovel),
                                ..._buildGroup(
                                    grouped, 3, '看過', AppColors.success),
                                ..._buildGroup(
                                    grouped, 4, '擱置', AppColors.warning),
                                ..._buildGroup(
                                    grouped, 5, '拋棄', AppColors.danger),
                                const SizedBox(height: 80),
                              ],
                            ),
            ),
          ],
        ),
      ),

      // Bottom action bar
      bottomNavigationBar: _selected.isNotEmpty
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: ElevatedButton(
                  onPressed: _importing ? null : _importSelected,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.anime,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _importing
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : Text(
                          '匯入 ${_selected.length} 個項目',
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            )
          : null,
    );
  }

  List<Widget> _buildGroup(Map<int, List<BangumiCollection>> grouped, int status,
      String label, Color color) {
    final items = grouped[status] ?? [];
    if (items.isEmpty) return [];

    return [
      Padding(
        padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 16,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '$label (${items.length})',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
      ...items.map((c) => _collectionTile(c)),
    ];
  }

  Widget _collectionTile(BangumiCollection c) {
    final isSelected = _selected.contains(c.subjectId);
    final alreadyExists = ref
        .read(itemsNotifierProvider)
        .any((i) => i.id == 'bgm_${c.subjectId}');

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.paperElevated,
        borderRadius: BorderRadius.circular(10),
        border: isSelected
            ? Border.all(color: AppColors.anime, width: 1)
            : null,
      ),
      child: CheckboxListTile(
        value: isSelected,
        onChanged: alreadyExists
            ? null
            : (v) {
                setState(() {
                  if (v == true) {
                    _selected.add(c.subjectId);
                  } else {
                    _selected.remove(c.subjectId);
                  }
                });
              },
        title: Text(
          c.displayName,
          style: TextStyle(
            fontSize: 14,
            color: alreadyExists ? AppColors.textMuted : Colors.white,
          ),
        ),
        subtitle: Text(
          alreadyExists ? '已存在' : (c.eps != null ? '${c.eps} 集' : ''),
          style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
        ),
        secondary: c.posterUrl != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: PosterImageWidget(
                  posterUrl: c.posterUrl,
                  type: switch (c.type) { 2 => 'anime', 1 => 'manga', 4 => 'game', _ => 'anime' },
                  width: 40,
                  height: 56,
                  fit: BoxFit.cover,
                  borderRadius: BorderRadius.circular(4),
                ),
              )
            : null,
        controlAffinity: ListTileControlAffinity.trailing,
        activeColor: AppColors.anime,
        checkColor: Colors.white,
      ),
    );
  }
}
