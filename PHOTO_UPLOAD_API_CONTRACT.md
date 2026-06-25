# 📸 사진(다중) 업로드 기능 — 백엔드 API 계약서

> 작성: Flutter(kimi) / 대상: 백엔드 클로드 (`~/work/app/project1`, Spring Boot + PostgreSQL)
> 목적: 기존 "영상 게시"에 더해 **사진 여러 장을 한 게시물로 업로드/표시**하는 기능. 피드에서는 인스타그램식 가로 캐러셀로 표시.
> Flutter 측은 이 계약 기준으로 구현 완료. **백엔드가 아래 필드/분기만 추가하면 연동 완료됨.**

---

## 🚨 현재 상태(2026-06-25 실측) — 백엔드 미구현 확인

실제 업로드 후 피드 응답을 확인한 결과:
```
boardId=2929 typeDtCd=I imageUrls=null videoPath=null thumb=https://imagedelivery.net/.../d4098ecd.../public
```
- ✅ `typeDtCd='I'` 저장됨
- ✅ `thumbnailPath`(첫 사진 URL) 저장·반환됨  ← Flutter가 `thumbnailPath=imageUrls.first`로 보낸 값
- ❌ **`imageUrls`(전체 배열)는 저장/반환 안 됨** ← **백엔드 작업 필요**

**Flutter 임시 대응:** `imageUrls`가 비면 `thumbnailPath`(첫 사진)라도 캐러셀에 1장 표시하도록 폴백 적용함.
→ **백엔드가 아래 `imageUrls` 저장/반환을 구현하면, 여러 장이 자동으로 모두 표시됨.**

**백엔드가 해야 할 일(요약):** `/board/saveAll` 요청의 `boardWeatherVo.imageUrls`/`imageIds`(JSON 배열)를 저장하고, 피드/내글/상세 응답의 `BoardWeatherListData`에 `imageUrls`(배열)로 반환.

---

## 1. 핵심 개념: `typeDtCd`로 영상/사진 구분

기존 게시물은 `typeCd='V'`, `typeDtCd='V'`(영상). 사진 게시물은 다음으로 구분한다.

| 구분 | typeCd | typeDtCd | 미디어 필드 |
|------|--------|----------|-------------|
| 영상(기존) | `V` | `V` | `videoPath`, `videoId`, `thumbnailPath` |
| **사진(신규)** | `V` | **`I`** | **`imageUrls[]`, `imageIds[]`** (아래) |

> `typeCd`는 기존대로 `V` 유지(보드 대분류). 미디어 종류는 **`typeDtCd`** 로만 구분한다. (`V`=Video, `I`=Image)

---

## 2. 저장 API — `POST /board/saveAll`

요청 본문은 기존 `BoardSaveData` 구조 그대로. **사진일 때만 아래 필드가 채워진다.**

### 2-1. `boardMastInVo` (BoardSaveMainData)
```jsonc
{
  "typeCd": "V",
  "typeDtCd": "I",          // ★ 사진이면 "I"
  "contents": "캡션/해시태그",
  "anonyYn": "N",
  "hideYn": "N",
  "subject": "",
  "depthNo": "0"
}
```

### 2-2. `boardWeatherVo` (BoardSaveWeatherData) — 신규 필드 2개
```jsonc
{
  // 영상 필드(사진이면 null/미전송)
  "videoPath": null,
  "videoId": null,
  "thumbnailPath": null,
  "thumbnailId": null,

  // ★ 신규: 사진 다중 URL/ID (순서 = 게시물 내 사진 순서)
  "imageUrls": [
    "https://imagedelivery.net/xxxx/aaaa/public",
    "https://imagedelivery.net/xxxx/bbbb/public"
  ],
  "imageIds": ["aaaa", "bbbb"],

  // 날씨/위치 등 기존 필드는 영상과 동일하게 채워짐
  "lat": "...", "lon": "...", "location": "...", "feelCd": "...", "...": "..."
}
```

> **이미지 업로드 위치**: Flutter가 **Cloudflare Images**(`imageFileUpload`)로 각 사진을 먼저 업로드하고, 받은 delivery URL/ID 배열을 위처럼 보낸다. 백엔드는 **URL/ID 저장만** 하면 된다(이미지 바이너리 처리 불필요).

### 2-3. 백엔드 스키마 제안 (PostgreSQL)
- 가장 단순: 게시물 1:N 자식 테이블 `board_image(board_id, sort_no, image_url, image_id)`.
- 또는 PostgreSQL `text[]` / `jsonb` 컬럼으로 `image_urls`, `image_ids` 저장.
- 권장: **자식 테이블**(정렬·확장 용이). 저장 시 `imageUrls[i]`↔`imageIds[i]` 같은 index로 매핑, `sort_no=i`.

---

## 3. 피드 조회 API — 응답에 사진 배열 포함

피드 응답 모델 `BoardWeatherListData`에 **신규 필드 `imageUrls`(string[])** 추가.

```jsonc
{
  "boardId": 123,
  "typeCd": "V",
  "typeDtCd": "I",                 // ★ "I"면 Flutter가 캐러셀로 렌더
  "videoPath": null,
  "thumbnailPath": null,
  "imageUrls": [                    // ★ 신규: 사진 순서대로
    "https://imagedelivery.net/xxxx/aaaa/public",
    "https://imagedelivery.net/xxxx/bbbb/public"
  ],
  "contents": "캡션",
  "nickNm": "...", "likeCnt": 0, "replyCnt": 0, "...": "..."
  // 나머지 필드는 영상과 동일
}
```

- **영상 게시물**: 기존대로 `typeDtCd='V'`, `imageUrls`는 null/빈배열.
- **사진 게시물**: `typeDtCd='I'`, `videoPath` null, `imageUrls`에 1장 이상.
- 정렬/페이징/거리계산 등은 영상과 동일 로직 재사용.

---

## 4. 백엔드 체크리스트 (요약)

- [ ] `BoardSaveWeatherData`(요청 DTO)에 `List<String> imageUrls`, `List<String> imageIds` 추가
- [ ] `/board/saveAll`에서 `typeDtCd='I'`면 `imageUrls/imageIds`를 자식테이블/배열컬럼에 저장 (videoPath 계열은 null 허용)
- [ ] `BoardWeatherListData`(피드 응답 DTO)에 `List<String> imageUrls` 추가, 조회 시 사진 URL 채우기
- [ ] 피드/내 게시물/상세 등 게시물 반환하는 모든 쿼리에서 `imageUrls` 채우도록 매핑
- [ ] (선택) 삭제 시 Cloudflare 이미지 정리 필요하면 `imageIds`로 처리

---

## 5. Flutter 측 구현 범위 (참고)

- 카메라 화면: 영상/사진 모드 토글, 사진 다중 촬영, 갤러리 다중 선택
- `PhotoRegPage`: 가로 캐러셀 미리보기 + 캡션/feel/정책 + 게시하기
- 업로드: `cloudflare.imageFileUpload()` 병렬 → URL/ID 수집 → 위 계약대로 `/board/saveAll`
- 피드: `typeDtCd='I'`면 `imageUrls`로 가로 캐러셀(점 인디케이터) 렌더, 아니면 기존 VideoPlayer
