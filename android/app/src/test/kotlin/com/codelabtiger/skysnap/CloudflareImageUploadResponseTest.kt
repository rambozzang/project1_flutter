package com.codelabtiger.skysnap

import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class CloudflareImageUploadResponseTest {
    private val url = "https://upload.imagedelivery.net/test-account/test-image"
    private val duplicate = """{"success":false,"errors":[{"code":5409,"message":"Resource already exists. Verify the resource information and try again."}]}"""

    @Test fun recognizesObservedDuplicateImageResponse() {
        assertTrue(CloudflareImageUploadResponse.isAlreadyUploaded(url, 409, duplicate))
    }

    @Test fun rejectsOtherStatusCodes() {
        for (status in listOf(200, 400, 403, 408, 429, 500)) {
            assertFalse(CloudflareImageUploadResponse.isAlreadyUploaded(url, status, duplicate))
        }
    }

    @Test fun requiresCloudflareImagesHttpsHost() {
        for (other in listOf(
            "http://upload.imagedelivery.net/a/b",
            "https://upload.imagedelivery.net.evil.example/a/b",
            "https://evil.example/?host=upload.imagedelivery.net",
            "https://upload.videodelivery.net/a/b",
            "https://upload.imagedelivery.net:8443/a/b",
            "not a URL",
        )) {
            assertFalse(CloudflareImageUploadResponse.isAlreadyUploaded(other, 409, duplicate))
        }
    }

    @Test fun rejectsUnknownConflictsAndMixedErrors() {
        for (body in listOf(
            """{"success":false,"errors":[{"code":9999}]}""",
            """{"success":false,"errors":[{"code":5409.5}]}""",
            """{"success":false,"errors":[{"code":"5409"}]}""",
            """{"success":false,"errors":[{"code":5409},{"code":9999}]}""",
            """{"success":true,"errors":[{"code":5409}]}""",
            """{"errors":[{"code":5409}]}""",
            """{"success":false,"errors":[]}""",
            """{"success":false,"errors":[{"message":"Resource already exists"}]}""",
            "<html>Conflict</html>",
            "",
        )) {
            assertFalse(CloudflareImageUploadResponse.isAlreadyUploaded(url, 409, body))
        }
    }

    @Test fun unknown409RemainsRetryable() {
        assertTrue(BackgroundUploadHttp.isRetryableStatus(409))
    }
}
