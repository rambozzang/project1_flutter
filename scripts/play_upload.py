# SkySnap AAB → Google Play 업로드 (deploy_android.sh 에서 호출)
#
# 필요한 환경변수(config.env 에서 로드됨):
#   PLAY_SERVICE_ACCOUNT_JSON : Play Console 서비스계정 JSON 경로 (필수)
#   PLAY_PACKAGE_NAME         : 패키지명 (기본 com.codelabtiger.skysnap)
#   PLAY_TRACK                : production | internal | alpha | beta (기본 production)
#   PLAY_AAB_PATH             : AAB 경로 (기본 build/app/outputs/bundle/release/app-release.aab)
#   PLAY_RELEASE_NOTES_FILE   : 릴리즈 노트(ko-KR) 텍스트 파일 (기본 scripts/release_notes_ko.txt)
#   PLAY_RELEASE_STATUS       : completed(기본) | draft
#       draft = 심사 제출 없이 번들만 트랙에 올린다. 새 권한(FOREGROUND_SERVICE_* 등)이 들어간
#       빌드는 Play 가 "앱 콘텐츠 선언" 을 요구해 completed 커밋이 403 으로 거부되는데, 그 선언 폼은
#       해당 권한이 든 번들이 트랙에 올라간 뒤에야 콘솔에 나타난다(2026-09-06). draft 로 먼저 올려
#       폼을 열고, 선언 뒤 PLAY_PROMOTE_VERSION_CODE 로 같은 번들을 completed 로 바꾼다.
#   PLAY_PROMOTE_VERSION_CODE : 지정 시 AAB 업로드를 건너뛰고 이미 올라간 versionCode 를 트랙 릴리즈로 설정
import os
import socket
import sys

# 대용량 AAB(130MB+)의 마지막 청크에서 서버가 번들 전체를 처리하는 동안
# 기본 소켓 타임아웃으로 read가 끊기던 문제(2026-07-15) → 10분으로 연장.
socket.setdefaulttimeout(600)

from google.oauth2 import service_account
from googleapiclient.discovery import build
from googleapiclient.http import MediaFileUpload

SA_JSON = os.environ.get("PLAY_SERVICE_ACCOUNT_JSON", "")
PACKAGE = os.environ.get("PLAY_PACKAGE_NAME", "com.codelabtiger.skysnap")
TRACK = os.environ.get("PLAY_TRACK", "production")
AAB = os.environ.get("PLAY_AAB_PATH", "build/app/outputs/bundle/release/app-release.aab")
NOTES_FILE = os.environ.get("PLAY_RELEASE_NOTES_FILE", "scripts/release_notes_ko.txt")
RELEASE_STATUS = os.environ.get("PLAY_RELEASE_STATUS", "completed")
PROMOTE = os.environ.get("PLAY_PROMOTE_VERSION_CODE", "").strip()
if RELEASE_STATUS not in ("completed", "draft"):
    sys.exit(f"❌ PLAY_RELEASE_STATUS 는 completed | draft 만 가능: {RELEASE_STATUS}")

if not SA_JSON or not os.path.exists(SA_JSON):
    sys.exit(f"❌ 서비스계정 JSON 없음: '{SA_JSON}' (config.env 의 PLAY_SERVICE_ACCOUNT_JSON 확인)")
if not PROMOTE and not os.path.exists(AAB):
    sys.exit(f"❌ AAB 없음: {AAB} (flutter build appbundle --release 먼저)")

notes = "안정성 개선 및 버그 수정"
if os.path.exists(NOTES_FILE):
    with open(NOTES_FILE, encoding="utf-8") as f:
        content = f.read().strip()
    if content:
        notes = content[:500]  # Play 릴리즈 노트 500자 제한

creds = service_account.Credentials.from_service_account_file(
    SA_JSON, scopes=["https://www.googleapis.com/auth/androidpublisher"])
svc = build("androidpublisher", "v3", credentials=creds)

print(f"▶ Play 업로드: {PACKAGE} → {TRACK} 트랙")
print("1) edit 생성...")
edit_id = svc.edits().insert(packageName=PACKAGE, body={}).execute()["id"]

if PROMOTE:
    version_code = int(PROMOTE)
    print(f"2) AAB 업로드 생략 — 이미 올라간 versionCode {version_code} 를 사용")
else:
    size_mb = os.path.getsize(AAB) / 1024 / 1024
    print(f"2) AAB 업로드 중 ({size_mb:.1f}MB)...")
    media = MediaFileUpload(AAB, mimetype="application/octet-stream",
                            resumable=True, chunksize=8 * 1024 * 1024)
    req = svc.edits().bundles().upload(packageName=PACKAGE, editId=edit_id, media_body=media)
    resp = None
    while resp is None:
        status, resp = req.next_chunk(num_retries=5)  # 일시적 네트워크/5xx 재시도
        if status:
            print(f"   업로드 {int(status.progress() * 100)}%", flush=True)
    version_code = resp["versionCode"]
    print("   업로드 완료. versionCode:", version_code)

print(f"3) {TRACK} 트랙 릴리즈 설정 (status={RELEASE_STATUS})...")
svc.edits().tracks().update(
    packageName=PACKAGE, editId=edit_id, track=TRACK,
    body={"releases": [{
        "versionCodes": [str(version_code)],
        "status": RELEASE_STATUS,
        "releaseNotes": [{"language": "ko-KR", "text": notes}],
    }]},
).execute()

# 3.5) 스토어 등록정보 제목(ko-KR) — fastlane 메타데이터에서 읽어 같은 edit에 함께 반영.
#      제목만 부분 갱신(patch)해 짧은/전체 설명은 건드리지 않는다. 실패해도 배포는 계속.
TITLE_FILE = os.environ.get("PLAY_TITLE_FILE", "fastlane/metadata/android/ko-KR/title.txt")
if os.path.exists(TITLE_FILE):
    with open(TITLE_FILE, encoding="utf-8") as f:
        title = f.read().strip()[:30]  # Play 제목 30자 제한
    if title:
        try:
            svc.edits().listings().patch(
                packageName=PACKAGE, editId=edit_id, language="ko-KR",
                body={"title": title}).execute()
            print(f"3.5) 등록정보 제목 반영(ko-KR): {title}")
        except Exception as e:
            print("   ⚠️ 제목 반영 스킵(배포는 계속):", str(e)[:200])

print("4) commit(초안 저장)..." if RELEASE_STATUS == "draft" else "4) commit(심사 제출)...")
try:
    svc.edits().commit(packageName=PACKAGE, editId=edit_id).execute()
    if RELEASE_STATUS == "draft":
        print(f"✅ 초안 저장 — versionCode {version_code} 이(가) {TRACK} 트랙 초안에 올라감 (심사 미제출). "
              f"콘솔에서 앱 콘텐츠 선언 뒤 PLAY_PROMOTE_VERSION_CODE={version_code} 로 다시 실행")
    else:
        print(f"✅ 완료 — versionCode {version_code} 이(가) {TRACK} 트랙에 제출됨 (구글 심사 후 배포)")
except Exception as e:
    # 콘솔에 미완료 선언 등이 있으면 리뷰 미전송 커밋으로 폴백
    print("   기본 커밋 실패:", e)
    print("   changesNotSentForReview=True 로 재시도...")
    svc.edits().commit(packageName=PACKAGE, editId=edit_id,
                       changesNotSentForReview=True).execute()
    print(f"⚠️ 커밋됨(리뷰 미전송) — Play Console 에서 '변경사항 검토 후 제출' 필요 (versionCode {version_code})")
