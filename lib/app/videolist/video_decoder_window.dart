/// 비디오 피드에서 **네이티브 디코더를 실제로 물고 있을 범위.**
///
/// 페이지 위젯은 `preLoadingCount`(5)만큼 앞뒤로 미리 만들어야 넘길 때 레이아웃이
/// 끊기지 않는다. 하지만 디코더까지 그만큼 물 이유는 없다 — 자매 앱(모모앨범)
/// 실측에서 그 상태로 Java 힙이 상한 256MB 를 쳐서 앱이 죽었다.
///
/// **값은 모모앨범과 그대로 맞춘다**(2026-09-04, 사용자 지시). 앞뒤 대칭 3장씩, 총 7개
/// — `album_immersive_page.dart` 의 `_videoWindow = 3`, 판정식
/// `(index - _index).abs() <= 3` 과 동일하다.
///
/// (한때 앞 4/뒤 2로 비대칭을 시도한 적이 있다 — 피드는 아래로만 넘기는 경우가
///  많아 진행 방향 여유를 늘리려 했다. 모모앨범과의 동일성을 우선하기로 하며 되돌렸다.
///  다시 비대칭이 필요하면 이 이유를 참고할 것.)
const int kVideoWindow = 3;

/// 이 영상이 지금 디코더를 물고 있어야 하는지.
///
/// ⚠️ 반드시 **영상 데이터 인덱스**로 판정한다. 피드에는 광고 페이지가 10장마다
/// 끼어 있어 PageView 의 물리적 page 와 영상 인덱스가 어긋난다
/// (`_pageToVideoIndex` 참고).
bool isVideoActive({required int videoIndex, required int currentVideoIndex}) {
  return (videoIndex - currentVideoIndex).abs() <= kVideoWindow;
}
