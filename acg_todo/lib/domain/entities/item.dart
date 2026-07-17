// ignore_for_file: invalid_annotation_target

import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:acg_todo/domain/entities/pin_tier.dart';

part 'item.freezed.dart';
part 'item.g.dart';

@freezed
class Item with _$Item {
  const Item._();

  const factory Item({
    required String id,
    required String userId,
    required String type,
    int? anilistId,
    required String title,
    String? posterUrl,
    int? totalUnits,
    @Default(0) int currentUnits,
    @Default('集') String unitLabel,
    @Default('in_progress') String status,
    DateTime? deadline,
    DateTime? createdAt,
    DateTime? completedAt,
    int? bookmarkUnits,
    @Default(0) int sortOrder,
    DateTime? lastProgressAt,
    String? folderId,
    /// Folder before auto-move to completed (for restore).
    String? previousFolderId,
    /// global | custom | off
    @Default('global') String deadlineRemindMode,
    /// Comma-separated days when mode is custom, e.g. "7,3,1,0"
    String? customDeadlineOffsets,
    /// Site score 0–10 (AniList averageScore/10).
    double? score,
    int? scoreCount,
    String? summary,
    String? originalTitle,
    /// YYYY-MM-DD when known.
    String? airDate,
    /// bangumi | anilist | manual
    String? source,
    String? externalUrl,
    /// User free-form notes.
    String? remark,
    /// Personal rating 0.0–10.0 step 0.1; null = unset.
    double? userScore,
    /// Free-form user tags.
    @Default([]) List<String> tags,
    /// none | watching | priority
    @JsonKey(fromJson: pinTierFromJson, toJson: pinTierToJson)
    @Default(PinTier.none)
    PinTier pinTier,
    /// Order within the same [pinTier] (lower = first).
    @Default(0) int pinOrder,
  }) = _Item;

  factory Item.fromJson(Map<String, dynamic> json) => _$ItemFromJson(json);

  bool get isPinned => pinTier.isPinned;
}

PinTier pinTierFromJson(Object? json) {
  if (json is String) return PinTier.fromStorage(json);
  if (json is bool) return PinTier.fromStorage(null, legacyIsPinned: json);
  return PinTier.none;
}

String pinTierToJson(PinTier t) => t.name;
