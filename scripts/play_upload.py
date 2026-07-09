# SkySnap AAB → Google Play 업로드 (deploy_android.sh 에서 호출)
#
# 필요한 환경변수(config.env 에서 로드됨):
#   PLAY_SERVICE_ACCOUNT_JSON : Play Console 서비스계정 JSON 경로 (필수)
#   PLAY_PACKAGE_NAME         : 패키지명 (기본 com.codelabtiger.skysnap)
#   PLAY_TRACK                : production | internal | alpha | beta (기본 production)
#   PLAY_AAB_PATH             : AAB 경로 (기본 build/app/outputs/bundle/release/app-release.aab)
#   PLAY_RELEASE_NOTES_FILE   : 릴리즈 노트(ko-KR) 텍스트 파일 (기본 scripts/release_notes_ko.txt)
import os
import sys

from google.oauth2 import service_account
from googleapiclient.discovery import build
from googleapiclient.http import MediaFileUpload

SA_JSON = os.environ.get("PLAY_SERVICE_ACCOUNT_JSON", "")
PACKAGE = os.environ.get("PLAY_PACKAGE_NAME", "com.codelabtiger.skysnap")
TRACK = os.environ.get("PLAY_TRACK", "production")
AAB = os.environ.get("PLAY_AAB_PATH", "build/app/outputs/bundle/release/app-release.aab")
NOTES_FILE = os.environ.get("PLAY_RELEASE_NOTES_FILE", "scripts/release_notes_ko.txt")

if not SA_JSON or not os.path.exists(SA_JSON):
    sys.exit(f"❌ 서비스계정 JSON 없음: '{SA_JSON}' (config.env 의 PLAY_SERVICE_ACCOUNT_JSON 확인)")
if not os.path.exists(AAB):
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

size_mb = os.path.getsize(AAB) / 1024 / 1024
print(f"2) AAB 업로드 중 ({size_mb:.1f}MB)...")
media = MediaFileUpload(AAB, mimetype="application/octet-stream",
                        resumable=True, chunksize=8 * 1024 * 1024)
req = svc.edits().bundles().upload(packageName=PACKAGE, editId=edit_id, media_body=media)
resp = None
while resp is None:
    status, resp = req.next_chunk()
    if status:
        print(f"   업로드 {int(status.progress() * 100)}%", flush=True)
version_code = resp["versionCode"]
print("   업로드 완료. versionCode:", version_code)

print(f"3) {TRACK} 트랙 릴리즈 설정...")
svc.edits().tracks().update(
    packageName=PACKAGE, editId=edit_id, track=TRACK,
    body={"releases": [{
        "versionCodes": [str(version_code)],
        "status": "completed",
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

print("4) commit(심사 제출)...")
try:
    svc.edits().commit(packageName=PACKAGE, editId=edit_id).execute()
    print(f"✅ 완료 — versionCode {version_code} 이(가) {TRACK} 트랙에 제출됨 (구글 심사 후 배포)")
except Exception as e:
    # 콘솔에 미완료 선언 등이 있으면 리뷰 미전송 커밋으로 폴백
    print("   기본 커밋 실패:", e)
    print("   changesNotSentForReview=True 로 재시도...")
    svc.edits().commit(packageName=PACKAGE, editId=edit_id,
                       changesNotSentForReview=True).execute()
    print(f"⚠️ 커밋됨(리뷰 미전송) — Play Console 에서 '변경사항 검토 후 제출' 필요 (versionCode {version_code})")
