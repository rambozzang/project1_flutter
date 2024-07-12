import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:xml/xml.dart';

import '../../../adapter/adapter_xml.dart';

part 'super_fct_model.freezed.dart';
part 'super_fct_model.g.dart';

@freezed
class SuperFctModel with _$SuperFctModel {
  const factory SuperFctModel({
    /// 초단기 예보조회
    ResponseSuperFct? response,
  }) = _SuperFctModel;

  factory SuperFctModel.fromJson(Map<String, Object?> json) =>
      _$SuperFctModelFromJson(json);
}

@freezed
class ResponseSuperFct with _$ResponseSuperFct {
  const factory ResponseSuperFct({
    HeaderSuperFct? header,
    BodySuperFct? body,
  }) = _ResponseSuperFct;

  factory ResponseSuperFct.fromJson(Map<String, Object?> json) =>
      _$ResponseSuperFctFromJson(json);
}

@freezed
class BodySuperFct with _$BodySuperFct {
  const factory BodySuperFct({
    String? dataType,
    ItemsSuperFct? items,
    int? pageNo,
    int? numOfRows,
    int? totalCount,
  }) = _BodySuperFct;

  factory BodySuperFct.fromJson(Map<String, Object?> json) =>
      _$BodySuperFctFromJson(json);
}

@freezed
class ItemsSuperFct with _$ItemsSuperFct {
  const factory ItemsSuperFct({
    List<ItemSuperFct>? item,
  }) = _ItemsSuperFct;

  factory ItemsSuperFct.fromJson(Map<String, Object?> json) =>
      _$ItemsSuperFctFromJson(json);
}

@freezed
class ItemSuperFct with _$ItemSuperFct {
  const factory ItemSuperFct({
    String? baseDate,
    String? baseTime,
    String? category,
    String? fcstDate,
    String? fcstTime,
    String? fcstValue,
    int? nx,
    int? ny,
  }) = _ItemSuperFct;

  factory ItemSuperFct.fromJson(Map<String, Object?> json) =>
      _$ItemSuperFctFromJson(json);

  factory ItemSuperFct.fromXml(XmlElement xml) {
    return ItemSuperFct(
      baseDate: AdapterXml.resultXml(xml, 'baseDate'),
      baseTime: AdapterXml.resultXml(xml, 'baseTime'),
      category: AdapterXml.resultXml(xml, 'category'),
      fcstDate: AdapterXml.resultXml(xml, 'fcstDate'),
      fcstTime: AdapterXml.resultXml(xml, 'fcstTime'),
      fcstValue: AdapterXml.resultXml(xml, 'fcstValue'),
      nx: AdapterXml.resultXmlInt(xml, 'nx'),
      ny: AdapterXml.resultXmlInt(xml, 'ny'),
    );
  }
}

@freezed
class HeaderSuperFct with _$HeaderSuperFct {
  const factory HeaderSuperFct({
    String? resultCode,
    String? resultMsg,
  }) = _HeaderSuperFct;

  factory HeaderSuperFct.fromJson(Map<String, Object?> json) =>
      _$HeaderSuperFctFromJson(json);
}
