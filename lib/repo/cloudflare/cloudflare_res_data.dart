// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:flutter/foundation.dart';

class CloudflareResData {
  bool? success;
  List<CloudflareError>? errors;
  CloudflareResData({
    this.success,
    this.errors,
  });

  CloudflareResData copyWith({
    bool? success,
    List<CloudflareError>? errors,
  }) {
    return CloudflareResData(
      success: success ?? this.success,
      errors: errors ?? this.errors,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'success': success,
      'errors': errors?.map((x) => x.toMap()).toList(),
    };
  }

  factory CloudflareResData.fromMap(Map<String, dynamic> map) {
    return CloudflareResData(
      success: map['success'] != null ? map['success'] as bool : null,
      errors: map['errors'] != null
          ? List<CloudflareError>.from(
              (map['errors'] as List).map<CloudflareError?>(
                (x) => CloudflareError.fromMap(x as Map<String, dynamic>),
              ),
            )
          : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory CloudflareResData.fromJson(String source) => CloudflareResData.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() => 'CloudflareResData(success: $success, errors: $errors)';

  @override
  bool operator ==(covariant CloudflareResData other) {
    if (identical(this, other)) return true;

    return other.success == success && listEquals(other.errors, errors);
  }

  @override
  int get hashCode => success.hashCode ^ errors.hashCode;
}

class CloudflareError {
  int? code;
  String? message;
  CloudflareError({
    this.code,
    this.message,
  });

  CloudflareError copyWith({
    int? code,
    String? message,
  }) {
    return CloudflareError(
      code: code ?? this.code,
      message: message ?? this.message,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'code': code,
      'message': message,
    };
  }

  factory CloudflareError.fromMap(Map<String, dynamic> map) {
    return CloudflareError(
      code: map['code'] != null ? map['code'] as int : null,
      message: map['message'] != null ? map['message'] as String : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory CloudflareError.fromJson(String source) => CloudflareError.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() => 'CloudflareError(code: $code, message: $message)';

  @override
  bool operator ==(covariant CloudflareError other) {
    if (identical(this, other)) return true;

    return other.code == code && other.message == message;
  }

  @override
  int get hashCode => code.hashCode ^ message.hashCode;
}
