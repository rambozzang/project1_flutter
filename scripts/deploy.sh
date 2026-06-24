#!/bin/bash
# SkySnap 통합 배포
#   ./deploy.sh <target> [옵션]
#     target : android | ios | all
#   옵션:
#     --bump [build|patch|minor|major]  배포 전 버전 증가 (기본: 안 함)
#     --clean                           flutter clean 수행
#     --apk                             (android) APK도 생성
#     --no-upload                       (ios) TestFlight 업로드 생략
#
# 예) ./deploy.sh all --bump build --clean
#     ./deploy.sh android --apk
#     ./deploy.sh ios --no-upload
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
    --bump) BUMP="${2:-build}"; shift 2 ;;
    *) PASS+=("$1"); shift ;;
  esac
done

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
