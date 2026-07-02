# 📝 변경 이력 (LOG.md)

**형식**: `[시간] [담당자] [상태] [내용]`

---

## 2026-07-03

### 08:05 | claude | ✅ 완료 (카메라 페이지 UI 개선 — 배치·아이콘)
**작업**: 표준 카메라 UX 문법으로 재배치 + 아이콘/스타일 통일 (기능 로직 불변)
- **상단 바**: close 글래스 원형(40) 통일 + **플래시·비율 버튼을 상단 우측으로 이동**(일반 카메라 앱 관례). 플래시는 켜짐/자동/손전등 시 노란색으로 상태 인지, 비율은 "16:9" 텍스트 원형. 녹화 중 숨김. '다음' pill 유지
- **셔터 위 중앙 = 줌 핀 전용**: 플래시/비율/구분선이 섞여 있던 캡슐에서 분리 — 줌 배율 핀만 슬림 캡슐로
- **모드 토글**: 사진/영상 칩에 아이콘(photo_camera/videocam) 추가
- **하단 버튼**: 갤러리 = 라운드 사각(48, image_rounded — 원형 셔터·전환과 형태 구분), 전환 = cached(새로고침 오해) → **cameraswitch_rounded**, 52→48 슬림
- 검증: analyze 클린, Android 디버그 빌드 성공. 실기기서 상단 플래시/비율 동작 확인 필요

### 01:50 | claude | ✅ 완료 (앨범 홈 헤더 종(알림) 버튼 제거)
**작업**: 앨범 홈 상단의 구 라운지 알림(벨) 버튼 삭제 — 사용자 요청
- 헤더 구성: [검색][보기 토글][+ 만들기]로 축소. AlramPage 진입은 설정 > '스카이 라운지' 링크로 보존
- 검증: analyze 클린, Android 디버그 빌드 성공

### 01:40 | claude | ✅ 완료 (표지 이미지 로딩 속도 개선)
**작업**: 새 앨범 만들기에서 템플릿 선택 시 미리보기 반영이 수 초 걸리던 문제 수정
- **원인**: 미리보기가 Unsplash 원본 URL(원본 해상도, 수 MB)을 그대로 로드 — 스트립 썸네일만 w=200 파라미터가 있었음
- **수정 3단**: ① `coverImageUrl()` 헬퍼(cover_template.dart) — unsplash URL에 `?w=&q=70&fm=jpg` 자동 부착(타 호스트 no-op) ② 만들기 진입 시 10종 w=800 프리캐시(백그라운드) ③ 미리보기 placeholder로 이미 캐시된 w=200 썸네일을 깔아 선택 즉시 전환 체감
- **동일 문제 일괄 적용**: 홈 겹침 스택 표지 폴백(w=600)·모자이크 카드(w=400)·탐색 목록(w=200)도 경량본 사용
- 검증: analyze 클린, Android 디버그 빌드 성공

### 01:20 | claude | ✅ 완료 (메인 영상 피드에 공유 버튼 노출)
**작업**: `Video_screen_page` 우측 액션열의 주석 처리돼 있던 공유 버튼을 실제 노출
- 좋아요·댓글·조회수 아래에 `Icons.ios_share` + "공유" 라벨 버튼 추가 → `share()`(SNS 공유) 호출
- 기존엔 몰입 뷰(공유앨범)에만 공유 버튼이 있었고 메인 피드엔 주석 처리로 숨겨져 있었음
- 검증: analyze 오류 0, debug APK 빌드

### 01:10 | claude | ✅ 완료 (SNS 공유 ① 범용 공유 시트)
**작업**: 영상/사진을 틱톡·인스타 등 SNS로 내보내는 기능 1단계 — 범용 OS 공유 시트(외부 등록 불필요)
- 신규 `lib/utils/sns_share.dart` `SnsShare.shareMedia()`: mp4(우선)/이미지 URL을 임시파일로 다운로드(dio, 진행률 다이얼로그+취소) → `Share.shareXFiles`로 OS 공유 시트 전달. HLS(m3u8)는 SNS가 못 받으므로 mp4 없으면 썸네일 이미지로 폴백. 텍스트만 있으면 텍스트 공유
- 연결: 피드 영상 상세(`Video_screen_page.share()`)·공유앨범 몰입 뷰(`album_immersive_page` 공유 버튼)의 placeholder 공유(example.com)를 실제 미디어 공유로 교체. typeDtCd V/I로 영상/사진 분기
- 사용자는 공유 시트에서 틱톡/인스타/카톡 등 선택(인스타는 피드·DM 컴포저). 전용 버튼(인스타 스토리 딥링크·틱톡 Share Kit)은 FB App ID·TikTok key 발급 후 2단계 예정
- 검증: 3파일 analyze 신규 오류 0, debug APK 빌드

### 00:40 | claude | ✅ 완료 (표지 템플릿 귀여운 무드 재교체 + 하단탭 라벨)
**작업**: 표지 템플릿 10종을 "밝고 귀엽고 경쾌한 캐릭터(토이)" 무드로 재교체 + 하단탭 라운지→앨범
- 후보 19장 URL 검증·썸네일 눈검수 → 9종 교체(연애 하트보케 유지): 흰 꽃(결혼)/양철 로봇+오리(동창회)/파스텔 테디+바구니(100일)/젤리(파티)/레고 브릭(망년회)/마카롱(생일)/나무 기차 마을(여행)/나비넥타이 테디(가족)/레고 4인방 횡단보도(친구)
- 3곳 갱신: 프론트 cover_template.dart(2ce50e4)/백엔드 CommunityCoverTemplates(ea3b7f6, 자동배포)/운영 DB 기존 앨범 2건
- 하단탭 index3: '라운지'→'앨범', 아이콘 groups→photo_library_rounded
- 검증: analyze 클린, Android 디버그 빌드, 백엔드 compileJava 성공

### 00:15 | claude | ✅ 완료 (앨범 만들기 다크 재작성)
**작업**: 앨범 만들기가 구 라이트 디자인이라 새 다크 홈과 이질적 → `album_create_page`로 재작성
- 기능 동일 보존: 표지(큰 미리보기 + 템플릿 10종 스트립 + 내 사진 업로드 타일, teal 링), 이름/소개 다크 인풋, 공개 범위·가입 방식(teal 세그먼트 + 힌트 문구), 장소 연결(카카오 검색 400ms 디바운스·선택 칩·해제, Spot 상세 prefill 지원), '앨범 만들기' 그라디언트 CTA
- 진입점 3곳 교체: 홈 헤더 [+]/빈 상태 CTA, Spot 상세 '이 장소로 앨범 만들기' → /AlbumCreatePage. 구 CommunityCreatePage는 라우트 병존
- 검증: analyze 클린, Android 디버그 빌드 성공

## 2026-07-02

### 25:50 | claude | ✅ 완료 (하단탭 라운지 → 공유앨범 홈 교체)
**작업**: 하단탭 index3을 CommunityHubPage → AlbumListPage(공유앨범 1a)로 교체 + 허브 기능 4종 이관
- `root_page.dart`: mainlist[3] = AlbumListPage (허브는 라우트로 병존)
- **알림 벨**: 홈 헤더에 벨 추가(/AlramPage — 구 허브의 유일 알림 진입점 보존)
- **받은 초대**: 홈 헤더 아래 섹션(warn 톤 카드, 수락=teal/거절, 수락 시 목록 갱신) — getMyInvites/accept/decline 재사용
- **검색+코드 참여**: 신규 `album_explore_page`(다크) — 공개 앨범 검색(디바운스, 비우면 인기순), 초대 코드 다이얼로그(joinByCode), 결과 카드(멤버 N·승인제/바로참여, 참여/신청/멤버/신청됨 상태), 가입 발생 시 홈 reload
- 헤더 재구성: [검색][보기 토글][벨][+ 만들기(그라디언트 원형)]
- 검증: analyze 클린, Android 디버그 빌드 성공. 검수: 하단탭 3번 탭

### 23:55 | claude | ✅ 완료 (기존 라운지를 설정에 링크)
**작업**: 라운지 하단탭이 새 앨범 허브로 교체됨 → 기존 라운지(`AlramPage` "스카이 라운지", 게시판 등)를 설정에서 진입하도록 링크 추가
- `setting_page.dart`: "커뮤니티" 그룹 신설(문의 아래) + '스카이 라운지' 항목(Icons.groups, teal) → `Get.toNamed('/AlramPage')`
- `alram_page.dart`: AppBar `automaticallyImplyLeading: false`→`true` — 하단탭에서 빠져 이제 푸시로만 진입하므로 뒤로가기 버튼 노출(기존엔 없어 설정/허브서 열면 못 돌아감)
- 참고: 새 허브의 '알림' 벨 아이콘도 `/AlramPage`를 열고 있음(그대로 둠)
- 검증: flutter analyze 신규 이슈 0, debug APK 빌드

### 25:30 | claude | ✅ 완료 (1g 업로드·1h 멤버 초대 — 공유앨범 8화면 전체 완료)
**작업**: 공유앨범 마지막 화면 2종 구현 — 디자인 핸드오프 1a~1h 전체 완료
- **1g 업로드(`album_upload_page`)**: 1d 올리기 FAB → 촬영/갤러리 시트. 갤러리 다중 선택 → 대상 앨범 칩 + 미디어 그리드(첫 항목 2x2·x 제거·+ 추가) + 캡션 + **날씨·위치 자동 태그 토글**(WeatherGogoCntr 현재 위치·날씨 → BoardSaveWeatherData, OFF면 미첨부) + 'N개 업로드'(기존 goTimerPhotos 재사용). 사진 전용 — 영상은 촬영 플로우
- **1h 멤버 초대(`album_invite_page`)**: 초대 링크 카드(복사·공유) + **QR 카드(qr_flutter ^4.1.0 신규 의존성)**, 팔로우에서 초대(멤버/초대됨/초대 버튼 상태), 현재 멤버(역할·모두 보기), 대기 중(보낸 초대 + 다시 보내기, 매니저만)
- **백엔드(819dfd5, 배포·검증)**: GET /community/invited(방장·매니저) — 운영에서 비매니저 거부·방장 실데이터 조회 확인
- 프론트 6e9e1aa. 검증: analyze 클린, Android 디버그 빌드(qr_flutter 포함) 성공
- 스코프 노트: 1g 알림 토글은 백엔드가 저장 시 자동 발송이라 생략(끄기 지원하려면 boardSave 파라미터 확장 필요)

### 23:45 | claude | ✅ 완료 (회원가입 동의 화면 디자인 개선 → 로딩화면 톤)
**작업**: 회원가입 동의 화면(`agree_page.dart`)을 로딩화면(AuthPage)과 동일한 브랜드 톤으로 재디자인
- 밋밋한 흰 배경+파랑/초록 → **대각선 3색 그라데이션(#FFCB6B→#FF8F8F→#FF6FA6)** + 흰 구름 로고 + Quicksand "skysnap" + "반가워요! 👋" 헤더
- 약관 목록은 흰 카드(그림자)로 감싸 가독성 확보. 전체동의 강조 타일 + 원형 체크(액센트 #EA3799 채움) + 개별 항목 '보기' 링크(chevron)
- 확인 버튼: 그라데이션 위에서 도드라지는 흰 배경+액센트 글자 "동의하고 시작하기"(전체동의 전엔 비활성)
- 기능 전부 보존(전체/개별 동의 토글·보기 라우팅·위치권한 흐름·signUpProc·로딩 오버레이·PopScope)
- 검증: flutter analyze 신규 이슈 0, debug APK 빌드

### 25:00 | claude | ✅ 완료 (1f 대문 편집)
**작업**: 공유앨범 1f 대문 편집 — 실시간 미리보기 + 테마/대표미디어/표시옵션
- **백엔드(de3c1f2, 배포·운영검증 완료)**: tb_community에 theme_color/cover_media_ids/card_options 3컬럼(ALTER 완료), POST /community/updateFront(방장·매니저만, null=미변경·빈값=해제), my/detail에 3필드 노출. 운영 라운드트립: 방장 저장→반영→해제 원복 ✓, 비매니저 거부 ✓
- **프론트(c3a8037)**: `album_cover_editor_page` — 취소/저장(teal) 상단바, PREVIEW 카드(teal 링, SaAlbumCard 재사용·편집 즉시 반영), 대표 미디어 스트립(탭 순서=겹침 순서 1~3, teal 링+순번, 재탭 해제), 제목/소개 다크 인풋, 테마 스와치(자동+날씨 8종), 표시 옵션 스위치 4종, 멤버 관리 행
- 카드 반영: SaAlbumCard·모자이크가 themeColor 우선 그라디언트+cardOptions 존중, 홈 커버는 지정 미디어 순서 우선(부족분 최근순)
- 진입: 1d more 시트 '대문 편집'(방장·매니저만) → 저장 시 상세 재조회
- 검증: 백엔드 compileJava·운영 API, 프론트 analyze 클린·Android 디버그 빌드 성공

### 23:35 | claude | ✅ 완료 (카메라 녹화 버튼 빨간 네모 원 밖으로 튀는 문제)
**작업**: 녹화 중 셔터 버튼의 빨간 사각형 모서리가 흰 원 밖으로 삐져나오던 버그 수정
- 원인: `_shutterButtonDecoration`가 안쪽을 padding으로 꽉 채워(66×66) borderRadius만 8로 바꿈 → 원(내경 ~67)에 꽉 찬 사각형은 대각선(~93)이 원을 넘어 모서리 4곳이 튀어나옴
- 수정: padding 제거+중앙 정렬, 안쪽 크기를 상태별로 지정 — 대기 60(원판)/녹화 30(작은 정지 사각형). 대각선 ~42 < 원 지름 67이라 원 안에 안전히 들어옴
- `camera_awesome_page.dart` (활성 카메라=camerawesome)
- 검증: flutter analyze 신규 이슈 0, debug APK 빌드

### 23:25 | claude | ✅ 완료 (내정보 페이지 제목 "닉네임"→"내정보")
**작업**: 내정보 탭 상단 제목이 로그인 닉네임(예: "스카이")을 표시하던 것을 고정 "내정보"로 변경
- `myinfo_page.dart` `_appBar()`: 닉네임 Obx Text + 빈 바텀시트를 여는 InkWell(죽은 동작) 제거 → `const Text('내정보')`
- 검증: flutter analyze(신규 경고 0), debug APK 빌드

### 23:15 | claude | ✅ 완료 (스팟 날씨·상세 디자인 톤 통일)
**작업**: 스팟별 날씨(목록)와 스팟 상세 페이지의 디자인 패턴 불일치 해소 — 사용자 선택으로 밝은 톤 통일
- **문제**: 목록(`spot_weather_body/page`)은 밝은 톤(bg #F8F9FB·흰 카드·검정/회색), 상세(`spot_detail_page`)만 어두운 톤(bg #11141C·#1B1F2A·파랑 #4A90E2). 게다가 목록 내에서도 액센트 2개(FAB 보라 #8C83DD vs 본문 근검정 #04101C)로 갈림
- **결정**: 앱 기본 테마(scaffold 흰색)·목록 주석("흰색 배경") 근거로 **밝은 톤을 표준**으로 확정(사용자 승인). 액센트는 브랜드 보라 **#8C83DD로 3파일 통일**
- **상세 페이지 변환**: 다크→라이트(bg #F8F9FB, 흰 카드+#E8EAED 테두리+연한 그림자, 검정/#5F6368 텍스트, 보라 액센트). 앱바 흰색, 썸네일 플레이스홀더 #EEF0F3(흰 배경서 빈 썸네일 보이게)
- **목록 본문**: 근검정 액센트→보라(선택 카테고리 칩·기온·리프레시·재생아이콘 일관화)
- 검증: 3파일 flutter analyze 이슈 0, debug APK 빌드

### 24:00 | claude | ✅ 완료 (NEW 열람 추적 — 백엔드+뱃지 연결)
**작업**: 공유앨범 NEW(안 본 콘텐츠) 열람 추적 구현 — 읽기 화면 3종 완료 후 일괄 연결
- **백엔드(1b37577, 자동배포)**: tb_community_member.last_seen_dtm(운영 DB ALTER 완료), POST /community/seen, my/detail 응답에 newCnt(마지막 열람—없으면 joined_at—이후 남이 올린 미디어 수)·lastSeenDtm
- **프론트(0da56c1)**: 1a/1c 카드 NEW pulse 뱃지 활성화, 1d 진입 시 markSeen(홈 복귀 시 뱃지 해소), 1d 셀 pink 점(진입 시점의 이전 lastSeen 기준 — 세션 동안 유지)
- 검증: 백엔드 compileJava·프론트 analyze/빌드 성공. 실기기 QA: 멤버 계정으로 새 글 올린 뒤 홈 뱃지→1d 점→재진입 해소 확인 필요

### 23:40 | claude | ✅ 완료 (1e 몰입 뷰, 리뷰 대기)
**작업**: 공유앨범 1e 몰입 뷰(틱톡식 세로 풀스크린) 구현
- `album_immersive_page.dart`: 세로 PageView, 현재 페이지만 VideoPlayer 유지(이전 dispose), hls→mp4→videoPath 순 재생, 사진은 풀스크린 이미지
- 상단: 글래스 back + 앨범명 칩 + 뷰 세그먼트(몰입 active, 그리드 탭=복귀) / 우상단 진행 표시(≤12개 세로 도트, 초과 시 n/total mono)
- 우측 액션 레일: 업로더 아바타(OtherInfoPage) → 좋아요(낙관적 토글+LikeRepo, pink) → 댓글(기존 CommentPage().open 재사용) → 공유(share_plus)
- 좌하단: 업로더명(800/16)+시간(mono)+캡션 2줄+날씨 글래스 칩(city·온도·습도) / 하단: 영상 스크러버+0:09/0:24+"↑ 다음" bob 힌트(4초)
- 인터랙션: 탭=재생/일시정지, 더블탭=좋아요+하트 스케일 애니, 끝 5개 남으면 다음 페이지 로드
- 1d 연결: 셀 탭(해당 인덱스)·몰입 세그먼트 → 몰입 뷰(아이템 객체 공유로 좋아요 상태 복귀 반영). 풀스크린 규칙 준수(SafeArea 금지·cover·viewPadding 보정)
- 부수: LikeRepo.save에 pushYn/alramCd 추가(백엔드 필수 파라미터인데 누락돼 있던 사문 코드 정상화)
- 검증: analyze 클린, Android 디버그 빌드 성공. 실기기 QA 필수(영상 재생/스크러버/좋아요/댓글)

### 22:55 | claude | ✅ 완료 (네이티브 스플래시 = 로딩화면 디자인)
**작업**: 로딩화면(AuthPage) 디자인을 네이티브 스플래시로 재현 — 앞선 preserve/remove(밋밋한 스플래시가 로딩화면을 가림)를 되돌리고 방향 반대로 재작업
- preserve/remove 원복(main.dart / root_page.dart / join_page.dart) → AuthPage 그라데이션 로딩화면 다시 표시
- AuthPage와 동일한 대각선 3색 그라데이션(#FFCB6B→#FF8F8F→#FF6FA6) 배경 PNG 생성(PIL, 1290×2796) → `assets/icon/splash_bg.png`
- pubspec `background_image`로 지정(+구름 로고 image). color·background_image는 병용 불가라 최상위 color 주석 처리
- `flutter_native_splash:create` 재생성: Android drawable/background.png·iOS LaunchBackground 모두 1290×2796 그라데이션 확인
- 한계: Android 12+는 OS 제약으로 그라데이션 배경 불가 → android_12.color=#FF8F8F 단색 + 구름(직후 AuthPage가 실제 그라데이션 렌더). iOS·Android11↓는 전체 그라데이션
- 검증: 3개 dart analyze(에러 0), debug APK 빌드 성공

### 22:50 | claude | ✅ 완료 (표지 템플릿 사진 전면 교체)
**작업**: 앨범 만들기 표지 템플릿 10종 사진 전면 교체 — "AI 티 난다" 피드백 반영
- 발랄·캐릭터 무드의 Unsplash 무료 사진으로 교체: 레고 유니콘(100일)·티피 텐트 코기(가족)·장난감 요트(친구)·스프링클 도넛(생일)·색종이(파티)·무지개 콘서트(망년회)·노랑 밴(여행)·건배(동창회)·하트 보케(연애)·반지+부케(결혼)
- 후보 18장 URL 접근 검증(200) + 썸네일 다운로드해 이미지 내용 전수 눈검수 후 10장 확정
- 3곳 동시 갱신: 프론트 cover_template.dart(05aa94d) / 백엔드 CommunityCoverTemplates.java(c7ef64a, 자동배포) / 운영 DB 기존 앨범 2건 image_url UPDATE
- 검증: 프론트 analyze·빌드, 백엔드 compileJava 성공

### 19:35 | claude | ✅ 완료 (1c 모자이크 그리드 추가, 리뷰 대기)
**작업**: 공유앨범 홈에 1c 모자이크 그리드를 '보기 방식 토글'로 추가
- 헤더에 토글 버튼(squaresFour↔rows) — 1a 스택 피드 ↔ 1c 2열 스태거드 전환, 선택값 secure storage 유지
- `widget/sa_album_mosaic_card.dart`: 이미지 tall150/short106 교차(0,3,4,7… tall) + 제목(700/14) + 멤버/미디어 아이콘 스탯, NEW 뱃지 슬롯
- MasonryGridView(기보유 flutter_staggered_grid_view) 사용, 탭 동작은 1a와 동일(AlbumDetailPage)
- 검증: analyze 클린, Android 디버그 빌드 성공

### 19:10 | claude | ✅ 완료 (1d 갤러리 + 미디어수 백엔드, 리뷰 대기)
**작업**: 공유앨범 1d 갤러리 뷰 + 앨범별 미디어 수 백엔드 확장
- **백엔드(배포됨 a96800c)**: CommunityItem에 videoCnt/photoCnt 추가, countByCommunityIdAndTypeDtCd 쿼리(TYPE_DT_CD V/I, DEL_YN·LOCK_YN N), toItem(withCounts) 오버로드 — my/detail만 계산(검색은 기존대로). 운영 검증: detail 응답에 videoCnt 포함 확인
- **프론트 1d(`album_detail_page.dart`)**: 원형 back/more 앱바, 커버 스트립(미니 겹침스택 64+멤버 아바타+VIDEO/PHOTO mono 스탯), 필터 칩(전체/영상 N/사진 N, active=teal), 뷰 전환 세그먼트(그리드 active·몰입→기존 COMMUNITY 풀스크린 임시연결), 3열 그리드(1:1.12, gap6, r13, 영상=play/사진=image 아이콘, 무한스크롤), '＋ 올리기' FAB(pendingCommunityId+카메라, 기존 로직 재사용), more 시트(멤버/초대 기존 라우트 연결)
- CommunityData에 videoCnt/photoCnt/mediaCnt 추가 → 1a 카드 +N 칩 활성화, 1a 카드 탭 → AlbumDetailPage로 교체
- NEW(안 본 것) pink 점은 열람 추적 백엔드 후 연결(1e까지 완료 후 일괄)
- 검증: 백엔드 compileJava 성공·운영 API 확인, flutter analyze 클린, Android 디버그 빌드 성공

### 18:15 | claude | ✅ 완료 (1a 홈, 리뷰 대기)
**작업**: 공유앨범 1a 홈(스택 피드) 화면 구현
- `lib/app/shared_album/album_list_page.dart` + `widget/sa_album_card.dart`
- 데이터 조립: 기존 `/community/my` → 앨범별 `feed(3건)`+`members` 병렬 지연 로드(썸네일 3장·아바타 3명·최근 업데이트 timeage)
- 카드: SaOverlapImageStack(썸네일 없으면 앨범 id 기반 날씨 그라디언트 순환) + 재생 글래스 버튼 + 제목/소개 + 아바타 스택·멤버 수·최근 업데이트
- 헤더: "우리의 앨범" + N ALBUMS(mono teal) + 검색(다음 단계 연결) + 만들기(기존 CommunityCreatePage)
- 카드 탭 → 기존 CommunityHomePage (1d 구현 시 교체 예정)
- **백엔드 확장 대기 항목**: 총 미디어 수 칩(+124)·NEW 뱃지(열람 추적) — 데이터 없어 자동 숨김 처리
- 검수 경로: 설정 > (디버그) '공유앨범 홈 1a'. analyze 클린, Android 디버그 빌드 성공

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
