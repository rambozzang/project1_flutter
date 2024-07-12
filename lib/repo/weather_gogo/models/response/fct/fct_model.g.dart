// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'fct_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$_FctModel _$$_FctModelFromJson(Map<String, dynamic> json) => _$_FctModel(
      response: json['response'] == null
          ? null
          : ResponseFct.fromJson(json['response'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$$_FctModelToJson(_$_FctModel instance) =>
    <String, dynamic>{
      'response': instance.response,
    };

_$_ResponseFct _$$_ResponseFctFromJson(Map<String, dynamic> json) =>
    _$_ResponseFct(
      header: json['header'] == null
          ? null
          : HeaderFct.fromJson(json['header'] as Map<String, dynamic>),
      body: json['body'] == null
          ? null
          : BodyFct.fromJson(json['body'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$$_ResponseFctToJson(_$_ResponseFct instance) =>
    <String, dynamic>{
      'header': instance.header,
      'body': instance.body,
    };

_$_BodyFct _$$_BodyFctFromJson(Map<String, dynamic> json) => _$_BodyFct(
      dataType: json['dataType'] as String?,
      items: json['items'] == null
          ? null
          : ItemsFct.fromJson(json['items'] as Map<String, dynamic>),
      pageNo: json['pageNo'] as int?,
      numOfRows: json['numOfRows'] as int?,
      totalCount: json['totalCount'] as int?,
    );

Map<String, dynamic> _$$_BodyFctToJson(_$_BodyFct instance) =>
    <String, dynamic>{
      'dataType': instance.dataType,
      'items': instance.items,
      'pageNo': instance.pageNo,
      'numOfRows': instance.numOfRows,
      'totalCount': instance.totalCount,
    };

_$_ItemsFct _$$_ItemsFctFromJson(Map<String, dynamic> json) => _$_ItemsFct(
      item: (json['item'] as List<dynamic>?)
          ?.map((e) => ItemFct.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$$_ItemsFctToJson(_$_ItemsFct instance) =>
    <String, dynamic>{
      'item': instance.item,
    };

_$_ItemFct _$$_ItemFctFromJson(Map<String, dynamic> json) => _$_ItemFct(
      baseDate: json['baseDate'] as String?,
      baseTime: json['baseTime'] as String?,
      category: json['category'] as String?,
      fcstDate: json['fcstDate'] as String?,
      fcstTime: json['fcstTime'] as String?,
      fcstValue: json['fcstValue'] as String?,
      nx: json['nx'] as int?,
      ny: json['ny'] as int?,
    );

Map<String, dynamic> _$$_ItemFctToJson(_$_ItemFct instance) =>
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

_$_HeaderFct _$$_HeaderFctFromJson(Map<String, dynamic> json) => _$_HeaderFct(
      resultCode: json['resultCode'] as String?,
      resultMsg: json['resultMsg'] as String?,
    );

Map<String, dynamic> _$$_HeaderFctToJson(_$_HeaderFct instance) =>
    <String, dynamic>{
      'resultCode': instance.resultCode,
      'resultMsg': instance.resultMsg,
    };
