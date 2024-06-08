// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

class CloudflareReqSaveData {
  String? uid;

  String? preview;
  int? size;
  String? thumbnail;
  String? dash;
  String? hls;
  String? mp4;
  int? range;
  int? total;
  CloudflareReqSaveData({
    this.uid,
    this.preview,
    this.size,
    this.thumbnail,
    this.dash,
    this.hls,
    this.mp4,
    this.range,
    this.total,
  });

  CloudflareReqSaveData copyWith({
    String? uid,
    String? preview,
    int? size,
    String? thumbnail,
    String? dash,
    String? hls,
    String? mp4,
    int? range,
    int? total,
  }) {
    return CloudflareReqSaveData(
      uid: uid ?? this.uid,
      preview: preview ?? this.preview,
      size: size ?? this.size,
      thumbnail: thumbnail ?? this.thumbnail,
      dash: dash ?? this.dash,
      hls: hls ?? this.hls,
      mp4: mp4 ?? this.mp4,
      range: range ?? this.range,
      total: total ?? this.total,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'uid': uid,
      'preview': preview,
      'size': size,
      'thumbnail': thumbnail,
      'dash': dash,
      'hls': hls,
      'mp4': mp4,
      'range': range,
      'total': total,
    };
  }

  factory CloudflareReqSaveData.fromMap(Map<String, dynamic> map) {
    return CloudflareReqSaveData(
      uid: map['uid'] != null ? map['uid'] as String : null,
      preview: map['preview'] != null ? map['preview'] as String : null,
      size: map['size'] != null ? map['size'] as int : null,
      thumbnail: map['thumbnail'] != null ? map['thumbnail'] as String : null,
      dash: map['dash'] != null ? map['dash'] as String : null,
      hls: map['hls'] != null ? map['hls'] as String : null,
      mp4: map['mp4'] != null ? map['mp4'] as String : null,
      range: map['range'] != null ? map['range'] as int : null,
      total: map['total'] != null ? map['total'] as int : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory CloudflareReqSaveData.fromJson(String source) => CloudflareReqSaveData.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'CloudflareReqSaveData(uid: $uid, preview: $preview, size: $size, thumbnail: $thumbnail, dash: $dash, hls: $hls, mp4: $mp4, range: $range, total: $total)';
  }

  @override
  bool operator ==(covariant CloudflareReqSaveData other) {
    if (identical(this, other)) return true;

    return other.uid == uid &&
        other.preview == preview &&
        other.size == size &&
        other.thumbnail == thumbnail &&
        other.dash == dash &&
        other.hls == hls &&
        other.mp4 == mp4 &&
        other.range == range &&
        other.total == total;
  }

  @override
  int get hashCode {
    return uid.hashCode ^
        preview.hashCode ^
        size.hashCode ^
        thumbnail.hashCode ^
        dash.hashCode ^
        hls.hashCode ^
        mp4.hashCode ^
        range.hashCode ^
        total.hashCode;
  }
}
