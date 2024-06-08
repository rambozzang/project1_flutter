// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

class AlramReqData {
  String? senderCustId;
  String? receiverCustId;
  String? alramCd;
  AlramReqData({
    this.senderCustId,
    this.receiverCustId,
    this.alramCd,
  });

  AlramReqData copyWith({
    String? senderCustId,
    String? receiverCustId,
    String? alramCd,
  }) {
    return AlramReqData(
      senderCustId: senderCustId ?? this.senderCustId,
      receiverCustId: receiverCustId ?? this.receiverCustId,
      alramCd: alramCd ?? this.alramCd,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'senderCustId': senderCustId,
      'receiverCustId': receiverCustId,
      'alramCd': alramCd,
    };
  }

  factory AlramReqData.fromMap(Map<String, dynamic> map) {
    return AlramReqData(
      senderCustId: map['senderCustId'] != null ? map['senderCustId'] as String : null,
      receiverCustId: map['receiverCustId'] != null ? map['receiverCustId'] as String : null,
      alramCd: map['alramCd'] != null ? map['alramCd'] as String : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory AlramReqData.fromJson(String source) => AlramReqData.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() => 'AlramReqData(senderCustId: $senderCustId, receiverCustId: $receiverCustId, alramCd: $alramCd)';

  @override
  bool operator ==(covariant AlramReqData other) {
    if (identical(this, other)) return true;

    return other.senderCustId == senderCustId && other.receiverCustId == receiverCustId && other.alramCd == alramCd;
  }

  @override
  int get hashCode => senderCustId.hashCode ^ receiverCustId.hashCode ^ alramCd.hashCode;
}
