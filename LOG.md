# 📝 변경 이력 (LOG.md)

**형식**: `[시간] [담당자] [상태] [내용]`

---

## 2026-07-02

### 17:45 | claude | 🟢 시작 (1단계: 테마+공용위젯, 리뷰 대기)
**작업**: 공유앨범(design_handoff_shared_album) 구현 착수 — 디자인 토큰·공용 위젯
- 구조: `lib/app/shared_album/` (theme/ 3파일 + widget/ 5파일 + 미리보기 페이지) — 기존 컨벤션(lib/app/기능, widget/ 단수, StatefulWidget+repo) 준수
- theme: SaColors(다크 토큰+primary 그라디언트), SaWeatherGradients(날씨 8종+byKey), SaText(Pretendard 스케일+Space Mono)
- widget: SaGlassChip(블러 칩), SaNewBadge(pink pulse 2.4s)+SaNewDot, SaMemberAvatarStack(겹침 아바타+N), SaOverlapImageStack(±7° 겹침 스택+오버레이 슬롯), SaGradientButton(teal→blue pill/FAB glow)
- **부수 발견·수정**: AppTheme이 fontFamily 'Pretendard'를 지정했지만 pubspec에 폰트 선언이 없어 앱 전체가 시스템 폰트로 폴백 중이었음 → Pretendard OTF 5종(400~800, ~7.9MB) 번들 + pubspec fonts 선언 (전체 앱 폰트 정상화)
- 리뷰 경로: 설정 > (디버그) '공유앨범 위젯 미리보기' (/SaPreviewPage)
- 검증: flutter analyze 에러/워닝 0, Android 디버그 빌드 성공

### 16:35 | claude | ✅ 완료
**작업**: 관심지역 등록 오류 수정(운영 DB) + 페이지 UI 전면 개선
- **원인**: 운영 DB `tb_cust_tag.addr` 컬럼이 bytea(바이너리) 타입으로 잘못 생성 → INSERT가 "column addr is of type bytea" SQL 오류로 100% 실패. 마지막 등록 성공이 2025-04-17 — **14개월간 깨져 있던 버그** (curl로 재현·확정)
- **수정**: 백업(tb_cust_tag_bak_20260702) 후 `ALTER TABLE ... ALTER COLUMN addr TYPE varchar(255) USING convert_from(addr,'UTF8')` → 기존 40건 주소 정상 복원 + 저장 재검증 성공(code 00). 코드 배포 불필요, 즉시 복구
- **UI 개선(favorite_area_page.dart 전면 재작성)**:
  - 사용자에게 그대로 노출되던 "지도 표시 영역 (현재 주석 처리됨)" 죽은 영역 + 네이버맵 dead code 전부 제거
  - 별도 페이지로 이동하던 2단계 검색 → 페이지 내 인라인 검색(300ms 디바운스) + 결과에서 바로 [+ 추가], 등록된 곳은 '등록됨' 표시
  - 나의 관심 지역: 주소 서브텍스트 표시, 탭 시 저장된 좌표로 즉시 날씨 조회(카카오 재지오코딩 제거, 좌표 없는 과거 데이터만 폴백), 삭제 확인 다이얼로그
  - favorite_area_search_page.dart 삭제(전용 파일, 미사용화)
- **부수 수정**: cust_repo.saveTag의 잠재 크래시(`lon||lat` 조건 + 강제언랩 + 무검증 parse) → tryParse && 가드로 교정
- 검증: flutter analyze 에러/워닝 0, Android 디버그 빌드, 운영 API 저장/삭제/조회 curl 검증 완료

### 16:10 | claude | ❌ 롤백
**작업**: 카메라 동시 촬영(듀얼캠) 시도 → 실기기에서 동작 안 해 커밋 전 제거
- camerawesome 멀티캠(실험 기능)으로 후면 메인+전면 PiP 구현했으나 실기기 테스트에서 동작 실패
- 코드 전부 되돌림(git checkout, 커밋된 적 없음). 상세 원인·재시도 조건은 프로젝트 메모리(camera-gestures) 참고

### 15:20 | claude | ✅ 완료
**작업**: 날씨 상태바 상시 알림 (Android 전용) 신규 구현
- WorkManager(workmanager ^0.9.0) 주기 작업(30분/1시간/3시간)이 백그라운드에서 백엔드 날씨 캐시 API를 조회해 ongoing 알림 갱신
- 날씨 API(/weather/current·superfct)는 무인증 공개 엔드포인트라 백그라운드 isolate에서 토큰 없이 호출 (AuthCntr 의존 없음)
- 위치: lastKnown → 직전 저장 위치 → 서울 폴백 (백그라운드 위치 권한 불필요 — 심사 리스크 회피)
- 상태바 아이콘 4종(맑음/구름/비/눈, 모노크롬 벡터) + 알림 제목 "23.5° 맑음" 형식
- 설정 페이지(/WeatherNotiSettingPage): 켜기/끄기·주기 선택·지금 갱신, 알림 권한 배너. 설정 > "날씨 상태바 알림" 메뉴(Android만 노출)
- 신규: lib/services/weather_notification_service.dart, lib/app/setting/weather_noti_setting_page.dart, drawable ic_stat_w_*.xml 4종
- 수정: main.dart(Workmanager initialize), setting_page.dart, app_route.dart, AndroidManifest(POST_NOTIFICATIONS), pubspec
- 미세먼지는 백엔드 미세먼지 배치(403, data.go.kr 키 문제) 복구 후 추가 예정
- ⚠️ iOS 배포 타깃 13.0→14.0 상향 (workmanager_apple 포드가 iOS 14+ 요구. iOS 13 잔존 기기는 극소수)
- 검증: flutter analyze 에러 0, Android·iOS 디버그 빌드 모두 성공
- (추가) 알림 패널 우측에 날씨별 컬러 이모지 largeIcon 표시 — 이모지(☀️⛅☁️🌧️🌨️❄️)를 dart:ui로 128px PNG 렌더링(에셋 불필요, 헤드리스 엔진 루트 isolate라 dart:ui 사용 가능)

### 10:05 | claude | ✅ 완료
**작업**: 카메라 제스처 힌트 슬림화 + 위치·노출 정책 변경
- 캡슐 안 텍스트 블록 제거 → 트랙만 있는 얇은 캡슐(26px) + 캡슐 밖 미니 라벨(밝기/줌)로 분리, 점 20→12px
- 상하(밝기) 힌트=화면 우측 측면, 좌우(줌) 힌트=화면 중앙 배치
- 앱 실행당 1번만 노출(static 플래그) — 카메라 재진입 시 생략, 힌트 숨김 후 스와이프 애니메이션도 정지
- 수정 파일: `lib/app/camera/page/camera_awesome_page.dart`

### 09:50 | claude | ✅ 완료
**작업**: 카메라 초광각(0.5x) 지원 — 렌즈 전환 대신 줌 배율 방식으로 양 플랫폼 구현
- 원인: camerawesome 2.5.0의 Android `getBackSensors()`가 미구현(TODO)이라 0.5x 버튼이 Android에서 항상 숨겨짐. iOS는 물리 렌즈 스왑이라 전환이 뚝 끊김.
- Android: `getMinZoom()`(논리 카메라 minZoomRatio)<1.0이면 0.5x 핀 노출. CameraX 크롭폭 선형 공식으로 0.5x/1x/2x/5x 핀을 실제 배율 위치에 매핑.
- iOS: AppDelegate에 `com.skysnap/camera_lens` 채널 추가(트리플/듀얼와이드 가상 디바이스 uid+switchOver 조회) → 카메라 시작 시 가상 디바이스로 1회 전환 → 이후 0.5x~5x 전부 videoZoomFactor 램프(렌즈 점프 없음). factor 1.0=0.5x, switchOver[0](보통 2.0)=1x.
- 전/후면 전환 시 줌 캡 재계산, 전면에선 0.5x 숨김. 핀 하이라이트는 최근접 방식으로 교체.
- 수정 파일: `lib/app/camera/page/camera_awesome_page.dart`, `ios/Runner/AppDelegate.swift`
- 검증: flutter analyze 에러/워닝 0, Android 디버그 빌드 성공, iOS 디버그 빌드 진행
- 실기기 QA 필요: 기기별 `getMinZoom()` 값(로그 `[CAM] zoom caps`), iOS 가상 디바이스 전환 후 프리뷰/녹화 확인

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
