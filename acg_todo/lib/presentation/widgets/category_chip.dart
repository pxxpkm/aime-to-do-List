import 'package:flutter/material.dart';

import 'package:acg_todo/domain/entities/item_category.dart';
import 'package:acg_todo/presentation/widgets/paper_filter_chip.dart';

class CategoryChip extends StatelessWidget {
  final ItemCategory category;
  final bool selected;
  final VoidCallback? onTap;

  const CategoryChip({
    super.key,
    required this.category,
    this.selected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return PaperFilterChip(
      label: category.label,
      selected: selected,
      accent: category.color,
      onTap: onTap,
    );
  }
}
