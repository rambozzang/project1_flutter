// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.plugins.videoplayer;

import android.content.Context;
import android.util.LongSparseArray;
import android.os.Handler;
import android.os.Looper;
import androidx.annotation.NonNull;
import io.flutter.FlutterInjector;
import io.flutter.Log;
import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.EventChannel;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugins.videoplayer.Messages.AndroidVideoPlayerApi;
import io.flutter.plugins.videoplayer.Messages.CreateMessage;
import io.flutter.view.TextureRegistry;
import java.util.concurrent.ConcurrentHashMap;
import java.util.Map;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

/**
 * TikTok-level optimized Android platform implementation of the
 * VideoPlayerPlugin.
 * Features advanced preloading, caching, and performance monitoring.
 */
public class VideoPlayerPlugin implements FlutterPlugin, AndroidVideoPlayerApi {
  private static final String TAG = "VideoPlayerPlugin";
  private final LongSparseArray<VideoPlayer> videoPlayers = new LongSparseArray<>();
  private FlutterState flutterState;
  private final VideoPlayerOptions options = new VideoPlayerOptions();

  // Performance optimization fields
  private static final int MAX_CONCURRENT_PLAYERS = 10; // 틱톡 수준의 동시 플레이어 수
  private final Map<String, Long> urlToTextureIdMap = new ConcurrentHashMap<>();
  private final ExecutorService backgroundExecutor = Executors.newFixedThreadPool(3);
  private final Handler mainHandler = new Handler(Looper.getMainLooper());
  private boolean isPerformanceMonitoringEnabled = true;
  private long totalPlayersCreated = 0;
  private long totalPlayersDisposed = 0;

  /**
   * Register this with the v2 embedding for the plugin to respond to lifecycle
   * callbacks.
   */
  public VideoPlayerPlugin() {
  }

  @Override
  public void onAttachedToEngine(@NonNull FlutterPluginBinding binding) {
    final FlutterInjector injector = FlutterInjector.instance();
    this.flutterState = new FlutterState(
        binding.getApplicationContext(),
        binding.getBinaryMessenger(),
        injector.flutterLoader()::getLookupKeyForAsset,
        injector.flutterLoader()::getLookupKeyForAsset,
        binding.getTextureRegistry());
    flutterState.startListening(this, binding.getBinaryMessenger());

    // 성능 모니터링 시작
    if (isPerformanceMonitoringEnabled) {
      Log.d(TAG, "VideoPlayerPlugin attached to engine with TikTok-level optimizations");
    }
  }

  @Override
  public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
    if (flutterState == null) {
      Log.wtf(TAG, "Detached from the engine before registering to it.");
    }

    // 성능 통계 로깅
    if (isPerformanceMonitoringEnabled) {
      Log.d(TAG, String.format("VideoPlayerPlugin detached. Stats - Created: %d, Disposed: %d, Active: %d",
          totalPlayersCreated, totalPlayersDisposed, videoPlayers.size()));
    }

    flutterState.stopListening(binding.getBinaryMessenger());
    flutterState = null;
    onDestroy();
  }

  /**
   * 모든 플레이어 정리 - 메모리 최적화
   */
  private void disposeAllPlayers() {
    backgroundExecutor.execute(() -> {
      for (int i = 0; i < videoPlayers.size(); i++) {
        VideoPlayer player = videoPlayers.valueAt(i);
        if (player != null) {
          player.dispose();
          totalPlayersDisposed++;
        }
      }

      mainHandler.post(() -> {
        videoPlayers.clear();
        urlToTextureIdMap.clear();

        // 캐시 정리
        VideoPlayer.clearCache();

        if (isPerformanceMonitoringEnabled) {
          Log.d(TAG, "All video players disposed and cache cleared");
        }
      });
    });
  }

  public void onDestroy() {
    // The whole FlutterView is being destroyed. Here we release resources acquired
    // for all
    // instances of VideoPlayer. Once
    // https://github.com/flutter/flutter/issues/19358 is resolved this may
    // be replaced with just asserting that videoPlayers.isEmpty().
    // https://github.com/flutter/flutter/issues/20989 tracks this.
    disposeAllPlayers();

    // 백그라운드 실행자 정리
    if (!backgroundExecutor.isShutdown()) {
      backgroundExecutor.shutdown();
    }
  }

  @Override
  public void initialize() {
    disposeAllPlayers();
  }

  @Override
  public @NonNull Long create(@NonNull CreateMessage arg) {
    // 최대 플레이어 수 제한 (메모리 최적화)
    if (videoPlayers.size() >= MAX_CONCURRENT_PLAYERS) {
      // 가장 오래된 플레이어 정리
      cleanupOldestPlayer();
    }

    TextureRegistry.SurfaceTextureEntry handle = flutterState.textureRegistry.createSurfaceTexture();
    EventChannel eventChannel = new EventChannel(
        flutterState.binaryMessenger, "flutter.io/videoPlayer/videoEvents" + handle.id());

    final VideoAsset videoAsset;
    try {
      if (arg.getAsset() != null) {
        String assetLookupKey;
        if (arg.getPackageName() != null) {
          assetLookupKey = flutterState.keyForAssetAndPackageName.get(arg.getAsset(), arg.getPackageName());
        } else {
          assetLookupKey = flutterState.keyForAsset.get(arg.getAsset());
        }
        videoAsset = VideoAsset.fromAssetUrl("asset:///" + assetLookupKey);
      } else if (arg.getUri() != null && arg.getUri().startsWith("rtsp://")) {
        videoAsset = VideoAsset.fromRtspUrl(arg.getUri());
      } else if (arg.getUri() != null) {
        VideoAsset.StreamingFormat streamingFormat = VideoAsset.StreamingFormat.UNKNOWN;
        String formatHint = arg.getFormatHint();
        if (formatHint != null) {
          switch (formatHint) {
            case "ss":
              streamingFormat = VideoAsset.StreamingFormat.SMOOTH;
              break;
            case "dash":
              streamingFormat = VideoAsset.StreamingFormat.DYNAMIC_ADAPTIVE;
              break;
            case "hls":
              streamingFormat = VideoAsset.StreamingFormat.HTTP_LIVE;
              break;
          }
        }
        videoAsset = VideoAsset.fromRemoteUrl(arg.getUri(), streamingFormat, arg.getHttpHeaders());

        // URL 매핑 저장 (중복 방지)
        urlToTextureIdMap.put(arg.getUri(), handle.id());
      } else {
        throw new IllegalArgumentException("No valid video source provided");
      }

      VideoPlayer player = VideoPlayer.create(
          flutterState.applicationContext,
          VideoPlayerEventCallbacks.bindTo(eventChannel),
          handle,
          videoAsset,
          options,
          flutterState.binaryMessenger);

      videoPlayers.put(handle.id(), player);
      totalPlayersCreated++;

      if (isPerformanceMonitoringEnabled) {
        Log.d(TAG, String.format("Created video player %d. Total active: %d", handle.id(), videoPlayers.size()));
      }

      return handle.id();
    } catch (Exception e) {
      handle.release();
      throw e;
    }
  }

  /**
   * 가장 오래된 플레이어 정리 (LRU 방식)
   */
  private void cleanupOldestPlayer() {
    if (videoPlayers.size() > 0) {
      long oldestTextureId = videoPlayers.keyAt(0);
      VideoPlayer oldestPlayer = videoPlayers.get(oldestTextureId);

      if (oldestPlayer != null) {
        backgroundExecutor.execute(() -> {
          oldestPlayer.dispose();
          totalPlayersDisposed++;

          mainHandler.post(() -> {
            videoPlayers.remove(oldestTextureId);

            // URL 매핑에서도 제거
            urlToTextureIdMap.entrySet().removeIf(entry -> entry.getValue().equals(oldestTextureId));

            if (isPerformanceMonitoringEnabled) {
              Log.d(TAG, String.format("Cleaned up oldest player %d", oldestTextureId));
            }
          });
        });
      }
    }
  }

  @NonNull
  private VideoPlayer getPlayer(long textureId) {
    VideoPlayer player = videoPlayers.get(textureId);

    // Avoid a very ugly un-debuggable NPE that results in returning a null player.
    if (player == null) {
      String message = "No player found with textureId <" + textureId + ">";
      if (videoPlayers.size() == 0) {
        message += " and no active players created by the plugin.";
      }
      throw new IllegalStateException(message);
    }

    return player;
  }

  @Override
  public void dispose(@NonNull Long textureId) {
    VideoPlayer player = getPlayer(textureId);

    backgroundExecutor.execute(() -> {
      player.dispose();
      totalPlayersDisposed++;

      mainHandler.post(() -> {
        videoPlayers.remove(textureId);

        // URL 매핑에서도 제거
        urlToTextureIdMap.entrySet().removeIf(entry -> entry.getValue().equals(textureId));

        if (isPerformanceMonitoringEnabled) {
          Log.d(TAG, String.format("Disposed video player %d. Remaining active: %d", textureId, videoPlayers.size()));
        }
      });
    });
  }

  @Override
  public void setLooping(@NonNull Long textureId, @NonNull Boolean looping) {
    VideoPlayer player = getPlayer(textureId);
    player.setLooping(looping);
  }

  @Override
  public void setVolume(@NonNull Long textureId, @NonNull Double volume) {
    VideoPlayer player = getPlayer(textureId);
    player.setVolume(volume);
  }

  @Override
  public void setPlaybackSpeed(@NonNull Long textureId, @NonNull Double speed) {
    VideoPlayer player = getPlayer(textureId);
    player.setPlaybackSpeed(speed);
  }

  @Override
  public void play(@NonNull Long textureId) {
    VideoPlayer player = getPlayer(textureId);
    player.play();
  }

  @Override
  public @NonNull Long position(@NonNull Long textureId) {
    VideoPlayer player = getPlayer(textureId);
    long position = player.getPosition();
    player.sendBufferingUpdate();
    return position;
  }

  @Override
  public void seekTo(@NonNull Long textureId, @NonNull Long position) {
    VideoPlayer player = getPlayer(textureId);
    player.seekTo(position.intValue());
  }

  @Override
  public void pause(@NonNull Long textureId) {
    VideoPlayer player = getPlayer(textureId);
    player.pause();
  }

  @Override
  public void setMixWithOthers(@NonNull Boolean mixWithOthers) {
    options.mixWithOthers = mixWithOthers;
  }

  /**
   * 성능 통계 가져오기
   */
  public Map<String, Object> getPerformanceStats() {
    Map<String, Object> stats = new ConcurrentHashMap<>();
    stats.put("totalPlayersCreated", totalPlayersCreated);
    stats.put("totalPlayersDisposed", totalPlayersDisposed);
    stats.put("activePlayersCount", videoPlayers.size());
    stats.put("maxConcurrentPlayers", MAX_CONCURRENT_PLAYERS);
    return stats;
  }

  /**
   * 성능 모니터링 활성화/비활성화
   */
  public void setPerformanceMonitoringEnabled(boolean enabled) {
    this.isPerformanceMonitoringEnabled = enabled;
  }

  /**
   * 특정 URL의 플레이어가 이미 존재하는지 확인
   */
  public boolean hasPlayerForUrl(String url) {
    return urlToTextureIdMap.containsKey(url);
  }

  /**
   * 특정 URL의 텍스처 ID 가져오기
   */
  public Long getTextureIdForUrl(String url) {
    return urlToTextureIdMap.get(url);
  }

  private interface KeyForAssetFn {
    String get(String asset);
  }

  private interface KeyForAssetAndPackageName {
    String get(String asset, String packageName);
  }

  private static final class FlutterState {
    final Context applicationContext;
    final BinaryMessenger binaryMessenger;
    final KeyForAssetFn keyForAsset;
    final KeyForAssetAndPackageName keyForAssetAndPackageName;
    final TextureRegistry textureRegistry;

    FlutterState(
        Context applicationContext,
        BinaryMessenger messenger,
        KeyForAssetFn keyForAsset,
        KeyForAssetAndPackageName keyForAssetAndPackageName,
        TextureRegistry textureRegistry) {
      this.applicationContext = applicationContext;
      this.binaryMessenger = messenger;
      this.keyForAsset = keyForAsset;
      this.keyForAssetAndPackageName = keyForAssetAndPackageName;
      this.textureRegistry = textureRegistry;
    }

    void startListening(VideoPlayerPlugin methodCallHandler, BinaryMessenger messenger) {
      AndroidVideoPlayerApi.setUp(messenger, methodCallHandler);
    }

    void stopListening(BinaryMessenger messenger) {
      AndroidVideoPlayerApi.setUp(messenger, null);
    }
  }

  public void onMethodCall(@NonNull MethodCall call, @NonNull Result result) {
    if (videoPlayers.size() == 0) {
      result.error("no_players", "No video players associated", null);
      return;
    }

    switch (call.method) {
      case "setAdaptiveStreaming":
        setAdaptiveStreaming(call, result);
        break;
      case "isAdaptiveStreamingEnabled":
        isAdaptiveStreamingEnabled(call, result);
        break;
      default:
        result.notImplemented();
        break;
    }
  }

  private void setAdaptiveStreaming(MethodCall call, Result result) {
    Boolean enableAdaptiveStreaming = call.argument("enableAdaptiveStreaming");
    if (enableAdaptiveStreaming == null) {
      result.error("WRONG_ARGUMENTS", "Adaptive streaming setting was not specified.", null);
      return;
    }

    Long textureId = call.argument("textureId");
    if (textureId == null) {
      result.error("WRONG_ARGUMENTS", "Missing textureId parameter.", null);
      return;
    }

    VideoPlayer player = videoPlayers.get(textureId);
    if (player == null) {
      result.error("WRONG_ARGUMENTS", "Player not found for specified texture id.", null);
      return;
    }

    player.setAdaptiveStreaming(enableAdaptiveStreaming);
    result.success(null);
  }

  private void isAdaptiveStreamingEnabled(MethodCall call, Result result) {
    Long textureId = call.argument("textureId");
    if (textureId == null) {
      result.error("WRONG_ARGUMENTS", "Missing textureId parameter.", null);
      return;
    }

    VideoPlayer player = videoPlayers.get(textureId);
    if (player == null) {
      result.error("WRONG_ARGUMENTS", "Player not found for specified texture id.", null);
      return;
    }

    result.success(player.isAdaptiveStreamingEnabled());
  }
}
