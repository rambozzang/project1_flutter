# 🎯 SkySnap 프로젝트 (Frontend + Backend)

## 📁 프로젝트 구조

### Frontend: Flutter (현재 디렉토리)
```
~/work/app/flutter/project1/
├── lib/              # Flutter Dart 코드
├── android/          # Android 빌드
├── ios/              # iOS 빌드
├── pubspec.yaml      # Flutter 의존성
└── BUILD_GUIDE.md    # 빌드 가이드
```

### Backend: Spring Boot Java
```
~/work/app/project1/
├── src/main/java/    # Java 소스코드
├── build.gradle      # Gradle 빌드 설정
├── gradlew           # Gradle wrapper
└── README.md         # 백엔드 설명
```

**기술 스택**:
- Backend: Spring Boot 3.2.3, Java 17, MySQL
- Frontend: Flutter (Dart), Android/iOS
- 인증: Firebase Auth
- 채팅: Supabase (현재 중단)
- 데이터: Firebase Firestore (부분)

---

# 🎯 SkySnap Flutter 프로젝트 규칙

## 📋 협업 규칙

### 1. 상태 관리
- **STATE.md**: 현재 작업 상황 (매일 업데이트)
- **LOG.md**: 변경 이력 (작업마다 기록)
- **COLLABORATION.md**: 협업 절차 (참고)

### 2. 작업 흐름
```
STATE.md에서 담당 할당 
  ↓
작업 시작: LOG.md에 🟢 시작 기록
  ↓
진행 중: STATE.md에서 상태 확인 및 체크리스트 업데이트
  ↓
완료: LOG.md에 ✅ 완료 기록 + STATE.md 이동
```

### 3. 커밋 메시지 규칙
```
[상태] [담당자] 작업명 - 상세 설명

- 변경 사항
- 관련 이슈

Related to: STATE.md line XX
```

**예시**:
```
[진행] [kimi] AdMob 광고 통합 - 배너 광고 UI 추가

- google_mobile_ads 설정 완료
- 비디오 재생 화면에 배너 추가
- 테스트 광고 활성화

Related to: STATE.md AdMob 섹션
```

---

## 🛠️ 개발 환경

### 언어 및 스타일
- **Dart/Flutter**: 최신 버전 (3.5.3+)
- **val 선호**: var 최소화
- **한글 주석**: 명확히
- **코드 포맷**: `flutter format`

### 필수 패키지
```yaml
- firebase_auth, firebase_core
- google_mobile_ads (광고)
- in_app_purchase (결제)
- dio (네트워크)
- video_player
```

---

## ✅ 코드 변경 전 체크리스트

- [ ] STATE.md에서 작업 확인
- [ ] LOG.md에 시작 기록
- [ ] 기존 패턴 확인 후 동일하게 따르기
- [ ] 빌드/테스트 검증
  ```bash
  flutter clean
  flutter pub get
  flutter build apk --debug  # Android
  flutter build ios --debug  # iOS
  ```
- [ ] 에러 발생 시 원인과 해결방법 기록

---

## 📝 주요 이슈

### Cellular 네트워크 크래시
- **상태**: 진행 중 (kimi)
- **원인**: WiFi vs Cellular 네트워크 타임아웃/SSL 인증
- **추적**: STATE.md → LOG.md

### 수익화 기능
- **AdMob**: 설계 단계
- **프리미엄 구독**: 예정
- **창작자 수익분배**: 이후 단계

---

## 🔗 중요 파일

| 파일 | 목적 |
|------|------|
| STATE.md | 현재 진행 상황 + 체크리스트 |
| LOG.md | 변경 이력 (시간순) |
| COLLABORATION.md | 협업 절차 상세 |
| pubspec.yaml | 의존성 관리 |
| android/build.gradle | Android 빌드 설정 |
| ios/Podfile | iOS 의존성 |

---

## 🎓 작업 시작 (체크리스트)

1. **상태 확인**
   ```bash
   cat STATE.md  # 현재 작업 보기
   ```

2. **담당 할당 요청** (리드에게)
   ```
   상태: 진행 중
   담당: [에이전트명]
   ```

3. **작업 시작 기록**
   ```
   ### HH:MM | [담당자] | 🟢 시작
   ```

4. **코드 작성** (기존 패턴 따르기)

5. **테스트**
   ```bash
   flutter test
   flutter run --debug
   ```

6. **완료 기록**
   ```
   ### HH:MM | [담당자] | ✅ 완료
   ```

---

## 📞 막힘 상황

상태를 🔴 막힘으로 변경:
```markdown
### [작업명]
- 상태: 🔴 막힘
- 문제: [구체적 설명]
- 필요: [도움 요청]
```

LOG.md에도 기록:
```markdown
### 10:45 | kimi | 🔴 막힘
**작업**: Cellular 버그
- 원인: SSL 인증서 검증 실패
- 필요한 도움: 네트워크 로그

**로그**: Blocked by SSL certificate validation.
```

---

## 🚀 배포 전 체크리스트

- [ ] STATE.md 모든 항목 완료
- [ ] LOG.md 최신 업데이트
- [ ] 테스트 완료 (Android + iOS)
- [ ] 코드 리뷰 통과
- [ ] 커밋 메시지 규칙 준수
- [ ] git push 전 STATE.md 최종 확인

---

## 🔄 주간 동기화 (매주 월요일)

```markdown
## 주간 요약

### ✅ 완료 (X개)
- 작업 1
- 작업 2

### 🔵 진행 중 (Y개)
- 작업 3
- 작업 4

### 🔴 막힘 (Z개)
- 작업 5

### 다음주 우선순위
1. ...
2. ...
```

---

## 📌 협업 팀원

| 이름 | 역할 | 예시 |
|------|------|------|
| kimi | Flutter/Android 핵심 | 빌드, 핵심 기능 |
| glm | UI/UX, 기능 구현 | 화면 디자인, 기능 추가 |
| 기타 | (정의 예정) | - |

---

**마지막 갱신**: 2026-06-24  
**담당**: kimi
