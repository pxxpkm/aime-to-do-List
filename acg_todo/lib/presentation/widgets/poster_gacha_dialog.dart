import 'dart:async';
import 'dart:math';

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:acg_todo/core/theme/app_colors.dart';
import 'package:acg_todo/core/theme/app_typography.dart';
import 'package:acg_todo/core/utils/item_display.dart';
import 'package:acg_todo/domain/entities/item.dart';
import 'package:acg_todo/presentation/home/home_hero_pool.dart';
import 'package:acg_todo/presentation/providers/daily_goal_provider.dart';
import 'package:acg_todo/presentation/providers/repository_providers.dart';
import 'package:acg_todo/presentation/widgets/poster_image_widget.dart';

/// Pure-fun poster gacha popup. Does not change pin tiers or progress.
Future<void> showPosterGachaDialog(
  BuildContext context, {
  required List<Item> items,
  required void Function(Item item) onOpenItem,
}) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: '關閉抽海報',
    barrierColor: Colors.black.withValues(alpha: 0.68),
    transitionDuration: const Duration(milliseconds: 220),
    pageBuilder: (ctx, a1, a2) {
      return PosterGachaDialog(
        items: items,
        onOpenItem: onOpenItem,
      );
    },
    transitionBuilder: (ctx, anim, _, child) {
      return FadeTransition(
        opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
        child: ScaleTransition(
          scale: Tween(begin: 0.92, end: 1.0).animate(
            CurvedAnimation(parent: anim, curve: Curves.easeOutBack),
          ),
          child: child,
        ),
      );
    },
  );
}

class PosterGachaDialog extends ConsumerStatefulWidget {
  final List<Item> items;
  final void Function(Item item) onOpenItem;

  const PosterGachaDialog({
    super.key,
    required this.items,
    required this.onOpenItem,
  });

  @override
  ConsumerState<PosterGachaDialog> createState() => _PosterGachaDialogState();
}

class _PosterGachaDialogState extends ConsumerState<PosterGachaDialog> {
  final _rng = Random();
  late ConfettiController _confetti;
  Timer? _timer;
  int _rollStep = 0;
  bool _rolling = true;
  Item? _display;
  Item? _result;

  List<Item> get _pool {
    final withArt = widget.items
        .where((i) => i.posterUrl != null && i.posterUrl!.isNotEmpty)
        .toList();
    if (withArt.isNotEmpty) return withArt;
    return List<Item>.from(widget.items);
  }

  @override
  void initState() {
    super.initState();
    _confetti =
        ConfettiController(duration: const Duration(milliseconds: 1400));
    WidgetsBinding.instance.addPostFrameCallback((_) => _startRoll());
  }

  @override
  void dispose() {
    _timer?.cancel();
    _confetti.dispose();
    super.dispose();
  }

  void _startRoll() {
    final pool = _pool;
    if (pool.isEmpty) {
      setState(() {
        _rolling = false;
        _result = null;
      });
      return;
    }
    _timer?.cancel();
    setState(() {
      _rolling = true;
      _result = null;
      _rollStep = 0;
      _display = pool[_rng.nextInt(pool.length)];
    });
    _scheduleNext(pool, 50);
  }

  void _scheduleNext(List<Item> pool, int delayMs) {
    _timer = Timer(Duration(milliseconds: delayMs), () {
      if (!mounted) return;
      _rollStep++;
      final nextDelay = (50 + _rollStep * 18).clamp(50, 320);
      if (_rollStep >= 18) {
        final result = pool[_rng.nextInt(pool.length)];
        setState(() {
          _rolling = false;
          _display = result;
          _result = result;
        });
        _confetti.play();
        return;
      }
      setState(() => _display = pool[_rng.nextInt(pool.length)]);
      _scheduleNext(pool, nextDelay);
    });
  }

  Future<void> _setAsHomeHero(Item item) async {
    await ref.read(goalSettingsStoreProvider).pinHomeHero(item.id);
    ref.read(dailyGoalTickProvider.notifier).state++;
    if (!mounted) return;
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('已設「${item.title}」為主頁海報'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(milliseconds: 1200),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s2t = ref.watch(goalSettingsStoreProvider).titleSimpToTrad;
    final shown = _display;
    final color = shown != null
        ? AppColors.getTypeColor(shown.type)
        : AppColors.anime;
    final title = shown != null
        ? displayTitle(shown.title, simpToTrad: s2t)
        : '';

    // Immersive 2:3 stage — reserve enough chrome so action buttons never
    // sit under the poster (result Wrap can be 1–2 rows ≈ 100–120px).
    final screen = MediaQuery.sizeOf(context);
    final pad = MediaQuery.paddingOf(context);
    // title+subtitle+gaps ≈ 56; gap under card 28; actions 2 rows ≈ 108; bottom 16
    final chrome = _rolling ? 140.0 : 220.0;
    final size = gachaPosterSize(
      screenWidth: screen.width,
      screenHeight: screen.height,
      chromeHeight: chrome + pad.vertical,
    );
    final cardW = size.width;
    final cardH = size.height;

    return Material(
      color: Colors.transparent,
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _rolling ? '抽海報中…' : '抽到了！',
                  style: AppTypography.title.copyWith(
                    color: Colors.white,
                    fontSize: 20,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '純娛樂 · 不影響釘選',
                  style: AppTypography.micro.copyWith(color: Colors.white70),
                ),
                const SizedBox(height: 14),
                // Clip so confetti/shadow cannot paint over the button row.
                Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.hardEdge,
                  children: [
                    // No scale > 1.0: AnimatedScale used to overflow into buttons.
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 280),
                      curve: Curves.easeOutCubic,
                      width: cardW,
                      height: cardH,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _result != null
                              ? AppColors.anime
                              : Colors.white24,
                          width: _result != null ? 2.5 : 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: (_result != null
                                    ? AppColors.anime
                                    : Colors.black)
                                .withValues(alpha: _result != null ? 0.5 : 0.4),
                            blurRadius: _result != null ? 32 : 24,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(11),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            if (shown != null)
                              PosterImageWidget(
                                key: ValueKey(
                                  'gacha_${shown.id}_$_rollStep',
                                ),
                                posterUrl: shown.posterUrl,
                                type: shown.type,
                                fit: BoxFit.cover,
                              )
                            else
                              const ColoredBox(color: Color(0xFF2C2416)),
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
                                      Colors.black.withValues(alpha: 0.85),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            if (shown != null && !_rolling)
                              Positioned(
                                left: 10,
                                right: 10,
                                bottom: 10,
                                child: Text(
                                  title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                  style: AppTypography.cardTitle.copyWith(
                                    color: Colors.white,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      top: 0,
                      child: ConfettiWidget(
                        confettiController: _confetti,
                        blastDirectionality: BlastDirectionality.explosive,
                        shouldLoop: false,
                        numberOfParticles: 24,
                        maxBlastForce: 22,
                        minBlastForce: 6,
                        emissionFrequency: 0.06,
                        gravity: 0.18,
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
                // Explicit gap: buttons must never crowd the poster.
                const SizedBox(height: 28),
                if (_rolling)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 8),
                    child: SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white70,
                      ),
                    ),
                  )
                else if (_result != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        FilledButton.icon(
                          onPressed: _startRoll,
                          icon: const Icon(Icons.casino, size: 18),
                          label: const Text('再抽一次'),
                        ),
                        FilledButton.tonalIcon(
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.white24,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () {
                            final item = _result!;
                            Navigator.of(context).pop();
                            widget.onOpenItem(item);
                          },
                          icon: const Icon(Icons.open_in_new, size: 18),
                          label: const Text('去看看'),
                        ),
                        TextButton.icon(
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () => _setAsHomeHero(_result!),
                          icon: const Icon(Icons.image_outlined, size: 18),
                          label: const Text('設為主頁海報'),
                        ),
                        TextButton(
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.white70,
                          ),
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('關閉'),
                        ),
                      ],
                    ),
                  )
                else
                  TextButton(
                    style: TextButton.styleFrom(foregroundColor: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('關閉'),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
