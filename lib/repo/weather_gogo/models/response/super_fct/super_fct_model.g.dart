// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'super_fct_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$_SuperFctModel _$$_SuperFctModelFromJson(Map<String, dynamic> json) =>
    _$_SuperFctModel(
      response: json['response'] == null
          ? null
          : ResponseSuperFct.fromJson(json['response'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$$_SuperFctModelToJson(_$_SuperFctModel instance) =>
    <String, dynamic>{
      'response': instance.response,
    };

_$_ResponseSuperFct _$$_ResponseSuperFctFromJson(Map<String, dynamic> json) =>
    _$_ResponseSuperFct(
      header: json['header'] == null
          ? null
          : HeaderSuperFct.fromJson(json['header'] as Map<String, dynamic>),
      body: json['body'] == null
          ? null
          : BodySuperFct.fromJson(json['body'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$$_ResponseSuperFctToJson(_$_ResponseSuperFct instance) =>
    <String, dynamic>{
      'header': instance.header,
      'body': instance.body,
    };

_$_BodySuperFct _$$_BodySuperFctFromJson(Map<String, dynamic> json) =>
    _$_BodySuperFct(
      dataType: json['dataType'] as String?,
      items: json['items'] == null
          ? null
          : ItemsSuperFct.fromJson(json['items'] as Map<String, dynamic>),
      pageNo: json['pageNo'] as int?,
      numOfRows: json['numOfRows'] as int?,
      totalCount: json['totalCount'] as int?,
    );

Map<String, dynamic> _$$_BodySuperFctToJson(_$_BodySuperFct instance) =>
    <String, dynamic>{
      'dataType': instance.dataType,
      'items': instance.items,
      'pageNo': instance.pageNo,
      'numOfRows': instance.numOfRows,
      'totalCount': instance.totalCount,
    };

_$_ItemsSuperFct _$$_ItemsSuperFctFromJson(Map<String, dynamic> json) =>
    _$_ItemsSuperFct(
      item: (json['item'] as List<dynamic>?)
          ?.map((e) => ItemSuperFct.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$$_ItemsSuperFctToJson(_$_ItemsSuperFct instance) =>
    <String, dynamic>{
      'item': instance.item,
    };

_$_ItemSuperFct _$$_ItemSuperFctFromJson(Map<String, dynamic> json) =>
    _$_ItemSuperFct(
      baseDate: json['baseDate'] as String?,
      baseTime: json['baseTime'] as String?,
      category: json['category'] as String?,
      fcstDate: json['fcstDate'] as String?,
      fcstTime: json['fcstTime'] as String?,
      fcstValue: json['fcstValue'] as String?,
      nx: json['nx'] as int?,
      ny: json['ny'] as int?,
    );

Map<String, dynamic> _$$_ItemSuperFctToJson(_$_ItemSuperFct instance) =>
    <String, dynamic>{
      'baseDate': instance.baseDate,
      'baseTime': instance.baseTime,
      'category': instance.category,
      'fcstDate': instance.fcstDate,
      'fcstTime': instance.fcstTime,
      'fcstValue': instance.fcstValue,
      'nx': instance.nx,
      'ny': instance.ny,
    };

_$_HeaderSuperFct _$$_HeaderSuperFctFromJson(Map<String, dynamic> json) =>
    _$_HeaderSuperFct(
      resultCode: json['resultCode'] as String?,
      resultMsg: json['resultMsg'] as String?,
    );

Map<String, dynamic> _$$_HeaderSuperFctToJson(_$_HeaderSuperFct instance) =>
    <String, dynamic>{
      'resultCode': instance.resultCode,
      'resultMsg': instance.resultMsg,
    };
