#!/usr/bin/env bash
# SkySnap 개발용 logcat 헬퍼
# - 앱 프로세스(--pid)의 로그만 표시
# - 쓸데없는 Android 시스템/WebView 노이즈를 필터링해서 깔끔하게 본다.
#
# 사용법:
#   scripts/logcat.sh                 # 기본 패키지(com.codelabtiger.skysnap)
#   scripts/logcat.sh <패키지명>      # 다른 패키지
#   ANDROID_SERIAL=R3CX10EQS3T scripts/logcat.sh   # 기기 여러 대일 때 지정
#
# 노이즈 추가/제거: 아래 NOISE 정규식만 수정하면 된다.
set -euo pipefail

PKG="${1:-com.codelabtiger.skysnap}"

SERIAL_ARG=()
if [ -n "${ANDROID_SERIAL:-}" ]; then
  SERIAL_ARG=(-s "${ANDROID_SERIAL}")
fi

# 필터링할 노이즈 패턴(정규식, | 로 구분). 우리 앱 로그와 무관한 시스템 스팸들.
#  - setRequestedFrameRate : Android 14+ 가변주사율 API. WebView/AdMob 웹뷰가 그릴 때마다 도배(I/View)
#  - VRI\[ / BLASTBufferQueue / ViewRootImpl : 렌더 파이프라인 내부 로그
#  - OpenGLRenderer / eglCodecCommon         : GPU 렌더러 잡음
#  - ProfileInstaller / nativeloader / chatty: 부팅/로더 잡음
NOISE='setRequestedFrameRate|VRI\[|BLASTBufferQueue|ViewRootImpl|OpenGLRenderer|eglCodecCommon|ProfileInstaller|nativeloader|chatty|Looper|InsetsController|ImeTracker'

echo "▶ logcat 시작: pkg=$PKG  (Ctrl+C로 종료)"

# 앱 PID 확보(실행 중이어야 --pid 사용 가능)
PID="$(adb "${SERIAL_ARG[@]}" shell pidof "$PKG" 2>/dev/null | tr -d '\r' | awk '{print $1}')"

if [ -n "${PID}" ]; then
  echo "▶ 앱 PID=$PID 로그만 표시 (노이즈 필터 적용)"
  adb "${SERIAL_ARG[@]}" logcat --pid="${PID}" -v color 2>/dev/null \
    | grep --line-buffered -Ev "${NOISE}"
else
  echo "⚠ 앱이 실행 중이 아닙니다. 전체 로그에서 노이즈만 필터링합니다."
  adb "${SERIAL_ARG[@]}" logcat -v color 2>/dev/null \
    | grep --line-buffered -Ev "${NOISE}"
fi
