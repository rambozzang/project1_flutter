#!/bin/bash
# SkySnap Android 릴리즈 빌드 (AAB + APK)
#   ./deploy_android.sh [--clean] [--apk]
#     --clean : flutter clean 먼저 실행
#     --apk   : AAB 외에 APK도 함께 생성
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SCRIPTS="$ROOT/scripts"
cd "$ROOT"

GREEN='\033[0;32m'; RED='\033[0;31m'; BLUE='\033[0;34m'; NC='\033[0m'
ok(){ echo -e "${GREEN}✅ $1${NC}"; }
info(){ echo -e "${BLUE}▶ $1${NC}"; }
die(){ echo -e "${RED}❌ $1${NC}"; exit 1; }

DO_CLEAN=false; DO_APK=false
for a in "$@"; do
  case "$a" in
    --clean) DO_CLEAN=true ;;
    --apk) DO_APK=true ;;
  esac
done

# 1. 설정 로드
[ -f "$SCRIPTS/config.env" ] || die "scripts/config.env 가 없습니다. config.env.example 을 복사해 채우세요."
set -a; source "$SCRIPTS/config.env"; set +a

# 2. 서명 키(key.properties) 자동 생성
KEYPROPS="$ROOT/android/app/key.properties"
[ -f "$ANDROID_KEYSTORE_PATH" ] || die "키스토어를 찾을 수 없습니다: $ANDROID_KEYSTORE_PATH"
cat > "$KEYPROPS" <<EOF
storePassword=${ANDROID_STORE_PASSWORD}
keyPassword=${ANDROID_KEY_PASSWORD}
keyAlias=${ANDROID_KEY_ALIAS}
storeFile=${ANDROID_KEYSTORE_PATH}
EOF
ok "서명 설정 생성: android/app/key.properties"

# 3. 빌드
VER=$(grep -E '^version:' pubspec.yaml | head -1 | sed -E 's/^version:[[:space:]]*//; s/[[:space:]]*#.*//')
info "버전 $VER 빌드 시작"
$DO_CLEAN && { info "flutter clean"; flutter clean; }
flutter pub get

info "AAB(App Bundle) 빌드 — Google Play 제출용"
flutter build appbundle --release
AAB="build/app/outputs/bundle/release/app-release.aab"
[ -f "$AAB" ] || die "AAB 생성 실패"
ok "AAB: $AAB ($(du -h "$AAB" | cut -f1))"

if $DO_APK; then
  info "APK 빌드 — 직접 설치/테스트용"
  flutter build apk --release
  ok "APK: build/app/outputs/flutter-apk/app-release.apk"
fi

echo ""
ok "Android 빌드 완료 (버전 $VER)"
echo "   다음: Google Play Console → 프로덕션/내부테스트 → 위 AAB 업로드"
echo "   (fastlane supply 자동업로드를 쓰려면 scripts/README.md 참고)"
