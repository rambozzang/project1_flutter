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
    }

    override suspend fun doWork(): Result = withContext(Dispatchers.IO) {
        val id = inputData.getString(KEY_ID).orEmpty()
        val file = File(inputData.getString(KEY_FILE_PATH).orEmpty())
        val uploadUrl = inputData.getString(KEY_UPLOAD_URL).orEmpty()
        if (id.isEmpty() || uploadUrl.isEmpty() || !file.exists()) {
            BackgroundUploadStore.write(applicationContext, id, BackgroundUploadStore.FAILED, "file_missing")
            return@withContext Result.failure()
        }
        setForeground(createForegroundInfo())
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
            val responseCode = BackgroundUploadHttp.upload(applicationContext, request)
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
            if (runAttemptCount < 8) {
                BackgroundUploadStore.write(applicationContext, id, BackgroundUploadStore.QUEUED, e.message)
                Result.retry()
            } else {
                BackgroundUploadStore.write(applicationContext, id, BackgroundUploadStore.FAILED, e.message)
                Result.failure()
            }
        }
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
        val notification = NotificationCompat.Builder(applicationContext, CHANNEL_ID)
            .setSmallIcon(applicationContext.applicationInfo.icon)
            .setContentTitle(applicationContext.getString(R.string.background_upload_title))
            .setContentText(applicationContext.getString(R.string.background_upload_message))
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .build()
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
