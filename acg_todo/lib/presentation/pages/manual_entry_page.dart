import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:acg_todo/core/theme/app_colors.dart';
import 'package:acg_todo/core/theme/app_scaffold.dart';
import 'package:acg_todo/core/utils/poster_url.dart';
import 'package:acg_todo/domain/entities/item.dart';
import 'package:acg_todo/domain/entities/item_category.dart';
import 'package:acg_todo/presentation/providers/items_provider.dart';

class ManualEntryPage extends ConsumerStatefulWidget {
  const ManualEntryPage({super.key});

  @override
  ConsumerState<ManualEntryPage> createState() => _ManualEntryPageState();
}

class _ManualEntryPageState extends ConsumerState<ManualEntryPage> {
  final _titleController = TextEditingController();
  final _posterUrlController = TextEditingController();
  final _totalController = TextEditingController();
  ItemCategory _category = ItemCategory.anime;
  DateTime? _deadline;

  @override
  void dispose() {
    _titleController.dispose();
    _posterUrlController.dispose();
    _totalController.dispose();
    super.dispose();
  }

  Future<void> _pickDeadline() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (picked != null) setState(() => _deadline = picked);
  }

  Future<void> _save() async {
    if (_titleController.text.trim().isEmpty) return;

    final total = int.tryParse(_totalController.text);
    final item = Item(
      id: 'manual_${DateTime.now().millisecondsSinceEpoch}',
      userId: 'local_user',
      type: _category.storageKey,
      title: _titleController.text.trim(),
      posterUrl: normalizePosterUrl(
        _posterUrlController.text.trim().isNotEmpty
            ? _posterUrlController.text.trim()
            : null,
      ),
      totalUnits: total,
      currentUnits: 0,
      unitLabel: _category.unitLabel,
      status: 'in_progress',
      deadline: _deadline,
      source: 'manual',
    );

    await ref.read(itemsNotifierProvider.notifier).addItem(item);
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
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
                  const Text(
                    '手動建立',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    // Category picker
                    const Text('類別', style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: ItemCategory.values.map((c) {
                        final selected = _category == c;
                        return GestureDetector(
                          onTap: () => setState(() => _category = c),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: selected
                                  ? c.color
                                  : c.color.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: selected
                                    ? c.color
                                    : c.color.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Text(
                              c.label,
                              style: TextStyle(
                                color: selected ? Colors.white : c.color,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 24),

                    // Title
                    const Text('標題 *',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        hintText: '作品名稱',
                        filled: true,
                        fillColor: AppColors.paperElevated,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Poster URL
                    const Text('海報圖片網址（選填）',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _posterUrlController,
                      decoration: InputDecoration(
                        hintText: 'https://...',
                        filled: true,
                        fillColor: AppColors.paperElevated,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Total units
                    Text('總共${_category.unitLabel == '%' ? '（百分比）' : '有幾'}${_category.unitLabel}（選填）',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _totalController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: '例如：12',
                        filled: true,
                        fillColor: AppColors.paperElevated,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Deadline
                    const Text('限期（選填）',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: _pickDeadline,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.paperElevated,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today_outlined, size: 18),
                            const SizedBox(width: 12),
                            Text(
                              _deadline != null
                                  ? '${_deadline!.year}/${_deadline!.month}/${_deadline!.day}'
                                  : '選擇日期',
                              style: TextStyle(
                                color: _deadline != null
                                    ? Colors.white
                                    : AppColors.inkMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 40),

                    // Save button
                    ElevatedButton(
                      onPressed: _titleController.text.trim().isNotEmpty
                          ? _save
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _category.color,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        '建立項目',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
    );
  }
}
