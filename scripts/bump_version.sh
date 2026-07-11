#!/bin/bash
# pubspec.yaml 버전 증가
#   ./bump_version.sh patch   → 패치 +1, 빌드 +1 (1.2.1+60 → 1.2.2+61)  ★기본값
#   ./bump_version.sh minor   → 마이너 +1
#   ./bump_version.sh major   → 메이저 +1
#   ./bump_version.sh build   → 빌드번호만 +1   (1.2.1+60 → 1.2.1+61)  ⚠️거의 금지
# 인자 없으면 patch 로 동작.
#
# ⚠️ 중요(2026-07-11 사고): 마케팅 버전(patch)을 안 올리고 build 만 올리면
#   ① 앱 업데이트 모달이 안 뜬다 — root_page._compareVersion 이 '+빌드번호'를 버려서
#      1.2.1+60 과 1.2.1+61 을 똑같이 "1.2.1" 로 취급(스토어/백엔드 모두 차이 0).
#   ② iOS 업로드가 거부된다 — 이미 승인된 마케팅 버전 재사용(Error 90062 "train closed").
#   그래서 기본값을 build→patch 로 바꿨다. build 모드는 같은 마케팅 버전 재업로드가
#   확실할 때만. 상세: memory release-always-bump-marketing-version
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PUBSPEC="$ROOT/pubspec.yaml"
MODE="${1:-build}"

# 'version: 1.0.21+46 # 주석' 에서 1.0.21 / 46 추출 (주석 보존)
LINE=$(grep -E '^version:' "$PUBSPEC" | head -1)
VER=$(echo "$LINE" | sed -E 's/^version:[[:space:]]*([0-9]+\.[0-9]+\.[0-9]+)\+([0-9]+).*/\1/')
BUILD=$(echo "$LINE" | sed -E 's/^version:[[:space:]]*([0-9]+\.[0-9]+\.[0-9]+)\+([0-9]+).*/\2/')
MAJOR=$(echo "$VER" | cut -d. -f1)
MINOR=$(echo "$VER" | cut -d. -f2)
PATCH=$(echo "$VER" | cut -d. -f3)

case "$MODE" in
  major) MAJOR=$((MAJOR+1)); MINOR=0; PATCH=0 ;;
  minor) MINOR=$((MINOR+1)); PATCH=0 ;;
  patch) PATCH=$((PATCH+1)) ;;
  build) echo "⚠️  build 모드: 마케팅 버전 유지 → 업데이트 모달 안 뜸·iOS 업로드 거부 위험. 같은 버전 재업로드가 확실할 때만!" ;;
  *) echo "사용법: $0 [build|patch|minor|major]"; exit 1 ;;
esac
BUILD=$((BUILD+1))

NEW="${MAJOR}.${MINOR}.${PATCH}+${BUILD}"
# 같은 줄의 뒤 주석은 유지
sed -i '' -E "s/^version:[[:space:]]*[0-9]+\.[0-9]+\.[0-9]+\+[0-9]+/version: ${NEW}/" "$PUBSPEC"

echo "✅ 버전: ${VER}+$(($BUILD-1)) → ${NEW}"
