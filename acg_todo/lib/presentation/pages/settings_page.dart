import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter/foundation.dart';

import 'package:acg_todo/core/notifications/web_browser_notification.dart';
import 'package:acg_todo/core/theme/app_colors.dart';
import 'package:acg_todo/core/theme/app_palette.dart';
import 'package:acg_todo/core/theme/app_scaffold.dart';
import 'package:acg_todo/data/local/library_backend_info.dart';
import 'package:acg_todo/domain/services/reminder_types.dart';
import 'package:acg_todo/presentation/providers/bangumi_provider.dart';
import 'package:acg_todo/presentation/providers/daily_goal_provider.dart';
import 'package:acg_todo/presentation/providers/folders_provider.dart';
import 'package:acg_todo/presentation/providers/items_provider.dart';
import 'package:acg_todo/presentation/providers/notification_providers.dart';
import 'package:acg_todo/presentation/providers/repository_providers.dart';
import 'package:acg_todo/core/utils/web_hard_reload.dart';
import 'package:acg_todo/presentation/widgets/backup_import_sheet.dart';
import 'package:acg_todo/presentation/widgets/hive_to_server_migrate_sheet.dart';
import 'package:acg_todo/presentation/widgets/storage_mode_banner.dart';
import 'package:acg_todo/data/local/hive_cache.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  final _tokenController = TextEditingController();
  bool _obscureToken = true;

  @override
  void dispose() {
    _tokenController.dispose();
    super.dispose();
  }

  Future<void> _verifyToken() async {
    final token = _tokenController.text.trim();
    if (token.isEmpty) return;
    await ref.read(bangumiNotifierProvider.notifier).verifyAndSaveToken(token);
  }

  String _backupSubtitle() {
    final store = ref.read(goalSettingsStoreProvider);
    final backend = ref.read(libraryBackendInfoProvider);
    final hiveHint = backend.isServer
        ? ''
        : ' · 瀏覽器庫請常備份';
    final at = store.lastBackupAt;
    if (at == null) {
      return '下載 JSON（作品、資料夾、目標進度）· 尚未匯出$hiveHint';
    }
    final local = at.toLocal();
    final stamp =
        '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')} '
        '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
    final days = DateTime.now().difference(at).inDays;
    final stale = days >= 14 ? ' · 建議再匯出' : '';
    return '上次 $stamp$stale$hiveHint';
  }

  @override
  Widget build(BuildContext context) {
    final bangumiState = ref.watch(bangumiNotifierProvider);
    final backend = ref.watch(libraryBackendInfoProvider);
    ref.watch(dailyGoalTickProvider);
    final tokenStore = ref.watch(bangumiTokenStoreProvider);

    return AppScaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const StorageModeBanner(),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  if (context.canPop())
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => context.pop(),
                    ),
                  const Text(
                    '設定',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    // ── 儲存位置 ──
                    const _SectionTitle(title: '儲存位置'),
                    const SizedBox(height: 8),
                    _SettingTile(
                      title: backend.title,
                      subtitle: backend.detail,
                      icon: backend.isServer
                          ? Icons.storage_outlined
                          : Icons.web_asset_outlined,
                      onTap: () {},
                    ),
                    SizedBox(height: 32),

                    // ── Bangumi 帳號 ──
                    _SectionTitle(title: 'Bangumi 帳號'),
                    SizedBox(height: 8),

                    if (bangumiState.isVerified) ...[
                      Material(
                        color: context.palette.elevated,
                        borderRadius: BorderRadius.circular(12),
                        child: ListTile(
                          leading:
                              Icon(Icons.check_circle, color: context.palette.success),
                          title: Text('已連結：${bangumiState.username ?? ""}'),
                          subtitle: Text('點擊取消連結',
                              style: TextStyle(
                                  color: context.palette.inkMuted, fontSize: 12)),
                          onTap: () => ref
                              .read(bangumiNotifierProvider.notifier)
                              .clearToken(),
                        ),
                      ),
                      if (tokenStore.canPersistToDisk) ...[
                        SizedBox(height: 8),
                        Material(
                          color: context.palette.elevated,
                          borderRadius: BorderRadius.circular(12),
                          child: SwitchListTile(
                            secondary: Icon(
                              Icons.save_outlined,
                              color: context.palette.manga,
                            ),
                            title: Text('Token 存到磁碟庫'),
                            subtitle: Text(
                              tokenStore.persistToDisk
                                  ? '已寫入 library.db 設定（清瀏覽器仍保留）'
                                  : '預設只在瀏覽器；開啟後一併寫入磁碟（opt-in）',
                              style: TextStyle(
                                color: context.palette.inkMuted,
                                fontSize: 12,
                              ),
                            ),
                            value: tokenStore.persistToDisk,
                            onChanged: (v) async {
                              await tokenStore.setPersistToDisk(v);
                              ref.read(dailyGoalTickProvider.notifier).state++;
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    v ? '已將 Token 存到磁碟庫' : '已改回僅瀏覽器儲存',
                                  ),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                              setState(() {});
                            },
                          ),
                        ),
                      ],
                      SizedBox(height: 8),
                      Material(
                        color: context.palette.elevated,
                        borderRadius: BorderRadius.circular(12),
                        child: ListTile(
                          leading:
                              Icon(Icons.download, color: context.palette.game),
                          title: Text('匯入我的收藏列表'),
                          subtitle: Text('從 Bangumi 匯入你的想看/在看/看過',
                              style: TextStyle(
                                  color: context.palette.inkMuted, fontSize: 12)),
                          onTap: () => context.push('/import-collection'),
                        ),
                      ),
                    ] else ...[
                      Material(
                        color: context.palette.elevated,
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            TextField(
                              controller: _tokenController,
                              obscureText: _obscureToken,
                              decoration: InputDecoration(
                                labelText: 'Bangumi Token',
                                hintText: '貼上您的 Access Token',
                                suffixIcon: IconButton(
                                  icon: Icon(_obscureToken
                                      ? Icons.visibility_off
                                      : Icons.visibility),
                                  onPressed: () => setState(
                                      () => _obscureToken = !_obscureToken),
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                filled: true,
                                fillColor:
                                    context.palette.elevated,
                              ),
                            ),
                            SizedBox(height: 12),
                            SizedBox(
                              height: 44,
                              child: ElevatedButton(
                                onPressed: bangumiState.isLoading
                                    ? null
                                    : _verifyToken,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: context.palette.lightNovel,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(12),
                                  ),
                                ),
                                child: bangumiState.isLoading
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Text('驗證並連結',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold)),
                              ),
                            ),
                            if (bangumiState.error != null) ...[
                              SizedBox(height: 8),
                              Text(
                                bangumiState.error!,
                                style: TextStyle(
                                    color: context.palette.danger, fontSize: 12),
                              ),
                            ],
                            const SizedBox(height: 8),
                            Text(
                              'Token 可在 bgm.tv 設定頁取得',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.white.withValues(alpha: 0.3),
                              ),
                            ),
                          ],
                        ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 32),

                    // ── 外觀（主題）──
                    const _SectionTitle(title: '外觀'),
                    const SizedBox(height: 8),
                    const _ThemeSettingsPanel(),
                    const SizedBox(height: 32),

                    // ── 進度目標 ──
                    const _SectionTitle(title: '進度目標'),
                    const SizedBox(height: 8),
                    const _MultiGoalSettings(),
                    const SizedBox(height: 32),

                    // ── 主頁外觀 ──
                    const _SectionTitle(title: '主頁外觀'),
                    const SizedBox(height: 8),
                    const _HomeDensitySetting(),
                    const SizedBox(height: 32),

                    // ── 搜尋 ──
                    const _SectionTitle(title: '搜尋'),
                    const SizedBox(height: 8),
                    const _SearchT2sSetting(),
                    const SizedBox(height: 8),
                    const _TitleS2tSetting(),
                    const SizedBox(height: 32),

                    // ── 通知設定 ──
                    const _SectionTitle(title: '通知設定'),
                    const SizedBox(height: 8),
                    const _NotificationSettingsPanel(),
                    const SizedBox(height: 32),

                    // ── 資料 ──
                    const _SectionTitle(title: '資料'),
                    const SizedBox(height: 8),
                    if (backend.isServer) ...[
                      Builder(
                        builder: (context) {
                          final hive = ref.watch(hiveCacheProvider);
                          final counts = ref
                              .read(libraryBackupRepositoryProvider)
                              .hiveSnapshotCounts(hive);
                          final canMigrate = !counts.isEmpty;
                          return _SettingTile(
                            title: '上傳瀏覽器資料到磁碟庫',
                            subtitle: canMigrate
                                ? 'Hive 作品 ${counts.itemCount} · '
                                    '資料夾 ${counts.folderCount} → library.db'
                                : '瀏覽器無作品可遷移',
                            icon: Icons.cloud_upload_outlined,
                            onTap: canMigrate
                                ? () => showHiveToServerMigrateSheet(context)
                                : () {},
                          );
                        },
                      ),
                      const SizedBox(height: 8),
                    ],
                    _SettingTile(
                      title: '匯出備份',
                      subtitle: _backupSubtitle(),
                      icon: Icons.download_outlined,
                      onTap: () => exportLibraryBackup(ref, context),
                    ),
                    const SizedBox(height: 8),
                    _SettingTile(
                      title: '匯入備份',
                      subtitle: '合併另一個網址的庫，或還原 JSON',
                      icon: Icons.upload_outlined,
                      onTap: () => showBackupImportSheet(context),
                    ),
                    const SizedBox(height: 8),
                    _SettingTile(
                      title: '清除本機作品',
                      subtitle: backend.isServer
                          ? '刪除磁碟庫中的全部作品（資料夾保留）'
                          : '刪除瀏覽器內全部作品（資料夾保留）',
                      icon: Icons.delete_sweep_outlined,
                      onTap: () async {
                        final ok = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('清除本機作品？'),
                            content: Text(
                              backend.isServer
                                  ? '將刪除磁碟庫（SQLite）中的全部作品，無法復原。'
                                      '建議先「匯出備份」。'
                                  : '將刪除這個瀏覽器網址下的全部作品，無法復原。'
                                      '建議先「匯出備份」。',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                child: Text('取消'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, true),
                                style: TextButton.styleFrom(
                                  foregroundColor: context.palette.danger,
                                ),
                                child: const Text('清除'),
                              ),
                            ],
                          ),
                        );
                        if (ok != true || !context.mounted) return;
                        await ref
                            .read(libraryBackupRepositoryProvider)
                            .clearLibraryItems();
                        ref.invalidate(itemsNotifierProvider);
                        ref.invalidate(foldersNotifierProvider);
                        ref.invalidate(multiGoalProvider);
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('已清除本機作品')),
                        );
                      },
                    ),

                    const SizedBox(height: 32),

                    // ── 關於 ──
                    const _SectionTitle(title: '關於'),
                    const SizedBox(height: 8),
                    _SettingTile(
                      title: '資料來源',
                      subtitle: 'AniList / Bangumi',
                      icon: Icons.source_outlined,
                      onTap: () {},
                    ),
                    const SizedBox(height: 8),
                    _SettingTile(
                      title: '版本',
                      subtitle: '1.0.0',
                      icon: Icons.info_outlined,
                      onTap: () {},
                    ),
                    if (kIsWeb) ...[
                      const SizedBox(height: 8),
                      _SettingTile(
                        title: '強制重新載入',
                        subtitle: '清除 Service Worker / 快取後重整（改 UI 後若仍見舊版）',
                        icon: Icons.refresh,
                        onTap: () async {
                          final ok = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('強制重新載入？'),
                              content: const Text(
                                '會取消註冊 Service Worker、清 Cache Storage，'
                                '然後重新整理頁面。本機作品資料不會因此刪除。',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, false),
                                  child: const Text('取消'),
                                ),
                                FilledButton(
                                  onPressed: () => Navigator.pop(ctx, true),
                                  child: const Text('重新載入'),
                                ),
                              ],
                            ),
                          );
                          if (ok == true) await hardReloadApp();
                        },
                      ),
                    ],

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ],
          ),
        ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.bold,
        color: context.palette.inkSecondary,
        letterSpacing: 0.5,
      ),
    );
  }
}

/// Theme picker — default paper_light; dark opt-in; system follow optional.
class _ThemeSettingsPanel extends ConsumerWidget {
  const _ThemeSettingsPanel();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final store = ref.watch(goalSettingsStoreProvider);
    ref.watch(dailyGoalTickProvider);
    final follow = store.themeFollowSystem;
    final id = store.themeId;
    final resolvedId = follow
        ? (MediaQuery.platformBrightnessOf(context) == Brightness.dark
            ? AppPalette.paperDarkId
            : AppPalette.paperLightId)
        : id;

    void tick() => ref.read(dailyGoalTickProvider.notifier).state++;

    return Material(
      color: context.palette.elevated,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.palette_outlined,
                    color: context.palette.anime, size: 20),
                const SizedBox(width: 8),
                const Text('顏色主題',
                    style: TextStyle(fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              segments: [
                for (final p in AppPalette.registry.values)
                  ButtonSegment(value: p.id, label: Text(p.label)),
              ],
              selected: {follow ? resolvedId : AppPalette.byId(id).id},
              onSelectionChanged: follow
                  ? (_) {}
                  : (s) async {
                      await store.setThemeId(s.first);
                      tick();
                    },
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('跟隨系統淺色/深色'),
              subtitle: Text(
                follow
                    ? '已開啟：會在紙感淺色與深色畫廊間切換'
                    : '關閉時使用上方手動選擇（預設淺色，不影響現有網站）',
                style: TextStyle(
                    fontSize: 12, color: context.palette.inkMuted),
              ),
              value: follow,
              onChanged: (v) async {
                await store.setThemeFollowSystem(v);
                tick();
              },
            ),
            Text(
              '預設為淺色紙感。深色為可選；海報上的白字/黑漸層不跟主題改變。'
              '多數畫面已跟主題切換。',
              style:
                  TextStyle(fontSize: 12, color: context.palette.inkMuted),
            ),
          ],
        ),
      ),
    );
  }
}

class _MultiGoalSettings extends ConsumerWidget {
  const _MultiGoalSettings();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final store = ref.watch(goalSettingsStoreProvider);
    ref.watch(dailyGoalTickProvider);
    void tick() => ref.read(dailyGoalTickProvider.notifier).state++;

    return Column(
      children: [
        _GoalStepperTile(
          icon: Icons.today,
          title: '今日目標',
          value: store.goalUnits,
          onChanged: (v) async {
            await store.setGoalUnits(v);
            tick();
          },
        ),
        const SizedBox(height: 8),
        _GoalStepperTile(
          icon: Icons.date_range,
          title: '近 ${store.rollingDays} 日目標',
          value: store.rollingTarget,
          enabled: store.rollingEnabled,
          onToggle: (v) async {
            await store.setRollingEnabled(v);
            tick();
          },
          onChanged: (v) async {
            await store.setRollingTarget(v);
            tick();
          },
          extra: Row(
            children: [
              const Text('天數', style: TextStyle(fontSize: 12)),
              IconButton(
                icon: const Icon(Icons.remove, size: 18),
                onPressed: store.rollingDays <= 2
                    ? null
                    : () async {
                        await store.setRollingDays(store.rollingDays - 1);
                        tick();
                      },
              ),
              Text('${store.rollingDays}'),
              IconButton(
                icon: const Icon(Icons.add, size: 18),
                onPressed: store.rollingDays >= 31
                    ? null
                    : () async {
                        await store.setRollingDays(store.rollingDays + 1);
                        tick();
                      },
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        _GoalStepperTile(
          icon: Icons.calendar_month,
          title: '本月目標',
          value: store.monthTarget,
          enabled: store.monthEnabled,
          onToggle: (v) async {
            await store.setMonthEnabled(v);
            tick();
          },
          onChanged: (v) async {
            await store.setMonthTarget(v);
            tick();
          },
        ),
        const SizedBox(height: 8),
        _GoalStepperTile(
          icon: Icons.calendar_today,
          title: '今年目標',
          value: store.yearTarget,
          enabled: store.yearEnabled,
          onToggle: (v) async {
            await store.setYearEnabled(v);
            tick();
          },
          onChanged: (v) async {
            await store.setYearTarget(v);
            tick();
          },
        ),
      ],
    );
  }
}

class _GoalStepperTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final int value;
  final ValueChanged<int> onChanged;
  final bool? enabled;
  final ValueChanged<bool>? onToggle;
  final Widget? extra;

  const _GoalStepperTile({
    required this.icon,
    required this.title,
    required this.value,
    required this.onChanged,
    this.enabled,
    this.onToggle,
    this.extra,
  });

  @override
  Widget build(BuildContext context) {
    final on = enabled ?? true;
    return Material(
      color: context.palette.elevated,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: EdgeInsets.fromLTRB(12, 8, 4, 8),
        child: Column(
          children: [
            Row(
              children: [
                Icon(icon, color: context.palette.anime, size: 20),
                const SizedBox(width: 8),
                Expanded(child: Text(title)),
                if (onToggle != null)
                  Switch(value: on, onChanged: onToggle),
                IconButton(
                  onPressed: !on || value <= 1
                      ? null
                      : () => onChanged(value - 1),
                  icon: const Icon(Icons.remove_circle_outline),
                ),
                Text(
                  '$value',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: !on ? null : () => onChanged(value + 1),
                  icon: const Icon(Icons.add_circle_outline),
                ),
              ],
            ),
            if (extra != null && on) extra!,
          ],
        ),
      ),
    );
  }
}

class _SearchT2sSetting extends ConsumerWidget {
  const _SearchT2sSetting();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final store = ref.watch(goalSettingsStoreProvider);
    ref.watch(dailyGoalTickProvider);
    final on = store.searchTradToSimp;
    return Material(
      color: context.palette.elevated,
      borderRadius: BorderRadius.circular(12),
      child: SwitchListTile(
        secondary: Icon(Icons.translate, color: context.palette.manga),
        title: Text('Bangumi 搜尋繁轉簡'),
        subtitle: Text(
          '繁體關鍵字自動轉簡體再搜尋',
          style: TextStyle(color: context.palette.inkMuted, fontSize: 12),
        ),
        value: on,
        onChanged: (v) async {
          await store.setSearchTradToSimp(v);
          ref.read(dailyGoalTickProvider.notifier).state++;
        },
      ),
    );
  }
}

class _TitleS2tSetting extends ConsumerWidget {
  const _TitleS2tSetting();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final store = ref.watch(goalSettingsStoreProvider);
    ref.watch(dailyGoalTickProvider);
    final on = store.titleSimpToTrad;
    return Material(
      color: context.palette.elevated,
      borderRadius: BorderRadius.circular(12),
      child: SwitchListTile(
        secondary: Icon(Icons.title, color: context.palette.lightNovel),
        title: Text('標題簡轉繁'),
        subtitle: Text(
          '新增與顯示時把簡體標題轉成繁體',
          style: TextStyle(color: context.palette.inkMuted, fontSize: 12),
        ),
        value: on,
        onChanged: (v) async {
          await store.setTitleSimpToTrad(v);
          ref.read(dailyGoalTickProvider.notifier).state++;
        },
      ),
    );
  }
}

class _HomeDensitySetting extends ConsumerWidget {
  const _HomeDensitySetting();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final store = ref.watch(goalSettingsStoreProvider);
    ref.watch(dailyGoalTickProvider);
    final density = store.homeGridDensity;

    return Material(
      color: context.palette.elevated,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.grid_view, color: context.palette.manga, size: 20),
                SizedBox(width: 8),
                Text('媒體庫海報大小', style: TextStyle(fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'large', label: Text('畫廊')),
                ButtonSegment(value: 'comfortable', label: Text('標準')),
                ButtonSegment(value: 'compact', label: Text('緊湊')),
              ],
              selected: {density},
              onSelectionChanged: (s) async {
                await store.setHomeGridDensity(s.first);
                ref.read(dailyGoalTickProvider.notifier).state++;
              },
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.crop_free, color: context.palette.manga, size: 20),
                SizedBox(width: 8),
                Text('媒體庫海報裁切', style: TextStyle(fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'cover', label: Text('填滿裁切')),
                ButtonSegment(value: 'contain', label: Text('完整顯示')),
              ],
              selected: {store.posterImageFit},
              onSelectionChanged: (s) async {
                await store.setPosterImageFit(s.first);
                ref.read(dailyGoalTickProvider.notifier).state++;
              },
            ),
            SizedBox(height: 6),
            Text(
              '僅影響媒體庫海報牆。主頁大海報 / 抽海報維持填滿。',
              style: TextStyle(fontSize: 12, color: context.palette.inkMuted),
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.image_outlined, color: context.palette.anime, size: 20),
                SizedBox(width: 8),
                Text('主頁大海報', style: TextStyle(fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'daily', label: Text('每日')),
                ButtonSegment(value: 'pinned', label: Text('固定')),
                ButtonSegment(value: 'off', label: Text('關閉')),
              ],
              selected: {store.homeHeroMode},
              onSelectionChanged: (s) async {
                await store.setHomeHeroMode(s.first);
                ref.read(dailyGoalTickProvider.notifier).state++;
              },
            ),
            SizedBox(height: 6),
            Text(
              '固定：主頁海報「固定」鈕或抽海報「設為主頁海報」。箭嘴/滑動只瀏覽，不改釘選。',
              style: TextStyle(fontSize: 12, color: context.palette.inkMuted),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationSettingsPanel extends ConsumerWidget {
  const _NotificationSettingsPanel();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cache = ref.watch(notificationSettingsProvider);
    final goals = ref.watch(goalSettingsStoreProvider);
    ref.watch(dailyGoalTickProvider);
    final master = cache.notificationsEnabled;
    final deadline = cache.getNotificationEnabled(ReminderTypes.settingDeadline);
    final stale = cache.getNotificationEnabled(ReminderTypes.settingStale);
    final daily = cache.getNotificationEnabled(ReminderTypes.settingDailyGoal);
    final staleDays = cache.staleDays;
    final offsets = goals.deadlineReminderDays.toSet();
    final overdue = goals.deadlineRemindOverdue;
    final browserPerm = kIsWeb ? WebBrowserNotification.permission : null;

    void tick() {
      ref.read(notificationsTickProvider.notifier).state++;
      ref.read(dailyGoalTickProvider.notifier).state++;
    }

    return Column(
      children: [
        _SwitchTile(
          title: '提醒總開關',
          subtitle: '關閉後不再產生新提醒',
          icon: Icons.notifications_outlined,
          value: master,
          onChanged: (v) async {
            await cache.setNotificationsEnabled(v);
            tick();
          },
        ),
        const SizedBox(height: 8),
        _SwitchTile(
          title: '期限提醒',
          subtitle: '依下方自訂「還剩幾天」觸發',
          icon: Icons.alarm_outlined,
          value: deadline,
          onChanged: master
              ? (v) async {
                  await cache.setNotificationEnabled(
                      ReminderTypes.settingDeadline, v);
                  tick();
                }
              : null,
        ),
        if (deadline && master) ...[
          SizedBox(height: 4),
          Material(
            color: context.palette.elevated,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '提醒日（距到期還剩）',
                    style: TextStyle(
                      fontSize: 12,
                      color: context.palette.inkSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final d in [14, 7, 5, 3, 2, 1, 0])
                        FilterChip(
                          label: Text(d == 0 ? '當天' : '$d 天'),
                          selected: offsets.contains(d),
                          onSelected: (on) async {
                            final next = Set<int>.from(offsets);
                            if (on) {
                              next.add(d);
                            } else {
                              next.remove(d);
                            }
                            if (next.isEmpty) next.add(0);
                            await goals.setDeadlineReminderDays(next.toList());
                            tick();
                          },
                        ),
                    ],
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('逾期也提醒', style: TextStyle(fontSize: 13)),
                    value: overdue,
                    onChanged: (v) async {
                      await goals.setDeadlineRemindOverdue(v);
                      tick();
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
        const SizedBox(height: 8),
        _SwitchTile(
          title: '進度停滯提醒',
          subtitle: '超過 $staleDays 天未更新進度',
          icon: Icons.hourglass_bottom_outlined,
          value: stale,
          onChanged: master
              ? (v) async {
                  await cache.setNotificationEnabled(
                      ReminderTypes.settingStale, v);
                  tick();
                }
              : null,
        ),
        if (stale && master) ...[
          SizedBox(height: 4),
          Material(
            color: context.palette.elevated,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, 4, 8, 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text('停滯天數',
                        style: TextStyle(color: context.palette.inkSecondary)),
                  ),
                  IconButton(
                    onPressed: staleDays <= 1
                        ? null
                        : () async {
                            await cache.setStaleDays(staleDays - 1);
                            tick();
                          },
                    icon: const Icon(Icons.remove_circle_outline, size: 20),
                  ),
                  Text('$staleDays',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  IconButton(
                    onPressed: staleDays >= 30
                        ? null
                        : () async {
                            await cache.setStaleDays(staleDays + 1);
                            tick();
                          },
                    icon: const Icon(Icons.add_circle_outline, size: 20),
                  ),
                ],
              ),
            ),
          ),
        ],
        const SizedBox(height: 8),
        _SwitchTile(
          title: '今日目標提醒',
          subtitle: '未達標時提醒（一天一則）',
          icon: Icons.flag_outlined,
          value: daily,
          onChanged: master
              ? (v) async {
                  await cache.setNotificationEnabled(
                      ReminderTypes.settingDailyGoal, v);
                  tick();
                }
              : null,
        ),
        if (kIsWeb) ...[
          SizedBox(height: 8),
          Material(
            color: context.palette.elevated,
            borderRadius: BorderRadius.circular(12),
            child: ListTile(
              leading: Icon(Icons.web, color: context.palette.manga),
              title: Text('瀏覽器通知'),
              subtitle: Text(
                _browserPermLabel(browserPerm),
                style: TextStyle(
                    color: context.palette.inkMuted, fontSize: 12),
              ),
              trailing: browserPerm == 'granted'
                  ? Icon(Icons.check_circle, color: context.palette.success)
                  : TextButton(
                      onPressed: () async {
                        final r =
                            await WebBrowserNotification.requestPermission();
                        tick();
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('權限：$r'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      child: const Text('允許'),
                    ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 6, 8, 0),
            child: Text(
              '網頁版：提醒會寫入通知中心；允許後可再跳系統氣泡。關閉瀏覽器後無法背景推送。',
              style: TextStyle(
                fontSize: 11,
                color: Colors.white.withValues(alpha: 0.35),
              ),
            ),
          ),
        ],
        SizedBox(height: 8),
        Material(
          color: context.palette.elevated,
          borderRadius: BorderRadius.circular(12),
          child: ListTile(
            leading: Icon(Icons.refresh, color: context.palette.lightNovel),
            title: Text('立即檢查提醒'),
            subtitle: Text(
              '依目前作品與目標產生通知',
              style: TextStyle(color: context.palette.inkMuted, fontSize: 12),
            ),
            onTap: () async {
              final n = await ref
                  .read(notificationsNotifierProvider.notifier)
                  .runCheck();
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(n == 0 ? '沒有新提醒' : '新增了 $n 則提醒'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  String _browserPermLabel(String? p) {
    switch (p) {
      case 'granted':
        return '已允許系統通知';
      case 'denied':
        return '已拒絕（仍可用通知中心）';
      case 'default':
        return '尚未請求權限';
      default:
        return p ?? '不支援';
    }
  }
}

class _SwitchTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool value;
  final ValueChanged<bool>? onChanged;

  const _SwitchTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.palette.elevated,
      borderRadius: BorderRadius.circular(12),
      child: SwitchListTile(
        secondary: Icon(icon, color: context.palette.manga),
        title: Text(title),
        subtitle: Text(
          subtitle,
          style: TextStyle(color: context.palette.inkMuted, fontSize: 12),
        ),
        value: value,
        onChanged: onChanged,
      ),
    );
  }
}

class _SettingTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _SettingTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.palette.elevated,
      borderRadius: BorderRadius.circular(12),
      child: ListTile(
        leading: Icon(icon, color: context.palette.manga),
        title: Text(title),
        subtitle: Text(
          subtitle,
          style: TextStyle(color: context.palette.inkMuted, fontSize: 12),
        ),
        trailing: Icon(Icons.chevron_right, color: context.palette.inkMuted),
        onTap: onTap,
      ),
    );
  }
}
