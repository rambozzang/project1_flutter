# 앨범(커뮤니티) 표지 꾸미기 기능 설계

## 배경 / 목적

앨범(커뮤니티)은 동창회·결혼식·100일 기념·파티·망년회 등 매우 다양한 목적으로 만들어진다. 지금은 `tb_community.image_url` 필드가 존재하지만 이를 설정하는 UI가 어디에도 없어서, 실제로는 모든 앨범이 이니셜 글자 + 그라데이션 폴백(`community_home_page.dart`의 `_thumbFallback`)으로만 표시된다. 앨범을 만들 때 "대문(표지)"을 기본적으로 꾸밀 수 있게 하고, 나중에도 수정할 수 있게 한다.

## 결정된 방식: 하이브리드 (템플릿 + 선택적 커스텀 사진)

- 기본은 테마 템플릿(무료 스톡사진 배경) 중 하나를 고르는 것으로 시작 — 사진이 없어도 바로 예쁜 표지가 생긴다.
- 원하면 언제든 자신의 사진으로 교체할 수 있다.
- 표지 위에 제목/날짜 등 문구를 편집하는 기능은 넣지 않는다 (앨범 이름은 이미 상단바 등 기존 위치에 표시되므로 중복 방지, 스코프 최소화).

## 템플릿 목록 (10종, 무료 스톡사진 URL 하드코딩)

코드에 고정된 상수 목록으로 관리한다(DB 테이블 없음). 각 항목은 `templateId`(문자열 키) + 표시명 + 이미지 URL.

| templateId | 표시명 | 이미지 URL (Unsplash, `?w=` 파라미터로 리사이즈) |
|---|---|---|
| `wedding` | 결혼식 | `https://images.unsplash.com/photo-1519741497674-611481863552` |
| `reunion` | 동창회 | `https://images.unsplash.com/photo-1529156069898-49953e39b3ac` |
| `baby100` | 100일 기념 | `https://images.unsplash.com/photo-1511895426328-dc8714191300` |
| `party` | 파티 | `https://images.unsplash.com/photo-1530103862676-de8c9debad1d` |
| `yearend` | 망년회 | `https://images.unsplash.com/photo-1467810563316-b5476525c0f9` |
| `birthday` | 생일 | `https://images.unsplash.com/photo-1464349095431-e9a21285b5f3` |
| `travel` | 여행 | `https://images.unsplash.com/photo-1501785888041-af3ef285b470` |
| `family` | 가족모임 | `https://images.unsplash.com/photo-1516450360452-9312f5e86fc7` |
| `friends` | 친구모임 | `https://images.unsplash.com/photo-1543269865-cbf427effbad` |
| `couple` | 연애 | `https://images.unsplash.com/photo-1524504388940-b1c1722653e1` |

모든 URL은 `curl -o /dev/null -w '%{http_code}'`로 200 응답을 확인했다(2026-07-01 기준). **단, URL 도달 가능 여부만 확인했고 사진 내용이 테마와 실제로 어울리는지는 육안 확인이 필요하다 — 구현 단계에서 실제 화면으로 한 번씩 렌더링해서 부적절한 사진이 있으면 같은 표에서 교체한다.** (플레이스홀더가 아니라 정상 설계 산출물이며, 이 최종 확인 절차 자체가 구현 계획의 한 단계다.)

## 데이터 모델 변경

`tb_community`에 컬럼 1개 추가:

```sql
ALTER TABLE tb_community ADD COLUMN cover_template_id VARCHAR(20) NULL;
```

- 템플릿 선택 시: `cover_template_id = 'wedding'`, `image_url = <해당 템플릿의 스톡사진 URL>` 함께 저장.
- 커스텀 사진 업로드 시: `cover_template_id = NULL`, `image_url = <업로드된 사진 URL>`.
- 둘 다 비어있으면(레거시 앨범 또는 아무 것도 안 고른 경우): 기존 `_thumbFallback` 그라데이션 그대로 유지.
- `image_url`을 그대로 재사용하므로 허브 목록(`community_hub_page.dart`)·앨범 홈 리스트(`community_home_page.dart`의 `_thumb`)의 **기존 렌더링 코드는 수정 불필요**.
- `cover_template_id`는 "지금 선택된 템플릿이 무엇인지" UI에서 하이라이트하는 용도로만 쓰인다.

## 백엔드 API

새 엔드포인트 1개 추가 (`CommunityCtrl`/`CommunitySvc`, 기존 `@Operation` 번호 이어서 22번):

```
POST /community/updateCover
  파라미터: communityId (Long), coverTemplateId (String, nullable), imageUrl (String, nullable)
  권한: requireManager(communityId) 재사용 (방장+매니저)
  동작:
    - coverTemplateId가 있으면: 서버가 자체 템플릿 목록에서 URL을 찾아 image_url에 반영 (클라이언트가 보낸 imageUrl 무시 — 스푸핑 방지)
    - coverTemplateId가 없고 imageUrl만 있으면: image_url = imageUrl, cover_template_id = null
    - 유효하지 않은 coverTemplateId면 DefaultException
    - coverTemplateId와 imageUrl이 둘 다 없으면 DefaultException("표지 정보가 없습니다")
```

서버 쪽에도 템플릿 목록(10종)을 동일하게 상수로 둔다(프론트와 이중 관리이지만, 서버가 신뢰할 수 있는 URL만 저장하도록 하기 위한 최소한의 검증 장치 — 프론트가 보낸 imageUrl을 그대로 믿지 않음).

`CommunityVo.CreateReq`에는 이미 `imageUrl`, `spotId` 등이 있으므로 `coverTemplateId` 필드 하나만 추가하면 생성 시점에도 동일한 방식으로 재사용 가능(생성 자체는 기존 `/community/create` 그대로, 서비스 로직에서 coverTemplateId 검증 후 image_url 채우는 부분만 추가).

## 프론트 UI

### 1. 템플릿 피커 위젯 (신규, 공용 컴포넌트)
`lib/app/community/widget/cover_template_picker.dart` — 10개 템플릿을 사진 카드 그리드로 보여주고, 맨 마지막에 "직접 사진 선택" 카드 추가. 선택된 항목은 테두리 하이라이트.

### 2. 생성 화면 (`community_create_page.dart`)
템플릿 피커를 노출하고 **첫 번째 템플릿(`wedding`)이 기본 선택된 상태**로 시작 — 사용자가 아무것도 안 건드려도 표지가 채워진 채로 앨범이 생성된다("기본적으로 꾸밀 수 있다" 요구사항 충족). "직접 사진 선택"을 고르면 기존에 쓰던 이미지 업로드 유틸(프로필 사진 교체 등에서 쓰는 것과 동일한 방식)을 재사용해 업로드 후 URL을 받아온다.

### 3. 앨범 홈 (`community_home_page.dart`)
지금은 대문 배너 영역이 없다. AppBar 위에 커버 이미지를 보여주는 히어로 배너(예: `SliverAppBar` + `flexibleSpace`, 높이 180~200)를 신규 추가하고, 이미지가 없으면 기존 그라데이션 폴백을 배너 크기로 확대해서 사용한다. 방장/매니저에게만 배너 우측 상단에 "표지 수정" 아이콘 버튼을 노출 → 탭하면 템플릿 피커를 바텀시트로 띄워 `updateCover` 호출.

### 4. 허브 목록 / 검색 목록
`community_hub_page.dart`, `community_home_page.dart`의 기존 `_thumb`/`_thumbFallback`은 **변경 없음** — `imageUrl`을 그대로 그리고 있어 템플릿이든 커스텀 사진이든 자동으로 반영된다.

## 테스트 계획

- 백엔드: `updateCover`에 대해 (a) 방장/매니저가 아닌 일반 멤버가 호출 시 거부, (b) 존재하지 않는 coverTemplateId 거부, (c) 템플릿 선택 시 서버가 자체 URL로 덮어쓰는지(클라이언트가 다른 imageUrl을 보내도 무시되는지) 확인.
- 프론트: `flutter analyze` 0 에러, 생성 화면에서 기본 템플릿이 선택된 채 생성되는지, 앨범 홈 배너와 허브 썸네일에 동일한 이미지가 반영되는지 수동 확인.
- 지난 세션에 구축해 둔 3인 페르소나 QA 절차(운영 DB에 테스트 계정 생성 → API로 시나리오 실행 → 정리)를 재사용해 `updateCover` 권한 분기까지 검증 가능.
