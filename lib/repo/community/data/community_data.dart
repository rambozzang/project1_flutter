// 모임(커뮤니티) 아이템 - 백엔드 CommunityVo.CommunityItem 과 1:1 매핑
class CommunityData {
  final int communityId;
  final String name;
  final String? description;
  final String? imageUrl;
  final String? ownerCustId;
  final int? spotId;
  final String isPublic; // 'Y' | 'N'
  final String joinType; // 'AUTO' | 'APPROVAL'
  final int memberCnt;
  final String? crtDtm;
  final String? myStatus; // 'JOINED' | 'PENDING' | null(미가입)
  final bool isOwner;

  CommunityData({
    required this.communityId,
    required this.name,
    this.description,
    this.imageUrl,
    this.ownerCustId,
    this.spotId,
    this.isPublic = 'Y',
    this.joinType = 'AUTO',
    this.memberCnt = 0,
    this.crtDtm,
    this.myStatus,
    this.isOwner = false,
  });

  bool get isJoined => myStatus == 'JOINED';
  bool get isPending => myStatus == 'PENDING';
  bool get isPrivate => isPublic == 'N';
  bool get isApproval => joinType == 'APPROVAL';

  factory CommunityData.fromMap(Map<String, dynamic> map) {
    return CommunityData(
      communityId: (map['communityId'] as num).toInt(),
      name: map['name']?.toString() ?? '',
      description: map['description']?.toString(),
      imageUrl: map['imageUrl']?.toString(),
      ownerCustId: map['ownerCustId']?.toString(),
      spotId: map['spotId'] == null ? null : (map['spotId'] as num).toInt(),
      isPublic: map['isPublic']?.toString() ?? 'Y',
      joinType: map['joinType']?.toString() ?? 'AUTO',
      memberCnt: map['memberCnt'] == null ? 0 : (map['memberCnt'] as num).toInt(),
      crtDtm: map['crtDtm']?.toString(),
      myStatus: map['myStatus']?.toString(),
      // Jackson 은 boolean isOwner 를 'owner' 키로 직렬화 → 두 키 모두 방어적으로 처리
      isOwner: (map['owner'] ?? map['isOwner'] ?? false) == true,
    );
  }
}
