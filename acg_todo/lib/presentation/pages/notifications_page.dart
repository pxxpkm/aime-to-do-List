import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:acg_todo/core/theme/app_colors.dart';
import 'package:acg_todo/domain/entities/item.dart';
import 'package:acg_todo/domain/entities/notification.dart';
import 'package:acg_todo/domain/services/reminder_types.dart';
import 'package:acg_todo/presentation/providers/items_provider.dart';
import 'package:acg_todo/presentation/providers/notification_providers.dart';

class NotificationsPage extends ConsumerStatefulWidget {
  const NotificationsPage({super.key});

  @override
  ConsumerState<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends ConsumerState<NotificationsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(notificationsNotifierProvider.notifier).markAllSeen();
    });
  }

  @override
  Widget build(BuildContext context) {
    final notifications = ref.watch(notificationsNotifierProvider);
    final items = ref.watch(itemsNotifierProvider);
    final itemMap = {for (final i in items) i.id: i};

    final grouped = <String, List<AppNotification>>{};
    for (final n in notifications) {
      grouped.putIfAbsent(n.type, () => []).add(n);
    }

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => context.pop(),
                    ),
                    const Expanded(
                      child: Text(
                        '通知中心',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (notifications.isNotEmpty)
                      TextButton(
                        onPressed: () => ref
                            .read(notificationsNotifierProvider.notifier)
                            .clearAll(),
                        child: const Text('清除全部'),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: notifications.isEmpty
                    ? _emptyState()
                    : ListView(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        children: [
                          _maybeSection(
                            '今日目標',
                            grouped[ReminderTypes.dailyGoal],
                            Icons.flag_outlined,
                            AppColors.anime,
                            itemMap,
                          ),
                          ..._deadlineSections(grouped, itemMap),
                          _maybeSection(
                            '已逾期',
                            grouped[ReminderTypes.overdue],
                            Icons.warning_amber,
                            AppColors.danger,
                            itemMap,
                          ),
                          _maybeSection(
                            '進度停滯',
                            grouped[ReminderTypes.stale],
                            Icons.hourglass_disabled,
                            AppColors.textSecondary,
                            itemMap,
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

  List<Widget> _deadlineSections(
    Map<String, List<AppNotification>> grouped,
    Map<String, Item> itemMap,
  ) {
    final keys = grouped.keys
        .where((k) => ReminderTypes.parseDeadlineDays(k) != null)
        .toList()
      ..sort((a, b) {
        final da = ReminderTypes.parseDeadlineDays(a)!;
        final db = ReminderTypes.parseDeadlineDays(b)!;
        return da.compareTo(db);
      });
    return [
      for (final k in keys)
        _maybeSection(
          _deadlineSectionTitle(k),
          grouped[k],
          Icons.access_time,
          AppColors.warning,
          itemMap,
        ),
    ];
  }

  String _deadlineSectionTitle(String type) {
    final n = ReminderTypes.parseDeadlineDays(type);
    if (n == null) return type;
    if (n == 0) return '今天到期';
    if (n == 1) return '明天到期';
    return '還有 $n 天到期';
  }

  Widget _maybeSection(
    String title,
    List<AppNotification>? list,
    IconData icon,
    Color color,
    Map<String, Item> itemMap,
  ) {
    if (list == null || list.isEmpty) return const SizedBox.shrink();
    return _section(title, list, icon, color, itemMap);
  }

  Widget _section(
    String title,
    List<AppNotification> list,
    IconData icon,
    Color color,
    Map<String, Item> itemMap,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 8),
          child: Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: color,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
        for (final n in list) _tile(n, itemMap, color),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _tile(
    AppNotification n,
    Map<String, Item> itemMap,
    Color color,
  ) {
    final isDaily = n.type == ReminderTypes.dailyGoal;
    final item = itemMap[n.itemId];
    final title = isDaily
        ? '今日目標未完成'
        : (item?.title ?? n.itemId);
    final subtitle = _subtitleFor(n.type);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        child: ListTile(
          title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
          subtitle: Text(
            subtitle,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
          ),
          trailing: isDaily || item == null
              ? const Icon(Icons.chevron_right, color: AppColors.textMuted)
              : IconButton(
                  tooltip: '+1',
                  icon: Icon(Icons.add_circle, color: color),
                  onPressed: () async {
                    await ref
                        .read(itemsNotifierProvider.notifier)
                        .incrementProgress(item.id);
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${item.title} +1'),
                        duration: const Duration(milliseconds: 800),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                ),
          onTap: () {
            if (isDaily) {
              context.pop();
            } else if (item != null) {
              context.push('/item/${item.id}');
            }
          },
        ),
      ),
    );
  }

  String _subtitleFor(String type) {
    if (type == ReminderTypes.overdue) return '已逾期';
    if (type == ReminderTypes.stale) return '進度停滯，該動一動了';
    if (type == ReminderTypes.dailyGoal) return '還沒達到今日集數目標';
    final n = ReminderTypes.parseDeadlineDays(type);
    if (n != null) {
      if (n == 0) return '今天到期';
      if (n == 1) return '明天到期';
      return '還有 $n 天到期';
    }
    // legacy types
    if (type == 'deadline_3day') return '還有 3 天到期';
    if (type == 'deadline_1day') return '明天到期';
    if (type == 'deadline_today') return '今天到期';
    return type;
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.notifications_none,
              size: 64, color: Colors.white.withValues(alpha: 0.3)),
          const SizedBox(height: 12),
          Text(
            '目前沒有通知',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () async {
              final n = await ref
                  .read(notificationsNotifierProvider.notifier)
                  .runCheck();
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(n == 0 ? '沒有新提醒' : '新增了 $n 則提醒'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: const Text('立即檢查'),
          ),
        ],
      ),
    );
  }
}
