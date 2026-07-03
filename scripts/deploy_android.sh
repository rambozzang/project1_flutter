#!/bin/bash
# SkySnap Android 릴리즈 빌드 + Google Play 자동 업로드
#   ./deploy_android.sh [--clean] [--apk] [--no-upload]
#     --clean     : flutter clean 먼저 실행
#     --apk       : AAB 외에 APK도 함께 생성
#     --no-upload : Play 업로드 생략 (빌드만)
#
# Play 업로드에는 scripts/config.env 의 PLAY_SERVICE_ACCOUNT_JSON 이 필요합니다.
# 릴리즈 노트는 scripts/release_notes_ko.txt 를 수정하세요 (매 배포 전 갱신 권장).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SCRIPTS="$ROOT/scripts"
cd "$ROOT"

GREEN='\033[0;32m'; RED='\033[0;31m'; BLUE='\033[0;34m'; YELLOW='\033[1;33m'; NC='\033[0m'
ok(){ echo -e "${GREEN}✅ $1${NC}"; }
info(){ echo -e "${BLUE}▶ $1${NC}"; }
warn(){ echo -e "${YELLOW}⚠️ $1${NC}"; }
die(){ echo -e "${RED}❌ $1${NC}"; exit 1; }

DO_CLEAN=false; DO_APK=false; DO_UPLOAD=true
for a in "$@"; do
  case "$a" in
    --clean) DO_CLEAN=true ;;
    --apk) DO_APK=true ;;
    --no-upload) DO_UPLOAD=false ;;
  esac
done

# 1. 설정 로드 (없어도 기존 key.properties 가 있으면 빌드는 가능)
if [ -f "$SCRIPTS/config.env" ]; then
  set -a; source "$SCRIPTS/config.env"; set +a
fi

# 2. 서명 키(key.properties) — config.env 에 키스토어 값이 있으면 생성, 없으면 기존 파일 사용
KEYPROPS="$ROOT/android/app/key.properties"
if [ -n "${ANDROID_KEYSTORE_PATH:-}" ]; then
  [ -f "$ANDROID_KEYSTORE_PATH" ] || die "키스토어를 찾을 수 없습니다: $ANDROID_KEYSTORE_PATH"
  cat > "$KEYPROPS" <<EOF
storePassword=${ANDROID_STORE_PASSWORD}
keyPassword=${ANDROID_KEY_PASSWORD}
keyAlias=${ANDROID_KEY_ALIAS}
storeFile=${ANDROID_KEYSTORE_PATH}
EOF
  ok "서명 설정 생성: android/app/key.properties"
elif [ -f "$KEYPROPS" ]; then
  ok "기존 서명 설정 사용: android/app/key.properties"
else
  die "서명 설정이 없습니다. config.env 의 ANDROID_* 를 채우거나 android/app/key.properties 를 준비하세요."
fi

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

# 4. Google Play 업로드 (서비스계정 JSON 필요)
if $DO_UPLOAD; then
  if [ -z "${PLAY_SERVICE_ACCOUNT_JSON:-}" ] || [ ! -f "${PLAY_SERVICE_ACCOUNT_JSON:-}" ]; then
    warn "PLAY_SERVICE_ACCOUNT_JSON 미설정/없음 → 업로드 생략 (config.env 확인)"
    echo "   수동 업로드: Google Play Console → 프로덕션 → $AAB"
  else
    # 파이썬 업로드 환경(venv) 자동 준비 — 최초 1회만 설치
    VENV="$SCRIPTS/.venv-play"
    if [ ! -x "$VENV/bin/python" ]; then
      info "업로드용 파이썬 환경 설치(최초 1회)..."
      python3 -m venv "$VENV"
      "$VENV/bin/pip" install -q google-auth google-api-python-client
    fi
    info "Google Play 업로드 시작 (트랙: ${PLAY_TRACK:-production})"
    PLAY_AAB_PATH="$AAB" "$VENV/bin/python" "$SCRIPTS/play_upload.py"
  fi
fi

echo ""
ok "Android 배포 완료 (버전 $VER)"
