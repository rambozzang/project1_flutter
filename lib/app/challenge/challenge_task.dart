/// 챌린지 typeCd/targetCd 를 해석해 "앱 내 행동(촬영/업로드)으로 달성하는
/// 챌린지"인지 판단한다.
///
/// 서버가 내려주는 코드값을 정확히 알 수 없으므로 키워드 부분 일치로 관대하게
/// 판정한다. 매칭에 실패하면 기존의 수동 완료(버튼 탭) 방식으로 자연스럽게
/// fallback 되므로, 오탐이 있어도 기능이 퇴화하지 않는다.
class ChallengeTask {
  /// 촬영/업로드 계열 과제인지 여부.
  /// true 이면 화면은 "완료하기"(가짜 보상 클릭) 대신 카메라로 이동시켜
  /// 실제 게시(업로드)로 달성하도록 유도한다. 업로드가 끝나면 서버가 자동으로
  /// 오늘 챌린지를 완료 처리한다(RootCntr._completeTodayChallengeAfterUpload).
  static bool isCaptureTask(String? typeCd, String? targetCd) {
    final s = '${typeCd ?? ''} ${targetCd ?? ''}'.toUpperCase();
    if (s.trim().isEmpty) return false;
    const keys = [
      'VIDEO', 'PHOTO', 'POST', 'UPLOAD', 'SHOOT', 'SNAP', 'FEED', 'CAM',
      'SKY', 'CLOUD', 'SUNSET', 'SUNRISE', 'RAIN', 'SNOW', 'RECORD',
    ];
    return keys.any(s.contains);
  }
}
