// 모임(커뮤니티) 아이템 - 백엔드 CommunityVo.CommunityItem 과 1:1 매핑
class CommunityData {
  final int communityId;
  final String name;
  final String? description;
  final String? imageUrl;
  final String? coverThumbnailUrl;
  final String? ownerCustId;
  final int? spotId;
  final String isPublic; // 'Y' | 'N'
  final String joinType; // 'AUTO' | 'APPROVAL'
  final int memberCnt;
  final String? crtDtm;
  final String? myStatus; // 'JOINED' | 'PENDING' | null(미가입)
  final bool isOwner;
  final String? coverTemplateId;
  final bool isManager; // 방장 포함 true — 표지 수정 등 매니저 권한 UI 노출용
  final int videoCnt; // 앨범 내 영상 수(내 목록/상세 응답에서만 계산됨, 그 외 0)
  final int photoCnt; // 앨범 내 사진 수
  final int newCnt; // 마지막 열람 이후 남이 올린 미디어 수(JOINED 멤버만)
  final String? lastSeenDtm; // 마지막 열람 시각(1d 셀 pink 점 판단용)
  // ── 대문 편집(1f) ──
  final String? themeColor; // 카드 무드 그라디언트 키(rain/sunset/...). null=앨범 id 순환
  final List<int> coverMediaIds; // 대표 미디어 boardId(순서 유지, 최대 3)
  final Set<String>? cardOptions; // 카드 표시 옵션(member/media/avatars/new). null=전체 표시
  // ── 목록 카드 즉시 렌더용(_fillCard N콜 제거) ──
  final List<String> avatars; // 상위 멤버 프로필경로(최대 4, JOINED)
  final String? lastMediaDtm; // 최신 미디어 시각('yyyy-MM-dd HH:mm')

  CommunityData({
    required this.communityId,
    required this.name,
    this.description,
    this.imageUrl,
    this.coverThumbnailUrl,
    this.coverTemplateId,
    this.ownerCustId,
    this.spotId,
    this.isPublic = 'Y',
    this.joinType = 'AUTO',
    this.memberCnt = 0,
    this.crtDtm,
    this.myStatus,
    this.isOwner = false,
    this.isManager = false,
    this.videoCnt = 0,
    this.photoCnt = 0,
    this.newCnt = 0,
    this.lastSeenDtm,
    this.themeColor,
    this.coverMediaIds = const [],
    this.cardOptions,
    this.avatars = const [],
    this.lastMediaDtm,
  });

  int get mediaCnt => videoCnt + photoCnt;

  /// 카드 표시 옵션 — null(미설정)이면 전체 표시
  bool showOpt(String key) => cardOptions == null || cardOptions!.contains(key);

  /// 대문 편집 미리보기용 복사본
  CommunityData copyWith({
    String? name,
    String? description,
    String? imageUrl,
    String? coverThumbnailUrl,
    String? coverTemplateId,
    String? themeColor,
    List<int>? coverMediaIds,
    Set<String>? cardOptions,
  }) {
    return CommunityData(
      communityId: communityId,
      name: name ?? this.name,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      coverThumbnailUrl: coverThumbnailUrl ?? this.coverThumbnailUrl,
      coverTemplateId: coverTemplateId ?? this.coverTemplateId,
      ownerCustId: ownerCustId,
      spotId: spotId,
      isPublic: isPublic,
      joinType: joinType,
      memberCnt: memberCnt,
      crtDtm: crtDtm,
      myStatus: myStatus,
      isOwner: isOwner,
      isManager: isManager,
      videoCnt: videoCnt,
      photoCnt: photoCnt,
      newCnt: newCnt,
      lastSeenDtm: lastSeenDtm,
      themeColor: themeColor ?? this.themeColor,
      coverMediaIds: coverMediaIds ?? this.coverMediaIds,
      cardOptions: cardOptions ?? this.cardOptions,
    );
  }

  bool get isJoined => myStatus == 'JOINED';
  bool get isPending => myStatus == 'PENDING';
  bool get isPrivate => isPublic == 'N';
  bool get isApproval => joinType == 'APPROVAL';
  bool get canEditCover => isOwner || isManager;

  /// 앱에서는 경량 대문을 우선하고, 구버전 백엔드 응답은 원본으로 안전하게 폴백한다.
  String? get coverDisplayUrl {
    final thumbnail = coverThumbnailUrl?.trim();
    if (thumbnail != null && thumbnail.isNotEmpty) return thumbnail;
    final original = imageUrl?.trim();
    return original == null || original.isEmpty ? null : original;
  }

  factory CommunityData.fromMap(Map<String, dynamic> map) {
    return CommunityData(
      communityId: (map['communityId'] as num).toInt(),
      name: map['name']?.toString() ?? '',
      description: map['description']?.toString(),
      imageUrl: map['imageUrl']?.toString(),
      coverThumbnailUrl: map['coverThumbnailUrl']?.toString(),
      ownerCustId: map['ownerCustId']?.toString(),
      spotId: map['spotId'] == null ? null : (map['spotId'] as num).toInt(),
      isPublic: map['isPublic']?.toString() ?? 'Y',
      joinType: map['joinType']?.toString() ?? 'AUTO',
      memberCnt: map['memberCnt'] == null ? 0 : (map['memberCnt'] as num).toInt(),
      crtDtm: map['crtDtm']?.toString(),
      myStatus: map['myStatus']?.toString(),
      // Jackson 은 boolean isOwner 를 'owner' 키로 직렬화 → 두 키 모두 방어적으로 처리
      isOwner: (map['owner'] ?? map['isOwner'] ?? false) == true,
      coverTemplateId: map['coverTemplateId']?.toString(),
      // Jackson 은 boolean isManager 를 'manager' 키로 직렬화(isOwner→owner 와 동일 패턴) → manager 키를 fallback 체인에 포함
      isManager: (map['isManager'] ?? map['manager'] ?? map['owner'] ?? map['isOwner'] ?? false) == true,
      videoCnt: map['videoCnt'] == null ? 0 : (map['videoCnt'] as num).toInt(),
      photoCnt: map['photoCnt'] == null ? 0 : (map['photoCnt'] as num).toInt(),
      newCnt: map['newCnt'] == null ? 0 : (map['newCnt'] as num).toInt(),
      lastSeenDtm: map['lastSeenDtm']?.toString(),
      themeColor: map['themeColor']?.toString(),
      coverMediaIds: (map['coverMediaIds']?.toString() ?? '')
          .split(',')
          .map((e) => int.tryParse(e.trim()))
          .whereType<int>()
          .toList(),
      cardOptions: map['cardOptions'] == null
          ? null
          : map['cardOptions'].toString().split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toSet(),
      avatars: (map['avatars'] as List?)
              ?.map((e) => e.toString())
              .where((e) => e.isNotEmpty)
              .toList() ??
          const [],
      lastMediaDtm: map['lastMediaDtm']?.toString(),
    );
  }
}
