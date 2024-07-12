// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target

part of 'super_nct_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#custom-getters-and-methods');

SuperNctModel _$SuperNctModelFromJson(Map<String, dynamic> json) {
  return _SuperNctModel.fromJson(json);
}

/// @nodoc
mixin _$SuperNctModel {
  /// 초단기 실황 조회
  @JsonKey(name: 'response')
  ResponseBean? get response => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $SuperNctModelCopyWith<SuperNctModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SuperNctModelCopyWith<$Res> {
  factory $SuperNctModelCopyWith(
          SuperNctModel value, $Res Function(SuperNctModel) then) =
      _$SuperNctModelCopyWithImpl<$Res, SuperNctModel>;
  @useResult
  $Res call({@JsonKey(name: 'response') ResponseBean? response});

  $ResponseBeanCopyWith<$Res>? get response;
}

/// @nodoc
class _$SuperNctModelCopyWithImpl<$Res, $Val extends SuperNctModel>
    implements $SuperNctModelCopyWith<$Res> {
  _$SuperNctModelCopyWithImpl(this._value, this._then);

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
              as ResponseBean?,
    ) as $Val);
  }

  @override
  @pragma('vm:prefer-inline')
  $ResponseBeanCopyWith<$Res>? get response {
    if (_value.response == null) {
      return null;
    }

    return $ResponseBeanCopyWith<$Res>(_value.response!, (value) {
      return _then(_value.copyWith(response: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$_SuperNctModelCopyWith<$Res>
    implements $SuperNctModelCopyWith<$Res> {
  factory _$$_SuperNctModelCopyWith(
          _$_SuperNctModel value, $Res Function(_$_SuperNctModel) then) =
      __$$_SuperNctModelCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({@JsonKey(name: 'response') ResponseBean? response});

  @override
  $ResponseBeanCopyWith<$Res>? get response;
}

/// @nodoc
class __$$_SuperNctModelCopyWithImpl<$Res>
    extends _$SuperNctModelCopyWithImpl<$Res, _$_SuperNctModel>
    implements _$$_SuperNctModelCopyWith<$Res> {
  __$$_SuperNctModelCopyWithImpl(
      _$_SuperNctModel _value, $Res Function(_$_SuperNctModel) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? response = freezed,
  }) {
    return _then(_$_SuperNctModel(
      response: freezed == response
          ? _value.response
          : response // ignore: cast_nullable_to_non_nullable
              as ResponseBean?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$_SuperNctModel implements _SuperNctModel {
  const _$_SuperNctModel({@JsonKey(name: 'response') this.response});

  factory _$_SuperNctModel.fromJson(Map<String, dynamic> json) =>
      _$$_SuperNctModelFromJson(json);

  /// 초단기 실황 조회
  @override
  @JsonKey(name: 'response')
  final ResponseBean? response;

  @override
  String toString() {
    return 'SuperNctModel(response: $response)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$_SuperNctModel &&
            (identical(other.response, response) ||
                other.response == response));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, response);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$_SuperNctModelCopyWith<_$_SuperNctModel> get copyWith =>
      __$$_SuperNctModelCopyWithImpl<_$_SuperNctModel>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$_SuperNctModelToJson(
      this,
    );
  }
}

abstract class _SuperNctModel implements SuperNctModel {
  const factory _SuperNctModel(
          {@JsonKey(name: 'response') final ResponseBean? response}) =
      _$_SuperNctModel;

  factory _SuperNctModel.fromJson(Map<String, dynamic> json) =
      _$_SuperNctModel.fromJson;

  @override

  /// 초단기 실황 조회
  @JsonKey(name: 'response')
  ResponseBean? get response;
  @override
  @JsonKey(ignore: true)
  _$$_SuperNctModelCopyWith<_$_SuperNctModel> get copyWith =>
      throw _privateConstructorUsedError;
}

ResponseBean _$ResponseBeanFromJson(Map<String, dynamic> json) {
  return _ResponseBean.fromJson(json);
}

/// @nodoc
mixin _$ResponseBean {
  @JsonKey(name: 'header')
  HeaderSuperNct? get header => throw _privateConstructorUsedError;
  @JsonKey(name: 'body')
  BodySuperNct? get body => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $ResponseBeanCopyWith<ResponseBean> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ResponseBeanCopyWith<$Res> {
  factory $ResponseBeanCopyWith(
          ResponseBean value, $Res Function(ResponseBean) then) =
      _$ResponseBeanCopyWithImpl<$Res, ResponseBean>;
  @useResult
  $Res call(
      {@JsonKey(name: 'header') HeaderSuperNct? header,
      @JsonKey(name: 'body') BodySuperNct? body});

  $HeaderSuperNctCopyWith<$Res>? get header;
  $BodySuperNctCopyWith<$Res>? get body;
}

/// @nodoc
class _$ResponseBeanCopyWithImpl<$Res, $Val extends ResponseBean>
    implements $ResponseBeanCopyWith<$Res> {
  _$ResponseBeanCopyWithImpl(this._value, this._then);

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
              as HeaderSuperNct?,
      body: freezed == body
          ? _value.body
          : body // ignore: cast_nullable_to_non_nullable
              as BodySuperNct?,
    ) as $Val);
  }

  @override
  @pragma('vm:prefer-inline')
  $HeaderSuperNctCopyWith<$Res>? get header {
    if (_value.header == null) {
      return null;
    }

    return $HeaderSuperNctCopyWith<$Res>(_value.header!, (value) {
      return _then(_value.copyWith(header: value) as $Val);
    });
  }

  @override
  @pragma('vm:prefer-inline')
  $BodySuperNctCopyWith<$Res>? get body {
    if (_value.body == null) {
      return null;
    }

    return $BodySuperNctCopyWith<$Res>(_value.body!, (value) {
      return _then(_value.copyWith(body: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$_ResponseBeanCopyWith<$Res>
    implements $ResponseBeanCopyWith<$Res> {
  factory _$$_ResponseBeanCopyWith(
          _$_ResponseBean value, $Res Function(_$_ResponseBean) then) =
      __$$_ResponseBeanCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@JsonKey(name: 'header') HeaderSuperNct? header,
      @JsonKey(name: 'body') BodySuperNct? body});

  @override
  $HeaderSuperNctCopyWith<$Res>? get header;
  @override
  $BodySuperNctCopyWith<$Res>? get body;
}

/// @nodoc
class __$$_ResponseBeanCopyWithImpl<$Res>
    extends _$ResponseBeanCopyWithImpl<$Res, _$_ResponseBean>
    implements _$$_ResponseBeanCopyWith<$Res> {
  __$$_ResponseBeanCopyWithImpl(
      _$_ResponseBean _value, $Res Function(_$_ResponseBean) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? header = freezed,
    Object? body = freezed,
  }) {
    return _then(_$_ResponseBean(
      header: freezed == header
          ? _value.header
          : header // ignore: cast_nullable_to_non_nullable
              as HeaderSuperNct?,
      body: freezed == body
          ? _value.body
          : body // ignore: cast_nullable_to_non_nullable
              as BodySuperNct?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$_ResponseBean implements _ResponseBean {
  const _$_ResponseBean(
      {@JsonKey(name: 'header') this.header, @JsonKey(name: 'body') this.body});

  factory _$_ResponseBean.fromJson(Map<String, dynamic> json) =>
      _$$_ResponseBeanFromJson(json);

  @override
  @JsonKey(name: 'header')
  final HeaderSuperNct? header;
  @override
  @JsonKey(name: 'body')
  final BodySuperNct? body;

  @override
  String toString() {
    return 'ResponseBean(header: $header, body: $body)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$_ResponseBean &&
            (identical(other.header, header) || other.header == header) &&
            (identical(other.body, body) || other.body == body));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, header, body);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$_ResponseBeanCopyWith<_$_ResponseBean> get copyWith =>
      __$$_ResponseBeanCopyWithImpl<_$_ResponseBean>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$_ResponseBeanToJson(
      this,
    );
  }
}

abstract class _ResponseBean implements ResponseBean {
  const factory _ResponseBean(
      {@JsonKey(name: 'header') final HeaderSuperNct? header,
      @JsonKey(name: 'body') final BodySuperNct? body}) = _$_ResponseBean;

  factory _ResponseBean.fromJson(Map<String, dynamic> json) =
      _$_ResponseBean.fromJson;

  @override
  @JsonKey(name: 'header')
  HeaderSuperNct? get header;
  @override
  @JsonKey(name: 'body')
  BodySuperNct? get body;
  @override
  @JsonKey(ignore: true)
  _$$_ResponseBeanCopyWith<_$_ResponseBean> get copyWith =>
      throw _privateConstructorUsedError;
}

BodySuperNct _$BodySuperNctFromJson(Map<String, dynamic> json) {
  return _BodySuperNct.fromJson(json);
}

/// @nodoc
mixin _$BodySuperNct {
  @JsonKey(name: 'dataType')
  String? get dataType => throw _privateConstructorUsedError;
  @JsonKey(name: 'items')
  ItemsSuperNct? get items => throw _privateConstructorUsedError;
  @JsonKey(name: 'pageNo')
  int? get pageNo => throw _privateConstructorUsedError;
  @JsonKey(name: 'numOfRows')
  int? get numOfRows => throw _privateConstructorUsedError;
  @JsonKey(name: 'totalCount')
  int? get totalCount => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $BodySuperNctCopyWith<BodySuperNct> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $BodySuperNctCopyWith<$Res> {
  factory $BodySuperNctCopyWith(
          BodySuperNct value, $Res Function(BodySuperNct) then) =
      _$BodySuperNctCopyWithImpl<$Res, BodySuperNct>;
  @useResult
  $Res call(
      {@JsonKey(name: 'dataType') String? dataType,
      @JsonKey(name: 'items') ItemsSuperNct? items,
      @JsonKey(name: 'pageNo') int? pageNo,
      @JsonKey(name: 'numOfRows') int? numOfRows,
      @JsonKey(name: 'totalCount') int? totalCount});

  $ItemsSuperNctCopyWith<$Res>? get items;
}

/// @nodoc
class _$BodySuperNctCopyWithImpl<$Res, $Val extends BodySuperNct>
    implements $BodySuperNctCopyWith<$Res> {
  _$BodySuperNctCopyWithImpl(this._value, this._then);

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
              as ItemsSuperNct?,
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
  $ItemsSuperNctCopyWith<$Res>? get items {
    if (_value.items == null) {
      return null;
    }

    return $ItemsSuperNctCopyWith<$Res>(_value.items!, (value) {
      return _then(_value.copyWith(items: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$_BodySuperNctCopyWith<$Res>
    implements $BodySuperNctCopyWith<$Res> {
  factory _$$_BodySuperNctCopyWith(
          _$_BodySuperNct value, $Res Function(_$_BodySuperNct) then) =
      __$$_BodySuperNctCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@JsonKey(name: 'dataType') String? dataType,
      @JsonKey(name: 'items') ItemsSuperNct? items,
      @JsonKey(name: 'pageNo') int? pageNo,
      @JsonKey(name: 'numOfRows') int? numOfRows,
      @JsonKey(name: 'totalCount') int? totalCount});

  @override
  $ItemsSuperNctCopyWith<$Res>? get items;
}

/// @nodoc
class __$$_BodySuperNctCopyWithImpl<$Res>
    extends _$BodySuperNctCopyWithImpl<$Res, _$_BodySuperNct>
    implements _$$_BodySuperNctCopyWith<$Res> {
  __$$_BodySuperNctCopyWithImpl(
      _$_BodySuperNct _value, $Res Function(_$_BodySuperNct) _then)
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
    return _then(_$_BodySuperNct(
      dataType: freezed == dataType
          ? _value.dataType
          : dataType // ignore: cast_nullable_to_non_nullable
              as String?,
      items: freezed == items
          ? _value.items
          : items // ignore: cast_nullable_to_non_nullable
              as ItemsSuperNct?,
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
class _$_BodySuperNct implements _BodySuperNct {
  const _$_BodySuperNct(
      {@JsonKey(name: 'dataType') this.dataType,
      @JsonKey(name: 'items') this.items,
      @JsonKey(name: 'pageNo') this.pageNo,
      @JsonKey(name: 'numOfRows') this.numOfRows,
      @JsonKey(name: 'totalCount') this.totalCount});

  factory _$_BodySuperNct.fromJson(Map<String, dynamic> json) =>
      _$$_BodySuperNctFromJson(json);

  @override
  @JsonKey(name: 'dataType')
  final String? dataType;
  @override
  @JsonKey(name: 'items')
  final ItemsSuperNct? items;
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
    return 'BodySuperNct(dataType: $dataType, items: $items, pageNo: $pageNo, numOfRows: $numOfRows, totalCount: $totalCount)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$_BodySuperNct &&
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
  _$$_BodySuperNctCopyWith<_$_BodySuperNct> get copyWith =>
      __$$_BodySuperNctCopyWithImpl<_$_BodySuperNct>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$_BodySuperNctToJson(
      this,
    );
  }
}

abstract class _BodySuperNct implements BodySuperNct {
  const factory _BodySuperNct(
      {@JsonKey(name: 'dataType') final String? dataType,
      @JsonKey(name: 'items') final ItemsSuperNct? items,
      @JsonKey(name: 'pageNo') final int? pageNo,
      @JsonKey(name: 'numOfRows') final int? numOfRows,
      @JsonKey(name: 'totalCount') final int? totalCount}) = _$_BodySuperNct;

  factory _BodySuperNct.fromJson(Map<String, dynamic> json) =
      _$_BodySuperNct.fromJson;

  @override
  @JsonKey(name: 'dataType')
  String? get dataType;
  @override
  @JsonKey(name: 'items')
  ItemsSuperNct? get items;
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
  _$$_BodySuperNctCopyWith<_$_BodySuperNct> get copyWith =>
      throw _privateConstructorUsedError;
}

ItemsSuperNct _$ItemsSuperNctFromJson(Map<String, dynamic> json) {
  return _ItemsSuperNct.fromJson(json);
}

/// @nodoc
mixin _$ItemsSuperNct {
  @JsonKey(name: 'item')
  List<ItemSuperNct>? get item => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $ItemsSuperNctCopyWith<ItemsSuperNct> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ItemsSuperNctCopyWith<$Res> {
  factory $ItemsSuperNctCopyWith(
          ItemsSuperNct value, $Res Function(ItemsSuperNct) then) =
      _$ItemsSuperNctCopyWithImpl<$Res, ItemsSuperNct>;
  @useResult
  $Res call({@JsonKey(name: 'item') List<ItemSuperNct>? item});
}

/// @nodoc
class _$ItemsSuperNctCopyWithImpl<$Res, $Val extends ItemsSuperNct>
    implements $ItemsSuperNctCopyWith<$Res> {
  _$ItemsSuperNctCopyWithImpl(this._value, this._then);

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
              as List<ItemSuperNct>?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$_ItemsSuperNctCopyWith<$Res>
    implements $ItemsSuperNctCopyWith<$Res> {
  factory _$$_ItemsSuperNctCopyWith(
          _$_ItemsSuperNct value, $Res Function(_$_ItemsSuperNct) then) =
      __$$_ItemsSuperNctCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({@JsonKey(name: 'item') List<ItemSuperNct>? item});
}

/// @nodoc
class __$$_ItemsSuperNctCopyWithImpl<$Res>
    extends _$ItemsSuperNctCopyWithImpl<$Res, _$_ItemsSuperNct>
    implements _$$_ItemsSuperNctCopyWith<$Res> {
  __$$_ItemsSuperNctCopyWithImpl(
      _$_ItemsSuperNct _value, $Res Function(_$_ItemsSuperNct) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? item = freezed,
  }) {
    return _then(_$_ItemsSuperNct(
      item: freezed == item
          ? _value._item
          : item // ignore: cast_nullable_to_non_nullable
              as List<ItemSuperNct>?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$_ItemsSuperNct implements _ItemsSuperNct {
  const _$_ItemsSuperNct(
      {@JsonKey(name: 'item') final List<ItemSuperNct>? item})
      : _item = item;

  factory _$_ItemsSuperNct.fromJson(Map<String, dynamic> json) =>
      _$$_ItemsSuperNctFromJson(json);

  final List<ItemSuperNct>? _item;
  @override
  @JsonKey(name: 'item')
  List<ItemSuperNct>? get item {
    final value = _item;
    if (value == null) return null;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  @override
  String toString() {
    return 'ItemsSuperNct(item: $item)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$_ItemsSuperNct &&
            const DeepCollectionEquality().equals(other._item, _item));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode =>
      Object.hash(runtimeType, const DeepCollectionEquality().hash(_item));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$_ItemsSuperNctCopyWith<_$_ItemsSuperNct> get copyWith =>
      __$$_ItemsSuperNctCopyWithImpl<_$_ItemsSuperNct>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$_ItemsSuperNctToJson(
      this,
    );
  }
}

abstract class _ItemsSuperNct implements ItemsSuperNct {
  const factory _ItemsSuperNct(
          {@JsonKey(name: 'item') final List<ItemSuperNct>? item}) =
      _$_ItemsSuperNct;

  factory _ItemsSuperNct.fromJson(Map<String, dynamic> json) =
      _$_ItemsSuperNct.fromJson;

  @override
  @JsonKey(name: 'item')
  List<ItemSuperNct>? get item;
  @override
  @JsonKey(ignore: true)
  _$$_ItemsSuperNctCopyWith<_$_ItemsSuperNct> get copyWith =>
      throw _privateConstructorUsedError;
}

ItemSuperNct _$ItemSuperNctFromJson(Map<String, dynamic> json) {
  return _ItemSuperNct.fromJson(json);
}

/// @nodoc
mixin _$ItemSuperNct {
  @JsonKey(name: 'baseDate')
  String? get baseDate => throw _privateConstructorUsedError;
  @JsonKey(name: 'baseTime')
  String? get baseTime => throw _privateConstructorUsedError;
  @JsonKey(name: 'category')
  String? get category => throw _privateConstructorUsedError;
  @JsonKey(name: 'nx')
  int? get nx => throw _privateConstructorUsedError;
  @JsonKey(name: 'ny')
  int? get ny => throw _privateConstructorUsedError;
  @JsonKey(name: 'obsrValue')
  String? get obsrValue => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $ItemSuperNctCopyWith<ItemSuperNct> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ItemSuperNctCopyWith<$Res> {
  factory $ItemSuperNctCopyWith(
          ItemSuperNct value, $Res Function(ItemSuperNct) then) =
      _$ItemSuperNctCopyWithImpl<$Res, ItemSuperNct>;
  @useResult
  $Res call(
      {@JsonKey(name: 'baseDate') String? baseDate,
      @JsonKey(name: 'baseTime') String? baseTime,
      @JsonKey(name: 'category') String? category,
      @JsonKey(name: 'nx') int? nx,
      @JsonKey(name: 'ny') int? ny,
      @JsonKey(name: 'obsrValue') String? obsrValue});
}

/// @nodoc
class _$ItemSuperNctCopyWithImpl<$Res, $Val extends ItemSuperNct>
    implements $ItemSuperNctCopyWith<$Res> {
  _$ItemSuperNctCopyWithImpl(this._value, this._then);

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
    Object? nx = freezed,
    Object? ny = freezed,
    Object? obsrValue = freezed,
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
      nx: freezed == nx
          ? _value.nx
          : nx // ignore: cast_nullable_to_non_nullable
              as int?,
      ny: freezed == ny
          ? _value.ny
          : ny // ignore: cast_nullable_to_non_nullable
              as int?,
      obsrValue: freezed == obsrValue
          ? _value.obsrValue
          : obsrValue // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$_ItemSuperNctCopyWith<$Res>
    implements $ItemSuperNctCopyWith<$Res> {
  factory _$$_ItemSuperNctCopyWith(
          _$_ItemSuperNct value, $Res Function(_$_ItemSuperNct) then) =
      __$$_ItemSuperNctCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@JsonKey(name: 'baseDate') String? baseDate,
      @JsonKey(name: 'baseTime') String? baseTime,
      @JsonKey(name: 'category') String? category,
      @JsonKey(name: 'nx') int? nx,
      @JsonKey(name: 'ny') int? ny,
      @JsonKey(name: 'obsrValue') String? obsrValue});
}

/// @nodoc
class __$$_ItemSuperNctCopyWithImpl<$Res>
    extends _$ItemSuperNctCopyWithImpl<$Res, _$_ItemSuperNct>
    implements _$$_ItemSuperNctCopyWith<$Res> {
  __$$_ItemSuperNctCopyWithImpl(
      _$_ItemSuperNct _value, $Res Function(_$_ItemSuperNct) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? baseDate = freezed,
    Object? baseTime = freezed,
    Object? category = freezed,
    Object? nx = freezed,
    Object? ny = freezed,
    Object? obsrValue = freezed,
  }) {
    return _then(_$_ItemSuperNct(
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
      nx: freezed == nx
          ? _value.nx
          : nx // ignore: cast_nullable_to_non_nullable
              as int?,
      ny: freezed == ny
          ? _value.ny
          : ny // ignore: cast_nullable_to_non_nullable
              as int?,
      obsrValue: freezed == obsrValue
          ? _value.obsrValue
          : obsrValue // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$_ItemSuperNct implements _ItemSuperNct {
  const _$_ItemSuperNct(
      {@JsonKey(name: 'baseDate') this.baseDate,
      @JsonKey(name: 'baseTime') this.baseTime,
      @JsonKey(name: 'category') this.category,
      @JsonKey(name: 'nx') this.nx,
      @JsonKey(name: 'ny') this.ny,
      @JsonKey(name: 'obsrValue') this.obsrValue});

  factory _$_ItemSuperNct.fromJson(Map<String, dynamic> json) =>
      _$$_ItemSuperNctFromJson(json);

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
  @JsonKey(name: 'nx')
  final int? nx;
  @override
  @JsonKey(name: 'ny')
  final int? ny;
  @override
  @JsonKey(name: 'obsrValue')
  final String? obsrValue;

  @override
  String toString() {
    return 'ItemSuperNct(baseDate: $baseDate, baseTime: $baseTime, category: $category, nx: $nx, ny: $ny, obsrValue: $obsrValue)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$_ItemSuperNct &&
            (identical(other.baseDate, baseDate) ||
                other.baseDate == baseDate) &&
            (identical(other.baseTime, baseTime) ||
                other.baseTime == baseTime) &&
            (identical(other.category, category) ||
                other.category == category) &&
            (identical(other.nx, nx) || other.nx == nx) &&
            (identical(other.ny, ny) || other.ny == ny) &&
            (identical(other.obsrValue, obsrValue) ||
                other.obsrValue == obsrValue));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode =>
      Object.hash(runtimeType, baseDate, baseTime, category, nx, ny, obsrValue);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$_ItemSuperNctCopyWith<_$_ItemSuperNct> get copyWith =>
      __$$_ItemSuperNctCopyWithImpl<_$_ItemSuperNct>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$_ItemSuperNctToJson(
      this,
    );
  }
}

abstract class _ItemSuperNct implements ItemSuperNct {
  const factory _ItemSuperNct(
      {@JsonKey(name: 'baseDate') final String? baseDate,
      @JsonKey(name: 'baseTime') final String? baseTime,
      @JsonKey(name: 'category') final String? category,
      @JsonKey(name: 'nx') final int? nx,
      @JsonKey(name: 'ny') final int? ny,
      @JsonKey(name: 'obsrValue') final String? obsrValue}) = _$_ItemSuperNct;

  factory _ItemSuperNct.fromJson(Map<String, dynamic> json) =
      _$_ItemSuperNct.fromJson;

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
  @JsonKey(name: 'nx')
  int? get nx;
  @override
  @JsonKey(name: 'ny')
  int? get ny;
  @override
  @JsonKey(name: 'obsrValue')
  String? get obsrValue;
  @override
  @JsonKey(ignore: true)
  _$$_ItemSuperNctCopyWith<_$_ItemSuperNct> get copyWith =>
      throw _privateConstructorUsedError;
}

HeaderSuperNct _$HeaderSuperNctFromJson(Map<String, dynamic> json) {
  return _HeaderSuperNct.fromJson(json);
}

/// @nodoc
mixin _$HeaderSuperNct {
  @JsonKey(name: 'resultCode')
  String? get resultCode => throw _privateConstructorUsedError;
  @JsonKey(name: 'resultMsg')
  String? get resultMsg => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $HeaderSuperNctCopyWith<HeaderSuperNct> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $HeaderSuperNctCopyWith<$Res> {
  factory $HeaderSuperNctCopyWith(
          HeaderSuperNct value, $Res Function(HeaderSuperNct) then) =
      _$HeaderSuperNctCopyWithImpl<$Res, HeaderSuperNct>;
  @useResult
  $Res call(
      {@JsonKey(name: 'resultCode') String? resultCode,
      @JsonKey(name: 'resultMsg') String? resultMsg});
}

/// @nodoc
class _$HeaderSuperNctCopyWithImpl<$Res, $Val extends HeaderSuperNct>
    implements $HeaderSuperNctCopyWith<$Res> {
  _$HeaderSuperNctCopyWithImpl(this._value, this._then);

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
abstract class _$$_HeaderSuperNctCopyWith<$Res>
    implements $HeaderSuperNctCopyWith<$Res> {
  factory _$$_HeaderSuperNctCopyWith(
          _$_HeaderSuperNct value, $Res Function(_$_HeaderSuperNct) then) =
      __$$_HeaderSuperNctCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@JsonKey(name: 'resultCode') String? resultCode,
      @JsonKey(name: 'resultMsg') String? resultMsg});
}

/// @nodoc
class __$$_HeaderSuperNctCopyWithImpl<$Res>
    extends _$HeaderSuperNctCopyWithImpl<$Res, _$_HeaderSuperNct>
    implements _$$_HeaderSuperNctCopyWith<$Res> {
  __$$_HeaderSuperNctCopyWithImpl(
      _$_HeaderSuperNct _value, $Res Function(_$_HeaderSuperNct) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? resultCode = freezed,
    Object? resultMsg = freezed,
  }) {
    return _then(_$_HeaderSuperNct(
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
class _$_HeaderSuperNct implements _HeaderSuperNct {
  const _$_HeaderSuperNct(
      {@JsonKey(name: 'resultCode') this.resultCode,
      @JsonKey(name: 'resultMsg') this.resultMsg});

  factory _$_HeaderSuperNct.fromJson(Map<String, dynamic> json) =>
      _$$_HeaderSuperNctFromJson(json);

  @override
  @JsonKey(name: 'resultCode')
  final String? resultCode;
  @override
  @JsonKey(name: 'resultMsg')
  final String? resultMsg;

  @override
  String toString() {
    return 'HeaderSuperNct(resultCode: $resultCode, resultMsg: $resultMsg)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$_HeaderSuperNct &&
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
  _$$_HeaderSuperNctCopyWith<_$_HeaderSuperNct> get copyWith =>
      __$$_HeaderSuperNctCopyWithImpl<_$_HeaderSuperNct>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$_HeaderSuperNctToJson(
      this,
    );
  }
}

abstract class _HeaderSuperNct implements HeaderSuperNct {
  const factory _HeaderSuperNct(
      {@JsonKey(name: 'resultCode') final String? resultCode,
      @JsonKey(name: 'resultMsg') final String? resultMsg}) = _$_HeaderSuperNct;

  factory _HeaderSuperNct.fromJson(Map<String, dynamic> json) =
      _$_HeaderSuperNct.fromJson;

  @override
  @JsonKey(name: 'resultCode')
  String? get resultCode;
  @override
  @JsonKey(name: 'resultMsg')
  String? get resultMsg;
  @override
  @JsonKey(ignore: true)
  _$$_HeaderSuperNctCopyWith<_$_HeaderSuperNct> get copyWith =>
      throw _privateConstructorUsedError;
}
