import 'package:flutter/material.dart';

String saAlbumCoverHeroTag(int communityId) => 'shared-album-cover-$communityId';

/// 목록의 앨범 표지와 앨범 내부 대문을 잇는 shared-element 전환.
/// 시스템에서 동작 줄이기를 사용 중이면 Hero를 생략해 접근성 설정을 존중한다.
class SaAlbumCoverHero extends StatelessWidget {
  const SaAlbumCoverHero({
    super.key,
    required this.communityId,
    required this.child,
  });

  final int communityId;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (reduceMotion) return child;
    return Hero(
      tag: saAlbumCoverHeroTag(communityId),
      transitionOnUserGestures: true,
      child: child,
    );
  }
}
