// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

class AlramResData {
  int? seq;
  String? senderCustId;
  String? senderCustNm;
  String? senderNickNm;
  String? receiverCustId;
  String? profilePath;
  int? boardId;
  String? alramCd;
  String? alramTitle;
  String? alramContents;
  String? crtDtm;
  AlramResData({
    this.seq,
    this.senderCustId,
    this.senderCustNm,
    this.senderNickNm,
    this.receiverCustId,
    this.profilePath,
    this.boardId,
    this.alramCd,
    this.alramTitle,
    this.alramContents,
    this.crtDtm,
  });

  AlramResData copyWith({
    int? seq,
    String? senderCustId,
    String? senderCustNm,
    String? senderNickNm,
    String? receiverCustId,
    String? profilePath,
    int? boardId,
    String? alramCd,
    String? alramTitle,
    String? alramContents,
    String? crtDtm,
  }) {
    return AlramResData(
      seq: seq ?? this.seq,
      senderCustId: senderCustId ?? this.senderCustId,
      senderCustNm: senderCustNm ?? this.senderCustNm,
      senderNickNm: senderNickNm ?? this.senderNickNm,
      receiverCustId: receiverCustId ?? this.receiverCustId,
      profilePath: profilePath ?? this.profilePath,
      boardId: boardId ?? this.boardId,
      alramCd: alramCd ?? this.alramCd,
      alramTitle: alramTitle ?? this.alramTitle,
      alramContents: alramContents ?? this.alramContents,
      crtDtm: crtDtm ?? this.crtDtm,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'seq': seq,
      'senderCustId': senderCustId,
      'senderCustNm': senderCustNm,
      'senderNickNm': senderNickNm,
      'receiverCustId': receiverCustId,
      'profilePath': profilePath,
      'boardId': boardId,
      'alramCd': alramCd,
      'alramTitle': alramTitle,
      'alramContents': alramContents,
      'crtDtm': crtDtm,
    };
  }

  factory AlramResData.fromMap(Map<String, dynamic> map) {
    return AlramResData(
      seq: map['seq'] != null ? map['seq'] as int : null,
      senderCustId: map['senderCustId'] != null ? map['senderCustId'] as String : null,
      senderCustNm: map['senderCustNm'] != null ? map['senderCustNm'] as String : null,
      senderNickNm: map['senderNickNm'] != null ? map['senderNickNm'] as String : null,
      receiverCustId: map['receiverCustId'] != null ? map['receiverCustId'] as String : null,
      profilePath: map['profilePath'] != null ? map['profilePath'] as String : null,
      boardId: map['boardId'] != null ? map['boardId'] as int : null,
      alramCd: map['alramCd'] != null ? map['alramCd'] as String : null,
      alramTitle: map['alramTitle'] != null ? map['alramTitle'] as String : null,
      alramContents: map['alramContents'] != null ? map['alramContents'] as String : null,
      crtDtm: map['crtDtm'] != null ? map['crtDtm'] as String : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory AlramResData.fromJson(String source) => AlramResData.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'AlramResData(seq: $seq, senderCustId: $senderCustId, senderCustNm: $senderCustNm, senderNickNm: $senderNickNm, receiverCustId: $receiverCustId, profilePath: $profilePath, boardId: $boardId, alramCd: $alramCd, alramTitle: $alramTitle, alramContents: $alramContents, crtDtm: $crtDtm)';
  }

  @override
  bool operator ==(covariant AlramResData other) {
    if (identical(this, other)) return true;

    return other.seq == seq &&
        other.senderCustId == senderCustId &&
        other.senderCustNm == senderCustNm &&
        other.senderNickNm == senderNickNm &&
        other.receiverCustId == receiverCustId &&
        other.profilePath == profilePath &&
        other.boardId == boardId &&
        other.alramCd == alramCd &&
        other.alramTitle == alramTitle &&
        other.alramContents == alramContents &&
        other.crtDtm == crtDtm;
  }

  @override
  int get hashCode {
    return seq.hashCode ^
        senderCustId.hashCode ^
        senderCustNm.hashCode ^
        senderNickNm.hashCode ^
        receiverCustId.hashCode ^
        profilePath.hashCode ^
        boardId.hashCode ^
        alramCd.hashCode ^
        alramTitle.hashCode ^
        alramContents.hashCode ^
        crtDtm.hashCode;
  }
}
