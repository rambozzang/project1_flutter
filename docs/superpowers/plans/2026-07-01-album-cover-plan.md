# 앨범 표지 꾸미기 (Cover Template) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 앨범(커뮤니티) 생성/수정 시 테마 템플릿(10종, 무료 스톡사진) 또는 직접 업로드한 사진으로 표지("대문")를 꾸밀 수 있게 한다.

**Architecture:** 백엔드는 `tb_community.image_url`(기존 컬럼)을 그대로 재사용하고 `cover_template_id`(신규, 어떤 템플릿을 골랐는지 기록용) 컬럼 하나만 추가한다. 템플릿 목록은 DB 테이블 없이 백엔드·프론트 양쪽에 동일한 상수로 하드코딩한다(서버가 클라이언트의 imageUrl을 신뢰하지 않고 자체 목록에서 URL을 재검증/치환 — 스푸핑 방지). 신규 API `POST /community/updateCover` 하나만 추가하면 끝.

**Tech Stack:** Spring Boot 3.2.3 / Java 17 / PostgreSQL (백엔드), Flutter / Dio / GetX / `image_picker` + `cloudflare` 패키지(프론트, 기존 사진 업로드 방식 재사용).

**참고 스펙 문서:** `docs/superpowers/specs/2026-07-01-album-cover-design.md`

---

## 배경 컨텍스트 (이 플랜을 실행하는 엔지니어가 알아야 할 것)

- 이 저장소는 프론트(`~/work/app/flutter/project1`, 현재 위치)와 백엔드(`~/work/app/project1`, **완전히 별도의 git 저장소**) 2개로 구성된다.
- 백엔드는 로컬에서 실행/테스트할 수 있는 dev DB가 방화벽으로 막혀있어, 지난 세션 관례상 **운영 DB에 직접 마이그레이션/테스트 데이터를 넣고 API로 검증 후 정리**하는 방식을 쓴다. 운영 DB 접속: `mcp__ssh-manager__ssh_execute` 도구로 서버 `oracle`에 접속해 `PGPASSWORD='skysnap1234!' psql -h 127.0.0.1 -p 54332 -U skysnap -d skysnap -c "..."` 실행.
- 운영 API 베이스 URL: `https://skysnap.co.kr/api`. 인증은 `Authorization: Bearer <JWT>` + `Device-ID: <아무 문자열>` 헤더 필요(JwtFilter가 `device_id` 컬럼과 대조하며, 계정의 `device_id`가 null이면 500 에러가 나므로 테스트 계정은 반드시 device_id를 채워야 함). 테스트용 JWT는 `GET /auth/gettoken/{custId}`(인증 불필요, "Test AccessToken 발급"용 엔드포인트)로 발급받는다.
- **백엔드 `main` 브랜치로의 `git push`는 Jenkins가 즉시 운영서버에 자동배포한다.** 이 플랜의 마지막 태스크(커밋)까지만 수행하고, `main` 브랜치 merge/push는 사용자에게 확인받은 뒤 진행한다(자동으로 push하지 않는다).
- 기존 컨벤션: 컨트롤러는 `try { ResData.SUCCESS(...) } catch (Exception e) { log.error(...); return ResData.FAIL(...); }` 패턴, 권한 체크는 `CommunitySvc.requireManager(communityId)`(방장 또는 매니저만 통과, 아니면 `DefaultException`) 재사용. `@Operation(summary="NN...")` 번호는 현재 21까지 사용 중이므로 22부터 이어붙인다.

---

## Task 1: 백엔드 — DB 마이그레이션 (cover_template_id 컬럼)

**Files:**
- Create: `~/work/app/project1/db_migration_community_cover.sql`

- [ ] **Step 1: 마이그레이션 SQL 파일 작성**

```sql
-- 앨범 표지 꾸미기: cover_template_id 컬럼 추가
-- 실행 환경: PostgreSQL (운영 DB, schema: skysnap)
-- 실행: PGPASSWORD='skysnap1234!' psql -h 127.0.0.1 -p 54332 -U skysnap -d skysnap -f db_migration_community_cover.sql (또는 -c로 직접 실행)

ALTER TABLE tb_community ADD COLUMN IF NOT EXISTS cover_template_id VARCHAR(20) NULL;
```

- [ ] **Step 2: 운영 DB에 마이그레이션 적용**

`mcp__ssh-manager__ssh_execute` 도구로 서버 `oracle`에서 실행:

```bash
PGPASSWORD='skysnap1234!' psql -h 127.0.0.1 -p 54332 -U skysnap -d skysnap -c "ALTER TABLE tb_community ADD COLUMN IF NOT EXISTS cover_template_id VARCHAR(20) NULL;"
```

Expected: `ALTER TABLE` 출력, 에러 없음.

- [ ] **Step 3: 컬럼 반영 확인**

```bash
PGPASSWORD='skysnap1234!' psql -h 127.0.0.1 -p 54332 -U skysnap -d skysnap -c "SELECT column_name, is_nullable, data_type FROM information_schema.columns WHERE table_name='tb_community' AND column_name='cover_template_id';"
```

Expected: 1 row, `cover_template_id | YES | character varying`.

- [ ] **Step 4: 커밋**

```bash
cd ~/work/app/project1
git add db_migration_community_cover.sql
git commit -m "[앨범] 표지 꾸미기 - cover_template_id 컬럼 마이그레이션 SQL"
```

---

## Task 2: 백엔드 — 표지 템플릿 상수 클래스

**Files:**
- Create: `~/work/app/project1/src/main/java/com/tigerbk/project1/biz/community/CommunityCoverTemplates.java`

- [ ] **Step 1: 템플릿 레지스트리 클래스 작성**

```java
package com.tigerbk.project1.biz.community;

import java.util.LinkedHashMap;
import java.util.Map;

/**
 * 앨범 표지 템플릿(테마별 무료 스톡사진) 고정 목록.
 * DB 테이블 없이 서버 코드에 하드코딩 — 프론트(cover_template.dart)와 동일한 templateId·URL을 유지해야 한다.
 * 클라이언트가 보낸 imageUrl을 그대로 믿지 않고, coverTemplateId가 있으면 여기서 URL을 재조회해 덮어쓴다(스푸핑 방지).
 */
public final class CommunityCoverTemplates {

    private CommunityCoverTemplates() {
    }

    private static final Map<String, String> TEMPLATES = new LinkedHashMap<>();

    static {
        TEMPLATES.put("wedding", "https://images.unsplash.com/photo-1519741497674-611481863552");
        TEMPLATES.put("reunion", "https://images.unsplash.com/photo-1529156069898-49953e39b3ac");
        TEMPLATES.put("baby100", "https://images.unsplash.com/photo-1511895426328-dc8714191300");
        TEMPLATES.put("party", "https://images.unsplash.com/photo-1530103862676-de8c9debad1d");
        TEMPLATES.put("yearend", "https://images.unsplash.com/photo-1467810563316-b5476525c0f9");
        TEMPLATES.put("birthday", "https://images.unsplash.com/photo-1464349095431-e9a21285b5f3");
        TEMPLATES.put("travel", "https://images.unsplash.com/photo-1501785888041-af3ef285b470");
        TEMPLATES.put("family", "https://images.unsplash.com/photo-1516450360452-9312f5e86fc7");
        TEMPLATES.put("friends", "https://images.unsplash.com/photo-1543269865-cbf427effbad");
        TEMPLATES.put("couple", "https://images.unsplash.com/photo-1524504388940-b1c1722653e1");
    }

    public static boolean isValid(String templateId) {
        return templateId != null && TEMPLATES.containsKey(templateId);
    }

    public static String resolveUrl(String templateId) {
        return TEMPLATES.get(templateId);
    }
}
```

- [ ] **Step 2: 컴파일 확인**

```bash
cd ~/work/app/project1 && ./gradlew compileJava -q
```

Expected: 에러 없이 종료(exit code 0).

- [ ] **Step 3: 커밋**

```bash
git add src/main/java/com/tigerbk/project1/biz/community/CommunityCoverTemplates.java
git commit -m "[앨범] 표지 꾸미기 - 템플릿 레지스트리(10종) 추가"
```

---

## Task 3: 백엔드 — 엔티티/VO 필드 추가

**Files:**
- Modify: `~/work/app/project1/src/main/java/com/tigerbk/project1/entity/TbCommunity.java`
- Modify: `~/work/app/project1/src/main/java/com/tigerbk/project1/biz/community/vo/CommunityVo.java`

- [ ] **Step 1: `TbCommunity`에 필드 추가**

`invite_code` 필드 바로 아래(파일 맨 끝, `crtDtm` 필드 위)에 추가:

```java
    // 표지 템플릿 ID(선택). 커스텀 사진을 쓰면 NULL, image_url만 채워짐.
    @Column(name = "cover_template_id", length = 20)
    private String coverTemplateId;
```

- [ ] **Step 2: `CommunityVo.CreateReq`에 필드 추가**

```java
    public static class CreateReq {
        private String name;
        private String description;
        private String imageUrl;
        private String coverTemplateId; // 선택: 표지 템플릿 ID (예: "wedding"). 있으면 imageUrl은 서버가 덮어씀.
        private Long spotId;        // 선택
        private String isPublic;    // Y/N (기본 Y)
        private String joinType;    // AUTO/APPROVAL (기본 AUTO)
        private Double lat;
        private Double lon;
    }
```

- [ ] **Step 3: `CommunityVo.CommunityItem`에 필드 추가**

```java
    public static class CommunityItem {
        private Long communityId;
        private String name;
        private String description;
        private String imageUrl;
        private String coverTemplateId; // 현재 선택된 템플릿(없으면 커스텀 사진이거나 미설정)
        private String ownerCustId;
        private Long spotId;
        private String isPublic;
        private String joinType;
        private int memberCnt;
        private String crtDtm;
        // 뷰어 기준
        private String myStatus;   // JOINED / PENDING / null(미가입)
        private boolean isOwner;
        private boolean isManager; // 방장 포함(방장도 true) — 표지 수정 등 매니저 권한 UI 노출용
    }
```

- [ ] **Step 4: 컴파일 확인** (아직 `toItem()`에서 새 필드를 안 채워도 컴파일은 된다 — 다음 태스크에서 채운다)

```bash
cd ~/work/app/project1 && ./gradlew compileJava -q
```

Expected: 에러 없이 종료.

- [ ] **Step 5: 커밋**

```bash
git add src/main/java/com/tigerbk/project1/entity/TbCommunity.java src/main/java/com/tigerbk/project1/biz/community/vo/CommunityVo.java
git commit -m "[앨범] 표지 꾸미기 - 엔티티/VO에 coverTemplateId, isManager 필드 추가"
```

---

## Task 4: 백엔드 — CommunitySvc 로직 (생성 시 템플릿 반영 + updateCover + isManager 노출)

**Files:**
- Modify: `~/work/app/project1/src/main/java/com/tigerbk/project1/biz/community/svc/CommunitySvc.java`

- [ ] **Step 1: import 추가**

파일 상단 import 블록에 추가:

```java
import com.tigerbk.project1.biz.community.CommunityCoverTemplates;
```

- [ ] **Step 2: `create()`에서 coverTemplateId 검증 및 image_url 반영**

기존 `create()` 메서드를 아래로 교체(`TbCommunity c = TbCommunity.builder()...build();` 부분 전체):

```java
    @Transactional
    public Long create(CommunityVo.CreateReq req) {
        if (req.getName() == null || req.getName().trim().isEmpty()) {
            throw new DefaultException("앨범명을 입력해주세요.");
        }
        String me = viewer();
        String coverTemplateId = req.getCoverTemplateId();
        String resolvedImageUrl = req.getImageUrl();
        if (coverTemplateId != null && !coverTemplateId.isEmpty()) {
            if (!CommunityCoverTemplates.isValid(coverTemplateId)) {
                throw new DefaultException("존재하지 않는 표지 템플릿입니다.");
            }
            resolvedImageUrl = CommunityCoverTemplates.resolveUrl(coverTemplateId);
        }
        TbCommunity c = TbCommunity.builder()
                .name(req.getName().trim())
                .description(req.getDescription())
                .imageUrl(resolvedImageUrl)
                .coverTemplateId(coverTemplateId)
                .ownerCustId(me)
                .spotId(req.getSpotId())
                .isPublic(req.getIsPublic() == null ? "Y" : req.getIsPublic())
                .joinType(req.getJoinType() == null ? "AUTO" : req.getJoinType())
                .memberCnt(1)
                .lat(req.getLat()).lon(req.getLon())
                .useYn("Y")
                .crtDtm(LocalDateTime.now())
                .build();
        Long id = communityRepository.save(c).getCommunityId();

        memberRepository.save(TbCommunityMember.builder()
                .communityId(id).custId(me).role("OWNER").status("JOINED")
                .joinedAt(LocalDateTime.now()).build());
        return id;
    }
```

- [ ] **Step 3: `updateCover()` 신규 메서드 추가**

`// ───────────────────────── 매니저 지정/해제 · 강퇴 ─────────────────────────` 섹션 바로 위에 새 섹션으로 추가:

```java
    // ───────────────────────── 표지 꾸미기 ─────────────────────────

    /**
     * 앨범 표지 수정(템플릿 또는 커스텀 사진, 방장/매니저만 가능).
     * coverTemplateId가 있으면 서버가 자체 템플릿 목록에서 URL을 찾아 image_url에 반영한다
     * (클라이언트가 보낸 imageUrl은 이 경우 무시 — 스푸핑 방지).
     */
    @Transactional
    public void updateCover(Long communityId, String coverTemplateId, String imageUrl) {
        TbCommunity c = requireManager(communityId);
        if (coverTemplateId != null && !coverTemplateId.isEmpty()) {
            if (!CommunityCoverTemplates.isValid(coverTemplateId)) {
                throw new DefaultException("존재하지 않는 표지 템플릿입니다.");
            }
            c.setCoverTemplateId(coverTemplateId);
            c.setImageUrl(CommunityCoverTemplates.resolveUrl(coverTemplateId));
        } else if (imageUrl != null && !imageUrl.isEmpty()) {
            c.setCoverTemplateId(null);
            c.setImageUrl(imageUrl);
        } else {
            throw new DefaultException("표지 정보가 없습니다.");
        }
        communityRepository.save(c);
    }

```

- [ ] **Step 4: `isManagerViewer()` 헬퍼 추가 + `toItem()`에 반영**

`requireManager()` 메서드 바로 아래에 헬퍼 추가:

```java
    /** 방장 또는 매니저인지(예외 안 던지고 boolean만 반환) — CommunityItem.isManager 채우는 용도 */
    private boolean isManagerViewer(TbCommunity c, String viewerCustId) {
        if (viewerCustId.equals(c.getOwnerCustId())) return true;
        return memberRepository.findByCommunityIdAndCustId(c.getCommunityId(), viewerCustId)
                .map(m -> "MANAGER".equals(m.getRole())).orElse(false);
    }
```

`toItem()` 메서드를 아래로 교체:

```java
    private CommunityVo.CommunityItem toItem(TbCommunity c, String viewer) {
        return CommunityVo.CommunityItem.builder()
                .communityId(c.getCommunityId()).name(c.getName()).description(c.getDescription())
                .imageUrl(c.getImageUrl()).coverTemplateId(c.getCoverTemplateId())
                .ownerCustId(c.getOwnerCustId()).spotId(c.getSpotId())
                .isPublic(c.getIsPublic()).joinType(c.getJoinType())
                .memberCnt(c.getMemberCnt() == null ? 0 : c.getMemberCnt())
                .crtDtm(c.getCrtDtm() == null ? null : c.getCrtDtm().format(DTM))
                .myStatus(myStatus(c.getCommunityId(), viewer))
                .isOwner(viewer.equals(c.getOwnerCustId()))
                .isManager(isManagerViewer(c, viewer))
                .build();
    }
```

- [ ] **Step 5: 컴파일 확인**

```bash
cd ~/work/app/project1 && ./gradlew compileJava -q
```

Expected: 에러 없이 종료.

- [ ] **Step 6: 커밋**

```bash
git add src/main/java/com/tigerbk/project1/biz/community/svc/CommunitySvc.java
git commit -m "[앨범] 표지 꾸미기 - CommunitySvc.updateCover + 생성 시 템플릿 반영 + isManager 노출"
```

---

## Task 5: 백엔드 — updateCover API 엔드포인트

**Files:**
- Modify: `~/work/app/project1/src/main/java/com/tigerbk/project1/biz/community/ctrl/CommunityCtrl.java`

- [ ] **Step 1: 엔드포인트 추가**

파일 맨 끝, `getSpotRanking()` 메서드 다음(마지막 `}` 앞)에 추가:

```java

    @Operation(summary = "22.앨범 표지 수정 (템플릿 또는 커스텀 사진, 방장/매니저)")
    @PostMapping("/community/updateCover")
    public ResponseEntity<?> updateCover(@RequestParam("communityId") Long communityId,
                                         @RequestParam(value = "coverTemplateId", required = false) String coverTemplateId,
                                         @RequestParam(value = "imageUrl", required = false) String imageUrl) {
        try {
            communitySvc.updateCover(communityId, coverTemplateId, imageUrl);
            return ResData.SUCCESS(true, "표지를 변경했습니다.");
        } catch (Exception e) {
            log.error(e.getMessage(), e);
            return ResData.FAIL(e.getMessage());
        }
    }
```

- [ ] **Step 2: 컴파일 확인**

```bash
cd ~/work/app/project1 && ./gradlew compileJava -q
```

Expected: 에러 없이 종료.

- [ ] **Step 3: 커밋**

```bash
git add src/main/java/com/tigerbk/project1/biz/community/ctrl/CommunityCtrl.java
git commit -m "[앨범] 표지 꾸미기 - POST /community/updateCover 엔드포인트 추가"
```

---

## Task 6: 백엔드 — 운영 API 수동 검증 (배포 전 로컬 컴파일만으로는 API 동작을 확인할 수 없으므로, 배포 후 3인 페르소나로 실제 확인)

이 태스크는 **Task 5까지 커밋 후 사용자가 backend main에 merge/push(=운영 배포)한 뒤에** 실행한다. push 여부는 사용자에게 확인받는다.

**Files:** 없음(API 호출만)

- [ ] **Step 1: 테스트 계정 1개 생성 + JWT 발급**

`mcp__ssh-manager__ssh_execute`로 서버 `oracle`에서:

```bash
PGPASSWORD='skysnap1234!' psql -h 127.0.0.1 -p 54332 -U skysnap -d skysnap -c "INSERT INTO tb_cust_master (cust_id, nick_nm, provider, role, device_id) VALUES ('qatest_cover','표지테스트','GOOGLE','USER','qatest-device') RETURNING cust_id;"
```

```bash
curl -s "https://skysnap.co.kr/api/auth/gettoken/qatest_cover"
```

Expected: `{"code":"00",...,"data":"<JWT>"}` — 이 JWT를 이후 단계에서 `$TOKEN`으로 사용.

- [ ] **Step 2: 템플릿으로 앨범 생성 (기본 템플릿 반영 확인)**

```bash
curl -s -X POST "https://skysnap.co.kr/api/community/create" \
  -H "Authorization: Bearer $TOKEN" -H "Device-ID: qatest-device" -H "Content-Type: application/json" \
  -d '{"name":"표지테스트앨범","coverTemplateId":"wedding","isPublic":"Y","joinType":"AUTO"}'
```

Expected: `{"code":"00",...,"data":<communityId>}`. 이 communityId를 `$CID`로 사용.

```bash
curl -s "https://skysnap.co.kr/api/community/detail?communityId=$CID" -H "Authorization: Bearer $TOKEN" -H "Device-ID: qatest-device"
```

Expected: 응답 `data.coverTemplateId == "wedding"`, `data.imageUrl == "https://images.unsplash.com/photo-1519741497674-611481863552"`, `data.isManager == true`(방장이므로).

- [ ] **Step 3: updateCover로 다른 템플릿으로 교체 (+ 클라이언트가 보낸 imageUrl이 무시되는지 확인)**

```bash
curl -s -X POST "https://skysnap.co.kr/api/community/updateCover?communityId=$CID&coverTemplateId=party&imageUrl=https://evil.example.com/spoofed.jpg" \
  -H "Authorization: Bearer $TOKEN" -H "Device-ID: qatest-device"
```

Expected: `{"code":"00","msg":"표지를 변경했습니다.",...}`. 이후 `/community/detail`로 재조회해 `coverTemplateId=="party"`이고 `imageUrl`이 `https://images.unsplash.com/photo-1467810563316-b5476525c0f9`(party 템플릿의 서버측 URL)인지 확인 — `evil.example.com` 값이 무시되고 서버가 자체 URL로 덮어썼어야 한다.

- [ ] **Step 4: 존재하지 않는 템플릿 거부 확인**

```bash
curl -s -X POST "https://skysnap.co.kr/api/community/updateCover?communityId=$CID&coverTemplateId=notexist" \
  -H "Authorization: Bearer $TOKEN" -H "Device-ID: qatest-device"
```

Expected: `{"code":"99","msg":"존재하지 않는 표지 템플릿입니다.",...}` (코드는 `DefaultException` 처리 관례에 따름).

- [ ] **Step 5: 일반 멤버가 updateCover 시도 시 거부 확인**

테스트 계정 2개(`qatest_cover2`)를 Step 1과 같은 방식으로 추가 생성 → `/community/join?communityId=$CID`로 가입(MEMBER) → 그 계정의 JWT로 updateCover 호출.

```bash
curl -s -X POST "https://skysnap.co.kr/api/community/updateCover?communityId=$CID&coverTemplateId=family" \
  -H "Authorization: Bearer $TOKEN2" -H "Device-ID: qatest-device"
```

Expected: `{"code":"99","msg":"방장/매니저만 가능합니다.",...}`.

- [ ] **Step 6: 테스트 데이터 정리**

```bash
PGPASSWORD='skysnap1234!' psql -h 127.0.0.1 -p 54332 -U skysnap -d skysnap -c "
DELETE FROM tb_community_member WHERE community_id = $CID;
DELETE FROM tb_community WHERE community_id = $CID;
DELETE FROM tb_cust_master WHERE cust_id IN ('qatest_cover','qatest_cover2');
"
```

Expected: 각 DELETE 결과 행 수 출력, 이후 `SELECT count(*) FROM tb_cust_master WHERE cust_id LIKE 'qatest_cover%'`로 0 확인.

---

## Task 7: 프론트 — CommunityData 모델에 coverTemplateId / isManager 추가

**Files:**
- Modify: `/Users/bumkyuchun/work/app/flutter/project1/lib/repo/community/data/community_data.dart`

- [ ] **Step 1: 필드 추가**

클래스 필드 선언부(`final bool isOwner;` 다음 줄)에 추가:

```dart
  final String? coverTemplateId;
  final bool isManager; // 방장 포함 true — 표지 수정 등 매니저 권한 UI 노출용
```

생성자 파라미터에도 추가:

```dart
  CommunityData({
    required this.communityId,
    required this.name,
    this.description,
    this.imageUrl,
    this.coverTemplateId,
    this.ownerCustId,
    this.spotId,
    this.isPublic = 'Y',
    this.joinType = 'AUTO',
    this.memberCnt = 0,
    this.crtDtm,
    this.myStatus,
    this.isOwner = false,
    this.isManager = false,
  });
```

- [ ] **Step 2: getter 추가 및 fromMap 반영**

`bool get isApproval => joinType == 'APPROVAL';` 다음 줄에 추가:

```dart
  bool get canEditCover => isOwner || isManager;
```

`fromMap` 팩토리에 추가(`isOwner:` 라인 다음):

```dart
      coverTemplateId: map['coverTemplateId']?.toString(),
      isManager: (map['isManager'] ?? map['owner'] ?? map['isOwner'] ?? false) == true,
```

(참고: 방장은 백엔드에서도 `isManager=true`로 내려주지만, 혹시 몰라 `owner`/`isOwner` 키도 방어적으로 함께 체크 — 기존 `isOwner` 파싱 시 Jackson 직렬화 키 이슈를 방어한 것과 동일한 패턴.)

- [ ] **Step 3: `flutter analyze` 확인**

```bash
cd /Users/bumkyuchun/work/app/flutter/project1 && flutter analyze lib/repo/community/data/community_data.dart
```

Expected: `No issues found!` 또는 기존에 있던 것과 동일한 info성 경고만 존재.

- [ ] **Step 4: 커밋**

```bash
git add lib/repo/community/data/community_data.dart
git commit -m "[앨범] 표지 꾸미기 - CommunityData에 coverTemplateId/isManager 추가"
```

---

## Task 8: 프론트 — CommunityRepo에 updateCover 추가 + create()에 coverTemplateId 반영

**Files:**
- Modify: `/Users/bumkyuchun/work/app/flutter/project1/lib/repo/community/community_repo.dart`

- [ ] **Step 1: `create()` 시그니처에 `coverTemplateId` 추가**

기존 `create()` 메서드를 아래로 교체:

```dart
  /// 모임 생성. 성공 시 (true, 메시지, communityId).
  Future<(bool, String, int?)> create({
    required String name,
    String? description,
    String? imageUrl,
    String? coverTemplateId,
    int? spotId,
    String isPublic = 'Y',
    String joinType = 'AUTO',
    double? lat,
    double? lon,
  }) async {
    try {
      final dio = await AuthDio.instance.getDio();
      final res = await dio.post('${UrlConfig.baseURL}/community/create', data: {
        'name': name,
        'description': description,
        'imageUrl': imageUrl,
        'coverTemplateId': coverTemplateId,
        'spotId': spotId,
        'isPublic': isPublic,
        'joinType': joinType,
        'lat': lat,
        'lon': lon,
      });
      final resData = AuthDio.instance.dioResponse(res);
      final ok = resData.code == '00';
      final id = ok && resData.data != null ? (resData.data as num).toInt() : null;
      return (ok, resData.msg?.toString() ?? '', id);
    } catch (e) {
      lo.g('CommunityRepo.create error: $e');
      return (false, '모임 생성 중 오류가 발생했습니다: $e', null);
    }
  }
```

- [ ] **Step 2: `updateCover()` 메서드 추가**

파일 맨 끝, 클래스 닫는 `}` 바로 위에 추가:

```dart

  /// 표지 수정(템플릿 또는 커스텀 사진, 방장/매니저). coverTemplateId가 있으면 imageUrl은 무시됨(서버가 재검증).
  Future<(bool, String)> updateCover(int communityId, {String? coverTemplateId, String? imageUrl}) async {
    try {
      final dio = await AuthDio.instance.getDio();
      final res = await dio.post('${UrlConfig.baseURL}/community/updateCover', queryParameters: {
        'communityId': communityId,
        if (coverTemplateId != null) 'coverTemplateId': coverTemplateId,
        if (imageUrl != null) 'imageUrl': imageUrl,
      });
      final resData = AuthDio.instance.dioResponse(res);
      return (resData.code == '00', resData.msg?.toString() ?? '');
    } catch (e) {
      lo.g('CommunityRepo.updateCover error: $e');
      return (false, '표지 변경 중 오류가 발생했습니다: $e');
    }
  }
```

- [ ] **Step 3: `flutter analyze` 확인**

```bash
cd /Users/bumkyuchun/work/app/flutter/project1 && flutter analyze lib/repo/community/community_repo.dart
```

Expected: `No issues found!`

- [ ] **Step 4: 커밋**

```bash
git add lib/repo/community/community_repo.dart
git commit -m "[앨범] 표지 꾸미기 - CommunityRepo.updateCover 추가 + create() coverTemplateId 반영"
```

---

## Task 9: 프론트 — 표지 템플릿 데이터 + 업로드 유틸

**Files:**
- Create: `/Users/bumkyuchun/work/app/flutter/project1/lib/app/community/widget/cover_template.dart`

- [ ] **Step 1: 파일 작성**

```dart
import 'dart:io';

import 'package:cloudflare/cloudflare.dart';
import 'package:image_picker/image_picker.dart';
import 'package:project1/repo/cloudflare/cloudflare_repo.dart';
import 'package:project1/utils/log_utils.dart';
import 'package:project1/utils/utils.dart';

/// 앨범 표지 템플릿 1개(테마 + 무료 스톡사진). 백엔드 CommunityCoverTemplates와 templateId·URL을 동일하게 유지해야 한다.
class CoverTemplate {
  const CoverTemplate(this.id, this.label, this.imageUrl);

  final String id;
  final String label;
  final String imageUrl;
}

/// 표지 템플릿 10종(순서 중요 — 첫 항목이 앨범 생성 시 기본 선택값).
const List<CoverTemplate> kCoverTemplates = [
  CoverTemplate('wedding', '결혼식', 'https://images.unsplash.com/photo-1519741497674-611481863552'),
  CoverTemplate('reunion', '동창회', 'https://images.unsplash.com/photo-1529156069898-49953e39b3ac'),
  CoverTemplate('baby100', '100일 기념', 'https://images.unsplash.com/photo-1511895426328-dc8714191300'),
  CoverTemplate('party', '파티', 'https://images.unsplash.com/photo-1530103862676-de8c9debad1d'),
  CoverTemplate('yearend', '망년회', 'https://images.unsplash.com/photo-1467810563316-b5476525c0f9'),
  CoverTemplate('birthday', '생일', 'https://images.unsplash.com/photo-1464349095431-e9a21285b5f3'),
  CoverTemplate('travel', '여행', 'https://images.unsplash.com/photo-1501785888041-af3ef285b470'),
  CoverTemplate('family', '가족모임', 'https://images.unsplash.com/photo-1516450360452-9312f5e86fc7'),
  CoverTemplate('friends', '친구모임', 'https://images.unsplash.com/photo-1543269865-cbf427effbad'),
  CoverTemplate('couple', '연애', 'https://images.unsplash.com/photo-1524504388940-b1c1722653e1'),
];

/// 갤러리에서 사진을 골라 Cloudflare에 업로드하고 URL을 반환한다.
/// 사용자가 취소하거나 업로드에 실패하면 null을 반환한다(에러는 Utils.alert로 이미 표시됨).
/// (myinfo_page.dart의 프로필 사진 업로드와 동일한 방식 재사용 — 크롭 단계는 생략해 범위를 최소화함.)
Future<String?> pickAndUploadCoverPhoto() async {
  final picker = ImagePicker();
  final XFile? pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
  if (pickedFile == null) return null;

  final File file = File(pickedFile.path);
  final CloudflareRepo cloudflare = CloudflareRepo();
  await cloudflare.init();
  final CloudflareHTTPResponse<CloudflareImage?>? res = await cloudflare.imageFileUpload(file);
  if (res?.isSuccessful != true) {
    Utils.alert('사진 업로드에 실패했습니다.');
    return null;
  }
  lo.g('표지 사진 업로드 성공: ${res?.body?.toString()}');
  return res!.body!.variants[0].toString();
}
```

- [ ] **Step 2: `flutter analyze` 확인**

```bash
cd /Users/bumkyuchun/work/app/flutter/project1 && flutter analyze lib/app/community/widget/cover_template.dart
```

Expected: `No issues found!`

- [ ] **Step 3: 커밋**

```bash
git add lib/app/community/widget/cover_template.dart
git commit -m "[앨범] 표지 꾸미기 - 템플릿 목록(10종) + 사진 업로드 유틸 추가"
```

---

## Task 10: 프론트 — CoverTemplatePicker 위젯

**Files:**
- Create: `/Users/bumkyuchun/work/app/flutter/project1/lib/app/community/widget/cover_template_picker.dart`

- [ ] **Step 1: 파일 작성**

```dart
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'cover_template.dart';

/// 표지 템플릿 그리드 + "직접 사진 선택" 카드.
/// 선택 상태 관리는 부모(Stateful) 위젯이 가지고, 이 위젯은 순수 표시 + 콜백만 담당한다.
class CoverTemplatePicker extends StatelessWidget {
  const CoverTemplatePicker({
    super.key,
    required this.selectedTemplateId,
    required this.isCustomPhotoSelected,
    required this.onSelectTemplate,
    required this.onPickCustomPhoto,
  });

  /// 현재 선택된 템플릿 id (커스텀 사진을 선택했으면 null)
  final String? selectedTemplateId;
  final bool isCustomPhotoSelected;
  final ValueChanged<String> onSelectTemplate;
  final VoidCallback onPickCustomPhoto;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 0.85,
      children: [
        ...kCoverTemplates.map((t) => _templateCard(t)),
        _customPhotoCard(),
      ],
    );
  }

  Widget _templateCard(CoverTemplate t) {
    final selected = !isCustomPhotoSelected && selectedTemplateId == t.id;
    return GestureDetector(
      onTap: () => onSelectTemplate(t.id),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: selected ? const Color(0xFF3B6FE0) : Colors.transparent, width: 3),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            CachedNetworkImage(
              imageUrl: '${t.imageUrl}?w=200',
              fit: BoxFit.cover,
              errorWidget: (_, __, ___) => Container(color: const Color(0xFFE6E8EF)),
            ),
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.transparent, Colors.black54],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
            Positioned(
              left: 6, right: 6, bottom: 6,
              child: Text(t.label,
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
            ),
            if (selected)
              const Positioned(
                top: 6, right: 6,
                child: Icon(Icons.check_circle, color: Color(0xFF3B6FE0), size: 20),
              ),
          ],
        ),
      ),
    );
  }

  Widget _customPhotoCard() {
    return GestureDetector(
      onTap: onPickCustomPhoto,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: const Color(0xFFF1F3F8),
          border: Border.all(color: isCustomPhotoSelected ? const Color(0xFF3B6FE0) : const Color(0xFFE6E8EF), width: isCustomPhotoSelected ? 3 : 1),
        ),
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add_photo_alternate_outlined, color: isCustomPhotoSelected ? const Color(0xFF3B6FE0) : const Color(0xFF7A8291), size: 26),
            const SizedBox(height: 4),
            Text('직접 사진 선택', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isCustomPhotoSelected ? const Color(0xFF3B6FE0) : const Color(0xFF7A8291))),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: `flutter analyze` 확인**

```bash
cd /Users/bumkyuchun/work/app/flutter/project1 && flutter analyze lib/app/community/widget/cover_template_picker.dart
```

Expected: `No issues found!`

- [ ] **Step 3: 커밋**

```bash
git add lib/app/community/widget/cover_template_picker.dart
git commit -m "[앨범] 표지 꾸미기 - CoverTemplatePicker 위젯 추가"
```

---

## Task 11: 프론트 — 앨범 생성 화면에 표지 선택 통합

**Files:**
- Modify: `/Users/bumkyuchun/work/app/flutter/project1/lib/app/community/community_create_page.dart`

- [ ] **Step 1: import 추가**

파일 상단 import 블록에 추가:

```dart
import 'package:project1/app/community/widget/cover_template.dart';
import 'package:project1/app/community/widget/cover_template_picker.dart';
```

- [ ] **Step 2: 표지 관련 state 필드 추가**

`bool _saving = false;` 다음 줄에 추가:

```dart

  // 표지 (기본: 첫 템플릿이 선택된 상태로 시작)
  String? _coverTemplateId = kCoverTemplates.first.id;
  String? _customCoverUrl;
  bool _uploadingCover = false;
```

- [ ] **Step 3: 표지 선택 핸들러 메서드 추가**

`_clearSpot()` 메서드 다음에 추가:

```dart

  void _selectTemplate(String templateId) {
    setState(() {
      _coverTemplateId = templateId;
      _customCoverUrl = null;
    });
  }

  Future<void> _pickCustomCover() async {
    setState(() => _uploadingCover = true);
    final url = await pickAndUploadCoverPhoto();
    if (!mounted) return;
    setState(() {
      _uploadingCover = false;
      if (url != null) {
        _customCoverUrl = url;
        _coverTemplateId = null;
      }
    });
  }
```

- [ ] **Step 4: `_submit()`에 표지 정보 반영**

`_repo.create(` 호출 부분을 아래로 교체:

```dart
    final (ok, msg, _) = await _repo.create(
      name: name,
      description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
      isPublic: _isPublic ? 'Y' : 'N',
      joinType: _joinType,
      spotId: _spotId,
      lat: _spotLat,
      lon: _spotLon,
      coverTemplateId: _customCoverUrl == null ? _coverTemplateId : null,
      imageUrl: _customCoverUrl,
    );
```

- [ ] **Step 5: 빌드 화면에 표지 섹션 추가**

`_label('소개'),` ~ `const SizedBox(height: 20),`(소개 입력 블록) 바로 다음, `_label('장소 연결 (선택)'),` 이전에 추가:

```dart
          _label('표지'),
          const SizedBox(height: 6),
          if (_uploadingCover)
            const Padding(padding: EdgeInsets.symmetric(vertical: 20), child: Center(child: CircularProgressIndicator()))
          else
            CoverTemplatePicker(
              selectedTemplateId: _coverTemplateId,
              isCustomPhotoSelected: _customCoverUrl != null,
              onSelectTemplate: _selectTemplate,
              onPickCustomPhoto: _pickCustomCover,
            ),
          const SizedBox(height: 20),
```

- [ ] **Step 6: `flutter analyze` 확인**

```bash
cd /Users/bumkyuchun/work/app/flutter/project1 && flutter analyze lib/app/community/community_create_page.dart
```

Expected: `No issues found!`

- [ ] **Step 7: 커밋**

```bash
git add lib/app/community/community_create_page.dart
git commit -m "[앨범] 표지 꾸미기 - 생성 화면에 템플릿 피커 통합(기본 템플릿 선택)"
```

---

## Task 12: 프론트 — 앨범 홈 화면에 표지 배너 + 수정 기능 추가

**Files:**
- Modify: `/Users/bumkyuchun/work/app/flutter/project1/lib/app/community/community_home_page.dart`

- [ ] **Step 1: import 추가**

파일 상단 import 블록에 추가:

```dart
import 'package:project1/app/community/widget/cover_template.dart';
import 'package:project1/app/community/widget/cover_template_picker.dart';
```

- [ ] **Step 2: 표지 수정 바텀시트 호출 메서드 추가**

`_showInviteSheet()` 메서드 다음에 추가:

```dart

  Future<void> _showCoverEditSheet() async {
    final c = _community;
    if (c == null) return;
    String? selectedTemplateId = c.coverTemplateId;
    bool isCustomSelected = c.coverTemplateId == null && (c.imageUrl?.isNotEmpty ?? false);
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('표지 수정', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
              const SizedBox(height: 14),
              CoverTemplatePicker(
                selectedTemplateId: selectedTemplateId,
                isCustomPhotoSelected: isCustomSelected,
                onSelectTemplate: (id) async {
                  Navigator.of(ctx).pop();
                  final (ok, msg) = await _repo.updateCover(_communityId, coverTemplateId: id);
                  Utils.alert(msg.isEmpty ? (ok ? '표지를 변경했습니다.' : '실패했습니다.') : msg);
                  if (ok) _refresh();
                },
                onPickCustomPhoto: () async {
                  final url = await pickAndUploadCoverPhoto();
                  if (url == null) return;
                  Navigator.of(ctx).pop();
                  final (ok, msg) = await _repo.updateCover(_communityId, imageUrl: url);
                  Utils.alert(msg.isEmpty ? (ok ? '표지를 변경했습니다.' : '실패했습니다.') : msg);
                  if (ok) _refresh();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
```

- [ ] **Step 3: `_header()`에 표지 배너 추가**

`_header()` 메서드를 아래로 교체(배너를 카드 상단에 추가하고, 기존 `Row(children: [_thumb(c, 64), ...])`는 배너 아래에 유지):

```dart
  Widget _header() {
    final c = _community!;
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: const Color(0xFFECEEF3))),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _coverBanner(c),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _thumb(c, 64),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(child: Text(c.name, maxLines: 1, overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black87))),
                              if (c.isPrivate) ...[const SizedBox(width: 6), const Icon(Icons.lock, size: 15, color: Color(0xFF9AA3B2))],
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.people, size: 14, color: Color(0xFF9AA3B2)),
                              const SizedBox(width: 3),
                              Text('멤버 ${c.memberCnt}명', style: const TextStyle(fontSize: 12.5, color: Color(0xFF7A8291))),
                              const SizedBox(width: 10),
                              Text(c.isApproval ? '승인제' : '자유가입', style: const TextStyle(fontSize: 12.5, color: Color(0xFF7A8291))),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (c.description != null && c.description!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(c.description!, style: const TextStyle(fontSize: 13.5, color: Color(0xFF4A5162), height: 1.45)),
                ],
                const SizedBox(height: 14),
                _actionButton(c),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _coverBanner(CommunityData c) {
    return Stack(
      children: [
        if (c.imageUrl != null && c.imageUrl!.isNotEmpty)
          CachedNetworkImage(
            imageUrl: '${c.imageUrl}?w=800',
            width: double.infinity, height: 140, fit: BoxFit.cover,
            errorWidget: (_, __, ___) => _coverFallback(c),
          )
        else
          _coverFallback(c),
        if (c.canEditCover)
          Positioned(
            top: 10, right: 10,
            child: Material(
              color: Colors.black45,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: _showCoverEditSheet,
                child: const Padding(
                  padding: EdgeInsets.all(8),
                  child: Icon(Icons.edit, color: Colors.white, size: 18),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _coverFallback(CommunityData c) {
    return Container(
      width: double.infinity, height: 140,
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [Color(0xFF5B8DEF), Color(0xFF3B6FE0)], begin: Alignment.topLeft, end: Alignment.bottomRight),
      ),
      alignment: Alignment.center,
      child: Text(c.name.isNotEmpty ? c.name.characters.first : '?',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 40)),
    );
  }
```

- [ ] **Step 4: `flutter analyze` 확인**

```bash
cd /Users/bumkyuchun/work/app/flutter/project1 && flutter analyze lib/app/community/community_home_page.dart
```

Expected: `No issues found!`

- [ ] **Step 5: 커밋**

```bash
git add lib/app/community/community_home_page.dart
git commit -m "[앨범] 표지 꾸미기 - 앨범 홈에 표지 배너 + 수정 바텀시트 추가"
```

---

## Task 13: 프론트 — 전체 빌드 검증

**Files:** 없음(검증만)

- [ ] **Step 1: 전체 analyze**

```bash
cd /Users/bumkyuchun/work/app/flutter/project1 && flutter analyze lib
```

Expected: 에러(error) 0건. 기존에 있던 info/warning성 항목 개수만 그대로(새로 늘어난 error 없음).

- [ ] **Step 2: 디버그 APK 빌드**

```bash
flutter build apk --debug
```

Expected: `✓ Built build/app/outputs/flutter-apk/app-debug.apk`

- [ ] **Step 3: 문제 없으면 다음 태스크로, 있으면 해당 태스크로 돌아가 수정**

---

## Task 14: 마무리 — 배포 확인 요청 (자동 실행 금지)

이 플랜을 실행하는 에이전트는 **여기서 멈추고 사용자에게 보고한다.** 아래는 절대 자동으로 하지 않는다:
- 백엔드/프론트 `main` 브랜치로 merge
- `git push` (백엔드 push는 Jenkins 자동배포를 트리거하므로 특히 주의)

보고 내용: 변경 파일 목록, 커밋 목록, `flutter analyze`/`gradlew compileJava`/`flutter build apk --debug` 결과, Task 6(운영 API 수동 검증)을 아직 못 했다면 "배포 후 진행 필요"라고 명시.
