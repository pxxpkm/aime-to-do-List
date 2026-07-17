// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'item.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

Item _$ItemFromJson(Map<String, dynamic> json) {
  return _Item.fromJson(json);
}

/// @nodoc
mixin _$Item {
  String get id => throw _privateConstructorUsedError;
  String get userId => throw _privateConstructorUsedError;
  String get type => throw _privateConstructorUsedError;
  int? get anilistId => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  String? get posterUrl => throw _privateConstructorUsedError;
  int? get totalUnits => throw _privateConstructorUsedError;
  int get currentUnits => throw _privateConstructorUsedError;
  String get unitLabel => throw _privateConstructorUsedError;
  String get status => throw _privateConstructorUsedError;
  DateTime? get deadline => throw _privateConstructorUsedError;
  DateTime? get createdAt => throw _privateConstructorUsedError;
  DateTime? get completedAt => throw _privateConstructorUsedError;
  int? get bookmarkUnits => throw _privateConstructorUsedError;
  int get sortOrder => throw _privateConstructorUsedError;
  DateTime? get lastProgressAt => throw _privateConstructorUsedError;
  String? get folderId => throw _privateConstructorUsedError;

  /// Folder before auto-move to completed (for restore).
  String? get previousFolderId => throw _privateConstructorUsedError;

  /// global | custom | off
  String get deadlineRemindMode => throw _privateConstructorUsedError;

  /// Comma-separated days when mode is custom, e.g. "7,3,1,0"
  String? get customDeadlineOffsets => throw _privateConstructorUsedError;

  /// Site score 0–10 (AniList averageScore/10).
  double? get score => throw _privateConstructorUsedError;
  int? get scoreCount => throw _privateConstructorUsedError;
  String? get summary => throw _privateConstructorUsedError;
  String? get originalTitle => throw _privateConstructorUsedError;

  /// YYYY-MM-DD when known.
  String? get airDate => throw _privateConstructorUsedError;

  /// bangumi | anilist | manual
  String? get source => throw _privateConstructorUsedError;
  String? get externalUrl => throw _privateConstructorUsedError;

  /// User free-form notes.
  String? get remark => throw _privateConstructorUsedError;

  /// Personal rating 0.0–10.0 step 0.1; null = unset.
  double? get userScore => throw _privateConstructorUsedError;

  /// Free-form user tags.
  List<String> get tags => throw _privateConstructorUsedError;

  /// none | watching | priority
  @JsonKey(fromJson: pinTierFromJson, toJson: pinTierToJson)
  PinTier get pinTier => throw _privateConstructorUsedError;

  /// Order within the same [pinTier] (lower = first).
  int get pinOrder => throw _privateConstructorUsedError;

  /// Serializes this Item to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Item
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ItemCopyWith<Item> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ItemCopyWith<$Res> {
  factory $ItemCopyWith(Item value, $Res Function(Item) then) =
      _$ItemCopyWithImpl<$Res, Item>;
  @useResult
  $Res call({
    String id,
    String userId,
    String type,
    int? anilistId,
    String title,
    String? posterUrl,
    int? totalUnits,
    int currentUnits,
    String unitLabel,
    String status,
    DateTime? deadline,
    DateTime? createdAt,
    DateTime? completedAt,
    int? bookmarkUnits,
    int sortOrder,
    DateTime? lastProgressAt,
    String? folderId,
    String? previousFolderId,
    String deadlineRemindMode,
    String? customDeadlineOffsets,
    double? score,
    int? scoreCount,
    String? summary,
    String? originalTitle,
    String? airDate,
    String? source,
    String? externalUrl,
    String? remark,
    double? userScore,
    List<String> tags,
    @JsonKey(fromJson: pinTierFromJson, toJson: pinTierToJson) PinTier pinTier,
    int pinOrder,
  });
}

/// @nodoc
class _$ItemCopyWithImpl<$Res, $Val extends Item>
    implements $ItemCopyWith<$Res> {
  _$ItemCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Item
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? type = null,
    Object? anilistId = freezed,
    Object? title = null,
    Object? posterUrl = freezed,
    Object? totalUnits = freezed,
    Object? currentUnits = null,
    Object? unitLabel = null,
    Object? status = null,
    Object? deadline = freezed,
    Object? createdAt = freezed,
    Object? completedAt = freezed,
    Object? bookmarkUnits = freezed,
    Object? sortOrder = null,
    Object? lastProgressAt = freezed,
    Object? folderId = freezed,
    Object? previousFolderId = freezed,
    Object? deadlineRemindMode = null,
    Object? customDeadlineOffsets = freezed,
    Object? score = freezed,
    Object? scoreCount = freezed,
    Object? summary = freezed,
    Object? originalTitle = freezed,
    Object? airDate = freezed,
    Object? source = freezed,
    Object? externalUrl = freezed,
    Object? remark = freezed,
    Object? userScore = freezed,
    Object? tags = null,
    Object? pinTier = null,
    Object? pinOrder = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            userId: null == userId
                ? _value.userId
                : userId // ignore: cast_nullable_to_non_nullable
                      as String,
            type: null == type
                ? _value.type
                : type // ignore: cast_nullable_to_non_nullable
                      as String,
            anilistId: freezed == anilistId
                ? _value.anilistId
                : anilistId // ignore: cast_nullable_to_non_nullable
                      as int?,
            title: null == title
                ? _value.title
                : title // ignore: cast_nullable_to_non_nullable
                      as String,
            posterUrl: freezed == posterUrl
                ? _value.posterUrl
                : posterUrl // ignore: cast_nullable_to_non_nullable
                      as String?,
            totalUnits: freezed == totalUnits
                ? _value.totalUnits
                : totalUnits // ignore: cast_nullable_to_non_nullable
                      as int?,
            currentUnits: null == currentUnits
                ? _value.currentUnits
                : currentUnits // ignore: cast_nullable_to_non_nullable
                      as int,
            unitLabel: null == unitLabel
                ? _value.unitLabel
                : unitLabel // ignore: cast_nullable_to_non_nullable
                      as String,
            status: null == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                      as String,
            deadline: freezed == deadline
                ? _value.deadline
                : deadline // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            createdAt: freezed == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            completedAt: freezed == completedAt
                ? _value.completedAt
                : completedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            bookmarkUnits: freezed == bookmarkUnits
                ? _value.bookmarkUnits
                : bookmarkUnits // ignore: cast_nullable_to_non_nullable
                      as int?,
            sortOrder: null == sortOrder
                ? _value.sortOrder
                : sortOrder // ignore: cast_nullable_to_non_nullable
                      as int,
            lastProgressAt: freezed == lastProgressAt
                ? _value.lastProgressAt
                : lastProgressAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            folderId: freezed == folderId
                ? _value.folderId
                : folderId // ignore: cast_nullable_to_non_nullable
                      as String?,
            previousFolderId: freezed == previousFolderId
                ? _value.previousFolderId
                : previousFolderId // ignore: cast_nullable_to_non_nullable
                      as String?,
            deadlineRemindMode: null == deadlineRemindMode
                ? _value.deadlineRemindMode
                : deadlineRemindMode // ignore: cast_nullable_to_non_nullable
                      as String,
            customDeadlineOffsets: freezed == customDeadlineOffsets
                ? _value.customDeadlineOffsets
                : customDeadlineOffsets // ignore: cast_nullable_to_non_nullable
                      as String?,
            score: freezed == score
                ? _value.score
                : score // ignore: cast_nullable_to_non_nullable
                      as double?,
            scoreCount: freezed == scoreCount
                ? _value.scoreCount
                : scoreCount // ignore: cast_nullable_to_non_nullable
                      as int?,
            summary: freezed == summary
                ? _value.summary
                : summary // ignore: cast_nullable_to_non_nullable
                      as String?,
            originalTitle: freezed == originalTitle
                ? _value.originalTitle
                : originalTitle // ignore: cast_nullable_to_non_nullable
                      as String?,
            airDate: freezed == airDate
                ? _value.airDate
                : airDate // ignore: cast_nullable_to_non_nullable
                      as String?,
            source: freezed == source
                ? _value.source
                : source // ignore: cast_nullable_to_non_nullable
                      as String?,
            externalUrl: freezed == externalUrl
                ? _value.externalUrl
                : externalUrl // ignore: cast_nullable_to_non_nullable
                      as String?,
            remark: freezed == remark
                ? _value.remark
                : remark // ignore: cast_nullable_to_non_nullable
                      as String?,
            userScore: freezed == userScore
                ? _value.userScore
                : userScore // ignore: cast_nullable_to_non_nullable
                      as double?,
            tags: null == tags
                ? _value.tags
                : tags // ignore: cast_nullable_to_non_nullable
                      as List<String>,
            pinTier: null == pinTier
                ? _value.pinTier
                : pinTier // ignore: cast_nullable_to_non_nullable
                      as PinTier,
            pinOrder: null == pinOrder
                ? _value.pinOrder
                : pinOrder // ignore: cast_nullable_to_non_nullable
                      as int,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$ItemImplCopyWith<$Res> implements $ItemCopyWith<$Res> {
  factory _$$ItemImplCopyWith(
    _$ItemImpl value,
    $Res Function(_$ItemImpl) then,
  ) = __$$ItemImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String userId,
    String type,
    int? anilistId,
    String title,
    String? posterUrl,
    int? totalUnits,
    int currentUnits,
    String unitLabel,
    String status,
    DateTime? deadline,
    DateTime? createdAt,
    DateTime? completedAt,
    int? bookmarkUnits,
    int sortOrder,
    DateTime? lastProgressAt,
    String? folderId,
    String? previousFolderId,
    String deadlineRemindMode,
    String? customDeadlineOffsets,
    double? score,
    int? scoreCount,
    String? summary,
    String? originalTitle,
    String? airDate,
    String? source,
    String? externalUrl,
    String? remark,
    double? userScore,
    List<String> tags,
    @JsonKey(fromJson: pinTierFromJson, toJson: pinTierToJson) PinTier pinTier,
    int pinOrder,
  });
}

/// @nodoc
class __$$ItemImplCopyWithImpl<$Res>
    extends _$ItemCopyWithImpl<$Res, _$ItemImpl>
    implements _$$ItemImplCopyWith<$Res> {
  __$$ItemImplCopyWithImpl(_$ItemImpl _value, $Res Function(_$ItemImpl) _then)
    : super(_value, _then);

  /// Create a copy of Item
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? type = null,
    Object? anilistId = freezed,
    Object? title = null,
    Object? posterUrl = freezed,
    Object? totalUnits = freezed,
    Object? currentUnits = null,
    Object? unitLabel = null,
    Object? status = null,
    Object? deadline = freezed,
    Object? createdAt = freezed,
    Object? completedAt = freezed,
    Object? bookmarkUnits = freezed,
    Object? sortOrder = null,
    Object? lastProgressAt = freezed,
    Object? folderId = freezed,
    Object? previousFolderId = freezed,
    Object? deadlineRemindMode = null,
    Object? customDeadlineOffsets = freezed,
    Object? score = freezed,
    Object? scoreCount = freezed,
    Object? summary = freezed,
    Object? originalTitle = freezed,
    Object? airDate = freezed,
    Object? source = freezed,
    Object? externalUrl = freezed,
    Object? remark = freezed,
    Object? userScore = freezed,
    Object? tags = null,
    Object? pinTier = null,
    Object? pinOrder = null,
  }) {
    return _then(
      _$ItemImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        userId: null == userId
            ? _value.userId
            : userId // ignore: cast_nullable_to_non_nullable
                  as String,
        type: null == type
            ? _value.type
            : type // ignore: cast_nullable_to_non_nullable
                  as String,
        anilistId: freezed == anilistId
            ? _value.anilistId
            : anilistId // ignore: cast_nullable_to_non_nullable
                  as int?,
        title: null == title
            ? _value.title
            : title // ignore: cast_nullable_to_non_nullable
                  as String,
        posterUrl: freezed == posterUrl
            ? _value.posterUrl
            : posterUrl // ignore: cast_nullable_to_non_nullable
                  as String?,
        totalUnits: freezed == totalUnits
            ? _value.totalUnits
            : totalUnits // ignore: cast_nullable_to_non_nullable
                  as int?,
        currentUnits: null == currentUnits
            ? _value.currentUnits
            : currentUnits // ignore: cast_nullable_to_non_nullable
                  as int,
        unitLabel: null == unitLabel
            ? _value.unitLabel
            : unitLabel // ignore: cast_nullable_to_non_nullable
                  as String,
        status: null == status
            ? _value.status
            : status // ignore: cast_nullable_to_non_nullable
                  as String,
        deadline: freezed == deadline
            ? _value.deadline
            : deadline // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        createdAt: freezed == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        completedAt: freezed == completedAt
            ? _value.completedAt
            : completedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        bookmarkUnits: freezed == bookmarkUnits
            ? _value.bookmarkUnits
            : bookmarkUnits // ignore: cast_nullable_to_non_nullable
                  as int?,
        sortOrder: null == sortOrder
            ? _value.sortOrder
            : sortOrder // ignore: cast_nullable_to_non_nullable
                  as int,
        lastProgressAt: freezed == lastProgressAt
            ? _value.lastProgressAt
            : lastProgressAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        folderId: freezed == folderId
            ? _value.folderId
            : folderId // ignore: cast_nullable_to_non_nullable
                  as String?,
        previousFolderId: freezed == previousFolderId
            ? _value.previousFolderId
            : previousFolderId // ignore: cast_nullable_to_non_nullable
                  as String?,
        deadlineRemindMode: null == deadlineRemindMode
            ? _value.deadlineRemindMode
            : deadlineRemindMode // ignore: cast_nullable_to_non_nullable
                  as String,
        customDeadlineOffsets: freezed == customDeadlineOffsets
            ? _value.customDeadlineOffsets
            : customDeadlineOffsets // ignore: cast_nullable_to_non_nullable
                  as String?,
        score: freezed == score
            ? _value.score
            : score // ignore: cast_nullable_to_non_nullable
                  as double?,
        scoreCount: freezed == scoreCount
            ? _value.scoreCount
            : scoreCount // ignore: cast_nullable_to_non_nullable
                  as int?,
        summary: freezed == summary
            ? _value.summary
            : summary // ignore: cast_nullable_to_non_nullable
                  as String?,
        originalTitle: freezed == originalTitle
            ? _value.originalTitle
            : originalTitle // ignore: cast_nullable_to_non_nullable
                  as String?,
        airDate: freezed == airDate
            ? _value.airDate
            : airDate // ignore: cast_nullable_to_non_nullable
                  as String?,
        source: freezed == source
            ? _value.source
            : source // ignore: cast_nullable_to_non_nullable
                  as String?,
        externalUrl: freezed == externalUrl
            ? _value.externalUrl
            : externalUrl // ignore: cast_nullable_to_non_nullable
                  as String?,
        remark: freezed == remark
            ? _value.remark
            : remark // ignore: cast_nullable_to_non_nullable
                  as String?,
        userScore: freezed == userScore
            ? _value.userScore
            : userScore // ignore: cast_nullable_to_non_nullable
                  as double?,
        tags: null == tags
            ? _value._tags
            : tags // ignore: cast_nullable_to_non_nullable
                  as List<String>,
        pinTier: null == pinTier
            ? _value.pinTier
            : pinTier // ignore: cast_nullable_to_non_nullable
                  as PinTier,
        pinOrder: null == pinOrder
            ? _value.pinOrder
            : pinOrder // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$ItemImpl extends _Item {
  const _$ItemImpl({
    required this.id,
    required this.userId,
    required this.type,
    this.anilistId,
    required this.title,
    this.posterUrl,
    this.totalUnits,
    this.currentUnits = 0,
    this.unitLabel = '集',
    this.status = 'in_progress',
    this.deadline,
    this.createdAt,
    this.completedAt,
    this.bookmarkUnits,
    this.sortOrder = 0,
    this.lastProgressAt,
    this.folderId,
    this.previousFolderId,
    this.deadlineRemindMode = 'global',
    this.customDeadlineOffsets,
    this.score,
    this.scoreCount,
    this.summary,
    this.originalTitle,
    this.airDate,
    this.source,
    this.externalUrl,
    this.remark,
    this.userScore,
    final List<String> tags = const [],
    @JsonKey(fromJson: pinTierFromJson, toJson: pinTierToJson)
    this.pinTier = PinTier.none,
    this.pinOrder = 0,
  }) : _tags = tags,
       super._();

  factory _$ItemImpl.fromJson(Map<String, dynamic> json) =>
      _$$ItemImplFromJson(json);

  @override
  final String id;
  @override
  final String userId;
  @override
  final String type;
  @override
  final int? anilistId;
  @override
  final String title;
  @override
  final String? posterUrl;
  @override
  final int? totalUnits;
  @override
  @JsonKey()
  final int currentUnits;
  @override
  @JsonKey()
  final String unitLabel;
  @override
  @JsonKey()
  final String status;
  @override
  final DateTime? deadline;
  @override
  final DateTime? createdAt;
  @override
  final DateTime? completedAt;
  @override
  final int? bookmarkUnits;
  @override
  @JsonKey()
  final int sortOrder;
  @override
  final DateTime? lastProgressAt;
  @override
  final String? folderId;

  /// Folder before auto-move to completed (for restore).
  @override
  final String? previousFolderId;

  /// global | custom | off
  @override
  @JsonKey()
  final String deadlineRemindMode;

  /// Comma-separated days when mode is custom, e.g. "7,3,1,0"
  @override
  final String? customDeadlineOffsets;

  /// Site score 0–10 (AniList averageScore/10).
  @override
  final double? score;
  @override
  final int? scoreCount;
  @override
  final String? summary;
  @override
  final String? originalTitle;

  /// YYYY-MM-DD when known.
  @override
  final String? airDate;

  /// bangumi | anilist | manual
  @override
  final String? source;
  @override
  final String? externalUrl;

  /// User free-form notes.
  @override
  final String? remark;

  /// Personal rating 0.0–10.0 step 0.1; null = unset.
  @override
  final double? userScore;

  /// Free-form user tags.
  final List<String> _tags;

  /// Free-form user tags.
  @override
  @JsonKey()
  List<String> get tags {
    if (_tags is EqualUnmodifiableListView) return _tags;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_tags);
  }

  /// none | watching | priority
  @override
  @JsonKey(fromJson: pinTierFromJson, toJson: pinTierToJson)
  final PinTier pinTier;

  /// Order within the same [pinTier] (lower = first).
  @override
  @JsonKey()
  final int pinOrder;

  @override
  String toString() {
    return 'Item(id: $id, userId: $userId, type: $type, anilistId: $anilistId, title: $title, posterUrl: $posterUrl, totalUnits: $totalUnits, currentUnits: $currentUnits, unitLabel: $unitLabel, status: $status, deadline: $deadline, createdAt: $createdAt, completedAt: $completedAt, bookmarkUnits: $bookmarkUnits, sortOrder: $sortOrder, lastProgressAt: $lastProgressAt, folderId: $folderId, previousFolderId: $previousFolderId, deadlineRemindMode: $deadlineRemindMode, customDeadlineOffsets: $customDeadlineOffsets, score: $score, scoreCount: $scoreCount, summary: $summary, originalTitle: $originalTitle, airDate: $airDate, source: $source, externalUrl: $externalUrl, remark: $remark, userScore: $userScore, tags: $tags, pinTier: $pinTier, pinOrder: $pinOrder)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ItemImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.anilistId, anilistId) ||
                other.anilistId == anilistId) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.posterUrl, posterUrl) ||
                other.posterUrl == posterUrl) &&
            (identical(other.totalUnits, totalUnits) ||
                other.totalUnits == totalUnits) &&
            (identical(other.currentUnits, currentUnits) ||
                other.currentUnits == currentUnits) &&
            (identical(other.unitLabel, unitLabel) ||
                other.unitLabel == unitLabel) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.deadline, deadline) ||
                other.deadline == deadline) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.completedAt, completedAt) ||
                other.completedAt == completedAt) &&
            (identical(other.bookmarkUnits, bookmarkUnits) ||
                other.bookmarkUnits == bookmarkUnits) &&
            (identical(other.sortOrder, sortOrder) ||
                other.sortOrder == sortOrder) &&
            (identical(other.lastProgressAt, lastProgressAt) ||
                other.lastProgressAt == lastProgressAt) &&
            (identical(other.folderId, folderId) ||
                other.folderId == folderId) &&
            (identical(other.previousFolderId, previousFolderId) ||
                other.previousFolderId == previousFolderId) &&
            (identical(other.deadlineRemindMode, deadlineRemindMode) ||
                other.deadlineRemindMode == deadlineRemindMode) &&
            (identical(other.customDeadlineOffsets, customDeadlineOffsets) ||
                other.customDeadlineOffsets == customDeadlineOffsets) &&
            (identical(other.score, score) || other.score == score) &&
            (identical(other.scoreCount, scoreCount) ||
                other.scoreCount == scoreCount) &&
            (identical(other.summary, summary) || other.summary == summary) &&
            (identical(other.originalTitle, originalTitle) ||
                other.originalTitle == originalTitle) &&
            (identical(other.airDate, airDate) || other.airDate == airDate) &&
            (identical(other.source, source) || other.source == source) &&
            (identical(other.externalUrl, externalUrl) ||
                other.externalUrl == externalUrl) &&
            (identical(other.remark, remark) || other.remark == remark) &&
            (identical(other.userScore, userScore) ||
                other.userScore == userScore) &&
            const DeepCollectionEquality().equals(other._tags, _tags) &&
            (identical(other.pinTier, pinTier) || other.pinTier == pinTier) &&
            (identical(other.pinOrder, pinOrder) ||
                other.pinOrder == pinOrder));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hashAll([
    runtimeType,
    id,
    userId,
    type,
    anilistId,
    title,
    posterUrl,
    totalUnits,
    currentUnits,
    unitLabel,
    status,
    deadline,
    createdAt,
    completedAt,
    bookmarkUnits,
    sortOrder,
    lastProgressAt,
    folderId,
    previousFolderId,
    deadlineRemindMode,
    customDeadlineOffsets,
    score,
    scoreCount,
    summary,
    originalTitle,
    airDate,
    source,
    externalUrl,
    remark,
    userScore,
    const DeepCollectionEquality().hash(_tags),
    pinTier,
    pinOrder,
  ]);

  /// Create a copy of Item
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ItemImplCopyWith<_$ItemImpl> get copyWith =>
      __$$ItemImplCopyWithImpl<_$ItemImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ItemImplToJson(this);
  }
}

abstract class _Item extends Item {
  const factory _Item({
    required final String id,
    required final String userId,
    required final String type,
    final int? anilistId,
    required final String title,
    final String? posterUrl,
    final int? totalUnits,
    final int currentUnits,
    final String unitLabel,
    final String status,
    final DateTime? deadline,
    final DateTime? createdAt,
    final DateTime? completedAt,
    final int? bookmarkUnits,
    final int sortOrder,
    final DateTime? lastProgressAt,
    final String? folderId,
    final String? previousFolderId,
    final String deadlineRemindMode,
    final String? customDeadlineOffsets,
    final double? score,
    final int? scoreCount,
    final String? summary,
    final String? originalTitle,
    final String? airDate,
    final String? source,
    final String? externalUrl,
    final String? remark,
    final double? userScore,
    final List<String> tags,
    @JsonKey(fromJson: pinTierFromJson, toJson: pinTierToJson)
    final PinTier pinTier,
    final int pinOrder,
  }) = _$ItemImpl;
  const _Item._() : super._();

  factory _Item.fromJson(Map<String, dynamic> json) = _$ItemImpl.fromJson;

  @override
  String get id;
  @override
  String get userId;
  @override
  String get type;
  @override
  int? get anilistId;
  @override
  String get title;
  @override
  String? get posterUrl;
  @override
  int? get totalUnits;
  @override
  int get currentUnits;
  @override
  String get unitLabel;
  @override
  String get status;
  @override
  DateTime? get deadline;
  @override
  DateTime? get createdAt;
  @override
  DateTime? get completedAt;
  @override
  int? get bookmarkUnits;
  @override
  int get sortOrder;
  @override
  DateTime? get lastProgressAt;
  @override
  String? get folderId;

  /// Folder before auto-move to completed (for restore).
  @override
  String? get previousFolderId;

  /// global | custom | off
  @override
  String get deadlineRemindMode;

  /// Comma-separated days when mode is custom, e.g. "7,3,1,0"
  @override
  String? get customDeadlineOffsets;

  /// Site score 0–10 (AniList averageScore/10).
  @override
  double? get score;
  @override
  int? get scoreCount;
  @override
  String? get summary;
  @override
  String? get originalTitle;

  /// YYYY-MM-DD when known.
  @override
  String? get airDate;

  /// bangumi | anilist | manual
  @override
  String? get source;
  @override
  String? get externalUrl;

  /// User free-form notes.
  @override
  String? get remark;

  /// Personal rating 0.0–10.0 step 0.1; null = unset.
  @override
  double? get userScore;

  /// Free-form user tags.
  @override
  List<String> get tags;

  /// none | watching | priority
  @override
  @JsonKey(fromJson: pinTierFromJson, toJson: pinTierToJson)
  PinTier get pinTier;

  /// Order within the same [pinTier] (lower = first).
  @override
  int get pinOrder;

  /// Create a copy of Item
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ItemImplCopyWith<_$ItemImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
