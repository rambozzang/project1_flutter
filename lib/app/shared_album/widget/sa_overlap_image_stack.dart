import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:project1/app/community/widget/cover_template.dart' show coverImageUrl;
import 'package:project1/app/shared_album/theme/sa_colors.dart';
import 'package:project1/app/shared_album/theme/sa_weather_gradients.dart';

/// 홈 카드(1a)의 겹침 이미지 스택.
/// 중앙 리드 이미지 + 좌우 뒤에 2장이 ±7° 회전해 삐져나오는 형태.
/// 이미지 URL이 없으면 gradientKey 기반 날씨 그라디언트 플레이스홀더를 그린다.
class SaOverlapImageStack extends StatelessWidget {
  const SaOverlapImageStack({
    super.key,
    this.leadUrl,
    this.leftUrl,
    this.rightUrl,
    this.gradientKey,
    this.height = 208,
    this.leadHeight = 200,
    this.overlay,
    this.heroTag,
  });

  final String? leadUrl;
  final String? leftUrl;
  final String? rightUrl;

  /// 이미지 없을 때 쓸 날씨 그라디언트 키(rain/sunset/...). null이면 night.
  final String? gradientKey;
  final double height;
  final double leadHeight;

  /// 리드 이미지 위 오버레이(날씨칩·미디어수칩·재생버튼·NEW뱃지 등) — Stack으로 얹힌다.
  final Widget? overlay;
  final Object? heroTag;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final double w = constraints.maxWidth;
          final double leadW = w * 0.62;
          final double sideW = w * 0.46;
          final double sideH = leadHeight * 0.88;
          return Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              // 좌측 뒤 카드 (-7°)
              Positioned(
                left: -sideW * 0.18,
                child: Transform.rotate(
                  angle: -7 * math.pi / 180,
                  child: _media(leftUrl, sideW, sideH, radius: 18, dim: 0.35),
                ),
              ),
              // 우측 뒤 카드 (+7°)
              Positioned(
                right: -sideW * 0.18,
                child: Transform.rotate(
                  angle: 7 * math.pi / 180,
                  child: _media(rightUrl, sideW, sideH, radius: 18, dim: 0.35),
                ),
              ),
              // 중앙 리드
              if (heroTag != null)
                Hero(
                  tag: heroTag!,
                  transitionOnUserGestures: true,
                  child: _media(leadUrl, leadW, leadHeight, radius: 20, shadow: true),
                )
              else
                _media(leadUrl, leadW, leadHeight, radius: 20, shadow: true),
              if (overlay != null)
                SizedBox(width: leadW, height: leadHeight, child: overlay),
            ],
          );
        },
      ),
    );
  }

  Widget _media(String? url, double w, double h, {required double radius, bool shadow = false, double dim = 0}) {
    final Widget inner = url == null || url.isEmpty
        ? DecoratedBox(decoration: BoxDecoration(gradient: SaWeatherGradients.of(gradientKey)))
        : CachedNetworkImage(
            // Unsplash 표지 폴백은 원본(수 MB)이라 경량본으로 변환(다른 호스트는 no-op)
            imageUrl: coverImageUrl(url, width: 600),
            memCacheWidth: 600,
            fit: BoxFit.cover,
            placeholder: (_, __) =>
                DecoratedBox(decoration: BoxDecoration(gradient: SaWeatherGradients.of(gradientKey))),
            errorWidget: (_, __, ___) =>
                DecoratedBox(decoration: BoxDecoration(gradient: SaWeatherGradients.of(gradientKey))),
          );
    return Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: SaColors.border, width: 1),
        boxShadow: shadow
            ? const [BoxShadow(color: Color(0x8C000000), offset: Offset(0, 16), blurRadius: 34)]
            : null,
      ),
      clipBehavior: Clip.antiAlias,
      foregroundDecoration: dim > 0
          ? BoxDecoration(
              color: Colors.black.withOpacity(dim),
              borderRadius: BorderRadius.circular(radius),
            )
          : null,
      child: inner,
    );
  }
}
