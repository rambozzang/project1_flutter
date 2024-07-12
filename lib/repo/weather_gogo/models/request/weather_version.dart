import 'package:intl/intl.dart';
import 'package:json_annotation/json_annotation.dart';

import '../enum/data_type.dart';
import '../enum/file_type.dart';

part 'weather_version.g.dart';

@JsonSerializable()
class WeatherVersion {
  /// 공공데이터포털에서 받은 인증키
  @JsonKey(name: 'ServiceKey')
  final String serviceKey;

  /// 페이지번호 [Default: 1]
  final int pageNo;

  /// 한 페이지 결과 수 [Default: 1]
  final int numOfRows;

  /// 요청자료형식(XML/JSON) [Default: JSON]
  final DataType dataType;

  /// 파일구분 [Default: ODAM]
  /// -ODAM: 동네예보실황
  /// -VSRT: 동네예보초단기
  /// -SHRT: 동네예보단기
  @JsonKey(name: 'ftype')
  final FileType fileType;

  /// 발표일시분 [자동생성]
  @JsonKey(name: 'basedatetime')
  String? baseDateTime;

  @JsonKey(ignore: true)
  late DateTime _dateTime;

  WeatherVersion({
    DateTime? dateTime,
    required this.serviceKey,
    this.pageNo = 1,
    this.numOfRows = 1,
    this.dataType = DataType.json,
    this.fileType = FileType.oDAM,
  }) {
    _dateTime = dateTime ?? DateTime.now();
    baseDateTime = _dateTimeBase(_dateTime);
  }

  DateTime get date => _dateTime;

  WeatherVersion copyWith({
    String? serviceKey,
    int? numOfRows,
    int? pageNo,
    DataType? dataType,
    FileType? fileType,
    DateTime? dateTime,
  }) {
    return WeatherVersion(
      serviceKey: serviceKey ?? this.serviceKey,
      numOfRows: numOfRows ?? this.numOfRows,
      pageNo: pageNo ?? this.pageNo,
      dataType: dataType ?? this.dataType,
      fileType: fileType ?? this.fileType,
      dateTime: dateTime ?? _dateTime,
    );
  }

  factory WeatherVersion.fromJson(Map<String, dynamic> json) {
    return _$WeatherVersionFromJson(json);
  }

  Map<String, dynamic> toJson() => _$WeatherVersionToJson(this);

  String _dateTimeBase(DateTime dateTime) =>
      DateFormat('yyyyMMddkkmm').format(dateTime);
}
