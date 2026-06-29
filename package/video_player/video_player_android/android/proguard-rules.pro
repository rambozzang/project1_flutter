# TikTok-level Video Player ProGuard Rules
# 비디오 플레이어 성능 최적화를 위한 ProGuard 설정

# ExoPlayer 관련 클래스 보존
-keep class com.google.android.exoplayer2.** { *; }
-keep class androidx.media3.** { *; }
-dontwarn com.google.android.exoplayer2.**
-dontwarn androidx.media3.**

# VideoPlayer 플러그인 클래스 보존
-keep class io.flutter.plugins.videoplayer.** { *; }
-keep interface io.flutter.plugins.videoplayer.** { *; }

# Flutter 관련 클래스 보존
-keep class io.flutter.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.view.** { *; }

# 네이티브 메서드 보존
-keepclasseswithmembernames class * {
    native <methods>;
}

# 성능 최적화를 위한 설정
-optimizations !code/simplification/arithmetic,!code/simplification/cast,!field/*,!class/merging/*
-optimizationpasses 5
-allowaccessmodification
-dontpreverify

# 네트워크 관련 클래스 보존 (OkHttp)
-keep class okhttp3.** { *; }
-keep interface okhttp3.** { *; }
-dontwarn okhttp3.**
-dontwarn okio.**

# 리플렉션 사용 클래스 보존
-keepattributes Signature
-keepattributes *Annotation*
-keepattributes EnclosingMethod
-keepattributes InnerClasses

# 열거형 보존
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# Serializable 클래스 보존
-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
}

# 성능 크리티컬한 클래스들의 최적화 방지
-keep class io.flutter.plugins.videoplayer.VideoPlayer {
    public <methods>;
}

-keep class io.flutter.plugins.videoplayer.ExoPlayerEventListener {
    public <methods>;
}

# 디버깅을 위한 라인 번호 보존 (릴리스에서는 제거 가능)
-keepattributes SourceFile,LineNumberTable

# 경고 무시
-dontwarn java.lang.invoke.**
-dontwarn javax.annotation.**
-dontwarn org.codehaus.mojo.animal_sniffer.* 