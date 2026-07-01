# SkySnap 모임(커뮤니티) 기능 — 설계 확정서

> 방향: **Spot(장소) → 모임(Community) → 콘텐츠** 계층. 기존 SkySnap 자산 최대 재사용.
> 상태: 설계 확정 (코딩 전). 작성 2026-07-01.

---

## 0. 설계 원칙

1. **처음부터 만들지 않는다.** 게시물/좋아요/댓글/조회/팔로우/틱톡뷰어/그리드/업로드는 이미 있음 → 재사용.
2. **모임은 "board에 소속 라벨을 붙이는" 얕은 확장.** `tb_board_master`에 `COMMUNITY_ID`만 추가.
3. **Spot 기반.** 모임은 선택적으로 Spot(장소)에 귀속 → 지역 아카이브·랭킹 확장 대비.
4. **출시 영향 최소화.** 신규 테이블·API·화면만 추가, 기존 흐름 불변.

---

## 1. 기존 자산 ↔ 계획 매핑

| 계획 항목 | 재사용 자산 | 신규 |
|-----------|-------------|------|
| 틱톡뷰어(상하 스와이프) | `lib/app/videolist/video_list_page.dart` (PreloadPageView + FastPageScrollPhysics) | 모임 필터 파라미터 |
| 앨범 그리드(2·4열) | `lib/root/board_list_page.dart` (2열 GridView) | 모임 필터 |
| 사진/영상 업로드 | `root_cntr` uploadCloudflare/uploadPhotos → `BoardRepo.save()` | community_id 추가 |
| 좋아요/조회/팔로우 | `TbBoardLike/View/Follow` (+id 테이블) | 그대로 |
| 댓글 | `board/searchComment`, `saveComment` | 그대로 |
| 태그 | 본문 해시태그 + `getTagBoardList`(CONTENTS LIKE) | 태그 집계 페이지 |
| 푸시 | FCM (`firebase_api`, `alram`) | 모임 이벤트 알림 |
| 장소(Spot) | `tb_spot` + spot 제보/승인 (이번 세션 구축) | 모임↔spot 연결 |
| **모임(그룹) 소속** | ❌ 없음 | **TB_COMMUNITY / MEMBER 신규** |

핵심 통합 사실:
- `tb_board_master`는 `TYPE_CD`/`TYPE_DT_CD`로 분류(V=영상, I=사진, NOTI, FAQ …). 커뮤니티/스팟 FK 없음.
- 태그는 **별도 테이블 없이 본문 해시태그를 `CONTENTS LIKE '%TAG%'`로 매칭**.
- 스팟-게시물은 **반경(GPS) 기반**(`searchBoardsNearby`), FK 아님.

---

## 2. 데이터 모델

### 2-1. 신규 테이블 (최소)

```sql
-- 모임
TB_COMMUNITY (
  community_id   BIGSERIAL PK,
  name           VARCHAR(100),
  description    TEXT,
  image_url      VARCHAR(300),      -- 대표사진
  owner_cust_id  VARCHAR(100),      -- 방장 (TB_CUST_MASTER)
  spot_id        BIGINT NULL,       -- 선택: 소속 장소(tb_spot) → Spot 기반 확장
  is_public      CHAR(1) DEFAULT 'Y',    -- 공개/비공개
  join_type      VARCHAR(10) DEFAULT 'AUTO', -- AUTO(자동) / APPROVAL(승인)
  member_cnt     INT DEFAULT 1,
  lat DOUBLE PRECISION NULL, lon DOUBLE PRECISION NULL,  -- 위치(선택)
  use_yn         CHAR(1) DEFAULT 'Y',
  crt_dtm        TIMESTAMP
);

-- 모임 멤버
TB_COMMUNITY_MEMBER (
  community_id BIGINT,
  cust_id      VARCHAR(100),
  role         VARCHAR(10) DEFAULT 'MEMBER', -- OWNER / MANAGER / MEMBER
  status       VARCHAR(10) DEFAULT 'JOINED', -- PENDING / JOINED / BANNED
  joined_at    TIMESTAMP,
  PRIMARY KEY (community_id, cust_id)
);
```

### 2-2. 기존 테이블 확장 (게시물/미디어 재사용)

```sql
-- 게시물은 기존 tb_board_master 재사용 + community_id 추가
ALTER TABLE tb_board_master ADD COLUMN IF NOT EXISTS community_id BIGINT NULL;
CREATE INDEX IF NOT EXISTS idx_board_community ON tb_board_master(community_id, crt_dtm DESC);
```
- 미디어: `tb_board_image`(사진 다중) + `tb_board_weather`(날씨) 그대로.
- community_id가 NULL이면 기존 개인 피드/스팟 피드(변경 없음), 값이 있으면 그 모임 게시물.

### 2-3. 태그 (2안 중 택1 — 열린 결정)

- **A안(빠름·기존방식):** 태그 테이블 없이 본문 해시태그 유지 → `CONTENTS LIKE '%#노을%'` + community_id 필터. 태그 집계는 근사치.
- **B안(정확·확장):** 아래 신규 테이블로 게시물-태그 정규화.
```sql
TB_COMMUNITY_TAG (tag_id BIGSERIAL PK, tag_name VARCHAR(50) UNIQUE, use_count INT DEFAULT 0);
TB_COMMUNITY_POST_TAG (board_id BIGINT, tag_id BIGINT, PRIMARY KEY(board_id, tag_id));
```
> 권장: **Phase 1은 A안**(빠른 출시), 태그 페이지 고도화 시 B안으로 승격.

---

## 3. 백엔드 API (신규)

기존 `BoardCtrl`/`BoardSvc`, `SpotCtrl` 스타일(GET/POST + ResData) 그대로.

**모임 CRUD/가입**
- `POST /community/create` — 생성(방장=세션유저, 자동 멤버 등록)
- `GET  /community/my` — 내가 가입한 모임 목록
- `GET  /community/search?keyword=&spotId=` — 검색/추천
- `GET  /community/{id}` — 모임 상세
- `POST /community/join` {communityId} — 가입(자동=즉시 JOINED, 승인=PENDING)
- `POST /community/leave` {communityId}
- `GET  /community/members?communityId=` — 멤버 목록
- `POST /community/approve` {communityId, custId} — (방장/매니저) 가입 승인
- `POST /community/invite/link?communityId=` — 초대 링크 발급

**모임 피드/앨범/태그** (기존 board 재사용, community_id 필터만 추가)
- `GET /community/feed?communityId=&pageNum=` — 시간순 피드(틱톡/그리드 공용)
- `GET /community/album?communityId=&pageNum=` — 그리드
- `GET /community/tags?communityId=` — 태그 목록+집계
- `GET /community/tag/board?communityId=&tag=&pageNum=` — 태그별 콘텐츠

**게시물 등록**: 기존 `BoardRepo.save(BoardSaveData)`에 `communityId`만 실어 보냄 → `/board/saveAll` 확장.

**권한 규칙**: 비공개 모임은 멤버(status=JOINED)만 feed/album/tag 조회 가능. 멤버 판정은 `TB_COMMUNITY_MEMBER`.

---

## 4. Flutter 화면 트리

```text
모임 탭 (하단 5탭 중 신규 or 라운지 확장)
├─ 모임 진입 분기
│    if (내 모임 없음) → 모임 검색/추천
│    else            → 모임 홈
├─ 모임 검색 (community/search) + [모임 만들기]
├─ 모임 생성 (community/create) — 카카오 장소검색 재사용(spot 연결), 대표사진, 공개/가입방식
├─ 모임 홈 [피드 | 앨범 | 태그 | 멤버] 탭바
│    ├─ 피드 = video_list_page 재사용(communityId)
│    ├─ 앨범 = board_list_page 그리드 재사용(communityId)
│    ├─ 태그 = 태그 집계 + 태그별 그리드
│    └─ 멤버 = community/members
├─ 게시물 상세 = 기존 Video_screen_page / 사진 캐러셀 재사용
└─ 틱톡뷰어 = video_list_page 재사용 (앨범→탭→전체화면 상하스와이프)
```

**재사용 극대화**: 피드/앨범/틱톡뷰어/상세는 **기존 위젯에 `communityId` 파라미터만 추가**. 신규 화면은 검색·생성·멤버·태그집계 4개뿐.

**진입점** (계획 #13):
```dart
if (myCommunities.isEmpty) showSearchCommunityPage();
else showCommunityHome();
```
탭 배치: 하단 5탭에 "모임" 신설 or 기존 "라운지(스카이라운지)"를 모임 허브로 확장(탭 과밀 방지). → **열린 결정**.

---

## 5. 단계별 로드맵

| Phase | 내용 | 산출물 |
|-------|------|--------|
| **P1 백엔드 기반** | TB_COMMUNITY/MEMBER + board.community_id + create/my/search/join/feed API | 모임 생성·가입·피드 동작(서버) |
| **P2 프론트 최소** | 모임 검색/생성/홈(피드) — 기존 피드 위젯 재사용 | 앱에서 모임 만들고 글 올리고 봄 |
| **P3 확장** | 앨범/태그/멤버 탭 + 승인 가입 + FCM 모임 알림 | 완전한 모임 홈 |
| **P4 Spot 연계·차별화** | 모임↔spot 연결, 지역 아카이브/랭킹/타임랩스 기반 | 날씨 기반 장소 커뮤니티 |

각 Phase는 독립 배포 가능(백엔드 자동배포, 앱은 스토어).

---

## 6. 결정사항 (확정 2026-07-01)

1. **탭 위치**: ✅ **기존 "스카이라운지" 확장** (신규 탭 X → 라운지를 모임 허브로).
2. **태그**: ✅ **A안**(본문 해시태그 + `CONTENTS LIKE` + community_id 필터, 빠름).
3. **Spot 연결**: ✅ **선택**(모임 생성 시 Spot 필수 아님, spot_id NULL 허용).
4. **비공개 격리**: ✅ **전부 숨김**(비공개 모임은 멤버(JOINED)만 feed/album/tag/썸네일 접근).

---

## 7. 리스크

- 대형 기능 → **출시 심사 중 릴리즈와 분리**(별도 브랜치 권장).
- board.community_id 추가는 기존 쿼리에 영향 없음(NULL 기본) → 안전.
- 비공개 모임 권한 누락 시 콘텐츠 유출 → 멤버 판정 서버측 필수(클라 신뢰 금지).
