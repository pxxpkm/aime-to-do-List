// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'bangumi_provider.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$BangumiState {
  bool get isLoading => throw _privateConstructorUsedError;
  bool get isVerified => throw _privateConstructorUsedError;
  String? get username => throw _privateConstructorUsedError;
  String? get error => throw _privateConstructorUsedError;

  /// Create a copy of BangumiState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $BangumiStateCopyWith<BangumiState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $BangumiStateCopyWith<$Res> {
  factory $BangumiStateCopyWith(
    BangumiState value,
    $Res Function(BangumiState) then,
  ) = _$BangumiStateCopyWithImpl<$Res, BangumiState>;
  @useResult
  $Res call({bool isLoading, bool isVerified, String? username, String? error});
}

/// @nodoc
class _$BangumiStateCopyWithImpl<$Res, $Val extends BangumiState>
    implements $BangumiStateCopyWith<$Res> {
  _$BangumiStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of BangumiState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? isLoading = null,
    Object? isVerified = null,
    Object? username = freezed,
    Object? error = freezed,
  }) {
    return _then(
      _value.copyWith(
            isLoading: null == isLoading
                ? _value.isLoading
                : isLoading // ignore: cast_nullable_to_non_nullable
                      as bool,
            isVerified: null == isVerified
                ? _value.isVerified
                : isVerified // ignore: cast_nullable_to_non_nullable
                      as bool,
            username: freezed == username
                ? _value.username
                : username // ignore: cast_nullable_to_non_nullable
                      as String?,
            error: freezed == error
                ? _value.error
                : error // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$BangumiStateImplCopyWith<$Res>
    implements $BangumiStateCopyWith<$Res> {
  factory _$$BangumiStateImplCopyWith(
    _$BangumiStateImpl value,
    $Res Function(_$BangumiStateImpl) then,
  ) = __$$BangumiStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({bool isLoading, bool isVerified, String? username, String? error});
}

/// @nodoc
class __$$BangumiStateImplCopyWithImpl<$Res>
    extends _$BangumiStateCopyWithImpl<$Res, _$BangumiStateImpl>
    implements _$$BangumiStateImplCopyWith<$Res> {
  __$$BangumiStateImplCopyWithImpl(
    _$BangumiStateImpl _value,
    $Res Function(_$BangumiStateImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of BangumiState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? isLoading = null,
    Object? isVerified = null,
    Object? username = freezed,
    Object? error = freezed,
  }) {
    return _then(
      _$BangumiStateImpl(
        isLoading: null == isLoading
            ? _value.isLoading
            : isLoading // ignore: cast_nullable_to_non_nullable
                  as bool,
        isVerified: null == isVerified
            ? _value.isVerified
            : isVerified // ignore: cast_nullable_to_non_nullable
                  as bool,
        username: freezed == username
            ? _value.username
            : username // ignore: cast_nullable_to_non_nullable
                  as String?,
        error: freezed == error
            ? _value.error
            : error // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc

class _$BangumiStateImpl implements _BangumiState {
  const _$BangumiStateImpl({
    this.isLoading = false,
    this.isVerified = false,
    this.username,
    this.error,
  });

  @override
  @JsonKey()
  final bool isLoading;
  @override
  @JsonKey()
  final bool isVerified;
  @override
  final String? username;
  @override
  final String? error;

  @override
  String toString() {
    return 'BangumiState(isLoading: $isLoading, isVerified: $isVerified, username: $username, error: $error)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$BangumiStateImpl &&
            (identical(other.isLoading, isLoading) ||
                other.isLoading == isLoading) &&
            (identical(other.isVerified, isVerified) ||
                other.isVerified == isVerified) &&
            (identical(other.username, username) ||
                other.username == username) &&
            (identical(other.error, error) || other.error == error));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, isLoading, isVerified, username, error);

  /// Create a copy of BangumiState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$BangumiStateImplCopyWith<_$BangumiStateImpl> get copyWith =>
      __$$BangumiStateImplCopyWithImpl<_$BangumiStateImpl>(this, _$identity);
}

abstract class _BangumiState implements BangumiState {
  const factory _BangumiState({
    final bool isLoading,
    final bool isVerified,
    final String? username,
    final String? error,
  }) = _$BangumiStateImpl;

  @override
  bool get isLoading;
  @override
  bool get isVerified;
  @override
  String? get username;
  @override
  String? get error;

  /// Create a copy of BangumiState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$BangumiStateImplCopyWith<_$BangumiStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
