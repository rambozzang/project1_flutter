package com.codelabtiger.skysnap

import java.net.URI
import org.json.JSONObject

/**
 * Cloudflare Images 일회용 주소에 같은 파일을 다시 보냈을 때의 응답 판별.
 *
 * 모모앨범(2026-09-27 실기기)에서 옮겨 왔다. 저장은 끝났지만 완료 기록 전에 프로세스가
 * 죽은 사진을 WorkManager/UIDT가 같은 URL로 다시 보내면 409 / 5409(Resource already
 * exists)가 온다. 이걸 재시도 대상으로 두면 8번 헛돌다 실패로 끝나고, Dart가 새 티켓으로
 * 같은 사진을 한 번 더 올려 Cloudflare에 고아 이미지가 남는다.
 */
internal object CloudflareImageUploadResponse {
    fun isAlreadyUploaded(uploadUrl: String, status: Int, body: String): Boolean {
        if (status != 409) return false
        return try {
            val url = URI(uploadUrl)
            if (url.scheme != "https" || url.host != "upload.imagedelivery.net" ||
                (url.port != -1 && url.port != 443)) return false
            val json = JSONObject(body)
            if (json.opt("success") != false) return false
            val errors = json.optJSONArray("errors") ?: return false
            // 다른 충돌이나 추가 오류가 섞인 응답까지 성공으로 숨기지 않는다.
            errors.length() == 1 && errors.optJSONObject(0)?.opt("code") == 5409
        } catch (_: Exception) {
            false
        }
    }
}
