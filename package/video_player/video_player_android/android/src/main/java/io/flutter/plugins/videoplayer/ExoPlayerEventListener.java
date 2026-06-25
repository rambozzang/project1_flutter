// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.plugins.videoplayer;

import android.os.Build;
import android.os.Handler;
import android.os.Looper;
import androidx.annotation.NonNull;
import androidx.annotation.OptIn;
import androidx.media3.common.Format;
import androidx.media3.common.PlaybackException;
import androidx.media3.common.Player;
import androidx.media3.common.VideoSize;
import androidx.media3.exoplayer.ExoPlayer;
import java.util.Objects;

/**
 * TikTok-level optimized ExoPlayer event listener with enhanced performance
 * monitoring
 */
final class ExoPlayerEventListener implements Player.Listener {
  private final ExoPlayer exoPlayer;
  private final VideoPlayerCallbacks events;
  private boolean isBuffering = false;
  private boolean isInitialized;

  // Performance optimization fields
  private long lastBufferUpdateTime = 0;
  private static final long BUFFER_UPDATE_INTERVAL = 100; // 100ms
  private Handler mainHandler = new Handler(Looper.getMainLooper());
  private Runnable bufferUpdateRunnable;
  private boolean isPerformanceMonitoringEnabled = true;
  private long initializationStartTime = 0;

  private enum RotationDegrees {
    ROTATE_0(0),
    ROTATE_90(90),
    ROTATE_180(180),
    ROTATE_270(270);

    private final int degrees;

    RotationDegrees(int degrees) {
      this.degrees = degrees;
    }

    public static RotationDegrees fromDegrees(int degrees) {
      for (RotationDegrees rotationDegrees : RotationDegrees.values()) {
        if (rotationDegrees.degrees == degrees) {
          return rotationDegrees;
        }
      }
      throw new IllegalArgumentException("Invalid rotation degrees specified: " + degrees);
    }

    public int getDegrees() {
      return this.degrees;
    }
  }

  ExoPlayerEventListener(ExoPlayer exoPlayer, VideoPlayerCallbacks events) {
    this(exoPlayer, events, false);
  }

  ExoPlayerEventListener(ExoPlayer exoPlayer, VideoPlayerCallbacks events, boolean initialized) {
    this.exoPlayer = exoPlayer;
    this.events = events;
    this.isInitialized = initialized;
    this.initializationStartTime = System.currentTimeMillis();

    // 버퍼 업데이트 최적화를 위한 Runnable 설정
    this.bufferUpdateRunnable = new Runnable() {
      @Override
      public void run() {
        if (isBuffering && exoPlayer != null) {
          events.onBufferingUpdate(exoPlayer.getBufferedPosition());
          mainHandler.postDelayed(this, BUFFER_UPDATE_INTERVAL);
        }
      }
    };
  }

  private void setBuffering(boolean buffering) {
    if (isBuffering == buffering) {
      return;
    }

    isBuffering = buffering;

    if (buffering) {
      events.onBufferingStart();
      // 최적화된 버퍼 업데이트 시작
      startOptimizedBufferUpdates();
    } else {
      events.onBufferingEnd();
      // 버퍼 업데이트 중지
      stopOptimizedBufferUpdates();
    }
  }

  /**
   * 최적화된 버퍼 업데이트 시작
   */
  private void startOptimizedBufferUpdates() {
    mainHandler.removeCallbacks(bufferUpdateRunnable);
    mainHandler.post(bufferUpdateRunnable);
  }

  /**
   * 버퍼 업데이트 중지
   */
  private void stopOptimizedBufferUpdates() {
    mainHandler.removeCallbacks(bufferUpdateRunnable);
  }

  @SuppressWarnings("SuspiciousNameCombination")
  private void sendInitialized() {
    if (isInitialized) {
      return;
    }

    isInitialized = true;

    // 초기화 시간 측정 (성능 모니터링)
    if (isPerformanceMonitoringEnabled) {
      long initializationTime = System.currentTimeMillis() - initializationStartTime;
      // 로그나 분석을 위해 초기화 시간을 기록할 수 있음
    }

    VideoSize videoSize = exoPlayer.getVideoSize();
    int rotationCorrection = 0;
    int width = videoSize.width;
    int height = videoSize.height;

    if (width != 0 && height != 0) {
      RotationDegrees reportedRotationCorrection = RotationDegrees.ROTATE_0;

      if (Build.VERSION.SDK_INT <= 21) {
        // On API 21 and below, Exoplayer may not internally handle rotation correction
        // and reports it through VideoSize.unappliedRotationDegrees. We may apply it to
        // fix the case of upside-down playback.
        try {
          reportedRotationCorrection = RotationDegrees.fromDegrees(videoSize.unappliedRotationDegrees);
          rotationCorrection = getRotationCorrectionFromUnappliedRotation(reportedRotationCorrection);
        } catch (IllegalArgumentException e) {
          // Unapplied rotation other than 0, 90, 180, 270 reported by VideoSize. Because
          // this is unexpected,
          // we apply no rotation correction.
          reportedRotationCorrection = RotationDegrees.ROTATE_0;
          rotationCorrection = 0;
        }
      }
      // TODO(camsim99): Replace this with a call to `handlesCropAndRotation` when it
      // is
      // available in stable. https://github.com/flutter/flutter/issues/157198
      else if (Build.VERSION.SDK_INT < 29) {
        // When the SurfaceTexture backend for Impeller is used, the preview should
        // already
        // be correctly rotated.
        rotationCorrection = 0;
      } else {
        // The video's Format also provides a rotation correction that may be used to
        // correct the rotation, so we try to use that to correct the video rotation
        // when the ImageReader backend for Impeller is used.
        rotationCorrection = getRotationCorrectionFromFormat(exoPlayer);

        try {
          reportedRotationCorrection = RotationDegrees.fromDegrees(rotationCorrection);
        } catch (IllegalArgumentException e) {
          // Rotation correction other than 0, 90, 180, 270 reported by Format. Because
          // this is unexpected,
          // we apply no rotation correction.
          reportedRotationCorrection = RotationDegrees.ROTATE_0;
          rotationCorrection = 0;
        }
      }

      // Switch the width/height if video was taken in portrait mode and a rotation
      // correction was detected.
      if (reportedRotationCorrection == RotationDegrees.ROTATE_90
          || reportedRotationCorrection == RotationDegrees.ROTATE_270) {
        width = videoSize.height;
        height = videoSize.width;
      }
    }

    events.onInitialized(width, height, exoPlayer.getDuration(), rotationCorrection);
  }

  private int getRotationCorrectionFromUnappliedRotation(RotationDegrees unappliedRotationDegrees) {
    int rotationCorrection = 0;

    // Rotating the video with ExoPlayer does not seem to be possible with a
    // Surface,
    // so inform the Flutter code that the widget needs to be rotated to prevent
    // upside-down playback for videos with unappliedRotationDegrees of 180 (other
    // orientations
    // work correctly without correction).
    if (unappliedRotationDegrees == RotationDegrees.ROTATE_180) {
      rotationCorrection = unappliedRotationDegrees.getDegrees();
    }

    return rotationCorrection;
  }

  @OptIn(markerClass = androidx.media3.common.util.UnstableApi.class)
  // A video's Format and its rotation degrees are unstable because they are not
  // guaranteed
  // the same implementation across API versions. It is possible that this logic
  // may need
  // revisiting should the implementation change across versions of the Exoplayer
  // API.
  private int getRotationCorrectionFromFormat(ExoPlayer exoPlayer) {
    Format videoFormat = Objects.requireNonNull(exoPlayer.getVideoFormat());
    return videoFormat.rotationDegrees;
  }

  @Override
  public void onPlaybackStateChanged(final int playbackState) {
    switch (playbackState) {
      case Player.STATE_BUFFERING:
        setBuffering(true);
        break;
      case Player.STATE_READY:
        setBuffering(false);
        sendInitialized();
        break;
      case Player.STATE_ENDED:
        setBuffering(false);
        events.onCompleted();
        break;
      case Player.STATE_IDLE:
        setBuffering(false);
        break;
    }
  }

  @Override
  public void onPlayerError(@NonNull final PlaybackException error) {
    setBuffering(false);

    // 향상된 에러 처리
    if (error.errorCode == PlaybackException.ERROR_CODE_BEHIND_LIVE_WINDOW) {
      // See
      // https://exoplayer.dev/live-streaming.html#behindlivewindowexception-and-error_code_behind_live_window
      try {
        exoPlayer.seekToDefaultPosition();
        exoPlayer.prepare();
      } catch (Exception e) {
        events.onError("VideoError", "Failed to recover from behind live window: " + e.getMessage(), null);
      }
    } else if (error.errorCode == PlaybackException.ERROR_CODE_IO_NETWORK_CONNECTION_FAILED ||
        error.errorCode == PlaybackException.ERROR_CODE_IO_NETWORK_CONNECTION_TIMEOUT) {
      // 네트워크 에러 처리
      events.onError("NetworkError", "Network connection failed: " + error.getMessage(), null);
    } else if (error.errorCode == PlaybackException.ERROR_CODE_DECODER_INIT_FAILED ||
        error.errorCode == PlaybackException.ERROR_CODE_DECODER_QUERY_FAILED) {
      // 디코더 에러 처리
      events.onError("DecoderError", "Video decoder error: " + error.getMessage(), null);
    } else {
      events.onError("VideoError", "Video player had error " + error, null);
    }
  }

  @Override
  public void onIsPlayingChanged(boolean isPlaying) {
    events.onIsPlayingStateUpdate(isPlaying);

    // 재생 상태 변경 시 버퍼링 최적화
    if (!isPlaying && isBuffering) {
      // 재생이 중지되었지만 여전히 버퍼링 중인 경우 버퍼 업데이트 빈도 조정
      stopOptimizedBufferUpdates();
    }
  }

  /**
   * 성능 모니터링 활성화/비활성화
   */
  public void setPerformanceMonitoringEnabled(boolean enabled) {
    this.isPerformanceMonitoringEnabled = enabled;
  }

  /**
   * 리소스 정리
   */
  public void dispose() {
    stopOptimizedBufferUpdates();
    if (mainHandler != null) {
      mainHandler.removeCallbacksAndMessages(null);
    }
  }
}
