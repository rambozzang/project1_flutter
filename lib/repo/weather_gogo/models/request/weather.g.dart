// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'weather.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Weather _$WeatherFromJson(Map<String, dynamic> json) => Weather(
      nx: json['nx'] as int? ?? 0,
      ny: json['ny'] as int? ?? 1,
      serviceKey: json['ServiceKey'] as String,
      pageNo: json['pageNo'] as int? ?? 1,
      numOfRows: json['numOfRows'] as int? ?? 1000,
      dataType: $enumDecodeNullable(_$DataTypeEnumMap, json['dataType']) ?? DataType.json,
    )
      ..baseDate = json['base_date'] as String?
      ..baseTime = json['base_time'] as String?;

Map<String, dynamic> _$WeatherToJson(Weather instance) => <String, dynamic>{
      'ServiceKey': instance.serviceKey,
      'pageNo': instance.pageNo,
      'numOfRows': instance.numOfRows,
      'dataType': _$DataTypeEnumMap[instance.dataType]!,
      'base_date': instance.baseDate,
      'base_time': instance.baseTime,
      'nx': instance.nx,
      'ny': instance.ny,
    };

const _$DataTypeEnumMap = {
  DataType.json: 'JSON',
  DataType.xml: 'XML',
};
