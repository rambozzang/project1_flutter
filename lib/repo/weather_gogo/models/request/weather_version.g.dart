// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'weather_version.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WeatherVersion _$WeatherVersionFromJson(Map<String, dynamic> json) =>
    WeatherVersion(
      serviceKey: json['ServiceKey'] as String,
      pageNo: json['pageNo'] as int? ?? 1,
      numOfRows: json['numOfRows'] as int? ?? 1,
      dataType: $enumDecodeNullable(_$DataTypeEnumMap, json['dataType']) ??
          DataType.json,
      fileType: $enumDecodeNullable(_$FileTypeEnumMap, json['ftype']) ??
          FileType.oDAM,
    )..baseDateTime = json['basedatetime'] as String?;

Map<String, dynamic> _$WeatherVersionToJson(WeatherVersion instance) =>
    <String, dynamic>{
      'ServiceKey': instance.serviceKey,
      'pageNo': instance.pageNo,
      'numOfRows': instance.numOfRows,
      'dataType': _$DataTypeEnumMap[instance.dataType]!,
      'ftype': _$FileTypeEnumMap[instance.fileType]!,
      'basedatetime': instance.baseDateTime,
    };

const _$DataTypeEnumMap = {
  DataType.json: 'JSON',
  DataType.xml: 'XML',
};

const _$FileTypeEnumMap = {
  FileType.oDAM: 'ODAM',
  FileType.vSRT: 'VSRT',
  FileType.sHRT: 'SHRT',
};
