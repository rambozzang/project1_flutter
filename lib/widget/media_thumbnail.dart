import 'dart:ui';

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
///  2. 플레이 배지는 [isVideo] 가 true 일 때만 붙인다 — 사진 게시물에 재생
///     표시가 붙어 있던 문제를 호출부마다 판단하지 않고 여기서 끝낸다.
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

    final Widget image = resolved.isEmpty
        ? fallback
        : CachedNetworkImage(
            imageUrl: resolved,
            cacheKey: resolved,
            fit: fit,
            placeholder: (_, __) => fallback,
            errorWidget: (_, __, ___) => fallback,
          );

    // passthrough 로 부모 제약을 이미지에 그대로 넘겨, 그리드 칸·SizedBox 안에서
    // 이미지가 칸을 꽉 채우게 한다.
    final Widget content = Stack(
      fit: StackFit.passthrough,
      children: [
        image,
        if (isVideo) Positioned(top: 6, right: 6, child: _PlayBadge(size: badgeSize)),
      ],
    );

    if (borderRadius == null) return content;
    return ClipRRect(borderRadius: borderRadius!, child: content);
  }
}

/// 사진 위 다크 글래스 배지 — 톤은 SaGlassChip 과 동일(블러 10, 검정 28%, 강한 보더).
class _PlayBadge extends StatelessWidget {
  const _PlayBadge({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            // 라이트 모드와 무관하게 흰 아이콘·흰 계열 보더 고정
            color: Colors.black.withValues(alpha: 0.28),
            shape: BoxShape.circle,
            border: Border.all(color: SaColorsDark.borderStrong, width: 1),
          ),
          child: Center(
            child: PhosphorIcon(PhosphorIconsFill.play, size: size * 0.5, color: Colors.white),
          ),
        ),
      ),
    );
  }
}
