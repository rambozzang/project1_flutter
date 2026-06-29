# SkySnap 활성화 MVP 기획안

## 목표
- 사용자가 매일 앱을 켜는 습관 형성
- 날씨 영상 UGC(사용자 생성 콘텐츠) 증가
- 지역 기반 참여 유도

## MVP 범위 (1차)
1. **출석 체크**: 앱 실행 시 매일 출석 기록
2. **데일리 챌린지**: "오늘 내 동네 날씨 인증하기" 챌린지
   - 날씨 영상 업로드 완료 시 자동 챌린지 완료 처리
3. **연속 출석 보상**: 3일/7일/30일 연속 출석 배지
4. **챌린지 리마인드 푸시**: 미완료 사용자에게 오후 6시 FCM 푸시

## MVP 범위 외 (2차)
- 지역 랭킹 (시도/시군구별)
- 포인트 상점
- 친구 초대 보상

## 백엔드 설계

### 신규 테이블

#### TB_CHALLENGE_MASTER
| 컬럼 | 타입 | 설명 |
|------|------|------|
| CHALLENGE_ID | BIGINT PK | 챌린지 ID |
| CHALLENGE_NM | VARCHAR(100) | 챌린지명 |
| CHALLENGE_DESC | VARCHAR(500) | 설명 |
| START_DATE | DATE | 시작일 |
| END_DATE | DATE | 종료일 |
| TYPE_CD | VARCHAR(4) | 유형(DAILY, WEEKLY) |
| TARGET_CD | VARCHAR(4) | 대상(UPLOAD, LOGIN, SHARE) |
| REWARD_DESC | VARCHAR(200) | 보상 설명 |
| USE_YN | CHAR(1) | 사용여부 |
| CRT_DTM | DATETIME | 생성일 |
| CRT_CUST_ID | VARCHAR(100) | 생성자 |

#### TB_CHALLENGE_PARTICIPANT
| 컬럼 | 타입 | 설명 |
|------|------|------|
| PARTICIPANT_ID | BIGINT PK | 참여 ID |
| CHALLENGE_ID | BIGINT FK | 챌린지 ID |
| CUST_ID | VARCHAR(100) | 사용자 ID |
| CHALLENGE_DATE | DATE | 챌린지 일자 |
| COMPLETE_YN | CHAR(1) | 완료여부 |
| COMPLETE_DTM | DATETIME | 완료일시 |
| CRT_DTM | DATETIME | 생성일 |

#### TB_ATTENDANCE
| 컬럼 | 타입 | 설명 |
|------|------|------|
| ATTENDANCE_ID | BIGINT PK | 출석 ID |
| CUST_ID | VARCHAR(100) | 사용자 ID |
| ATTENDANCE_DATE | DATE | 출석일 |
| ATTENDANCE_TYPE | VARCHAR(4) | 유형(APP_OPEN, UPLOAD) |
| CRT_DTM | DATETIME | 생성일 |

### API 목록

| Method | URL | 설명 |
|--------|-----|------|
| GET | /challenge/today | 오늘의 챌린지 조회 |
| POST | /challenge/complete | 챌린지 완료 처리 |
| GET | /challenge/me | 내 챌린지 현황 조회 |
| POST | /attendance/check | 출석 체크 |
| GET | /attendance/me | 내 출석 이력/연속일 조회 |

### 푸시 알림
- 스케줄러: 매일 18:00 실행
- 대상: 오늘 챌린지 미완료 + FCM ID 존재 + 알림 수신 동의 사용자
- 메시지: "오늘 챌린지 아직 안 했어요! 내 동네 날씨 인증하고 보상 받기"

## Flutter 설계

### 신규 화면
1. **ChallengeMainPage**: 챌린지 메인 (오늘 챌린지, 출석 캘린더, 보상)
2. **AttendanceCalendarPage**: 출석 달력 상세

### 수정 화면
1. **VideoListPage / RootPage**: 상단에 "오늘 챌린지" 배너 추가
2. **영상 업로드 완료 후**: 챌린지 완료 축하 팝업

### 신규 Repository
- `ChallengeRepo`: 챌린지 API
- `AttendanceRepo`: 출석 API

### Controller
- `ChallengeCntr`: 챌린지 상태 관리
- `AttendanceCntr`: 출석 상태 관리

## 구현 순서
1. 백엔드 Entity/Repository/Service/Controller
2. Flutter Repository/Data/Controller
3. Flutter UI (챌린지 메인, 출석 캘린더)
4. 업로드 완료 시 챌린지 완료 API 연동
5. 앱 실행 시 출석 체크 API 연동
6. 백엔드 푸시 스케줄러
7. 테스트

## 기대 효과
- DAU 상승 (출석 체크 + 리마인드 푸시)
- 일일 업로드 수 증가 (챌린지 유도)
- 사용자 참여 지표 개선
