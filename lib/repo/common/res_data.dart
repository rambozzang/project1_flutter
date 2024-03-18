// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

class ResData<T> {
  String? code;
  String? msg;
  T? data;
  ResData({
    this.code,
    this.msg,
    this.data,
  });

  ResData<T> copyWith({
    String? code,
    String? msg,
    T? data,
  }) {
    return ResData<T>(
      code: code ?? this.code,
      msg: msg ?? this.msg,
      data: data ?? this.data,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'code': code,
      'msg': msg,
      'data': data,
    };
  }

  factory ResData.fromMap(Map<String, dynamic> map) {
    return ResData<T>(
      code: map['code'] != null ? map["code"] ?? '' : null,
      msg: map['msg'] != null ? map["msg"] ?? '' : null,
      data: map['data'] != null ? (map["data"] ?? Map<String, dynamic>.from({})) : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory ResData.fromJson(String source) => ResData.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() => 'ResponseData(code: $code, msg: $msg, data: $data)';
  String toString2() => json.decode('{"code": "$code", "msg": "$msg", "data": "$data")');

  @override
  bool operator ==(covariant ResData<T> other) {
    if (identical(this, other)) return true;

    return other.code == code && other.msg == msg && other.data == data;
  }

  @override
  int get hashCode => code.hashCode ^ msg.hashCode ^ data.hashCode;
}
