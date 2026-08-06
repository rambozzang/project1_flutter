import 'package:flutter/material.dart';

/// 영상이 아직 인코딩 중임을 알리는 배지.
///
/// Cloudflare Stream 은 업로드 후 인코딩을 마쳐야 재생된다. 그런데 재생 URL 은
/// uid 만으로 조립되므로 인코딩 전에도 게시물이 만들어져 목록에 바로 뜬다.
/// 실측(2026-08-05) 인코딩 시간은 중앙값 20초 안팎, 최대 11분 36초였다.
/// 그 사이 썸네일만 보고 눌렀다가 재생이 안 되면 고장으로 오해하므로,
/// 목록 단계에서 미리 알려준다.
///
/// 썸네일 위에 겹쳐 쓴다.
/// ```dart
/// Stack(children: [
///   thumbnailWidget,
///   if (item.isVideoProcessing) const VideoProcessingBadge(),
/// ])
/// ```
class VideoProcessingBadge extends StatelessWidget {
  /// 배지만 표시할지(false), 썸네일 전체를 어둡게 덮을지(true).
  /// 그리드처럼 작은 칸에서는 덮는 편이 눈에 잘 띈다.
  final bool dimBackground;

  /// 작은 썸네일(그리드)용 축소 표시
  final bool compact;

  const VideoProcessingBadge({
    super.key,
    this.dimBackground = true,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final badge = Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : 9,
        vertical: compact ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.72),
        borderRadius: BorderRadius.circular(compact ? 5 : 7),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: compact ? 9 : 12,
            height: compact ? 9 : 12,
            child: const CircularProgressIndicator(strokeWidth: 1.6, color: Colors.white),
          ),
          SizedBox(width: compact ? 4 : 6),
          Text(
            '처리중',
            style: TextStyle(
              color: Colors.white,
              fontSize: compact ? 9 : 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );

    if (!dimBackground) {
      return Positioned(left: 6, top: 6, child: badge);
    }

    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.42),
        alignment: Alignment.center,
        child: badge,
      ),
    );
  }
}
