/// 비디오 피드에서 **네이티브 디코더를 실제로 물고 있을 범위.**
///
/// 페이지 위젯은 `preLoadingCount`(5)만큼 앞뒤로 미리 만들어야 넘길 때 레이아웃이
/// 끊기지 않는다. 하지만 디코더까지 그만큼 물 이유는 없다 — 자매 앱(모모앨범)
/// 실측에서 그 상태로 Java 힙이 상한 256MB 를 쳐서 앱이 죽었다.
///
/// 3으로 둔 이유: 2도 바로 다음 장은 항상 준비되지만, 연속으로 빠르게 넘길 때
/// 여유가 한 장뿐이라 버퍼링이 보일 여지가 있다. 3이면 두 장을 앞서 준비하고
/// 디코더는 여전히 절반 아래다(동시 7개 < 프리로드 11장).
const int kVideoWindow = 3;

/// 이 영상이 지금 디코더를 물고 있어야 하는지.
///
/// ⚠️ 반드시 **영상 데이터 인덱스**로 판정한다. 피드에는 광고 페이지가 10장마다
/// 끼어 있어 PageView 의 물리적 page 와 영상 인덱스가 어긋난다
/// (`_pageToVideoIndex` 참고).
bool isVideoActive({required int videoIndex, required int currentVideoIndex}) {
  return (videoIndex - currentVideoIndex).abs() <= kVideoWindow;
}
