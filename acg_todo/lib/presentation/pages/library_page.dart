import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:reorderable_grid_view/reorderable_grid_view.dart';

import 'package:acg_todo/core/theme/app_colors.dart';
import 'package:acg_todo/core/theme/app_scaffold.dart';
import 'package:acg_todo/core/theme/app_shadows.dart';
import 'package:acg_todo/core/theme/app_typography.dart';
import 'package:acg_todo/presentation/widgets/paper_filter_chip.dart';
import 'package:acg_todo/domain/entities/item.dart';
import 'package:acg_todo/domain/entities/item_category.dart';
import 'package:acg_todo/domain/entities/pin_tier.dart';
import 'package:acg_todo/domain/services/item_sort_service.dart';
import 'package:acg_todo/presentation/home/home_item_query.dart';
import 'package:acg_todo/presentation/home/home_layout.dart';
import 'package:acg_todo/presentation/providers/daily_goal_provider.dart';
import 'package:acg_todo/presentation/providers/folders_provider.dart';
import 'package:acg_todo/presentation/providers/items_provider.dart';
import 'package:acg_todo/presentation/providers/repository_providers.dart';
import 'package:acg_todo/presentation/widgets/category_chip.dart';
import 'package:acg_todo/presentation/widgets/deadline_editor_sheet.dart';
import 'package:acg_todo/presentation/widgets/edit_total_units_dialog.dart';
import 'package:acg_todo/presentation/widgets/folder_chip_bar.dart';
import 'package:acg_todo/presentation/widgets/folder_tile.dart';
import 'package:acg_todo/presentation/widgets/item_editor_sheet.dart';
import 'package:acg_todo/presentation/widgets/move_to_folder_sheet.dart';
import 'package:acg_todo/presentation/widgets/poster_card.dart';
import 'package:acg_todo/presentation/widgets/user_score_editor.dart';

/// Full poster wall: filters, sort, multi-select, FAB.
class LibraryPage extends ConsumerStatefulWidget {
  const LibraryPage({super.key});

  @override
  ConsumerState<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends ConsumerState<LibraryPage> {
  ItemCategory? _typeFilter;
  String? _folderFilter;
  /// Last route `folder` query we applied (avoids fighting chip ↔ URL).
  String? _lastRouteFolderQuery;
  /// null = all tags; '' = no tags; else tag name
  String? _tagFilter;
  String? _dropHighlightFolderId;
  bool _selectionMode = false;
  final Set<String> _selectedIds = {};
  bool _searchOpen = false;
  final _searchController = TextEditingController();
  final _searchFocus = FocusNode();

  HomeSortMode get _sortMode =>
      ref.read(goalSettingsStoreProvider).homeSortMode;

  String get _searchQuery => _searchController.text;

  bool get _hasSearch => _searchQuery.trim().isNotEmpty;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncFolderFromRoute();
  }

  void _syncFolderFromRoute() {
    final raw = GoRouterState.of(context).uri.queryParameters['folder'];
    if (raw == _lastRouteFolderQuery) return;
    _lastRouteFolderQuery = raw;
    final parsed = parseLibraryFolderQuery(raw);
    if (parsed != _folderFilter) {
      setState(() => _folderFilter = parsed);
    }
  }

  void _setFolderFilter(String? value) {
    setState(() => _folderFilter = value);
    final param = libraryFolderQueryParam(value);
    _lastRouteFolderQuery = param;
    if (!mounted) return;
    context.go(libraryLocationForFolder(value));
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  List<Item> _filterItems(
    List<Item> items,
    HomeSortMode sortMode, {
    bool sortAscending = false,
  }) {
    return filterAndSortHomeItems(
      items: items,
      sortMode: sortMode,
      sortAscending: sortAscending,
      typeKey: _typeFilter?.storageKey,
      folderFilter: _folderFilter,
      tagFilter: _tagFilter,
      searchQuery: _searchQuery,
    );
  }

  void _openSearch() {
    setState(() => _searchOpen = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _searchFocus.requestFocus();
    });
  }

  void _closeSearch() {
    setState(() {
      _searchOpen = false;
      _searchController.clear();
    });
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

  /// Reorder only in manual sort + folder/uncategorized + no search.
  bool get _itemListReorder =>
      _sortMode == HomeSortMode.manual &&
      _folderFilter != null &&
      !_hasSearch;

  /// Mixed folder tiles: only "全部" + 手動 + 無搜尋.
  bool _useMixedHome(HomeSortMode sortMode) => useMixedHomeLayout(
        folderFilter: _folderFilter,
        sortMode: sortMode,
        searchQuery: _searchQuery,
      );

  Future<void> _onReorder(
    int oldIndex,
    int newIndex,
    List<Item> filtered,
  ) async {
    if (oldIndex == newIndex) return;
    final list = List<Item>.from(filtered);
    if (oldIndex >= list.length) return;
    final item = list.removeAt(oldIndex);
    final insertAt = newIndex.clamp(0, list.length);
    list.insert(insertAt, item);
    await ref.read(itemsNotifierProvider.notifier).reorderVisibleItems(list);
  }

  Future<void> _setPinTier(Item item, PinTier tier) async {
    await ref.read(itemsNotifierProvider.notifier).setPinTier(item.id, tier);
    if (!mounted) return;
    final msg = switch (tier) {
      PinTier.watching => '已釘選到正在追',
      PinTier.priority => '已釘選到優先追',
      PinTier.none => '已取消置頂',
    };
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        duration: const Duration(milliseconds: 900),
        behavior: SnackBarBehavior.floating,
      ),
    );
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
      backgroundColor: AppColors.paperElevated,
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
                leading: Icon(
                  Icons.local_fire_department,
                  color: item.pinTier == PinTier.watching
                      ? AppColors.anime
                      : null,
                ),
                title: Text(
                  item.pinTier == PinTier.watching
                      ? '✓ 正在追'
                      : '釘選到正在追',
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _setPinTier(
                    item,
                    item.pinTier == PinTier.watching
                        ? PinTier.none
                        : PinTier.watching,
                  );
                },
              ),
              ListTile(
                leading: Icon(
                  Icons.star,
                  color: item.pinTier == PinTier.priority
                      ? AppColors.lightNovel
                      : null,
                ),
                title: Text(
                  item.pinTier == PinTier.priority
                      ? '✓ 優先追'
                      : '釘選到優先追',
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _setPinTier(
                    item,
                    item.pinTier == PinTier.priority
                        ? PinTier.none
                        : PinTier.priority,
                  );
                },
              ),
              if (item.isPinned)
                ListTile(
                  leading: const Icon(Icons.push_pin_outlined),
                  title: const Text('取消置頂'),
                  onTap: () {
                    Navigator.pop(ctx);
                    _setPinTier(item, PinTier.none);
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

  Future<void> _setSortAscending(bool ascending) async {
    await ref.read(goalSettingsStoreProvider).setHomeSortAscending(ascending);
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
    final sortAscending = store.homeSortAscending;
    final layout = homeGridLayout(density);
    final filtered = _filterItems(
      items,
      sortMode,
      sortAscending: sortAscending,
    );
    // Library shows all filtered items (pins included; board lives on dashboard).
    final gridItems = filtered;
    final allTags = ref.read(itemsRepositoryProvider).allTags();

    return AppScaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 8, 2),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _selectionMode
                          ? '已選 ${_selectedIds.length}'
                          : '媒體庫',
                      style: AppTypography.display.copyWith(
                        fontSize: _selectionMode ? 20 : 24,
                      ),
                    ),
                  ),
                  if (_selectionMode) ...[
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
                              ? AppColors.inkMuted
                              : AppColors.danger,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ] else ...[
                    _HeaderIcon(
                      icon: _searchOpen || _hasSearch
                          ? Icons.search_off
                          : Icons.search,
                      onTap: () {
                        if (_searchOpen || _hasSearch) {
                          _closeSearch();
                        } else {
                          _openSearch();
                        }
                      },
                    ),
                    PopupMenuButton<String>(
                      tooltip: '更多',
                      icon: const Icon(
                        Icons.more_horiz,
                        color: AppColors.inkSecondary,
                      ),
                      onSelected: (value) {
                        if (value.startsWith('sort:')) {
                          final name = value.substring(5);
                          final mode = HomeSortMode.values.firstWhere(
                            (m) => m.name == name,
                            orElse: () => HomeSortMode.manual,
                          );
                          _setSortMode(mode);
                          return;
                        }
                        switch (value) {
                          case 'dir:asc':
                            _setSortAscending(true);
                          case 'dir:desc':
                            _setSortAscending(false);
                          case 'select':
                            setState(() => _selectionMode = true);
                          case 'stats':
                            context.push('/stats');
                        }
                      },
                      itemBuilder: (ctx) {
                        final dirLabel = sortMode == HomeSortMode.manual
                            ? '手動'
                            : (sortAscending ? '升序' : '降序');
                        return [
                          PopupMenuItem(
                            enabled: false,
                            child: Text(
                              '排序 · ${sortMode.label} · $dirLabel',
                              style: AppTypography.micro,
                            ),
                          ),
                          for (final m in HomeSortMode.values)
                            PopupMenuItem(
                              value: 'sort:${m.name}',
                              child: Text(
                                m == sortMode ? '✓ ${m.label}' : m.label,
                              ),
                            ),
                          const PopupMenuDivider(),
                          PopupMenuItem(
                            value: 'dir:desc',
                            enabled: sortMode != HomeSortMode.manual,
                            child: Text(
                              !sortAscending &&
                                      sortMode != HomeSortMode.manual
                                  ? '✓ 降序'
                                  : '降序',
                            ),
                          ),
                          PopupMenuItem(
                            value: 'dir:asc',
                            enabled: sortMode != HomeSortMode.manual,
                            child: Text(
                              sortAscending &&
                                      sortMode != HomeSortMode.manual
                                  ? '✓ 升序'
                                  : '升序',
                            ),
                          ),
                          const PopupMenuDivider(),
                          const PopupMenuItem(
                            value: 'select',
                            child: Text('選擇'),
                          ),
                          const PopupMenuItem(
                            value: 'stats',
                            child: Text('統計'),
                          ),
                        ];
                      },
                    ),
                  ],
                ],
              ),
            ),
            Expanded(
              child: NestedScrollView(
                headerSliverBuilder: (context, innerBoxIsScrolled) {
                  return [
                    if (!_selectionMode && (_searchOpen || _hasSearch))
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                          child: TextField(
                            controller: _searchController,
                            focusNode: _searchFocus,
                            onChanged: (_) => setState(() {}),
                            textInputAction: TextInputAction.search,
                            decoration: InputDecoration(
                              hintText: '搜尋架上作品…',
                              isDense: true,
                              filled: true,
                              fillColor: AppColors.paperElevated,
                              prefixIcon: const Icon(Icons.search, size: 20),
                              suffixIcon: _hasSearch
                                  ? IconButton(
                                      icon: const Icon(Icons.clear, size: 18),
                                      onPressed: () {
                                        _searchController.clear();
                                        setState(() {});
                                      },
                                    )
                                  : IconButton(
                                      icon: const Icon(Icons.close, size: 18),
                                      onPressed: _closeSearch,
                                    ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ),
                      ),
                    SliverToBoxAdapter(
                      child: SizedBox(
                        height: 36,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          children: [
                            PaperFilterChip(
                              label: '全部',
                              selected: _typeFilter == null,
                              accent: AppColors.inkPrimary,
                              onTap: () =>
                                  setState(() => _typeFilter = null),
                            ),
                            const SizedBox(width: 6),
                            CategoryChip(
                              category: ItemCategory.anime,
                              selected: _typeFilter == ItemCategory.anime,
                              onTap: () => setState(() => _typeFilter =
                                  _typeFilter == ItemCategory.anime
                                      ? null
                                      : ItemCategory.anime),
                            ),
                            const SizedBox(width: 6),
                            CategoryChip(
                              category: ItemCategory.manga,
                              selected: _typeFilter == ItemCategory.manga,
                              onTap: () => setState(() => _typeFilter =
                                  _typeFilter == ItemCategory.manga
                                      ? null
                                      : ItemCategory.manga),
                            ),
                            const SizedBox(width: 6),
                            CategoryChip(
                              category: ItemCategory.lightNovel,
                              selected:
                                  _typeFilter == ItemCategory.lightNovel,
                              onTap: () => setState(() => _typeFilter =
                                  _typeFilter == ItemCategory.lightNovel
                                      ? null
                                      : ItemCategory.lightNovel),
                            ),
                            const SizedBox(width: 6),
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
                    ),
                    if (allTags.isNotEmpty)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: SizedBox(
                            height: 32,
                            child: ListView(
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              children: [
                                PaperFilterChip(
                                  label: '全部標籤',
                                  selected: _tagFilter == null,
                                  accent: AppColors.inkPrimary,
                                  onTap: () =>
                                      setState(() => _tagFilter = null),
                                ),
                                const SizedBox(width: 6),
                                PaperFilterChip(
                                  label: '無標籤',
                                  selected: _tagFilter != null &&
                                      _tagFilter!.isEmpty,
                                  accent: AppColors.inkMuted,
                                  onTap: () =>
                                      setState(() => _tagFilter = ''),
                                ),
                                for (final t in allTags) ...[
                                  const SizedBox(width: 6),
                                  PaperFilterChip(
                                    label: t,
                                    selected: _tagFilter == t,
                                    accent: AppColors.lightNovel,
                                    onTap: () => setState(
                                      () => _tagFilter =
                                          _tagFilter == t ? null : t,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 4, bottom: 4),
                        child: FolderChipBar(
                          selectedFolderFilter: _folderFilter,
                          onSelected: _setFolderFilter,
                          dropHighlightFolderId: _dropHighlightFolderId,
                          onItemDropped: _dropIntoFolder,
                          onDragEnterFolder: (id) => setState(
                            () => _dropHighlightFolderId = id,
                          ),
                          onDragLeaveFolder: () => setState(
                            () => _dropHighlightFolderId = null,
                          ),
                        ),
                      ),
                    ),
                    if (_hasSearch)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
                          child: Text(
                            '搜尋「${_searchQuery.trim()}」· ${filtered.length} 筆',
                            style: AppTypography.micro.copyWith(
                              color: AppColors.inkMuted,
                            ),
                          ),
                        ),
                      ),
                  ];
                },
                body: _buildBody(
                  items: items,
                  folders: folders,
                  filtered: gridItems,
                  layout: layout,
                  sortMode: sortMode,
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          boxShadow: AppShadows.fab,
        ),
        child: FloatingActionButton.extended(
          onPressed: () => context.push('/search'),
          icon: const Icon(Icons.add),
          label: const Text('加入架上'),
          backgroundColor: AppColors.anime,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
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
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 96),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: cols,
              childAspectRatio: layout.aspectRatio,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
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
                            _setFolderFilter(folder.id),
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
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 96),
            crossAxisCount: cols,
            childAspectRatio: layout.aspectRatio,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
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
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 96),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: cols,
            childAspectRatio: layout.aspectRatio,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
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
              density: PosterCardDensity.poster,
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
            density: PosterCardDensity.poster,
            selected: selected,
            showIncrement: false,
            onTap: () => _toggleSelect(item.id),
          ),
          Positioned(
            top: 8,
            left: 8,
            child: Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: selected
                    ? AppColors.success
                    : AppColors.paperElevated.withValues(alpha: 0.94),
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected
                      ? AppColors.success
                      : AppColors.borderSubtle,
                  width: 1.5,
                ),
                boxShadow: AppShadows.soft,
              ),
              child: Icon(
                selected ? Icons.check : Icons.circle_outlined,
                size: 16,
                color: selected ? Colors.white : AppColors.inkMuted,
              ),
            ),
          ),
        ],
      );
    }
    return PosterCard(
      key: key,
      item: item,
      density: PosterCardDensity.poster,
      onTap: () => context.push('/item/${item.id}'),
      onIncrement: () => _onIncrement(item),
      onMenu: () => _showItemMenu(item),
      longPressOpensMenu: longPressOpensMenu,
    );
  }

  Widget _emptyState() {
    if (_hasSearch) {
      final q = _searchQuery.trim();
      return Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 300),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.search_off,
                  size: 56,
                  color: AppColors.inkMuted,
                ),
                const SizedBox(height: 16),
                Text(
                  '沒有符合「$q」的作品',
                  textAlign: TextAlign.center,
                  style: AppTypography.title.copyWith(fontSize: 17),
                ),
                const SizedBox(height: 8),
                Text(
                  '試試其他關鍵字，或清除篩選',
                  textAlign: TextAlign.center,
                  style: AppTypography.caption,
                ),
                const SizedBox(height: 20),
                OutlinedButton(
                  onPressed: _closeSearch,
                  child: const Text('清除搜尋'),
                ),
                const SizedBox(height: 8),
                FilledButton.icon(
                  onPressed: () => context.push('/search'),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('去新增'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final isFolderEmpty = _folderFilter != null;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 300),
        child: Container(
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
          decoration: BoxDecoration(
            color: AppColors.paperElevated,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.borderSubtle),
            boxShadow: AppShadows.soft,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isFolderEmpty
                    ? Icons.folder_open_outlined
                    : Icons.video_library_outlined,
                size: 56,
                color: AppColors.inkMuted,
              ),
              const SizedBox(height: 16),
              Text(
                isFolderEmpty ? '這個架子還是空的' : '架上還沒有作品',
                textAlign: TextAlign.center,
                style: AppTypography.title.copyWith(fontSize: 17),
              ),
              const SizedBox(height: 8),
              Text(
                isFolderEmpty
                    ? '把作品拖進資料夾，或用 ⋮ 移入'
                    : '搜尋後放上第一張海報',
                textAlign: TextAlign.center,
                style: AppTypography.caption,
              ),
              const SizedBox(height: 20),
              if (isFolderEmpty)
                OutlinedButton(
                  onPressed: () => _setFolderFilter(null),
                  child: const Text('看全部'),
                )
              else
                FilledButton.icon(
                  onPressed: () => context.push('/search'),
                  icon: const Icon(Icons.search, size: 18),
                  label: const Text('去搜尋新增'),
                ),
            ],
          ),
        ),
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


