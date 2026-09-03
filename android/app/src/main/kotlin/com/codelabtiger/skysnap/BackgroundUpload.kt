package com.codelabtiger.skysnap

import android.app.job.JobInfo
import android.app.job.JobScheduler
import android.content.ComponentName
import android.content.Context
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.os.PersistableBundle
import androidx.work.BackoffPolicy
import androidx.work.Constraints
import androidx.work.Data
import androidx.work.ExistingWorkPolicy
import androidx.work.NetworkType
import androidx.work.OneTimeWorkRequest
import androidx.work.OneTimeWorkRequestBuilder
import androidx.work.WorkInfo
import androidx.work.WorkManager
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.util.UUID
import java.util.concurrent.Executors
import java.util.concurrent.TimeUnit
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.runBlocking

/** Android 14+ UIDT / 구버전 WorkManager 혼합 진입점. 실제 OS 작업 ID를 상태와 함께 남긴다. */
object BackgroundUpload {
    const val CHANNEL = "com.skysnap/background_upload"
    private const val UNIQUE_PREFIX = "skysnap-background-upload-"
    private const val REGISTRATION_GRACE_MILLIS = 10_000L
    private val io = Executors.newSingleThreadExecutor()
    private val main = Handler(Looper.getMainLooper())

    fun handle(context: Context, call: MethodCall, result: MethodChannel.Result) {
        // MethodChannel의 기본 핸들러는 main thread다. WorkManager DB 대기와 SharedPreferences
        // commit은 모두 전용 IO 큐에서 하고 Flutter 응답만 main으로 되돌린다.
        io.execute {
            try {
                when (call.method) {
                    "enqueue" -> {
                        val raw = call.argument<List<Map<String, Any?>>>("uploads") ?: emptyList()
                        enqueueBatch(context, raw)
                        succeed(result, null)
                    }
                    "states" -> {
                        val ids = call.argument<List<String>>("ids") ?: emptyList()
                        succeed(result, reconciledStates(context, ids))
                    }
                    "forget" -> {
                        val ids = call.argument<List<String>>("ids") ?: emptyList()
                        BackgroundUploadStore.remove(context, ids)
                        succeed(result, null)
                    }
                    "excludeFromBackup" -> {
                        // 이 앱은 manifest에서 allowBackup=false 라 백업 자체가 없다.
                        succeed(result, null)
                    }
                    else -> main.post { result.notImplemented() }
                }
            } catch (e: Exception) {
                fail(result, if (call.method == "states") "states_failed" else "enqueue_failed", e)
            }
        }
    }

    private fun succeed(result: MethodChannel.Result, value: Any?) = main.post { result.success(value) }

    private fun fail(result: MethodChannel.Result, code: String, error: Exception) = main.post {
        result.error(code, error.message ?: code, null)
    }

    private data class Upload(
        val id: String,
        val batchId: String,
        val filePath: String,
        val uploadUrl: String,
        val protocol: String,
        val uploadLength: Long,
    )

    /**
     * 모든 항목을 먼저 검증한 뒤 WorkManager 체인 하나로 등록한다.
     * 상태를 먼저 디스크에 확정한다. WorkManager DB 등록은 비동기지만, 등록 직후 10초
     * 동안은 UUID 조회의 반영 지연을 기다리고 그 뒤에는 work_missing으로 복구한다.
     */
    private fun enqueueBatch(context: Context, raw: List<Map<String, Any?>>) {
        require(raw.isNotEmpty()) { "uploads is empty" }
        val uploads = raw.map(::parse)
        val batchId = uploads.first().batchId
        require(uploads.all { it.batchId == batchId }) { "uploads must share a batch id" }
        require(uploads.map { it.id }.distinct().size == uploads.size) { "duplicate upload id" }

        if (uploads.all { BackgroundUploadStore.status(context, it.id) == BackgroundUploadStore.SUCCESS }) return
        // 같은 job을 Dart가 두 번 넘겨도 이미 살아 있는 Work를 그대로 쓴다.
        // 묶음은 WorkManager 체인 하나로 실행된다. 앞 사진은 이미 끝났고 뒤 사진만
        // 전송 중인 경우에도, 하나라도 살아 있으면 같은 unique chain에 새 작업을
        // 얹으면 안 된다. KEEP 정책에 의해 새 UUID만 기록되고 실제로는 실행되지 않아
        // 완료된 항목을 다시 queued로 되돌리는 문제가 생길 수 있기 때문이다.
        if (uploads.any { hasLiveTransfer(context, BackgroundUploadStore.readRecord(context, it.id)) }) return

        uploads.forEach { upload ->
            BackgroundUploadStore.writeRequest(
                context = context,
                id = upload.id,
                batchId = upload.batchId,
                filePath = upload.filePath,
                uploadUrl = upload.uploadUrl,
                protocol = upload.protocol,
                uploadLength = upload.uploadLength,
            )
        }

        // UIDT는 화면에서 사용자가 시작한 장시간 전송용이다. 전처리 중 앱이 이미
        // 백그라운드가 됐거나 시스템이 예약을 거부하면 schedule()이 실패하므로 기존
        // WorkManager foreground 경로로 즉시 내려가 파일을 잃지 않는다.
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE &&
            scheduleUidt(context, batchId, uploads)) {
            return
        }

        val requests = uploads.map(::workRequest)
        uploads.zip(requests).forEach { (upload, request) ->
            BackgroundUploadStore.write(
                context,
                upload.id,
                BackgroundUploadStore.QUEUED,
                workId = request.id.toString(),
            )
        }

        var continuation = WorkManager.getInstance(context).beginUniqueWork(
            UNIQUE_PREFIX + batchId, ExistingWorkPolicy.KEEP, requests.first())
        requests.drop(1).forEach { request -> continuation = continuation.then(request) }
        try {
            continuation.enqueue()
        } catch (error: Exception) {
            uploads.forEach {
                BackgroundUploadStore.write(context, it.id, BackgroundUploadStore.FAILED, "work_enqueue_failed")
            }
            throw error
        }
    }

    private fun hasLiveTransfer(context: Context, record: BackgroundUploadStore.Record): Boolean {
        if (record.status != BackgroundUploadStore.QUEUED && record.status != BackgroundUploadStore.RUNNING) {
            return false
        }
        val id = record.workId ?: return false
        if (id.startsWith("uidt:")) {
            if (Build.VERSION.SDK_INT < Build.VERSION_CODES.UPSIDE_DOWN_CAKE) return false
            return try {
                val jobId = id.removePrefix("uidt:").toInt()
                val scheduler = context.getSystemService(JobScheduler::class.java)
                scheduler.getPendingJob(jobId) != null
            } catch (_: Exception) {
                // 조회 실패를 작업 소실로 단정하면 동일 파일을 중복 전송할 수 있다.
                true
            }
        }
        return try {
            when (workInfo(context, id)?.state) {
                WorkInfo.State.ENQUEUED, WorkInfo.State.BLOCKED, WorkInfo.State.RUNNING -> true
                else -> false
            }
        } catch (_: Exception) {
            // 확인 자체가 실패하면 새 작업을 만들지 않는다. 다음 states 호출에서 null을
            // 반환해 Dart가 큐를 보존하고 재확인하게 한다.
            true
        }
    }

    /** SharedPreferences 상태를 WorkManager DB와 대조해 유령 queued 상태를 제거한다. */
    private fun reconciledStates(context: Context, ids: List<String>): List<Map<String, String>> {
        val workManager = WorkManager.getInstance(context)
        ids.forEach { id ->
            val record = BackgroundUploadStore.readRecord(context, id)
            if (record.status != BackgroundUploadStore.QUEUED && record.status != BackgroundUploadStore.RUNNING) {
                return@forEach
            }
            val workId = record.workId
            if (workId.isNullOrBlank()) {
                // 이전 버전/등록 중단으로 UUID가 없다면 실제 작업을 확인할 수 없다.
                BackgroundUploadStore.write(context, id, BackgroundUploadStore.FAILED, "work_reference_missing")
                return@forEach
            }
            if (workId.startsWith("uidt:")) {
                val pending = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
                    try {
                        context.getSystemService(JobScheduler::class.java)
                            .getPendingJob(workId.removePrefix("uidt:").toInt()) != null
                    } catch (error: Exception) {
                        throw IllegalStateException("uidt_state_unavailable", error)
                    }
                } else {
                    false
                }
                if (!pending && System.currentTimeMillis() - record.updatedAt >= REGISTRATION_GRACE_MILLIS) {
                    BackgroundUploadStore.write(context, id, BackgroundUploadStore.FAILED, "uidt_job_missing")
                }
                return@forEach
            }
            val info = try {
                workInfo(workManager, workId)
            } catch (error: Exception) {
                throw IllegalStateException("work_state_unavailable", error)
            }
            when (info?.state) {
                WorkInfo.State.ENQUEUED, WorkInfo.State.BLOCKED ->
                    BackgroundUploadStore.write(context, id, BackgroundUploadStore.QUEUED)
                WorkInfo.State.RUNNING ->
                    BackgroundUploadStore.write(context, id, BackgroundUploadStore.RUNNING)
                WorkInfo.State.SUCCEEDED ->
                    BackgroundUploadStore.write(context, id, BackgroundUploadStore.SUCCESS)
                WorkInfo.State.FAILED ->
                    BackgroundUploadStore.write(context, id, BackgroundUploadStore.FAILED, "work_failed")
                WorkInfo.State.CANCELLED ->
                    BackgroundUploadStore.write(context, id, BackgroundUploadStore.FAILED, "work_cancelled")
                null -> {
                    // enqueue() 직후 WorkManager DB가 아직 UUID를 노출하지 않는 짧은
                    // 구간에는 상태를 보존한다. 그 뒤에도 없으면 실제 작업이 없으므로
                    // Dart가 새 URL로 안전하게 복구할 수 있다.
                    if (System.currentTimeMillis() - record.updatedAt >= REGISTRATION_GRACE_MILLIS) {
                        BackgroundUploadStore.write(context, id, BackgroundUploadStore.FAILED, "work_missing")
                    }
                }
            }
        }
        return ids.map { BackgroundUploadStore.read(context, it) }
    }

    private fun workInfo(context: Context, workId: String): WorkInfo? =
        workInfo(WorkManager.getInstance(context), workId)

    private fun workInfo(workManager: WorkManager, workId: String): WorkInfo? = runBlocking {
        workManager.getWorkInfoByIdFlow(UUID.fromString(workId)).first()
    }

    private fun parse(raw: Map<String, Any?>): Upload {
        val id = raw["id"]?.toString()?.trim().orEmpty()
        val batchId = raw["batchId"]?.toString()?.trim().orEmpty()
        val filePath = raw["filePath"]?.toString()?.trim().orEmpty()
        val uploadUrl = raw["uploadUrl"]?.toString()?.trim().orEmpty()
        val protocol = raw["protocol"]?.toString()?.trim()?.lowercase().orEmpty().ifEmpty { "multipart" }
        require(id.isNotEmpty() && batchId.isNotEmpty() && filePath.isNotEmpty() && uploadUrl.isNotEmpty()) {
            "invalid upload request"
        }
        val file = java.io.File(filePath)
        require(file.isFile) { "upload file is missing" }
        val uploadLength = (raw["uploadLength"] as? Number)?.toLong() ?: file.length()
        require(uploadLength > 0L && uploadLength == file.length()) { "upload length does not match file" }
        return Upload(id, batchId, filePath, uploadUrl, protocol, uploadLength)
    }

    @androidx.annotation.RequiresApi(Build.VERSION_CODES.UPSIDE_DOWN_CAKE)
    private fun scheduleUidt(context: Context, batchId: String, uploads: List<Upload>): Boolean {
        val scheduler = context.getSystemService(JobScheduler::class.java)
        val jobId = uidtJobId(context, scheduler, batchId) ?: return false
        BackgroundUploadStore.writeBatch(context, batchId, jobId, uploads.map(Upload::id))
        uploads.forEach { upload ->
            BackgroundUploadStore.write(
                context,
                upload.id,
                BackgroundUploadStore.QUEUED,
                workId = "uidt:$jobId",
            )
        }
        val extras = PersistableBundle().apply {
            putString(BackgroundUploadJobService.KEY_BATCH_ID, batchId)
        }
        val totalBytes = uploads.sumOf(Upload::uploadLength).coerceAtLeast(1L)
        val info = JobInfo.Builder(
            jobId,
            ComponentName(context, BackgroundUploadJobService::class.java),
        )
            .setExtras(extras)
            .setUserInitiated(true)
            .setRequiredNetworkType(JobInfo.NETWORK_TYPE_ANY)
            .setEstimatedNetworkBytes(0L, totalBytes)
            .setBackoffCriteria(15_000L, JobInfo.BACKOFF_POLICY_EXPONENTIAL)
            .build()
        return try {
            scheduler.schedule(info) == JobScheduler.RESULT_SUCCESS
        } catch (_: Exception) {
            false
        }
    }

    @androidx.annotation.RequiresApi(Build.VERSION_CODES.UPSIDE_DOWN_CAKE)
    private fun uidtJobId(
        context: Context,
        scheduler: JobScheduler,
        batchId: String,
    ): Int? {
        BackgroundUploadStore.batchJobId(context, batchId)?.let { existing ->
            val existingBatch = scheduler.getPendingJob(existing)
                ?.extras?.getString(BackgroundUploadJobService.KEY_BATCH_ID)
            if (existingBatch == null || existingBatch == batchId) return existing
        }
        // 앱 전용 20-bit 구간에서 충돌 시 선형 탐색한다. extras의 batchId를 대조하므로
        // 서로 다른 업로드가 같은 hash를 가져도 기존 Job을 덮어쓰지 않는다.
        val base = 0x4d000000 or (batchId.hashCode() and 0x000fffff)
        repeat(64) { offset ->
            val candidate = base + offset
            val occupied = scheduler.getPendingJob(candidate)
            if (occupied == null ||
                occupied.extras.getString(BackgroundUploadJobService.KEY_BATCH_ID) == batchId) {
                return candidate
            }
        }
        return null
    }

    private fun workRequest(upload: Upload): OneTimeWorkRequest =
        OneTimeWorkRequestBuilder<BackgroundUploadWorker>()
            .setInputData(Data.Builder()
                .putString(BackgroundUploadWorker.KEY_ID, upload.id)
                .putString(BackgroundUploadWorker.KEY_FILE_PATH, upload.filePath)
                .putString(BackgroundUploadWorker.KEY_UPLOAD_URL, upload.uploadUrl)
                .build())
            .setConstraints(Constraints.Builder().setRequiredNetworkType(NetworkType.CONNECTED).build())
            .setBackoffCriteria(BackoffPolicy.LINEAR, 15, TimeUnit.SECONDS)
            .build()
}
