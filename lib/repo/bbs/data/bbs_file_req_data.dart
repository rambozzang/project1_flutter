// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

class BbsFileData {
  String fileType;
  String fileNm;
  String fileKey;
  String filePath;
  BbsFileData({
    required this.fileType,
    required this.fileNm,
    required this.fileKey,
    required this.filePath,
  });

  BbsFileData copyWith({
    String? fileType,
    String? fileNm,
    String? fileKey,
    String? filePath,
  }) {
    return BbsFileData(
      fileType: fileType ?? this.fileType,
      fileNm: fileNm ?? this.fileNm,
      fileKey: fileKey ?? this.fileKey,
      filePath: filePath ?? this.filePath,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'fileType': fileType,
      'fileNm': fileNm,
      'fileKey': fileKey,
      'filePath': filePath,
    };
  }

  factory BbsFileData.fromMap(Map<String, dynamic> map) {
    return BbsFileData(
      fileType: map['fileType'] as String,
      fileNm: map['fileNm'] as String,
      fileKey: map['fileKey'] as String,
      filePath: map['filePath'] as String,
    );
  }

  String toJson() => json.encode(toMap());

  factory BbsFileData.fromJson(String source) => BbsFileData.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'BbsFileData(fileType: $fileType, fileNm: $fileNm, fileKey: $fileKey, filePath: $filePath)';
  }

  @override
  bool operator ==(covariant BbsFileData other) {
    if (identical(this, other)) return true;

    return other.fileType == fileType && other.fileNm == fileNm && other.fileKey == fileKey && other.filePath == filePath;
  }

  @override
  int get hashCode {
    return fileType.hashCode ^ fileNm.hashCode ^ fileKey.hashCode ^ filePath.hashCode;
  }
}
