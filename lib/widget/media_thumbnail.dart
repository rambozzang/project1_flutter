import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:project1/app/shared_album/theme/sa_colors.dart';
import 'package:project1/utils/cf_media_url.dart';

/// 목록·그리드·지도에 쓰는 공통 썸네일.
///
/// 두 가지를 한 곳에서 보장한다.
///  1. URL 은 항상 [CfMediaUrl.streamPoster] 로 정규화한다 — DB 에 남아 있는
///     애니메이션 GIF 썸네일이 목록에서 재생되지 않고 정적 JPG 로 내려온다.
///  2. 타입 배지는 [isVideo] 가 **false**(사진)일 때만 붙인다. 목록의 대다수가 영상이라
///     "영상마다 재생 배지"는 화면 전체가 배지투성이였다 — 대신 소수인 사진에 표시해
///     "이건 영상이 아니라 사진"이라는 예외만 알려준다(2026-09-04, 모든 영상 리스트 공통 적용).
class MediaThumbnail extends StatelessWidget {
  const MediaThumbnail({
    super.key,
    required this.url,
    required this.isVideo,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.placeholder,
    this.badgeSize = 28,
    this.posterWidth = 900,
  });

  /// 원본 썸네일 URL. 비어 있거나 null 이면 [placeholder] 만 그린다.
  final String? url;

  /// 영상 게시물인가. true 일 때만 우측 상단 플레이 배지를 붙인다.
  final bool isVideo;

  final BoxFit fit;
  final BorderRadius? borderRadius;

  /// 로딩·실패 시 자리 채움. 생략하면 표면색 사각형.
  final Widget? placeholder;

  /// 플레이 배지 지름. 아이콘은 이 값의 절반으로 그린다.
  final double badgeSize;

  /// Cloudflare Stream 에 요청할 포스터 가로 크기(px).
  /// 44pt 아바타에 900px 을 받지 않도록 작은 자리에서는 줄여 넘긴다.
  final int posterWidth;

  @override
  Widget build(BuildContext context) {
    final String raw = url ?? '';
    // 캐시 키도 정규화된 URL 을 쓴다 — 정규화 전 URL 로 캐싱하면 같은 영상의
    // GIF 와 JPG 가 서로 다른 항목으로 두 번 저장된다.
    final String resolved = CfMediaUrl.streamPoster(raw, width: posterWidth);
    final Widget fallback = placeholder ?? Container(color: SaColors.surfaceElevated);

    // 칸 크기에 맞춰 **디코딩 해상도를 낮춘다.**
    // 서버에서 900px 포스터를 받아도 디코딩까지 900px 로 하면 3열 그리드(칸 약 435px)에서
    // 칸마다 약 4배의 비트맵 메모리를 쓴다. memCacheWidth 로 디코더에 실제 필요한 크기를
    // 알려주면 같은 화면을 훨씬 적은 메모리로 그린다. (2026-09-04)
    final Widget image = resolved.isEmpty
        ? fallback
        : LayoutBuilder(
            builder: (context, constraints) {
              final double dpr = MediaQuery.devicePixelRatioOf(context);
              final double w = constraints.maxWidth;
              // 부모가 폭을 안 주는 자리(무한 제약)에서는 원본 그대로 둔다.
              final int? decodeWidth =
                  (w.isFinite && w > 0) ? (w * dpr).round().clamp(1, posterWidth) : null;
              return CachedNetworkImage(
                imageUrl: resolved,
                cacheKey: resolved,
                fit: fit,
                memCacheWidth: decodeWidth,
                placeholder: (_, __) => fallback,
                errorWidget: (_, __, ___) => fallback,
              );
            },
          );

    // passthrough 로 부모 제약을 이미지에 그대로 넘겨, 그리드 칸·SizedBox 안에서
    // 이미지가 칸을 꽉 채우게 한다.
    final Widget content = Stack(
      fit: StackFit.passthrough,
      children: [
        image,
        if (!isVideo) Positioned(top: 6, right: 6, child: _PhotoBadge(size: badgeSize)),
      ],
    );

    if (borderRadius == null) return content;
    return ClipRRect(borderRadius: borderRadius!, child: content);
  }
}

/// 사진(비영상) 게시물 표시 배지.
///
/// ⚠️ 예전엔 [BackdropFilter] 로 배경을 흐렸다. 보기엔 좋았지만 **썸네일 한 칸마다**
/// 별도 레이어를 뜨는 연산이라, 3열 그리드에서 화면당 12~18개가 매 프레임 돌았다
/// (그리드에서 이 위젯을 쓰는 화면이 7개). 블러를 걷어내고 불투명도를 조금 올려
/// 같은 대비를 만든다 — 28px 배지에서는 눈에 띄는 차이가 없다. (2026-09-04)
class _PhotoBadge extends StatelessWidget {
  const _PhotoBadge({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        // 라이트 모드와 무관하게 흰 아이콘·흰 계열 보더 고정.
        // 블러를 뺀 만큼(0.28 → 0.42) 필을 진하게 해 밝은 사진 위에서도 배지가 읽힌다.
        color: Colors.black.withValues(alpha: 0.42),
        shape: BoxShape.circle,
        border: Border.all(color: SaColorsDark.borderStrong, width: 1),
      ),
      child: Center(
        child: PhosphorIcon(PhosphorIconsFill.image, size: size * 0.5, color: Colors.white),
      ),
    );
  }
}
