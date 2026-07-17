import 'package:flutter/material.dart';

import 'package:acg_todo/core/theme/app_colors.dart';
import 'package:acg_todo/core/theme/app_shadows.dart';
import 'package:acg_todo/core/theme/app_typography.dart';
import 'package:acg_todo/domain/entities/item.dart';
import 'package:acg_todo/domain/entities/pin_tier.dart';
import 'package:acg_todo/presentation/widgets/poster_card.dart';

/// Top home board: left 正在追 / right 優先追 (stacked on narrow).
class HomePriorityBoard extends StatelessWidget {
  final List<Item> watching;
  final List<Item> priority;
  final void Function(Item item) onTap;
  final void Function(Item item)? onMenu;
  final void Function(Item item)? onIncrement;
  final void Function(PinTier tier)? onTitleTap;
  final bool allowReorder;
  final void Function(PinTier tier, int oldIndex, int newIndex)? onReorder;

  const HomePriorityBoard({
    super.key,
    required this.watching,
    required this.priority,
    required this.onTap,
    this.onMenu,
    this.onIncrement,
    this.onTitleTap,
    this.allowReorder = false,
    this.onReorder,
  });

  /// Strip density: full-bleed art; slightly taller so overlay controls stay clear.
  static ({double w, double h}) cardSizeFor(double laneWidth) {
    if (laneWidth < 360) {
      return (w: 84, h: 136);
    }
    if (laneWidth < 520) {
      return (w: 92, h: 148);
    }
    return (w: 104, h: 168);
  }

  @override
  Widget build(BuildContext context) {
    if (watching.isEmpty && priority.isEmpty) {
      return const SizedBox.shrink();
    }

    return LayoutBuilder(
      builder: (context, c) {
        final sideBySide = c.maxWidth >= 640;
        // Outer LayoutBuilder only — never nest LayoutBuilder inside IntrinsicHeight.
        final contentWidth = c.maxWidth.isFinite ? c.maxWidth : 360.0;
        final laneWidth = sideBySide
            ? (contentWidth - 32 - 12) / 2
            : contentWidth - 32;
        final cardSize = cardSizeFor(laneWidth.clamp(0, double.infinity));

        final watchingLane = _PinLane(
          tier: PinTier.watching,
          title: '正在追',
          accent: AppColors.anime,
          items: watching,
          cardSize: cardSize,
          onTap: onTap,
          onMenu: onMenu,
          onIncrement: onIncrement,
          onTitleTap: onTitleTap,
          allowReorder: allowReorder,
          onReorder: onReorder,
        );
        final priorityLane = _PinLane(
          tier: PinTier.priority,
          title: '優先追',
          accent: AppColors.lightNovel,
          items: priority,
          cardSize: cardSize,
          onTap: onTap,
          onMenu: onMenu,
          onIncrement: onIncrement,
          onTitleTap: onTitleTap,
          allowReorder: allowReorder,
          onReorder: onReorder,
        );

        if (sideBySide) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 2, 16, 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: watchingLane),
                const SizedBox(width: 8),
                Expanded(child: priorityLane),
              ],
            ),
          );
        }
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 2, 16, 6),
          child: Column(
            children: [
              watchingLane,
              const SizedBox(height: 6),
              priorityLane,
            ],
          ),
        );
      },
    );
  }
}

class _PinLane extends StatelessWidget {
  final PinTier tier;
  final String title;
  final Color accent;
  final List<Item> items;
  final ({double w, double h}) cardSize;
  final void Function(Item item) onTap;
  final void Function(Item item)? onMenu;
  final void Function(Item item)? onIncrement;
  final void Function(PinTier tier)? onTitleTap;
  final bool allowReorder;
  final void Function(PinTier tier, int oldIndex, int newIndex)? onReorder;

  const _PinLane({
    required this.tier,
    required this.title,
    required this.accent,
    required this.items,
    required this.cardSize,
    required this.onTap,
    this.onMenu,
    this.onIncrement,
    this.onTitleTap,
    this.allowReorder = false,
    this.onReorder,
  });

  static const double _gripWidth = 18;
  static const double _gripIconSize = 16;
  static const double _itemGap = 6;
  static const double _padTop = 6;
  static const double _padBottom = 6;
  static const double _titleBlock = 20;
  static const double _titleGap = 6;

  double get _laneHeight {
    if (items.isEmpty) {
      return _padTop + _titleBlock + _titleGap + 48 + _padBottom;
    }
    return _padTop + _titleBlock + _titleGap + cardSize.h + _padBottom;
  }

  @override
  Widget build(BuildContext context) {
    final reorder = allowReorder && onReorder != null;

    // Explicit height — no IntrinsicHeight + LayoutBuilder (intrinsic height = 0).
    return SizedBox(
      height: _laneHeight,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.paperElevated,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.borderSubtle),
          boxShadow: AppShadows.soft,
        ),
        clipBehavior: Clip.antiAlias,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 3, color: accent),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, _padTop, 8, _padBottom),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: _titleBlock,
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: items.isEmpty
                              ? null
                              : () => onTitleTap?.call(tier),
                          borderRadius: BorderRadius.circular(8),
                          child: Row(
                            children: [
                              Text(
                                title,
                                style: AppTypography.caption.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: accent,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '${items.length}',
                                style: AppTypography.caption.copyWith(
                                  color: AppColors.inkSecondary,
                                ),
                              ),
                              if (items.isNotEmpty && onTitleTap != null) ...[
                                const SizedBox(width: 2),
                                Icon(
                                  Icons.chevron_right,
                                  size: 18,
                                  color: accent.withValues(alpha: 0.85),
                                ),
                              ],
                              if (reorder && items.length > 1) ...[
                                const Spacer(),
                                Text(
                                  '右側拖排序',
                                  style: AppTypography.micro.copyWith(
                                    color: AppColors.inkMuted,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: _titleGap),
                    if (items.isEmpty)
                      Expanded(
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            '⋮ 釘選到$title',
                            style: AppTypography.caption.copyWith(
                              color: AppColors.inkMuted,
                            ),
                          ),
                        ),
                      )
                    else
                      SizedBox(
                        height: cardSize.h,
                        child: reorder
                            ? ReorderableListView.builder(
                                scrollDirection: Axis.horizontal,
                                buildDefaultDragHandles: false,
                                physics: const BouncingScrollPhysics(
                                  parent: AlwaysScrollableScrollPhysics(),
                                ),
                                padding: const EdgeInsets.only(right: 20),
                                proxyDecorator: (child, index, animation) {
                                  return AnimatedBuilder(
                                    animation: animation,
                                    builder: (context, _) {
                                      final t = Curves.easeInOut
                                          .transform(animation.value);
                                      return Material(
                                        elevation: 2 + 6 * t,
                                        color: Colors.transparent,
                                        borderRadius:
                                            BorderRadius.circular(16),
                                        child: child,
                                      );
                                    },
                                  );
                                },
                                onReorder: (o, n) {
                                  var newIndex = n;
                                  if (o < newIndex) newIndex -= 1;
                                  onReorder!(tier, o, newIndex);
                                },
                                itemCount: items.length,
                                itemBuilder: (context, i) {
                                  final item = items[i];
                                  return _reorderableCard(
                                    item,
                                    index: i,
                                    key: ValueKey(
                                      'pin_${tier.name}_${item.id}',
                                    ),
                                  );
                                },
                              )
                            : ListView.separated(
                                scrollDirection: Axis.horizontal,
                                physics: const BouncingScrollPhysics(
                                  parent: AlwaysScrollableScrollPhysics(),
                                ),
                                padding: const EdgeInsets.only(right: 20),
                                itemCount: items.length,
                                separatorBuilder: (_, _) =>
                                    const SizedBox(width: 10),
                                itemBuilder: (context, i) => _card(items[i]),
                              ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _card(Item item, {Key? key}) {
    return SizedBox(
      key: key,
      width: cardSize.w,
      height: cardSize.h,
      child: PosterCard(
        item: item,
        density: PosterCardDensity.strip,
        heroTag: '',
        onTap: () => onTap(item),
        onMenu: onMenu != null ? () => onMenu!(item) : null,
        onIncrement: onIncrement != null ? () => onIncrement!(item) : null,
        showIncrement: onIncrement != null,
        longPressOpensMenu: !allowReorder,
      ),
    );
  }

  Widget _reorderableCard(
    Item item, {
    required int index,
    required Key key,
  }) {
    return Padding(
      key: key,
      padding: const EdgeInsets.only(right: _itemGap),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: cardSize.w,
            height: cardSize.h,
            child: PosterCard(
              item: item,
              density: PosterCardDensity.strip,
              heroTag: '',
              onTap: () => onTap(item),
              onMenu: onMenu != null ? () => onMenu!(item) : null,
              onIncrement:
                  onIncrement != null ? () => onIncrement!(item) : null,
              showIncrement: onIncrement != null,
              longPressOpensMenu: false,
            ),
          ),
          ReorderableDragStartListener(
            index: index,
            child: SizedBox(
              width: _gripWidth,
              child: Icon(
                Icons.drag_indicator,
                size: _gripIconSize,
                color: AppColors.inkMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
