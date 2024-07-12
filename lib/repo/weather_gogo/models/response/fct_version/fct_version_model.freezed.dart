// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target

part of 'fct_version_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#custom-getters-and-methods');

FctVersionModel _$FctVersionModelFromJson(Map<String, dynamic> json) {
  return _FctVersionModel.fromJson(json);
}

/// @nodoc
mixin _$FctVersionModel {
  /// 예보버전 조회
  @JsonKey(name: 'response')
  ResponseFctVersion? get response => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $FctVersionModelCopyWith<FctVersionModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $FctVersionModelCopyWith<$Res> {
  factory $FctVersionModelCopyWith(
          FctVersionModel value, $Res Function(FctVersionModel) then) =
      _$FctVersionModelCopyWithImpl<$Res, FctVersionModel>;
  @useResult
  $Res call({@JsonKey(name: 'response') ResponseFctVersion? response});

  $ResponseFctVersionCopyWith<$Res>? get response;
}

/// @nodoc
class _$FctVersionModelCopyWithImpl<$Res, $Val extends FctVersionModel>
    implements $FctVersionModelCopyWith<$Res> {
  _$FctVersionModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? response = freezed,
  }) {
    return _then(_value.copyWith(
      response: freezed == response
          ? _value.response
          : response // ignore: cast_nullable_to_non_nullable
              as ResponseFctVersion?,
    ) as $Val);
  }

  @override
  @pragma('vm:prefer-inline')
  $ResponseFctVersionCopyWith<$Res>? get response {
    if (_value.response == null) {
      return null;
    }

    return $ResponseFctVersionCopyWith<$Res>(_value.response!, (value) {
      return _then(_value.copyWith(response: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$_FctVersionModelCopyWith<$Res>
    implements $FctVersionModelCopyWith<$Res> {
  factory _$$_FctVersionModelCopyWith(
          _$_FctVersionModel value, $Res Function(_$_FctVersionModel) then) =
      __$$_FctVersionModelCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({@JsonKey(name: 'response') ResponseFctVersion? response});

  @override
  $ResponseFctVersionCopyWith<$Res>? get response;
}

/// @nodoc
class __$$_FctVersionModelCopyWithImpl<$Res>
    extends _$FctVersionModelCopyWithImpl<$Res, _$_FctVersionModel>
    implements _$$_FctVersionModelCopyWith<$Res> {
  __$$_FctVersionModelCopyWithImpl(
      _$_FctVersionModel _value, $Res Function(_$_FctVersionModel) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? response = freezed,
  }) {
    return _then(_$_FctVersionModel(
      response: freezed == response
          ? _value.response
          : response // ignore: cast_nullable_to_non_nullable
              as ResponseFctVersion?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$_FctVersionModel implements _FctVersionModel {
  const _$_FctVersionModel({@JsonKey(name: 'response') this.response});

  factory _$_FctVersionModel.fromJson(Map<String, dynamic> json) =>
      _$$_FctVersionModelFromJson(json);

  /// 예보버전 조회
  @override
  @JsonKey(name: 'response')
  final ResponseFctVersion? response;

  @override
  String toString() {
    return 'FctVersionModel(response: $response)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$_FctVersionModel &&
            (identical(other.response, response) ||
                other.response == response));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, response);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$_FctVersionModelCopyWith<_$_FctVersionModel> get copyWith =>
      __$$_FctVersionModelCopyWithImpl<_$_FctVersionModel>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$_FctVersionModelToJson(
      this,
    );
  }
}

abstract class _FctVersionModel implements FctVersionModel {
  const factory _FctVersionModel(
          {@JsonKey(name: 'response') final ResponseFctVersion? response}) =
      _$_FctVersionModel;

  factory _FctVersionModel.fromJson(Map<String, dynamic> json) =
      _$_FctVersionModel.fromJson;

  @override

  /// 예보버전 조회
  @JsonKey(name: 'response')
  ResponseFctVersion? get response;
  @override
  @JsonKey(ignore: true)
  _$$_FctVersionModelCopyWith<_$_FctVersionModel> get copyWith =>
      throw _privateConstructorUsedError;
}

ResponseFctVersion _$ResponseFctVersionFromJson(Map<String, dynamic> json) {
  return _ResponseFctVersion.fromJson(json);
}

/// @nodoc
mixin _$ResponseFctVersion {
  @JsonKey(name: 'header')
  HeaderFctVersion? get header => throw _privateConstructorUsedError;
  @JsonKey(name: 'body')
  BodyFctVersion? get body => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $ResponseFctVersionCopyWith<ResponseFctVersion> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ResponseFctVersionCopyWith<$Res> {
  factory $ResponseFctVersionCopyWith(
          ResponseFctVersion value, $Res Function(ResponseFctVersion) then) =
      _$ResponseFctVersionCopyWithImpl<$Res, ResponseFctVersion>;
  @useResult
  $Res call(
      {@JsonKey(name: 'header') HeaderFctVersion? header,
      @JsonKey(name: 'body') BodyFctVersion? body});

  $HeaderFctVersionCopyWith<$Res>? get header;
  $BodyFctVersionCopyWith<$Res>? get body;
}

/// @nodoc
class _$ResponseFctVersionCopyWithImpl<$Res, $Val extends ResponseFctVersion>
    implements $ResponseFctVersionCopyWith<$Res> {
  _$ResponseFctVersionCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? header = freezed,
    Object? body = freezed,
  }) {
    return _then(_value.copyWith(
      header: freezed == header
          ? _value.header
          : header // ignore: cast_nullable_to_non_nullable
              as HeaderFctVersion?,
      body: freezed == body
          ? _value.body
          : body // ignore: cast_nullable_to_non_nullable
              as BodyFctVersion?,
    ) as $Val);
  }

  @override
  @pragma('vm:prefer-inline')
  $HeaderFctVersionCopyWith<$Res>? get header {
    if (_value.header == null) {
      return null;
    }

    return $HeaderFctVersionCopyWith<$Res>(_value.header!, (value) {
      return _then(_value.copyWith(header: value) as $Val);
    });
  }

  @override
  @pragma('vm:prefer-inline')
  $BodyFctVersionCopyWith<$Res>? get body {
    if (_value.body == null) {
      return null;
    }

    return $BodyFctVersionCopyWith<$Res>(_value.body!, (value) {
      return _then(_value.copyWith(body: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$_ResponseFctVersionCopyWith<$Res>
    implements $ResponseFctVersionCopyWith<$Res> {
  factory _$$_ResponseFctVersionCopyWith(_$_ResponseFctVersion value,
          $Res Function(_$_ResponseFctVersion) then) =
      __$$_ResponseFctVersionCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@JsonKey(name: 'header') HeaderFctVersion? header,
      @JsonKey(name: 'body') BodyFctVersion? body});

  @override
  $HeaderFctVersionCopyWith<$Res>? get header;
  @override
  $BodyFctVersionCopyWith<$Res>? get body;
}

/// @nodoc
class __$$_ResponseFctVersionCopyWithImpl<$Res>
    extends _$ResponseFctVersionCopyWithImpl<$Res, _$_ResponseFctVersion>
    implements _$$_ResponseFctVersionCopyWith<$Res> {
  __$$_ResponseFctVersionCopyWithImpl(
      _$_ResponseFctVersion _value, $Res Function(_$_ResponseFctVersion) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? header = freezed,
    Object? body = freezed,
  }) {
    return _then(_$_ResponseFctVersion(
      header: freezed == header
          ? _value.header
          : header // ignore: cast_nullable_to_non_nullable
              as HeaderFctVersion?,
      body: freezed == body
          ? _value.body
          : body // ignore: cast_nullable_to_non_nullable
              as BodyFctVersion?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$_ResponseFctVersion implements _ResponseFctVersion {
  const _$_ResponseFctVersion(
      {@JsonKey(name: 'header') this.header, @JsonKey(name: 'body') this.body});

  factory _$_ResponseFctVersion.fromJson(Map<String, dynamic> json) =>
      _$$_ResponseFctVersionFromJson(json);

  @override
  @JsonKey(name: 'header')
  final HeaderFctVersion? header;
  @override
  @JsonKey(name: 'body')
  final BodyFctVersion? body;

  @override
  String toString() {
    return 'ResponseFctVersion(header: $header, body: $body)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$_ResponseFctVersion &&
            (identical(other.header, header) || other.header == header) &&
            (identical(other.body, body) || other.body == body));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, header, body);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$_ResponseFctVersionCopyWith<_$_ResponseFctVersion> get copyWith =>
      __$$_ResponseFctVersionCopyWithImpl<_$_ResponseFctVersion>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$_ResponseFctVersionToJson(
      this,
    );
  }
}

abstract class _ResponseFctVersion implements ResponseFctVersion {
  const factory _ResponseFctVersion(
          {@JsonKey(name: 'header') final HeaderFctVersion? header,
          @JsonKey(name: 'body') final BodyFctVersion? body}) =
      _$_ResponseFctVersion;

  factory _ResponseFctVersion.fromJson(Map<String, dynamic> json) =
      _$_ResponseFctVersion.fromJson;

  @override
  @JsonKey(name: 'header')
  HeaderFctVersion? get header;
  @override
  @JsonKey(name: 'body')
  BodyFctVersion? get body;
  @override
  @JsonKey(ignore: true)
  _$$_ResponseFctVersionCopyWith<_$_ResponseFctVersion> get copyWith =>
      throw _privateConstructorUsedError;
}

BodyFctVersion _$BodyFctVersionFromJson(Map<String, dynamic> json) {
  return _BodyFctVersion.fromJson(json);
}

/// @nodoc
mixin _$BodyFctVersion {
  @JsonKey(name: 'dataType')
  String? get dataType => throw _privateConstructorUsedError;
  @JsonKey(name: 'items')
  ItemsFctVersion? get items => throw _privateConstructorUsedError;
  @JsonKey(name: 'pageNo')
  int? get pageNo => throw _privateConstructorUsedError;
  @JsonKey(name: 'numOfRows')
  int? get numOfRows => throw _privateConstructorUsedError;
  @JsonKey(name: 'totalCount')
  int? get totalCount => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $BodyFctVersionCopyWith<BodyFctVersion> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $BodyFctVersionCopyWith<$Res> {
  factory $BodyFctVersionCopyWith(
          BodyFctVersion value, $Res Function(BodyFctVersion) then) =
      _$BodyFctVersionCopyWithImpl<$Res, BodyFctVersion>;
  @useResult
  $Res call(
      {@JsonKey(name: 'dataType') String? dataType,
      @JsonKey(name: 'items') ItemsFctVersion? items,
      @JsonKey(name: 'pageNo') int? pageNo,
      @JsonKey(name: 'numOfRows') int? numOfRows,
      @JsonKey(name: 'totalCount') int? totalCount});

  $ItemsFctVersionCopyWith<$Res>? get items;
}

/// @nodoc
class _$BodyFctVersionCopyWithImpl<$Res, $Val extends BodyFctVersion>
    implements $BodyFctVersionCopyWith<$Res> {
  _$BodyFctVersionCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? dataType = freezed,
    Object? items = freezed,
    Object? pageNo = freezed,
    Object? numOfRows = freezed,
    Object? totalCount = freezed,
  }) {
    return _then(_value.copyWith(
      dataType: freezed == dataType
          ? _value.dataType
          : dataType // ignore: cast_nullable_to_non_nullable
              as String?,
      items: freezed == items
          ? _value.items
          : items // ignore: cast_nullable_to_non_nullable
              as ItemsFctVersion?,
      pageNo: freezed == pageNo
          ? _value.pageNo
          : pageNo // ignore: cast_nullable_to_non_nullable
              as int?,
      numOfRows: freezed == numOfRows
          ? _value.numOfRows
          : numOfRows // ignore: cast_nullable_to_non_nullable
              as int?,
      totalCount: freezed == totalCount
          ? _value.totalCount
          : totalCount // ignore: cast_nullable_to_non_nullable
              as int?,
    ) as $Val);
  }

  @override
  @pragma('vm:prefer-inline')
  $ItemsFctVersionCopyWith<$Res>? get items {
    if (_value.items == null) {
      return null;
    }

    return $ItemsFctVersionCopyWith<$Res>(_value.items!, (value) {
      return _then(_value.copyWith(items: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$_BodyFctVersionCopyWith<$Res>
    implements $BodyFctVersionCopyWith<$Res> {
  factory _$$_BodyFctVersionCopyWith(
          _$_BodyFctVersion value, $Res Function(_$_BodyFctVersion) then) =
      __$$_BodyFctVersionCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@JsonKey(name: 'dataType') String? dataType,
      @JsonKey(name: 'items') ItemsFctVersion? items,
      @JsonKey(name: 'pageNo') int? pageNo,
      @JsonKey(name: 'numOfRows') int? numOfRows,
      @JsonKey(name: 'totalCount') int? totalCount});

  @override
  $ItemsFctVersionCopyWith<$Res>? get items;
}

/// @nodoc
class __$$_BodyFctVersionCopyWithImpl<$Res>
    extends _$BodyFctVersionCopyWithImpl<$Res, _$_BodyFctVersion>
    implements _$$_BodyFctVersionCopyWith<$Res> {
  __$$_BodyFctVersionCopyWithImpl(
      _$_BodyFctVersion _value, $Res Function(_$_BodyFctVersion) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? dataType = freezed,
    Object? items = freezed,
    Object? pageNo = freezed,
    Object? numOfRows = freezed,
    Object? totalCount = freezed,
  }) {
    return _then(_$_BodyFctVersion(
      dataType: freezed == dataType
          ? _value.dataType
          : dataType // ignore: cast_nullable_to_non_nullable
              as String?,
      items: freezed == items
          ? _value.items
          : items // ignore: cast_nullable_to_non_nullable
              as ItemsFctVersion?,
      pageNo: freezed == pageNo
          ? _value.pageNo
          : pageNo // ignore: cast_nullable_to_non_nullable
              as int?,
      numOfRows: freezed == numOfRows
          ? _value.numOfRows
          : numOfRows // ignore: cast_nullable_to_non_nullable
              as int?,
      totalCount: freezed == totalCount
          ? _value.totalCount
          : totalCount // ignore: cast_nullable_to_non_nullable
              as int?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$_BodyFctVersion implements _BodyFctVersion {
  const _$_BodyFctVersion(
      {@JsonKey(name: 'dataType') this.dataType,
      @JsonKey(name: 'items') this.items,
      @JsonKey(name: 'pageNo') this.pageNo,
      @JsonKey(name: 'numOfRows') this.numOfRows,
      @JsonKey(name: 'totalCount') this.totalCount});

  factory _$_BodyFctVersion.fromJson(Map<String, dynamic> json) =>
      _$$_BodyFctVersionFromJson(json);

  @override
  @JsonKey(name: 'dataType')
  final String? dataType;
  @override
  @JsonKey(name: 'items')
  final ItemsFctVersion? items;
  @override
  @JsonKey(name: 'pageNo')
  final int? pageNo;
  @override
  @JsonKey(name: 'numOfRows')
  final int? numOfRows;
  @override
  @JsonKey(name: 'totalCount')
  final int? totalCount;

  @override
  String toString() {
    return 'BodyFctVersion(dataType: $dataType, items: $items, pageNo: $pageNo, numOfRows: $numOfRows, totalCount: $totalCount)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$_BodyFctVersion &&
            (identical(other.dataType, dataType) ||
                other.dataType == dataType) &&
            (identical(other.items, items) || other.items == items) &&
            (identical(other.pageNo, pageNo) || other.pageNo == pageNo) &&
            (identical(other.numOfRows, numOfRows) ||
                other.numOfRows == numOfRows) &&
            (identical(other.totalCount, totalCount) ||
                other.totalCount == totalCount));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode =>
      Object.hash(runtimeType, dataType, items, pageNo, numOfRows, totalCount);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$_BodyFctVersionCopyWith<_$_BodyFctVersion> get copyWith =>
      __$$_BodyFctVersionCopyWithImpl<_$_BodyFctVersion>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$_BodyFctVersionToJson(
      this,
    );
  }
}

abstract class _BodyFctVersion implements BodyFctVersion {
  const factory _BodyFctVersion(
      {@JsonKey(name: 'dataType') final String? dataType,
      @JsonKey(name: 'items') final ItemsFctVersion? items,
      @JsonKey(name: 'pageNo') final int? pageNo,
      @JsonKey(name: 'numOfRows') final int? numOfRows,
      @JsonKey(name: 'totalCount') final int? totalCount}) = _$_BodyFctVersion;

  factory _BodyFctVersion.fromJson(Map<String, dynamic> json) =
      _$_BodyFctVersion.fromJson;

  @override
  @JsonKey(name: 'dataType')
  String? get dataType;
  @override
  @JsonKey(name: 'items')
  ItemsFctVersion? get items;
  @override
  @JsonKey(name: 'pageNo')
  int? get pageNo;
  @override
  @JsonKey(name: 'numOfRows')
  int? get numOfRows;
  @override
  @JsonKey(name: 'totalCount')
  int? get totalCount;
  @override
  @JsonKey(ignore: true)
  _$$_BodyFctVersionCopyWith<_$_BodyFctVersion> get copyWith =>
      throw _privateConstructorUsedError;
}

ItemsFctVersion _$ItemsFctVersionFromJson(Map<String, dynamic> json) {
  return _ItemsFctVersion.fromJson(json);
}

/// @nodoc
mixin _$ItemsFctVersion {
  @JsonKey(name: 'item')
  List<ItemFctVersion>? get item => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $ItemsFctVersionCopyWith<ItemsFctVersion> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ItemsFctVersionCopyWith<$Res> {
  factory $ItemsFctVersionCopyWith(
          ItemsFctVersion value, $Res Function(ItemsFctVersion) then) =
      _$ItemsFctVersionCopyWithImpl<$Res, ItemsFctVersion>;
  @useResult
  $Res call({@JsonKey(name: 'item') List<ItemFctVersion>? item});
}

/// @nodoc
class _$ItemsFctVersionCopyWithImpl<$Res, $Val extends ItemsFctVersion>
    implements $ItemsFctVersionCopyWith<$Res> {
  _$ItemsFctVersionCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? item = freezed,
  }) {
    return _then(_value.copyWith(
      item: freezed == item
          ? _value.item
          : item // ignore: cast_nullable_to_non_nullable
              as List<ItemFctVersion>?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$_ItemsFctVersionCopyWith<$Res>
    implements $ItemsFctVersionCopyWith<$Res> {
  factory _$$_ItemsFctVersionCopyWith(
          _$_ItemsFctVersion value, $Res Function(_$_ItemsFctVersion) then) =
      __$$_ItemsFctVersionCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({@JsonKey(name: 'item') List<ItemFctVersion>? item});
}

/// @nodoc
class __$$_ItemsFctVersionCopyWithImpl<$Res>
    extends _$ItemsFctVersionCopyWithImpl<$Res, _$_ItemsFctVersion>
    implements _$$_ItemsFctVersionCopyWith<$Res> {
  __$$_ItemsFctVersionCopyWithImpl(
      _$_ItemsFctVersion _value, $Res Function(_$_ItemsFctVersion) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? item = freezed,
  }) {
    return _then(_$_ItemsFctVersion(
      item: freezed == item
          ? _value._item
          : item // ignore: cast_nullable_to_non_nullable
              as List<ItemFctVersion>?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$_ItemsFctVersion implements _ItemsFctVersion {
  const _$_ItemsFctVersion(
      {@JsonKey(name: 'item') final List<ItemFctVersion>? item})
      : _item = item;

  factory _$_ItemsFctVersion.fromJson(Map<String, dynamic> json) =>
      _$$_ItemsFctVersionFromJson(json);

  final List<ItemFctVersion>? _item;
  @override
  @JsonKey(name: 'item')
  List<ItemFctVersion>? get item {
    final value = _item;
    if (value == null) return null;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  @override
  String toString() {
    return 'ItemsFctVersion(item: $item)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$_ItemsFctVersion &&
            const DeepCollectionEquality().equals(other._item, _item));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode =>
      Object.hash(runtimeType, const DeepCollectionEquality().hash(_item));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$_ItemsFctVersionCopyWith<_$_ItemsFctVersion> get copyWith =>
      __$$_ItemsFctVersionCopyWithImpl<_$_ItemsFctVersion>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$_ItemsFctVersionToJson(
      this,
    );
  }
}

abstract class _ItemsFctVersion implements ItemsFctVersion {
  const factory _ItemsFctVersion(
          {@JsonKey(name: 'item') final List<ItemFctVersion>? item}) =
      _$_ItemsFctVersion;

  factory _ItemsFctVersion.fromJson(Map<String, dynamic> json) =
      _$_ItemsFctVersion.fromJson;

  @override
  @JsonKey(name: 'item')
  List<ItemFctVersion>? get item;
  @override
  @JsonKey(ignore: true)
  _$$_ItemsFctVersionCopyWith<_$_ItemsFctVersion> get copyWith =>
      throw _privateConstructorUsedError;
}

ItemFctVersion _$ItemFctVersionFromJson(Map<String, dynamic> json) {
  return _ItemFctVersion.fromJson(json);
}

/// @nodoc
mixin _$ItemFctVersion {
  @JsonKey(name: 'filetype')
  String? get filetype => throw _privateConstructorUsedError;
  @JsonKey(name: 'version')
  String? get version => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $ItemFctVersionCopyWith<ItemFctVersion> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ItemFctVersionCopyWith<$Res> {
  factory $ItemFctVersionCopyWith(
          ItemFctVersion value, $Res Function(ItemFctVersion) then) =
      _$ItemFctVersionCopyWithImpl<$Res, ItemFctVersion>;
  @useResult
  $Res call(
      {@JsonKey(name: 'filetype') String? filetype,
      @JsonKey(name: 'version') String? version});
}

/// @nodoc
class _$ItemFctVersionCopyWithImpl<$Res, $Val extends ItemFctVersion>
    implements $ItemFctVersionCopyWith<$Res> {
  _$ItemFctVersionCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? filetype = freezed,
    Object? version = freezed,
  }) {
    return _then(_value.copyWith(
      filetype: freezed == filetype
          ? _value.filetype
          : filetype // ignore: cast_nullable_to_non_nullable
              as String?,
      version: freezed == version
          ? _value.version
          : version // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$_ItemFctVersionCopyWith<$Res>
    implements $ItemFctVersionCopyWith<$Res> {
  factory _$$_ItemFctVersionCopyWith(
          _$_ItemFctVersion value, $Res Function(_$_ItemFctVersion) then) =
      __$$_ItemFctVersionCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@JsonKey(name: 'filetype') String? filetype,
      @JsonKey(name: 'version') String? version});
}

/// @nodoc
class __$$_ItemFctVersionCopyWithImpl<$Res>
    extends _$ItemFctVersionCopyWithImpl<$Res, _$_ItemFctVersion>
    implements _$$_ItemFctVersionCopyWith<$Res> {
  __$$_ItemFctVersionCopyWithImpl(
      _$_ItemFctVersion _value, $Res Function(_$_ItemFctVersion) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? filetype = freezed,
    Object? version = freezed,
  }) {
    return _then(_$_ItemFctVersion(
      filetype: freezed == filetype
          ? _value.filetype
          : filetype // ignore: cast_nullable_to_non_nullable
              as String?,
      version: freezed == version
          ? _value.version
          : version // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$_ItemFctVersion implements _ItemFctVersion {
  const _$_ItemFctVersion(
      {@JsonKey(name: 'filetype') this.filetype,
      @JsonKey(name: 'version') this.version});

  factory _$_ItemFctVersion.fromJson(Map<String, dynamic> json) =>
      _$$_ItemFctVersionFromJson(json);

  @override
  @JsonKey(name: 'filetype')
  final String? filetype;
  @override
  @JsonKey(name: 'version')
  final String? version;

  @override
  String toString() {
    return 'ItemFctVersion(filetype: $filetype, version: $version)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$_ItemFctVersion &&
            (identical(other.filetype, filetype) ||
                other.filetype == filetype) &&
            (identical(other.version, version) || other.version == version));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, filetype, version);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$_ItemFctVersionCopyWith<_$_ItemFctVersion> get copyWith =>
      __$$_ItemFctVersionCopyWithImpl<_$_ItemFctVersion>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$_ItemFctVersionToJson(
      this,
    );
  }
}

abstract class _ItemFctVersion implements ItemFctVersion {
  const factory _ItemFctVersion(
      {@JsonKey(name: 'filetype') final String? filetype,
      @JsonKey(name: 'version') final String? version}) = _$_ItemFctVersion;

  factory _ItemFctVersion.fromJson(Map<String, dynamic> json) =
      _$_ItemFctVersion.fromJson;

  @override
  @JsonKey(name: 'filetype')
  String? get filetype;
  @override
  @JsonKey(name: 'version')
  String? get version;
  @override
  @JsonKey(ignore: true)
  _$$_ItemFctVersionCopyWith<_$_ItemFctVersion> get copyWith =>
      throw _privateConstructorUsedError;
}

HeaderFctVersion _$HeaderFctVersionFromJson(Map<String, dynamic> json) {
  return _HeaderFctVersion.fromJson(json);
}

/// @nodoc
mixin _$HeaderFctVersion {
  @JsonKey(name: 'resultCode')
  String? get resultCode => throw _privateConstructorUsedError;
  @JsonKey(name: 'resultMsg')
  String? get resultMsg => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $HeaderFctVersionCopyWith<HeaderFctVersion> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $HeaderFctVersionCopyWith<$Res> {
  factory $HeaderFctVersionCopyWith(
          HeaderFctVersion value, $Res Function(HeaderFctVersion) then) =
      _$HeaderFctVersionCopyWithImpl<$Res, HeaderFctVersion>;
  @useResult
  $Res call(
      {@JsonKey(name: 'resultCode') String? resultCode,
      @JsonKey(name: 'resultMsg') String? resultMsg});
}

/// @nodoc
class _$HeaderFctVersionCopyWithImpl<$Res, $Val extends HeaderFctVersion>
    implements $HeaderFctVersionCopyWith<$Res> {
  _$HeaderFctVersionCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? resultCode = freezed,
    Object? resultMsg = freezed,
  }) {
    return _then(_value.copyWith(
      resultCode: freezed == resultCode
          ? _value.resultCode
          : resultCode // ignore: cast_nullable_to_non_nullable
              as String?,
      resultMsg: freezed == resultMsg
          ? _value.resultMsg
          : resultMsg // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$_HeaderFctVersionCopyWith<$Res>
    implements $HeaderFctVersionCopyWith<$Res> {
  factory _$$_HeaderFctVersionCopyWith(
          _$_HeaderFctVersion value, $Res Function(_$_HeaderFctVersion) then) =
      __$$_HeaderFctVersionCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@JsonKey(name: 'resultCode') String? resultCode,
      @JsonKey(name: 'resultMsg') String? resultMsg});
}

/// @nodoc
class __$$_HeaderFctVersionCopyWithImpl<$Res>
    extends _$HeaderFctVersionCopyWithImpl<$Res, _$_HeaderFctVersion>
    implements _$$_HeaderFctVersionCopyWith<$Res> {
  __$$_HeaderFctVersionCopyWithImpl(
      _$_HeaderFctVersion _value, $Res Function(_$_HeaderFctVersion) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? resultCode = freezed,
    Object? resultMsg = freezed,
  }) {
    return _then(_$_HeaderFctVersion(
      resultCode: freezed == resultCode
          ? _value.resultCode
          : resultCode // ignore: cast_nullable_to_non_nullable
              as String?,
      resultMsg: freezed == resultMsg
          ? _value.resultMsg
          : resultMsg // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$_HeaderFctVersion implements _HeaderFctVersion {
  const _$_HeaderFctVersion(
      {@JsonKey(name: 'resultCode') this.resultCode,
      @JsonKey(name: 'resultMsg') this.resultMsg});

  factory _$_HeaderFctVersion.fromJson(Map<String, dynamic> json) =>
      _$$_HeaderFctVersionFromJson(json);

  @override
  @JsonKey(name: 'resultCode')
  final String? resultCode;
  @override
  @JsonKey(name: 'resultMsg')
  final String? resultMsg;

  @override
  String toString() {
    return 'HeaderFctVersion(resultCode: $resultCode, resultMsg: $resultMsg)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$_HeaderFctVersion &&
            (identical(other.resultCode, resultCode) ||
                other.resultCode == resultCode) &&
            (identical(other.resultMsg, resultMsg) ||
                other.resultMsg == resultMsg));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, resultCode, resultMsg);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$_HeaderFctVersionCopyWith<_$_HeaderFctVersion> get copyWith =>
      __$$_HeaderFctVersionCopyWithImpl<_$_HeaderFctVersion>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$_HeaderFctVersionToJson(
      this,
    );
  }
}

abstract class _HeaderFctVersion implements HeaderFctVersion {
  const factory _HeaderFctVersion(
          {@JsonKey(name: 'resultCode') final String? resultCode,
          @JsonKey(name: 'resultMsg') final String? resultMsg}) =
      _$_HeaderFctVersion;

  factory _HeaderFctVersion.fromJson(Map<String, dynamic> json) =
      _$_HeaderFctVersion.fromJson;

  @override
  @JsonKey(name: 'resultCode')
  String? get resultCode;
  @override
  @JsonKey(name: 'resultMsg')
  String? get resultMsg;
  @override
  @JsonKey(ignore: true)
  _$$_HeaderFctVersionCopyWith<_$_HeaderFctVersion> get copyWith =>
      throw _privateConstructorUsedError;
}
