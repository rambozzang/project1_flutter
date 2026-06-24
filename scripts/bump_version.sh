#!/bin/bash
# pubspec.yaml 버전 증가
#   ./bump_version.sh build   → 빌드번호만 +1   (1.0.21+46 → 1.0.21+47)
#   ./bump_version.sh patch   → 패치 +1, 빌드 +1 (1.0.21+46 → 1.0.22+47)
#   ./bump_version.sh minor   → 마이너 +1
#   ./bump_version.sh major   → 메이저 +1
# 인자 없으면 build 로 동작.
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
  build) ;;
  *) echo "사용법: $0 [build|patch|minor|major]"; exit 1 ;;
esac
BUILD=$((BUILD+1))

NEW="${MAJOR}.${MINOR}.${PATCH}+${BUILD}"
# 같은 줄의 뒤 주석은 유지
sed -i '' -E "s/^version:[[:space:]]*[0-9]+\.[0-9]+\.[0-9]+\+[0-9]+/version: ${NEW}/" "$PUBSPEC"

echo "✅ 버전: ${VER}+$(($BUILD-1)) → ${NEW}"
