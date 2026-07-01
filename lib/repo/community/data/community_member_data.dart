// 모임 멤버 - 백엔드 CommunityVo.MemberItem 과 1:1 매핑
class CommunityMemberData {
  final String custId;
  final String? nickNm;
  final String? profilePath;
  final String role; // 'OWNER' | 'MANAGER' | 'MEMBER'
  final String status; // 'JOINED' | 'PENDING'
  final String? joinedAt;

  CommunityMemberData({
    required this.custId,
    this.nickNm,
    this.profilePath,
    this.role = 'MEMBER',
    this.status = 'JOINED',
    this.joinedAt,
  });

  bool get isOwner => role == 'OWNER';
  bool get isManager => role == 'OWNER' || role == 'MANAGER';

  factory CommunityMemberData.fromMap(Map<String, dynamic> map) {
    return CommunityMemberData(
      custId: map['custId']?.toString() ?? '',
      nickNm: map['nickNm']?.toString(),
      profilePath: map['profilePath']?.toString(),
      role: map['role']?.toString() ?? 'MEMBER',
      status: map['status']?.toString() ?? 'JOINED',
      joinedAt: map['joinedAt']?.toString(),
    );
  }
}
