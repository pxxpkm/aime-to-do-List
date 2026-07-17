import 'package:flutter/material.dart';

import 'package:acg_todo/presentation/widgets/poster_image_widget.dart';

Future<void> showPosterFullscreen(
  BuildContext context, {
  required String? posterUrl,
  required String type,
  required String title,
}) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: '關閉',
    barrierColor: Colors.black.withValues(alpha: 0.92),
    transitionDuration: const Duration(milliseconds: 200),
    pageBuilder: (ctx, anim, secondary) {
      return SafeArea(
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                minScale: 0.8,
                maxScale: 4,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.sizeOf(ctx).width,
                    maxHeight: MediaQuery.sizeOf(ctx).height * 0.9,
                  ),
                  child: AspectRatio(
                    aspectRatio: 0.7,
                    child: PosterImageWidget(
                      posterUrl: posterUrl,
                      type: type,
                      fit: BoxFit.contain,
                      width: double.infinity,
                      height: double.infinity,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: Material(
                color: Colors.black54,
                shape: const CircleBorder(),
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.of(ctx).pop(),
                  tooltip: '關閉',
                ),
              ),
            ),
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.75),
                  fontSize: 13,
                  decoration: TextDecoration.none,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}
