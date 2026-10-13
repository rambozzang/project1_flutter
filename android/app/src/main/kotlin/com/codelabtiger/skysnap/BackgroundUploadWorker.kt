package com.codelabtiger.skysnap

import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.content.pm.ServiceInfo
import android.os.Build
import androidx.core.app.NotificationCompat
import androidx.work.CoroutineWorker
import androidx.work.ForegroundInfo
import androidx.work.WorkerParameters
import java.io.File
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext

/**
 * 앱 UI와 Dart isolate가 사라져도 WorkManager가 실행하는 Direct Upload worker.
 * 요청을 통째로 재시도하는 전송이다. Cloudflare Direct URL이 만료되면 failed로 남기고
 * Flutter가 다음 실행에 새 URL을 발급해 기존 Dio 경로로 안전하게 재시도한다.
 */
class BackgroundUploadWorker(appContext: Context, params: WorkerParameters) : CoroutineWorker(appContext, params) {
    companion object {
        const val KEY_ID = "id"
        const val KEY_FILE_PATH = "filePath"
        const val KEY_UPLOAD_URL = "uploadUrl"
        private const val CHANNEL_ID = "skysnap_background_upload"
        private const val NOTIFICATION_ID = 43021

        /**
         * foreground service 시작이 막혔을 때 미뤄 보는 횟수. 이걸 넘기면 실패로
         * 남긴다(알림 없이 올리지 않는다). 일반 전송 실패 상한(8)보다 짧은 이유는,
         * 여기서 빨리 실패를 돌려줘야 Dart가 새 티켓으로 다시 등록할 기회를 얻기
         * 때문이다 — 15초 선형 백오프로 8회면 9분 가까이 묻힌다.
         */
        private const val FOREGROUND_RETRY_ATTEMPTS = 3
    }

    override suspend fun doWork(): Result = withContext(Dispatchers.IO) {
        val id = inputData.getString(KEY_ID).orEmpty()
        val file = File(inputData.getString(KEY_FILE_PATH).orEmpty())
        val uploadUrl = inputData.getString(KEY_UPLOAD_URL).orEmpty()
        if (id.isEmpty() || uploadUrl.isEmpty() || !file.exists()) {
            BackgroundUploadStore.write(applicationContext, id, BackgroundUploadStore.FAILED, "file_missing")
            return@withContext Result.failure()
        }
        // Android 12/13에서는 앱이 백그라운드로 내려간 사이 foreground service 시작이
        // 금지돼 이 호출이 ForegroundServiceStartNotAllowedException을 던진다. try 밖에
        // 두면 worker가 그대로 죽고 아래 재시도 기록 경로를 한 번도 타지 못해 Dart 쪽에는
        // 유령 QUEUED만 남는다(모모앨범 2f99a10). 일반 예외와 같은 재시도 상태로 다룬다.
        //
        // **알림 없이 몰래 올리지는 않는다.** 몇 번 미뤄 보고 그래도 안 되면 실패로
        // 남긴다 — 원본은 Dart 큐에 남아 있고, Dart는 failed를 보면 새 티켓으로
        // 다시 등록한다(DurableUpload.transferMany).
        try {
            setForeground(createForegroundInfo())
        } catch (e: CancellationException) {
            throw e
        } catch (e: Exception) {
            if (runAttemptCount < FOREGROUND_RETRY_ATTEMPTS) {
                BackgroundUploadStore.write(
                    applicationContext, id, BackgroundUploadStore.QUEUED, "foreground_denied")
                return@withContext Result.retry()
            }
            BackgroundUploadStore.write(
                applicationContext, id, BackgroundUploadStore.FAILED, "foreground_denied")
            return@withContext Result.failure()
        }
        BackgroundUploadStore.write(applicationContext, id, BackgroundUploadStore.RUNNING)
        try {
            val request = BackgroundUploadStore.readRequest(applicationContext, id)
                ?: BackgroundUploadStore.Request(
                    id = id,
                    batchId = id,
                    filePath = file.path,
                    uploadUrl = uploadUrl,
                    protocol = "multipart",
                    uploadLength = file.length(),
                )
            lastPercent = -1
            val responseCode = BackgroundUploadHttp.upload(applicationContext, request) { sent, total ->
                updateProgress(sent, total)
            }
            if (responseCode in 200..299) {
                BackgroundUploadStore.write(applicationContext, id, BackgroundUploadStore.SUCCESS)
                Result.success()
            } else if (responseCode in 400..499 && !BackgroundUploadHttp.isRetryableStatus(responseCode)) {
                // 일회용 Direct URL 만료(보통 403/404), 권한 오류 등은 같은 URL로
                // 재시도해도 절대 성공하지 않는다. Flutter가 즉시 새 티켓 경로로 넘긴다.
                BackgroundUploadStore.write(applicationContext, id, BackgroundUploadStore.FAILED, "http_$responseCode")
                Result.failure()
            } else if (runAttemptCount < 8) {
                BackgroundUploadStore.write(applicationContext, id, BackgroundUploadStore.QUEUED, "http_$responseCode")
                Result.retry()
            } else {
                BackgroundUploadStore.write(applicationContext, id, BackgroundUploadStore.FAILED, "http_$responseCode")
                Result.failure()
            }
        } catch (e: Exception) {
            // WorkManager가 작업을 멈춘 경우(제약 해제·시스템 회수)다. 재시도 횟수를 깎거나
            // 실패로 적지 않는다 — WorkManager가 같은 작업을 다시 실행하고, 그 사이 상태는
            // reconciledStates가 WorkInfo를 보고 queued로 맞춘다.
            if (e is CancellationException) throw e
            if (runAttemptCount < 8) {
                BackgroundUploadStore.write(applicationContext, id, BackgroundUploadStore.QUEUED, e.message)
                Result.retry()
            } else {
                BackgroundUploadStore.write(applicationContext, id, BackgroundUploadStore.FAILED, e.message)
                Result.failure()
            }
        }
    }

    private var lastPercent = -1

    /**
     * 전송 진행률을 상태바 알림에 반영한다(모모앨범 BackgroundUploadWorker.updateProgress).
     * 퍼센트가 바뀔 때만 갱신해 알림 폭주로 시스템이 갱신을 버리지 않게 한다.
     *
     * 여기까지 왔다면 setForeground는 반드시 통과했다(실패하면 위에서 retry 또는
     * failure로 끝난다). 그래서 이 알림은 항상 foreground service 수명에 묶여
     * 있고, 전송이 끝나면 함께 사라진다.
     */
    private fun updateProgress(sent: Long, total: Long) {
        val percent = if (total > 0L) ((sent * 100) / total).toInt().coerceIn(0, 100) else -1
        if (percent == lastPercent) return
        lastPercent = percent
        val manager = applicationContext.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        manager.notify(NOTIFICATION_ID, buildNotification(sent, total))
    }

    private fun buildNotification(sent: Long = 0L, total: Long = 0L): android.app.Notification {
        val builder = NotificationCompat.Builder(applicationContext, CHANNEL_ID)
            .setSmallIcon(applicationContext.applicationInfo.icon)
            .setContentTitle(applicationContext.getString(R.string.background_upload_title))
            .setContentText(applicationContext.getString(R.string.background_upload_message))
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .setCategory(NotificationCompat.CATEGORY_PROGRESS)
        if (total > 0L) {
            val percent = ((sent * 100) / total).toInt().coerceIn(0, 100)
            builder.setProgress(100, percent, false)
            builder.setSubText("$percent%")
        } else {
            // 크기를 모르는 구간(연결·헤더 교환)은 불확정 막대가 정확한 표현이다.
            builder.setProgress(0, 0, true)
        }
        return builder.build()
    }

    private fun createForegroundInfo(): ForegroundInfo {
        val manager = applicationContext.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        manager.createNotificationChannel(
            NotificationChannel(
                CHANNEL_ID,
                applicationContext.getString(R.string.background_upload_channel),
                NotificationManager.IMPORTANCE_LOW,
            )
        )
        val notification = buildNotification()
        // Manifest 선언만으로는 부족하다. Android 14+/targetSdk 34+에서는 실행 시
        // ForegroundInfo에도 타입을 넘기지 않으면 type=none으로 판정해 프로세스를
        // InvalidForegroundServiceTypeException으로 즉시 종료한다.
        val serviceType = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            ServiceInfo.FOREGROUND_SERVICE_TYPE_DATA_SYNC
        } else {
            0
        }
        return ForegroundInfo(NOTIFICATION_ID, notification, serviceType)
    }
}
