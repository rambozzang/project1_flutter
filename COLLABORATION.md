# 🤝 다중 에이전트 협업 가이드

**팀 구성**: kimi (Claude Code) | glm (GLM) | 기타 팀원

---

## 📋 협업 워크플로우

### 1️⃣ 작업 배정 (STATE.md)

**누가**: 프로젝트 리드 또는 담당자  
**언제**: 새 작업 시작 전

```markdown
### [작업명]
- 상태: 대기 중 → 진행 중
- 담당: glm (예시)
- 예상 완료: 2026-06-28
```

---

### 2️⃣ 작업 진행 (작업 중)

**체크리스트 기반 진행**:
```
□ 환경 설정
□ 코드 작성
□ 테스트
□ 코드 리뷰
□ 병합
```

**각 단계에서**:
- `LOG.md`에 진행 상황 기록
- 막힘 시 `STATE.md`의 상태를 🔴 막힘으로 변경
- 진행률 업데이트

---

### 3️⃣ 커밋 메시지 규칙

```bash
git commit -m "[상태] [담당자] 작업명 - 상세 설명

- 변경 사항 1
- 변경 사항 2

Related to: STATE.md line XX"
```

**예시**:
```bash
git commit -m "[진행] [kimi] AdMob 광고 통합 - 배너 광고 UI 추가

- google_mobile_ads 설정
- 비디오 재생 화면에 배너 추가
- 테스트 광고 활성화

Related to: STATE.md AdMob 섹션"
```

---

### 4️⃣ 작업 완료 (STATE.md + LOG.md)

**작업 완료 시**:

1. `STATE.md` 업데이트:
   ```markdown
   ### [작업명]
   - 상태: ✅ 완료
   - 담당: glm
   - 완료일: 2026-06-28
   ```

2. `LOG.md`에 완료 로그 추가:
   ```markdown
   ### 14:30 | glm | ✅ 완료
   **작업**: AdMob 광고 통합
   - 배너 광고 구현
   - 테스트 광고 활성화
   - 커밋: a1b2c3d
   
   **로그**: AdMob integration complete. Ready for production ads.
   ```

3. 관련 파일 정리

---

## 🔄 상태 전환 흐름

```
대기 중 → 진행 중 → 코드 리뷰 → 완료
         ↓
       막힘 (문제 발생)
         ↓
       해결 → 진행 중
```

---

## 📂 파일 구조

```
project1/
├── STATE.md          # 현재 상태 + 진행 상황
├── LOG.md            # 변경 이력 (시간순)
├── COLLABORATION.md  # 이 파일
├── CLAUDE.md         # 규칙 + 환경 설정
└── [소스코드]
```

---

## 🚀 에이전트별 책임

### kimi (Claude Code)
- Android/Flutter 핵심 기능
- 빌드 설정
- CI/CD 관련

### glm (GLM)
- UI/UX 개선
- 기능 구현 지원
- 테스트

### 기타 팀원
- (역할 정의 필요)

---

## ⚡ 빠른 참조

### STATE.md 업데이트 (작업 시작)
```
담당: [에이전트명]
상태: 진행 중
```

### LOG.md 기록 (매 변경)
```
[시간] | [담당자] | [상태] [작업명]
```

### 병합 전 체크리스트
- [ ] STATE.md 업데이트됨
- [ ] LOG.md 기록됨
- [ ] 테스트 완료
- [ ] 코드 리뷰 통과
- [ ] 커밋 메시지 규칙 준수

---

## 📞 막힘 상황 처리

**문제 발생 시**:

1. `STATE.md` 상태를 🔴 막힘으로 변경
2. `LOG.md`에 문제 기록:
   ```markdown
   ### 10:45 | kimi | 🔴 막힘
   **작업**: Cellular 버그 분석
   - 원인: SSL 인증서 검증 실패
   - 필요한 도움: 네트워크 로그 분석
   
   **로그**: Blocked by SSL certificate validation. Need logs from test device.
   ```
3. 팀원에게 알림
4. 해결 후 상태 업데이트

---

## 💾 자동 동기화 (선택사항)

매일 정해진 시간에 자동으로:
- STATE.md 갱신 (진행률 확인)
- LOG.md 정렬 (최신순)

```bash
# .git/hooks/post-commit에 추가 (선택)
# STATE.md, LOG.md 변경 확인
```

---

## 📊 진행 상황 리포트 (주간)

매주 월요일 갱신:
```markdown
## 주간 요약 (2026-06-24~06-30)

### 완료된 작업 (3/8)
- ✅ Android 빌드 수정
- ✅ 아이콘 리디자인
- ✅ 협업 프로세스 구축

### 진행 중 (2/8)
- 🔵 Cellular 버그 분석
- 🔵 AdMob 설정

### 막힘 (0/8)
- (없음)

### 다음주 우선순위
1. Cellular 버그 해결
2. AdMob 광고 활성화
3. 프리미엠 구독 설계
```

---

## ✨ 팁

- **STATE.md 먼저 봐요**: 누가 뭘 하고 있는지 한눈에
- **LOG.md는 기록용**: 변경 이유와 시간이 남음
- **COLLABORATION.md 숙지**: 모든 팀원이 같은 프로세스 따름
- **매일 동기화**: 아침에 STATE.md 확인, 저녁에 LOG.md 업데이트
