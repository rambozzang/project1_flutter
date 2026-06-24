// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.plugins.videoplayer;

import static androidx.media3.common.Player.REPEAT_MODE_ALL;
import static androidx.media3.common.Player.REPEAT_MODE_OFF;

import android.content.Context;
import android.net.Uri;
import android.view.Surface;
import android.os.Handler;
import android.os.Looper;
import androidx.annotation.NonNull;
import androidx.annotation.VisibleForTesting;
import androidx.media3.common.C;
import androidx.media3.common.Format;
import androidx.media3.common.MediaItem;
import androidx.media3.common.PlaybackException;
import androidx.media3.common.PlaybackParameters;
import androidx.media3.common.Player;
import androidx.media3.common.Player.Listener;
import androidx.media3.common.util.Util;
import androidx.media3.datasource.DataSource;
import androidx.media3.datasource.DefaultDataSource;
import androidx.media3.datasource.DefaultHttpDataSource;
import androidx.media3.datasource.TransferListener;
import androidx.media3.datasource.cache.CacheDataSource;
import androidx.media3.datasource.cache.LeastRecentlyUsedCacheEvictor;
import androidx.media3.datasource.cache.SimpleCache;
import androidx.media3.database.StandaloneDatabaseProvider;
import androidx.media3.exoplayer.DefaultLoadControl;
import androidx.media3.exoplayer.DefaultRenderersFactory;
import androidx.media3.exoplayer.ExoPlayer;
import androidx.media3.exoplayer.LoadControl;
import androidx.media3.common.AudioAttributes;
import androidx.media3.exoplayer.dash.DashMediaSource;
import androidx.media3.exoplayer.dash.DefaultDashChunkSource;
import androidx.media3.exoplayer.hls.HlsMediaSource;
import androidx.media3.exoplayer.smoothstreaming.DefaultSsChunkSource;
import androidx.media3.exoplayer.smoothstreaming.SsMediaSource;
import androidx.media3.exoplayer.source.MediaSource;
import androidx.media3.exoplayer.source.ProgressiveMediaSource;
import androidx.media3.exoplayer.trackselection.AdaptiveTrackSelection;
import androidx.media3.exoplayer.trackselection.DefaultTrackSelector;
import androidx.media3.exoplayer.trackselection.TrackSelector;
import androidx.media3.exoplayer.upstream.Allocator;
import androidx.media3.exoplayer.upstream.DefaultAllocator;
import androidx.media3.exoplayer.upstream.DefaultBandwidthMeter;
import java.io.File;
import io.flutter.plugin.common.EventChannel;
import io.flutter.view.TextureRegistry;
import io.flutter.plugin.common.BinaryMessenger;
import java.util.Arrays;
import java.util.Collections;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

/**
 * TikTok-level optimized video player with advanced preloading, caching, and
 * performance features
 */
final class VideoPlayer {
  private static final String TAG = "VideoPlayer";
  private static final String FORMAT_SS = "ss";
  private static final String FORMAT_DASH = "dash";
  private static final String FORMAT_HLS = "hls";
  private static final String FORMAT_OTHER = "other";

  // TikTok-style two-stage buffering
  private static final long MAX_CACHE_SIZE = 500 * 1024 * 1024; // 500MB 캐시

  private ExoPlayer exoPlayer;
  private DefaultTrackSelector trackSelector;
  private DefaultBandwidthMeter bandwidthMeter;
  private VideoLoadControl videoLoadControl;

  private Surface surface;
  private final TextureRegistry.SurfaceTextureEntry textureEntry;
  private QueuingEventSink eventSink;
  private final EventChannel eventChannel;

  @VisibleForTesting
  boolean isInitialized = false;

  private final VideoPlayerOptions options;

  // 글로벌 캐시 및 프리로딩 관리
  private static SimpleCache cache;
  private static final Map<String, MediaSource> preloadedSources = new ConcurrentHashMap<>();
  private static final ExecutorService preloadExecutor = Executors.newFixedThreadPool(3);
  private static Handler mainHandler = new Handler(Looper.getMainLooper());

  // 성능 최적화 설정
  private boolean isAdaptiveStreamingEnabled = true;
  private boolean isPreloadingEnabled = true;
  private boolean isFastStartEnabled = true;
  private long lastBufferUpdateTime = 0;
  private static final long BUFFER_UPDATE_INTERVAL = 250; // 250ms - 메인 스레드 부하 완화

  VideoPlayer(
      Context context,
      EventChannel eventChannel,
      TextureRegistry.SurfaceTextureEntry textureEntry,
      String dataSource,
      String formatHint,
      @NonNull Map<String, String> httpHeaders,
      VideoPlayerOptions options) {
    this.eventChannel = eventChannel;
    this.textureEntry = textureEntry;
    this.options = options;

    initializeCache(context);
    initializePlayer(context, dataSource, formatHint, httpHeaders);
  }

  // Constructor used to directly test members of this class.
  @VisibleForTesting
  VideoPlayer(
      ExoPlayer exoPlayer,
      EventChannel eventChannel,
      TextureRegistry.SurfaceTextureEntry textureEntry,
      VideoPlayerOptions options,
      QueuingEventSink eventSink) {
    this.eventChannel = eventChannel;
    this.textureEntry = textureEntry;
    this.options = options;

    setUpVideoPlayer(exoPlayer, eventSink);
  }

  /**
   * 캐시 초기화 - 틱톡 수준의 캐싱 전략
   */
  private void initializeCache(Context context) {
    if (cache == null) {
      synchronized (VideoPlayer.class) {
        if (cache == null) {
          File cacheDir = new File(context.getCacheDir(), "tiktok_video_cache");
          StandaloneDatabaseProvider databaseProvider = new StandaloneDatabaseProvider(context);
          cache = new SimpleCache(
              cacheDir,
              new LeastRecentlyUsedCacheEvictor(MAX_CACHE_SIZE),
              databaseProvider);
        }
      }
    }
  }

  /**
   * 플레이어 초기화 - 최적화된 설정
   */
  private void initializePlayer(Context context, String dataSource, String formatHint,
      Map<String, String> httpHeaders) {
    // 대역폭 측정기 설정
    bandwidthMeter = new DefaultBandwidthMeter.Builder(context)
        .setInitialBitrateEstimate(1000000) // 1Mbps 초기 추정값
        .build();

    // 적응형 트랙 선택 - 빠른 시작 + 부드러운 화질 전환 튜닝
    // 낮은 화질로 즉시 시작하고, 화질 상승은 신중하게(잦은 전환 hitch 방지)
    AdaptiveTrackSelection.Factory trackSelectionFactory = new AdaptiveTrackSelection.Factory(
        /* minDurationForQualityIncreaseMs= */ 6000,
        /* maxDurationForQualityDecreaseMs= */ 4000,
        /* minDurationToRetainAfterDiscardMs= */ 5000,
        /* bandwidthFraction= */ 0.7f);
    trackSelector = new DefaultTrackSelector(context, trackSelectionFactory);

    // 동적 버퍼 컨트롤 - 프리로드 5초 / 활성화 20초
    videoLoadControl = new VideoLoadControl();

    // 렌더러 팩토리 최적화
    DefaultRenderersFactory renderersFactory = new DefaultRenderersFactory(context)
        .setEnableDecoderFallback(true)
        .setExtensionRendererMode(DefaultRenderersFactory.EXTENSION_RENDERER_MODE_PREFER);

    // ExoPlayer 빌드
    exoPlayer = new ExoPlayer.Builder(context)
        .setRenderersFactory(renderersFactory)
        .setTrackSelector(trackSelector)
        .setLoadControl(videoLoadControl)
        .setBandwidthMeter(bandwidthMeter)
        // 스크롤 중 디스플레이 프레임레이트 전환으로 인한 끊김 방지
        .setVideoChangeFrameRateStrategy(C.VIDEO_CHANGE_FRAME_RATE_STRATEGY_OFF)
        // 이어폰 분리 등 오디오 출력 변경 시 자동 일시정지
        .setHandleAudioBecomingNoisy(true)
        .build();

    // 트랙 선택 최적화
    setAdaptiveStreaming(isAdaptiveStreamingEnabled);

    // 미디어 소스 준비
    Uri uri = Uri.parse(dataSource);
    MediaSource mediaSource = getOrCreateMediaSource(uri, httpHeaders, formatHint, context);

    exoPlayer.setMediaSource(mediaSource);
    exoPlayer.prepare();

    // 빠른 시작을 위한 설정
    if (isFastStartEnabled) {
      exoPlayer.setPlayWhenReady(false);
      // 프리로딩 시작
      preloadNextVideos(context, dataSource, httpHeaders, formatHint);
    }

    setUpVideoPlayer(exoPlayer, new QueuingEventSink());
  }

  /**
   * 미디어 소스 가져오기 또는 생성 (캐싱 포함)
   */
  private MediaSource getOrCreateMediaSource(Uri uri, Map<String, String> httpHeaders, String formatHint,
      Context context) {
    // MediaSource 객체는 절대 재사용하지 않는다.
    // media3에서 하나의 MediaSource는 동시에 한 ExoPlayer에만 바인딩 가능하며,
    // 재사용 시 "Source error: IllegalStateException" 발생.
    // 실제 캐싱은 CacheDataSource(바이트 단위 SimpleCache)가 담당하므로,
    // 매번 새 MediaSource를 만들어도 다운로드한 바이트는 캐시에서 재사용된다.
    DataSource.Factory dataSourceFactory = createDataSourceFactory(context, httpHeaders);
    return buildMediaSource(uri, dataSourceFactory, formatHint, context);
  }

  /**
   * 데이터 소스 팩토리 생성 - 캐싱 및 최적화 포함
   */
  private DataSource.Factory createDataSourceFactory(Context context, Map<String, String> httpHeaders) {
    DataSource.Factory upstreamFactory;

    // HTTP 데이터 소스 최적화
    DefaultHttpDataSource.Factory httpDataSourceFactory = new DefaultHttpDataSource.Factory()
        .setUserAgent("TikTokVideoPlayer/1.0")
        .setConnectTimeoutMs(8000)
        .setReadTimeoutMs(8000)
        .setAllowCrossProtocolRedirects(true)
        .setKeepPostFor302Redirects(true);

    if (httpHeaders != null && !httpHeaders.isEmpty()) {
      httpDataSourceFactory.setDefaultRequestProperties(httpHeaders);
    }

    upstreamFactory = new DefaultDataSource.Factory(context, httpDataSourceFactory);

    // 캐시 데이터 소스 팩토리
    return new CacheDataSource.Factory()
        .setCache(cache)
        .setUpstreamDataSourceFactory(upstreamFactory)
        .setFlags(CacheDataSource.FLAG_IGNORE_CACHE_ON_ERROR)
        .setCacheWriteDataSinkFactory(null); // 쓰기 최적화
  }

  /**
   * 다음 비디오들 프리로딩
   */
  private void preloadNextVideos(Context context, String currentDataSource, Map<String, String> httpHeaders,
      String formatHint) {
    if (!isPreloadingEnabled)
      return;

    preloadExecutor.execute(() -> {
      try {
        // 여기서는 예시로 현재 비디오의 다음 비디오들을 프리로드
        // 실제 구현에서는 비디오 리스트에서 다음 비디오들의 URL을 가져와야 함
        // 이는 Flutter 측에서 제공되어야 하는 정보입니다.

        // 프리로딩 로직은 앱의 비디오 리스트 관리 방식에 따라 구현되어야 합니다.
      } catch (Exception e) {
        // 프리로딩 실패는 무시
      }
    });
  }

  private static boolean isHTTP(Uri uri) {
    if (uri == null || uri.getScheme() == null) {
      return false;
    }
    String scheme = uri.getScheme();
    return scheme.equals("http") || scheme.equals("https");
  }

  private MediaSource buildMediaSource(
      Uri uri, DataSource.Factory mediaDataSourceFactory, String formatHint, Context context) {
    int type;
    if (formatHint == null) {
      type = Util.inferContentType(uri);
    } else {
      switch (formatHint) {
        case FORMAT_SS:
          type = C.CONTENT_TYPE_SS;
          break;
        case FORMAT_DASH:
          type = C.CONTENT_TYPE_DASH;
          break;
        case FORMAT_HLS:
          type = C.CONTENT_TYPE_HLS;
          break;
        case FORMAT_OTHER:
          type = C.CONTENT_TYPE_OTHER;
          break;
        default:
          type = -1;
          break;
      }
    }

    switch (type) {
      case C.CONTENT_TYPE_SS:
        return new SsMediaSource.Factory(
            new DefaultSsChunkSource.Factory(mediaDataSourceFactory),
            new DefaultDataSource.Factory(context, mediaDataSourceFactory))
            .createMediaSource(MediaItem.fromUri(uri));
      case C.CONTENT_TYPE_DASH:
        return new DashMediaSource.Factory(
            new DefaultDashChunkSource.Factory(mediaDataSourceFactory),
            new DefaultDataSource.Factory(context, mediaDataSourceFactory))
            .createMediaSource(MediaItem.fromUri(uri));
      case C.CONTENT_TYPE_HLS:
        return new HlsMediaSource.Factory(mediaDataSourceFactory)
            .setAllowChunklessPreparation(true)
            .createMediaSource(MediaItem.fromUri(uri));
      case C.CONTENT_TYPE_OTHER:
        return new ProgressiveMediaSource.Factory(mediaDataSourceFactory)
            .createMediaSource(MediaItem.fromUri(uri));
      default: {
        throw new IllegalStateException("Unsupported type: " + type);
      }
    }
  }

  private void setUpVideoPlayer(ExoPlayer exoPlayer, QueuingEventSink eventSink) {
    this.exoPlayer = exoPlayer;
    this.eventSink = eventSink;

    eventChannel.setStreamHandler(
        new EventChannel.StreamHandler() {
          @Override
          public void onListen(Object o, EventChannel.EventSink sink) {
            eventSink.setDelegate(sink);
          }

          @Override
          public void onCancel(Object o) {
            eventSink.setDelegate(null);
          }
        });

    surface = new Surface(textureEntry.surfaceTexture());
    exoPlayer.setVideoSurface(surface);
    setAudioAttributes(exoPlayer, options.mixWithOthers);

    exoPlayer.addListener(
        new Listener() {
          private boolean isBuffering = false;

          public void setBuffering(boolean buffering) {
            if (isBuffering != buffering) {
              isBuffering = buffering;
              Map<String, Object> event = new HashMap<>();
              event.put("event", isBuffering ? "bufferingStart" : "bufferingEnd");
              eventSink.success(event);
            }
          }

          @Override
          public void onPlaybackStateChanged(final int playbackState) {
            if (playbackState == Player.STATE_BUFFERING) {
              setBuffering(true);
              sendBufferingUpdate();
            } else if (playbackState == Player.STATE_READY) {
              if (!isInitialized) {
                isInitialized = true;
                sendInitialized();
              }
              setBuffering(false);
            } else if (playbackState == Player.STATE_ENDED) {
              Map<String, Object> event = new HashMap<>();
              event.put("event", "completed");
              eventSink.success(event);
            }
          }

          @Override
          public void onPlayerError(final PlaybackException error) {
            setBuffering(false);
            if (eventSink != null) {
              eventSink.error("VideoError", "Video player had error " + error, null);
            }
          }
        });
  }

  void sendBufferingUpdate() {
    long currentTime = System.currentTimeMillis();
    if (currentTime - lastBufferUpdateTime < BUFFER_UPDATE_INTERVAL) {
      return; // 너무 자주 업데이트하지 않음
    }
    lastBufferUpdateTime = currentTime;

    Map<String, Object> event = new HashMap<>();
    event.put("event", "bufferingUpdate");
    List<? extends Number> range = Arrays.asList(0, exoPlayer.getBufferedPosition());
    event.put("values", Collections.singletonList(range));
    eventSink.success(event);
  }

  private static void setAudioAttributes(ExoPlayer exoPlayer, boolean isMixMode) {
    exoPlayer.setAudioAttributes(
        new AudioAttributes.Builder()
            .setContentType(C.AUDIO_CONTENT_TYPE_MOVIE)
            .setUsage(C.USAGE_MEDIA)
            .build(),
        !isMixMode);
  }

  void play() {
    // 활성화 모드: 20초까지 버퍼링 허용 + 디코더 리소스 유지(재버퍼링 감소)
    if (videoLoadControl != null) videoLoadControl.setActive(true);
    exoPlayer.setForegroundMode(true);
    exoPlayer.setPlayWhenReady(true);
  }

  void pause() {
    exoPlayer.setPlayWhenReady(false);
    // 프리로드 모드로 복귀: 5초만 버퍼링 + 디코더 리소스 해제(메모리 절약)
    if (videoLoadControl != null) videoLoadControl.setActive(false);
    exoPlayer.setForegroundMode(false);
  }

  void setLooping(boolean value) {
    exoPlayer.setRepeatMode(value ? Player.REPEAT_MODE_ALL : Player.REPEAT_MODE_OFF);
  }

  void setVolume(double value) {
    float bracketedValue = (float) Math.max(0.0, Math.min(1.0, value));
    exoPlayer.setVolume(bracketedValue);
  }

  void setPlaybackSpeed(double value) {
    final PlaybackParameters playbackParameters = new PlaybackParameters((float) value);
    exoPlayer.setPlaybackParameters(playbackParameters);
  }

  void seekTo(int location) {
    exoPlayer.seekTo(location);
  }

  long getPosition() {
    return exoPlayer.getCurrentPosition();
  }

  @SuppressWarnings("SuspiciousNameCombination")
  @VisibleForTesting
  void sendInitialized() {
    if (isInitialized) {
      Map<String, Object> event = new HashMap<>();
      event.put("event", "initialized");
      event.put("duration", exoPlayer.getDuration());

      if (exoPlayer.getVideoFormat() != null) {
        Format videoFormat = exoPlayer.getVideoFormat();
        int width = videoFormat.width;
        int height = videoFormat.height;
        int rotationDegrees = videoFormat.rotationDegrees;
        if (rotationDegrees == 90 || rotationDegrees == 270) {
          width = videoFormat.height;
          height = videoFormat.width;
        }
        event.put("width", width);
        event.put("height", height);

        if (rotationDegrees == 180) {
          event.put("rotationCorrection", rotationDegrees);
        }
      }

      eventSink.success(event);
    }
  }

  /**
   * 적응형 스트리밍 설정 - 틱톡 수준의 품질 관리
   */
  void setAdaptiveStreaming(boolean enableAdaptiveStreaming) {
    isAdaptiveStreamingEnabled = enableAdaptiveStreaming;
    if (trackSelector != null) {
      trackSelector.setParameters(
          trackSelector.buildUponParameters()
              .setMaxVideoBitrate(enableAdaptiveStreaming ? Integer.MAX_VALUE : 2000000)
              .setMaxVideoSize(enableAdaptiveStreaming ? Integer.MAX_VALUE : 1920,
                  enableAdaptiveStreaming ? Integer.MAX_VALUE : 1080)
              .setForceHighestSupportedBitrate(false)
              .setForceLowestBitrate(!enableAdaptiveStreaming)
              .setTunnelingEnabled(true) // 하드웨어 가속 활성화
      );
    }
  }

  boolean isAdaptiveStreamingEnabled() {
    return isAdaptiveStreamingEnabled;
  }

  /**
   * 프리로딩 활성화/비활성화
   */
  void setPreloadingEnabled(boolean enabled) {
    isPreloadingEnabled = enabled;
  }

  boolean isPreloadingEnabled() {
    return isPreloadingEnabled;
  }

  /**
   * 빠른 시작 활성화/비활성화
   */
  void setFastStartEnabled(boolean enabled) {
    isFastStartEnabled = enabled;
  }

  boolean isFastStartEnabled() {
    return isFastStartEnabled;
  }

  /**
   * 캐시 정리
   */
  public static void clearCache() {
    if (cache != null) {
      try {
        cache.release();
        cache = null;
      } catch (Exception e) {
        // 캐시 정리 실패 무시
      }
    }
    preloadedSources.clear();
  }

  /**
   * 메모리 최적화를 위한 정리
   */
  void dispose() {
    // ExoPlayer/Surface/TextureEntry 접근은 반드시 메인 스레드에서 실행해야 함
    // (백그라운드 스레드에서 호출 시 "Player is accessed on the wrong thread" 크래시)
    Runnable teardown = () -> {
      try {
        if (isInitialized && exoPlayer != null) {
          exoPlayer.stop();
        }
      } catch (Exception ignored) {
      }
      eventChannel.setStreamHandler(null);
      if (surface != null) {
        surface.release();
      }
      if (exoPlayer != null) {
        exoPlayer.release();
      }
      textureEntry.release();
    };

    if (Looper.myLooper() == Looper.getMainLooper()) {
      teardown.run();
    } else {
      mainHandler.post(teardown);
    }
  }

  /**
   * TikTok-style dynamic load control
   * - 프리로드(화면 밖): 5초만 버퍼링
   * - 활성화(화면에 보일 때): 20초까지 버퍼링
   *
   * DefaultLoadControl을 상속하여 lifecycle 메서드(onPrepared/onStopped/onReleased/
   * onTracksSelected/getAllocator)는 부모 구현을 그대로 사용하고,
   * 버퍼링 판단 로직만 동적으로 오버라이드한다. (media3 1.4.1 호환)
   */
  private static final class VideoLoadControl extends DefaultLoadControl {
    private volatile boolean isActive = false;

    // 프리로드: 최소 2초, 최대 5초
    private static final long PRELOAD_MIN_US = 2_000_000L;
    private static final long PRELOAD_MAX_US = 5_000_000L;

    // 활성화: 최소 3초, 최대 20초
    private static final long ACTIVE_MIN_US  = 3_000_000L;
    private static final long ACTIVE_MAX_US  = 20_000_000L;

    // 재생 시작 버퍼: 300ms (빠른 스타트)
    private static final long PLAYBACK_START_US   = 300_000L;
    private static final long REBUFFER_START_US   = 1_500_000L;

    VideoLoadControl() {
      // allocator 메모리 풀이 활성화 모드(20초)를 감당하도록 buffer 상한 설정
      super(
          new DefaultAllocator(true, C.DEFAULT_BUFFER_SEGMENT_SIZE),
          /* minBufferMs= */ 2000,
          /* maxBufferMs= */ 20000,
          /* bufferForPlaybackMs= */ 300,
          /* bufferForPlaybackAfterRebufferMs= */ 1500,
          /* targetBufferBytes= */ C.LENGTH_UNSET,
          /* prioritizeTimeOverSizeThresholds= */ true,
          /* backBufferDurationMs= */ 0,
          /* retainBackBufferFromKeyframe= */ false);
    }

    void setActive(boolean active) {
      this.isActive = active;
    }

    @Override
    public boolean shouldContinueLoading(LoadControl.Parameters p) {
      // 프리로드(정지)든 활성(재생)이든 상한까지는 무조건 채운다.
      // → 화면 밖 영상도 미리 5초를 확보해 두어 스와이프 즉시 재생 가능.
      long maxUs = isActive ? ACTIVE_MAX_US : PRELOAD_MAX_US;
      return p.bufferedDurationUs < maxUs;
    }

    @Override
    public boolean shouldStartPlayback(LoadControl.Parameters p) {
      long target = p.rebuffering ? REBUFFER_START_US : PLAYBACK_START_US;
      return p.bufferedDurationUs >= target;
    }
  }

  public static VideoPlayer create(
      Context context,
      EventChannel.StreamHandler eventHandler,
      TextureRegistry.SurfaceTextureEntry textureEntry,
      VideoAsset videoAsset,
      VideoPlayerOptions options,
      BinaryMessenger binaryMessenger) {

    if (videoAsset == null) {
      throw new IllegalArgumentException("videoAsset cannot be null");
    }

    EventChannel eventChannel = new EventChannel(
        binaryMessenger,
        "flutter.io/videoPlayer/videoEvents" + textureEntry.id());
    eventChannel.setStreamHandler(eventHandler);

    try {
      return new VideoPlayer(
          context,
          eventChannel,
          textureEntry,
          videoAsset.getUri().toString(),
          videoAsset.getFormatHint(),
          videoAsset.getHttpHeaders(),
          options);
    } catch (IllegalStateException e) {
      throw new IllegalArgumentException("Invalid video asset: " + e.getMessage());
    }
  }
}
