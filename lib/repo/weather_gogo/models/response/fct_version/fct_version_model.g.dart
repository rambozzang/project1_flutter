// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'fct_version_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$_FctVersionModel _$$_FctVersionModelFromJson(Map<String, dynamic> json) =>
    _$_FctVersionModel(
      response: json['response'] == null
          ? null
          : ResponseFctVersion.fromJson(
              json['response'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$$_FctVersionModelToJson(_$_FctVersionModel instance) =>
    <String, dynamic>{
      'response': instance.response,
    };

_$_ResponseFctVersion _$$_ResponseFctVersionFromJson(
        Map<String, dynamic> json) =>
    _$_ResponseFctVersion(
      header: json['header'] == null
          ? null
          : HeaderFctVersion.fromJson(json['header'] as Map<String, dynamic>),
      body: json['body'] == null
          ? null
          : BodyFctVersion.fromJson(json['body'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$$_ResponseFctVersionToJson(
        _$_ResponseFctVersion instance) =>
    <String, dynamic>{
      'header': instance.header,
      'body': instance.body,
    };

_$_BodyFctVersion _$$_BodyFctVersionFromJson(Map<String, dynamic> json) =>
    _$_BodyFctVersion(
      dataType: json['dataType'] as String?,
      items: json['items'] == null
          ? null
          : ItemsFctVersion.fromJson(json['items'] as Map<String, dynamic>),
      pageNo: json['pageNo'] as int?,
      numOfRows: json['numOfRows'] as int?,
      totalCount: json['totalCount'] as int?,
    );

Map<String, dynamic> _$$_BodyFctVersionToJson(_$_BodyFctVersion instance) =>
    <String, dynamic>{
      'dataType': instance.dataType,
      'items': instance.items,
      'pageNo': instance.pageNo,
      'numOfRows': instance.numOfRows,
      'totalCount': instance.totalCount,
    };

_$_ItemsFctVersion _$$_ItemsFctVersionFromJson(Map<String, dynamic> json) =>
    _$_ItemsFctVersion(
      item: (json['item'] as List<dynamic>?)
          ?.map((e) => ItemFctVersion.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$$_ItemsFctVersionToJson(_$_ItemsFctVersion instance) =>
    <String, dynamic>{
      'item': instance.item,
    };

_$_ItemFctVersion _$$_ItemFctVersionFromJson(Map<String, dynamic> json) =>
    _$_ItemFctVersion(
      filetype: json['filetype'] as String?,
      version: json['version'] as String?,
    );

Map<String, dynamic> _$$_ItemFctVersionToJson(_$_ItemFctVersion instance) =>
    <String, dynamic>{
      'filetype': instance.filetype,
      'version': instance.version,
    };

_$_HeaderFctVersion _$$_HeaderFctVersionFromJson(Map<String, dynamic> json) =>
    _$_HeaderFctVersion(
      resultCode: json['resultCode'] as String?,
      resultMsg: json['resultMsg'] as String?,
    );

Map<String, dynamic> _$$_HeaderFctVersionToJson(_$_HeaderFctVersion instance) =>
    <String, dynamic>{
      'resultCode': instance.resultCode,
      'resultMsg': instance.resultMsg,
    };
