// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target

part of 'super_fct_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#custom-getters-and-methods');

SuperFctModel _$SuperFctModelFromJson(Map<String, dynamic> json) {
  return _SuperFctModel.fromJson(json);
}

/// @nodoc
mixin _$SuperFctModel {
  /// 초단기 예보조회
  @JsonKey(name: 'response')
  ResponseSuperFct? get response => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $SuperFctModelCopyWith<SuperFctModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SuperFctModelCopyWith<$Res> {
  factory $SuperFctModelCopyWith(
          SuperFctModel value, $Res Function(SuperFctModel) then) =
      _$SuperFctModelCopyWithImpl<$Res, SuperFctModel>;
  @useResult
  $Res call({@JsonKey(name: 'response') ResponseSuperFct? response});

  $ResponseSuperFctCopyWith<$Res>? get response;
}

/// @nodoc
class _$SuperFctModelCopyWithImpl<$Res, $Val extends SuperFctModel>
    implements $SuperFctModelCopyWith<$Res> {
  _$SuperFctModelCopyWithImpl(this._value, this._then);

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
              as ResponseSuperFct?,
    ) as $Val);
  }

  @override
  @pragma('vm:prefer-inline')
  $ResponseSuperFctCopyWith<$Res>? get response {
    if (_value.response == null) {
      return null;
    }

    return $ResponseSuperFctCopyWith<$Res>(_value.response!, (value) {
      return _then(_value.copyWith(response: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$_SuperFctModelCopyWith<$Res>
    implements $SuperFctModelCopyWith<$Res> {
  factory _$$_SuperFctModelCopyWith(
          _$_SuperFctModel value, $Res Function(_$_SuperFctModel) then) =
      __$$_SuperFctModelCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({@JsonKey(name: 'response') ResponseSuperFct? response});

  @override
  $ResponseSuperFctCopyWith<$Res>? get response;
}

/// @nodoc
class __$$_SuperFctModelCopyWithImpl<$Res>
    extends _$SuperFctModelCopyWithImpl<$Res, _$_SuperFctModel>
    implements _$$_SuperFctModelCopyWith<$Res> {
  __$$_SuperFctModelCopyWithImpl(
      _$_SuperFctModel _value, $Res Function(_$_SuperFctModel) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? response = freezed,
  }) {
    return _then(_$_SuperFctModel(
      response: freezed == response
          ? _value.response
          : response // ignore: cast_nullable_to_non_nullable
              as ResponseSuperFct?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$_SuperFctModel implements _SuperFctModel {
  const _$_SuperFctModel({@JsonKey(name: 'response') this.response});

  factory _$_SuperFctModel.fromJson(Map<String, dynamic> json) =>
      _$$_SuperFctModelFromJson(json);

  /// 초단기 예보조회
  @override
  @JsonKey(name: 'response')
  final ResponseSuperFct? response;

  @override
  String toString() {
    return 'SuperFctModel(response: $response)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$_SuperFctModel &&
            (identical(other.response, response) ||
                other.response == response));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, response);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$_SuperFctModelCopyWith<_$_SuperFctModel> get copyWith =>
      __$$_SuperFctModelCopyWithImpl<_$_SuperFctModel>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$_SuperFctModelToJson(
      this,
    );
  }
}

abstract class _SuperFctModel implements SuperFctModel {
  const factory _SuperFctModel(
          {@JsonKey(name: 'response') final ResponseSuperFct? response}) =
      _$_SuperFctModel;

  factory _SuperFctModel.fromJson(Map<String, dynamic> json) =
      _$_SuperFctModel.fromJson;

  @override

  /// 초단기 예보조회
  @JsonKey(name: 'response')
  ResponseSuperFct? get response;
  @override
  @JsonKey(ignore: true)
  _$$_SuperFctModelCopyWith<_$_SuperFctModel> get copyWith =>
      throw _privateConstructorUsedError;
}

ResponseSuperFct _$ResponseSuperFctFromJson(Map<String, dynamic> json) {
  return _ResponseSuperFct.fromJson(json);
}

/// @nodoc
mixin _$ResponseSuperFct {
  @JsonKey(name: 'header')
  HeaderSuperFct? get header => throw _privateConstructorUsedError;
  @JsonKey(name: 'body')
  BodySuperFct? get body => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $ResponseSuperFctCopyWith<ResponseSuperFct> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ResponseSuperFctCopyWith<$Res> {
  factory $ResponseSuperFctCopyWith(
          ResponseSuperFct value, $Res Function(ResponseSuperFct) then) =
      _$ResponseSuperFctCopyWithImpl<$Res, ResponseSuperFct>;
  @useResult
  $Res call(
      {@JsonKey(name: 'header') HeaderSuperFct? header,
      @JsonKey(name: 'body') BodySuperFct? body});

  $HeaderSuperFctCopyWith<$Res>? get header;
  $BodySuperFctCopyWith<$Res>? get body;
}

/// @nodoc
class _$ResponseSuperFctCopyWithImpl<$Res, $Val extends ResponseSuperFct>
    implements $ResponseSuperFctCopyWith<$Res> {
  _$ResponseSuperFctCopyWithImpl(this._value, this._then);

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
              as HeaderSuperFct?,
      body: freezed == body
          ? _value.body
          : body // ignore: cast_nullable_to_non_nullable
              as BodySuperFct?,
    ) as $Val);
  }

  @override
  @pragma('vm:prefer-inline')
  $HeaderSuperFctCopyWith<$Res>? get header {
    if (_value.header == null) {
      return null;
    }

    return $HeaderSuperFctCopyWith<$Res>(_value.header!, (value) {
      return _then(_value.copyWith(header: value) as $Val);
    });
  }

  @override
  @pragma('vm:prefer-inline')
  $BodySuperFctCopyWith<$Res>? get body {
    if (_value.body == null) {
      return null;
    }

    return $BodySuperFctCopyWith<$Res>(_value.body!, (value) {
      return _then(_value.copyWith(body: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$_ResponseSuperFctCopyWith<$Res>
    implements $ResponseSuperFctCopyWith<$Res> {
  factory _$$_ResponseSuperFctCopyWith(
          _$_ResponseSuperFct value, $Res Function(_$_ResponseSuperFct) then) =
      __$$_ResponseSuperFctCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@JsonKey(name: 'header') HeaderSuperFct? header,
      @JsonKey(name: 'body') BodySuperFct? body});

  @override
  $HeaderSuperFctCopyWith<$Res>? get header;
  @override
  $BodySuperFctCopyWith<$Res>? get body;
}

/// @nodoc
class __$$_ResponseSuperFctCopyWithImpl<$Res>
    extends _$ResponseSuperFctCopyWithImpl<$Res, _$_ResponseSuperFct>
    implements _$$_ResponseSuperFctCopyWith<$Res> {
  __$$_ResponseSuperFctCopyWithImpl(
      _$_ResponseSuperFct _value, $Res Function(_$_ResponseSuperFct) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? header = freezed,
    Object? body = freezed,
  }) {
    return _then(_$_ResponseSuperFct(
      header: freezed == header
          ? _value.header
          : header // ignore: cast_nullable_to_non_nullable
              as HeaderSuperFct?,
      body: freezed == body
          ? _value.body
          : body // ignore: cast_nullable_to_non_nullable
              as BodySuperFct?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$_ResponseSuperFct implements _ResponseSuperFct {
  const _$_ResponseSuperFct(
      {@JsonKey(name: 'header') this.header, @JsonKey(name: 'body') this.body});

  factory _$_ResponseSuperFct.fromJson(Map<String, dynamic> json) =>
      _$$_ResponseSuperFctFromJson(json);

  @override
  @JsonKey(name: 'header')
  final HeaderSuperFct? header;
  @override
  @JsonKey(name: 'body')
  final BodySuperFct? body;

  @override
  String toString() {
    return 'ResponseSuperFct(header: $header, body: $body)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$_ResponseSuperFct &&
            (identical(other.header, header) || other.header == header) &&
            (identical(other.body, body) || other.body == body));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, header, body);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$_ResponseSuperFctCopyWith<_$_ResponseSuperFct> get copyWith =>
      __$$_ResponseSuperFctCopyWithImpl<_$_ResponseSuperFct>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$_ResponseSuperFctToJson(
      this,
    );
  }
}

abstract class _ResponseSuperFct implements ResponseSuperFct {
  const factory _ResponseSuperFct(
      {@JsonKey(name: 'header') final HeaderSuperFct? header,
      @JsonKey(name: 'body') final BodySuperFct? body}) = _$_ResponseSuperFct;

  factory _ResponseSuperFct.fromJson(Map<String, dynamic> json) =
      _$_ResponseSuperFct.fromJson;

  @override
  @JsonKey(name: 'header')
  HeaderSuperFct? get header;
  @override
  @JsonKey(name: 'body')
  BodySuperFct? get body;
  @override
  @JsonKey(ignore: true)
  _$$_ResponseSuperFctCopyWith<_$_ResponseSuperFct> get copyWith =>
      throw _privateConstructorUsedError;
}

BodySuperFct _$BodySuperFctFromJson(Map<String, dynamic> json) {
  return _BodySuperFct.fromJson(json);
}

/// @nodoc
mixin _$BodySuperFct {
  @JsonKey(name: 'dataType')
  String? get dataType => throw _privateConstructorUsedError;
  @JsonKey(name: 'items')
  ItemsSuperFct? get items => throw _privateConstructorUsedError;
  @JsonKey(name: 'pageNo')
  int? get pageNo => throw _privateConstructorUsedError;
  @JsonKey(name: 'numOfRows')
  int? get numOfRows => throw _privateConstructorUsedError;
  @JsonKey(name: 'totalCount')
  int? get totalCount => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $BodySuperFctCopyWith<BodySuperFct> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $BodySuperFctCopyWith<$Res> {
  factory $BodySuperFctCopyWith(
          BodySuperFct value, $Res Function(BodySuperFct) then) =
      _$BodySuperFctCopyWithImpl<$Res, BodySuperFct>;
  @useResult
  $Res call(
      {@JsonKey(name: 'dataType') String? dataType,
      @JsonKey(name: 'items') ItemsSuperFct? items,
      @JsonKey(name: 'pageNo') int? pageNo,
      @JsonKey(name: 'numOfRows') int? numOfRows,
      @JsonKey(name: 'totalCount') int? totalCount});

  $ItemsSuperFctCopyWith<$Res>? get items;
}

/// @nodoc
class _$BodySuperFctCopyWithImpl<$Res, $Val extends BodySuperFct>
    implements $BodySuperFctCopyWith<$Res> {
  _$BodySuperFctCopyWithImpl(this._value, this._then);

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
              as ItemsSuperFct?,
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
  $ItemsSuperFctCopyWith<$Res>? get items {
    if (_value.items == null) {
      return null;
    }

    return $ItemsSuperFctCopyWith<$Res>(_value.items!, (value) {
      return _then(_value.copyWith(items: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$_BodySuperFctCopyWith<$Res>
    implements $BodySuperFctCopyWith<$Res> {
  factory _$$_BodySuperFctCopyWith(
          _$_BodySuperFct value, $Res Function(_$_BodySuperFct) then) =
      __$$_BodySuperFctCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@JsonKey(name: 'dataType') String? dataType,
      @JsonKey(name: 'items') ItemsSuperFct? items,
      @JsonKey(name: 'pageNo') int? pageNo,
      @JsonKey(name: 'numOfRows') int? numOfRows,
      @JsonKey(name: 'totalCount') int? totalCount});

  @override
  $ItemsSuperFctCopyWith<$Res>? get items;
}

/// @nodoc
class __$$_BodySuperFctCopyWithImpl<$Res>
    extends _$BodySuperFctCopyWithImpl<$Res, _$_BodySuperFct>
    implements _$$_BodySuperFctCopyWith<$Res> {
  __$$_BodySuperFctCopyWithImpl(
      _$_BodySuperFct _value, $Res Function(_$_BodySuperFct) _then)
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
    return _then(_$_BodySuperFct(
      dataType: freezed == dataType
          ? _value.dataType
          : dataType // ignore: cast_nullable_to_non_nullable
              as String?,
      items: freezed == items
          ? _value.items
          : items // ignore: cast_nullable_to_non_nullable
              as ItemsSuperFct?,
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
class _$_BodySuperFct implements _BodySuperFct {
  const _$_BodySuperFct(
      {@JsonKey(name: 'dataType') this.dataType,
      @JsonKey(name: 'items') this.items,
      @JsonKey(name: 'pageNo') this.pageNo,
      @JsonKey(name: 'numOfRows') this.numOfRows,
      @JsonKey(name: 'totalCount') this.totalCount});

  factory _$_BodySuperFct.fromJson(Map<String, dynamic> json) =>
      _$$_BodySuperFctFromJson(json);

  @override
  @JsonKey(name: 'dataType')
  final String? dataType;
  @override
  @JsonKey(name: 'items')
  final ItemsSuperFct? items;
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
    return 'BodySuperFct(dataType: $dataType, items: $items, pageNo: $pageNo, numOfRows: $numOfRows, totalCount: $totalCount)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$_BodySuperFct &&
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
  _$$_BodySuperFctCopyWith<_$_BodySuperFct> get copyWith =>
      __$$_BodySuperFctCopyWithImpl<_$_BodySuperFct>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$_BodySuperFctToJson(
      this,
    );
  }
}

abstract class _BodySuperFct implements BodySuperFct {
  const factory _BodySuperFct(
      {@JsonKey(name: 'dataType') final String? dataType,
      @JsonKey(name: 'items') final ItemsSuperFct? items,
      @JsonKey(name: 'pageNo') final int? pageNo,
      @JsonKey(name: 'numOfRows') final int? numOfRows,
      @JsonKey(name: 'totalCount') final int? totalCount}) = _$_BodySuperFct;

  factory _BodySuperFct.fromJson(Map<String, dynamic> json) =
      _$_BodySuperFct.fromJson;

  @override
  @JsonKey(name: 'dataType')
  String? get dataType;
  @override
  @JsonKey(name: 'items')
  ItemsSuperFct? get items;
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
  _$$_BodySuperFctCopyWith<_$_BodySuperFct> get copyWith =>
      throw _privateConstructorUsedError;
}

ItemsSuperFct _$ItemsSuperFctFromJson(Map<String, dynamic> json) {
  return _ItemsSuperFct.fromJson(json);
}

/// @nodoc
mixin _$ItemsSuperFct {
  @JsonKey(name: 'item')
  List<ItemSuperFct>? get item => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $ItemsSuperFctCopyWith<ItemsSuperFct> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ItemsSuperFctCopyWith<$Res> {
  factory $ItemsSuperFctCopyWith(
          ItemsSuperFct value, $Res Function(ItemsSuperFct) then) =
      _$ItemsSuperFctCopyWithImpl<$Res, ItemsSuperFct>;
  @useResult
  $Res call({@JsonKey(name: 'item') List<ItemSuperFct>? item});
}

/// @nodoc
class _$ItemsSuperFctCopyWithImpl<$Res, $Val extends ItemsSuperFct>
    implements $ItemsSuperFctCopyWith<$Res> {
  _$ItemsSuperFctCopyWithImpl(this._value, this._then);

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
              as List<ItemSuperFct>?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$_ItemsSuperFctCopyWith<$Res>
    implements $ItemsSuperFctCopyWith<$Res> {
  factory _$$_ItemsSuperFctCopyWith(
          _$_ItemsSuperFct value, $Res Function(_$_ItemsSuperFct) then) =
      __$$_ItemsSuperFctCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({@JsonKey(name: 'item') List<ItemSuperFct>? item});
}

/// @nodoc
class __$$_ItemsSuperFctCopyWithImpl<$Res>
    extends _$ItemsSuperFctCopyWithImpl<$Res, _$_ItemsSuperFct>
    implements _$$_ItemsSuperFctCopyWith<$Res> {
  __$$_ItemsSuperFctCopyWithImpl(
      _$_ItemsSuperFct _value, $Res Function(_$_ItemsSuperFct) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? item = freezed,
  }) {
    return _then(_$_ItemsSuperFct(
      item: freezed == item
          ? _value._item
          : item // ignore: cast_nullable_to_non_nullable
              as List<ItemSuperFct>?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$_ItemsSuperFct implements _ItemsSuperFct {
  const _$_ItemsSuperFct(
      {@JsonKey(name: 'item') final List<ItemSuperFct>? item})
      : _item = item;

  factory _$_ItemsSuperFct.fromJson(Map<String, dynamic> json) =>
      _$$_ItemsSuperFctFromJson(json);

  final List<ItemSuperFct>? _item;
  @override
  @JsonKey(name: 'item')
  List<ItemSuperFct>? get item {
    final value = _item;
    if (value == null) return null;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  @override
  String toString() {
    return 'ItemsSuperFct(item: $item)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$_ItemsSuperFct &&
            const DeepCollectionEquality().equals(other._item, _item));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode =>
      Object.hash(runtimeType, const DeepCollectionEquality().hash(_item));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$_ItemsSuperFctCopyWith<_$_ItemsSuperFct> get copyWith =>
      __$$_ItemsSuperFctCopyWithImpl<_$_ItemsSuperFct>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$_ItemsSuperFctToJson(
      this,
    );
  }
}

abstract class _ItemsSuperFct implements ItemsSuperFct {
  const factory _ItemsSuperFct(
          {@JsonKey(name: 'item') final List<ItemSuperFct>? item}) =
      _$_ItemsSuperFct;

  factory _ItemsSuperFct.fromJson(Map<String, dynamic> json) =
      _$_ItemsSuperFct.fromJson;

  @override
  @JsonKey(name: 'item')
  List<ItemSuperFct>? get item;
  @override
  @JsonKey(ignore: true)
  _$$_ItemsSuperFctCopyWith<_$_ItemsSuperFct> get copyWith =>
      throw _privateConstructorUsedError;
}

ItemSuperFct _$ItemSuperFctFromJson(Map<String, dynamic> json) {
  return _ItemSuperFct.fromJson(json);
}

/// @nodoc
mixin _$ItemSuperFct {
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
  $ItemSuperFctCopyWith<ItemSuperFct> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ItemSuperFctCopyWith<$Res> {
  factory $ItemSuperFctCopyWith(
          ItemSuperFct value, $Res Function(ItemSuperFct) then) =
      _$ItemSuperFctCopyWithImpl<$Res, ItemSuperFct>;
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
class _$ItemSuperFctCopyWithImpl<$Res, $Val extends ItemSuperFct>
    implements $ItemSuperFctCopyWith<$Res> {
  _$ItemSuperFctCopyWithImpl(this._value, this._then);

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
abstract class _$$_ItemSuperFctCopyWith<$Res>
    implements $ItemSuperFctCopyWith<$Res> {
  factory _$$_ItemSuperFctCopyWith(
          _$_ItemSuperFct value, $Res Function(_$_ItemSuperFct) then) =
      __$$_ItemSuperFctCopyWithImpl<$Res>;
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
class __$$_ItemSuperFctCopyWithImpl<$Res>
    extends _$ItemSuperFctCopyWithImpl<$Res, _$_ItemSuperFct>
    implements _$$_ItemSuperFctCopyWith<$Res> {
  __$$_ItemSuperFctCopyWithImpl(
      _$_ItemSuperFct _value, $Res Function(_$_ItemSuperFct) _then)
      : super(_value, _then);

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
    return _then(_$_ItemSuperFct(
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
class _$_ItemSuperFct implements _ItemSuperFct {
  const _$_ItemSuperFct(
      {@JsonKey(name: 'baseDate') this.baseDate,
      @JsonKey(name: 'baseTime') this.baseTime,
      @JsonKey(name: 'category') this.category,
      @JsonKey(name: 'fcstDate') this.fcstDate,
      @JsonKey(name: 'fcstTime') this.fcstTime,
      @JsonKey(name: 'fcstValue') this.fcstValue,
      @JsonKey(name: 'nx') this.nx,
      @JsonKey(name: 'ny') this.ny});

  factory _$_ItemSuperFct.fromJson(Map<String, dynamic> json) =>
      _$$_ItemSuperFctFromJson(json);

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
    return 'ItemSuperFct(baseDate: $baseDate, baseTime: $baseTime, category: $category, fcstDate: $fcstDate, fcstTime: $fcstTime, fcstValue: $fcstValue, nx: $nx, ny: $ny)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$_ItemSuperFct &&
            (identical(other.baseDate, baseDate) ||
                other.baseDate == baseDate) &&
            (identical(other.baseTime, baseTime) ||
                other.baseTime == baseTime) &&
            (identical(other.category, category) ||
                other.category == category) &&
            (identical(other.fcstDate, fcstDate) ||
                other.fcstDate == fcstDate) &&
            (identical(other.fcstTime, fcstTime) ||
                other.fcstTime == fcstTime) &&
            (identical(other.fcstValue, fcstValue) ||
                other.fcstValue == fcstValue) &&
            (identical(other.nx, nx) || other.nx == nx) &&
            (identical(other.ny, ny) || other.ny == ny));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, baseDate, baseTime, category,
      fcstDate, fcstTime, fcstValue, nx, ny);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$_ItemSuperFctCopyWith<_$_ItemSuperFct> get copyWith =>
      __$$_ItemSuperFctCopyWithImpl<_$_ItemSuperFct>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$_ItemSuperFctToJson(
      this,
    );
  }
}

abstract class _ItemSuperFct implements ItemSuperFct {
  const factory _ItemSuperFct(
      {@JsonKey(name: 'baseDate') final String? baseDate,
      @JsonKey(name: 'baseTime') final String? baseTime,
      @JsonKey(name: 'category') final String? category,
      @JsonKey(name: 'fcstDate') final String? fcstDate,
      @JsonKey(name: 'fcstTime') final String? fcstTime,
      @JsonKey(name: 'fcstValue') final String? fcstValue,
      @JsonKey(name: 'nx') final int? nx,
      @JsonKey(name: 'ny') final int? ny}) = _$_ItemSuperFct;

  factory _ItemSuperFct.fromJson(Map<String, dynamic> json) =
      _$_ItemSuperFct.fromJson;

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
  _$$_ItemSuperFctCopyWith<_$_ItemSuperFct> get copyWith =>
      throw _privateConstructorUsedError;
}

HeaderSuperFct _$HeaderSuperFctFromJson(Map<String, dynamic> json) {
  return _HeaderSuperFct.fromJson(json);
}

/// @nodoc
mixin _$HeaderSuperFct {
  @JsonKey(name: 'resultCode')
  String? get resultCode => throw _privateConstructorUsedError;
  @JsonKey(name: 'resultMsg')
  String? get resultMsg => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $HeaderSuperFctCopyWith<HeaderSuperFct> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $HeaderSuperFctCopyWith<$Res> {
  factory $HeaderSuperFctCopyWith(
          HeaderSuperFct value, $Res Function(HeaderSuperFct) then) =
      _$HeaderSuperFctCopyWithImpl<$Res, HeaderSuperFct>;
  @useResult
  $Res call(
      {@JsonKey(name: 'resultCode') String? resultCode,
      @JsonKey(name: 'resultMsg') String? resultMsg});
}

/// @nodoc
class _$HeaderSuperFctCopyWithImpl<$Res, $Val extends HeaderSuperFct>
    implements $HeaderSuperFctCopyWith<$Res> {
  _$HeaderSuperFctCopyWithImpl(this._value, this._then);

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
abstract class _$$_HeaderSuperFctCopyWith<$Res>
    implements $HeaderSuperFctCopyWith<$Res> {
  factory _$$_HeaderSuperFctCopyWith(
          _$_HeaderSuperFct value, $Res Function(_$_HeaderSuperFct) then) =
      __$$_HeaderSuperFctCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@JsonKey(name: 'resultCode') String? resultCode,
      @JsonKey(name: 'resultMsg') String? resultMsg});
}

/// @nodoc
class __$$_HeaderSuperFctCopyWithImpl<$Res>
    extends _$HeaderSuperFctCopyWithImpl<$Res, _$_HeaderSuperFct>
    implements _$$_HeaderSuperFctCopyWith<$Res> {
  __$$_HeaderSuperFctCopyWithImpl(
      _$_HeaderSuperFct _value, $Res Function(_$_HeaderSuperFct) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? resultCode = freezed,
    Object? resultMsg = freezed,
  }) {
    return _then(_$_HeaderSuperFct(
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
class _$_HeaderSuperFct implements _HeaderSuperFct {
  const _$_HeaderSuperFct(
      {@JsonKey(name: 'resultCode') this.resultCode,
      @JsonKey(name: 'resultMsg') this.resultMsg});

  factory _$_HeaderSuperFct.fromJson(Map<String, dynamic> json) =>
      _$$_HeaderSuperFctFromJson(json);

  @override
  @JsonKey(name: 'resultCode')
  final String? resultCode;
  @override
  @JsonKey(name: 'resultMsg')
  final String? resultMsg;

  @override
  String toString() {
    return 'HeaderSuperFct(resultCode: $resultCode, resultMsg: $resultMsg)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$_HeaderSuperFct &&
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
  _$$_HeaderSuperFctCopyWith<_$_HeaderSuperFct> get copyWith =>
      __$$_HeaderSuperFctCopyWithImpl<_$_HeaderSuperFct>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$_HeaderSuperFctToJson(
      this,
    );
  }
}

abstract class _HeaderSuperFct implements HeaderSuperFct {
  const factory _HeaderSuperFct(
      {@JsonKey(name: 'resultCode') final String? resultCode,
      @JsonKey(name: 'resultMsg') final String? resultMsg}) = _$_HeaderSuperFct;

  factory _HeaderSuperFct.fromJson(Map<String, dynamic> json) =
      _$_HeaderSuperFct.fromJson;

  @override
  @JsonKey(name: 'resultCode')
  String? get resultCode;
  @override
  @JsonKey(name: 'resultMsg')
  String? get resultMsg;
  @override
  @JsonKey(ignore: true)
  _$$_HeaderSuperFctCopyWith<_$_HeaderSuperFct> get copyWith =>
      throw _privateConstructorUsedError;
}
