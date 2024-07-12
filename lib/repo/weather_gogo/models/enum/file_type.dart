import 'package:json_annotation/json_annotation.dart';

@JsonEnum(valueField: 'type')
enum FileType {
  /// 동네예보실황
  oDAM('ODAM'),

  /// 동네예보초단기
  vSRT('VSRT'),

  /// 동네예보단기
  sHRT('SHRT');

  final String type;

  const FileType(this.type);
}
