// 모임 초대 정보 - 백엔드 CommunityVo.InviteInfo 와 1:1 매핑
class CommunityInviteInfoData {
  final int communityId;
  final String name;
  final String inviteCode;
  final String shareText;

  CommunityInviteInfoData({
    required this.communityId,
    required this.name,
    required this.inviteCode,
    required this.shareText,
  });

  factory CommunityInviteInfoData.fromMap(Map<String, dynamic> map) {
    return CommunityInviteInfoData(
      communityId: (map['communityId'] as num).toInt(),
      name: map['name']?.toString() ?? '',
      inviteCode: map['inviteCode']?.toString() ?? '',
      shareText: map['shareText']?.toString() ?? '',
    );
  }
}
