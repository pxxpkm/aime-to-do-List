import 'dart:async';

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:acg_todo/core/theme/app_colors.dart';
import 'package:acg_todo/core/utils/score_utils.dart';
import 'package:acg_todo/domain/entities/item.dart';
import 'package:acg_todo/presentation/providers/folders_provider.dart';
import 'package:acg_todo/presentation/providers/items_provider.dart';
import 'package:acg_todo/presentation/providers/repository_providers.dart';
import 'package:acg_todo/presentation/widgets/deadline_editor_sheet.dart';
import 'package:acg_todo/presentation/widgets/edit_total_units_dialog.dart';
import 'package:acg_todo/presentation/widgets/item_editor_sheet.dart';
import 'package:acg_todo/presentation/widgets/move_to_folder_sheet.dart';
import 'package:acg_todo/presentation/widgets/poster_image_widget.dart';
import 'package:acg_todo/presentation/widgets/tags_editor.dart';
import 'package:acg_todo/presentation/widgets/user_score_editor.dart';
import 'package:url_launcher/url_launcher.dart';

class ItemDetailPage extends ConsumerStatefulWidget {
  final String itemId;
  const ItemDetailPage({super.key, required this.itemId});

  @override
  ConsumerState<ItemDetailPage> createState() => _ItemDetailPageState();
}

class _ItemDetailPageState extends ConsumerState<ItemDetailPage> {
  late ConfettiController _confettiController;
  double? _sliderValue;
  Timer? _sliderDebounce;
  late TextEditingController _remarkController;
  Timer? _remarkDebounce;
  String? _remarkItemId;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 2));
    _remarkController = TextEditingController();
    // Bangumi 補圖
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final item = ref.read(itemsNotifierProvider)
          .where((i) => i.id == widget.itemId).firstOrNull;
      if (item != null) {
        if (_remarkItemId != item.id) {
          _remarkItemId = item.id;
          _remarkController.text = item.remark ?? '';
        }
        if (item.posterUrl == null && item.id.startsWith('bgm_')) {
          ref.read(itemsNotifierProvider.notifier).ensureBangumiPoster(widget.itemId);
        }
      }
    });
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _sliderDebounce?.cancel();
    _remarkDebounce?.cancel();
    _remarkController.dispose();
    super.dispose();
  }

  void _onRemarkChanged(String value) {
    _remarkDebounce?.cancel();
    _remarkDebounce = Timer(const Duration(milliseconds: 600), () {
      ref.read(itemsNotifierProvider.notifier).updateRemark(widget.itemId, value);
    });
  }

  bool _isComplete(Item item, int total) => item.currentUnits >= total;

  Future<void> _markComplete(Item item, int total) async {
    if (_isComplete(item, total)) return;
    await ref.read(itemsNotifierProvider.notifier).markComplete(item.id);
    _confettiController.play();
  }

  Future<void> _editTotalUnits(Item item) =>
      showEditTotalUnitsDialog(context, ref, item: item);

  void _onSliderChanged(double v) {
    setState(() => _sliderValue = v);
    _sliderDebounce?.cancel();
    _sliderDebounce = Timer(const Duration(milliseconds: 300), () {
      final newVal = v.toInt();
      final currentItem = ref.read(itemsNotifierProvider).where((i) => i.id == widget.itemId).firstOrNull;
      if (newVal != currentItem?.currentUnits) {
        ref.read(itemsNotifierProvider.notifier).updateProgress(widget.itemId, newVal);
      }
      if (mounted) setState(() => _sliderValue = null);
    });
  }

  @override
  Widget build(BuildContext context) {
    final items = ref.watch(itemsNotifierProvider);
    final item = items.where((i) => i.id == widget.itemId).firstOrNull;

    if (item == null) {
      return const Scaffold(
        body: Center(child: Text('項目不存在')),
      );
    }

    final color = AppColors.getTypeColor(item.type);
    final hasTotal = item.totalUnits != null && item.totalUnits! > 0;
    final total = hasTotal ? item.totalUnits! : null;
    final isComplete =
        hasTotal && item.currentUnits >= item.totalUnits!;
    final displayValue = _sliderValue ?? item.currentUnits.toDouble();
    final totalLabel = hasTotal ? '$total' : '?';
    if (_remarkItemId != item.id) {
      _remarkItemId = item.id;
      _remarkController.text = item.remark ?? '';
    }

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SafeArea(
          child: Stack(
            children: [
              CustomScrollView(
                slivers: [
                  // App bar
                  SliverAppBar(
                    pinned: true,
                    backgroundColor: Colors.transparent,
                    leading: IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => context.pop(),
                    ),
                    actions: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined),
                        tooltip: '編輯項目',
                        onPressed: () =>
                            showItemEditorSheet(context, ref, item: item),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () async {
                          await ref
                              .read(itemsNotifierProvider.notifier)
                              .deleteItem(item.id);
                          if (context.mounted) context.pop();
                        },
                      ),
                    ],
                  ),

                  // Hero poster（AspectRatio 自適應任何比例螢幕）
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 300),
                          child: Hero(
                            tag: item.id,
                            child: AspectRatio(
                              aspectRatio: 0.7,
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: color.withValues(alpha: 0.25),
                                    width: 1,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: color.withValues(alpha: 0.3),
                                      blurRadius: 16,
                                      offset: const Offset(0, 6),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(14),
                                  child: PosterImageWidget(
                                    posterUrl: item.posterUrl,
                                    type: item.type,
                                    width: double.infinity,
                                    height: double.infinity,
                                    fit: BoxFit.cover,
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 16)),

                  // Title + category
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              GestureDetector(
                                onTap: () => showItemEditorSheet(
                                    context, ref,
                                    item: item),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: color.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    item.type.toUpperCase(),
                                    style: TextStyle(
                                      color: color,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              const Spacer(),
                              TextButton.icon(
                                onPressed: () => showItemEditorSheet(
                                    context, ref,
                                    item: item),
                                icon: const Icon(Icons.edit, size: 14),
                                label: const Text('編輯',
                                    style: TextStyle(fontSize: 12)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          GestureDetector(
                            onTap: () =>
                                showItemEditorSheet(context, ref, item: item),
                            child: Text(
                              item.title,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          if (item.originalTitle != null &&
                              item.originalTitle!.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              item.originalTitle!,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.white.withValues(alpha: 0.5),
                              ),
                            ),
                          ],
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 10,
                            runSpacing: 6,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              InkWell(
                                onTap: () => showUserScoreEditor(
                                    context, ref,
                                    item: item),
                                child: Text(
                                  item.userScore != null
                                      ? '我的 ${formatUserScore(item.userScore!)}'
                                      : '我的評分 · 點擊設定',
                                  style: TextStyle(
                                    color: item.userScore != null
                                        ? AppColors.lightNovel
                                        : AppColors.textMuted,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              if (item.score != null)
                                Text(
                                  'BGM ★ ${item.score!.toStringAsFixed(1)}'
                                  '${item.scoreCount != null ? ' (${item.scoreCount})' : ''}',
                                  style: const TextStyle(
                                    color: Color(0xFFfbbf24),
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                  ),
                                ),
                              if (item.airDate != null &&
                                  item.airDate!.isNotEmpty)
                                Text(
                                  item.airDate!,
                                  style: const TextStyle(
                                    color: AppColors.textMuted,
                                    fontSize: 12,
                                  ),
                                ),
                              if (item.source != null)
                                Text(
                                  item.source!,
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.4),
                                    fontSize: 11,
                                  ),
                                ),
                              if (item.externalUrl != null)
                                TextButton.icon(
                                  onPressed: () async {
                                    final uri = Uri.tryParse(item.externalUrl!);
                                    if (uri != null) {
                                      await launchUrl(
                                        uri,
                                        mode: LaunchMode.externalApplication,
                                      );
                                    }
                                  },
                                  icon: const Icon(Icons.open_in_new, size: 14),
                                  label: Text(
                                    item.source == 'anilist'
                                        ? 'AniList'
                                        : 'Bangumi',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  style: TextButton.styleFrom(
                                    visualDensity: VisualDensity.compact,
                                    foregroundColor: color,
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  if (item.summary != null && item.summary!.isNotEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                        child: Text(
                          item.summary!,
                          maxLines: 6,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.4,
                            color: Colors.white.withValues(alpha: 0.7),
                          ),
                        ),
                      ),
                    ),

                  const SliverToBoxAdapter(child: SizedBox(height: 16)),

                  // Progress section
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  '進度：${item.currentUnits} / $totalLabel ${item.unitLabel}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ),
                              TextButton.icon(
                                onPressed: () => _editTotalUnits(item),
                                icon: const Icon(Icons.edit, size: 16),
                                label: Text(
                                  hasTotal ? '改總量' : '設總量',
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          if (hasTotal)
                            Slider(
                              value: displayValue.clamp(0, total!.toDouble()),
                              min: 0,
                              max: total.toDouble(),
                              activeColor: color,
                              inactiveColor: color.withValues(alpha: 0.2),
                              onChanged: _onSliderChanged,
                            )
                          else
                            Text(
                              '總量未知（常見於 Bangumi 輕小說）。請點「設總量」以便追進度。',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white.withValues(alpha: 0.45),
                              ),
                            ),

                          const SizedBox(height: 8),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _circleButton(
                                icon: Icons.remove,
                                color: color,
                                onTap: item.currentUnits > 0
                                    ? () => ref
                                        .read(itemsNotifierProvider.notifier)
                                        .updateProgress(
                                            item.id, item.currentUnits - 1)
                                    : null,
                              ),
                              const SizedBox(width: 20),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '${item.currentUnits} / $totalLabel',
                                  style: TextStyle(
                                    color: color,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 20),
                              _circleButton(
                                icon: Icons.add,
                                color: color,
                                onTap: !hasTotal ||
                                        item.currentUnits < total!
                                    ? () => ref
                                        .read(itemsNotifierProvider.notifier)
                                        .updateProgress(
                                            item.id, item.currentUnits + 1)
                                    : null,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 24)),

                  // Tags
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '標籤',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TagsEditor(
                            tags: item.tags,
                            suggestions:
                                ref.read(itemsRepositoryProvider).allTags(),
                            onChanged: (tags) {
                              ref
                                  .read(itemsNotifierProvider.notifier)
                                  .setTags(item.id, tags);
                            },
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 24)),

                  // Remark
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '備註',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _remarkController,
                            onChanged: _onRemarkChanged,
                            maxLines: 4,
                            minLines: 2,
                            decoration: InputDecoration(
                              hintText: '進度備忘、連結、感想…',
                              filled: true,
                              fillColor: Colors.white.withValues(alpha: 0.06),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 16)),

                  // Folder
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Builder(
                        builder: (context) {
                          final folders = ref.watch(foldersNotifierProvider);
                          final folderName = item.folderId == null
                              ? '未分類'
                              : (folders
                                      .where((f) => f.id == item.folderId)
                                      .firstOrNull
                                      ?.name ??
                                  '未分類');
                          return Material(
                            color: Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(12),
                            child: ListTile(
                              leading: Icon(Icons.folder_outlined, color: color),
                              title: const Text('資料夾'),
                              subtitle: Text(
                                folderName,
                                style: const TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 13,
                                ),
                              ),
                              trailing: const Icon(
                                Icons.chevron_right,
                                color: AppColors.textMuted,
                              ),
                              onTap: () => showMoveToFolderSheet(
                                context,
                                ref,
                                itemId: item.id,
                                currentFolderId: item.folderId,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 16)),

                  // Deadline + remind
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Material(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(12),
                        child: ListTile(
                          leading: Icon(Icons.event_outlined, color: color),
                          title: const Text('限期與提醒'),
                          subtitle: Text(
                            item.deadline == null
                                ? '未設定 · 點擊設定到期日與提醒日'
                                : '${item.deadline!.year}/${item.deadline!.month}/${item.deadline!.day}'
                                    ' · ${_remindLabel(item)}',
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 12,
                            ),
                          ),
                          trailing: const Icon(
                            Icons.chevron_right,
                            color: AppColors.textMuted,
                          ),
                          onTap: () => showDeadlineEditor(
                            context,
                            ref,
                            itemId: item.id,
                            currentDeadline: item.deadline,
                            remindMode: item.deadlineRemindMode,
                            customOffsets: item.customDeadlineOffsets,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 80)),
                ],
              ),

              // Confetti overlay
              Align(
                alignment: Alignment.topCenter,
                child: ConfettiWidget(
                  confettiController: _confettiController,
                  blastDirectionality: BlastDirectionality.explosive,
                  shouldLoop: false,
                  colors: [color, Colors.white, Colors.yellow],
                ),
              ),
            ],
          ),
        ),
      ),

      // Bottom action — two buttons side by side
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // 📌 標記（保存進度 + 返回主頁）
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    _sliderDebounce?.cancel();
                    final valueToSave = _sliderValue ?? item.currentUnits.toDouble();
                    ref.read(itemsNotifierProvider.notifier)
                        .updateProgress(item.id, valueToSave.toInt());
                    if (context.mounted) context.pop();
                  },
                  icon: const Icon(Icons.save, size: 18),
                  label: const Text(
                    '標記',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.lightNovel,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // ✓ 標記完成
              Expanded(
                child: ElevatedButton(
                  onPressed: isComplete
                      ? () => ref
                          .read(itemsNotifierProvider.notifier)
                          .uncomplete(item.id)
                      : (!hasTotal
                          ? null
                          : () => _markComplete(item, total!)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: color.withValues(alpha: 0.3),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    isComplete
                        ? '取消完成'
                        : (hasTotal ? '標記完成' : '先設總量'),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _remindLabel(Item item) {
    switch (item.deadlineRemindMode) {
      case 'off':
        return '不提醒';
      case 'custom':
        return '自訂 ${item.customDeadlineOffsets ?? ''}';
      default:
        return '使用全域提醒日';
    }
  }

  Widget _circleButton({
    required IconData icon,
    required Color color,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: onTap != null
              ? color.withValues(alpha: 0.2)
              : Colors.white.withValues(alpha: 0.05),
          shape: BoxShape.circle,
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Icon(icon, color: onTap != null ? color : AppColors.textMuted),
      ),
    );
  }
}
