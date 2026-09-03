package com.codelabtiger.skysnap

import android.content.Context

/**
 * OS Worker가 앱 프로세스 없이도 쓰는 작은 영속 상태 저장소.
 *
 * queued/running 문자열만 저장하면 WorkManager 등록 직후 프로세스가 죽었을 때 유령
 * 상태가 생긴다. 그래서 각 항목의 실제 WorkRequest UUID와 갱신 시각도 함께 보관한다.
 */
object BackgroundUploadStore {
    const val QUEUED = "queued"
    const val RUNNING = "running"
    const val SUCCESS = "success"
    const val FAILED = "failed"
    private const val PREFS = "skysnap_background_uploads"

    data class Record(
        val id: String,
        val status: String,
        val error: String,
        val workId: String?,
        val updatedAt: Long,
    )

    data class Request(
        val id: String,
        val batchId: String,
        val filePath: String,
        val uploadUrl: String,
        val protocol: String,
        val uploadLength: Long,
    )

    private fun prefs(context: Context) = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)

    fun status(context: Context, id: String): String = readRecord(context, id).status

    fun readRecord(context: Context, id: String): Record {
        val prefs = prefs(context)
        return Record(
            id = id,
            status = prefs.getString("$id.status", "missing") ?: "missing",
            error = prefs.getString("$id.error", "") ?: "",
            workId = prefs.getString("$id.work_id", null),
            updatedAt = prefs.getLong("$id.updated_at", 0L),
        )
    }

    fun writeRequest(
        context: Context,
        id: String,
        batchId: String,
        filePath: String,
        uploadUrl: String,
        protocol: String,
        uploadLength: Long,
    ) {
        prefs(context).edit()
            .putString("$id.batch_id", batchId)
            .putString("$id.file_path", filePath)
            .putString("$id.upload_url", uploadUrl)
            .putString("$id.protocol", protocol)
            .putLong("$id.upload_length", uploadLength)
            // 새로 등록하는 전송이므로 지난 재시도 이력을 물려받지 않는다.
            .remove("$id.attempt")
            .commit()
    }

    fun readRequest(context: Context, id: String): Request? {
        val prefs = prefs(context)
        val batchId = prefs.getString("$id.batch_id", null).orEmpty()
        val filePath = prefs.getString("$id.file_path", null).orEmpty()
        val uploadUrl = prefs.getString("$id.upload_url", null).orEmpty()
        if (batchId.isEmpty() || filePath.isEmpty() || uploadUrl.isEmpty()) return null
        return Request(
            id = id,
            batchId = batchId,
            filePath = filePath,
            uploadUrl = uploadUrl,
            protocol = prefs.getString("$id.protocol", "multipart") ?: "multipart",
            uploadLength = prefs.getLong("$id.upload_length", 0L),
        )
    }

    /**
     * UIDT 재시도 횟수.
     *
     * WorkManager 는 runAttemptCount 를 자기가 세어 8회에서 포기하는데, JobScheduler 에는
     * 그런 값이 없다. 그대로 두면 Android 14+ 만 영원히 재시도해서, 같은 실패 상황에서
     * OS 버전에 따라 동작이 갈린다(13 이하는 포기, 14 이상은 무한). 여기서 직접 센다.
     */
    fun attempt(context: Context, id: String): Int = prefs(context).getInt("$id.attempt", 0)

    fun bumpAttempt(context: Context, id: String): Int {
        val next = attempt(context, id) + 1
        prefs(context).edit().putInt("$id.attempt", next).commit()
        return next
    }

    /** 성공했거나 사용자가 다시 올리기 시작하면 0 으로 되돌린다. */
    fun resetAttempt(context: Context, id: String) {
        prefs(context).edit().remove("$id.attempt").commit()
    }

    fun writeBatch(context: Context, batchId: String, jobId: Int, ids: List<String>) {
        prefs(context).edit()
            .putInt("batch.$batchId.job_id", jobId)
            .putString("batch.$batchId.ids", ids.joinToString(","))
            .commit()
    }

    fun batchIds(context: Context, batchId: String): List<String> =
        prefs(context).getString("batch.$batchId.ids", "")
            .orEmpty()
            .split(',')
            .map(String::trim)
            .filter(String::isNotEmpty)

    fun batchJobId(context: Context, batchId: String): Int? {
        val prefs = prefs(context)
        val key = "batch.$batchId.job_id"
        return if (prefs.contains(key)) prefs.getInt(key, 0) else null
    }

    /** null workId는 Worker가 상태만 갱신하는 경우라 기존 UUID를 보존한다. */
    fun write(
        context: Context,
        id: String,
        status: String,
        error: String? = null,
        workId: String? = null,
    ) {
        prefs(context).edit()
            .putString("$id.status", status)
            .putLong("$id.updated_at", System.currentTimeMillis())
            .apply {
                if (error.isNullOrBlank()) remove("$id.error") else putString("$id.error", error.take(300))
                if (!workId.isNullOrBlank()) putString("$id.work_id", workId)
            }
            // 앱이 등록 바로 뒤 종료돼도 Work UUID와 상태가 남아야 하므로 apply()가 아닌
            // commit()을 쓴다. 수십 바이트라 UI 스레드에서 호출하지 않도록 채널도 IO로 보낸다.
            .commit()
    }

    fun read(context: Context, id: String): Map<String, String> {
        val record = readRecord(context, id)
        return mapOf(
            "id" to id,
            "status" to record.status,
            "error" to record.error,
        )
    }

    fun remove(context: Context, ids: List<String>) {
        val editor = prefs(context).edit()
        val affectedBatches = ids.mapNotNull { readRequest(context, it)?.batchId }.distinct()
        ids.forEach { id ->
            editor.remove("$id.status")
            editor.remove("$id.error")
            editor.remove("$id.work_id")
            editor.remove("$id.updated_at")
            editor.remove("$id.batch_id")
            editor.remove("$id.file_path")
            editor.remove("$id.upload_url")
            editor.remove("$id.protocol")
            editor.remove("$id.upload_length")
            editor.remove("$id.attempt")
        }
        affectedBatches.forEach { batchId ->
            val remaining = batchIds(context, batchId).filterNot(ids.toSet()::contains)
            if (remaining.isEmpty()) {
                editor.remove("batch.$batchId.job_id")
                editor.remove("batch.$batchId.ids")
            } else {
                editor.putString("batch.$batchId.ids", remaining.joinToString(","))
            }
        }
        editor.commit()
    }
}
