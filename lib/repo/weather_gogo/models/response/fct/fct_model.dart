import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:xml/xml.dart';

import '../../../adapter/adapter_xml.dart';

part 'fct_model.freezed.dart';

part 'fct_model.g.dart';

@freezed
class FctModel with _$FctModel {
  const factory FctModel({
    /// 단기 예보조회
    ResponseFct? response,
  }) = _FctModel;

  factory FctModel.fromJson(Map<String, Object?> json) => _$FctModelFromJson(json);
}

@freezed
class ResponseFct with _$ResponseFct {
  const factory ResponseFct({
    HeaderFct? header,
    BodyFct? body,
  }) = _ResponseFct;

  factory ResponseFct.fromJson(Map<String, Object?> json) => _$ResponseFctFromJson(json);
}

@freezed
class BodyFct with _$BodyFct {
  const factory BodyFct({
    String? dataType,
    ItemsFct? items,
    int? pageNo,
    int? numOfRows,
    int? totalCount,
  }) = _BodyFct;

  factory BodyFct.fromJson(Map<String, Object?> json) => _$BodyFctFromJson(json);
}

@freezed
class ItemsFct with _$ItemsFct {
  const factory ItemsFct({
    List<ItemFct>? item,
  }) = _ItemsFct;

  factory ItemsFct.fromJson(Map<String, Object?> json) => _$ItemsFctFromJson(json);
}

@freezed
class ItemFct with _$ItemFct {
  const factory ItemFct({
    String? baseDate,
    String? baseTime,
    String? category,
    String? fcstDate,
    String? fcstTime,
    String? fcstValue,
    int? nx,
    int? ny,
  }) = _ItemFct;

  factory ItemFct.fromJson(Map<String, Object?> json) => _$ItemFctFromJson(json);

  factory ItemFct.fromXml(XmlElement xml) {
    return ItemFct(
      baseDate: AdapterXml.resultXml(xml, 'baseDate'),
      baseTime: AdapterXml.resultXml(xml, 'baseTime'),
      nx: AdapterXml.resultXmlInt(xml, 'nx'),
      ny: AdapterXml.resultXmlInt(xml, 'ny'),
      category: AdapterXml.resultXml(xml, 'category'),
      fcstDate: AdapterXml.resultXml(xml, 'fcstDate'),
      fcstTime: AdapterXml.resultXml(xml, 'fcstTime'),
      fcstValue: AdapterXml.resultXml(xml, 'fcstValue'),
    );
  }
}

@freezed
class HeaderFct with _$HeaderFct {
  const factory HeaderFct({
    String? resultCode,
    String? resultMsg,
  }) = _HeaderFct;

  factory HeaderFct.fromJson(Map<String, Object?> json) => _$HeaderFctFromJson(json);
}
