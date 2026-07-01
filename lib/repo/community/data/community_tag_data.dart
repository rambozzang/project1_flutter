// 앨범 인기 태그 집계 아이템 - 백엔드 CommunityVo.TagCount 와 1:1 매핑
class CommunityTagData {
  final String tag;
  final int count;

  CommunityTagData({required this.tag, required this.count});

  factory CommunityTagData.fromMap(Map<String, dynamic> map) {
    return CommunityTagData(
      tag: map['tag']?.toString() ?? '',
      count: map['count'] == null ? 0 : (map['count'] as num).toInt(),
    );
  }
}
