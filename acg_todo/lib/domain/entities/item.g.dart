// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ItemImpl _$$ItemImplFromJson(Map<String, dynamic> json) => _$ItemImpl(
  id: json['id'] as String,
  userId: json['userId'] as String,
  type: json['type'] as String,
  anilistId: (json['anilistId'] as num?)?.toInt(),
  title: json['title'] as String,
  posterUrl: json['posterUrl'] as String?,
  totalUnits: (json['totalUnits'] as num?)?.toInt(),
  currentUnits: (json['currentUnits'] as num?)?.toInt() ?? 0,
  unitLabel: json['unitLabel'] as String? ?? '集',
  status: json['status'] as String? ?? 'in_progress',
  deadline: json['deadline'] == null
      ? null
      : DateTime.parse(json['deadline'] as String),
  createdAt: json['createdAt'] == null
      ? null
      : DateTime.parse(json['createdAt'] as String),
  completedAt: json['completedAt'] == null
      ? null
      : DateTime.parse(json['completedAt'] as String),
  bookmarkUnits: (json['bookmarkUnits'] as num?)?.toInt(),
  sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
  lastProgressAt: json['lastProgressAt'] == null
      ? null
      : DateTime.parse(json['lastProgressAt'] as String),
  folderId: json['folderId'] as String?,
  previousFolderId: json['previousFolderId'] as String?,
  deadlineRemindMode: json['deadlineRemindMode'] as String? ?? 'global',
  customDeadlineOffsets: json['customDeadlineOffsets'] as String?,
  score: (json['score'] as num?)?.toDouble(),
  scoreCount: (json['scoreCount'] as num?)?.toInt(),
  summary: json['summary'] as String?,
  originalTitle: json['originalTitle'] as String?,
  airDate: json['airDate'] as String?,
  source: json['source'] as String?,
  externalUrl: json['externalUrl'] as String?,
  remark: json['remark'] as String?,
  userScore: (json['userScore'] as num?)?.toDouble(),
  tags:
      (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
  pinTier: json['pinTier'] == null
      ? PinTier.none
      : pinTierFromJson(json['pinTier']),
  pinOrder: (json['pinOrder'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$$ItemImplToJson(_$ItemImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'type': instance.type,
      'anilistId': instance.anilistId,
      'title': instance.title,
      'posterUrl': instance.posterUrl,
      'totalUnits': instance.totalUnits,
      'currentUnits': instance.currentUnits,
      'unitLabel': instance.unitLabel,
      'status': instance.status,
      'deadline': instance.deadline?.toIso8601String(),
      'createdAt': instance.createdAt?.toIso8601String(),
      'completedAt': instance.completedAt?.toIso8601String(),
      'bookmarkUnits': instance.bookmarkUnits,
      'sortOrder': instance.sortOrder,
      'lastProgressAt': instance.lastProgressAt?.toIso8601String(),
      'folderId': instance.folderId,
      'previousFolderId': instance.previousFolderId,
      'deadlineRemindMode': instance.deadlineRemindMode,
      'customDeadlineOffsets': instance.customDeadlineOffsets,
      'score': instance.score,
      'scoreCount': instance.scoreCount,
      'summary': instance.summary,
      'originalTitle': instance.originalTitle,
      'airDate': instance.airDate,
      'source': instance.source,
      'externalUrl': instance.externalUrl,
      'remark': instance.remark,
      'userScore': instance.userScore,
      'tags': instance.tags,
      'pinTier': pinTierToJson(instance.pinTier),
      'pinOrder': instance.pinOrder,
    };
