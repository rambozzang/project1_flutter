import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:xml/xml.dart';

import '../../../adapter/adapter_xml.dart';

part 'fct_version_model.freezed.dart';

part 'fct_version_model.g.dart';

@freezed
class FctVersionModel with _$FctVersionModel {
  const factory FctVersionModel({
    /// 예보버전 조회
    ResponseFctVersion? response,
  }) = _FctVersionModel;

  factory FctVersionModel.fromJson(Map<String, Object?> json) =>
      _$FctVersionModelFromJson(json);
}

@freezed
class ResponseFctVersion with _$ResponseFctVersion {
  const factory ResponseFctVersion({
    HeaderFctVersion? header,
    BodyFctVersion? body,
  }) = _ResponseFctVersion;

  factory ResponseFctVersion.fromJson(Map<String, Object?> json) =>
      _$ResponseFctVersionFromJson(json);
}

@freezed
class BodyFctVersion with _$BodyFctVersion {
  const factory BodyFctVersion({
    String? dataType,
    ItemsFctVersion? items,
    int? pageNo,
    int? numOfRows,
    int? totalCount,
  }) = _BodyFctVersion;

  factory BodyFctVersion.fromJson(Map<String, Object?> json) =>
      _$BodyFctVersionFromJson(json);
}

@freezed
class ItemsFctVersion with _$ItemsFctVersion {
  const factory ItemsFctVersion({
    List<ItemFctVersion>? item,
  }) = _ItemsFctVersion;

  factory ItemsFctVersion.fromJson(Map<String, Object?> json) =>
      _$ItemsFctVersionFromJson(json);
}

@freezed
class ItemFctVersion with _$ItemFctVersion {
  const factory ItemFctVersion({
    String? filetype,
    String? version,
  }) = _ItemFctVersion;

  factory ItemFctVersion.fromJson(Map<String, Object?> json) =>
      _$ItemFctVersionFromJson(json);

  factory ItemFctVersion.fromXml(XmlElement xml) {
    return ItemFctVersion(
      filetype: AdapterXml.resultXml(xml, 'filetype'),
      version: AdapterXml.resultXml(xml, 'version'),
    );
  }
}

@freezed
class HeaderFctVersion with _$HeaderFctVersion {
  const factory HeaderFctVersion({
    String? resultCode,
    String? resultMsg,
  }) = _HeaderFctVersion;

  factory HeaderFctVersion.fromJson(Map<String, Object?> json) =>
      _$HeaderFctVersionFromJson(json);
}
