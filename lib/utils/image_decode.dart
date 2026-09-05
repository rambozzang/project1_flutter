import 'package:flutter/widgets.dart';

/// 이미지 **디코딩 해상도**를 정하는 곳.
///
/// `CachedNetworkImage` 는 아무 것도 안 주면 내려받은 원본 크기 그대로 비트맵을 만든다.
/// 44pt 아바타에 1,000px 사진을 넣으면 화면에는 44pt 로 그려지지만 메모리는 1,000px 짜리를
/// 통째로 쓴다(4바이트/픽셀). `memCacheWidth` 로 실제 필요한 크기를 알려주면 디코더가
/// 그 크기로 줄여서 만든다.
///
/// 두 함수 모두 **논리 픽셀(pt)이 아니라 물리 픽셀을 돌려준다** — `memCacheWidth` 가 물리 픽셀
/// 단위이기 때문이다. 화면 배율(DPR)이 3인 기기에서 44pt 아바타는 132px 이 필요하다.
class ImageDecode {
  ImageDecode._();

  /// 고정 크기 자리(아바타·아이콘 등)에 쓴다.
  /// [logicalWidth] 는 위젯에 지정한 pt 값(예: 44).
  static int fixed(BuildContext context, double logicalWidth) {
    final double dpr = MediaQuery.devicePixelRatioOf(context);
    return (logicalWidth * dpr).round().clamp(1, 4096);
  }

  /// 화면을 가득 채우는 자리(전체화면 사진·몰입뷰 배경 등)에 쓴다.
  ///
  /// 원본이 4,000px 사진이어도 화면이 1,320px 이면 1,320px 로만 디코딩한다.
  /// 좌우 스와이프 캐러셀처럼 앞뒤 장이 함께 메모리에 올라가는 자리에서 특히 크게 줄어든다.
  static int fullScreen(BuildContext context) {
    final double dpr = MediaQuery.devicePixelRatioOf(context);
    final double w = MediaQuery.sizeOf(context).width;
    return (w * dpr).round().clamp(1, 4096);
  }
}
