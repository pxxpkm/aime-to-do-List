import 'package:acg_todo/core/notifications/web_browser_notification.dart';
import 'package:acg_todo/core/utils/logger.dart';
import 'package:acg_todo/data/local/goal_settings_store.dart';
import 'package:acg_todo/data/local/notification_store.dart';
import 'package:acg_todo/data/repositories/items_repository.dart';
import 'package:acg_todo/domain/entities/notification.dart';
import 'package:acg_todo/domain/services/deadline_service.dart';
import 'package:acg_todo/domain/services/reminder_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationScheduler {
  final ItemsRepository _itemsRepo;
  final NotificationStore _notifCache;
  final GoalSettingsStore _goalSettings;
  final ReminderService _reminderService;

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  FirebaseMessaging? _fcm;

  NotificationScheduler({
    required ItemsRepository itemsRepo,
    required NotificationStore notifCache,
    required GoalSettingsStore goalSettings,
    DeadlineService deadlineService = const DeadlineService(),
    ReminderService? reminderService,
  }) : this._(
          itemsRepo,
          notifCache,
          goalSettings,
          reminderService ??
              ReminderService(deadlineService: deadlineService),
        );

  NotificationScheduler._(
    this._itemsRepo,
    this._notifCache,
    this._goalSettings,
    this._reminderService,
  );

  /// Init local notifications (mobile) / soft-fail on web.
  Future<void> initialize() async {
    if (kIsWeb) {
      Logger().i(
        'Web notifications: in-app center + browser Notification API '
        '(permission=${WebBrowserNotification.permission})',
      );
      return;
    }

    try {
      _fcm = FirebaseMessaging.instance;
      final settings = await _fcm!.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        Logger().i('FCM permission granted');
      }
      final token = await _fcm!.getToken();
      if (token != null) Logger().i('FCM token: $token');
      _fcm!.onTokenRefresh.listen((t) => Logger().i('FCM token refreshed: $t'));
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);
    } catch (e) {
      Logger().w('FCM init skipped: $e');
    }

    await _initLocalNotifications();
  }

  Future<void> _initLocalNotifications() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    await _localNotifications.initialize(
      const InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload;
        if (payload != null && payload.isNotEmpty) {
          Logger().i('Local notification tapped: $payload');
        }
      },
    );

    const channel = AndroidNotificationChannel(
      'acg_todo_reminders',
      'ACG 提醒',
      description: '限期、停滯與每日目標提醒',
      importance: Importance.high,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    final title = message.notification?.title ?? 'ACG To-Do';
    final body = message.notification?.body ?? '';
    final itemId = message.data['itemId'];
    await _showLocal(title, body, itemId);
  }

  void _handleNotificationTap(RemoteMessage message) {
    final itemId = message.data['itemId'];
    if (itemId != null) {
      Logger().i('Notification tapped for item: $itemId');
    }
  }

  /// Collect reminders, persist to Hive, show system/browser notifications.
  /// Returns number of newly created notifications.
  Future<int> runLocalReminderCheck() async {
    if (!_notifCache.notificationsEnabled) {
      Logger().d('Reminders disabled globally');
      return 0;
    }

    final now = DateTime.now();
    final candidates = _reminderService.collect(
      items: _itemsRepo.getAll(),
      goalUnits: _goalSettings.goalUnits,
      todayUnits: _goalSettings.todayUnits(now), // day bucket
      staleDays: _notifCache.staleDays,
      globalDeadlineOffsets: _goalSettings.deadlineReminderDays,
      includeOverdue: _goalSettings.deadlineRemindOverdue,
      enabled: (key) => _notifCache.getNotificationEnabled(key),
      now: now,
    );

    var created = 0;
    for (final c in candidates) {
      if (_notifCache.wasNotifiedToday(c.itemId, c.type, now)) continue;

      final notification = AppNotification(
        id: 'notif_${c.itemId}_${c.type}_${now.millisecondsSinceEpoch}',
        itemId: c.itemId,
        type: c.type,
        scheduledAt: now,
        sentAt: now,
        createdAt: now,
      );
      await _notifCache.put(notification);
      created++;

      final dayKey =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      final tag = '${c.type}_${c.itemId}_$dayKey';

      if (kIsWeb) {
        if (WebBrowserNotification.permission == 'granted') {
          WebBrowserNotification.show(
            title: c.title,
            body: c.body,
            tag: tag,
          );
        }
      } else {
        await _showLocal(c.title, c.body, c.itemId);
      }
    }

    Logger().i('Reminder check: $created new notification(s)');
    return created;
  }

  Future<void> _showLocal(String title, String body, String? itemId) async {
    try {
      await _localNotifications.show(
        title.hashCode ^ body.hashCode,
        title,
        body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'acg_todo_reminders',
            'ACG 提醒',
            channelDescription: '限期、停滯與每日目標提醒',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: itemId,
      );
    } catch (e) {
      Logger().w('Local notification show failed: $e');
    }
  }
}
