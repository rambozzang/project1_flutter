#!/bin/bash
# SkySnap iOS 릴리즈 빌드 + TestFlight 업로드
#   ./deploy_ios.sh [--clean] [--no-upload]
#     --clean     : flutter clean 먼저 실행
#     --no-upload : IPA 빌드만, TestFlight 업로드 생략
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SCRIPTS="$ROOT/scripts"
cd "$ROOT"

GREEN='\033[0;32m'; RED='\033[0;31m'; BLUE='\033[0;34m'; NC='\033[0m'
ok(){ echo -e "${GREEN}✅ $1${NC}"; }
info(){ echo -e "${BLUE}▶ $1${NC}"; }
die(){ echo -e "${RED}❌ $1${NC}"; exit 1; }

[ "$(uname)" = "Darwin" ] || die "iOS 빌드는 macOS 에서만 가능합니다."

DO_CLEAN=false; DO_UPLOAD=true
for a in "$@"; do
  case "$a" in
    --clean) DO_CLEAN=true ;;
    --no-upload) DO_UPLOAD=false ;;
  esac
done

[ -f "$SCRIPTS/config.env" ] || die "scripts/config.env 가 없습니다. config.env.example 을 복사해 채우세요."
set -a; source "$SCRIPTS/config.env"; set +a

VER=$(grep -E '^version:' pubspec.yaml | head -1 | sed -E 's/^version:[[:space:]]*//; s/[[:space:]]*#.*//')
info "버전 $VER iOS 빌드 시작"

$DO_CLEAN && { info "flutter clean"; flutter clean; }
flutter pub get
( cd ios && pod install >/dev/null 2>&1 || true )

info "IPA 빌드 (flutter build ipa --release)"
flutter build ipa --release

IPA_PATH=$(find build/ios/ipa -name "*.ipa" | head -n 1)
[ -n "$IPA_PATH" ] || die "IPA 파일을 찾을 수 없습니다. Xcode 자동 서명 설정을 확인하세요."
ok "IPA: $IPA_PATH ($(du -h "$IPA_PATH" | cut -f1))"

if ! $DO_UPLOAD; then
  ok "업로드 생략(--no-upload). 빌드만 완료."
  exit 0
fi

info "TestFlight 업로드"
if [ -n "${ASC_API_KEY_ID:-}" ] && [ -n "${ASC_API_ISSUER_ID:-}" ]; then
  # 방법 A: App Store Connect API Key (권장)
  xcrun altool --upload-app --type ios \
    --file "$IPA_PATH" \
    --apiKey "$ASC_API_KEY_ID" \
    --apiIssuer "$ASC_API_ISSUER_ID"
else
  # 방법 B: Apple ID + 앱 전용 암호
  [ -n "${APPLE_ID:-}" ] && [ -n "${APPLE_APP_PASSWORD:-}" ] || die "iOS 업로드 자격증명이 없습니다(config.env)."
  xcrun altool --upload-app --type ios \
    --file "$IPA_PATH" \
    --username "$APPLE_ID" \
    --password "$APPLE_APP_PASSWORD" \
    --primary-bundle-id "${APPLE_BUNDLE_ID:-com.codelabtiger.skysnap}"
fi

ok "iOS TestFlight 업로드 완료 (버전 $VER)"
echo "   App Store Connect → TestFlight 에서 처리 상태를 확인하세요(수 분 소요)."
