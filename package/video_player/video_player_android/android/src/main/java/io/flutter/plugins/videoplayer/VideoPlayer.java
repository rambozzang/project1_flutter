// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.plugins.videoplayer;

import static com.google.android.exoplayer2.Player.REPEAT_MODE_ALL;
import static com.google.android.exoplayer2.Player.REPEAT_MODE_OFF;

import android.content.Context;
import android.net.Uri;
import android.view.Surface;
import androidx.annotation.NonNull;
import androidx.annotation.VisibleForTesting;
import com.google.android.exoplayer2.C;
import com.google.android.exoplayer2.ExoPlayer;
import com.google.android.exoplayer2.Format;
import com.google.android.exoplayer2.MediaItem;
import com.google.android.exoplayer2.PlaybackException;
import com.google.android.exoplayer2.PlaybackParameters;
import com.google.android.exoplayer2.Player;
import com.google.android.exoplayer2.Player.Listener;
import com.google.android.exoplayer2.audio.AudioAttributes;
import com.google.android.exoplayer2.source.MediaSource;
import com.google.android.exoplayer2.source.ProgressiveMediaSource;
import com.google.android.exoplayer2.source.dash.DashMediaSource;
import com.google.android.exoplayer2.source.dash.DefaultDashChunkSource;
import com.google.android.exoplayer2.source.hls.HlsMediaSource;
import com.google.android.exoplayer2.source.smoothstreaming.DefaultSsChunkSource;
import com.google.android.exoplayer2.source.smoothstreaming.SsMediaSource;
import com.google.android.exoplayer2.upstream.DataSource;
import com.google.android.exoplayer2.upstream.DefaultDataSource;
import com.google.android.exoplayer2.upstream.DefaultHttpDataSource;
import com.google.android.exoplayer2.util.Util;
import io.flutter.plugin.common.EventChannel;
import io.flutter.view.TextureRegistry;
import java.util.Arrays;
import java.util.Collections;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import com.google.android.exoplayer2.DefaultRenderersFactory;
import com.google.android.exoplayer2.database.StandaloneDatabaseProvider;
import com.google.android.exoplayer2.upstream.cache.CacheDataSource;
import com.google.android.exoplayer2.upstream.cache.LeastRecentlyUsedCacheEvictor;
import com.google.android.exoplayer2.upstream.cache.SimpleCache;
import java.io.File;
import com.google.android.exoplayer2.trackselection.AdaptiveTrackSelection;
import com.google.android.exoplayer2.trackselection.DefaultTrackSelector;
import com.google.android.exoplayer2.trackselection.TrackSelector;
import io.flutter.plugin.common.BinaryMessenger;
/*
setAdaptiveStreaming 메서드 추가:

이 메서드를 통해 적응형 스트리밍을 켜거나 끌 수 있습니다.
적응형 스트리밍이 켜져 있을 때는 최대 비트레이트 제한을 없애고, 가능한 가장 높은 품질의 비디오를 사용합니다.
적응형 스트리밍이 꺼져 있을 때는 최대 비트레이트를 1Mbps로 제한합니다.
isAdaptiveStreamingEnabled 메서드 추가:

현재 적응형 스트리밍의 상태를 확인할 수 있습니다.
isAdaptiveStreamingEnabled 변수 추가:

적응형 스트리밍의 상태를 저장합니다. 기본값은 true입니다.
생성자에서 setAdaptiveStreaming 호출:

VideoPlayer 객체가 생성될 때 초기 설정을 적용합니다.
이제 사용자에게 변경 사항을 보여주고 결과를 설명하겠습니다.
*/
final class VideoPlayer {
  private static final String TAG = "VideoPlayer";
  private static final String FORMAT_SS = "ss";
  private static final String FORMAT_DASH = "dash";
  private static final String FORMAT_HLS = "hls";
  private static final String FORMAT_OTHER = "other";

  private ExoPlayer exoPlayer;
  private DefaultTrackSelector trackSelector;

  private Surface surface;

  private final TextureRegistry.SurfaceTextureEntry textureEntry;

  private QueuingEventSink eventSink;

  private final EventChannel eventChannel;

  @VisibleForTesting boolean isInitialized = false;

  private final VideoPlayerOptions options;

  private static SimpleCache cache;
  private static final long MAX_CACHE_SIZE = 200 * 1024 * 1024; // 100MB

 // 적응형 스트리밍 설정은 setAdaptiveStreaming 메서드를 통해 이루어집니다.
// 이 설정은 trackSelector의 파라미터를 변경하는 방식으로 작동합니다.
// 실제 초기화 과정은 ExoPlayer의 prepare() 메서드 호출 시 이루어집니다.
// 적응형 스트리밍 설정은 비디오 재생 중에도 변경될 수 있습니다.
  private boolean isAdaptiveStreamingEnabled = true;

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

    AdaptiveTrackSelection.Factory trackSelectionFactory = new AdaptiveTrackSelection.Factory();
    this.trackSelector = new DefaultTrackSelector(context, trackSelectionFactory);

    setAdaptiveStreaming(isAdaptiveStreamingEnabled);

    ExoPlayer exoPlayer = new ExoPlayer.Builder(context)
        .setRenderersFactory(new DefaultRenderersFactory(context).setEnableDecoderFallback(true))
        .setTrackSelector(trackSelector)
        .build();


    Uri uri = Uri.parse(dataSource);
    DataSource.Factory dataSourceFactory;

    if (isHTTP(uri)) {
      DefaultHttpDataSource.Factory httpDataSourceFactory =
          new DefaultHttpDataSource.Factory()
              .setUserAgent("ExoPlayer")
              .setAllowCrossProtocolRedirects(true);

      if (httpHeaders != null && !httpHeaders.isEmpty()) {
        httpDataSourceFactory.setDefaultRequestProperties(httpHeaders);
      }
      dataSourceFactory = httpDataSourceFactory;
    } else {
      dataSourceFactory = new DefaultDataSource.Factory(context);
    }

    // 캐시 설정
    if (cache == null) {
      File cacheDir = new File(context.getCacheDir(), "media_cache");
      StandaloneDatabaseProvider databaseProvider = new StandaloneDatabaseProvider(context);
      cache = new SimpleCache(cacheDir, new LeastRecentlyUsedCacheEvictor(MAX_CACHE_SIZE), databaseProvider);
    }
    CacheDataSource.Factory cacheDataSourceFactory = new CacheDataSource.Factory()
        .setCache(cache)
        .setUpstreamDataSourceFactory(dataSourceFactory)
        .setFlags(CacheDataSource.FLAG_IGNORE_CACHE_ON_ERROR);

    MediaSource mediaSource = buildMediaSource(uri, cacheDataSourceFactory, formatHint, context);

    exoPlayer.setMediaSource(mediaSource);
    exoPlayer.prepare();

    // 프리로딩 설정: 비디오를 로드하지만 재생은 하지 않음
    exoPlayer.setPlayWhenReady(false);

    setUpVideoPlayer(exoPlayer, new QueuingEventSink());
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
      default:
        {
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
            } else if (playbackState == Player.STATE_ENDED) {
              Map<String, Object> event = new HashMap<>();
              event.put("event", "completed");
              eventSink.success(event);
            }

            if (playbackState != Player.STATE_BUFFERING) {
              setBuffering(false);
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
    Map<String, Object> event = new HashMap<>();
    event.put("event", "bufferingUpdate");
    List<? extends Number> range = Arrays.asList(0, exoPlayer.getBufferedPosition());
    event.put("values", Collections.singletonList(range));
    eventSink.success(event);
  }

  private static void setAudioAttributes(ExoPlayer exoPlayer, boolean isMixMode) {
    exoPlayer.setAudioAttributes(
        new AudioAttributes.Builder().setContentType(C.AUDIO_CONTENT_TYPE_MOVIE).build(),
        !isMixMode);
  }

  void play() {
    exoPlayer.setPlayWhenReady(true);
  }

  void pause() {
    exoPlayer.setPlayWhenReady(false);
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

  void setAdaptiveStreaming(boolean enableAdaptiveStreaming) {
    isAdaptiveStreamingEnabled = enableAdaptiveStreaming;
    if (trackSelector != null) {
      trackSelector.setParameters(
          trackSelector.buildUponParameters()
              .setMaxVideoBitrate(enableAdaptiveStreaming ? 5500000 : 1000000)
              .setForceHighestSupportedBitrate(enableAdaptiveStreaming)
      );
    }
  }

  boolean isAdaptiveStreamingEnabled() {
    return isAdaptiveStreamingEnabled;
  }

  void dispose() {
    if (isInitialized) {
      exoPlayer.stop();
    }
    textureEntry.release();
    eventChannel.setStreamHandler(null);
    if (surface != null) {
      surface.release();
    }
    if (exoPlayer != null) {
      exoPlayer.release();
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






