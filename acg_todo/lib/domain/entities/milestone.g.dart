// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'milestone.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$MilestoneImpl _$$MilestoneImplFromJson(Map<String, dynamic> json) =>
    _$MilestoneImpl(
      id: json['id'] as String,
      itemId: json['itemId'] as String,
      label: json['label'] as String,
      percentage: (json['percentage'] as num).toInt(),
      completed: json['completed'] as bool? ?? false,
    );

Map<String, dynamic> _$$MilestoneImplToJson(_$MilestoneImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'itemId': instance.itemId,
      'label': instance.label,
      'percentage': instance.percentage,
      'completed': instance.completed,
    };
