import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:acg_todo/core/theme/app_colors.dart';
import 'package:acg_todo/core/theme/app_shadows.dart';
import 'package:acg_todo/core/theme/app_typography.dart';
import 'package:acg_todo/core/utils/item_display.dart';
import 'package:acg_todo/core/utils/score_utils.dart';
import 'package:acg_todo/domain/entities/item.dart';
import 'package:acg_todo/domain/entities/pin_tier.dart';
import 'package:acg_todo/presentation/home/continue_item_badges.dart';
import 'package:acg_todo/presentation/providers/daily_goal_provider.dart';
import 'package:acg_todo/presentation/providers/repository_providers.dart';
import 'package:acg_todo/presentation/widgets/deadline_badge.dart';
import 'package:acg_todo/presentation/widgets/poster_image_widget.dart';

/// Layout density for [PosterCard].
enum PosterCardDensity {
  /// Full magazine: image + paper meta footer.
  magazine,

  /// Pin strip: full-bleed image; progress + + overlay on art.
  strip,

  /// Library wall: almost full poster; title/progress on bottom gradient.
  poster,
}

/// Magazine-style poster card: image on top, paper meta below.
class PosterCard extends ConsumerStatefulWidget {
  final Item item;
  final VoidCallback? onTap;
  final VoidCallback? onIncrement;
  final VoidCallback? onMenu;
  final bool showIncrement;
  final bool longPressOpensMenu;
  final bool selected;

  /// null → [item.id] (detail); empty → no Hero; else custom tag.
  final String? heroTag;
  final PosterCardDensity density;

  /// null → read [GoalSettingsStore.titleSimpToTrad]; set in tests to avoid Hive.
  final bool? titleSimpToTrad;

  /// Strip: show「久未動」pill (caller decides via [ContinueItemBadges]).
  final bool showStale;

  /// Strip: left accent for deadline risk (null = none).
  final ContinueRisk? continueRisk;

  const PosterCard({
    super.key,
    required this.item,
    this.onTap,
    this.onIncrement,
    this.onMenu,
    this.showIncrement = true,
    this.longPressOpensMenu = true,
    this.selected = false,
    this.heroTag,
    this.density = PosterCardDensity.magazine,
    this.titleSimpToTrad,
    this.showStale = false,
    this.continueRisk,
  });

  @override
  ConsumerState<PosterCard> createState() => _PosterCardState();
}

class _PosterCardState extends ConsumerState<PosterCard> {
  bool _pressed = false;

  Item get item => widget.item;

  bool get _isStrip => widget.density == PosterCardDensity.strip;
  bool get _isPoster => widget.density == PosterCardDensity.poster;

  Widget _buildPosterHero() {
    final image = PosterImageWidget(
      key: ValueKey('poster_${item.id}'),
      posterUrl: item.posterUrl,
      type: item.type,
      fit: BoxFit.cover,
    );
    final tag = widget.heroTag;
    if (tag != null && tag.isEmpty) return image;
    return Hero(
      tag: tag ?? item.id,
      child: image,
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool s2t;
    if (widget.titleSimpToTrad != null) {
      s2t = widget.titleSimpToTrad!;
    } else {
      ref.watch(dailyGoalTickProvider);
      s2t = ref.watch(goalSettingsStoreProvider).titleSimpToTrad;
    }
    final shownTitle = displayTitle(item.title, simpToTrad: s2t);
    final color = AppColors.getTypeColor(item.type);
    final progress = item.totalUnits != null && item.totalUnits! > 0
        ? (item.currentUnits / item.totalUnits!).clamp(0.0, 1.0)
        : 0.0;
    // Tighter corners keep more of the poster art visible.
    final radius = _isStrip
        ? 10.0
        : _isPoster
            ? 8.0
            : 12.0;

    final riskColor = switch (widget.continueRisk) {
      ContinueRisk.overdue => AppColors.danger,
      ContinueRisk.atRisk => AppColors.warning,
      null => null,
    };
    final borderColor = widget.selected
        ? AppColors.anime
        : (riskColor ?? AppColors.borderSubtle);
    final borderWidth = widget.selected
        ? 2.0
        : (riskColor != null ? 1.5 : 1.0);

    return AnimatedScale(
      scale: _pressed ? 0.97 : 1.0,
      duration: const Duration(milliseconds: 160),
      curve: Curves.easeOut,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          onLongPress: widget.longPressOpensMenu ? widget.onMenu : null,
          onHighlightChanged: (v) => setState(() => _pressed = v),
          borderRadius: BorderRadius.circular(radius),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(radius),
              color: AppColors.paperElevated,
              border: Border.all(
                color: borderColor,
                width: borderWidth,
              ),
              boxShadow: AppShadows.card,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(radius),
              child: _isStrip
                  ? _buildStripBody(color, progress, riskColor)
                  : _isPoster
                      ? _buildPosterBody(color, progress, shownTitle)
                      : _buildMagazineBody(color, progress, shownTitle),
            ),
          ),
        ),
      ),
    );
  }

  /// Full-bleed cover with meta on a bottom gradient (library wall).
  Widget _buildPosterBody(
    Color color,
    double progress,
    String shownTitle,
  ) {
    final progressLabel =
        '${item.currentUnits}/${item.totalUnits ?? '?'} ${item.unitLabel}';
    final showPlus = widget.showIncrement && widget.onIncrement != null;

    return Stack(
      fit: StackFit.expand,
      children: [
        _buildPosterHero(),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: 72,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.75),
                ],
              ),
            ),
          ),
        ),
        if (item.deadline != null)
          Positioned(
            top: 8,
            right: 8,
            child: DeadlineBadge(deadline: item.deadline!),
          ),
        if (item.isPinned)
          Positioned(
            top: 8,
            left: widget.onMenu != null ? 40 : 8,
            child: _PaperPill(
              background: (item.pinTier == PinTier.priority
                      ? AppColors.lightNovel
                      : AppColors.anime)
                  .withValues(alpha: 0.92),
              child: Text(
                item.pinTier.shortBadge,
                style: AppTypography.micro.copyWith(color: Colors.white),
              ),
            ),
          ),
        if (widget.onMenu != null)
          Positioned(
            top: 6,
            left: 6,
            child: Material(
              color: AppColors.paperElevated.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(8),
              child: InkWell(
                onTap: widget.onMenu,
                borderRadius: BorderRadius.circular(8),
                child: const SizedBox(
                  width: 28,
                  height: 28,
                  child: Icon(
                    Icons.more_vert,
                    size: 16,
                    color: AppColors.inkSecondary,
                  ),
                ),
              ),
            ),
          ),
        if (item.userScore != null || item.score != null)
          Positioned(
            top: item.deadline != null ? 36 : 8,
            right: 8,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (item.userScore != null)
                  _PaperPill(
                    margin: const EdgeInsets.only(bottom: 4),
                    background:
                        AppColors.lightNovel.withValues(alpha: 0.92),
                    child: Text(
                      '我 ${formatUserScore(item.userScore!)}',
                      style:
                          AppTypography.micro.copyWith(color: Colors.white),
                    ),
                  ),
                if (item.score != null)
                  _PaperPill(
                    child: Text(
                      '★ ${item.score!.toStringAsFixed(1)}',
                      style: AppTypography.micro.copyWith(
                        color: AppColors.lightNovel,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        Positioned(
          left: 8,
          right: 8,
          bottom: 8,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                shownTitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.cardTitle.copyWith(
                  color: Colors.white,
                  fontSize: 13,
                  shadows: const [
                    Shadow(blurRadius: 6, color: Colors.black54),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 3,
                  backgroundColor: Colors.white.withValues(alpha: 0.25),
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      progressLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (showPlus)
                    _PlusButton(
                      color: color,
                      onPressed: widget.onIncrement!,
                      size: 26,
                      iconSize: 16,
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Full-bleed poster; progress + + sit on the art (readable on short cards).
  Widget _buildStripBody(Color color, double progress, Color? riskColor) {
    final progressLabel =
        '${item.currentUnits}/${item.totalUnits ?? '?'} ${item.unitLabel}';
    final showPlus = widget.showIncrement && widget.onIncrement != null;
    final pinLeft = widget.onMenu != null ? 32.0 : 4.0;

    return Stack(
      fit: StackFit.expand,
      children: [
        _buildPosterHero(),
        // Bottom gradient for contrast
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: 56,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0),
                  Colors.black.withValues(alpha: 0.72),
                ],
              ),
            ),
          ),
        ),
        if (riskColor != null)
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: 3,
            child: ColoredBox(color: riskColor),
          ),
        if (widget.onMenu != null)
          Positioned(
            top: 4,
            left: 4,
            child: _StripIconButton(
              icon: Icons.more_vert,
              onTap: widget.onMenu!,
            ),
          ),
        if (item.isPinned)
          Positioned(
            top: 4,
            left: pinLeft,
            child: _PaperPill(
              background: (item.pinTier == PinTier.priority
                      ? AppColors.lightNovel
                      : AppColors.anime)
                  .withValues(alpha: 0.92),
              child: Text(
                item.pinTier.shortBadge,
                style: AppTypography.micro.copyWith(color: Colors.white),
              ),
            ),
          ),
        if (item.deadline != null)
          Positioned(
            top: 4,
            right: 4,
            child: DeadlineBadge(deadline: item.deadline!),
          ),
        if (widget.showStale)
          Positioned(
            top: item.deadline != null ? 28 : 4,
            right: 4,
            child: _PaperPill(
              background: AppColors.warning.withValues(alpha: 0.92),
              child: Text(
                '久未動',
                style: AppTypography.micro.copyWith(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        Positioned(
          left: 6,
          right: 6,
          bottom: 6,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 3,
                  backgroundColor: Colors.white.withValues(alpha: 0.25),
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      progressLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        height: 1.1,
                        shadows: [
                          Shadow(blurRadius: 4, color: Colors.black54),
                        ],
                      ),
                    ),
                  ),
                  if (showPlus)
                    _PlusButton(
                      color: color,
                      onPressed: widget.onIncrement!,
                      size: 24,
                      iconSize: 16,
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMagazineBody(
    Color color,
    double progress,
    String shownTitle,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          flex: 72,
          child: Stack(
            fit: StackFit.expand,
            children: [
              _buildPosterHero(),
              if (item.deadline != null)
                Positioned(
                  top: 8,
                  right: 8,
                  child: DeadlineBadge(deadline: item.deadline!),
                ),
              if (item.userScore != null || item.score != null)
                Positioned(
                  top: item.deadline != null ? 36 : 8,
                  right: 8,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (item.userScore != null)
                        _PaperPill(
                          margin: const EdgeInsets.only(bottom: 4),
                          background:
                              AppColors.lightNovel.withValues(alpha: 0.92),
                          child: Text(
                            '我 ${formatUserScore(item.userScore!)}',
                            style: AppTypography.micro
                                .copyWith(color: Colors.white),
                          ),
                        ),
                      if (item.score != null)
                        _PaperPill(
                          child: Text(
                            '★ ${item.score!.toStringAsFixed(1)}',
                            style: AppTypography.micro.copyWith(
                              color: AppColors.lightNovel,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              if (item.isPinned)
                Positioned(
                  top: 8,
                  left: widget.onMenu != null ? 40 : 8,
                  child: _PaperPill(
                    background: (item.pinTier == PinTier.priority
                            ? AppColors.lightNovel
                            : AppColors.anime)
                        .withValues(alpha: 0.92),
                    child: Text(
                      item.pinTier.shortBadge,
                      style:
                          AppTypography.micro.copyWith(color: Colors.white),
                    ),
                  ),
                ),
              if (widget.onMenu != null)
                Positioned(
                  top: 6,
                  left: 6,
                  child: Material(
                    color: AppColors.paperElevated.withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(8),
                    child: InkWell(
                      onTap: widget.onMenu,
                      borderRadius: BorderRadius.circular(8),
                      child: const SizedBox(
                        width: 28,
                        height: 28,
                        child: Icon(
                          Icons.more_vert,
                          size: 16,
                          color: AppColors.inkSecondary,
                        ),
                      ),
                    ),
                  ),
                ),
              if (item.remark != null && item.remark!.isNotEmpty)
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: _PaperPill(
                    child: const Icon(
                      Icons.sticky_note_2_outlined,
                      size: 14,
                      color: AppColors.inkSecondary,
                    ),
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          flex: 28,
          child: Container(
            padding: const EdgeInsets.fromLTRB(8, 6, 6, 6),
            color: AppColors.paperElevated,
            child: LayoutBuilder(
              builder: (context, meta) {
                final showTags =
                    item.tags.isNotEmpty && meta.maxHeight > 78;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      shownTitle,
                      maxLines: meta.maxHeight > 70 ? 2 : 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.cardTitle.copyWith(
                        fontSize: meta.maxHeight > 70 ? 14 : 12,
                      ),
                    ),
                    if (showTags) ...[
                      const SizedBox(height: 2),
                      Text(
                        item.tags.length == 1
                            ? item.tags.first
                            : '${item.tags.first}+${item.tags.length - 1}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.micro,
                      ),
                    ],
                    const Spacer(flex: 1),
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: progress),
                      duration: const Duration(milliseconds: 350),
                      curve: Curves.easeOutCubic,
                      builder: (context, value, _) {
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(3),
                          child: LinearProgressIndicator(
                            value: value,
                            minHeight: 3,
                            backgroundColor: AppColors.divider,
                            color: color,
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            transitionBuilder: (child, anim) =>
                                FadeTransition(opacity: anim, child: child),
                            child: Text(
                              '${item.currentUnits}/${item.totalUnits ?? '?'} ${item.unitLabel}',
                              key: ValueKey(
                                '${item.id}_${item.currentUnits}',
                              ),
                              style: AppTypography.caption
                                  .copyWith(fontSize: 11),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        if (widget.showIncrement &&
                            widget.onIncrement != null)
                          _PlusButton(
                            color: color,
                            onPressed: widget.onIncrement!,
                          ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _StripIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _StripIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.paperElevated.withValues(alpha: 0.9),
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: SizedBox(
          width: 24,
          height: 24,
          child: Icon(icon, size: 14, color: AppColors.inkSecondary),
        ),
      ),
    );
  }
}

class _PaperPill extends StatelessWidget {
  final Widget child;
  final Color? background;
  final EdgeInsetsGeometry? margin;

  const _PaperPill({
    required this.child,
    this.background,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: background ?? AppColors.paperElevated.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(8),
        border:
            Border.all(color: AppColors.borderSubtle.withValues(alpha: 0.8)),
        boxShadow: AppShadows.soft,
      ),
      child: child,
    );
  }
}

class _PlusButton extends StatelessWidget {
  final Color color;
  final VoidCallback onPressed;
  final double size;
  final double iconSize;

  const _PlusButton({
    required this.color,
    required this.onPressed,
    this.size = 28,
    this.iconSize = 18,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          width: size,
          height: size,
          child: Icon(Icons.add, size: iconSize, color: Colors.white),
        ),
      ),
    );
  }
}
