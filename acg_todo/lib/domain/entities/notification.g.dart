// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$AppNotificationImpl _$$AppNotificationImplFromJson(
  Map<String, dynamic> json,
) => _$AppNotificationImpl(
  id: json['id'] as String,
  itemId: json['itemId'] as String,
  type: json['type'] as String,
  scheduledAt: DateTime.parse(json['scheduledAt'] as String),
  sentAt: json['sentAt'] == null
      ? null
      : DateTime.parse(json['sentAt'] as String),
  createdAt: json['createdAt'] == null
      ? null
      : DateTime.parse(json['createdAt'] as String),
);

Map<String, dynamic> _$$AppNotificationImplToJson(
  _$AppNotificationImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'itemId': instance.itemId,
  'type': instance.type,
  'scheduledAt': instance.scheduledAt.toIso8601String(),
  'sentAt': instance.sentAt?.toIso8601String(),
  'createdAt': instance.createdAt?.toIso8601String(),
};
