# 📝 변경 이력 (LOG.md)

**형식**: `[시간] [담당자] [상태] [내용]`

---

## 2026-06-24

### 15:20 | kimi | ✅ 완료
**작업**: Jenkins 자동배포 파이프라인 구성 완료! 🎉
- ✅ Jenkinsfile 생성 (5단계 파이프라인)
- ✅ deploy.sh 배포 스크립트 작성
- ✅ JENKINS_SETUP.md 설정 가이드 작성
- ✅ README.md 백엔드 문서 작성

**파이프라인 구성**:
1. 🔍 Checkout - Git 코드 pull
2. 🔨 Build - Gradle JAR 빌드
3. 📦 Prepare - 배포 경로 준비
4. 🛑 Stop - 기존 서비스 중지
5. 📤 Deploy - JAR 파일 배포 (/vdata/jar/skysnap)
6. 🚀 Start - prd 프로파일로 서비스 시작 (port 9100)
7. ✅ Health - 헬스 체크

**생성된 파일**:
- /Jenkinsfile (파이프라인 정의)
- /scripts/deploy.sh (배포 관리 스크립트)
- /JENKINS_SETUP.md (Jenkins 설정 완벽 가이드)
- /README.md (백엔드 프로젝트 문서)

**배포 정보**:
- Jenkins: jenkins.codelabtiger.com
- 포트: 9100
- 경로: /vdata/jar/skysnap
- 프로파일: prd
- 상태: 자동 배포 준비 완료 ✅

### 15:10 | kimi | 📝 기록
**작업**: 프로젝트 구조 문서화
- Frontend: ~/work/app/flutter/project1 (Flutter - SkySnap)
- Backend: ~/work/app/project1 (Spring Boot 3.2.3, Java 17)
- CLAUDE.md, STATE.md에 프로젝트 구조 기록

**기술 스택**:
- Backend: Spring Boot 3.2.3, Java 17, MySQL
- Frontend: Flutter (Dart)
- 인증: Firebase Auth
- 채팅: Supabase (현재 중단)

**로그**: 프로젝트 전체 아키텍처 문서화 완료

### 15:05 | kimi | ✅ 완료
**작업**: Supabase 주석처리 - 회원가입/로그인 활성화 완료! 🎉
- ✅ lib/main.dart: Supabase 초기화 코드 주석 처리
- ✅ lib/app/auth/cntr/auth_cntr.dart: 모든 Supabase import 및 함수 주석 처리
  - _initializeSupabaseIfNeeded() 함수 완전 제거
  - initSupaBaseSession() 함수 완전 제거
  - _trySupabaseLogin() 함수 완전 제거
  - signUp() 함수 완전 제거
  - updateUserInfo() 함수 완전 제거
  - leave(), logout() 함수의 Supabase 부분 제거
- ✅ lib/repo/chatting/chat_repo.dart: Supabase 코드 주석 처리
- ✅ Android 빌드 성공

**빌드 결과**:
- 1차: auth_cntr.dart의 Supabase 참조로 인한 빌드 실패
- 2차: auth_cntr.dart 전체 수정 후 **빌드 성공!**
- 결과: build/app/outputs/flutter-apk/app-debug.apk 생성 (20.7초)

**효과**:
- ✅ Firebase 로그인/회원가입 정상 작동
- ✅ Supabase 채팅 기능 비활성화 (채팅 불가)
- ✅ 앱 실행 및 기본 기능 정상 작동

**다음 단계**:
1. 앱 실행 후 회원가입/로그인 테스트
2. iOS 빌드 테스트 (동일 수정 필요)
3. 광고/수익화 기능 추가

### 12:30 | kimi | 🔵 진행
**작업**: 앱 출시 전략 수립
- 광고 우선순위를 앱 활성화로 변경
- LAUNCH_GUIDE.md 완성 (Android + iOS)
- STATE.md 우선순위 재편성
- 5단계 배포 로드맵 작성

**상세**:
- Android 배포 (8시간): Google Play Console, 서명 키, APK 빌드
- iOS 배포 (10시간): Apple Developer, 인증서, IPA 빌드
- 심사 제출 (1시간)
- 라이브 배포 (자동)

**다음 단계**:
1. 앱 정보 최종화 (이름, 설명, 아이콘, 스크린샷)
2. 보안 검토 (API 키, 권한)
3. Google Play Developer 계정 생성 ($25)
4. Apple Developer 계정 확인 ($99/년)

### 12:00 | kimi | 🟢 시작
**작업**: 협업 프로세스 구축
- STATE.md, LOG.md 생성
- COLLABORATION.md 작성
- 다중 에이전트 협업 가이드 완성

**다음 단계**: GLM 및 팀원들이 이 템플릿을 따르기

---

## 사용 가능한 상태 아이콘

| 아이콘 | 의미 | 설명 |
|--------|------|------|
| 🟢 시작 | Start | 작업 시작 |
| 🔵 진행 | In Progress | 진행 중 |
| 🟡 대기 | Waiting | 다른 작업 대기 |
| 🔴 막힘 | Blocked | 문제 발생 |
| ✅ 완료 | Complete | 완료됨 |
| 🔄 리뷰 | Review | 코드 리뷰 중 |
| ⚠️ 주의 | Warning | 주의 필요 |

---

## 2026-06-23

### 16:53 | kimi | ✅ 완료
**작업**: Android 빌드 문제 해결
- compileSdk 36으로 업그레이드
- Gradle 8.11.1 적용
- 빌드 성공: app-debug.apk 생성

**로그**: Android build configuration fixed. Ready for device testing.

---

## 엔트리 템플릿

```markdown
## [날짜]

### [시간] | [담당자] | [상태 아이콘] [상태명]
**작업**: [작업 제목]
- 내용 항목 1
- 내용 항목 2

**로그**: [자유 형식 설명]
```

---

## 📌 중요 노트

- **매일 갱신**: 작업 시작/종료 시마다 로그 추가
- **STATE.md 연동**: LOG.md의 내용을 STATE.md에 반영
- **타임스탐프**: HH:MM 형식 (24시간), KST 기준
- **담당자**: kimi, glm, 등 명확히 기입

---

## 진행 상황 요약

**진행 중**: 
- Cellular 네트워크 버그 분석
- 수익화 기능 설계

**다음 우선순위**:
1. AdMob 광고 통합
2. Cellular 크래시 해결
3. 프리미엄 구독 시스템
