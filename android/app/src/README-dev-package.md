# 개발 빌드를 스토어 설치본과 **나란히** 까는 법

## 왜 있나

폰에 깔린 skysnap 은 Play 재서명 키로 서명돼 있다. 우리 개발 키로 만든 빌드는
같은 패키지명이라 덮어쓰려 하고, 서명이 달라 거부된다:

```
INSTALL_FAILED_UPDATE_INCOMPATIBLE: Existing package com.codelabtiger.skysnap
signatures do not match newer version
```

지우고 깔면 되지만 로그인·데이터가 날아간다. 그래서 개발 빌드만 패키지명을
`com.codelabtiger.skysnap.dev` 로 갈라 둘을 같이 둔다.

2026-09-21 에 영상 표면 수정(`surfaceReady`)을 실기기에서 **눈으로 못 보고**
넘어간 적이 있다. 그때 이 길을 냈다.

## 쓰는 법

```bash
flutter build apk --profile -P devId
adb install build/app/outputs/flutter-apk/app-profile.apk
```

`-P devId` 가 없으면 접미사가 붙지 않는다 — 스토어·CI 경로는 그대로다.

로그인은 로그인 화면 아래 **`테스트 계정으로 로그인 (개발용)`** 으로 한다.
`kReleaseMode` 로 가려 둬서 릴리즈 빌드에는 아예 없다(컴파일 타임 상수라
트리쉐이킹으로 통째로 떨어진다).

## `src/{profile,debug}/google-services.json` 은 뭔가

google-services 플러그인은 빌드하는 applicationId 와 **똑같은 package_name** 이
json 안에 있어야 통과시킨다. 없으면 이렇게 죽는다:

```
No matching client found for package name 'com.codelabtiger.skysnap.dev'
```

그래서 profile·debug 변형에만 적용되는 json 을 따로 두고, 그 안에
**`com.codelabtiger.skysnap` 과 `.dev` 두 클라이언트를 모두** 넣었다.
둘 다 넣은 이유는 `-P devId` **없이** 빌드할 때도 깨지지 않게 하려는 것이다 —
하나만 두면 접미사를 안 붙인 평범한 profile 빌드가 조용히 죽는다.

`.dev` 클라이언트는 운영 앱의 값을 복사하되 `oauth_client` 는 **비웠다.**
OAuth 클라이언트는 패키지명 + SHA-1 에 묶인 값이라 `.dev` 에서 쓸 수 없는데,
남겨 두면 "이걸로 소셜 로그인이 되는 줄" 오해한다.

## 이 빌드에서 안 되는 것

- **소셜 로그인 전부**(카카오·네이버·구글·애플). 키해시·OAuth 가 패키지명
  단위로 등록돼 있다. → 테스트 계정 로그인을 쓴다.
- **FCM 푸시·Firebase Auth.** `.dev` 는 Firebase 콘솔에 등록된 앱이 아니다.
  화면을 눈으로 보려고 만든 길이지, 기능 전수 검증용이 아니다.

푸시까지 봐야 하면 Firebase 콘솔에 `com.codelabtiger.skysnap.dev` 를 정식으로
등록하고 받은 `google-services.json` 으로 이 파일들을 갈아치운다.

## 운영에 새어 나가지 않나

- `applicationIdSuffix` 는 `-P devId` 가 있을 때만 붙는다.
- 이 json 들은 `src/profile/`·`src/debug/` 아래라 **release 변형은 읽지 않는다.**
  release 는 `android/app/google-services.json`(클라이언트 1개) 그대로다.
