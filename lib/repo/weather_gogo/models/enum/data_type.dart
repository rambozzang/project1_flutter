import 'package:json_annotation/json_annotation.dart';

@JsonEnum(valueField: 'type')
enum DataType {
  json('JSON'),
  xml('XML');

  final String type;

  const DataType(this.type);
}
