import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:acg_todo/core/theme/app_colors.dart';
import 'package:acg_todo/core/theme/app_palette.dart';
import 'package:acg_todo/core/theme/app_typography.dart';
import 'package:acg_todo/core/utils/web_hard_reload.dart';
import 'package:acg_todo/data/local/library_backend_info.dart';
import 'package:acg_todo/data/local/server_health.dart';

/// Shown on Web when not connected to local SQLite API (Hive mode).
///
/// - **Localhost**: nudge toward `proxy_server.py` + 8080 disk library.
/// - **Deployed host** (Cloudflare etc.): hive + backup discipline; no 8080 nag.
class StorageModeBanner extends ConsumerStatefulWidget {
  const StorageModeBanner({super.key});

  @override
  ConsumerState<StorageModeBanner> createState() => _StorageModeBannerState();
}

class _StorageModeBannerState extends ConsumerState<StorageModeBanner> {
  bool _dismissed = false;
  bool _retrying = false;

  bool get _isLocalDevHost {
    final h = Uri.base.host.toLowerCase();
    return h.isEmpty ||
        h == 'localhost' ||
        h == '127.0.0.1' ||
        h == '0.0.0.0' ||
        h.endsWith('.local');
  }

  Future<void> _retryProbe() async {
    if (_retrying) return;
    setState(() => _retrying = true);
    final health = await probeLibraryServer();
    if (!mounted) return;
    setState(() => _retrying = false);
    if (health != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('已偵測到磁碟庫，正在重新載入…'),
          behavior: SnackBarBehavior.floating,
          duration: Duration(milliseconds: 1200),
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 400));
      await hardReloadApp();
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _isLocalDevHost
              ? '仍連不上 /api/health — 請確認 proxy 已在 8080 執行'
              : '此站點未提供磁碟庫 API（雲端靜態部署為瀏覽器儲存）',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showHelp() {
    final local = _isLocalDevHost;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(local ? '本機磁碟庫' : '雲端瀏覽器儲存'),
        content: Text(
          local
              ? '正式本機用法：\n'
                  '1. flutter build web\n'
                  '2. python proxy_server.py\n'
                  '3. 只用 http://127.0.0.1:8080 開啟\n\n'
                  '若用 flutter run 隨機埠，會退回瀏覽器 Hive，'
                  '清快取可能丟失作品。\n\n'
                  '「重試連線」探測 /api/health，成功後強制重新載入。'
              : '此網址為靜態部署（如 Cloudflare Pages）。\n\n'
                  '作品資料存在**這個瀏覽器**（Hive / IndexedDB），'
                  '不是雲端共用資料庫。\n\n'
                  '• 清站資料 / 換裝置 / 換瀏覽器 → 可能看不到作品\n'
                  '• 請定期到「設定 → 匯出備份」下載 JSON\n'
                  '• 本機仍可用 8080 + SQLite 當權威庫，再匯入\n\n'
                  '海報圖經同源 /proxy（Pages Function 或本機 proxy）載入。',
        ),
        actions: [
          if (!local)
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                context.push('/settings');
              },
              child: const Text('去設定備份'),
            ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('知道了'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb || _dismissed) return SizedBox.shrink();
    final info = ref.watch(libraryBackendInfoProvider);
    if (info.isServer) return SizedBox.shrink();

    final local = _isLocalDevHost;

    return Material(
      color: context.palette.warning.withValues(alpha: 0.12),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.only(top: 2),
              child: Icon(
                Icons.info_outline,
                size: 18,
                color: context.palette.warning,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    local
                        ? '未連上本機磁碟庫。請執行 python proxy_server.py，'
                            '並用 http://127.0.0.1:8080 開啟，'
                            '作品與目標才不會因清快取消失。'
                        : '資料存在此瀏覽器（非雲端共用庫）。'
                            '清站或換裝置可能丟失作品 — 請定期「設定 → 匯出備份」。',
                    style: AppTypography.caption.copyWith(
                      color: context.palette.ink,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 4,
                    runSpacing: 0,
                    children: [
                      if (local)
                        TextButton(
                          onPressed: _retrying ? null : _retryProbe,
                          style: TextButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                            foregroundColor: context.palette.anime,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                          ),
                          child: _retrying
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text('重試連線'),
                        )
                      else
                        TextButton(
                          onPressed: () => context.push('/settings'),
                          style: TextButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                            foregroundColor: context.palette.anime,
                            padding: EdgeInsets.symmetric(horizontal: 8),
                          ),
                          child: Text('匯出備份'),
                        ),
                      TextButton(
                        onPressed: _showHelp,
                        style: TextButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          foregroundColor: context.palette.inkSecondary,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                        ),
                        child: const Text('說明'),
                      ),
                    ],
                  ),
                ],
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
