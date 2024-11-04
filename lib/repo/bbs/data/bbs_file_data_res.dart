// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

class BbsFileDataRes {
  int? id;
  int? boardId;
  int? num;
  String? fileType;
  String? fileNm;
  String? fileKey;
  String? filePath;
  String? crtDtm;
  BbsFileDataRes({
    this.id,
    this.boardId,
    this.num,
    this.fileType,
    this.fileNm,
    this.fileKey,
    this.filePath,
    this.crtDtm,
  });

  BbsFileDataRes copyWith({
    int? id,
    int? boardId,
    int? num,
    String? fileType,
    String? fileNm,
    String? fileKey,
    String? filePath,
    String? crtDtm,
  }) {
    return BbsFileDataRes(
      id: id ?? this.id,
      boardId: boardId ?? this.boardId,
      num: num ?? this.num,
      fileType: fileType ?? this.fileType,
      fileNm: fileNm ?? this.fileNm,
      fileKey: fileKey ?? this.fileKey,
      filePath: filePath ?? this.filePath,
      crtDtm: crtDtm ?? this.crtDtm,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'boardId': boardId,
      'num': num,
      'fileType': fileType,
      'fileNm': fileNm,
      'fileKey': fileKey,
      'filePath': filePath,
      'crtDtm': crtDtm,
    };
  }

  factory BbsFileDataRes.fromMap(Map<String, dynamic> map) {
    return BbsFileDataRes(
      id: map['id'] != null ? map['id'] as int : null,
      boardId: map['boardId'] != null ? map['boardId'] as int : null,
      num: map['num'] != null ? map['num'] as int : null,
      fileType: map['fileType'] != null ? map['fileType'] as String : null,
      fileNm: map['fileNm'] != null ? map['fileNm'] as String : null,
      fileKey: map['fileKey'] != null ? map['fileKey'] as String : null,
      filePath: map['filePath'] != null ? map['filePath'] as String : null,
      crtDtm: map['crtDtm'] != null ? map['crtDtm'] as String : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory BbsFileDataRes.fromJson(String source) => BbsFileDataRes.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'BbsFileDataRes(id: $id, boardId: $boardId, num: $num, fileType: $fileType, fileNm: $fileNm, fileKey: $fileKey, filePath: $filePath, crtDtm: $crtDtm)';
  }

  @override
  bool operator ==(covariant BbsFileDataRes other) {
    if (identical(this, other)) return true;

    return other.id == id &&
        other.boardId == boardId &&
        other.num == num &&
        other.fileType == fileType &&
        other.fileNm == fileNm &&
        other.fileKey == fileKey &&
        other.filePath == filePath &&
        other.crtDtm == crtDtm;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        boardId.hashCode ^
        num.hashCode ^
        fileType.hashCode ^
        fileNm.hashCode ^
        fileKey.hashCode ^
        filePath.hashCode ^
        crtDtm.hashCode;
  }
}
