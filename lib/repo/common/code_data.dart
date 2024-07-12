// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

class CodeReq {
  int? pageSize;
  int? pageNum;
  String? grpCd;
  String? code;
  String? codeNm;
  String? useYn;
  CodeReq({
    this.pageSize,
    this.pageNum,
    this.grpCd,
    this.code,
    this.codeNm,
    this.useYn,
  });

  CodeReq copyWith({
    int? pageSize,
    int? pageNum,
    String? grpCd,
    String? code,
    String? codeNm,
    String? useYn,
  }) {
    return CodeReq(
      pageSize: pageSize ?? this.pageSize,
      pageNum: pageNum ?? this.pageNum,
      grpCd: grpCd ?? this.grpCd,
      code: code ?? this.code,
      codeNm: codeNm ?? this.codeNm,
      useYn: useYn ?? this.useYn,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'pageSize': pageSize,
      'pageNum': pageNum,
      'grpCd': grpCd,
      'code': code,
      'codeNm': codeNm,
      'useYn': useYn,
    };
  }

  factory CodeReq.fromMap(Map<String, dynamic> map) {
    return CodeReq(
      pageSize: map['pageSize'] != null ? map['pageSize'] as int : null,
      pageNum: map['pageNum'] != null ? map['pageNum'] as int : null,
      grpCd: map['grpCd'] != null ? map['grpCd'] as String : null,
      code: map['code'] != null ? map['code'] as String : null,
      codeNm: map['codeNm'] != null ? map['codeNm'] as String : null,
      useYn: map['useYn'] != null ? map['useYn'] as String : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory CodeReq.fromJson(String source) => CodeReq.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'CodeReq(pageSize: $pageSize, pageNum: $pageNum, grpCd: $grpCd, code: $code, codeNm: $codeNm, useYn: $useYn)';
  }

  @override
  bool operator ==(covariant CodeReq other) {
    if (identical(this, other)) return true;

    return other.pageSize == pageSize &&
        other.pageNum == pageNum &&
        other.grpCd == grpCd &&
        other.code == code &&
        other.codeNm == codeNm &&
        other.useYn == useYn;
  }

  @override
  int get hashCode {
    return pageSize.hashCode ^ pageNum.hashCode ^ grpCd.hashCode ^ code.hashCode ^ codeNm.hashCode ^ useYn.hashCode;
  }
}

class CodeRes {
  String? grpCd;
  String? code;
  String? codeNm;
  String? grpNm;
  String? grpDesc;
  int? num;
  String? etc1;
  String? etc2;
  String? etc3;
  String? useYn;
  String? crtDtm;
  String? crtMembNo;
  String? chgDtm;
  String? chgMembNo;

  CodeRes({
    this.grpCd,
    this.code,
    this.codeNm,
    this.grpNm,
    this.grpDesc,
    this.num,
    this.etc1,
    this.etc2,
    this.etc3,
    this.useYn,
    this.crtDtm,
    this.crtMembNo,
    this.chgDtm,
    this.chgMembNo,
  });

  CodeRes copyWith({
    String? grpCd,
    String? code,
    String? codeNm,
    String? grpNm,
    String? grpDesc,
    int? num,
    String? etc1,
    String? etc2,
    String? etc3,
    String? useYn,
    String? crtDtm,
    String? crtMembNo,
    String? chgDtm,
    String? chgMembNo,
  }) {
    return CodeRes(
      grpCd: grpCd ?? this.grpCd,
      code: code ?? this.code,
      codeNm: codeNm ?? this.codeNm,
      grpNm: grpNm ?? this.grpNm,
      grpDesc: grpDesc ?? this.grpDesc,
      num: num ?? this.num,
      etc1: etc1 ?? this.etc1,
      etc2: etc2 ?? this.etc2,
      etc3: etc3 ?? this.etc3,
      useYn: useYn ?? this.useYn,
      crtDtm: crtDtm ?? this.crtDtm,
      crtMembNo: crtMembNo ?? this.crtMembNo,
      chgDtm: chgDtm ?? this.chgDtm,
      chgMembNo: chgMembNo ?? this.chgMembNo,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'grpCd': grpCd,
      'code': code,
      'codeNm': codeNm,
      'grpNm': grpNm,
      'grpDesc': grpDesc,
      'num': num,
      'etc1': etc1,
      'etc2': etc2,
      'etc3': etc3,
      'useYn': useYn,
      'crtDtm': crtDtm,
      'crtMembNo': crtMembNo,
      'chgDtm': chgDtm,
      'chgMembNo': chgMembNo,
    };
  }

  factory CodeRes.fromMap(Map<String, dynamic> map) {
    return CodeRes(
      grpCd: map['grpCd'],
      code: map['code'],
      codeNm: map['codeNm'],
      grpNm: map['grpNm'],
      grpDesc: map['grpDesc'],
      num: map['num'],
      etc1: map['etc1'],
      etc2: map['etc2'],
      etc3: map['etc3'],
      useYn: map['useYn'],
      crtDtm: map['crtDtm'],
      crtMembNo: map['crtMembNo'],
      chgDtm: map['chgDtm'],
      chgMembNo: map['chgMembNo'],
    );
  }

  String toJson() => json.encode(toMap());

  factory CodeRes.fromJson(String source) => CodeRes.fromMap(json.decode(source));

  @override
  String toString() {
    return 'CommCodeSearchResData(grpCd: $grpCd, code: $code, codeNm: $codeNm, grpNm: $grpNm, grpDesc: $grpDesc, num: $num, etc1: $etc1, etc2: $etc2, etc3: $etc3, useYn: $useYn, crtDtm: $crtDtm, crtMembNo: $crtMembNo, chgDtm: $chgDtm, chgMembNo: $chgMembNo)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is CodeRes &&
        other.grpCd == grpCd &&
        other.code == code &&
        other.codeNm == codeNm &&
        other.grpNm == grpNm &&
        other.grpDesc == grpDesc &&
        other.num == num &&
        other.etc1 == etc1 &&
        other.etc2 == etc2 &&
        other.etc3 == etc3 &&
        other.useYn == useYn &&
        other.crtDtm == crtDtm &&
        other.crtMembNo == crtMembNo &&
        other.chgDtm == chgDtm &&
        other.chgMembNo == chgMembNo;
  }

  @override
  int get hashCode {
    return grpCd.hashCode ^
        code.hashCode ^
        codeNm.hashCode ^
        grpNm.hashCode ^
        grpDesc.hashCode ^
        num.hashCode ^
        etc1.hashCode ^
        etc2.hashCode ^
        etc3.hashCode ^
        useYn.hashCode ^
        crtDtm.hashCode ^
        crtMembNo.hashCode ^
        chgDtm.hashCode ^
        chgMembNo.hashCode;
  }
}
