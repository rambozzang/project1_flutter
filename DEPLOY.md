# SkySnap 스토어 배포 가이드

앱(iOS/Android)을 스토어에 배포하는 표준 절차. 모든 명령은 `skysnap_app/`에서 실행한다.
(2026-07-15 v1.2.4+64 배포 기준으로 검증된 절차)

## TL;DR — 양대 스토어 한 번에

```bash
# 1) 릴리즈 노트 갱신(필수 — Play/App Store 양쪽에 그대로 반영됨)
vi scripts/release_notes_ko.txt

# 2) 배포 (patch 버전 자동 범프 → Android AAB→Play production → iOS IPA→ASC→심사 제출)
./scripts/deploy.sh all --submit
```

- `--submit`: iOS 업로드 후 **App Store 심사까지 자동 제출**(ASC 빌드 처리 완료까지 최대 40분 폴링).
  빼면 App Store Connect에 업로드만 되고 심사 제출은 수동.
- Android는 Play **production 트랙에 자동 제출**된다(구글 심사 후 배포).
- 오래 걸리므로(빌드+업로드+폴링 30분+) 터미널을 유지하거나 `nohup ... &`로 실행 권장.

## 개별 배포

```bash
./scripts/deploy.sh android          # Android만 (AAB 빌드 + Play 업로드)
./scripts/deploy.sh ios              # iOS만 (IPA 빌드 + ASC 업로드, 심사 제출은 수동)
./scripts/deploy.sh ios --submit     # iOS + 심사 자동 제출
./scripts/deploy.sh android --apk    # AAB 외에 APK도 생성(직접 설치 테스트용)
./scripts/deploy.sh all --clean      # flutter clean 후 배포
```

### 업로드만 재시도 (빌드 재사용)

업로드 단계만 실패했을 때 재빌드 없이:

```bash
# Android — 이미 빌드된 AAB 재업로드
set -a; source scripts/config.env; set +a
PLAY_AAB_PATH=build/app/outputs/bundle/release/app-release.aab \
  scripts/.venv-play/bin/python scripts/play_upload.py

# iOS — 심사 제출만 재시도 (버전은 pubspec 기준으로 지정)
set -a; source scripts/config.env; set +a
APP_VERSION=1.2.4 BUILD_NUMBER=64 scripts/.venv-play/bin/python scripts/appstore_submit.py
```

## 버전 정책 (중요)

- 배포 시 **patch 자동 범프**가 기본(`1.2.3+63 → 1.2.4+64`). 이유(2026-07-11 사고):
  - 마케팅 버전을 안 올리면 ① 앱 업데이트 모달이 안 뜸(빌드번호는 비교에서 무시됨)
    ② iOS 업로드 거부(Error 90062 "train closed" — 승인된 버전 재사용 불가).
- 버전 유지가 꼭 필요할 때만 `--bump none` (같은 마케팅 버전 재업로드가 확실한 경우만).
- 수동 범프: `./scripts/bump_version.sh patch|minor|major|build`

## 사전 조건 (한 번 설정돼 있으면 재확인만)

| 항목 | 위치 | 용도 |
|---|---|---|
| `scripts/config.env` | gitignore됨(비밀) | 모든 자격증명. `config.env.example` 참고 |
| `android/app/key.properties` | gitignore됨 | Android 서명(키스토어) |
| `PLAY_SERVICE_ACCOUNT_JSON` | config.env에 경로 | Play 업로드 서비스계정 |
| `ASC_API_KEY_ID/ISSUER_ID/KEY_PATH` | config.env | iOS 업로드·심사 제출(App Store Connect API) |
| `AuthKey_XXXX.p8` | 프로젝트 루트(gitignore됨) | ASC API 키. **config.env의 KEY_PATH가 실제 위치와 일치해야 함** |
| `scripts/release_notes_ko.txt` | 커밋됨 | 릴리즈 노트(ko). Play 500자/스토어 반영 |

## 스토어 메타데이터만 갱신 (바이너리 없이)

```bash
fastlane play_metadata      # Google Play 등록정보
fastlane appstore_metadata  # App Store 등록정보
fastlane all_metadata       # 양쪽
# 원본: fastlane/metadata/ (제목·설명 등)
```

## 자주 겪는 문제

| 증상 | 원인/해결 |
|---|---|
| Play 업로드 99%에서 `read operation timed out` | 대용량 AAB 마지막 청크 처리 중 소켓 타임아웃. `play_upload.py`에 10분 타임아웃+재시도 반영됨(2026-07-15). 재발 시 위 "업로드만 재시도" |
| iOS `Error 90062` (train closed) | 마케팅 버전 재사용. patch 범프 후 재배포 |
| `.p8 키 없음` | config.env의 `ASC_API_KEY_PATH`가 실제 파일 위치와 다름. 프로젝트 루트의 `AuthKey_*.p8` 경로로 수정 |
| `Failed to load AuthKey file` (altool) | deploy_ios.sh가 `~/.appstoreconnect/private_keys/`로 자동 복사함 — KEY_PATH만 맞으면 해결 |
| 업데이트 모달이 안 뜸 | 마케팅 버전이 안 올라감 — `--bump none` 썼는지 확인 |

## 백엔드 배포 (별도)

`skysnap_backend/`는 **git push와 동시에 자동 배포**된다(Jenkins, profile `prod`, systemd `skysnap`).
→ 백엔드에 push하는 것 자체가 배포 행위이므로, **컴파일 확인(`./gradlew build -x test`) 없이 push 금지.**
API 계약이 바뀐 릴리즈는 **백엔드 먼저(또는 동시) 배포** — 앱은 폴백을 두는 것이 원칙.
상세: `JENKINS_SETUP.md`, `scripts/` 참고.

## 배포 후 확인

1. Play Console / App Store Connect에서 심사 상태 확인(구글 수 시간~수일, 애플 통상 1~2일).
2. 릴리즈 노트·스크립트 수정·버전 범프를 커밋/푸시(비밀 파일 제외 — gitignore가 막아줌).
3. 심사 통과 후 운영에서 핵심 변경(광고·날씨 등) 실동작 확인.
