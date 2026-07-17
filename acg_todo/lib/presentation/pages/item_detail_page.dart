import 'dart:async';

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:acg_todo/core/theme/app_colors.dart';
import 'package:acg_todo/core/theme/app_scaffold.dart';
import 'package:acg_todo/core/theme/app_shadows.dart';
import 'package:acg_todo/core/theme/app_typography.dart';
import 'package:acg_todo/core/utils/date_utils.dart' as app_date;
import 'package:acg_todo/core/utils/item_display.dart';
import 'package:acg_todo/core/utils/score_utils.dart';
import 'package:acg_todo/domain/entities/item.dart';
import 'package:acg_todo/domain/entities/item_category.dart';
import 'package:acg_todo/domain/entities/pin_tier.dart';
import 'package:acg_todo/presentation/pages/item_detail/detail_layout.dart';
import 'package:acg_todo/presentation/pages/item_detail/detail_paper_section.dart';
import 'package:acg_todo/presentation/pages/item_detail/detail_progress_card.dart';
import 'package:acg_todo/presentation/pages/item_detail/poster_fullscreen_dialog.dart';
import 'package:acg_todo/presentation/providers/daily_goal_provider.dart';
import 'package:acg_todo/presentation/providers/folders_provider.dart';
import 'package:acg_todo/presentation/providers/items_provider.dart';
import 'package:acg_todo/presentation/providers/repository_providers.dart';
import 'package:acg_todo/presentation/widgets/deadline_editor_sheet.dart';
import 'package:acg_todo/presentation/widgets/edit_total_units_dialog.dart';
import 'package:acg_todo/presentation/widgets/item_editor_sheet.dart';
import 'package:acg_todo/presentation/widgets/move_to_folder_sheet.dart';
import 'package:acg_todo/presentation/widgets/paper_filter_chip.dart';
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
  bool _summaryExpanded = false;

  @override
  void initState() {
    super.initState();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 2));
    _remarkController = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final item = ref
          .read(itemsNotifierProvider)
          .where((i) => i.id == widget.itemId)
          .firstOrNull;
      if (item != null) {
        if (_remarkItemId != item.id) {
          _remarkItemId = item.id;
          _remarkController.text = item.remark ?? '';
        }
        if (item.posterUrl == null && item.id.startsWith('bgm_')) {
          ref
              .read(itemsNotifierProvider.notifier)
              .ensureBangumiPoster(widget.itemId);
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
      final currentItem = ref
          .read(itemsNotifierProvider)
          .where((i) => i.id == widget.itemId)
          .firstOrNull;
      if (newVal != currentItem?.currentUnits) {
        ref
            .read(itemsNotifierProvider.notifier)
            .updateProgress(widget.itemId, newVal);
      }
      if (mounted) setState(() => _sliderValue = null);
    });
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
    final isComplete = hasTotal && item.currentUnits >= item.totalUnits!;
    final displayValue = _sliderValue ?? item.currentUnits.toDouble();
    if (_remarkItemId != item.id) {
      _remarkItemId = item.id;
      _remarkController.text = item.remark ?? '';
    }
    // Item detail is full-screen; viewport width is fine for CTA placement.
    final useWideChrome = MediaQuery.sizeOf(context).width >= 900;

    return AppScaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                _buildAppBar(item),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final wide = useWideDetailLayout(constraints);
                      if (wide) {
                        return _buildWideBody(
                          item: item,
                          color: color,
                          displayValue: displayValue,
                          hasTotal: hasTotal,
                          total: total,
                          isComplete: isComplete,
                          constraints: constraints,
                        );
                      }
                      return _buildNarrowBody(
                        item: item,
                        color: color,
                        displayValue: displayValue,
                        hasTotal: hasTotal,
                        total: total,
                      );
                    },
                  ),
                ),
              ],
            ),
            Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _confettiController,
                blastDirectionality: BlastDirectionality.explosive,
                shouldLoop: false,
                numberOfParticles: 28,
                maxBlastForce: 25,
                minBlastForce: 8,
                emissionFrequency: 0.05,
                gravity: 0.15,
                colors: [
                  color,
                  AppColors.lightNovel,
                  AppColors.success,
                  const Color(0xFFE8B86D),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: useWideChrome
          ? null
          : _buildBottomBar(
              item: item,
              color: color,
              hasTotal: hasTotal,
              total: total,
              isComplete: isComplete,
            ),
    );
  }

  Widget _buildAppBar(Item item) {
    return Material(
      color: AppColors.paperBg.withValues(alpha: 0.96),
      child: SizedBox(
        height: 52,
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.pop(),
            ),
            Expanded(
              child: Builder(
                builder: (context) {
                  ref.watch(dailyGoalTickProvider);
                  final s2t =
                      ref.watch(goalSettingsStoreProvider).titleSimpToTrad;
                  return Text(
                    displayTitle(item.title, simpToTrad: s2t),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.title.copyWith(fontSize: 16),
                  );
                },
              ),
            ),
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: '編輯項目',
              onPressed: () => showItemEditorSheet(context, ref, item: item),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: '刪除',
              onPressed: () async {
                await ref
                    .read(itemsNotifierProvider.notifier)
                    .deleteItem(item.id);
                if (mounted) context.pop();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWideBody({
    required Item item,
    required Color color,
    required double displayValue,
    required bool hasTotal,
    required int? total,
    required bool isComplete,
    required BoxConstraints constraints,
  }) {
    final posterColW = widePosterColumnWidth(constraints.maxWidth);
    final size = widePosterSize(
      columnWidth: posterColW - 20,
      availableHeight: constraints.maxHeight - 12,
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          width: posterColW,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 6, 6, 8),
            child: Align(
              alignment: Alignment.topCenter,
              child: _PosterPane(
                item: item,
                width: size.width,
                height: size.height,
              ),
            ),
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(6, 6, 16, 12),
                  children: [
                    _buildHeader(item, color),
                    const SizedBox(height: 10),
                    _buildProgress(item, color, displayValue, hasTotal, total),
                    const SizedBox(height: 10),
                    _buildInfoPanel(item, color, wide: true),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 0, 16, 10),
                child: _buildCompleteButton(
                  item: item,
                  color: color,
                  hasTotal: hasTotal,
                  total: total,
                  isComplete: isComplete,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNarrowBody({
    required Item item,
    required Color color,
    required double displayValue,
    required bool hasTotal,
    required int? total,
  }) {
    final media = MediaQuery.sizeOf(context);
    final size = portraitPosterSize(
      mediaWidth: media.width,
      mediaHeight: media.height,
    );

    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
          child: Center(
            child: _PosterPane(
              item: item,
              width: size.width,
              height: size.height,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _buildHeader(item, color),
        ),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _buildProgress(item, color, displayValue, hasTotal, total),
        ),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _buildInfoPanel(item, color, wide: false),
        ),
      ],
    );
  }

  static String _statusLabel(String status) => switch (status) {
        'completed' => '已完成',
        'paused' => '暫停',
        'dropped' => '棄坑',
        _ => '進行中',
      };

  Future<void> _cycleStatus(Item item) async {
    const order = ['in_progress', 'paused', 'dropped', 'completed'];
    final i = order.indexOf(item.status);
    final next = order[(i < 0 ? 0 : i + 1) % order.length];
    await ref.read(itemsNotifierProvider.notifier).setStatus(item.id, next);
  }

  Future<void> _cyclePin(Item item) async {
    final next = switch (item.pinTier) {
      PinTier.none => PinTier.watching,
      PinTier.watching => PinTier.priority,
      PinTier.priority => PinTier.none,
    };
    await ref.read(itemsNotifierProvider.notifier).setPinTier(item.id, next);
  }

  Future<void> _pickStatus(Item item) async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.paperElevated,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final s in const [
              'in_progress',
              'paused',
              'dropped',
              'completed',
            ])
              ListTile(
                title: Text(_statusLabel(s)),
                trailing: item.status == s
                    ? const Icon(Icons.check, color: AppColors.success)
                    : null,
                onTap: () => Navigator.pop(ctx, s),
              ),
          ],
        ),
      ),
    );
    if (picked == null || picked == item.status) return;
    await ref.read(itemsNotifierProvider.notifier).setStatus(item.id, picked);
  }

  Future<void> _pickPin(Item item) async {
    final picked = await showModalBottomSheet<PinTier>(
      context: context,
      backgroundColor: AppColors.paperElevated,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final t in PinTier.values)
              ListTile(
                leading: Icon(
                  t.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                ),
                title: Text(t == PinTier.none ? '不釘選' : t.label),
                trailing: item.pinTier == t
                    ? const Icon(Icons.check, color: AppColors.success)
                    : null,
                onTap: () => Navigator.pop(ctx, t),
              ),
          ],
        ),
      ),
    );
    if (picked == null || picked == item.pinTier) return;
    await ref.read(itemsNotifierProvider.notifier).setPinTier(item.id, picked);
  }

  String? _lastProgressLabel(Item item) {
    final at = item.lastProgressAt;
    if (at == null) return null;
    final days = DateTime.now().difference(at).inDays;
    if (days <= 0) return '上次進度 · 今天';
    if (days == 1) return '上次進度 · 昨天';
    if (days < 30) return '上次進度 · $days 天前';
    return '上次進度 · ${app_date.DateUtils.formatDate(at)}';
  }

  Widget _buildHeader(Item item, Color color) {
    ref.watch(dailyGoalTickProvider);
    final s2t = ref.watch(goalSettingsStoreProvider).titleSimpToTrad;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 6,
          runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            PaperFilterChip(
              label: ItemCategory.fromStorageKey(item.type).label,
              selected: true,
              accent: color,
            ),
            PaperFilterChip(
              label: _statusLabel(item.status),
              selected: item.status == 'in_progress',
              accent: item.status == 'completed'
                  ? AppColors.success
                  : item.status == 'dropped'
                      ? AppColors.danger
                      : color,
              onTap: () => _cycleStatus(item),
              onLongPress: () => _pickStatus(item),
            ),
            PaperFilterChip(
              label: item.pinTier == PinTier.none
                  ? '釘選'
                  : item.pinTier.label,
              selected: item.pinTier.isPinned,
              accent: AppColors.lightNovel,
              icon: item.pinTier.isPinned
                  ? Icons.push_pin
                  : Icons.push_pin_outlined,
              onTap: () => _cyclePin(item),
              onLongPress: () => _pickPin(item),
            ),
            if (item.source != null)
              PaperFilterChip(
                label: item.source == 'anilist'
                    ? 'AniList'
                    : item.source == 'bangumi'
                        ? 'Bangumi'
                        : item.source!,
                selected: false,
                accent: color,
              ),
            if (item.airDate != null && item.airDate!.isNotEmpty)
              PaperFilterChip(
                label: item.airDate!,
                selected: false,
                accent: AppColors.inkMuted,
              ),
            if (item.externalUrl != null)
              PaperFilterChip(
                label: '連結',
                selected: false,
                accent: color,
                icon: Icons.open_in_new,
                onTap: () async {
                  final uri = Uri.tryParse(item.externalUrl!);
                  if (uri != null) {
                    await launchUrl(
                      uri,
                      mode: LaunchMode.externalApplication,
                    );
                  }
                },
              ),
            PaperFilterChip(
              label: item.userScore != null
                  ? '我的 ${formatUserScore(item.userScore!)}'
                  : '我的評分',
              selected: item.userScore != null,
              accent: AppColors.lightNovel,
              onTap: () => showUserScoreEditor(context, ref, item: item),
            ),
            if (item.score != null)
              PaperFilterChip(
                label:
                    '★ ${item.score!.toStringAsFixed(1)}'
                    '${item.scoreCount != null ? ' · ${item.scoreCount}' : ''}',
                selected: false,
                accent: AppColors.lightNovel,
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          displayTitle(item.title, simpToTrad: s2t),
          style: AppTypography.display.copyWith(fontSize: 22, height: 1.2),
        ),
        if (item.originalTitle != null && item.originalTitle!.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            displayTitle(item.originalTitle!, simpToTrad: s2t),
            style: AppTypography.caption.copyWith(
              color: AppColors.inkMuted,
              fontSize: 12,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildProgress(
    Item item,
    Color color,
    double displayValue,
    bool hasTotal,
    int? total,
  ) {
    final notifier = ref.read(itemsNotifierProvider.notifier);
    return DetailProgressCard(
      item: item,
      color: color,
      displayValue: displayValue,
      hasTotal: hasTotal,
      total: total,
      onEditTotal: () => _editTotalUnits(item),
      onSliderChanged: _onSliderChanged,
      onDecrement: item.currentUnits > 0
          ? () => notifier.updateProgress(item.id, item.currentUnits - 1)
          : null,
      onIncrement: !hasTotal || (total != null && item.currentUnits < total)
          ? () => notifier.updateProgress(item.id, item.currentUnits + 1)
          : null,
      lastProgressLabel: _lastProgressLabel(item),
      onBookmarkHere: () =>
          notifier.bookmarkItem(item.id, item.currentUnits),
      onJumpToBookmark: item.bookmarkUnits != null
          ? () => notifier.updateProgress(item.id, item.bookmarkUnits!)
          : null,
    );
  }

  /// Merged about + manage; wide mode uses 2-column interior.
  Widget _buildInfoPanel(Item item, Color color, {required bool wide}) {
    final folders = ref.watch(foldersNotifierProvider);
    final folderName = item.folderId == null
        ? '未分類'
        : (folders.where((f) => f.id == item.folderId).firstOrNull?.name ??
            '未分類');
    final deadlineLabel = item.deadline == null
        ? '未設定限期'
        : '${app_date.DateUtils.formatDate(item.deadline!)} · ${app_date.DateUtils.formatCountdown(item.deadline!)}';
    final hasSummary = item.summary != null && item.summary!.isNotEmpty;

    final summaryBlock = hasSummary
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const DetailSectionLabel('簡介'),
              const SizedBox(height: 4),
              Text(
                item.summary!,
                maxLines: _summaryExpanded ? 40 : 3,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.body.copyWith(
                  fontSize: 13,
                  height: 1.4,
                  color: AppColors.inkSecondary,
                ),
              ),
              if (item.summary!.length > 100)
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: () =>
                        setState(() => _summaryExpanded = !_summaryExpanded),
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      foregroundColor: color,
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      _summaryExpanded ? '收起' : '展開',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ),
            ],
          )
        : null;

    final tagsBlock = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const DetailSectionLabel('標籤'),
        const SizedBox(height: 6),
        TagsEditor(
          tags: item.tags,
          suggestions: ref.read(itemsRepositoryProvider).allTags(),
          onChanged: (tags) {
            ref.read(itemsNotifierProvider.notifier).setTags(item.id, tags);
          },
        ),
      ],
    );

    final remarkBlock = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const DetailSectionLabel('備註'),
        const SizedBox(height: 6),
        TextField(
          controller: _remarkController,
          onChanged: _onRemarkChanged,
          maxLines: 3,
          minLines: 2,
          style: AppTypography.body.copyWith(fontSize: 13),
          decoration: InputDecoration(
            hintText: '進度備忘、連結、感想…',
            isDense: true,
            filled: true,
            fillColor: AppColors.paperSurface,
            contentPadding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.borderSubtle),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.borderSubtle),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: color, width: 1.5),
            ),
          ),
        ),
      ],
    );

    final datesFooter = (item.createdAt != null || item.completedAt != null)
        ? Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              [
                if (item.createdAt != null)
                  '加入 ${app_date.DateUtils.formatDate(item.createdAt!)}',
                if (item.completedAt != null)
                  '完成 ${app_date.DateUtils.formatDate(item.completedAt!)}',
              ].join(' · '),
              style: AppTypography.micro.copyWith(color: AppColors.inkMuted),
            ),
          )
        : null;

    final manageGrid = Row(
      children: [
        Expanded(
          child: _ManageMiniCard(
            icon: Icons.folder_outlined,
            color: color,
            title: '資料夾',
            subtitle: folderName,
            onTap: () => showMoveToFolderSheet(
              context,
              ref,
              itemId: item.id,
              currentFolderId: item.folderId,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _ManageMiniCard(
            icon: Icons.event_outlined,
            color: color,
            title: '限期',
            subtitle: deadlineLabel,
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
      ],
    );

    final manageList = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ListTile(
          dense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 4),
          visualDensity: VisualDensity.compact,
          leading: Icon(Icons.folder_outlined, color: color, size: 22),
          title: Text('資料夾 · $folderName', style: AppTypography.caption),
          trailing: const Icon(
            Icons.chevron_right,
            size: 18,
            color: AppColors.inkMuted,
          ),
          onTap: () => showMoveToFolderSheet(
            context,
            ref,
            itemId: item.id,
            currentFolderId: item.folderId,
          ),
        ),
        ListTile(
          dense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 4),
          visualDensity: VisualDensity.compact,
          leading: Icon(Icons.event_outlined, color: color, size: 22),
          title: Text(deadlineLabel, style: AppTypography.caption),
          subtitle: item.deadline != null
              ? Text(
                  _remindLabel(item),
                  style:
                      AppTypography.micro.copyWith(color: AppColors.inkMuted),
                )
              : null,
          trailing: const Icon(
            Icons.chevron_right,
            size: 18,
            color: AppColors.inkMuted,
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
      ],
    );

    return DetailPaperSection(
      title: '詳情',
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: wide
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                manageGrid,
                if (datesFooter != null) datesFooter,
                if (summaryBlock != null) ...[
                  const SizedBox(height: 10),
                  const Divider(height: 1, color: AppColors.divider),
                  const SizedBox(height: 8),
                  summaryBlock,
                ],
                const SizedBox(height: 10),
                const Divider(height: 1, color: AppColors.divider),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: tagsBlock),
                    const SizedBox(width: 12),
                    Expanded(child: remarkBlock),
                  ],
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (summaryBlock != null) ...[
                  summaryBlock,
                  const SizedBox(height: 8),
                  const Divider(height: 1, color: AppColors.divider),
                  const SizedBox(height: 8),
                ],
                tagsBlock,
                const SizedBox(height: 10),
                remarkBlock,
                const SizedBox(height: 8),
                const Divider(height: 1, color: AppColors.divider),
                manageList,
                if (datesFooter != null) datesFooter,
              ],
            ),
    );
  }

  Widget _buildCompleteButton({
    required Item item,
    required Color color,
    required bool hasTotal,
    required int? total,
    required bool isComplete,
  }) {
    return FilledButton(
      onPressed: isComplete
          ? () =>
              ref.read(itemsNotifierProvider.notifier).uncomplete(item.id)
          : (!hasTotal ? null : () => _markComplete(item, total!)),
      style: FilledButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        disabledBackgroundColor: color.withValues(alpha: 0.28),
        disabledForegroundColor: Colors.white70,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
      child: Text(
        isComplete ? '取消完成' : (hasTotal ? '標記完成' : '先設總量'),
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildBottomBar({
    required Item item,
    required Color color,
    required bool hasTotal,
    required int? total,
    required bool isComplete,
  }) {
    return Material(
      color: AppColors.paperElevated,
      elevation: 0,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.divider)),
          boxShadow: [
            BoxShadow(
              color: Color(0x122C2416),
              blurRadius: 12,
              offset: Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
            child: _buildCompleteButton(
              item: item,
              color: color,
              hasTotal: hasTotal,
              total: total,
              isComplete: isComplete,
            ),
          ),
        ),
      ),
    );
  }
}

class _ManageMiniCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ManageMiniCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.paperSurface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.borderSubtle),
          ),
          child: Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTypography.micro.copyWith(
                        color: AppColors.inkMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.caption.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.inkPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PosterPane extends StatelessWidget {
  final Item item;
  final double width;
  final double height;

  const _PosterPane({
    required this.item,
    required this.width,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => showPosterFullscreen(
          context,
          posterUrl: item.posterUrl,
          type: item.type,
          title: item.title,
        ),
        child: Ink(
          width: width,
          height: height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.borderSubtle),
            boxShadow: AppShadows.card,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(13),
            child: Hero(
              tag: item.id,
              child: PosterImageWidget(
                posterUrl: item.posterUrl,
                type: item.type,
                width: width,
                height: height,
                fit: BoxFit.cover,
                borderRadius: BorderRadius.circular(13),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
