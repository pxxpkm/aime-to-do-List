import 'package:acg_todo/domain/entities/item.dart';
import 'package:hive_flutter/hive_flutter.dart';

class ItemAdapter extends TypeAdapter<Item> {
  @override
  final int typeId = 0;

  @override
  Item read(BinaryReader reader) {
    final fields = reader.readMap();
    return Item(
      id: fields['id'] as String,
      userId: fields['userId'] as String,
      type: fields['type'] as String,
      anilistId: fields['anilistId'] as int?,
      title: fields['title'] as String,
      posterUrl: fields['posterUrl'] as String?,
      totalUnits: fields['totalUnits'] as int?,
      currentUnits: fields['currentUnits'] as int? ?? 0,
      unitLabel: fields['unitLabel'] as String? ?? '集',
      status: fields['status'] as String? ?? 'in_progress',
      deadline: fields['deadline'] != null
          ? DateTime.parse(fields['deadline'] as String)
          : null,
      createdAt: fields['createdAt'] != null
          ? DateTime.parse(fields['createdAt'] as String)
          : null,
      completedAt: fields['completedAt'] != null
          ? DateTime.parse(fields['completedAt'] as String)
          : null,
      bookmarkUnits: fields['bookmarkUnits'] as int?,
      sortOrder: fields['sortOrder'] as int? ?? 0,
      lastProgressAt: fields['lastProgressAt'] != null
          ? DateTime.parse(fields['lastProgressAt'] as String)
          : null,
      folderId: fields['folderId'] as String?,
      previousFolderId: fields['previousFolderId'] as String?,
      deadlineRemindMode: fields['deadlineRemindMode'] as String? ?? 'global',
      customDeadlineOffsets: fields['customDeadlineOffsets'] as String?,
      score: (fields['score'] as num?)?.toDouble(),
      scoreCount: fields['scoreCount'] as int?,
      summary: fields['summary'] as String?,
      originalTitle: fields['originalTitle'] as String?,
      airDate: fields['airDate'] as String?,
      source: fields['source'] as String?,
      externalUrl: fields['externalUrl'] as String?,
      remark: fields['remark'] as String?,
      userScore: (fields['userScore'] as num?)?.toDouble(),
      tags: _readTags(fields['tags']),
    );
  }

  static List<String> _readTags(dynamic raw) {
    if (raw is List) {
      return raw.map((e) => e.toString()).where((s) => s.isNotEmpty).toList();
    }
    return const [];
  }

  @override
  void write(BinaryWriter writer, Item obj) {
    writer.writeMap({
      'id': obj.id,
      'userId': obj.userId,
      'type': obj.type,
      'anilistId': obj.anilistId,
      'title': obj.title,
      'posterUrl': obj.posterUrl,
      'totalUnits': obj.totalUnits,
      'currentUnits': obj.currentUnits,
      'unitLabel': obj.unitLabel,
      'status': obj.status,
      'deadline': obj.deadline?.toIso8601String(),
      'createdAt': obj.createdAt?.toIso8601String(),
      'completedAt': obj.completedAt?.toIso8601String(),
      'bookmarkUnits': obj.bookmarkUnits,
      'sortOrder': obj.sortOrder,
      'lastProgressAt': obj.lastProgressAt?.toIso8601String(),
      'folderId': obj.folderId,
      'previousFolderId': obj.previousFolderId,
      'deadlineRemindMode': obj.deadlineRemindMode,
      'customDeadlineOffsets': obj.customDeadlineOffsets,
      'score': obj.score,
      'scoreCount': obj.scoreCount,
      'summary': obj.summary,
      'originalTitle': obj.originalTitle,
      'airDate': obj.airDate,
      'source': obj.source,
      'externalUrl': obj.externalUrl,
      'remark': obj.remark,
      'userScore': obj.userScore,
      'tags': obj.tags,
    });
  }
}
