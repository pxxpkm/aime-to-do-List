import 'package:flutter/material.dart';

import 'package:acg_todo/core/theme/app_colors.dart';
import 'package:acg_todo/domain/entities/folder.dart';
import 'package:acg_todo/domain/entities/item.dart';
import 'package:acg_todo/presentation/widgets/poster_image_widget.dart';

class FolderTile extends StatelessWidget {
  final Folder folder;
  final List<Item> previewItems;
  final int count;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool isDropHighlight;

  const FolderTile({
    super.key,
    required this.folder,
    required this.previewItems,
    required this.count,
    this.onTap,
    this.onLongPress,
    this.isDropHighlight = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = folder.colorValue != null
        ? Color(folder.colorValue!)
        : AppColors.manga;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: AppColors.paperElevated,
            border: Border.all(
              color: isDropHighlight
                  ? AppColors.anime
                  : AppColors.borderSubtle,
              width: isDropHighlight ? 2 : 1,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x1A2C2416),
                blurRadius: 16,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 10, 10, 4),
                  child: _PreviewStack(items: previewItems, color: color),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
                child: Row(
                  children: [
                    Icon(Icons.folder, size: 16, color: color),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        folder.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: AppColors.inkPrimary,
                        ),
                      ),
                    ),
                    Text(
                      '$count',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.inkMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PreviewStack extends StatelessWidget {
  final List<Item> items;
  final Color color;

  const _PreviewStack({required this.items, required this.color});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: color.withValues(alpha: 0.15),
        ),
        child: Icon(Icons.folder_open, color: color.withValues(alpha: 0.6)),
      );
    }

    final show = items.take(3).toList();
    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth * 0.55;
        final h = c.maxHeight * 0.85;
        return Stack(
          alignment: Alignment.center,
          children: [
            for (var i = 0; i < show.length; i++)
              Transform.translate(
                offset: Offset((i - 1) * 10.0, (i - 1) * 6.0),
                child: Transform.rotate(
                  angle: (i - 1) * 0.06,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: SizedBox(
                      width: w,
                      height: h,
                      child: PosterImageWidget(
                        posterUrl: show[i].posterUrl,
                        type: show[i].type,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
