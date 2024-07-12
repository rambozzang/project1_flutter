import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:xml/xml.dart';

import '../../../adapter/adapter_xml.dart';

part 'super_nct_model.freezed.dart';
part 'super_nct_model.g.dart';

@freezed
class SuperNctModel with _$SuperNctModel {
  const factory SuperNctModel({
    /// 초단기 실황 조회
    ResponseBean? response,
  }) = _SuperNctModel;

  factory SuperNctModel.fromJson(Map<String, Object?> json) =>
      _$SuperNctModelFromJson(json);
}

@freezed
class ResponseBean with _$ResponseBean {
  const factory ResponseBean({
    HeaderSuperNct? header,
    BodySuperNct? body,
  }) = _ResponseBean;

  factory ResponseBean.fromJson(Map<String, Object?> json) =>
      _$ResponseBeanFromJson(json);
}

@freezed
class BodySuperNct with _$BodySuperNct {
  const factory BodySuperNct({
    String? dataType,
    ItemsSuperNct? items,
    int? pageNo,
    int? numOfRows,
    int? totalCount,
  }) = _BodySuperNct;

  factory BodySuperNct.fromJson(Map<String, Object?> json) =>
      _$BodySuperNctFromJson(json);
}

@freezed
class ItemsSuperNct with _$ItemsSuperNct {
  const factory ItemsSuperNct({
    List<ItemSuperNct>? item,
  }) = _ItemsSuperNct;

  factory ItemsSuperNct.fromJson(Map<String, Object?> json) =>
      _$ItemsSuperNctFromJson(json);
}

@freezed
class ItemSuperNct with _$ItemSuperNct {
  const factory ItemSuperNct({
    String? baseDate,
    String? baseTime,
    String? category,
    int? nx,
    int? ny,
    String? obsrValue,
  }) = _ItemSuperNct;

  factory ItemSuperNct.fromJson(Map<String, Object?> json) =>
      _$ItemSuperNctFromJson(json);

  factory ItemSuperNct.fromXml(XmlElement xml) {
    return ItemSuperNct(
      baseDate: AdapterXml.resultXml(xml, 'baseDate'),
      baseTime: AdapterXml.resultXml(xml, 'baseTime'),
      nx: AdapterXml.resultXmlInt(xml, 'nx'),
      ny: AdapterXml.resultXmlInt(xml, 'ny'),
      category: AdapterXml.resultXml(xml, 'category'),
      obsrValue: AdapterXml.resultXml(xml, 'obsrValue'),
    );
  }
}

@freezed
class HeaderSuperNct with _$HeaderSuperNct {
  const factory HeaderSuperNct({
    String? resultCode,
    String? resultMsg,
  }) = _HeaderSuperNct;

  factory HeaderSuperNct.fromJson(Map<String, Object?> json) =>
      _$HeaderSuperNctFromJson(json);
}
