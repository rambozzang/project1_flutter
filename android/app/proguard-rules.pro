## Flutter wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }
# ⚠️ 여기 있던 `-keep class !com.rive.** { *; }` 를 제거했다(2026-09-06).
# `!` 는 클래스 필터의 부정이라 "com.rive 를 제외한 **모든 클래스**를 보존"이라는 뜻이었다.
# rive 는 이 앱의 의존성도 아니어서, 사실상 R8 난독화를 통째로 끈 규칙이었다
# (난독화율 2.7% → Play Console "앱 최적화 기준점 미만" 경고의 원인).
-keep class * implements androidx.viewbinding.ViewBinding { *; }
-dontwarn io.flutter.embedding.**
# 네이버지도 최적화
-keep class com.naver.maps.** { *; }
-dontwarn com.naver.maps.**

# Google Sign-In 관련 추가 규칙
# ⚠️ `-keep class com.google.android.gms.** { *; }`(통짜 보존)는 제거했다(2026-09-06).
# Play 서비스 전체 1.3만 클래스를 그대로 남겨 난독화율을 끌어내렸다. 로그인에 필요한
# auth/common/tasks/base 는 아래에 개별 규칙으로 이미 남아 있고, Play 서비스 AAR 은
# 자체 consumer 규칙을 함께 배포한다. ads·maps 등 나머지는 난독화 대상으로 돌린다.
-keep class com.google.android.gms.auth.** { *; }
-keep class com.google.android.gms.common.** { *; }
-keep class com.google.android.gms.tasks.** { *; }

-keepattributes Signature
-keepattributes *Annotation*

# Google Sign-In SDK
-keep class com.google.android.gms.auth.api.signin.** { *; }
-keep class com.google.android.gms.auth.api.identity.** { *; }
-keep class com.google.android.gms.auth.api.phone.** { *; }

# Gson 관련 (Google Sign-In에서 사용될 수 있음)
-keepattributes Signature
-keepattributes *Annotation*
-dontwarn sun.misc.**
-keep class com.google.gson.** { *; }
-keep class * implements com.google.gson.TypeAdapterFactory
-keep class * implements com.google.gson.JsonSerializer
-keep class * implements com.google.gson.JsonDeserializer

# 기타 Google Play 서비스 관련
-keep class com.google.android.gms.common.api.** { *; }
-keep class com.google.android.gms.base.** { *; }

# 경고 무시
-dontwarn com.google.android.gms.**
-dontwarn com.google.api.client.**

# kakao 
-keep class com.kakao.sdk.**.model.* { <fields>; }
-keep class * extends com.google.gson.TypeAdapter

# https://github.com/square/okhttp/pull/6792
-dontwarn org.bouncycastle.jsse.**
-dontwarn org.conscrypt.*
-dontwarn org.openjsse.**

# OkHttp 관련 규칙 (R8 빌드 오류 해결)
-dontwarn com.squareup.okhttp.CipherSuite
-dontwarn com.squareup.okhttp.ConnectionSpec
-dontwarn com.squareup.okhttp.TlsVersion
-keep class com.squareup.okhttp.** { *; }
-dontwarn com.squareup.okhttp.**

# gRPC 관련 규칙
-keep class io.grpc.** { *; }
-dontwarn io.grpc.**
-keep class com.google.protobuf.** { *; }
-dontwarn com.google.protobuf.**

# 네이버 로그인
-keep public class com.navercorp.nid.** {
    public *;
}
# ── 리플렉션으로 이름이 필요한 것들 (R8 난독화 활성화에 따른 보호, 2026-09-06) ──

# WorkManager 는 워커의 **클래스 이름 문자열**을 내부 DB에 저장해 두었다가 나중에
# 인스턴스를 만든다. 난독화로 이름이 바뀌면 그 자체는 괜찮지만, 앱을 업데이트했을 때
# 이전 버전이 큐에 남겨 둔 작업이 옛 이름을 가리켜 실행되지 못한다.
# 업로드를 잃지 않는 것이 이 앱의 전제라 워커 이름은 고정한다.
-keep class * extends androidx.work.ListenableWorker { *; }

# flutter_local_notifications: 예약 알림을 Gson 으로 직렬화해 보관한다.
# 모델 클래스가 난독화되면 복원에 실패한다(플러그인 README 권장 규칙).
-keep class com.dexterous.** { *; }

# 크래시 스택을 mapping.txt 로 되돌릴 수 있게 줄번호를 남긴다.
# (원본 파일명은 감춘다 — 난독화 이점은 유지)
-keepattributes SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile
