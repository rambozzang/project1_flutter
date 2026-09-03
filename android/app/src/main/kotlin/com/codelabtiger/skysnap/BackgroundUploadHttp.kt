package com.codelabtiger.skysnap

import android.content.Context
import java.io.BufferedOutputStream
import java.io.File
import java.net.HttpURLConnection
import java.net.URL
import java.net.URLConnection
import java.util.UUID
import kotlinx.coroutines.currentCoroutineContext
import kotlinx.coroutines.ensureActive

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
            if (code in 200..299) onProgress?.invoke(total, total)
            // 연결 재사용을 위해 응답 본문을 끝까지 비운다.
            runCatching {
                (if (code in 200..299) connection.inputStream else connection.errorStream)
                    ?.use { it.readBytes() }
            }
            return code
        } finally {
            connection.disconnect()
        }
    }
}
