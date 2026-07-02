# Handoff: 공유 앨범 (Shared Album) — 날씨 영상 앱 신규 기능

## Overview
기존 Flutter 날씨 영상 앱에 붙일 **"함께 모으는 공유 앨범"** 기능의 화면 디자인 핸드오프입니다.
사용자는 앨범을 만들어 다른 사람을 초대하고, 서로 사진·영상을 올려 공유합니다. 홈에서는 속한 앨범들이
카드 리스트로 보이고, 앨범에 들어가면 갤러리(그리드)/몰입(틱톡식 풀스크린) 두 방식으로 볼 수 있으며,
앨범의 "대문(홈에 노출되는 카드)"을 직접 편집·관리할 수 있습니다.

## About the Design Files
이 번들의 `공유앨범 화면제안.dc.html` 은 **HTML로 만든 디자인 레퍼런스(프로토타입)** 입니다.
의도한 룩앤필과 동작을 보여주는 것이 목적이며, **그대로 복사해 쓰는 프로덕션 코드가 아닙니다.**
작업의 목표는 이 디자인을 **기존 Flutter 앱의 환경·패턴·상태관리 방식에 맞춰 재구현**하는 것입니다.
(기존 앱에 이미 쓰는 상태관리, 라우팅, 네트워크 계층, 위젯 컨벤션을 그대로 따르세요.)

- HTML은 브라우저에서 열어 시각 확인용으로만 사용하세요. (더블클릭 → 브라우저)
- `previews/` 폴더에 각 화면 스크린샷이 있습니다.
- `ios-frame.jsx` 는 목업용 아이폰 베젤일 뿐, 구현 대상이 아닙니다. **무시하세요.**

## Fidelity
**High-fidelity.** 최종 색상·타이포·간격·레이아웃이 확정된 목업입니다. 아래 디자인 토큰과 화면 스펙을
픽셀 단위로 재현하되, 위젯/애니메이션 구현은 Flutter 관용 방식으로 하세요.

> 참고: HTML 목업은 iOS 논리 해상도 **402 x 874 pt** 기준으로 그렸습니다. Flutter에서는 `MediaQuery`
> 기반 반응형으로 짜고, 아래 수치(px)는 그대로 **logical pixel(dp)** 로 대응시키면 됩니다.

---

## Design Tokens

### Colors
| 이름 | 값 | 용도 |
|---|---|---|
| `bgBase` | `#0C0D11` | 앱/화면 기본 배경 (다크) |
| `bgCanvas` | `radial-gradient(#171B26 → #0B0C10)` | (참고용 캔버스 배경, 앱에선 `bgBase` 사용) |
| `surface` | `#15171D` | 카드/셀 배경 |
| `surfaceElevated` | `#1A1D24` | 썸네일 플레이스홀더 등 |
| `border` | `rgba(255,255,255,0.07)` | 카드 외곽선 |
| `borderStrong` | `rgba(255,255,255,0.10)` | 인풋/버튼 외곽선 |
| `accentTeal` (Primary) | `#00E5D0` | 주요 액션, 선택 상태, 링크 |
| `accentBlue` | `#2B8FF0` | 그라디언트 짝 (teal→blue) |
| `accentPink` (New) | `#FF3D77` | "안 본 새 콘텐츠" 뱃지/점, 좋아요 |
| `warn` | `#FFB75E` | 대기 중 초대 등 |
| `textPrimary` | `#FFFFFF` | 본문 강조 |
| `textSecondary` | `rgba(255,255,255,0.55)` | 보조 텍스트 |
| `textTertiary` | `rgba(255,255,255,0.40)` | 메타/타임스탬프 |
| `onAccent` | `#04121A` | teal 버튼 위 텍스트 (진한 청록-검정) |

**Primary Gradient (버튼·FAB·아이콘칩):** `linear-gradient(145deg, #00E5D0, #2B8FF0)`

### Weather Gradients (영상/사진 썸네일 자리 = 날씨 씬)
실제 앱에선 **실제 미디어 썸네일**이 들어갈 자리입니다. 로딩 전 플레이스홀더/무드로 아래 그라디언트 사용 권장:
| 날씨 | 그라디언트 (angle 155deg) |
|---|---|
| 비 (rain) | `#5A9FE8 → #2B5FB0(55%) → #243B73` |
| 노을 (sunset) | `#FF9A5A → #FF5F6D(48%) → #7B3FA0` |
| 폭풍 (storm) | `#4A5C82 → #222C48(55%) → #5B3B7A` |
| 밤/맑음 (night) | `#2A3F82 → #2D1E5F(60%) → #0E1330` |
| 오로라 (aurora) | `#1FD6A6 → #2B8FF0(52%) → #7B5BF0` |
| 골든 (golden) | `#FFD15A → #FF8A3C(50%) → #FF5F8F` |
| 안개 (fog) | `#9AA7C7 → #6D7BA0(55%) → #B9A7D6` |
| 눈 (snow) | `#DBEEFF → #A9C8EC(55%) → #AAB8D8` |

### Typography
- **본문/UI 폰트**: `Pretendard` (한글). pubspec에 폰트 추가 또는 `pretendard` 패키지 사용.
  - 대안: `Noto Sans KR`. 절대 Inter/Roboto 기본으로 대체하지 말 것 — 톤이 달라짐.
- **숫자·메타·태그 폰트**: `Space Mono` (통계 수치, 타임스탬프, 링크, 뱃지 라벨). Google Fonts.
- 스케일 (weight / size / 용도):
  - Display: 800 / 34px — 커버 히어로 타이틀 (1b)
  - Title-L: 800 / 28px — 홈 헤더 "우리의 앨범"
  - Title-M: 800 / 22px — 앨범 카드 제목
  - Title-S: 700 / 16~17px — 앱바 제목, 리스트 제목
  - Body: 400~500 / 14~15px — 설명/소개
  - Caption: 500~600 / 12~13px — 스탯 라벨
  - Mono: 600~800 / 10~12px — 수치/태그/타임스탬프 (`Space Mono`, letter-spacing 0.02~0.1em)

### Radius / Spacing / Elevation
- Radius: 카드 26, 미디어 20~22, 썸네일 13~16, 칩/버튼 pill(999), 인풋 13~14.
- 화면 좌우 패딩: **16px**. 카드 내부 패딩: 14px.
- 상태바 클리어 상단 패딩: **56px** (Flutter에선 `SafeArea` + 커스텀 앱바).
- 하단 홈 인디케이터 영역: 34px (`SafeArea` bottom).
- 카드 그림자: `0 16px 34px rgba(0,0,0,0.55)` 계열, teal glow는 목업 캔버스용이라 앱에선 생략 가능.

### Icons
목업은 **Phosphor Icons** 사용. Flutter에선 [`phosphor_flutter`](https://pub.dev/packages/phosphor_flutter) 패키지로 1:1 매칭.
자주 쓴 아이콘: `images, magnifyingGlass, plus, play(Fill), playCircle, users(Fill), heart(Fill),
chatCircle(Fill), shareFat(Fill), bookmarkSimple(Fill), cloudRain(Fill), mapPin(Fill), caretLeft/Right/Up/Down,
dotsThree, squaresFour(Fill), frameCorners, camera(Fill), arrowUp, bell(Fill), lockSimple, usersThree, linkSimple, copy, sparkle(Fill)`.

---

## Screens / Views

각 화면은 HTML 좌상단 배지로 식별됩니다. 실제 앱에는 배지/캡션이 없습니다(목업 라벨).

### 1a · 홈 — 스택 피드 (추천 기본안)
- **목적**: 속한 앨범 목록. 앨범 하나 = 큰 카드 한 장.
- **레이아웃**: 세로 스크롤 리스트(`ListView`). 상단 헤더(타이틀 "우리의 앨범" + "N ALBUMS" mono, 우측 검색 원형 버튼 + teal 그라디언트 + 버튼).
- **카드 (`Card`/`Container` r26, surface, border)**:
  - 상단 **겹침 이미지 스택**(높이 208): 중앙 리드 이미지(r20, 200h) + 좌우 뒤에 2장이 살짝 회전(-7°/+7°)해 삐져나옴.
    - 리드 위 오버레이: 좌상단 날씨/위치 칩(glass), 우상단 미디어 수 칩(`+124`), 중앙 재생 글래스 버튼(54), 좌하단 `NEW 6` 뱃지(pink, pulse 애니메이션).
  - 제목(800/22) + 소개(400/13, secondary).
  - **스탯 행**: 멤버 아바타 스택(28px 원, -10px 겹침, 마지막 `+5`) + "멤버 8" + · + play 아이콘 132 + · + "3시간 전"(mono).
- 카드 2~3장 반복. (겹침 스택 = card_style 1)

### 1b · 홈 — 커버 히어로 (대안)
- 최상단 **대표 앨범 풀블리드 커버**(396h, weather gradient, 하단 스크림). 위에 앱바(투명), `NEW 12` 리본, 우측 peek 썸네일 2장, 하단 큰 타이틀(800/34) + 날씨칩 + 스탯 glass pill 3개(멤버/영상수/최근).
- 아래 **"MORE ALBUMS"** 리스트: 각 행 = 좌측 미니 겹침스택(82) + 우측 제목/스탯/날씨칩 + chevron. new는 제목 옆 pink 점.

### 1c · 홈 — 모자이크 그리드 (대안, 밀도 높음)
- 2열 스태거드(`MasonryGridView` 또는 두 Column). 카드 높이 가변(tall 150 / short 106 이미지). 각 카드: 이미지+날씨칩+(옵션)NEW뱃지 + 제목(700/14) + 멤버/영상 아이콘 스탯. 앨범 많은 파워유저용.

> **홈 3안은 택1 또는 설정 토글.** 기본 구현은 **1a** 권장. 1c는 "보기 방식" 옵션으로 추가 가능.

### 1d · 앨범 상세 — 갤러리 뷰
- 커스텀 앱바: back 원형 + 중앙 앨범명 + 우측 more.
- **커버 스트립**: 미니 겹침스택(64) + 멤버 아바타/스탯 + 날씨·위치·시간 mono 칩.
- **컨트롤 행**: 필터 칩 `전체`(active=teal) / `영상 98` / `사진 34` + 우측 **뷰 전환 세그먼트**(그리드=active | 몰입).
- **미디어 그리드**: 3열(`GridView`, aspect 1:1.12, gap 6, r13). 셀 위: 좌상단 pink 점(안 본 것), 우하단 재생+시간(mono) 또는 사진 아이콘.
- 하단 중앙 **"＋ 올리기" FAB pill**(teal gradient, glow).

### 1e · 앨범 상세 — 몰입 뷰 (틱톡식)
- 풀스크린 미디어(weather gradient 배경, 상하 스크림). **세로 스와이프(`PageView` scrollDirection: vertical)** 로 다음/이전.
- 상단: back + 중앙 앨범 칩 + 뷰 전환 세그먼트(몰입=active).
- 우측 상단 **진행 점 도트**(현재/전체).
- **우측 액션 레일**: 업로더 아바타(+팔로우 뱃지) → 좋아요(heartFill pink, "1.2천") → 댓글(84) → 저장 → 공유. 세로 정렬.
- **좌하단 정보**: 업로더명(800/16) + 시간 + 캡션(2줄) + 날씨/위치 glass 칩("서울 강남 · 비 24° · 습도 88%").
- 하단: **스크러버**(진행 38%) + "0:09 / 0:24" + "↑ 다음 영상" 힌트(bob 애니메이션).

### 1f · 대문 편집 / 관리 (핵심 관리 화면)
- 상단 바: `취소` / `대문 편집` / `저장`(teal).
- **PREVIEW 카드**(teal 링 강조): 현재 설정이 반영된 홈 카드 실시간 미리보기.
- **대표 이미지 · 겹침 순서**: 앨범 미디어 가로 스트립, 선택시 teal 링 + 순번(1/2/3), 끝에 `+` 추가. (드래그 재정렬 가능하게 구현 권장 — `ReorderableListView` 가로)
- **제목** 인풋(연필), **소개** 멀티라인 인풋.
- **테마 컬러**: 원형 스와치 5개(weather gradient), 선택시 링.
- **카드에 표시할 정보** (iOS 스타일 `Switch` 리스트): 회원 수/총 미디어 수/멤버 썸네일/새 콘텐츠 뱃지 = ON, 날씨·위치 태그 = OFF (토글 상태 예시).
- **공개 범위**(초대된 멤버만) / **멤버 관리**(8명) 이동 행.

### 1g · 업로드
- 상단 바: `취소` / `올리기` / `다음`.
- **대상 앨범 칩**(드롭다운): "장마의 기록 ▾".
- **선택된 미디어 그리드**: 첫 항목 2x2 크게(영상, 시간), 나머지 1x1, 각 우상단 `x` 제거, 끝에 `+` 추가 타일 + `촬영`(teal) 타일.
- **캡션** 멀티라인 인풋.
- **자동 감지 태그 카드**: GPS+날씨 자동 감지("서울 강남구 · 비 24°C") + attach 토글(ON). — 기존 날씨 앱 데이터 연동 포인트.
- **멤버에게 알림** 토글(ON).
- 하단 **"4개 업로드"** 버튼(teal gradient). 업로드 중엔 진행률 표시로 전환.

### 1h · 멤버 초대
- 앱바: back + "멤버 초대" + "장마의 기록 · 멤버 8".
- **초대 링크 카드** + **QR 카드** 나란히. 링크 mono 텍스트 + `복사` 버튼(teal). QR은 실제 생성(`qr_flutter` 패키지).
- **연락처에서 초대**: 아바타 + 이름/핸들 + `초대` 버튼(teal outline) 리스트.
- **현재 멤버 · 8**: 아바타 + 이름 + 역할(관리자/멤버) + more. "모두 보기".
- **대기 중 · 1**: 점선 아바타 + "초대 보냄"(warn mono) + `다시 보내기`.

---

## Interactions & Behavior
- **홈 카드 탭** → 앨범 상세(1d) 진입.
- **뷰 전환 세그먼트** → 갤러리(1d) ↔ 몰입(1e) 동일 앨범 내 전환. 상태 유지.
- **몰입 뷰**: 세로 스와이프로 미디어 전환, 탭으로 재생/일시정지, 더블탭 좋아요, 좋아요 시 heart 스케일 애니메이션.
- **NEW 뱃지 pulse**: `rgba(255,61,119)` 링이 2.4s ease-in-out 무한 확산. 미디어 열람 시 해당 뱃지 제거(안 본 것 → 본 것).
- **"다음 영상 ↑" 힌트**: 6px bob, 2s. 첫 진입 몇 초 후 자동 사라짐 권장.
- **업로드 FAB**: 눌러서 업로드(1g) 시트/화면 오픈.
- **대문 편집 토글/컬러/커버 순서 변경** → PREVIEW 카드 즉시 반영(실시간).
- **초대 링크 복사** → 클립보드 복사 + 스낵바.

## State Management
기존 앱의 상태관리(Provider/Riverpod/Bloc 등)를 그대로 사용. 필요한 상태:
- `List<Album>` (홈): id, 제목, 소개, 커버 미디어(정렬), 테마컬러, 멤버 목록, 미디어 수, 새 콘텐츠 수, 최근 업데이트, 날씨/위치 태그, 카드 표시옵션.
- `Album detail`: `List<MediaItem>`(영상/사진, 썸네일, duration, 업로더, isSeen, 좋아요/댓글 수, 캡션, 날씨/위치/시각), 뷰 모드(gallery|immersive), 필터(all|video|photo).
- `Upload draft`: 선택 미디어 리스트, 캡션, 대상 앨범, 자동태그 on/off + 감지값, 알림 on/off, 업로드 진행률.
- `Members/Invites`: 멤버 목록(역할), 대기 초대, 초대 링크/QR 데이터.
- `Cover editor`: 편집 중 앨범의 임시 복사본(취소 시 롤백, 저장 시 커밋).

## Data / 기존 앱 연동
- **날씨/위치 자동 태그**(1e, 1g)는 기존 날씨 앱의 위치·날씨 데이터를 재사용하는 것이 핵심 차별점. 업로드 시점의
  기온/날씨코드/지역명을 미디어 메타로 저장.
- 미디어 업로드/재생은 기존 앱의 스토리지/플레이어 계층 사용.

## Suggested Flutter Structure (제안)
```
lib/features/shared_album/
  models/        album.dart, media_item.dart, member.dart
  state/         album_list_controller.dart, album_detail_controller.dart, ...
  screens/       album_list_screen.dart (1a/1c)
                 album_detail_gallery_screen.dart (1d)
                 album_detail_immersive_screen.dart (1e)
                 cover_editor_screen.dart (1f)
                 upload_screen.dart (1g)
                 invite_screen.dart (1h)
  widgets/       album_card.dart, overlap_image_stack.dart, weather_chip.dart,
                 stat_row.dart, member_avatar_stack.dart, new_badge.dart,
                 media_grid_tile.dart, action_rail.dart, ios_switch.dart
  theme/         app_colors.dart, app_text_styles.dart, weather_gradients.dart
```

## Recommended packages
`phosphor_flutter`, `google_fonts`(Space Mono) + Pretendard 로컬 폰트, `qr_flutter`(1h),
`flutter_staggered_grid_view`(1c), `cached_network_image`(썸네일). 상태관리는 기존 앱 것 사용.

## Files
- `공유앨범 화면제안.dc.html` — 전체 8화면 디자인 레퍼런스 (브라우저에서 열기)
- `previews/*.png` — 화면 스크린샷
- `ios-frame.jsx` — (목업 베젤, 구현 무관 · 무시)
