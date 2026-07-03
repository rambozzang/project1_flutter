# SkySnap — App Store Connect 심사 자동제출
# 업로드된 빌드를 처리 완료까지 기다렸다가, App Store 버전 생성 → 빌드 연결 →
# 릴리즈 노트 → 심사 제출까지 수행한다. (deploy_ios.sh --submit 에서 호출)
#
# 필요한 환경변수:
#   ASC_API_KEY_ID       : App Store Connect API Key ID (예: B946U72BT4)
#   ASC_API_ISSUER_ID    : Issuer ID (UUID, 사용자·액세스 > 통합 상단)
#   ASC_API_KEY_PATH     : AuthKey_XXXX.p8 경로
#   APPLE_BUNDLE_ID      : 번들 ID (기본 com.codelabtiger.skysnap)
#   APP_VERSION          : 마케팅 버전 (예: 1.2.0)
#   BUILD_NUMBER         : 빌드 번호 (예: 49)
#   ASC_RELEASE_NOTES_FILE : 릴리즈 노트 파일 (기본 scripts/release_notes_ko.txt)
import os
import sys
import time

import jwt  # PyJWT
import requests

KEY_ID = os.environ.get("ASC_API_KEY_ID", "")
ISSUER = os.environ.get("ASC_API_ISSUER_ID", "")
KEY_PATH = os.environ.get("ASC_API_KEY_PATH", "")
BUNDLE = os.environ.get("APPLE_BUNDLE_ID", "com.codelabtiger.skysnap")
APP_VERSION = os.environ.get("APP_VERSION", "")
BUILD_NUMBER = os.environ.get("BUILD_NUMBER", "")
NOTES_FILE = os.environ.get("ASC_RELEASE_NOTES_FILE", "scripts/release_notes_ko.txt")
LOCALE = "ko"

BASE = "https://api.appstoreconnect.apple.com"


def die(msg):
    print(f"❌ {msg}")
    sys.exit(1)


for k, v in [("ASC_API_ISSUER_ID", ISSUER), ("ASC_API_KEY_ID", KEY_ID),
             ("APP_VERSION", APP_VERSION), ("BUILD_NUMBER", BUILD_NUMBER)]:
    if not v:
        die(f"환경변수 {k} 가 비어있습니다.")
if not os.path.exists(KEY_PATH):
    die(f".p8 키 없음: {KEY_PATH}")


def token():
    with open(KEY_PATH) as f:
        private_key = f.read()
    now = int(time.time())
    payload = {"iss": ISSUER, "iat": now, "exp": now + 1000, "aud": "appstoreconnect-v1"}
    return jwt.encode(payload, private_key, algorithm="ES256", headers={"kid": KEY_ID})


def api(method, path, **kw):
    headers = kw.pop("headers", {})
    headers["Authorization"] = f"Bearer {token()}"
    headers["Content-Type"] = "application/json"
    r = requests.request(method, BASE + path, headers=headers, timeout=60, **kw)
    if r.status_code >= 400:
        raise RuntimeError(f"{method} {path} → {r.status_code}: {r.text[:600]}")
    return r.json() if r.text else {}


notes = "안정성 개선 및 버그 수정"
if os.path.exists(NOTES_FILE):
    c = open(NOTES_FILE, encoding="utf-8").read().strip()
    if c:
        notes = c[:4000]

print(f"▶ App Store 심사 제출: {BUNDLE}  v{APP_VERSION} (build {BUILD_NUMBER})")

# 1. 앱 찾기
apps = api("GET", f"/v1/apps?filter[bundleId]={BUNDLE}")["data"]
if not apps:
    die(f"앱을 찾을 수 없음(bundleId={BUNDLE}) — API 키 권한/계정 확인")
app_id = apps[0]["id"]
print(f"  app id: {app_id}")

# 2. 빌드 처리 완료 대기 (최대 40분)
print("  빌드 처리 상태 확인(최대 40분 폴링)...")
build_id = None
deadline = time.time() + 40 * 60
while time.time() < deadline:
    builds = api("GET", f"/v1/builds?filter[app]={app_id}&filter[version]={BUILD_NUMBER}"
                        f"&fields[builds]=processingState,version&limit=1")["data"]
    if builds:
        state = builds[0]["attributes"]["processingState"]
        build_id = builds[0]["id"]
        print(f"    build {BUILD_NUMBER}: {state}")
        if state == "VALID":
            break
        if state in ("INVALID", "FAILED"):
            die(f"빌드 처리 실패: {state}")
    else:
        print("    아직 빌드가 안 보임(업로드 처리 대기)...")
    time.sleep(60)
if not build_id:
    die("빌드를 찾지 못했습니다(업로드 직후면 잠시 후 재실행). ")

# 3. App Store 버전 확보(없으면 생성)
vers = api("GET", f"/v1/apps/{app_id}/appStoreVersions"
                  f"?filter[versionString]={APP_VERSION}"
                  f"&fields[appStoreVersions]=appStoreState,versionString")["data"]
EDITABLE = {"PREPARE_FOR_SUBMISSION", "DEVELOPER_REJECTED", "REJECTED",
            "METADATA_REJECTED", "INVALID_BINARY"}
if vers:
    ver = vers[0]
    ver_id = ver["id"]
    st = ver["attributes"]["appStoreState"]
    if st not in EDITABLE:
        die(f"버전 {APP_VERSION} 상태가 편집 불가({st}). 새 버전 번호로 올리세요.")
    print(f"  기존 버전 사용: {APP_VERSION} ({st})")
else:
    ver_id = api("POST", "/v1/appStoreVersions", json={"data": {
        "type": "appStoreVersions",
        "attributes": {"platform": "IOS", "versionString": APP_VERSION},
        "relationships": {"app": {"data": {"type": "apps", "id": app_id}}},
    }})["data"]["id"]
    print(f"  버전 생성: {APP_VERSION}")

# 4. 릴리즈 노트(whatsNew) — 기존 로컬라이제이션 갱신, 없으면 생성
locs = api("GET", f"/v1/appStoreVersions/{ver_id}/appStoreVersionLocalizations"
                  f"?fields[appStoreVersionLocalizations]=locale")["data"]
loc = next((l for l in locs if l["attributes"]["locale"] == LOCALE), None) \
    or (locs[0] if locs else None)
try:
    if loc:
        api("PATCH", f"/v1/appStoreVersionLocalizations/{loc['id']}", json={"data": {
            "type": "appStoreVersionLocalizations", "id": loc["id"],
            "attributes": {"whatsNew": notes}}})
        print(f"  릴리즈 노트 갱신({loc['attributes']['locale']})")
except Exception as e:
    print(f"  ⚠️ 릴리즈 노트 설정 스킵: {str(e)[:150]}")

# 5. 빌드 연결
api("PATCH", f"/v1/appStoreVersions/{ver_id}/relationships/build",
    json={"data": {"type": "builds", "id": build_id}})
print("  빌드 연결 완료")

# 6. 심사 제출 (reviewSubmissions 플로우)
try:
    rs = api("POST", "/v1/reviewSubmissions", json={"data": {
        "type": "reviewSubmissions",
        "attributes": {"platform": "IOS"},
        "relationships": {"app": {"data": {"type": "apps", "id": app_id}}},
    }})["data"]
    rs_id = rs["id"]
    api("POST", "/v1/reviewSubmissionItems", json={"data": {
        "type": "reviewSubmissionItems",
        "relationships": {
            "reviewSubmission": {"data": {"type": "reviewSubmissions", "id": rs_id}},
            "appStoreVersion": {"data": {"type": "appStoreVersions", "id": ver_id}},
        }}})
    api("PATCH", f"/v1/reviewSubmissions/{rs_id}",
        json={"data": {"type": "reviewSubmissions", "id": rs_id,
                       "attributes": {"submitted": True}}})
    print(f"✅ App Store 심사 제출 완료 — v{APP_VERSION} (build {BUILD_NUMBER})")
except Exception as e:
    print(f"⚠️ 자동 심사제출 단계 실패: {str(e)[:400]}")
    print("   → 버전·빌드·릴리즈노트까지는 준비 완료. App Store Connect에서")
    print("     '심사에 제출' 버튼만 누르면 됩니다(메타데이터/스크린샷 확인 필요할 수 있음).")
    sys.exit(2)
