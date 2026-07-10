import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:reorderable_grid_view/reorderable_grid_view.dart';

import 'package:acg_todo/core/theme/app_colors.dart';
import 'package:acg_todo/domain/entities/item.dart';
import 'package:acg_todo/domain/entities/item_category.dart';
import 'package:acg_todo/domain/services/item_sort_service.dart';
import 'package:acg_todo/presentation/home/home_item_query.dart';
import 'package:acg_todo/presentation/home/home_layout.dart';
import 'package:acg_todo/presentation/providers/daily_goal_provider.dart';
import 'package:acg_todo/presentation/providers/folders_provider.dart';
import 'package:acg_todo/presentation/providers/items_provider.dart';
import 'package:acg_todo/presentation/providers/notification_providers.dart';
import 'package:acg_todo/presentation/providers/repository_providers.dart';
import 'package:acg_todo/presentation/widgets/category_chip.dart';
import 'package:acg_todo/presentation/widgets/daily_goal_bar.dart';
import 'package:acg_todo/presentation/widgets/deadline_editor_sheet.dart';
import 'package:acg_todo/presentation/widgets/edit_total_units_dialog.dart';
import 'package:acg_todo/presentation/widgets/folder_chip_bar.dart';
import 'package:acg_todo/presentation/widgets/folder_tile.dart';
import 'package:acg_todo/presentation/widgets/item_editor_sheet.dart';
import 'package:acg_todo/presentation/widgets/move_to_folder_sheet.dart';
import 'package:acg_todo/presentation/widgets/poster_card.dart';
import 'package:acg_todo/presentation/widgets/user_score_editor.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  ItemCategory? _typeFilter;
  String? _folderFilter;
  /// null = all tags; '' = no tags; else tag name
  String? _tagFilter;
  String? _dropHighlightFolderId;
  bool _selectionMode = false;
  final Set<String> _selectedIds = {};
  HomeSortMode get _sortMode =>
      ref.read(goalSettingsStoreProvider).homeSortMode;

  List<Item> _filterItems(List<Item> items, HomeSortMode sortMode) {
    return filterAndSortHomeItems(
      items: items,
      sortMode: sortMode,
      typeKey: _typeFilter?.storageKey,
      folderFilter: _folderFilter,
      tagFilter: _tagFilter,
    );
  }

  void _toggleSelect(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  void _exitSelection() {
    setState(() {
      _selectionMode = false;
      _selectedIds.clear();
    });
  }

  Future<void> _deleteSelected() async {
    if (_selectedIds.isEmpty) return;
    final n = _selectedIds.length;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('批量刪除'),
        content: Text('確定刪除 $n 個項目？無法復原。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('刪除', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await ref
        .read(itemsNotifierProvider.notifier)
        .deleteItems(_selectedIds.toList());
    if (!mounted) return;
    _exitSelection();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('已刪除 $n 項'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _confirmDeleteOne(Item item) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('刪除項目'),
        content: Text('確定刪除「${item.title}」？無法復原。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('刪除', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await ref.read(itemsNotifierProvider.notifier).deleteItem(item.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('已刪除'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Reorder only in manual sort + folder/uncategorized (not mixed "all").
  bool get _itemListReorder =>
      _sortMode == HomeSortMode.manual && _folderFilter != null;

  /// Mixed folder tiles: only "全部" + 手動排序.
  bool _useMixedHome(HomeSortMode sortMode) => useMixedHomeLayout(
        folderFilter: _folderFilter,
        sortMode: sortMode,
      );

  Future<void> _onReorder(
    int oldIndex,
    int newIndex,
    List<Item> filtered,
  ) async {
    if (oldIndex == newIndex) return;
    final list = List<Item>.from(filtered);
    final item = list.removeAt(oldIndex);
    final insertAt = newIndex.clamp(0, list.length);
    list.insert(insertAt, item);
    await ref.read(itemsNotifierProvider.notifier).reorderVisibleItems(list);
  }

  Future<void> _onIncrement(Item item) async {
    await ref.read(itemsNotifierProvider.notifier).incrementProgress(item.id);
    if (!mounted) return;
    final updated = ref
        .read(itemsNotifierProvider)
        .where((i) => i.id == item.id)
        .firstOrNull;
    final label = updated != null
        ? '${updated.currentUnits}/${updated.totalUnits ?? '?'} ${updated.unitLabel}'
        : '+1';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${item.title} → $label'),
        duration: const Duration(milliseconds: 900),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _openMoveSheet(Item item) async {
    await showMoveToFolderSheet(
      context,
      ref,
      itemId: item.id,
      currentFolderId: item.folderId,
    );
  }

  Future<void> _openDeadline(Item item) async {
    await showDeadlineEditor(
      context,
      ref,
      itemId: item.id,
      currentDeadline: item.deadline,
      remindMode: item.deadlineRemindMode,
      customOffsets: item.customDeadlineOffsets,
    );
  }

  Future<void> _dropIntoFolder(Item item, String? folderId) async {
    await ref.read(itemsNotifierProvider.notifier).moveToFolder(
          item.id,
          folderId,
        );
    if (!mounted) return;
    final name = folderId == null
        ? '未分類'
        : (ref
                .read(foldersNotifierProvider)
                .where((f) => f.id == folderId)
                .firstOrNull
                ?.name ??
            '資料夾');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('已移至「$name」'),
        duration: const Duration(milliseconds: 900),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showItemMenu(Item item) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.folder_outlined),
                title: const Text('移到資料夾'),
                onTap: () {
                  Navigator.pop(ctx);
                  _openMoveSheet(item);
                },
              ),
              ListTile(
                leading: const Icon(Icons.numbers),
                title: const Text('改總量'),
                onTap: () {
                  Navigator.pop(ctx);
                  showEditTotalUnitsDialog(context, ref, item: item);
                },
              ),
              ListTile(
                leading: const Icon(Icons.star_half),
                title: const Text('我的評分'),
                onTap: () {
                  Navigator.pop(ctx);
                  showUserScoreEditor(context, ref, item: item);
                },
              ),
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: const Text('編輯項目…'),
                onTap: () {
                  Navigator.pop(ctx);
                  showItemEditorSheet(context, ref, item: item);
                },
              ),
              ListTile(
                leading: const Icon(Icons.event_outlined),
                title: const Text('限期與提醒'),
                onTap: () {
                  Navigator.pop(ctx);
                  _openDeadline(item);
                },
              ),
              ListTile(
                leading: const Icon(Icons.sticky_note_2_outlined),
                title: const Text('編輯備註'),
                onTap: () {
                  Navigator.pop(ctx);
                  _editRemark(item);
                },
              ),
              if (item.status == 'completed')
                ListTile(
                  leading: const Icon(Icons.undo),
                  title: const Text('取消完成'),
                  onTap: () async {
                    Navigator.pop(ctx);
                    await ref
                        .read(itemsNotifierProvider.notifier)
                        .uncomplete(item.id);
                  },
                ),
              ListTile(
                leading:
                    const Icon(Icons.delete_outline, color: AppColors.danger),
                title:
                    const Text('刪除', style: TextStyle(color: AppColors.danger)),
                onTap: () {
                  Navigator.pop(ctx);
                  _confirmDeleteOne(item);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _editRemark(Item item) async {
    final controller = TextEditingController(text: item.remark ?? '');
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('備註'),
        content: TextField(
          controller: controller,
          maxLines: 5,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: '進度備忘、連結、感想…',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: const Text('儲存'),
          ),
        ],
      ),
    );
    if (result == null) return;
    await ref.read(itemsNotifierProvider.notifier).updateRemark(item.id, result);
  }

  Future<void> _setSortMode(HomeSortMode mode) async {
    await ref.read(goalSettingsStoreProvider).setHomeSortMode(mode);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final items = ref.watch(itemsNotifierProvider);
    final folders = ref.watch(foldersNotifierProvider);
    ref.watch(dailyGoalTickProvider);
    final store = ref.watch(goalSettingsStoreProvider);
    final density = store.homeGridDensity;
    final sortMode = store.homeSortMode;
    final layout = homeGridLayout(density);
    final filtered = _filterItems(items, sortMode);
    final allTags = ref.read(itemsRepositoryProvider).allTags();

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 12, 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (_selectionMode)
                      Text(
                        '已選 ${_selectedIds.length}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    else
                      const Text(
                        'ACG To-Do',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.5,
                        ),
                      ),
                    if (_selectionMode)
                      Row(
                        children: [
                          TextButton(
                            onPressed: _exitSelection,
                            child: const Text('取消'),
                          ),
                          TextButton(
                            onPressed:
                                _selectedIds.isEmpty ? null : _deleteSelected,
                            child: Text(
                              '刪除',
                              style: TextStyle(
                                color: _selectedIds.isEmpty
                                    ? AppColors.textMuted
                                    : AppColors.danger,
                              ),
                            ),
                          ),
                        ],
                      )
                    else
                      Row(
                        children: [
                          PopupMenuButton<HomeSortMode>(
                            tooltip: '排序',
                            initialValue: sortMode,
                            onSelected: _setSortMode,
                            itemBuilder: (ctx) => [
                              for (final m in HomeSortMode.values)
                                PopupMenuItem(
                                  value: m,
                                  child: Text(
                                    m == sortMode ? '✓ ${m.label}' : m.label,
                                  ),
                                ),
                            ],
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 6),
                              child: Row(
                                children: [
                                  const Icon(Icons.sort, size: 18),
                                  const SizedBox(width: 4),
                                  Text(
                                    sortMode.label,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: () =>
                                setState(() => _selectionMode = true),
                            child: const Text('選擇'),
                          ),
                          _HeaderIcon(
                            icon: Icons.bar_chart_outlined,
                            onTap: () => context.push('/stats'),
                          ),
                          _NotificationBell(
                            onTap: () => context.push('/notifications'),
                          ),
                          _HeaderIcon(
                            icon: Icons.settings_outlined,
                            onTap: () => context.push('/settings'),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              if (!_selectionMode) const DailyGoalBar(),
              SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    _FilterChip(
                      label: '全部類型',
                      selected: _typeFilter == null,
                      color: AppColors.textPrimary,
                      onTap: () => setState(() => _typeFilter = null),
                    ),
                    const SizedBox(width: 8),
                    CategoryChip(
                      category: ItemCategory.anime,
                      selected: _typeFilter == ItemCategory.anime,
                      onTap: () => setState(() => _typeFilter =
                          _typeFilter == ItemCategory.anime
                              ? null
                              : ItemCategory.anime),
                    ),
                    const SizedBox(width: 8),
                    CategoryChip(
                      category: ItemCategory.manga,
                      selected: _typeFilter == ItemCategory.manga,
                      onTap: () => setState(() => _typeFilter =
                          _typeFilter == ItemCategory.manga
                              ? null
                              : ItemCategory.manga),
                    ),
                    const SizedBox(width: 8),
                    CategoryChip(
                      category: ItemCategory.lightNovel,
                      selected: _typeFilter == ItemCategory.lightNovel,
                      onTap: () => setState(() => _typeFilter =
                          _typeFilter == ItemCategory.lightNovel
                              ? null
                              : ItemCategory.lightNovel),
                    ),
                    const SizedBox(width: 8),
                    CategoryChip(
                      category: ItemCategory.game,
                      selected: _typeFilter == ItemCategory.game,
                      onTap: () => setState(() => _typeFilter =
                          _typeFilter == ItemCategory.game
                              ? null
                              : ItemCategory.game),
                    ),
                  ],
                ),
              ),
              if (allTags.isNotEmpty) ...[
                const SizedBox(height: 4),
                SizedBox(
                  height: 34,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      _FilterChip(
                        label: '全部標籤',
                        selected: _tagFilter == null,
                        color: AppColors.textPrimary,
                        onTap: () => setState(() => _tagFilter = null),
                      ),
                      const SizedBox(width: 6),
                      _FilterChip(
                        label: '無標籤',
                        selected: _tagFilter != null && _tagFilter!.isEmpty,
                        color: AppColors.textMuted,
                        onTap: () => setState(() => _tagFilter = ''),
                      ),
                      for (final t in allTags) ...[
                        const SizedBox(width: 6),
                        _FilterChip(
                          label: t,
                          selected: _tagFilter == t,
                          color: AppColors.lightNovel,
                          onTap: () => setState(
                            () => _tagFilter = _tagFilter == t ? null : t,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 6),
              FolderChipBar(
                selectedFolderFilter: _folderFilter,
                onSelected: (v) => setState(() => _folderFilter = v),
                dropHighlightFolderId: _dropHighlightFolderId,
                onItemDropped: _dropIntoFolder,
                onDragEnterFolder: (id) =>
                    setState(() => _dropHighlightFolderId = id),
                onDragLeaveFolder: () =>
                    setState(() => _dropHighlightFolderId = null),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 6, 20, 0),
                child: Text(
                  _useMixedHome(sortMode)
                      ? '長按作品拖到資料夾 · 點「未分類」/資料夾後可拖動排序'
                      : (sortMode == HomeSortMode.manual
                          ? '長按拖曳排序 · 點 ⋮ 更多'
                          : '排序：${sortMode.label}（平面牆 · 切回「手動」可拖動）'),
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: _buildBody(
                  items: items,
                  folders: folders,
                  filtered: filtered,
                  layout: layout,
                  sortMode: sortMode,
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/search'),
        icon: const Icon(Icons.add),
        label: const Text('新增'),
        backgroundColor: AppColors.anime,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildBody({
    required List<Item> items,
    required List folders,
    required List<Item> filtered,
    required ({int Function(double width) columns, double aspectRatio}) layout,
    required HomeSortMode sortMode,
  }) {
    if (_useMixedHome(sortMode)) {
      final cells = buildHomeCells(
        allItems: items,
        folders: ref.read(foldersNotifierProvider),
        typeKey: _typeFilter?.storageKey,
      );
      if (cells.isEmpty) return _emptyState();
      return LayoutBuilder(
        builder: (context, constraints) {
          final cols = layout.columns(constraints.maxWidth);
          return GridView.builder(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 88),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: cols,
              childAspectRatio: layout.aspectRatio,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: cells.length,
            itemBuilder: (_, i) {
              final cell = cells[i];
              return switch (cell) {
                FolderHomeCell(
                  :final folder,
                  :final previewItems,
                  :final count
                ) =>
                  DragTarget<Item>(
                    onWillAcceptWithDetails: (d) {
                      setState(() => _dropHighlightFolderId = folder.id);
                      return d.data.folderId != folder.id;
                    },
                    onLeave: (_) {
                      if (_dropHighlightFolderId == folder.id) {
                        setState(() => _dropHighlightFolderId = null);
                      }
                    },
                    onAcceptWithDetails: (d) {
                      setState(() => _dropHighlightFolderId = null);
                      _dropIntoFolder(d.data, folder.id);
                    },
                    builder: (context, candidate, rejected) {
                      return FolderTile(
                        folder: folder,
                        previewItems: previewItems,
                        count: count,
                        isDropHighlight: candidate.isNotEmpty ||
                            _dropHighlightFolderId == folder.id,
                        onTap: () =>
                            setState(() => _folderFilter = folder.id),
                        onLongPress: () {
                          // folder chip bar already has actions; reuse open via filter
                        },
                      );
                    },
                  ),
                ItemHomeCell(:final item) => _draggableItemCard(item),
              };
            },
          );
        },
      );
    }

    if (filtered.isEmpty) return _emptyState();

    return LayoutBuilder(
      builder: (context, constraints) {
        final cols = layout.columns(constraints.maxWidth);
        if (_itemListReorder) {
          return ReorderableGridView.count(
            key: ValueKey(
              'reorder_${_folderFilter}_${filtered.map((e) => e.id).join(',')}',
            ),
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 88),
            crossAxisCount: cols,
            childAspectRatio: layout.aspectRatio,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            dragStartDelay: const Duration(milliseconds: 280),
            onReorder: (o, n) => _onReorder(o, n, filtered),
            children: [
              for (final item in filtered)
                _itemCard(
                  item,
                  key: ValueKey(item.id),
                  longPressOpensMenu: false,
                ),
            ],
          );
        }
        return GridView.builder(
          key: ValueKey(
            'grid_${sortMode.name}_${filtered.map((e) => e.id).join(',')}',
          ),
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 88),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: cols,
            childAspectRatio: layout.aspectRatio,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemCount: filtered.length,
          itemBuilder: (_, i) => sortMode == HomeSortMode.manual
              ? _draggableItemCard(filtered[i])
              : _itemCard(filtered[i], longPressOpensMenu: true),
        );
      },
    );
  }

  Widget _draggableItemCard(Item item) {
    if (_selectionMode) {
      return _itemCard(item, longPressOpensMenu: false);
    }
    return LongPressDraggable<Item>(
      data: item,
      delay: const Duration(milliseconds: 280),
      feedback: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(14),
        child: SizedBox(
          width: 100,
          height: 140,
          child: Opacity(
            opacity: 0.9,
            child: PosterCard(
              item: item,
              showIncrement: false,
            ),
          ),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.35,
        child: _itemCard(item, longPressOpensMenu: true),
      ),
      child: _itemCard(item, longPressOpensMenu: true),
    );
  }

  Widget _itemCard(
    Item item, {
    Key? key,
    required bool longPressOpensMenu,
  }) {
    if (_selectionMode) {
      final selected = _selectedIds.contains(item.id);
      return Stack(
        fit: StackFit.expand,
        children: [
          PosterCard(
            key: key,
            item: item,
            showIncrement: false,
            onTap: () => _toggleSelect(item.id),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: Icon(
              selected ? Icons.check_circle : Icons.circle_outlined,
              color: selected ? AppColors.success : Colors.white70,
            ),
          ),
        ],
      );
    }
    return PosterCard(
      key: key,
      item: item,
      onTap: () => context.push('/item/${item.id}'),
      onIncrement: () => _onIncrement(item),
      onMenu: () => _showItemMenu(item),
      longPressOpensMenu: longPressOpensMenu,
    );
  }

  Widget _emptyState() {
    final isFolderEmpty = _folderFilter != null;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isFolderEmpty
                ? Icons.folder_open_outlined
                : Icons.video_library_outlined,
            size: 64,
            color: Colors.white.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            isFolderEmpty ? '這個架子還是空的' : '架上還沒有作品',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.55),
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isFolderEmpty ? '把作品拖進資料夾，或用 ⋮ 移入' : '搜尋後放上第一張海報',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.35),
              fontSize: 13,
            ),
          ),
          if (isFolderEmpty) ...[
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => setState(() => _folderFilter = null),
              child: const Text('看全部'),
            ),
          ] else ...[
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: () => context.push('/search'),
              icon: const Icon(Icons.search),
              label: const Text('去搜尋'),
            ),
          ],
        ],
      ),
    );
  }
}

class _HeaderIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _HeaderIcon({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon, color: AppColors.textSecondary),
      onPressed: onTap,
    );
  }
}

class _NotificationBell extends ConsumerWidget {
  final VoidCallback onTap;

  const _NotificationBell({required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = ref.watch(unreadNotificationsCountProvider);
    return IconButton(
      onPressed: onTap,
      icon: Badge(
        isLabelVisible: unread > 0,
        label: Text(unread > 99 ? '99+' : '$unread'),
        child: const Icon(
          Icons.notifications_outlined,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? color.withValues(alpha: 0.3)
              : color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? color : color.withValues(alpha: 0.2),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : color.withValues(alpha: 0.8),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
