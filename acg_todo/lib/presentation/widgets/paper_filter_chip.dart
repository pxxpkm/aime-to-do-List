import 'package:flutter/material.dart';

import 'package:acg_todo/core/theme/app_colors.dart';

/// Paper-gallery filter pill — selected uses ink/accent text, never white-on-wash.
class PaperFilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color accent;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final IconData? icon;
  final String? countLabel;
  final EdgeInsetsGeometry padding;

  const PaperFilterChip({
    super.key,
    required this.label,
    required this.selected,
    required this.accent,
    this.onTap,
    this.onLongPress,
    this.icon,
    this.countLabel,
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
  });

  @override
  Widget build(BuildContext context) {
    final bg = selected
        ? accent.withValues(alpha: 0.14)
        : AppColors.paperElevated;
    final border = selected
        ? accent.withValues(alpha: 0.55)
        : AppColors.borderSubtle;
    final fg = selected ? accent : AppColors.inkSecondary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(999),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: padding,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: border),
            boxShadow: selected
                ? null
                : const [
                    BoxShadow(
                      color: Color(0x0A2C2416),
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    ),
                  ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 14, color: fg),
                const SizedBox(width: 4),
              ],
              Text(
                label,
                style: TextStyle(
                  color: fg,
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                ),
              ),
              if (countLabel != null) ...[
                const SizedBox(width: 4),
                Text(
                  countLabel!,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: selected
                        ? accent.withValues(alpha: 0.85)
                        : AppColors.inkMuted,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
