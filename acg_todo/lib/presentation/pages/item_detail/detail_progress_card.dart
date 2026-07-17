import 'package:flutter/material.dart';

import 'package:acg_todo/core/theme/app_colors.dart';
import 'package:acg_todo/core/theme/app_shadows.dart';
import 'package:acg_todo/core/theme/app_typography.dart';
import 'package:acg_todo/domain/entities/item.dart';
import 'package:acg_todo/presentation/widgets/progress_ring.dart';

/// Compact progress console for item detail (horizontal when wide enough).
class DetailProgressCard extends StatelessWidget {
  final Item item;
  final Color color;
  final double displayValue;
  final bool hasTotal;
  final int? total;
  final VoidCallback onEditTotal;
  final ValueChanged<double> onSliderChanged;
  final VoidCallback? onDecrement;
  final VoidCallback? onIncrement;
  final VoidCallback? onBookmarkHere;
  final VoidCallback? onJumpToBookmark;
  final String? lastProgressLabel;

  const DetailProgressCard({
    super.key,
    required this.item,
    required this.color,
    required this.displayValue,
    required this.hasTotal,
    required this.total,
    required this.onEditTotal,
    required this.onSliderChanged,
    this.onDecrement,
    this.onIncrement,
    this.onBookmarkHere,
    this.onJumpToBookmark,
    this.lastProgressLabel,
  });

  int get _shownUnits => displayValue.round();

  String get _totalLabel => hasTotal ? '$total' : '?';

  double get _progress {
    if (!hasTotal || total == null || total! <= 0) return 0;
    return (displayValue / total!).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
      decoration: BoxDecoration(
        color: AppColors.paperElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSubtle),
        boxShadow: AppShadows.soft,
      ),
      child: LayoutBuilder(
        builder: (context, c) {
          final horizontal = c.maxWidth >= 340;
          return horizontal ? _buildHorizontal() : _buildVertical();
        },
      ),
    );
  }

  Widget _buildHorizontal() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            AnimatedProgressRing(
              progress: _progress,
              size: 56,
              strokeWidth: 5.5,
              color: color,
              backgroundColor: AppColors.divider,
              duration: const Duration(milliseconds: 350),
              child: Text(
                hasTotal ? '${(_progress * 100).round()}' : '—',
                style: AppTypography.micro.copyWith(
                  fontWeight: FontWeight.w800,
                  color: color,
                  fontSize: 11,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 180),
                          child: Text(
                            '$_shownUnits / $_totalLabel ${item.unitLabel}',
                            key: ValueKey(
                              '$_shownUnits-$_totalLabel-${item.unitLabel}',
                            ),
                            style: AppTypography.display.copyWith(
                              fontSize: 22,
                              color: color,
                              height: 1.05,
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: hasTotal ? '改總量' : '設總量',
                        onPressed: onEditTotal,
                        visualDensity: VisualDensity.compact,
                        icon: Icon(
                          Icons.tune_rounded,
                          size: 18,
                          color: AppColors.inkSecondary,
                        ),
                      ),
                    ],
                  ),
                  if (hasTotal && total != null)
                    SliderTheme(
                      data: SliderThemeData(
                        trackHeight: 3.5,
                        activeTrackColor: color,
                        inactiveTrackColor: AppColors.divider,
                        thumbColor: color,
                        overlayShape: SliderComponentShape.noOverlay,
                        thumbShape: const RoundSliderThumbShape(
                          enabledThumbRadius: 7,
                        ),
                        padding: EdgeInsets.zero,
                      ),
                      child: Slider(
                        value: displayValue.clamp(0, total!.toDouble()),
                        min: 0,
                        max: total!.toDouble(),
                        onChanged: onSliderChanged,
                      ),
                    )
                  else
                    Text(
                      '總量未知 · 點右側設定',
                      style: AppTypography.micro.copyWith(
                        color: AppColors.inkMuted,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 4),
            Column(
              children: [
                _ProgressStepButton(
                  icon: Icons.add,
                  color: color,
                  compact: true,
                  onTap: onIncrement,
                ),
                const SizedBox(height: 6),
                _ProgressStepButton(
                  icon: Icons.remove,
                  color: color,
                  compact: true,
                  onTap: onDecrement,
                ),
              ],
            ),
          ],
        ),
        if (_hasMetaRow) ...[
          const SizedBox(height: 8),
          _metaRow(),
        ],
      ],
    );
  }

  Widget _buildVertical() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            AnimatedProgressRing(
              progress: _progress,
              size: 48,
              strokeWidth: 5,
              color: color,
              backgroundColor: AppColors.divider,
              duration: const Duration(milliseconds: 350),
              child: Text(
                hasTotal ? '${(_progress * 100).round()}' : '—',
                style: AppTypography.micro.copyWith(
                  fontWeight: FontWeight.w800,
                  color: color,
                  fontSize: 10,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '$_shownUnits / $_totalLabel ${item.unitLabel}',
                style: AppTypography.display.copyWith(
                  fontSize: 20,
                  color: color,
                  height: 1.05,
                ),
              ),
            ),
            IconButton(
              tooltip: hasTotal ? '改總量' : '設總量',
              onPressed: onEditTotal,
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.tune_rounded, size: 18),
            ),
          ],
        ),
        if (hasTotal && total != null)
          SliderTheme(
            data: SliderThemeData(
              trackHeight: 3.5,
              activeTrackColor: color,
              inactiveTrackColor: AppColors.divider,
              thumbColor: color,
              overlayShape: SliderComponentShape.noOverlay,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
            ),
            child: Slider(
              value: displayValue.clamp(0, total!.toDouble()),
              min: 0,
              max: total!.toDouble(),
              onChanged: onSliderChanged,
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              '總量未知 · 點右側設定後可用滑桿',
              style: AppTypography.micro.copyWith(color: AppColors.inkMuted),
            ),
          ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _ProgressStepButton(
              icon: Icons.remove,
              color: color,
              compact: true,
              onTap: onDecrement,
            ),
            const SizedBox(width: 16),
            _ProgressStepButton(
              icon: Icons.add,
              color: color,
              compact: true,
              onTap: onIncrement,
            ),
          ],
        ),
        if (_hasMetaRow) ...[
          const SizedBox(height: 6),
          _metaRow(),
        ],
      ],
    );
  }

  bool get _hasMetaRow =>
      lastProgressLabel != null ||
      item.bookmarkUnits != null ||
      onBookmarkHere != null;

  Widget _metaRow() {
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (lastProgressLabel != null)
          Text(
            lastProgressLabel!,
            style: AppTypography.micro.copyWith(color: AppColors.inkMuted),
          ),
        if (item.bookmarkUnits != null)
          TextButton(
            onPressed: onJumpToBookmark,
            style: TextButton.styleFrom(
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              foregroundColor: AppColors.inkSecondary,
            ),
            child: Text(
              '書籤 ${item.bookmarkUnits}',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
        if (onBookmarkHere != null)
          TextButton(
            onPressed: onBookmarkHere,
            style: TextButton.styleFrom(
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              foregroundColor: color,
            ),
            child: const Text(
              '設書籤',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
      ],
    );
  }
}

class _ProgressStepButton extends StatefulWidget {
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
  final bool compact;

  const _ProgressStepButton({
    required this.icon,
    required this.color,
    this.onTap,
    this.compact = false,
  });

  @override
  State<_ProgressStepButton> createState() => _ProgressStepButtonState();
}

class _ProgressStepButtonState extends State<_ProgressStepButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    final size = widget.compact ? 36.0 : 48.0;

    return AnimatedScale(
      scale: _pressed && enabled ? 0.94 : 1,
      duration: const Duration(milliseconds: 120),
      child: Material(
        color: enabled
            ? widget.color.withValues(alpha: 0.12)
            : AppColors.paperSurface,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: widget.onTap,
          onHighlightChanged: (v) {
            if (enabled) setState(() => _pressed = v);
          },
          child: Container(
            width: size,
            height: size,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: enabled
                    ? widget.color.withValues(alpha: 0.45)
                    : AppColors.borderSubtle,
              ),
            ),
            child: Icon(
              widget.icon,
              size: widget.compact ? 18 : 24,
              color: enabled ? widget.color : AppColors.inkMuted,
            ),
          ),
        ),
      ),
    );
  }
}
