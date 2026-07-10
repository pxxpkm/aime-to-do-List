import 'package:acg_todo/data/local/notification_cache.dart';
import 'package:acg_todo/data/repositories/notification_repository.dart';
import 'package:acg_todo/domain/entities/notification.dart';
import 'package:acg_todo/domain/services/deadline_service.dart';
import 'package:acg_todo/domain/services/notification_scheduler.dart';
import 'package:acg_todo/domain/services/reminder_service.dart';
import 'package:acg_todo/presentation/providers/repository_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'notification_providers.g.dart';

final notificationCacheProvider = Provider<NotificationCache>((ref) {
  throw UnimplementedError('Override in ProviderScope');
});

final deadlineServiceProvider = Provider<DeadlineService>((ref) {
  return const DeadlineService();
});

final reminderServiceProvider = Provider<ReminderService>((ref) {
  return ReminderService(
    deadlineService: ref.watch(deadlineServiceProvider),
  );
});

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  final cache = ref.watch(notificationCacheProvider);
  return NotificationRepository(cache);
});

final notificationSchedulerProvider = Provider<NotificationScheduler>((ref) {
  return NotificationScheduler(
    itemsRepo: ref.watch(itemsRepositoryProvider),
    notifCache: ref.watch(notificationCacheProvider),
    goalSettings: ref.watch(goalSettingsStoreProvider),
    deadlineService: ref.watch(deadlineServiceProvider),
    reminderService: ref.watch(reminderServiceProvider),
  );
});

/// Bumps when notifications or settings change.
final notificationsTickProvider = StateProvider<int>((ref) => 0);

@riverpod
class NotificationsNotifier extends _$NotificationsNotifier {
  @override
  List<AppNotification> build() {
    ref.watch(notificationsTickProvider);
    final repo = ref.read(notificationRepositoryProvider);
    return repo.getAll();
  }

  NotificationRepository get _repo => ref.read(notificationRepositoryProvider);
  NotificationCache get _cache => ref.read(notificationCacheProvider);

  void _tick() {
    ref.read(notificationsTickProvider.notifier).state++;
  }

  Future<void> markSent(String id) async {
    await _repo.markSent(id);
    state = _repo.getAll();
    _tick();
  }

  Future<void> clearAll() async {
    await _repo.clearAll();
    state = [];
    _tick();
  }

  Future<int> runCheck() async {
    final n =
        await ref.read(notificationSchedulerProvider).runLocalReminderCheck();
    state = _repo.getAll();
    _tick();
    return n;
  }

  Future<void> markAllSeen() async {
    await _cache.setLastSeenNow();
    _tick();
  }
}

final unreadNotificationsCountProvider = Provider<int>((ref) {
  ref.watch(notificationsTickProvider);
  ref.watch(notificationsNotifierProvider);
  return ref.watch(notificationCacheProvider).unreadCount();
});

final notificationSettingsProvider = Provider<NotificationCache>((ref) {
  ref.watch(notificationsTickProvider);
  return ref.watch(notificationCacheProvider);
});
