// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target

part of 'fct_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#custom-getters-and-methods');

FctModel _$FctModelFromJson(Map<String, dynamic> json) {
  return _FctModel.fromJson(json);
}

/// @nodoc
mixin _$FctModel {
  /// 단기 예보조회
  @JsonKey(name: 'response')
  ResponseFct? get response => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $FctModelCopyWith<FctModel> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $FctModelCopyWith<$Res> {
  factory $FctModelCopyWith(FctModel value, $Res Function(FctModel) then) = _$FctModelCopyWithImpl<$Res, FctModel>;
  @useResult
  $Res call({@JsonKey(name: 'response') ResponseFct? response});

  $ResponseFctCopyWith<$Res>? get response;
}

/// @nodoc
class _$FctModelCopyWithImpl<$Res, $Val extends FctModel> implements $FctModelCopyWith<$Res> {
  _$FctModelCopyWithImpl(this._value, this._then);

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
              as ResponseFct?,
    ) as $Val);
  }

  @override
  @pragma('vm:prefer-inline')
  $ResponseFctCopyWith<$Res>? get response {
    if (_value.response == null) {
      return null;
    }

    return $ResponseFctCopyWith<$Res>(_value.response!, (value) {
      return _then(_value.copyWith(response: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$_FctModelCopyWith<$Res> implements $FctModelCopyWith<$Res> {
  factory _$$_FctModelCopyWith(_$_FctModel value, $Res Function(_$_FctModel) then) = __$$_FctModelCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({@JsonKey(name: 'response') ResponseFct? response});

  @override
  $ResponseFctCopyWith<$Res>? get response;
}

/// @nodoc
class __$$_FctModelCopyWithImpl<$Res> extends _$FctModelCopyWithImpl<$Res, _$_FctModel> implements _$$_FctModelCopyWith<$Res> {
  __$$_FctModelCopyWithImpl(_$_FctModel _value, $Res Function(_$_FctModel) _then) : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? response = freezed,
  }) {
    return _then(_$_FctModel(
      response: freezed == response
          ? _value.response
          : response // ignore: cast_nullable_to_non_nullable
              as ResponseFct?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$_FctModel implements _FctModel {
  const _$_FctModel({@JsonKey(name: 'response') this.response});

  factory _$_FctModel.fromJson(Map<String, dynamic> json) => _$$_FctModelFromJson(json);

  /// 단기 예보조회
  @override
  @JsonKey(name: 'response')
  final ResponseFct? response;

  @override
  String toString() {
    return 'FctModel(response: $response)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is _$_FctModel && (identical(other.response, response) || other.response == response));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, response);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$_FctModelCopyWith<_$_FctModel> get copyWith => __$$_FctModelCopyWithImpl<_$_FctModel>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$_FctModelToJson(
      this,
    );
  }
}

abstract class _FctModel implements FctModel {
  const factory _FctModel({@JsonKey(name: 'response') final ResponseFct? response}) = _$_FctModel;

  factory _FctModel.fromJson(Map<String, dynamic> json) = _$_FctModel.fromJson;

  @override

  /// 단기 예보조회
  @JsonKey(name: 'response')
  ResponseFct? get response;
  @override
  @JsonKey(ignore: true)
  _$$_FctModelCopyWith<_$_FctModel> get copyWith => throw _privateConstructorUsedError;
}

ResponseFct _$ResponseFctFromJson(Map<String, dynamic> json) {
  return _ResponseFct.fromJson(json);
}

/// @nodoc
mixin _$ResponseFct {
  @JsonKey(name: 'header')
  HeaderFct? get header => throw _privateConstructorUsedError;
  @JsonKey(name: 'body')
  BodyFct? get body => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $ResponseFctCopyWith<ResponseFct> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ResponseFctCopyWith<$Res> {
  factory $ResponseFctCopyWith(ResponseFct value, $Res Function(ResponseFct) then) = _$ResponseFctCopyWithImpl<$Res, ResponseFct>;
  @useResult
  $Res call({@JsonKey(name: 'header') HeaderFct? header, @JsonKey(name: 'body') BodyFct? body});

  $HeaderFctCopyWith<$Res>? get header;
  $BodyFctCopyWith<$Res>? get body;
}

/// @nodoc
class _$ResponseFctCopyWithImpl<$Res, $Val extends ResponseFct> implements $ResponseFctCopyWith<$Res> {
  _$ResponseFctCopyWithImpl(this._value, this._then);

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
              as HeaderFct?,
      body: freezed == body
          ? _value.body
          : body // ignore: cast_nullable_to_non_nullable
              as BodyFct?,
    ) as $Val);
  }

  @override
  @pragma('vm:prefer-inline')
  $HeaderFctCopyWith<$Res>? get header {
    if (_value.header == null) {
      return null;
    }

    return $HeaderFctCopyWith<$Res>(_value.header!, (value) {
      return _then(_value.copyWith(header: value) as $Val);
    });
  }

  @override
  @pragma('vm:prefer-inline')
  $BodyFctCopyWith<$Res>? get body {
    if (_value.body == null) {
      return null;
    }

    return $BodyFctCopyWith<$Res>(_value.body!, (value) {
      return _then(_value.copyWith(body: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$_ResponseFctCopyWith<$Res> implements $ResponseFctCopyWith<$Res> {
  factory _$$_ResponseFctCopyWith(_$_ResponseFct value, $Res Function(_$_ResponseFct) then) = __$$_ResponseFctCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({@JsonKey(name: 'header') HeaderFct? header, @JsonKey(name: 'body') BodyFct? body});

  @override
  $HeaderFctCopyWith<$Res>? get header;
  @override
  $BodyFctCopyWith<$Res>? get body;
}

/// @nodoc
class __$$_ResponseFctCopyWithImpl<$Res> extends _$ResponseFctCopyWithImpl<$Res, _$_ResponseFct> implements _$$_ResponseFctCopyWith<$Res> {
  __$$_ResponseFctCopyWithImpl(_$_ResponseFct _value, $Res Function(_$_ResponseFct) _then) : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? header = freezed,
    Object? body = freezed,
  }) {
    return _then(_$_ResponseFct(
      header: freezed == header
          ? _value.header
          : header // ignore: cast_nullable_to_non_nullable
              as HeaderFct?,
      body: freezed == body
          ? _value.body
          : body // ignore: cast_nullable_to_non_nullable
              as BodyFct?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$_ResponseFct implements _ResponseFct {
  const _$_ResponseFct({@JsonKey(name: 'header') this.header, @JsonKey(name: 'body') this.body});

  factory _$_ResponseFct.fromJson(Map<String, dynamic> json) => _$$_ResponseFctFromJson(json);

  @override
  @JsonKey(name: 'header')
  final HeaderFct? header;
  @override
  @JsonKey(name: 'body')
  final BodyFct? body;

  @override
  String toString() {
    return 'ResponseFct(header: $header, body: $body)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$_ResponseFct &&
            (identical(other.header, header) || other.header == header) &&
            (identical(other.body, body) || other.body == body));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, header, body);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$_ResponseFctCopyWith<_$_ResponseFct> get copyWith => __$$_ResponseFctCopyWithImpl<_$_ResponseFct>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$_ResponseFctToJson(
      this,
    );
  }
}

abstract class _ResponseFct implements ResponseFct {
  const factory _ResponseFct({@JsonKey(name: 'header') final HeaderFct? header, @JsonKey(name: 'body') final BodyFct? body}) =
      _$_ResponseFct;

  factory _ResponseFct.fromJson(Map<String, dynamic> json) = _$_ResponseFct.fromJson;

  @override
  @JsonKey(name: 'header')
  HeaderFct? get header;
  @override
  @JsonKey(name: 'body')
  BodyFct? get body;
  @override
  @JsonKey(ignore: true)
  _$$_ResponseFctCopyWith<_$_ResponseFct> get copyWith => throw _privateConstructorUsedError;
}

BodyFct _$BodyFctFromJson(Map<String, dynamic> json) {
  return _BodyFct.fromJson(json);
}

/// @nodoc
mixin _$BodyFct {
  @JsonKey(name: 'dataType')
  String? get dataType => throw _privateConstructorUsedError;
  @JsonKey(name: 'items')
  ItemsFct? get items => throw _privateConstructorUsedError;
  @JsonKey(name: 'pageNo')
  int? get pageNo => throw _privateConstructorUsedError;
  @JsonKey(name: 'numOfRows')
  int? get numOfRows => throw _privateConstructorUsedError;
  @JsonKey(name: 'totalCount')
  int? get totalCount => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $BodyFctCopyWith<BodyFct> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $BodyFctCopyWith<$Res> {
  factory $BodyFctCopyWith(BodyFct value, $Res Function(BodyFct) then) = _$BodyFctCopyWithImpl<$Res, BodyFct>;
  @useResult
  $Res call(
      {@JsonKey(name: 'dataType') String? dataType,
      @JsonKey(name: 'items') ItemsFct? items,
      @JsonKey(name: 'pageNo') int? pageNo,
      @JsonKey(name: 'numOfRows') int? numOfRows,
      @JsonKey(name: 'totalCount') int? totalCount});

  $ItemsFctCopyWith<$Res>? get items;
}

/// @nodoc
class _$BodyFctCopyWithImpl<$Res, $Val extends BodyFct> implements $BodyFctCopyWith<$Res> {
  _$BodyFctCopyWithImpl(this._value, this._then);

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
              as ItemsFct?,
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
  $ItemsFctCopyWith<$Res>? get items {
    if (_value.items == null) {
      return null;
    }

    return $ItemsFctCopyWith<$Res>(_value.items!, (value) {
      return _then(_value.copyWith(items: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$_BodyFctCopyWith<$Res> implements $BodyFctCopyWith<$Res> {
  factory _$$_BodyFctCopyWith(_$_BodyFct value, $Res Function(_$_BodyFct) then) = __$$_BodyFctCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@JsonKey(name: 'dataType') String? dataType,
      @JsonKey(name: 'items') ItemsFct? items,
      @JsonKey(name: 'pageNo') int? pageNo,
      @JsonKey(name: 'numOfRows') int? numOfRows,
      @JsonKey(name: 'totalCount') int? totalCount});

  @override
  $ItemsFctCopyWith<$Res>? get items;
}

/// @nodoc
class __$$_BodyFctCopyWithImpl<$Res> extends _$BodyFctCopyWithImpl<$Res, _$_BodyFct> implements _$$_BodyFctCopyWith<$Res> {
  __$$_BodyFctCopyWithImpl(_$_BodyFct _value, $Res Function(_$_BodyFct) _then) : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? dataType = freezed,
    Object? items = freezed,
    Object? pageNo = freezed,
    Object? numOfRows = freezed,
    Object? totalCount = freezed,
  }) {
    return _then(_$_BodyFct(
      dataType: freezed == dataType
          ? _value.dataType
          : dataType // ignore: cast_nullable_to_non_nullable
              as String?,
      items: freezed == items
          ? _value.items
          : items // ignore: cast_nullable_to_non_nullable
              as ItemsFct?,
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
class _$_BodyFct implements _BodyFct {
  const _$_BodyFct(
      {@JsonKey(name: 'dataType') this.dataType,
      @JsonKey(name: 'items') this.items,
      @JsonKey(name: 'pageNo') this.pageNo,
      @JsonKey(name: 'numOfRows') this.numOfRows,
      @JsonKey(name: 'totalCount') this.totalCount});

  factory _$_BodyFct.fromJson(Map<String, dynamic> json) => _$$_BodyFctFromJson(json);

  @override
  @JsonKey(name: 'dataType')
  final String? dataType;
  @override
  @JsonKey(name: 'items')
  final ItemsFct? items;
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
    return 'BodyFct(dataType: $dataType, items: $items, pageNo: $pageNo, numOfRows: $numOfRows, totalCount: $totalCount)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$_BodyFct &&
            (identical(other.dataType, dataType) || other.dataType == dataType) &&
            (identical(other.items, items) || other.items == items) &&
            (identical(other.pageNo, pageNo) || other.pageNo == pageNo) &&
            (identical(other.numOfRows, numOfRows) || other.numOfRows == numOfRows) &&
            (identical(other.totalCount, totalCount) || other.totalCount == totalCount));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, dataType, items, pageNo, numOfRows, totalCount);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$_BodyFctCopyWith<_$_BodyFct> get copyWith => __$$_BodyFctCopyWithImpl<_$_BodyFct>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$_BodyFctToJson(
      this,
    );
  }
}

abstract class _BodyFct implements BodyFct {
  const factory _BodyFct(
      {@JsonKey(name: 'dataType') final String? dataType,
      @JsonKey(name: 'items') final ItemsFct? items,
      @JsonKey(name: 'pageNo') final int? pageNo,
      @JsonKey(name: 'numOfRows') final int? numOfRows,
      @JsonKey(name: 'totalCount') final int? totalCount}) = _$_BodyFct;

  factory _BodyFct.fromJson(Map<String, dynamic> json) = _$_BodyFct.fromJson;

  @override
  @JsonKey(name: 'dataType')
  String? get dataType;
  @override
  @JsonKey(name: 'items')
  ItemsFct? get items;
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
  _$$_BodyFctCopyWith<_$_BodyFct> get copyWith => throw _privateConstructorUsedError;
}

ItemsFct _$ItemsFctFromJson(Map<String, dynamic> json) {
  return _ItemsFct.fromJson(json);
}

/// @nodoc
mixin _$ItemsFct {
  @JsonKey(name: 'item')
  List<ItemFct>? get item => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $ItemsFctCopyWith<ItemsFct> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ItemsFctCopyWith<$Res> {
  factory $ItemsFctCopyWith(ItemsFct value, $Res Function(ItemsFct) then) = _$ItemsFctCopyWithImpl<$Res, ItemsFct>;
  @useResult
  $Res call({@JsonKey(name: 'item') List<ItemFct>? item});
}

/// @nodoc
class _$ItemsFctCopyWithImpl<$Res, $Val extends ItemsFct> implements $ItemsFctCopyWith<$Res> {
  _$ItemsFctCopyWithImpl(this._value, this._then);

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
              as List<ItemFct>?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$_ItemsFctCopyWith<$Res> implements $ItemsFctCopyWith<$Res> {
  factory _$$_ItemsFctCopyWith(_$_ItemsFct value, $Res Function(_$_ItemsFct) then) = __$$_ItemsFctCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({@JsonKey(name: 'item') List<ItemFct>? item});
}

/// @nodoc
class __$$_ItemsFctCopyWithImpl<$Res> extends _$ItemsFctCopyWithImpl<$Res, _$_ItemsFct> implements _$$_ItemsFctCopyWith<$Res> {
  __$$_ItemsFctCopyWithImpl(_$_ItemsFct _value, $Res Function(_$_ItemsFct) _then) : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? item = freezed,
  }) {
    return _then(_$_ItemsFct(
      item: freezed == item
          ? _value._item
          : item // ignore: cast_nullable_to_non_nullable
              as List<ItemFct>?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$_ItemsFct implements _ItemsFct {
  const _$_ItemsFct({@JsonKey(name: 'item') final List<ItemFct>? item}) : _item = item;

  factory _$_ItemsFct.fromJson(Map<String, dynamic> json) => _$$_ItemsFctFromJson(json);

  final List<ItemFct>? _item;
  @override
  @JsonKey(name: 'item')
  List<ItemFct>? get item {
    final value = _item;
    if (value == null) return null;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  @override
  String toString() {
    return 'ItemsFct(item: $item)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is _$_ItemsFct && const DeepCollectionEquality().equals(other._item, _item));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, const DeepCollectionEquality().hash(_item));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$_ItemsFctCopyWith<_$_ItemsFct> get copyWith => __$$_ItemsFctCopyWithImpl<_$_ItemsFct>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$_ItemsFctToJson(
      this,
    );
  }
}

abstract class _ItemsFct implements ItemsFct {
  const factory _ItemsFct({@JsonKey(name: 'item') final List<ItemFct>? item}) = _$_ItemsFct;

  factory _ItemsFct.fromJson(Map<String, dynamic> json) = _$_ItemsFct.fromJson;

  @override
  @JsonKey(name: 'item')
  List<ItemFct>? get item;
  @override
  @JsonKey(ignore: true)
  _$$_ItemsFctCopyWith<_$_ItemsFct> get copyWith => throw _privateConstructorUsedError;
}

ItemFct _$ItemFctFromJson(Map<String, dynamic> json) {
  return _ItemFct.fromJson(json);
}

/// @nodoc
mixin _$ItemFct {
  @JsonKey(name: 'baseDate')
  String? get baseDate => throw _privateConstructorUsedError;
  @JsonKey(name: 'baseTime')
  String? get baseTime => throw _privateConstructorUsedError;
  @JsonKey(name: 'category')
  String? get category => throw _privateConstructorUsedError;
  @JsonKey(name: 'fcstDate')
  String? get fcstDate => throw _privateConstructorUsedError;
  @JsonKey(name: 'fcstTime')
  String? get fcstTime => throw _privateConstructorUsedError;
  @JsonKey(name: 'fcstValue')
  String? get fcstValue => throw _privateConstructorUsedError;
  @JsonKey(name: 'nx')
  int? get nx => throw _privateConstructorUsedError;
  @JsonKey(name: 'ny')
  int? get ny => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $ItemFctCopyWith<ItemFct> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ItemFctCopyWith<$Res> {
  factory $ItemFctCopyWith(ItemFct value, $Res Function(ItemFct) then) = _$ItemFctCopyWithImpl<$Res, ItemFct>;
  @useResult
  $Res call(
      {@JsonKey(name: 'baseDate') String? baseDate,
      @JsonKey(name: 'baseTime') String? baseTime,
      @JsonKey(name: 'category') String? category,
      @JsonKey(name: 'fcstDate') String? fcstDate,
      @JsonKey(name: 'fcstTime') String? fcstTime,
      @JsonKey(name: 'fcstValue') String? fcstValue,
      @JsonKey(name: 'nx') int? nx,
      @JsonKey(name: 'ny') int? ny});
}

/// @nodoc
class _$ItemFctCopyWithImpl<$Res, $Val extends ItemFct> implements $ItemFctCopyWith<$Res> {
  _$ItemFctCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? baseDate = freezed,
    Object? baseTime = freezed,
    Object? category = freezed,
    Object? fcstDate = freezed,
    Object? fcstTime = freezed,
    Object? fcstValue = freezed,
    Object? nx = freezed,
    Object? ny = freezed,
  }) {
    return _then(_value.copyWith(
      baseDate: freezed == baseDate
          ? _value.baseDate
          : baseDate // ignore: cast_nullable_to_non_nullable
              as String?,
      baseTime: freezed == baseTime
          ? _value.baseTime
          : baseTime // ignore: cast_nullable_to_non_nullable
              as String?,
      category: freezed == category
          ? _value.category
          : category // ignore: cast_nullable_to_non_nullable
              as String?,
      fcstDate: freezed == fcstDate
          ? _value.fcstDate
          : fcstDate // ignore: cast_nullable_to_non_nullable
              as String?,
      fcstTime: freezed == fcstTime
          ? _value.fcstTime
          : fcstTime // ignore: cast_nullable_to_non_nullable
              as String?,
      fcstValue: freezed == fcstValue
          ? _value.fcstValue
          : fcstValue // ignore: cast_nullable_to_non_nullable
              as String?,
      nx: freezed == nx
          ? _value.nx
          : nx // ignore: cast_nullable_to_non_nullable
              as int?,
      ny: freezed == ny
          ? _value.ny
          : ny // ignore: cast_nullable_to_non_nullable
              as int?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$_ItemFctCopyWith<$Res> implements $ItemFctCopyWith<$Res> {
  factory _$$_ItemFctCopyWith(_$_ItemFct value, $Res Function(_$_ItemFct) then) = __$$_ItemFctCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@JsonKey(name: 'baseDate') String? baseDate,
      @JsonKey(name: 'baseTime') String? baseTime,
      @JsonKey(name: 'category') String? category,
      @JsonKey(name: 'fcstDate') String? fcstDate,
      @JsonKey(name: 'fcstTime') String? fcstTime,
      @JsonKey(name: 'fcstValue') String? fcstValue,
      @JsonKey(name: 'nx') int? nx,
      @JsonKey(name: 'ny') int? ny});
}

/// @nodoc
class __$$_ItemFctCopyWithImpl<$Res> extends _$ItemFctCopyWithImpl<$Res, _$_ItemFct> implements _$$_ItemFctCopyWith<$Res> {
  __$$_ItemFctCopyWithImpl(_$_ItemFct _value, $Res Function(_$_ItemFct) _then) : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? baseDate = freezed,
    Object? baseTime = freezed,
    Object? category = freezed,
    Object? fcstDate = freezed,
    Object? fcstTime = freezed,
    Object? fcstValue = freezed,
    Object? nx = freezed,
    Object? ny = freezed,
  }) {
    return _then(_$_ItemFct(
      baseDate: freezed == baseDate
          ? _value.baseDate
          : baseDate // ignore: cast_nullable_to_non_nullable
              as String?,
      baseTime: freezed == baseTime
          ? _value.baseTime
          : baseTime // ignore: cast_nullable_to_non_nullable
              as String?,
      category: freezed == category
          ? _value.category
          : category // ignore: cast_nullable_to_non_nullable
              as String?,
      fcstDate: freezed == fcstDate
          ? _value.fcstDate
          : fcstDate // ignore: cast_nullable_to_non_nullable
              as String?,
      fcstTime: freezed == fcstTime
          ? _value.fcstTime
          : fcstTime // ignore: cast_nullable_to_non_nullable
              as String?,
      fcstValue: freezed == fcstValue
          ? _value.fcstValue
          : fcstValue // ignore: cast_nullable_to_non_nullable
              as String?,
      nx: freezed == nx
          ? _value.nx
          : nx // ignore: cast_nullable_to_non_nullable
              as int?,
      ny: freezed == ny
          ? _value.ny
          : ny // ignore: cast_nullable_to_non_nullable
              as int?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$_ItemFct implements _ItemFct {
  const _$_ItemFct(
      {@JsonKey(name: 'baseDate') this.baseDate,
      @JsonKey(name: 'baseTime') this.baseTime,
      @JsonKey(name: 'category') this.category,
      @JsonKey(name: 'fcstDate') this.fcstDate,
      @JsonKey(name: 'fcstTime') this.fcstTime,
      @JsonKey(name: 'fcstValue') this.fcstValue,
      @JsonKey(name: 'nx') this.nx,
      @JsonKey(name: 'ny') this.ny});

  factory _$_ItemFct.fromJson(Map<String, dynamic> json) => _$$_ItemFctFromJson(json);

  @override
  @JsonKey(name: 'baseDate')
  final String? baseDate;
  @override
  @JsonKey(name: 'baseTime')
  final String? baseTime;
  @override
  @JsonKey(name: 'category')
  final String? category;
  @override
  @JsonKey(name: 'fcstDate')
  final String? fcstDate;
  @override
  @JsonKey(name: 'fcstTime')
  final String? fcstTime;
  @override
  @JsonKey(name: 'fcstValue')
  final String? fcstValue;
  @override
  @JsonKey(name: 'nx')
  final int? nx;
  @override
  @JsonKey(name: 'ny')
  final int? ny;

  @override
  String toString() {
    return 'ItemFct(baseDate: $baseDate, baseTime: $baseTime, category: $category, fcstDate: $fcstDate, fcstTime: $fcstTime, fcstValue: $fcstValue, nx: $nx, ny: $ny)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$_ItemFct &&
            (identical(other.baseDate, baseDate) || other.baseDate == baseDate) &&
            (identical(other.baseTime, baseTime) || other.baseTime == baseTime) &&
            (identical(other.category, category) || other.category == category) &&
            (identical(other.fcstDate, fcstDate) || other.fcstDate == fcstDate) &&
            (identical(other.fcstTime, fcstTime) || other.fcstTime == fcstTime) &&
            (identical(other.fcstValue, fcstValue) || other.fcstValue == fcstValue) &&
            (identical(other.nx, nx) || other.nx == nx) &&
            (identical(other.ny, ny) || other.ny == ny));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, baseDate, baseTime, category, fcstDate, fcstTime, fcstValue, nx, ny);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$_ItemFctCopyWith<_$_ItemFct> get copyWith => __$$_ItemFctCopyWithImpl<_$_ItemFct>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$_ItemFctToJson(
      this,
    );
  }
}

abstract class _ItemFct implements ItemFct {
  const factory _ItemFct(
      {@JsonKey(name: 'baseDate') final String? baseDate,
      @JsonKey(name: 'baseTime') final String? baseTime,
      @JsonKey(name: 'category') final String? category,
      @JsonKey(name: 'fcstDate') final String? fcstDate,
      @JsonKey(name: 'fcstTime') final String? fcstTime,
      @JsonKey(name: 'fcstValue') final String? fcstValue,
      @JsonKey(name: 'nx') final int? nx,
      @JsonKey(name: 'ny') final int? ny}) = _$_ItemFct;

  factory _ItemFct.fromJson(Map<String, dynamic> json) = _$_ItemFct.fromJson;

  @override
  @JsonKey(name: 'baseDate')
  String? get baseDate;
  @override
  @JsonKey(name: 'baseTime')
  String? get baseTime;
  @override
  @JsonKey(name: 'category')
  String? get category;
  @override
  @JsonKey(name: 'fcstDate')
  String? get fcstDate;
  @override
  @JsonKey(name: 'fcstTime')
  String? get fcstTime;
  @override
  @JsonKey(name: 'fcstValue')
  String? get fcstValue;
  @override
  @JsonKey(name: 'nx')
  int? get nx;
  @override
  @JsonKey(name: 'ny')
  int? get ny;
  @override
  @JsonKey(ignore: true)
  _$$_ItemFctCopyWith<_$_ItemFct> get copyWith => throw _privateConstructorUsedError;
}

HeaderFct _$HeaderFctFromJson(Map<String, dynamic> json) {
  return _HeaderFct.fromJson(json);
}

/// @nodoc
mixin _$HeaderFct {
  @JsonKey(name: 'resultCode')
  String? get resultCode => throw _privateConstructorUsedError;
  @JsonKey(name: 'resultMsg')
  String? get resultMsg => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $HeaderFctCopyWith<HeaderFct> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $HeaderFctCopyWith<$Res> {
  factory $HeaderFctCopyWith(HeaderFct value, $Res Function(HeaderFct) then) = _$HeaderFctCopyWithImpl<$Res, HeaderFct>;
  @useResult
  $Res call({@JsonKey(name: 'resultCode') String? resultCode, @JsonKey(name: 'resultMsg') String? resultMsg});
}

/// @nodoc
class _$HeaderFctCopyWithImpl<$Res, $Val extends HeaderFct> implements $HeaderFctCopyWith<$Res> {
  _$HeaderFctCopyWithImpl(this._value, this._then);

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
abstract class _$$_HeaderFctCopyWith<$Res> implements $HeaderFctCopyWith<$Res> {
  factory _$$_HeaderFctCopyWith(_$_HeaderFct value, $Res Function(_$_HeaderFct) then) = __$$_HeaderFctCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({@JsonKey(name: 'resultCode') String? resultCode, @JsonKey(name: 'resultMsg') String? resultMsg});
}

/// @nodoc
class __$$_HeaderFctCopyWithImpl<$Res> extends _$HeaderFctCopyWithImpl<$Res, _$_HeaderFct> implements _$$_HeaderFctCopyWith<$Res> {
  __$$_HeaderFctCopyWithImpl(_$_HeaderFct _value, $Res Function(_$_HeaderFct) _then) : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? resultCode = freezed,
    Object? resultMsg = freezed,
  }) {
    return _then(_$_HeaderFct(
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
class _$_HeaderFct implements _HeaderFct {
  const _$_HeaderFct({@JsonKey(name: 'resultCode') this.resultCode, @JsonKey(name: 'resultMsg') this.resultMsg});

  factory _$_HeaderFct.fromJson(Map<String, dynamic> json) => _$$_HeaderFctFromJson(json);

  @override
  @JsonKey(name: 'resultCode')
  final String? resultCode;
  @override
  @JsonKey(name: 'resultMsg')
  final String? resultMsg;

  @override
  String toString() {
    return 'HeaderFct(resultCode: $resultCode, resultMsg: $resultMsg)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$_HeaderFct &&
            (identical(other.resultCode, resultCode) || other.resultCode == resultCode) &&
            (identical(other.resultMsg, resultMsg) || other.resultMsg == resultMsg));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, resultCode, resultMsg);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$_HeaderFctCopyWith<_$_HeaderFct> get copyWith => __$$_HeaderFctCopyWithImpl<_$_HeaderFct>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$_HeaderFctToJson(
      this,
    );
  }
}

abstract class _HeaderFct implements HeaderFct {
  const factory _HeaderFct({@JsonKey(name: 'resultCode') final String? resultCode, @JsonKey(name: 'resultMsg') final String? resultMsg}) =
      _$_HeaderFct;

  factory _HeaderFct.fromJson(Map<String, dynamic> json) = _$_HeaderFct.fromJson;

  @override
  @JsonKey(name: 'resultCode')
  String? get resultCode;
  @override
  @JsonKey(name: 'resultMsg')
  String? get resultMsg;
  @override
  @JsonKey(ignore: true)
  _$$_HeaderFctCopyWith<_$_HeaderFct> get copyWith => throw _privateConstructorUsedError;
}
