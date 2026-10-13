package com.codelabtiger.skysnap

import android.content.Context
import java.io.BufferedOutputStream
import java.io.File
import java.net.HttpURLConnection
import java.net.URL
import java.net.URLConnection
import java.util.UUID
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.CoroutineStart
import kotlinx.coroutines.awaitCancellation
import kotlinx.coroutines.coroutineScope
import kotlinx.coroutines.currentCoroutineContext
import kotlinx.coroutines.ensureActive
import kotlinx.coroutines.launch

/**
 * WorkManager와 Android 14+ UIDT가 함께 쓰는 실제 HTTP 전송기.
 *
 * SkySnap 은 Cloudflare Direct Creator Upload 를 **multipart POST 로만** 쓴다.
 * (Dart 쪽 `DirectUploadRepo._uploadTo` 와 같은 형식 — form field 이름도 "file" 로 같다.)
 * 그래서 여기에는 tus 경로가 없다. tus 는 PATCH 가 필요해 HttpURLConnection 으로는
 * 보낼 수 없고, 그 하나 때문에 okhttp 의존성을 새로 들이는 건 지금 얻는 게 없다.
 * 나중에 대용량 이어올리기가 필요해지면 그때 okhttp 와 함께 추가한다.
 */
object BackgroundUploadHttp {
    private const val CONNECT_TIMEOUT_MILLIS = 30_000
    private const val READ_TIMEOUT_MILLIS = 120_000
    private const val BUFFER_BYTES = 64 * 1024

    /** 409 판별에 쓰는 응답 본문 상한. Cloudflare 오류 JSON은 수백 바이트다. */
    private const val ERROR_BODY_LIMIT = 16 * 1024

    fun isRetryableStatus(code: Int): Boolean =
        code <= 0 || code == 408 || code == 409 || code == 425 || code == 429 || code >= 500

    /**
     * @param onProgress 보낸 바이트/전체 바이트. 알림 진행률에 쓴다.
     * @return HTTP 상태 코드. 연결 자체가 실패하면 예외를 던진다(호출자가 재시도 판단).
     */
    suspend fun upload(
        context: Context,
        request: BackgroundUploadStore.Request,
        onProgress: ((sent: Long, total: Long) -> Unit)? = null,
    ): Int {
        val file = File(request.filePath)
        require(file.isFile) { "file_missing" }
        val total = file.length()
        require(total > 0L && (request.uploadLength <= 0L || request.uploadLength == total)) {
            "upload_length_mismatch"
        }
        return uploadMultipart(request.uploadUrl, file, total, onProgress)
    }

    private suspend fun uploadMultipart(
        uploadUrl: String,
        file: File,
        total: Long,
        onProgress: ((sent: Long, total: Long) -> Unit)?,
    ): Int {
        val boundary = "skysnap-${UUID.randomUUID()}"
        val mime = URLConnection.guessContentTypeFromName(file.name) ?: "application/octet-stream"
        val safeName = file.name.replace("\"", "")
        val header = (
            "--$boundary\r\n" +
                "Content-Disposition: form-data; name=\"file\"; filename=\"$safeName\"\r\n" +
                "Content-Type: $mime\r\n\r\n"
            ).toByteArray()
        val footer = "\r\n--$boundary--\r\n".toByteArray()

        val connection = (URL(uploadUrl).openConnection() as HttpURLConnection).apply {
            requestMethod = "POST"
            doOutput = true
            useCaches = false
            connectTimeout = CONNECT_TIMEOUT_MILLIS
            readTimeout = READ_TIMEOUT_MILLIS
            setRequestProperty("Content-Type", "multipart/form-data; boundary=$boundary")
            // 본문 전체를 메모리에 쌓지 않는다. 영상은 수십 MB라 버퍼링하면 OOM 이 난다.
            setFixedLengthStreamingMode(header.size + total + footer.size)
        }

        try {
            return abortOnCancel(connection) {
                sendMultipart(connection, header, footer, file, total, onProgress)
            }
        } finally {
            connection.disconnect()
        }
    }

    /**
     * 코루틴(Worker 중단·UIDT onStopJob)이 취소되면 다른 스레드에서 연결을 끊어
     * 응답 대기(최대 READ_TIMEOUT)에 묶인 스레드를 즉시 풀어 준다.
     *
     * 모모앨범은 OkHttp `Call.cancel()`로 같은 일을 한다(BackgroundUploadHttp.execute).
     * 이걸 안 하면 onStopJob 뒤에도 옛 스레드가 2분까지 같은 파일을 붙잡고 있고, 그 사이
     * 시스템이 재예약한 새 실행이 같은 일회용 URL로 한 번 더 보내 충돌이 난다.
     * 끊겨서 난 입출력 예외는 실패가 아니라 취소로 바꿔 재시도 횟수를 깎지 않는다.
     */
    private suspend fun <T> abortOnCancel(
        connection: HttpURLConnection,
        block: suspend () -> T,
    ): T = coroutineScope {
        val watcher = launch(start = CoroutineStart.UNDISPATCHED) {
            try {
                awaitCancellation()
            } finally {
                connection.disconnect()
            }
        }
        try {
            block()
        } catch (error: Exception) {
            if (error !is CancellationException) ensureActive()
            throw error
        } finally {
            watcher.cancel()
        }
    }

    private suspend fun sendMultipart(
        connection: HttpURLConnection,
        header: ByteArray,
        footer: ByteArray,
        file: File,
        total: Long,
        onProgress: ((sent: Long, total: Long) -> Unit)?,
    ): Int {
        onProgress?.invoke(0L, total)
        BufferedOutputStream(connection.outputStream).use { output ->
            output.write(header)
            file.inputStream().use { input ->
                val buffer = ByteArray(BUFFER_BYTES)
                var sent = 0L
                while (true) {
                    // 취소(작업 중단·시스템 회수)를 청크 경계에서 관측한다.
                    currentCoroutineContext().ensureActive()
                    val count = input.read(buffer)
                    if (count < 0) break
                    output.write(buffer, 0, count)
                    sent += count
                    onProgress?.invoke(sent, total)
                }
                // 파일이 전송 중에 잘리면 fixed-length 스트림과 어긋나 서버가 끊는다.
                // 여기서 먼저 걸러 원인을 분명히 남긴다.
                if (sent != total) throw java.io.EOFException("file_truncated")
            }
            output.write(footer)
            output.flush()
        }
        val code = connection.responseCode
        if (code in 200..299) {
            onProgress?.invoke(total, total)
            // 연결 재사용을 위해 응답 본문을 끝까지 비운다.
            runCatching { connection.inputStream?.use { it.readBytes() } }
            return code
        }
        val errorBody = runCatching {
            connection.errorStream?.use { readLimited(it, ERROR_BODY_LIMIT) }
        }.getOrNull().orEmpty()
        // 완료 응답을 저장하기 전에 프로세스가 죽으면 OS가 같은 일회용 URL로 다시
        // 보낸다. 확인된 Images 중복 오류(409/5409)만 완료로 정규화한다
        // (모모앨범 484b7ca). 그 밖의 409는 여전히 재시도 대상이다.
        if (CloudflareImageUploadResponse.isAlreadyUploaded(
                connection.url.toString(), code, errorBody)) {
            onProgress?.invoke(total, total)
            return 204
        }
        return code
    }

    private fun readLimited(input: java.io.InputStream, limit: Int): String {
        val out = java.io.ByteArrayOutputStream()
        val buffer = ByteArray(4 * 1024)
        while (out.size() < limit) {
            val count = input.read(buffer, 0, minOf(buffer.size, limit - out.size()))
            if (count < 0) break
            out.write(buffer, 0, count)
        }
        return out.toString(Charsets.UTF_8.name())
    }
}
