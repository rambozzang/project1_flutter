package com.codelabtiger.skysnap

import android.content.Context
import android.os.Handler
import android.os.Looper
import androidx.annotation.OptIn
import androidx.media3.common.C
import androidx.media3.common.MediaItem
import androidx.media3.common.PlaybackException
import androidx.media3.common.Player
import androidx.media3.common.VideoSize
import androidx.media3.common.util.UnstableApi
import androidx.media3.exoplayer.DefaultLoadControl
import androidx.media3.exoplayer.ExoPlayer
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.view.TextureRegistry

/**
 * 몰입뷰 전용 영상 플레이어 — **플레이어를 돌려쓴다.**
 *
 * ## 왜 만들었나
 * `video_player` 플러그인은 페이지마다 ExoPlayer 를 새로 만들고 버린다. 그리고
 * `DefaultLoadControl` 의 **뒤 버퍼만** 열어 줘서, 메모리를 먹는 앞 버퍼
 * (기본 50초 · 플레이어당 최대 125MB)를 줄일 방법이 없다.
 *
 * 실기기(SM-S926N)에서 잰 결과 몰입뷰만으로 자바 힙이 87~145MB 였고, 상한
 * 256MB 를 쳐서 앱이 두 번 죽었다(2026-09-16, 09-19 OOM).
 *
 * ## 무엇이 달라지나
 * 1. **버퍼를 줄인다** — 50초 → 8초, 목표 바이트 12.5MB → 2MB.
 * 2. **플레이어를 돌려쓴다** — [POOL_SIZE] 개만 만들어 두고 슬롯을 배정한다.
 *    만들고 버리는 비용(디코더 확보·표면 연결)이 스와이프마다 사라진다.
 * 3. **미리 준비한다** — 슬롯을 잡는 순간 `prepare()` 까지 해 둔다. 스와이프가
 *    도착했을 때는 이미 첫 프레임이 준비돼 있어 바로 재생된다.
 *
 * ## 슬롯 모델
 * Dart 는 "이 URL 을 틀 슬롯을 다오"([acquire])라고 요청하고, 네이티브는 비어
 * 있거나 가장 오래된 슬롯을 내준다. **같은 URL 을 이미 물고 있으면 그대로
 * 돌려준다** — 앞뒤로 오갈 때 다시 준비하지 않는다.
 */
@OptIn(UnstableApi::class)
class MomoVideo(
    private val context: Context,
    private val textures: TextureRegistry,
    private val channel: MethodChannel,
) {
    companion object {
        const val CHANNEL = "com.codelabtiger.momoalbum/momo_video"
        private const val TAG = "MomoVideo"

        /**
         * 동시에 살려두는 플레이어 수.
         *
         * **8** 이다. 처음에 3~4로 줄였다가 스와이프가 준비를 앞질러
         * "예전엔 틱톡처럼 바로 나왔는데 성능이 확 떨어졌다"는 제보를 받았다
         * (2026-09-19). 줄이는 게 목적이 아니었다.
         *
         * 이 구조의 이점은 **적게 무는 것이 아니라 같은 메모리로 더 많이 무는
         * 것**이다. 기본 플러그인은 플레이어당 버퍼가 최대 125MB 라 7개만 물어도
         * 힙이 터졌지만, 여기서는 8MB 로 묶어 뒀다. 8개를 물어도 64MB 다.
         *
         * 창(`album_immersive_page._videoWindow` = 3, 7페이지)보다 하나 크게
         * 잡는다 — 페이지가 넘어가는 찰나에 떠나는 쪽이 아직 반납하기 전이라
         * 딱 맞게 두면 요청이 거절된다(`no_slot`).
         */
        private const val POOL_SIZE = 8

        // 버퍼 설정.
        //
        // ⚠️ 처음에 2초/8초 · 2MB 로 잡았다가 **재생이 계속 끊겼다**(2026-09-19).
        // 로그에 STATE_READY 가 465ms 간격으로 반복해 찍혔다 — 준비와 버퍼링을
        // 오간다는 뜻이다. 사장님 눈에는 "첫 영상이 6초나 걸린다"로 보였다.
        //
        // 이유는 단순하다. Cloudflare Stream 세로 영상이 대략 2~5Mbps 인데
        // 2MB 면 3초도 못 담는다. 받자마자 소진하니 다시 버퍼링이다.
        // 메모리를 아끼려다 재생을 망치면 아무 의미가 없다.
        private const val MIN_BUFFER_MS = 5_000
        private const val MAX_BUFFER_MS = 15_000
        private const val BUFFER_FOR_PLAYBACK_MS = 500
        private const val BUFFER_FOR_REBUFFER_MS = 2_000

        /**
         * 플레이어당 목표 버퍼 바이트.
         *
         * 기본값(`DEFAULT_VIDEO_BUFFER_SIZE`)은 **131,072,000(125MB)** 이다.
         * 짧은 세로 영상에는 터무니없이 크다. 8MB 면 5Mbps 기준 13초 정도를
         * 담아 [MAX_BUFFER_MS] 를 채우고도 남는다.
         *
         * 플레이어 4개 × 8MB = 32MB. 예전 방식(플레이어 7개 × 기본 버퍼)이
         * 실측 100~145MB 였던 것에 비하면 여전히 1/4 이하다.
         */
        private const val TARGET_BUFFER_BYTES = 8 * 1024 * 1024

        /** 표면을 열 때 쓰는 초기 크기. 실제 크기는 onVideoSizeChanged 로 바꾼다. */
        private const val DEFAULT_SURFACE_WIDTH = 1080
        private const val DEFAULT_SURFACE_HEIGHT = 1920
    }

    private val main = Handler(Looper.getMainLooper())

    /** 슬롯 하나. 플레이어와 텍스처는 **한 번 만들면 계속 쓴다.** */
    private class Slot(
        val id: Int,
        val player: ExoPlayer,
        val surface: TextureRegistry.SurfaceProducer,
    ) {
        /** 지금 물고 있는 URL. 같은 걸 또 요청하면 준비를 건너뛴다. */
        var url: String? = null

        /** 마지막으로 배정된 시각 — 가장 오래된 슬롯을 밀어낼 때 쓴다. */
        var touchedAt: Long = 0

        /** Dart 가 이 슬롯을 지금 쓰고 있나. 쓰는 중이면 밀어내지 않는다. */
        var inUse: Boolean = false

        /** prepare 를 부른 시각 — 준비까지 걸린 시간을 재는 데 쓴다. */
        var preparedAt: Long = 0

        /**
         * 표면에 마지막으로 알려 준 영상 크기. 0 이면 아직 안 알려 줬다.
         *
         * **되먹임을 끊는 데 쓴다.** `setVideoSurface` 를 부르면 ExoPlayer 가
         * 표면이 바뀐 줄 알고 `onVideoSizeChanged` 를 다시 낸다 → 거기서 또
         * `setVideoSurface` → 끝없이 돈다. 실측 148,700 회/1분(2026-09-20).
         */
        var surfaceW: Int = 0
        var surfaceH: Int = 0

        /** READY 가 온 시각 / 첫 프레임이 그려진 시각. 그 사이가 검은 구간이다. */
        var readyAt: Long = 0
        var firstFrameAt: Long = 0
    }

    private val slots = mutableListOf<Slot>()
    private var released = false

    // ── Dart 에서 오는 호출 ──

    fun handle(call: MethodCall, result: MethodChannel.Result) {
        if (released) {
            result.error("released", "MomoVideo 가 이미 정리되었습니다.", null)
            return
        }
        try {
            when (call.method) {
                "acquire" -> acquire(call, result)
                "release" -> {
                    slotOf(call)?.let { freeSlot(it) }
                    result.success(true)
                }
                "play" -> withSlot(call, result) { it.player.play() }
                "pause" -> withSlot(call, result) { it.player.pause() }
                "seekTo" -> withSlot(call, result) {
                    it.player.seekTo((call.argument<Number>("ms") ?: 0).toLong())
                }
                "setLooping" -> withSlot(call, result) {
                    it.player.repeatMode =
                        if (call.argument<Boolean>("looping") == true) Player.REPEAT_MODE_ONE
                        else Player.REPEAT_MODE_OFF
                }
                "setVolume" -> withSlot(call, result) {
                    it.player.volume = (call.argument<Number>("volume") ?: 1).toFloat()
                }
                "position" -> {
                    val slot = slotOf(call)
                    result.success(slot?.player?.currentPosition ?: 0L)
                }
                "disposeAll" -> {
                    releaseAll()
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        } catch (e: Exception) {
            result.error("momo_video", e.message, null)
        }
    }

    private fun slotOf(call: MethodCall): Slot? {
        val id = call.argument<Number>("slot")?.toInt() ?: return null
        return slots.firstOrNull { it.id == id }
    }

    private inline fun withSlot(
        call: MethodCall,
        result: MethodChannel.Result,
        body: (Slot) -> Unit,
    ) {
        val slot = slotOf(call)
        if (slot == null) {
            // 슬롯이 이미 밀려났을 수 있다. 화면은 다음 프레임에 정리되므로
            // 오류로 만들지 않는다 — 여기서 던지면 Dart 쪽이 빨간 화면이 된다.
            result.success(false)
            return
        }
        body(slot)
        result.success(true)
    }

    /**
     * URL 을 틀 슬롯을 배정한다.
     *
     * @return `{slot, textureId, reused}` — `reused` 면 이미 준비된 것이라
     *         Dart 는 기다릴 필요가 없다.
     */
    private fun acquire(call: MethodCall, result: MethodChannel.Result) {
        val url = call.argument<String>("url")
        if (url.isNullOrBlank()) {
            result.error("bad_args", "url 이 없습니다.", null)
            return
        }

        // 1) 이미 이 URL 을 물고 있는 슬롯이 있으면 그대로 쓴다.
        slots.firstOrNull { it.url == url }?.let { hit ->
            hit.inUse = true
            hit.touchedAt = System.nanoTime()
            result.success(payload(hit, reused = true))
            return
        }

        // 2) 없으면 새로 만들거나(풀이 덜 찼으면) 가장 오래된 것을 밀어낸다.
        val slot = if (slots.size < POOL_SIZE) newSlot() else evictOldest()
        if (slot == null) {
            result.error("no_slot", "쓸 수 있는 슬롯이 없습니다.", null)
            return
        }

        slot.url = url
        slot.inUse = true
        slot.touchedAt = System.nanoTime()
        // 준비에 걸린 시간을 잰다. "첫 영상이 늦게 뜬다"는 제보가 오면 추측하지
        // 말고 이 값을 먼저 봐야 한다 — 네트워크인지 디코더인지 여기서 갈린다.
        slot.preparedAt = System.currentTimeMillis()
        // 새 영상이다 — 준비·첫 프레임 시각을 처음부터 다시 잰다.
        slot.readyAt = 0
        slot.firstFrameAt = 0
        android.util.Log.i(TAG, "acquire slot=${slot.id} ${url.takeLast(40)}")
        slot.player.apply {
            setMediaItem(MediaItem.fromUri(url))
            // 여기서 prepare 까지 해 둔다. 스와이프가 도착하면 바로 재생된다.
            prepare()
        }
        result.success(payload(slot, reused = false))
    }

    private fun payload(slot: Slot, reused: Boolean) = mapOf(
        "slot" to slot.id,
        "textureId" to slot.surface.id(),
        "reused" to reused,
    )

    // ── 슬롯 관리 ──

    private fun newSlot(): Slot {
        val surface = textures.createSurfaceProducer()
        // ⚠️ **크기를 먼저 준 다음** 표면을 가져와야 한다.
        //
        // 크기를 주기 전의 `getSurface()` 는 쓸 수 없는 표면을 돌려준다. 그걸
        // 플레이어에 붙이면 재생·스크러버는 멀쩡한데 **그림만 안 나온다**
        // (2026-09-19: 소리만 나고 화면이 검었다). 실제 영상 크기는 나중에
        // onVideoSizeChanged 로 오므로, 여기서는 흔한 세로 영상 크기로 열어 둔다.
        surface.setSize(DEFAULT_SURFACE_WIDTH, DEFAULT_SURFACE_HEIGHT)
        val player = ExoPlayer.Builder(context)
            .setLoadControl(
                DefaultLoadControl.Builder()
                    .setBufferDurationsMs(
                        MIN_BUFFER_MS,
                        MAX_BUFFER_MS,
                        BUFFER_FOR_PLAYBACK_MS,
                        BUFFER_FOR_REBUFFER_MS,
                    )
                    .setTargetBufferBytes(TARGET_BUFFER_BYTES)
                    // 시간을 우선한다. 크기를 우선하면 목표 바이트에 먼저 걸려
                    // MAX_BUFFER_MS 를 못 채우고, 그대로 끊김으로 이어진다.
                    // 상한은 setTargetBufferBytes 가 이미 잡고 있다.
                    .setPrioritizeTimeOverSizeThresholds(true)
                    .build()
            )
            .build()

        val slot = Slot(slots.size, player, surface)
        player.setVideoSurface(surface.surface)
        // 앱이 백그라운드에 다녀오면 표면이 버려졌다가 다시 만들어진다.
        // 다시 붙이지 않으면 돌아왔을 때 소리만 나고 화면이 검다.
        surface.setCallback(object : TextureRegistry.SurfaceProducer.Callback {
            override fun onSurfaceAvailable() {
                player.setVideoSurface(surface.surface)
                surface.scheduleFrame()
            }

            override fun onSurfaceCleanup() {
                player.setVideoSurface(null)
            }
        })
        player.addListener(object : Player.Listener {
            override fun onPlaybackStateChanged(state: Int) {
                if (state == Player.STATE_READY) {
                    // 첫 READY 만 잰다. 재생 중 버퍼링에서 돌아올 때마다 찍으면
                    // 값이 계속 누적돼 "준비에 10초" 같은 거짓말이 된다.
                    if (slot.preparedAt > 0) {
                        val ms = System.currentTimeMillis() - slot.preparedAt
                        android.util.Log.i(TAG, "ready slot=${slot.id} ${ms}ms")
                        slot.preparedAt = 0
                    } else {
                        android.util.Log.i(TAG, "rebuffered slot=${slot.id}")
                    }
                    if (slot.readyAt == 0L) slot.readyAt = System.currentTimeMillis()
                    notifyReady(slot)
                }
                if (state == Player.STATE_ENDED) send("ended", slot)
            }

            /**
             * **그림이 실제로 화면에 올라온 순간.** 진단용으로만 남긴다.
             *
             * `STATE_READY` 는 "틀 준비가 됐다"이지 "그려졌다"가 아니라서, 그
             * 사이에 텍스처가 검을까 봐 쟀다. **아니었다** — 실측하면 첫 프레임이
             * READY 와 같거나 **먼저** 온다(2026-09-20: `ready+-1ms`·`ready+1ms`).
             * 그러니 READY 에 맞춰 영상을 보여 줘도 검은 구간은 없다.
             * 깜빡임의 진짜 원인은 Dart 쪽 교차 페이드였다
             * (`immersive_media_view._buildVideo` 주석).
             */
            override fun onRenderedFirstFrame() {
                if (slot.firstFrameAt != 0L) return
                slot.firstFrameAt = System.currentTimeMillis()
                val gap =
                    if (slot.readyAt > 0) slot.firstFrameAt - slot.readyAt else -1
                android.util.Log.i(TAG, "firstFrame slot=${slot.id} ready+${gap}ms")
            }

            /**
             * 비디오 크기는 **STATE_READY 보다 늦게** 정해질 수 있다.
             *
             * 준비됐다고 크기까지 아는 게 아니다 — 비디오 트랙을 디코딩하기
             * 전에는 (0,0) 이다. 그 값을 그대로 화면에 쓰면 `SizedBox(0,0)` 이
             * 돼 **소리만 나고 그림이 안 보인다**(2026-09-19 제보).
             * 정해지는 즉시 다시 보낸다.
             */
            override fun onVideoSizeChanged(videoSize: VideoSize) {
                // ⚠️ 표면에 크기를 **반드시** 알려줘야 한다.
                //
                // `SurfaceProducer` 는 크기를 받기 전까지 쓸 만한 표면을 내주지
                // 않는다. 그래서 소리는 처음부터 나는데 **그림만 3초쯤 늦게**
                // 나왔다(2026-09-19 제보: "이미 3초가 지난 후에 화면이 나옴").
                // 디코딩이 느린 게 아니라 그릴 곳이 준비가 안 됐던 것이다.
                if (videoSize.width <= 0 || videoSize.height <= 0) return

                // ⛔ **같은 크기면 아무것도 하지 않는다.**
                //
                // 아래 `setVideoSurface` 가 ExoPlayer 에게 "표면이 바뀌었다" 로
                // 보여서, 그때마다 `onVideoSizeChanged` 가 **다시** 들어온다.
                // 막지 않으면 표면을 재부착하는 일이 끝없이 돈다 — 실측으로
                // 1분에 148,700 회였다(2026-09-20). 영상이 붙는 순간 화면이
                // 미세하게 흔들려 보인 것도 이것이다.
                if (videoSize.width == slot.surfaceW &&
                    videoSize.height == slot.surfaceH
                ) {
                    return
                }
                slot.surfaceW = videoSize.width
                slot.surfaceH = videoSize.height

                android.util.Log.i(
                    TAG,
                    "sizeKnown slot=${slot.id} ${videoSize.width}x${videoSize.height}",
                )
                slot.surface.setSize(videoSize.width, videoSize.height)
                // 크기를 바꾸면 표면이 새로 만들어질 수 있다. 다시 붙이지
                // 않으면 플레이어가 옛 표면에 계속 그린다 = 검은 화면.
                slot.player.setVideoSurface(slot.surface.surface)
                slot.surface.scheduleFrame()

                main.post {
                    channel.invokeMethod(
                        "onSize",
                        mapOf(
                            "slot" to slot.id,
                            "width" to videoSize.width,
                            "height" to videoSize.height,
                        ),
                    )
                }
            }

            override fun onIsPlayingChanged(isPlaying: Boolean) {
                send(if (isPlaying) "playing" else "paused", slot)
            }

            override fun onPlayerError(error: PlaybackException) {
                // 재생 실패는 화면에서 조용히 넘어가야 한다. 다음 장으로 스와이프하면
                // 그만이고, 여기서 예외를 던지면 앱이 죽는다.
                main.post {
                    channel.invokeMethod(
                        "onError",
                        mapOf("slot" to slot.id, "message" to (error.message ?: "재생 실패")),
                    )
                }
            }
        })
        slots.add(slot)
        return slot
    }

    private fun notifyReady(slot: Slot) {
        val d = slot.player.duration
        // 크기를 아는 채로 준비됐는지 남긴다. (0x0) 이면 Dart 쪽이 그 사이를
        // 포스터로 덮어야 한다 — 안 덮으면 화면에 꽉 늘어났다가 제자리로 튄다.
        android.util.Log.i(
            TAG,
            "readySize slot=${slot.id} ${slot.player.videoSize.width}x${slot.player.videoSize.height}",
        )
        main.post {
            channel.invokeMethod(
                "onReady",
                mapOf(
                    "slot" to slot.id,
                    "durationMs" to if (d == C.TIME_UNSET) 0L else d,
                    "width" to slot.player.videoSize.width,
                    "height" to slot.player.videoSize.height,
                ),
            )
        }
    }

    private fun send(event: String, slot: Slot) {
        main.post {
            channel.invokeMethod("on${event.replaceFirstChar { it.uppercase() }}",
                mapOf("slot" to slot.id))
        }
    }

    /**
     * 자리를 만든다. **비어 있는 것부터, 없으면 가장 오래된 것을 뺏는다.**
     *
     * 처음에는 쓰는 중인 슬롯을 아예 안 건드렸다. 그랬더니 창(5페이지)이 풀보다
     * 클 때 **보고 있는 페이지가 거절당해 영상이 안 떴다**(`no_slot`). 첫 진입이
     * 유난히 느리다는 제보가 이것이었다.
     *
     * 뺏어도 안전한 이유: 방금 요청한 페이지가 `touchedAt` 이 가장 새것이므로
     * **지금 보고 있는 장은 절대 희생되지 않는다.** 희생되는 건 화면에서 가장
     * 멀리 있어 오래전에 자리를 잡은 장이고, 그 장으로 돌아가면 그때 다시 잡는다.
     */
    private fun evictOldest(): Slot? {
        val victim = slots.filter { !it.inUse }.minByOrNull { it.touchedAt }
            ?: slots.minByOrNull { it.touchedAt }
            ?: return null
        victim.player.stop()
        victim.player.clearMediaItems()
        victim.url = null
        victim.inUse = false
        // 뺏긴 쪽 Dart 는 자기 슬롯이 사라진 걸 모른다. 알려 줘야 화면을
        // 빈 채로 두지 않고 다시 요청한다.
        main.post {
            channel.invokeMethod("onEvicted", mapOf("slot" to victim.id))
        }
        return victim
    }

    /** Dart 가 그 장을 떠났다. 플레이어는 **버리지 않고** 세워만 둔다. */
    private fun freeSlot(slot: Slot) {
        slot.inUse = false
        slot.player.pause()
        // seek 로 앞으로 돌려두면 다시 들어왔을 때 처음부터 나온다.
        slot.player.seekTo(0)
    }

    // ── 정리 ──

    fun releaseAll() {
        slots.forEach {
            it.player.release()
            it.surface.release()
        }
        slots.clear()
    }

    fun dispose() {
        released = true
        releaseAll()
    }
}
