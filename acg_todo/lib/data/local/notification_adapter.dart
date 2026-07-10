import 'package:acg_todo/domain/entities/notification.dart';
import 'package:hive_flutter/hive_flutter.dart';

class NotificationAdapter extends TypeAdapter<AppNotification> {
  @override
  final int typeId = 1;

  @override
  AppNotification read(BinaryReader reader) {
    final fields = reader.readMap();
    return AppNotification(
      id: fields['id'] as String,
      itemId: fields['itemId'] as String,
      type: fields['type'] as String,
      scheduledAt: DateTime.parse(fields['scheduledAt'] as String),
      sentAt: fields['sentAt'] != null
          ? DateTime.parse(fields['sentAt'] as String)
          : null,
      createdAt: fields['createdAt'] != null
          ? DateTime.parse(fields['createdAt'] as String)
          : null,
    );
  }

  @override
  void write(BinaryWriter writer, AppNotification obj) {
    writer.writeMap({
      'id': obj.id,
      'itemId': obj.itemId,
      'type': obj.type,
      'scheduledAt': obj.scheduledAt.toIso8601String(),
      'sentAt': obj.sentAt?.toIso8601String(),
      'createdAt': obj.createdAt?.toIso8601String(),
    });
  }
}
