// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

class AlramReqData {
  String? senderCustId = "";
  String? receiverCustId = "";
  String? alramCd = "";
  int? pageNum = 0;
  int? pageSize = 15;
  AlramReqData({
    this.senderCustId,
    this.receiverCustId,
    this.alramCd,
    this.pageNum,
    this.pageSize,
  });

  AlramReqData copyWith({
    String? senderCustId,
    String? receiverCustId,
    String? alramCd,
    int? pageNum,
    int? pageSize,
  }) {
    return AlramReqData(
      senderCustId: senderCustId ?? this.senderCustId,
      receiverCustId: receiverCustId ?? this.receiverCustId,
      alramCd: alramCd ?? this.alramCd,
      pageNum: pageNum ?? this.pageNum,
      pageSize: pageSize ?? this.pageSize,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'senderCustId': senderCustId,
      'receiverCustId': receiverCustId,
      'alramCd': alramCd,
      'pageNum': pageNum,
      'pageSize': pageSize,
    };
  }

  factory AlramReqData.fromMap(Map<String, dynamic> map) {
    return AlramReqData(
      senderCustId: map['senderCustId'] != null ? map['senderCustId'] as String : null,
      receiverCustId: map['receiverCustId'] != null ? map['receiverCustId'] as String : null,
      alramCd: map['alramCd'] != null ? map['alramCd'] as String : null,
      pageNum: map['pageNum'] != null ? map['pageNum'] as int : null,
      pageSize: map['pageSize'] != null ? map['pageSize'] as int : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory AlramReqData.fromJson(String source) => AlramReqData.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'AlramReqData(senderCustId: $senderCustId, receiverCustId: $receiverCustId, alramCd: $alramCd, pageNum: $pageNum, pageSize: $pageSize)';
  }

  @override
  bool operator ==(covariant AlramReqData other) {
    if (identical(this, other)) return true;

    return other.senderCustId == senderCustId &&
        other.receiverCustId == receiverCustId &&
        other.alramCd == alramCd &&
        other.pageNum == pageNum &&
        other.pageSize == pageSize;
  }

  @override
  int get hashCode {
    return senderCustId.hashCode ^ receiverCustId.hashCode ^ alramCd.hashCode ^ pageNum.hashCode ^ pageSize.hashCode;
  }
}
