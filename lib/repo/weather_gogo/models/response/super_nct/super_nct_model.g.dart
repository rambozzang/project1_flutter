// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'super_nct_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$_SuperNctModel _$$_SuperNctModelFromJson(Map<String, dynamic> json) =>
    _$_SuperNctModel(
      response: json['response'] == null
          ? null
          : ResponseBean.fromJson(json['response'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$$_SuperNctModelToJson(_$_SuperNctModel instance) =>
    <String, dynamic>{
      'response': instance.response,
    };

_$_ResponseBean _$$_ResponseBeanFromJson(Map<String, dynamic> json) =>
    _$_ResponseBean(
      header: json['header'] == null
          ? null
          : HeaderSuperNct.fromJson(json['header'] as Map<String, dynamic>),
      body: json['body'] == null
          ? null
          : BodySuperNct.fromJson(json['body'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$$_ResponseBeanToJson(_$_ResponseBean instance) =>
    <String, dynamic>{
      'header': instance.header,
      'body': instance.body,
    };

_$_BodySuperNct _$$_BodySuperNctFromJson(Map<String, dynamic> json) =>
    _$_BodySuperNct(
      dataType: json['dataType'] as String?,
      items: json['items'] == null
          ? null
          : ItemsSuperNct.fromJson(json['items'] as Map<String, dynamic>),
      pageNo: json['pageNo'] as int?,
      numOfRows: json['numOfRows'] as int?,
      totalCount: json['totalCount'] as int?,
    );

Map<String, dynamic> _$$_BodySuperNctToJson(_$_BodySuperNct instance) =>
    <String, dynamic>{
      'dataType': instance.dataType,
      'items': instance.items,
      'pageNo': instance.pageNo,
      'numOfRows': instance.numOfRows,
      'totalCount': instance.totalCount,
    };

_$_ItemsSuperNct _$$_ItemsSuperNctFromJson(Map<String, dynamic> json) =>
    _$_ItemsSuperNct(
      item: (json['item'] as List<dynamic>?)
          ?.map((e) => ItemSuperNct.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$$_ItemsSuperNctToJson(_$_ItemsSuperNct instance) =>
    <String, dynamic>{
      'item': instance.item,
    };

_$_ItemSuperNct _$$_ItemSuperNctFromJson(Map<String, dynamic> json) =>
    _$_ItemSuperNct(
      baseDate: json['baseDate'] as String?,
      baseTime: json['baseTime'] as String?,
      category: json['category'] as String?,
      nx: json['nx'] as int?,
      ny: json['ny'] as int?,
      obsrValue: json['obsrValue'] as String?,
    );

Map<String, dynamic> _$$_ItemSuperNctToJson(_$_ItemSuperNct instance) =>
    <String, dynamic>{
      'baseDate': instance.baseDate,
      'baseTime': instance.baseTime,
      'category': instance.category,
      'nx': instance.nx,
      'ny': instance.ny,
      'obsrValue': instance.obsrValue,
    };

_$_HeaderSuperNct _$$_HeaderSuperNctFromJson(Map<String, dynamic> json) =>
    _$_HeaderSuperNct(
      resultCode: json['resultCode'] as String?,
      resultMsg: json['resultMsg'] as String?,
    );

Map<String, dynamic> _$$_HeaderSuperNctToJson(_$_HeaderSuperNct instance) =>
    <String, dynamic>{
      'resultCode': instance.resultCode,
      'resultMsg': instance.resultMsg,
    };
