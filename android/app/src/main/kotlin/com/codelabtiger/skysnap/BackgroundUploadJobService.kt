package com.codelabtiger.skysnap

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.job.JobParameters
import android.app.job.JobService
import android.os.Build
import androidx.annotation.RequiresApi
import androidx.core.app.NotificationCompat
import java.io.File
import java.util.concurrent.ConcurrentHashMap
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.CoroutineStart
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.launch

/** Android 14+의 장시간 사용자 시작 업로드를 담당하는 UIDT JobService. */
@RequiresApi(Build.VERSION_CODES.UPSIDE_DOWN_CAKE)
class BackgroundUploadJobService : JobService() {
    companion object {
        const val KEY_BATCH_ID = "batch_id"
        const val CHANNEL_ID = "skysnap_background_upload"
        private const val NOTIFICATION_BASE_ID = 43100

        /**
         * 재시도 상한. WorkManager 경로(runAttemptCount < 8)와 같은 값으로 맞춘다 —
         * 다르면 같은 실패에서 OS 버전에 따라 한쪽만 영원히 재시도한다.
         */
        private const val MAX_ATTEMPTS = 8
    }

    private val serviceScope = CoroutineScope(SupervisorJob() + Dispatchers.IO)
    private val running = ConcurrentHashMap<Int, Job>()

    override fun onStartJob(params: JobParameters): Boolean {
        val batchId = params.extras.getString(KEY_BATCH_ID).orEmpty()
        val ids = BackgroundUploadStore.batchIds(applicationContext, batchId)
        if (batchId.isEmpty() || ids.isEmpty()) return false

        val notificationId = NOTIFICATION_BASE_ID + (params.jobId and 0x3ff)
        val done = ids.count {
            BackgroundUploadStore.status(applicationContext, it) == BackgroundUploadStore.SUCCESS
        }
        setNotification(
            params,
            notificationId,
            notification(done, ids.size, 0, 0),
            JOB_END_NOTIFICATION_POLICY_REMOVE,
        )
        val job = serviceScope.launch(start = CoroutineStart.LAZY) {
            var shouldRetry = false
            try {
                for ((index, id) in ids.withIndex()) {
                    val request = BackgroundUploadStore.readRequest(applicationContext, id)
                    if (request == null || !File(request.filePath).isFile) {
                        BackgroundUploadStore.write(
                            applicationContext, id, BackgroundUploadStore.FAILED, "file_missing")
                        failRemaining(ids.drop(index + 1), "batch_aborted")
                        break
                    }
                    if (BackgroundUploadStore.status(applicationContext, id) == BackgroundUploadStore.SUCCESS) {
                        continue
                    }
                    BackgroundUploadStore.write(applicationContext, id, BackgroundUploadStore.RUNNING)
                    // 몇 번째 파일을 올리는 중인지 먼저 보여 준다(진행률은 곧 콜백이 채운다).
                    setNotification(
                        params, notificationId, notification(index, ids.size, 0, 0),
                        JOB_END_NOTIFICATION_POLICY_REMOVE)
                    val code = try {
                        BackgroundUploadHttp.upload(applicationContext, request) { sent, total ->
                            setNotification(
                                params, notificationId,
                                notification(index, ids.size, sent, total),
                                JOB_END_NOTIFICATION_POLICY_REMOVE)
                        }
                    } catch (cancelled: CancellationException) {
                        throw cancelled
                    } catch (error: Exception) {
                        shouldRetry = giveUpOrRequeue(id, error.message ?: "network_error")
                        break
                    }
                    when {
                        code in 200..299 -> {
                            BackgroundUploadStore.write(
                                applicationContext, id, BackgroundUploadStore.SUCCESS)
                            BackgroundUploadStore.resetAttempt(applicationContext, id)
                        }
                        code in 400..499 && !BackgroundUploadHttp.isRetryableStatus(code) -> {
                            BackgroundUploadStore.write(
                                applicationContext, id, BackgroundUploadStore.FAILED, "http_$code")
                            failRemaining(ids.drop(index + 1), "batch_aborted")
                            break
                        }
                        else -> {
                            shouldRetry = giveUpOrRequeue(id, "http_$code")
                            break
                        }
                    }
                }
            } catch (_: CancellationException) {
                // onStopJob에서 queued로 되돌리고 시스템 재예약을 요청한다.
                shouldRetry = true
            } finally {
                // onStopJob이 이미 소유권을 회수한 작업에는 jobFinished를 다시 호출하지 않는다.
                if (running.remove(params.jobId) != null) {
                    jobFinished(params, shouldRetry)
                }
            }
        }
        running[params.jobId] = job
        job.start()
        return true
    }

    override fun onStopJob(params: JobParameters): Boolean {
        val batchId = params.extras.getString(KEY_BATCH_ID).orEmpty()
        BackgroundUploadStore.batchIds(applicationContext, batchId).forEach { id ->
            if (BackgroundUploadStore.status(applicationContext, id) == BackgroundUploadStore.RUNNING) {
                BackgroundUploadStore.write(
                    applicationContext, id, BackgroundUploadStore.QUEUED, "system_interrupted")
            }
        }
        running.remove(params.jobId)?.cancel()
        // 네트워크·발열·메모리 압박으로 멈춘 경우 같은 UIDT를 시스템이 재예약한다.
        return true
    }

    override fun onDestroy() {
        serviceScope.cancel()
        super.onDestroy()
    }

    /**
     * 일시 장애를 다시 큐에 넣되, 상한을 넘으면 포기한다.
     * @return 시스템에 재예약을 요청할지 여부
     */
    private fun giveUpOrRequeue(id: String, reason: String): Boolean {
        val attempt = BackgroundUploadStore.bumpAttempt(applicationContext, id)
        return if (attempt >= MAX_ATTEMPTS) {
            // 여기서 멈추지 않으면 Android 14+ 만 영원히 재시도한다(WorkManager 는 8회에서 포기).
            // 원본 파일은 큐에 남아 있어 사용자가 실패 카드에서 다시 시도할 수 있다.
            BackgroundUploadStore.write(
                applicationContext, id, BackgroundUploadStore.FAILED, reason)
            false
        } else {
            BackgroundUploadStore.write(
                applicationContext, id, BackgroundUploadStore.QUEUED, reason)
            true
        }
    }

    private fun failRemaining(ids: List<String>, reason: String) {
        ids.forEach { id ->
            if (BackgroundUploadStore.status(applicationContext, id) != BackgroundUploadStore.SUCCESS) {
                BackgroundUploadStore.write(
                    applicationContext, id, BackgroundUploadStore.FAILED, reason)
            }
        }
    }

    /**
     * UIDT 알림은 사용자가 업로드 상태를 볼 수 있는 **유일한 창구**다.
     * 고정 문구만 띄우면 큰 영상을 올릴 때 멈춘 건지 되는 건지 알 수 없으므로
     * 몇 번째 파일인지와 현재 파일의 진행률을 함께 보여 준다.
     *
     * @param doneCount 앞서 끝난 파일 수
     * @param totalCount 이 묶음의 전체 파일 수
     * @param sent 현재 파일에서 보낸 바이트(모르면 0)
     * @param total 현재 파일 전체 바이트(모르면 0 → 불확정 막대)
     */
    private fun notification(doneCount: Int, totalCount: Int, sent: Long, total: Long): Notification {
        val manager = getSystemService(NotificationManager::class.java)
        manager.createNotificationChannel(NotificationChannel(
            CHANNEL_ID,
            getString(R.string.background_upload_channel),
            NotificationManager.IMPORTANCE_LOW,
        ))
        val builder = NotificationCompat.Builder(this, CHANNEL_ID)
            .setSmallIcon(applicationInfo.icon)
            .setContentTitle(getString(R.string.background_upload_title))
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .setCategory(NotificationCompat.CATEGORY_PROGRESS)
        // 여러 장이면 "2/5" 를 함께 적는다. 한 장뿐이면 굳이 세지 않는다.
        val text = if (totalCount > 1) {
            getString(R.string.background_upload_progress,
                (doneCount + 1).coerceAtMost(totalCount), totalCount)
        } else {
            getString(R.string.background_upload_message)
        }
        builder.setContentText(text)
        if (total > 0L) {
            val percent = ((sent.toDouble() / total) * 100).toInt().coerceIn(0, 100)
            builder.setProgress(100, percent, false)
            builder.setSubText("$percent%")
        } else {
            // 크기를 모르는 구간(연결·헤더 교환)은 불확정 막대가 정확한 표현이다.
            builder.setProgress(0, 0, true)
        }
        return builder.build()
    }
}
