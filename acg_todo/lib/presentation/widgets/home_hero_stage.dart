import 'dart:math';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:acg_todo/core/theme/app_colors.dart';
import 'package:acg_todo/core/theme/app_palette.dart';
import 'package:acg_todo/core/theme/app_typography.dart';
import 'package:acg_todo/core/utils/item_display.dart';
import 'package:acg_todo/core/utils/poster_url.dart';
import 'package:acg_todo/domain/entities/item.dart';
import 'package:acg_todo/presentation/home/home_hero_pool.dart';
import 'package:acg_todo/presentation/pages/item_detail/poster_fullscreen_dialog.dart';
import 'package:acg_todo/presentation/providers/daily_goal_provider.dart';
import 'package:acg_todo/presentation/providers/notification_providers.dart';
import 'package:acg_todo/presentation/providers/repository_providers.dart';
import 'package:acg_todo/presentation/widgets/home_goal_card.dart';
import 'package:acg_todo/presentation/widgets/poster_gacha_dialog.dart';
import 'package:acg_todo/presentation/widgets/poster_image_widget.dart';

/// Immersive homepage hero: near-fullscreen 2:3 poster + overlay CTAs.
///
/// Arrows / swipe / ←→ cycle the hero pool (session browse). 「固定」writes
/// home-hero settings only — never pin tiers.
class HomeHeroStage extends ConsumerStatefulWidget {
  final List<Item> items;
  final void Function(Item item) onOpenItem;
  final void Function(Item item)? onIncrement;

  const HomeHeroStage({
    super.key,
    required this.items,
    required this.onOpenItem,
    this.onIncrement,
  });

  @override
  ConsumerState<HomeHeroStage> createState() => _HomeHeroStageState();
}

class _HomeHeroStageState extends ConsumerState<HomeHeroStage> {
  /// When true, arrows overrode the resolved (daily/pinned) hero for this session.
  bool _userBrowsing = false;
  String? _shownId;
  String? _lastPrecacheAroundId;
  final _focusNode = FocusNode(debugLabel: 'home_hero');

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant HomeHeroStage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_userBrowsing || _shownId == null) return;
    final pool = buildHeroPool(widget.items);
    if (!pool.any((i) => i.id == _shownId)) {
      _userBrowsing = false;
      _shownId = null;
    }
  }

  Item? _resolveHero(List<Item> pool) {
    final store = ref.read(goalSettingsStoreProvider);
    final mode = store.homeHeroMode;
    if (mode == 'off') return null;
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

  /// Pure display pick — no state writes (safe in build).
  Item? _displayHero(List<Item> pool) {
    if (pool.isEmpty) return null;

    if (_userBrowsing && _shownId != null) {
      final idx = pool.indexWhere((i) => i.id == _shownId);
      if (idx >= 0) return pool[idx];
    }

    return _resolveHero(pool);
  }

  void _step(int delta, List<Item> pool, Item current) {
    if (pool.length < 2) return;
    var idx = pool.indexWhere((i) => i.id == current.id);
    if (idx < 0) idx = 0;
    final safe = heroStepIndex(idx, delta, pool.length);
    setState(() {
      _userBrowsing = true;
      _shownId = pool[safe].id;
      _lastPrecacheAroundId = null; // force re-warm after step
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _precacheNeighbors(pool, safe);
    });
  }

  /// Warm adjacent posters so arrow / swipe feels instant.
  void _precacheNeighbors(List<Item> pool, int index) {
    if (pool.length < 2 || !mounted) return;
    final aroundId = pool[index.clamp(0, pool.length - 1)].id;
    if (_lastPrecacheAroundId == aroundId) return;
    _lastPrecacheAroundId = aroundId;
    for (final delta in const [-1, 1]) {
      final i = heroStepIndex(index, delta, pool.length);
      final raw = pool[i].posterUrl;
      final url = normalizePosterUrl(raw);
      if (url == null || url.startsWith('data:')) continue;
      final loadUrl = kIsWeb ? toProxyUrl(url) : url;
      // Fire-and-forget; ignore failures (offline / CORS).
      precacheImage(NetworkImage(loadUrl), context).ignore();
    }
  }

  void _onHorizontalDragEnd(
    DragEndDetails details,
    List<Item> pool,
    Item current,
  ) {
    if (pool.length < 2) return;
    final v = details.primaryVelocity ?? 0;
    if (v.abs() < 280) return;
    // Swipe left → next; swipe right → previous.
    _step(v < 0 ? 1 : -1, pool, current);
  }

  Future<void> _togglePinHero(Item item) async {
    final store = ref.read(goalSettingsStoreProvider);
    final isPinned =
        store.homeHeroMode == 'pinned' && store.homeHeroItemId == item.id;
    if (isPinned) {
      await store.setHomeHeroMode('daily');
    } else {
      await store.pinHomeHero(item.id);
      setState(() {
        _userBrowsing = false;
        _shownId = item.id;
      });
    }
    ref.read(dailyGoalTickProvider.notifier).state++;
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isPinned ? '已改回每日主視覺' : '已設「${item.title}」為主頁海報',
        ),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(milliseconds: 1200),
      ),
    );
  }

  void _openFullscreen(Item item) {
    final s2t = ref.read(goalSettingsStoreProvider).titleSimpToTrad;
    showPosterFullscreen(
      context,
      posterUrl: item.posterUrl,
      type: item.type,
      title: displayTitle(item.title, simpToTrad: s2t),
    );
  }

  /// Near full-bleed portrait stage; keep 2:3, prefer height when tight.
  static (double w, double h) _stageSize({
    required double maxWidth,
    required double viewportHeight,
    required EdgeInsets pad,
  }) {
    final availableH =
        (viewportHeight - pad.top - pad.bottom - 96).clamp(280.0, viewportHeight);
    final maxW = (maxWidth - 16).clamp(240.0, 720.0);

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
  Widget build(BuildContext context) {
    ref.watch(dailyGoalTickProvider);
    final store = ref.watch(goalSettingsStoreProvider);
    final s2t = store.titleSimpToTrad;
    final pool = buildHeroPool(widget.items);
    final hero = _displayHero(pool);
    final heroIndex = hero == null ? 0 : heroIndexOf(pool, hero.id);
    final unread = ref.watch(unreadNotificationsCountProvider);
    final canNav = pool.length > 1 && hero != null;
    final isHeroPinned = hero != null &&
        store.homeHeroMode == 'pinned' &&
        store.homeHeroItemId == hero.id;

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
                          items: widget.items,
                          onOpenItem: widget.onOpenItem,
                        ),
              ),
            ),
          );
        },
      );
    }

    final title = displayTitle(hero.title, simpToTrad: s2t);
    final accent = context.palette.typeColor(hero.type);

    // Precache neighbors once per displayed id (after frame).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _precacheNeighbors(pool, heroIndex);
    });

    final stage = LayoutBuilder(
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
                  // Poster surface. Swipe / long-press / tap handled here.
                  Positioned.fill(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onHorizontalDragEnd: canNav
                          ? (d) => _onHorizontalDragEnd(d, pool, hero)
                          : null,
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => widget.onOpenItem(hero),
                          onLongPress: () => _openFullscreen(hero),
                          borderRadius: BorderRadius.circular(14),
                          child: Ink(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: context.palette.border
                                    .withValues(alpha: 0.85),
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
                                  AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 240),
                                    switchInCurve: Curves.easeOut,
                                    switchOutCurve: Curves.easeIn,
                                    child: PosterImageWidget(
                                      key: ValueKey('home_hero_${hero.id}'),
                                      posterUrl: hero.posterUrl,
                                      type: hero.type,
                                      fit: BoxFit.cover,
                                    ),
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
                                          canNav
                                              ? '今日主視覺  ·  ${heroIndex + 1}/${pool.length}'
                                              : '今日主視覺',
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
                                          style:
                                              AppTypography.caption.copyWith(
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
                                                onTap: () =>
                                                    showPosterGachaDialog(
                                                  context,
                                                  items: widget.items,
                                                  onOpenItem:
                                                      widget.onOpenItem,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: _HeroBtn(
                                                filled: false,
                                                icon:
                                                    Icons.play_arrow_rounded,
                                                label: '開啟',
                                                onTap: () =>
                                                    widget.onOpenItem(hero),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            _HeroBtn(
                                              filled: isHeroPinned,
                                              icon: isHeroPinned
                                                  ? Icons.push_pin
                                                  : Icons.push_pin_outlined,
                                              label:
                                                  isHeroPinned ? '已固定' : '固定',
                                              compact: true,
                                              onTap: () =>
                                                  _togglePinHero(hero),
                                            ),
                                            if (widget.onIncrement != null) ...[
                                              const SizedBox(width: 8),
                                              _HeroBtn(
                                                filled: false,
                                                icon: Icons.add,
                                                label: '+1',
                                                compact: true,
                                                onTap: () =>
                                                    widget.onIncrement!(hero),
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
                  ),
                  const Positioned(
                    top: 10,
                    left: 10,
                    child: HomeGoalPill(),
                  ),
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
                  if (canNav) ...[
                    Positioned(
                      left: 6,
                      top: 0,
                      bottom: 0,
                      child: Center(
                        child: _HeroNavButton(
                          icon: Icons.chevron_left_rounded,
                          tooltip: '上一張海報',
                          onTap: () => _step(-1, pool, hero),
                        ),
                      ),
                    ),
                    Positioned(
                      right: 6,
                      top: 0,
                      bottom: 0,
                      child: Center(
                        child: _HeroNavButton(
                          icon: Icons.chevron_right_rounded,
                          tooltip: '下一張海報',
                          onTap: () => _step(1, pool, hero),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );

    if (!canNav) return stage;

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.arrowLeft): () =>
            _step(-1, pool, hero),
        const SingleActivator(LogicalKeyboardKey.arrowRight): () =>
            _step(1, pool, hero),
      },
      child: Focus(
        focusNode: _focusNode,
        autofocus: true,
        child: stage,
      ),
    );
  }
}

class _HeroNavButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _HeroNavButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.42),
      shape: const CircleBorder(),
      elevation: 2,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Tooltip(
          message: tooltip,
          child: SizedBox(
            width: 40,
            height: 40,
            child: Icon(icon, color: Colors.white, size: 28),
          ),
        ),
      ),
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
              fontSize: 12,
            ),
          ),
        ],
      ],
    );

    return Material(
      color: filled
          ? context.palette.anime
          : Colors.white.withValues(alpha: 0.18),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 10 : 10,
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
      padding: EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: context.palette.elevated,
        border: Border.all(color: context.palette.border),
      ),
      child: Column(
        children: [
          Icon(
            Icons.auto_awesome,
            size: 44,
            color: context.palette.anime.withValues(alpha: 0.75),
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
