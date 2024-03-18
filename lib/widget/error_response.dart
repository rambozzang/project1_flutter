// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

class ErrorResponse {
  String? errStatus;
  int? errCode;
  String? errMessage;
  ErrorResponse({
    this.errStatus,
    this.errCode,
    this.errMessage,
  });

  ErrorResponse copyWith({
    String? errStatus,
    int? errCode,
    String? errMessage,
  }) {
    return ErrorResponse(
      errStatus: errStatus ?? this.errStatus,
      errCode: errCode ?? this.errCode,
      errMessage: errMessage ?? this.errMessage,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'errStatus': errStatus,
      'errCode': errCode,
      'errMessage': errMessage,
    };
  }

  factory ErrorResponse.fromMap(Map<String, dynamic> map) {
    return ErrorResponse(
      errStatus: map['errStatus'] != null ? map['errStatus'] as String : null,
      errCode: map['errCode'] != null ? map['errCode'] as int : null,
      errMessage:
          map['errMessage'] != null ? map['errMessage'] as String : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory ErrorResponse.fromJson(String source) =>
      ErrorResponse.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() =>
      'ErrorResponse(errStatus: $errStatus, errCode: $errCode, errMessage: $errMessage)';

  @override
  bool operator ==(covariant ErrorResponse other) {
    if (identical(this, other)) return true;

    return other.errStatus == errStatus &&
        other.errCode == errCode &&
        other.errMessage == errMessage;
  }

  @override
  int get hashCode =>
      errStatus.hashCode ^ errCode.hashCode ^ errMessage.hashCode;
}
