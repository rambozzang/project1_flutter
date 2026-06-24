# 🚀 SkySnap 앱 출시 완벽 가이드

**목표**: Google Play Store & Apple App Store에 앱 배포  
**예상 시간**: 16-20시간 (심사 대기 포함 3-7일)  
**우선순위**: 🔴 가장 높음

---

## 📋 전체 체크리스트

```
총 5단계:
1️⃣  출시 전 검토 (2시간)
2️⃣  Android 배포 (8시간)
3️⃣  iOS 배포 (10시간)
4️⃣  심사 제출 (1시간)
5️⃣  라이브 배포 (자동)
```

---

## 1️⃣ 출시 전 검토 (2시간)

### A. 앱 정보 최종화

```bash
# pubspec.yaml 확인
cat pubspec.yaml | grep -A 2 "name:\|version:"
# 현재: version: 1.0.21+46
```

**필수 확인 사항**:
- [ ] 버전 번호 최종 확정 (1.0.21 = 공개 버전, 46 = 빌드 번호)
- [ ] 앱 이름: SkySnap (pubspec.yaml에서 "name: project1"로 되어 있음 → 수정 필요)
- [ ] 앱 설명: 영문/한문 버전
- [ ] 스크린샷: Android (최소 2장), iOS (최소 2장)
- [ ] 앱 아이콘: 1024x1024px PNG
- [ ] 개인정보처리방침 (Privacy Policy) URL
- [ ] 서비스약관 (Terms of Service) URL

### B. 앱 검증

```bash
# 1. 빌드 성공 확인
flutter clean
flutter pub get

# 2. Android 빌드 테스트
flutter build apk --release
# 결과: build/app/outputs/flutter-apk/app-release.apk

# 3. iOS 빌드 테스트
flutter build ios --release
# 결과: build/ios/iphoneos/Runner.app

# 4. 기능 테스트 (실제 디바이스)
flutter run --release
```

### C. 보안 검토

```bash
# 1. 민감한 정보 확인
grep -r "api_key\|token\|secret" --include="*.dart"
# ❌ 하드코딩된 키가 있으면 제거

# 2. 권한 확인
cat android/app/src/main/AndroidManifest.xml | grep permission
cat ios/Runner/Info.plist | grep Privacy
# 필요한 권한만 유지

# 3. Firebase 설정 확인
grep -r "firebase\|google" pubspec.yaml
# 프로덕션 키 사용 확인
```

---

## 2️⃣ Android 배포 (8시간)

### 단계 1: Google Play Console 계정 준비 (30분)

```
1. https://play.google.com/console 접속
2. 개발자 계정 생성 ($25 일회비)
3. 결제 정보 등록
4. "새 앱 만들기" 클릭
```

**입력 사항**:
- 앱 이름: SkySnap
- 기본 언어: 한국어 (또는 영어)
- 앱 유형: 무료 또는 유료
- 카테고리: 비디오, 소셜

### 단계 2: 서명 키(Keystore) 생성 (1시간)

```bash
# 1. 서명 키 생성 (처음 한 번만)
keytool -genkey -v -keystore ~/skysnap_key.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias skysnap_key \
  -storetype JKS

# 입력 정보:
# - 키스토어 암호: [강력한 암호]
# - 별칭 암호: [동일]
# - 이름: [당신의 이름]
# - 회사: [회사명]
# - 도시: Seoul
# - 주: Seoul
# - 국가: KR
```

**주의**: 이 파일은 **절대 잃어버리면 안 됨** → 안전한 곳에 백업

```bash
# 2. Android 프로젝트에 등록
cd android
```

`android/key.properties` 파일 생성:
```properties
storePassword=[keystore 암호]
keyPassword=[키 암호]
keyAlias=skysnap_key
storeFile=/Users/bumkyuchun/skysnap_key.jks
```

`android/app/build.gradle` 수정:
```gradle
// 파일 상단에 추가
def keystoreProperties = new Properties()
def keystorePropertiesFile = rootProject.file('key.properties')
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}

android {
    ...
    signingConfigs {
        release {
            keyAlias keystoreProperties['keyAlias']
            keyPassword keystoreProperties['keyPassword']
            storeFile keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
            storePassword keystoreProperties['storePassword']
        }
    }
    
    buildTypes {
        release {
            signingConfig signingConfigs.release
        }
    }
}
```

### 단계 3: Release APK 빌드 (2시간)

```bash
# 1. 앱 ID 확인
cat android/app/build.gradle | grep "applicationId"
# 보통: "com.example.project1" → "com.codelabtiger.skysnap"으로 변경 권장

# 2. Release APK 빌드
flutter clean
flutter pub get
flutter build apk --release

# 결과: build/app/outputs/flutter-apk/app-release.apk
# 크기 확인: 약 50-150MB
```

### 단계 4: Google Play Console에 업로드 (3시간)

**경로**: Google Play Console → SkySnap → 출시 → 프로덕션

```
1. "새 출시 만들기" 클릭
2. APK 파일 업로드
   - build/app/outputs/flutter-apk/app-release.apk
3. 앱 정보 입력:
   - 출시 이름: v1.0.21
   - 출시 노트: 
     "초기 출시: 비디오 스트리밍 플랫폼"
4. 앱 아이콘 업로드 (1024x1024px)
5. 스크린샷 업로드 (최소 2장, 최대 8장)
   - 권장 크기: 1440x2560px
6. 앱 설명 작성
7. 개인정보처리방침 URL 입력
8. 콘텐츠 등급 작성
   - 부정적 콘텐츠 없음 (보통)
9. 대상 연령 선택: 4+ 또는 12+
10. 심사용 계정 정보 제공 (필요시)
    - 이메일: rambo.zzang@gmail.com
    - 비밀번호: [테스트 계정]
```

---

## 3️⃣ iOS 배포 (10시간)

### 단계 1: Apple Developer 계정 준비 (30분)

```
1. https://developer.apple.com 접속
2. Apple ID로 로그인
3. 개발자 계정 등록 ($99/년)
4. 결제 정보 등록
5. 앱 ID 생성
```

### 단계 2: 인증서 생성 (2시간)

```bash
# 1. Xcode에서 자동 생성 (권장)
open ios/Runner.xcworkspace

# 2. Runner 프로젝트 선택
# 3. Signing & Capabilities 탭
# 4. "Automatically manage signing" 체크
# 5. Team 선택 (Apple ID 팀)
# 6. Bundle Identifier 설정: com.codelabtiger.skysnap
```

### 단계 3: 프로비저닝 프로필 생성 (1시간)

```
Xcode에서 자동 생성됨
- Development Profile (테스트용)
- Distribution Profile (배포용)
```

### 단계 4: App Store Connect 설정 (2시간)

```
1. https://appstoreconnect.apple.com 접속
2. "내 앱" → "새 앱"
3. 정보 입력:
   - 앱 이름: SkySnap
   - Bundle ID: com.codelabtiger.skysnap
   - SKU: skysnap_2026
   - 플랫폼: iOS
```

### 단계 5: 앱 정보 작성 (2시간)

**필수 입력**:
- 한국어 설명
- 영어 설명
- 스크린샷 (5개, 크기: 1290x2796px)
- 앱 프리뷰 (선택)
- 키워드 (최대 100자)
- 지원 URL
- 개인정보처리방침 URL

### 단계 6: Release IPA 빌드 (2시간)

```bash
# 1. Flutter 빌드
flutter build ios --release

# 2. Xcode에서 Archive
open ios/Runner.xcworkspace
# Product → Archive → Release

# 3. App Store Connect에 업로드
# Xcode: Window → Organizer → Archives → Upload to App Store

# 또는 Transporter 사용:
# https://apps.apple.com/app/transporter/id1450874784
```

### 단계 7: TestFlight 테스트 (1시간)

```
App Store Connect → TestFlight
1. Internal Testing 사용자 추가
2. 빌드 검토 대기 (약 1시간)
3. 테스트 기기에서 테스트
4. 버그 없음 확인
```

---

## 4️⃣ 심사 제출 (1시간)

### Android 심사 제출

```
Google Play Console → 출시 → 프로덕션
1. "검토를 위해 제출" 클릭
2. 정책 확인:
   - [ ] 개인정보처리방침 정책 준수
   - [ ] 콘텐츠 정책 준수
   - [ ] 광고 정책 준수
3. 제출 버튼
```

**심사 기간**: 보통 2-4시간 (긴급: 24시간 이내)

### iOS 심사 제출

```
App Store Connect → 앱 심사 제출
1. 빌드 선택
2. "심사 제출" 클릭
3. 정책 확인
4. 제출 버튼
```

**심사 기간**: 보통 1-2일 (가속심사 가능)

---

## 5️⃣ 라이브 배포 (자동)

### Android
```
심사 통과 → 자동 프로덕션 배포
예상 시간: 2-4시간
```

### iOS
```
심사 통과 → 개발자가 "릴리스" 버튼 클릭
설정: 자동 배포 또는 수동 배포
```

---

## 📋 최종 체크리스트

### 📱 공통

- [ ] 앱 버전: 1.0.21+46
- [ ] 앱 이름: SkySnap
- [ ] 앱 설명: 100글자 이상
- [ ] 앱 아이콘: 1024x1024px
- [ ] 스크린샷: 최소 2장 (각 플랫폼)
- [ ] 개인정보처리방침 URL
- [ ] 서비스약관 URL
- [ ] 버그/크래시 없음 (실제 디바이스 테스트)

### 🤖 Android

- [ ] Google Play Console 계정 생성
- [ ] 서명 키(keystore) 생성 및 백업
- [ ] key.properties 설정
- [ ] Release APK 빌드 성공
- [ ] 심사용 계정 정보 제공 (필요시)

### 🍎 iOS

- [ ] Apple Developer 계정 ($99/년)
- [ ] Bundle ID: com.codelabtiger.skysnap
- [ ] 인증서 생성 및 프로비저닝 프로필
- [ ] App Store Connect 앱 생성
- [ ] Release IPA 빌드 성공
- [ ] TestFlight 테스트 완료

---

## 🔥 트러블슈팅

### Android
| 문제 | 해결 |
|------|------|
| "서명 키 오류" | key.properties 경로 확인 |
| "빌드 실패" | `flutter clean` + `flutter pub get` |
| "심사 거절" | 개인정보처리방침 URL 재확인 |

### iOS
| 문제 | 해결 |
|------|------|
| "인증서 없음" | Xcode 자동 signing 활성화 |
| "Bundle ID 오류" | App Store Connect 앱 ID와 일치 확인 |
| "심사 거절" | TestFlight 테스트 결과 제출 |

---

## 💾 중요 파일 백업

```bash
# 반드시 백업할 파일
1. ~/skysnap_key.jks (Android 서명 키)
2. ios/Runner.xcodeproj/project.pbxproj (iOS 설정)
3. LAUNCH_GUIDE.md (이 파일)

# 명령어
mkdir -p ~/backups/skysnap
cp ~/skysnap_key.jks ~/backups/skysnap/
cp -r ios/Runner.xcodeproj ~/backups/skysnap/
```

---

## 📊 예상 비용

| 항목 | 비용 | 기간 |
|------|------|------|
| Google Play Developer | $25 | 일회 |
| Apple Developer Program | $99 | 년간 |
| **총액** | **$124** | **1년** |

---

## 🎯 예상 일정

```
Day 1: 출시 전 검토 + Android 배포
Day 2: iOS 배포
Day 3: 심사 제출
Day 4-5: Android 심사 (보통 통과)
Day 5-7: iOS 심사 (1-2일)
Day 7: 라이브 배포 완료 🎉
```

---

## 📞 다음 단계

1. ✅ **지금**: STATE.md 업데이트
   ```markdown
   상태: 🟢 시작
   담당: kimi
   ```

2. **1시간 내**: 출시 전 검토 완료
   ```bash
   flutter build apk --release
   flutter build ios --release
   ```

3. **오늘**: Android 배포 시작
   - Google Play Console 계정 생성
   - 서명 키 생성

4. **내일**: iOS 배포 시작
   - Apple Developer 계정 확인
   - App Store Connect 설정

5. **3일 후**: 심사 제출 완료

---

**문서 작성**: 2026-06-24  
**담당**: kimi  
**상태**: 진행 중
