# 🚀 SkySnap 자동배포 스크립트

Flutter 앱(Android/iOS)을 한 번의 명령으로 빌드·배포합니다.

```
scripts/
├── deploy.sh            통합 진입점 (android | ios | all)
├── deploy_android.sh    Android AAB/APK 빌드
├── deploy_ios.sh        iOS IPA 빌드 + TestFlight 업로드
├── bump_version.sh      pubspec 버전/빌드번호 증가
├── config.env.example   시크릿 템플릿 (복사해서 config.env 작성)
└── README.md            이 문서
```

---

## 1. 최초 1회 설정

### (1) 시크릿 파일 작성
```bash
cp scripts/config.env.example scripts/config.env
# scripts/config.env 를 열어 실제 값 입력 (이 파일은 git에 안 올라감)
```

### (2) Android 서명 키 준비
키스토어(.jks)가 없다면 한 번만 생성:
```bash
keytool -genkey -v -keystore ~/keys/skysnap.jks \
  -keyalg RSA -keysize 2048 -validity 10000 -alias skysnap
```
→ 경로/암호/별칭을 `config.env` 의 `ANDROID_*` 에 입력.
스크립트가 이 값으로 `android/app/key.properties` 를 **자동 생성**합니다.

### (3) iOS 자격증명
- **권장**: App Store Connect → 사용자/액세스 → 통합(API 키)에서 키 발급
  → `ASC_API_KEY_ID`, `ASC_API_ISSUER_ID`, `ASC_API_KEY_PATH` 입력
- **간단**: Apple ID + 앱 전용 암호(appleid.apple.com → 로그인 및 보안)
  → `APPLE_ID`, `APPLE_APP_PASSWORD` 입력
- Xcode 에서 Runner 자동 서명(Automatically manage signing)이 설정돼 있어야 함.

### (4) 실행 권한
```bash
chmod +x scripts/*.sh
```

---

## 2. 사용법

```bash
# 안드로이드 + iOS 모두 배포 (빌드번호 +1, 클린 빌드)
./scripts/deploy.sh all --bump build --clean

# 안드로이드만 (APK도 같이)
./scripts/deploy.sh android --apk

# iOS만, TestFlight 업로드까지
./scripts/deploy.sh ios

# iOS 빌드만 (업로드 생략)
./scripts/deploy.sh ios --no-upload

# 버전만 올리기
./scripts/bump_version.sh build    # 1.0.21+46 → 1.0.21+47
./scripts/bump_version.sh patch    # 1.0.21+46 → 1.0.22+47
```

### 옵션 요약
| 옵션 | 설명 |
|------|------|
| `--bump build/patch/minor/major` | 배포 전 버전 증가 (스토어는 매 업로드마다 빌드번호 상승 필요) |
| `--clean` | `flutter clean` 후 빌드 |
| `--apk` | (Android) AAB 외 APK도 생성 |
| `--no-upload` | (iOS) IPA만 만들고 업로드 생략 |

---

## 3. 산출물 경로

| 플랫폼 | 파일 | 용도 |
|--------|------|------|
| Android | `build/app/outputs/bundle/release/app-release.aab` | Google Play 제출 |
| Android | `build/app/outputs/flutter-apk/app-release.apk` | 직접 설치/테스트 |
| iOS | `build/ios/ipa/*.ipa` | TestFlight/App Store |

---

## 4. (선택) 완전 자동 스토어 업로드 — fastlane

현재 Android는 AAB 생성까지, iOS는 TestFlight 업로드까지 자동입니다.
Google Play 업로드까지 자동화하려면 fastlane `supply` 를 권장:

```bash
gem install fastlane
cd android && fastlane supply init   # Play Console 서비스계정 JSON 필요
# fastlane supply --aab build/app/outputs/bundle/release/app-release.aab --track internal
```

---

## ⚠️ 보안 주의
- `scripts/config.env`, `android/app/key.properties`, `*.jks`, `*.p8` 는 **절대 커밋 금지** (`.gitignore` 등록됨).
- 키스토어(.jks)를 분실하면 앱 업데이트가 불가능합니다 → 안전한 곳에 백업.
