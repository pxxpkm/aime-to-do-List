import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:acg_todo/core/theme/app_colors.dart';
import 'package:acg_todo/core/theme/app_typography.dart';
import 'package:acg_todo/data/local/library_backend_info.dart';

/// Shown on Web when not connected to local SQLite API.
class StorageModeBanner extends ConsumerStatefulWidget {
  const StorageModeBanner({super.key});

  @override
  ConsumerState<StorageModeBanner> createState() => _StorageModeBannerState();
}

class _StorageModeBannerState extends ConsumerState<StorageModeBanner> {
  bool _dismissed = false;

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb || _dismissed) return const SizedBox.shrink();
    final info = ref.watch(libraryBackendInfoProvider);
    if (info.isServer) return const SizedBox.shrink();

    return Material(
      color: AppColors.warning.withValues(alpha: 0.12),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.info_outline, size: 18, color: AppColors.warning),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '未連上本機磁碟庫。請執行 python proxy_server.py，'
                '並用 http://127.0.0.1:8080 開啟，'
                '作品與目標才不會因清快取消失。',
                style: AppTypography.caption.copyWith(
                  color: AppColors.inkPrimary,
                ),
              ),
            ),
            IconButton(
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.close, size: 18),
              onPressed: () => setState(() => _dismissed = true),
            ),
          ],
        ),
      ),
    );
  }
}
