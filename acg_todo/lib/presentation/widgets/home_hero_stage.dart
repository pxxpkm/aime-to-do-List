import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:acg_todo/core/theme/app_colors.dart';
import 'package:acg_todo/core/theme/app_typography.dart';
import 'package:acg_todo/core/utils/item_display.dart';
import 'package:acg_todo/domain/entities/item.dart';
import 'package:acg_todo/presentation/providers/daily_goal_provider.dart';
import 'package:acg_todo/presentation/providers/notification_providers.dart';
import 'package:acg_todo/presentation/providers/repository_providers.dart';
import 'package:acg_todo/presentation/widgets/home_goal_card.dart';
import 'package:acg_todo/presentation/widgets/poster_gacha_dialog.dart';
import 'package:acg_todo/presentation/widgets/poster_image_widget.dart';

/// Immersive homepage hero: near-fullscreen 2:3 poster + overlay CTAs.
class HomeHeroStage extends ConsumerWidget {
  final List<Item> items;
  final void Function(Item item) onOpenItem;
  final void Function(Item item)? onIncrement;

  const HomeHeroStage({
    super.key,
    required this.items,
    required this.onOpenItem,
    this.onIncrement,
  });

  List<Item> _pool() {
    final withArt = items
        .where((i) => i.posterUrl != null && i.posterUrl!.isNotEmpty)
        .toList();
    if (withArt.isNotEmpty) return withArt;
    return List<Item>.from(items);
  }

  Item? _resolveHero(WidgetRef ref) {
    final store = ref.read(goalSettingsStoreProvider);
    final mode = store.homeHeroMode;
    if (mode == 'off') return null;

    final pool = _pool();
    if (pool.isEmpty) return null;

    if (mode == 'pinned') {
      final id = store.homeHeroItemId;
      if (id != null) {
        final found = pool.where((i) => i.id == id).firstOrNull;
        if (found != null) return found;
      }
    }

    final day = store.dayKey();
    final seed = day.hashCode ^ pool.length;
    return pool[Random(seed).nextInt(pool.length)];
  }

  /// Near full-bleed portrait stage; keep 2:3, prefer height when tight.
  static (double w, double h) _stageSize({
    required double maxWidth,
    required double viewportHeight,
    required EdgeInsets pad,
  }) {
    // Leave a sliver for「接下來」peek + FAB breathing room.
    final availableH =
        (viewportHeight - pad.top - pad.bottom - 96).clamp(280.0, viewportHeight);
    final maxW = (maxWidth - 16).clamp(240.0, 720.0);

    // Prefer filling height (immersive), then center-fit width.
    var cardH = availableH * 0.92;
    var cardW = cardH / 1.5;
    if (cardW > maxW) {
      cardW = maxW;
      cardH = cardW * 1.5;
    }
    if (cardH > availableH) {
      cardH = availableH;
      cardW = cardH / 1.5;
    }
    return (cardW, cardH);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(dailyGoalTickProvider);
    final store = ref.watch(goalSettingsStoreProvider);
    final s2t = store.titleSimpToTrad;
    final pool = _pool();
    final hero = _resolveHero(ref);
    final unread = ref.watch(unreadNotificationsCountProvider);

    if (store.homeHeroMode == 'off' && pool.isEmpty) {
      return const SizedBox.shrink();
    }

    final viewportH = MediaQuery.sizeOf(context).height;
    final pad = MediaQuery.paddingOf(context);

    if (hero == null) {
      return LayoutBuilder(
        builder: (context, constraints) {
          final (_, cardH) = _stageSize(
            maxWidth: constraints.maxWidth.isFinite
                ? constraints.maxWidth
                : MediaQuery.sizeOf(context).width,
            viewportHeight: viewportH,
            pad: pad,
          );
          return Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
            child: SizedBox(
              height: cardH.clamp(220.0, 360.0),
              child: _EmptyHero(
                onSearch: () => context.push('/search'),
                onGacha: pool.isEmpty
                    ? null
                    : () => showPosterGachaDialog(
                          context,
                          items: items,
                          onOpenItem: onOpenItem,
                        ),
              ),
            ),
          );
        },
      );
    }

    final title = displayTitle(hero.title, simpToTrad: s2t);
    final accent = AppColors.getTypeColor(hero.type);

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxW = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        final (cardW, cardH) = _stageSize(
          maxWidth: maxW,
          viewportHeight: viewportH,
          pad: pad,
        );
        return Padding(
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
          child: Center(
            child: SizedBox(
              width: cardW,
              height: cardH,
              child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: 20,
                right: 20,
                bottom: 6,
                height: 52,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(40),
                    boxShadow: [
                      BoxShadow(
                        color: accent.withValues(alpha: 0.28),
                        blurRadius: 40,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
              ),
              // Poster surface (tap → detail). Overlays sit as siblings so
              // their gestures are not swallowed by this InkWell.
              Positioned.fill(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => onOpenItem(hero),
                    borderRadius: BorderRadius.circular(14),
                    child: Ink(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color:
                              AppColors.borderSubtle.withValues(alpha: 0.85),
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x402C2416),
                            blurRadius: 36,
                            offset: Offset(0, 18),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(13),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            PosterImageWidget(
                              key: ValueKey('home_hero_${hero.id}'),
                              posterUrl: hero.posterUrl,
                              type: hero.type,
                              fit: BoxFit.cover,
                            ),
                            Positioned(
                              left: 0,
                              right: 0,
                              top: 0,
                              height: 96,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.black.withValues(alpha: 0.55),
                                      Colors.transparent,
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              left: 0,
                              right: 0,
                              bottom: 0,
                              height: 168,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.transparent,
                                      Colors.black.withValues(alpha: 0.94),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              left: 14,
                              right: 14,
                              bottom: 14,
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.stretch,
                                children: [
                                  Text(
                                    '今日主視覺',
                                    style: AppTypography.micro.copyWith(
                                      color: Colors.white54,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    title,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTypography.title.copyWith(
                                      color: Colors.white,
                                      fontSize: 22,
                                      height: 1.2,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${hero.currentUnits}/${hero.totalUnits ?? '?'} ${hero.unitLabel}',
                                    style: AppTypography.caption.copyWith(
                                      color: Colors.white70,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _HeroBtn(
                                          filled: true,
                                          icon: Icons.casino_outlined,
                                          label: '抽海報',
                                          onTap: () => showPosterGachaDialog(
                                            context,
                                            items: items,
                                            onOpenItem: onOpenItem,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: _HeroBtn(
                                          filled: false,
                                          icon: Icons.play_arrow_rounded,
                                          label: '開啟',
                                          onTap: () => onOpenItem(hero),
                                        ),
                                      ),
                                      if (onIncrement != null) ...[
                                        const SizedBox(width: 8),
                                        _HeroBtn(
                                          filled: false,
                                          icon: Icons.add,
                                          label: '+1',
                                          compact: true,
                                          onTap: () => onIncrement!(hero),
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              // Goal pill — top-left (outside poster InkWell)
              const Positioned(
                top: 10,
                left: 10,
                child: HomeGoalPill(),
              ),
              // Notifications — top-right
              Positioned(
                top: 10,
                right: 10,
                child: Material(
                  color: Colors.black.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(999),
                  child: InkWell(
                    onTap: () => context.push('/notifications'),
                    borderRadius: BorderRadius.circular(999),
                    child: Padding(
                      padding: const EdgeInsets.all(9),
                      child: Badge(
                        isLabelVisible: unread > 0,
                        smallSize: 8,
                        child: const Icon(
                          Icons.notifications_outlined,
                          size: 20,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
      },
    );
  }
}

class _HeroBtn extends StatelessWidget {
  final bool filled;
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool compact;

  const _HeroBtn({
    required this.filled,
    required this.icon,
    required this.label,
    required this.onTap,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final child = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: Colors.white),
        if (!compact) ...[
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ] else ...[
          const SizedBox(width: 2),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
        ],
      ],
    );

    return Material(
      color: filled
          ? AppColors.anime
          : Colors.white.withValues(alpha: 0.18),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 12 : 10,
            vertical: 10,
          ),
          child: child,
        ),
      ),
    );
  }
}

class _EmptyHero extends StatelessWidget {
  final VoidCallback onSearch;
  final VoidCallback? onGacha;

  const _EmptyHero({required this.onSearch, this.onGacha});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: AppColors.paperElevated,
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        children: [
          Icon(
            Icons.auto_awesome,
            size: 44,
            color: AppColors.anime.withValues(alpha: 0.75),
          ),
          const SizedBox(height: 14),
          Text('架上還沒有作品', style: AppTypography.title.copyWith(fontSize: 18)),
          const SizedBox(height: 8),
          Text(
            '加入作品後，這裡會成為今日主視覺',
            style: AppTypography.caption,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 18),
          FilledButton(onPressed: onSearch, child: const Text('搜尋並加入')),
          if (onGacha != null) ...[
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: onGacha,
              icon: const Icon(Icons.casino_outlined, size: 18),
              label: const Text('抽海報'),
            ),
          ],
        ],
      ),
    );
  }
}
