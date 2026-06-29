# Consumer ProGuard Rules for TikTok-level Video Player
# 이 규칙들은 앱이 이 라이브러리를 사용할 때 자동으로 적용됩니다.

# ExoPlayer 핵심 클래스 보존
-keep class com.google.android.exoplayer2.ExoPlayer { *; }
-keep class com.google.android.exoplayer2.SimpleExoPlayer { *; }
-keep class androidx.media3.exoplayer.ExoPlayer { *; }

# VideoPlayer 공개 API 보존
-keep public class io.flutter.plugins.videoplayer.VideoPlayerPlugin { *; }
-keep public class io.flutter.plugins.videoplayer.VideoPlayer { *; }

# Flutter 플러그인 인터페이스 보존
-keep class * implements io.flutter.plugin.common.MethodChannel$MethodCallHandler { *; }
-keep class * implements io.flutter.plugin.common.EventChannel$StreamHandler { *; }

# 네이티브 메서드 보존
-keepclasseswithmembernames class * {
    native <methods>;
}

# 성능에 중요한 콜백 인터페이스 보존
-keep interface io.flutter.plugins.videoplayer.VideoPlayerCallbacks { *; }
-keep interface io.flutter.plugins.videoplayer.VideoPlayerEventCallbacks { *; } 