## Flutter wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }
-keep class !com.rive.** { *; }
-keep class * implements androidx.viewbinding.ViewBinding { *; }
-dontwarn io.flutter.embedding.**
# 네이버지도 최적화
-keep class com.naver.maps.** { *; }
-dontwarn com.naver.maps.**

# Google Sign-In 관련 추가 규칙
-keep class com.google.android.gms.** { *; }
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

# 네이버 로그인
-keep public class com.navercorp.nid.** {
    public *;
}