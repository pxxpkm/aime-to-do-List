import 'package:acg_todo/domain/entities/notification.dart';
import 'package:acg_todo/data/local/notification_store.dart';

class NotificationRepository {
  final NotificationStore _store;

  NotificationRepository(this._store);

  List<AppNotification> getAll() => _store.getAll();

  List<AppNotification> getUnsent() => _store.getUnsent();

  Future<void> schedule(AppNotification notification) async {
    await _store.put(notification);
  }

  Future<void> markSent(String id) async {
    await _store.markSent(id);
  }

  Future<void> clearAll() async {
    await _store.clearAll();
  }
}
