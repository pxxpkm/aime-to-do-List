import 'package:acg_todo/domain/entities/notification.dart';
import 'package:acg_todo/data/local/notification_cache.dart';

class NotificationRepository {
  final NotificationCache _cache;

  NotificationRepository(this._cache);

  List<AppNotification> getAll() => _cache.getAll();

  List<AppNotification> getUnsent() => _cache.getUnsent();

  Future<void> schedule(AppNotification notification) async {
    await _cache.put(notification);
  }

  Future<void> markSent(String id) async {
    await _cache.markSent(id);
  }

  Future<void> clearAll() async {
    await _cache.clearAll();
  }
}
