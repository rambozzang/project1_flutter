import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:project1/app/shared_album/theme/sa_colors.dart';
import 'package:project1/app/shared_album/theme/sa_text_styles.dart';
import 'package:project1/app/shared_album/widget/sa_glass_chip.dart';
import 'package:project1/app/shared_album/widget/sa_member_avatar_stack.dart';
import 'package:project1/app/shared_album/widget/sa_new_badge.dart';
import 'package:project1/app/shared_album/widget/sa_overlap_image_stack.dart';
import 'package:project1/repo/community/data/community_data.dart';

/// 1a 홈 카드에 필요한 데이터 묶음(앨범 + 지연 로드되는 썸네일/아바타).
class SaAlbumCardData {
  SaAlbumCardData({required this.community});

  final CommunityData community;

  /// 최근 미디어 썸네일(최대 3장) — 겹침 스택용. 로드 전엔 빈 리스트.
  List<String> thumbs = [];

  /// 백그라운드에서 로드 완료된 썸네일. 아직 화면에는 반영되지 않은 상태.
  /// 모든 카드의 로드가 끝난 뒤 한꺼번에 [thumbs]로 옮겨 대문 이미지에서 교체한다.
  List<String> loadedThumbs = [];

  /// 멤버 아바타 URL(최대 3명)
  List<String> avatars = [];

  /// 마지막 업데이트(피드 최신 항목 crtDtm)
  String? lastUpdated;

  /// 총 미디어 수(백엔드 확장 전까지 null → 칩 숨김)
  int? mediaCount;

  /// 안 본 새 콘텐츠 수(백엔드 확장 전까지 0 → 뱃지 숨김)
  int newCount = 0;
}

/// 홈(1a) — 앨범 스택 피드 카드.
/// 겹침 이미지 스택 + 제목/소개 + 스탯 행(멤버 아바타·수·최근 업데이트).
class SaAlbumCard extends StatelessWidget {
  const SaAlbumCard({super.key, required this.data, required this.onTap});

  final SaAlbumCardData data;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = data.community;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: SaColors.surface,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: SaColors.border, width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SaOverlapImageStack(
                leadUrl: data.thumbs.isNotEmpty ? data.thumbs[0] : c.imageUrl,
                leftUrl: data.thumbs.length > 1 ? data.thumbs[1] : null,
                rightUrl: data.thumbs.length > 2 ? data.thumbs[2] : null,
                gradientKey: _gradientKeyFor(c),
                overlay: Stack(
                  children: [
                    if (data.mediaCount != null && c.showOpt('media'))
                      Positioned(
                        right: 10,
                        top: 10,
                        child: SaGlassChip(label: '+${data.mediaCount}', mono: true),
                      ),
                    Center(
                      child: Container(
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.16),
                          shape: BoxShape.circle,
                          // 사진 위 오버레이 — 라이트 모드와 무관하게 흰 계열 고정
                          border: Border.all(color: SaColorsDark.borderStrong),
                        ),
                        child: const PhosphorIcon(PhosphorIconsFill.play,
                            size: 22, color: Colors.white),
                      ),
                    ),
                    Positioned(
                        left: 12,
                        bottom: 12,
                        child: SaNewBadge(count: c.showOpt('new') ? data.newCount : 0)),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Flexible(child: Text(c.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: SaText.titleM)),
                  // 내가 만든 앨범(주인장)이면 대장 뱃지 노출.
                  if (c.isOwner) ...[
                    const SizedBox(width: 6),
                    const SaOwnerBadge(),
                  ],
                ],
              ),
              if ((c.description ?? '').isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(c.description!, maxLines: 2, overflow: TextOverflow.ellipsis, style: SaText.body.copyWith(fontSize: 13)),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  if (c.showOpt('avatars')) ...[
                    SaMemberAvatarStack(
                      avatarUrls: data.avatars,
                      extraCount: (c.memberCnt - data.avatars.length).clamp(0, 999),
                    ),
                    const SizedBox(width: 8),
                  ],
                  if (c.showOpt('member')) Text('멤버 ${c.memberCnt}', style: SaText.caption),
                  if (data.lastUpdated != null) ...[
                    _dot(),
                    Text(data.lastUpdated!, style: SaText.mono(fontSize: 10.5)),
                  ],
                  const Spacer(),
                  PhosphorIcon(PhosphorIconsBold.caretRight, size: 14, color: SaColors.textTertiary),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dot() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Container(
        width: 3,
        height: 3,
        decoration: BoxDecoration(color: SaColors.textTertiary, shape: BoxShape.circle),
      ),
    );
  }

  /// 앨범별 무드 그라디언트 키: 대문 편집(1f)에서 고른 테마 컬러가 있으면 우선,
  /// 없으면 앨범 id 기반 순환(카드마다 다른 톤).
  String _gradientKeyFor(CommunityData c) {
    if ((c.themeColor ?? '').isNotEmpty) return c.themeColor!;
    const keys = ['rain', 'sunset', 'storm', 'night', 'aurora', 'golden', 'fog', 'snow'];
    return keys[c.communityId % keys.length];
  }
}

/// 앨범 주인장(대장) 표시 뱃지 — 리스트/모자이크 카드 공용.
class SaOwnerBadge extends StatelessWidget {
  const SaOwnerBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFEAA61E), // 대장 = 골드
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const PhosphorIcon(PhosphorIconsFill.crown, size: 11, color: Colors.white),
          const SizedBox(width: 3),
          Text('대장', style: SaText.mono(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white)),
        ],
      ),
    );
  }
}
