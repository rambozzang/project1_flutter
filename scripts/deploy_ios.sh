#!/bin/bash
# SkySnap iOS 릴리즈 빌드 + App Store Connect 업로드 (+선택: App Store 심사 제출)
#   ./deploy_ios.sh [--clean] [--no-upload] [--submit]
#     --clean     : flutter clean 먼저 실행
#     --no-upload : IPA 빌드만, 업로드 생략
#     --submit    : 업로드 후 App Store 심사까지 자동 제출 (ASC_API_ISSUER_ID 필요)
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SCRIPTS="$ROOT/scripts"
cd "$ROOT"

GREEN='\033[0;32m'; RED='\033[0;31m'; BLUE='\033[0;34m'; YELLOW='\033[1;33m'; NC='\033[0m'
ok(){ echo -e "${GREEN}✅ $1${NC}"; }
info(){ echo -e "${BLUE}▶ $1${NC}"; }
warn(){ echo -e "${YELLOW}⚠️ $1${NC}"; }
die(){ echo -e "${RED}❌ $1${NC}"; exit 1; }

[ "$(uname)" = "Darwin" ] || die "iOS 빌드는 macOS 에서만 가능합니다."

DO_CLEAN=false; DO_UPLOAD=true; DO_SUBMIT=false
for a in "$@"; do
  case "$a" in
    --clean) DO_CLEAN=true ;;
    --no-upload) DO_UPLOAD=false ;;
    --submit) DO_SUBMIT=true ;;
  esac
done

[ -f "$SCRIPTS/config.env" ] || die "scripts/config.env 가 없습니다. config.env.example 을 복사해 채우세요."
set -a; source "$SCRIPTS/config.env"; set +a

VER_LINE=$(grep -E '^version:' pubspec.yaml | head -1 | sed -E 's/^version:[[:space:]]*//; s/[[:space:]]*#.*//')
APP_VERSION="${VER_LINE%%+*}"   # 1.2.0
BUILD_NUMBER="${VER_LINE##*+}"  # 49
info "버전 $VER_LINE iOS 빌드 시작 (marketing=$APP_VERSION, build=$BUILD_NUMBER)"

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

info "App Store Connect 업로드"
if [ -n "${ASC_API_KEY_ID:-}" ] && [ -n "${ASC_API_ISSUER_ID:-}" ]; then
  # altool은 --apiKey 사용 시 .p8을 임의 경로가 아니라 고정 탐색 경로에서만 찾는다.
  # (~/.appstoreconnect/private_keys, ~/private_keys, ~/.private_keys 등)
  # ASC_API_KEY_PATH가 그 경로들 밖에 있으면 "Failed to load AuthKey file"로 실패하므로 자동 복사해둔다.
  if [ -n "${ASC_API_KEY_PATH:-}" ] && [ -f "$ASC_API_KEY_PATH" ]; then
    mkdir -p "$HOME/.appstoreconnect/private_keys"
    cp -f "$ASC_API_KEY_PATH" "$HOME/.appstoreconnect/private_keys/AuthKey_${ASC_API_KEY_ID}.p8"
  fi
  xcrun altool --upload-app --type ios --file "$IPA_PATH" \
    --apiKey "$ASC_API_KEY_ID" --apiIssuer "$ASC_API_ISSUER_ID"
else
  [ -n "${APPLE_ID:-}" ] && [ -n "${APPLE_APP_PASSWORD:-}" ] || die "iOS 업로드 자격증명이 없습니다(config.env)."
  xcrun altool --upload-app --type ios --file "$IPA_PATH" \
    --username "$APPLE_ID" --password "$APPLE_APP_PASSWORD" \
    --primary-bundle-id "${APPLE_BUNDLE_ID:-com.codelabtiger.skysnap}"
fi
ok "업로드 완료 (버전 $VER_LINE) — App Store Connect 에서 처리 중(수 분)"

# App Store 심사 자동 제출 (선택)
if $DO_SUBMIT; then
  [ -n "${ASC_API_ISSUER_ID:-}" ] || die "--submit 에는 config.env 의 ASC_API_ISSUER_ID(Issuer ID) 가 필요합니다."
  VENV="$SCRIPTS/.venv-play"
  if [ ! -x "$VENV/bin/python" ]; then
    info "제출용 파이썬 환경 설치(최초 1회)..."
    python3 -m venv "$VENV"
  fi
  "$VENV/bin/pip" install -q pyjwt cryptography requests 2>/dev/null || true
  info "App Store 심사 제출 (빌드 처리 완료까지 폴링, 최대 40분)"
  APP_VERSION="$APP_VERSION" BUILD_NUMBER="$BUILD_NUMBER" "$VENV/bin/python" "$SCRIPTS/appstore_submit.py"
fi

echo ""
ok "iOS 배포 완료 (버전 $VER_LINE)"
