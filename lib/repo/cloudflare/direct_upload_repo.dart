import 'dart:io';

import 'package:dio/dio.dart';
import 'package:heif_converter/heif_converter.dart';
import 'package:project1/config/url_config.dart';
import 'package:project1/repo/api/auth_dio.dart';
import 'package:project1/utils/log_utils.dart';

/// Cloudflare Direct Creator Upload.
/// API 토큰은 백엔드에만 존재하고, 앱은 백엔드가 발급한 "일회용 업로드 URL"로만 직접 업로드한다.
/// (기존: 앱에 계정 토큰·글로벌 API 키가 하드코딩 — APK 리버싱으로 유출 가능해 제거함)

/// 영상 업로드 티켓 — 일회용 업로드 URL + uid 기반 재생/썸네일 URL(서버가 조립).
class VideoUploadTicket {
  final String uploadUrl;
  final String uid;
  final String hls;
  final String dash;
  final String thumbnail; // jpg
  final String animatedThumbnail; // gif
  final String preview; // watch 페이지

  VideoUploadTicket({
    required this.uploadUrl,
    required this.uid,
    required this.hls,
    required this.dash,
    required this.thumbnail,
    required this.animatedThumbnail,
    required this.preview,
  });

  factory VideoUploadTicket.fromMap(Map<String, dynamic> m) => VideoUploadTicket(
        uploadUrl: m['uploadUrl']?.toString() ?? '',
        uid: m['uid']?.toString() ?? '',
        hls: m['hls']?.toString() ?? '',
        dash: m['dash']?.toString() ?? '',
        thumbnail: m['thumbnail']?.toString() ?? '',
        animatedThumbnail: m['animatedThumbnail']?.toString() ?? '',
        preview: m['preview']?.toString() ?? '',
      );
}

/// 이미지 업로드 결과 — imagedelivery 배포 URL과 이미지 ID(삭제 시 사용).
class ImageUploadResult {
  final String id;
  final String url;
  ImageUploadResult({required this.id, required this.url});
}

class DirectUploadRepo {
  /// 영상: 업로드 URL 발급 → 파일 업로드. 성공 시 재생 URL들이 담긴 티켓 반환, 실패 시 null.
  Future<VideoUploadTicket?> uploadVideoFile(File videoFile, {void Function(int, int)? onProgress}) async {
    final ticket = await _issueVideoTicket();
    if (ticket == null || ticket.uploadUrl.isEmpty) return null;
    final ok = await _uploadTo(ticket.uploadUrl, videoFile, onProgress: onProgress);
    return ok ? ticket : null;
  }

  /// 이미지: (heic/heif → png 변환 후) 업로드 URL 발급 → 파일 업로드.
  Future<ImageUploadResult?> uploadImageFile(File imageFile, {void Function(int, int)? onProgress}) async {
    try {
      if (imageFile.path.endsWith('.heif') || imageFile.path.endsWith('.heic')) {
        final String? converted = await HeifConverter.convert(imageFile.path, format: 'png');
        if (converted != null) imageFile = File(converted);
      }
    } catch (e) {
      lo.g('HEIF 변환 실패(원본으로 시도): $e');
    }

    final resData = await _post('/cloudflare/imageUploadUrl');
    if (resData == null) return null;
    final String uploadUrl = resData['uploadUrl']?.toString() ?? '';
    final String id = resData['id']?.toString() ?? '';
    final String url = resData['deliveryUrl']?.toString() ?? '';
    if (uploadUrl.isEmpty || id.isEmpty) return null;

    final ok = await _uploadTo(uploadUrl, imageFile, onProgress: onProgress);
    if (!ok) return null;
    return ImageUploadResult(id: id, url: url);
  }

  /// 이미지 삭제(백엔드 프록시 — 앱에 토큰 없음).
  Future<bool> deleteImage(String imageId) async {
    try {
      final dio = await AuthDio.instance.getDio();
      final res = await dio.post('${UrlConfig.baseURL}/cloudflare/deleteImage', queryParameters: {'imageId': imageId});
      final data = AuthDio.instance.dioResponse(res);
      return data.code == '00' && data.data == true;
    } catch (e) {
      lo.g('이미지 삭제 실패($imageId): $e');
      return false;
    }
  }

  Future<VideoUploadTicket?> _issueVideoTicket() async {
    final resData = await _post('/cloudflare/videoUploadUrl');
    if (resData == null) return null;
    return VideoUploadTicket.fromMap(resData);
  }

  Future<Map<String, dynamic>?> _post(String path) async {
    try {
      final dio = await AuthDio.instance.getDio();
      final res = await dio.post('${UrlConfig.baseURL}$path');
      final data = AuthDio.instance.dioResponse(res);
      if (data.code != '00' || data.data == null) {
        lo.g('$path 실패: ${data.msg}');
        return null;
      }
      return Map<String, dynamic>.from(data.data as Map);
    } catch (e) {
      lo.g('$path 오류: $e');
      return null;
    }
  }

  /// 발급받은 일회용 URL로 멀티파트 업로드(인증 헤더 불필요).
  Future<bool> _uploadTo(String uploadUrl, File file, {void Function(int, int)? onProgress}) async {
    try {
      final dio = Dio(BaseOptions(
        connectTimeout: const Duration(seconds: 30),
        // 대용량 영상 대비 — 전송은 길게, 응답은 짧게
        sendTimeout: const Duration(minutes: 30),
        receiveTimeout: const Duration(minutes: 2),
      ));
      final form = FormData.fromMap({'file': await MultipartFile.fromFile(file.path)});
      final res = await dio.post(uploadUrl, data: form, onSendProgress: onProgress);
      final int code = res.statusCode ?? 0;
      if (code < 200 || code >= 300) {
        lo.g('direct upload 실패: HTTP $code');
        return false;
      }
      return true;
    } on DioException catch (e) {
      lo.g('direct upload 오류: ${e.response?.statusCode} ${e.message}');
      return false;
    }
  }
}
