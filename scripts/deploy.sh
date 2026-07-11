#!/bin/bash
# SkySnap 통합 배포
#   ./deploy.sh <target> [옵션]
#     target : android | ios | all
#   옵션:
#     --bump [patch|minor|major|build|none]  배포 전 버전 증가 (기본: patch 자동)
#            ★기본 patch — 마케팅 버전을 매 배포마다 올려 앱 업데이트 모달이 반드시 뜨게 하고
#              iOS 업로드 거부(train closed)를 방지한다. 버전 유지가 꼭 필요하면 --bump none.
#     --clean                           flutter clean 수행
#     --apk                             (android) APK도 생성
#     --no-upload                       (ios) TestFlight 업로드 생략
#
# 예) ./deploy.sh all            (patch 자동 범프 후 양대 스토어)
#     ./deploy.sh all --clean
#     ./deploy.sh android --apk
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SCRIPTS="$ROOT/scripts"
GREEN='\033[0;32m'; RED='\033[0;31m'; BLUE='\033[0;34m'; YELLOW='\033[1;33m'; NC='\033[0m'

TARGET="${1:-}"; shift || true
case "$TARGET" in android|ios|all) ;; *)
  echo "사용법: ./deploy.sh <android|ios|all> [--bump build|patch|minor|major] [--clean] [--apk] [--no-upload]"
  exit 1 ;;
esac

BUMP=""; PASS=()
while [ $# -gt 0 ]; do
  case "$1" in
    --bump) BUMP="${2:-patch}"; shift 2 ;;
    *) PASS+=("$1"); shift ;;
  esac
done

# --bump 미지정 시 patch 자동(마케팅 버전 강제). 버전 유지가 필요하면 --bump none.
# ⚠️ 2026-07-11 사고: build-only(마케팅 버전 유지)는 ① 앱 업데이트 모달이 안 뜨고
#    ② iOS 업로드가 거부된다(Error 90062). 그래서 기본을 patch 로 강제한다.
if [ -z "$BUMP" ]; then BUMP="patch"; fi
if [ "$BUMP" = "none" ]; then BUMP=""; fi

echo -e "${BLUE}════════════════════════════════════════${NC}"
echo -e "${BLUE} SkySnap 배포  target=${TARGET}${NC}"
echo -e "${BLUE}════════════════════════════════════════${NC}"

# 버전 증가(선택)
if [ -n "$BUMP" ]; then
  bash "$SCRIPTS/bump_version.sh" "$BUMP"
fi

run_android(){ bash "$SCRIPTS/deploy_android.sh" "${PASS[@]:-}"; }
run_ios(){ bash "$SCRIPTS/deploy_ios.sh" "${PASS[@]:-}"; }

case "$TARGET" in
  android) run_android ;;
  ios)     run_ios ;;
  all)
    run_android
    echo ""
    run_ios
    ;;
esac

echo -e "${GREEN}════════════════════════════════════════${NC}"
echo -e "${GREEN} 배포 작업 완료 ($TARGET)${NC}"
echo -e "${GREEN}════════════════════════════════════════${NC}"
