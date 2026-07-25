import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import 'package:acg_todo/core/theme/app_colors.dart';
import 'package:acg_todo/core/theme/app_palette.dart';

class ShimmerPlaceholder extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const ShimmerPlaceholder({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 12,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: context.palette.divider,
      highlightColor: context.palette.elevated,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: context.palette.border,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}
