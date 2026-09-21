import 'dart:io';

import 'package:dio/dio.dart';
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

  factory VideoUploadTicket.fromMap(Map<String, dynamic> m) =>
      VideoUploadTicket(
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

/// 이미지 업로드 티켓 — 일회용 업로드 URL + 전송 성공 후 쓸 결과값.
/// 전송을 OS(네이티브 백그라운드 업로드)에 넘길 때는 URL만 건네고,
/// 성공 판정 뒤 [result] 를 그대로 게시에 쓴다.
class ImageUploadTicket {
  final String uploadUrl;
  final String id;
  final String url;

  ImageUploadTicket(
      {required this.uploadUrl, required this.id, required this.url});

  ImageUploadResult get result => ImageUploadResult(id: id, url: url);
}

class DirectUploadRepo {
  /// 영속화한 티켓의 URL로 전송한다. 티켓을 몰래 재발급하지 않는다.
  Future<bool> uploadTicket(String uploadUrl, File file) =>
      _uploadTo(uploadUrl, file);

  /// 영상: 업로드 URL 발급 → 파일 업로드. 성공 시 재생 URL들이 담긴 티켓 반환, 실패 시 null.
  Future<VideoUploadTicket?> uploadVideoFile(File videoFile,
      {void Function(int, int)? onProgress}) async {
    final ticket = await _issueVideoTicket();
    if (ticket == null || ticket.uploadUrl.isEmpty) return null;
    final ok =
        await _uploadTo(ticket.uploadUrl, videoFile, onProgress: onProgress);
    return ok ? ticket : null;
  }

  /// 이미지: (필요할 때만 변환 후) 업로드 URL 발급 → 파일 업로드.
  Future<ImageUploadResult?> uploadImageFile(File imageFile,
      {void Function(int, int)? onProgress}) async {
    final File prepared = await prepareForUpload(imageFile);
    final ImageUploadTicket? ticket = await issueImageTicket();
    if (ticket == null) return null;

    final ok =
        await _uploadTo(ticket.uploadUrl, prepared, onProgress: onProgress);
    if (!ok) return null;
    return ticket.result;
  }

  /// 업로드에 쓸 파일을 고른다. **Cloudflare 가 받아 주는 포맷은 손대지 않는다.**
  ///
  /// 예전에는 heic/heif 를 폰에서 **png 로 바꿔** 올렸다. 그런데 Cloudflare Images
  /// 는 heic 를 원본으로 받는다 — 거절할 때 직접 알려 주는 목록이 근거다
  /// (자매 앱 모모앨범이 2026-09-09 운영 계정에서 실측):
  ///
  ///     Uploaded image must have image/jpeg, image/png, image/webp,
  ///     image/gif, image/heic or image/svg+xml content-type
  ///
  /// 같은 시험에서 heic 업로드가 성공했고, 내려오는 variant 는 전부
  /// `image/jpeg` 였다. 즉 **변환은 Cloudflare 가 한다.**
  ///
  /// 폰에서 굳이 바꾸면 손해만 크다. png 는 무손실이라 12MP 아이폰 사진
  /// (heic 2MB 안팎)이 **20~35MB** 로 불어난다 — 변환 시간, 데이터 요금,
  /// 업로드 시간이 전부 열 배가 되고 큰 파일은 실패 위험까지 진다.
  ///
  /// 확장자가 아니라 **실제 시그니처**로 본다. 갤러리가 주는 경로의 확장자는
  /// 믿을 게 못 된다(`.jpg` 인데 내용은 heic 인 경우가 있다).
  ///
  /// 네이티브 백그라운드 전송도 **여기서 정한 같은 파일**을 써야 하므로 따로
  /// 떼어 공개한다.
  ///
  /// 걸러지는 건 Cloudflare 가 안 받는 포맷(bmp·tiff 등)뿐인데, 휴대폰
  /// 갤러리에서는 사실상 나오지 않아 **변환기를 두지 않는다.** 그대로 올려
  /// 서버 판정에 맡기고 로그만 남긴다 — 실제로 찍히기 시작하면 그때 jpeg
  /// 정규화를 넣는다. 추측으로 미리 만들지 않는다.
  Future<File> prepareForUpload(File imageFile) async {
    try {
      final String lowerPath = imageFile.path.toLowerCase();
      final List<int> header = await _readHeader(imageFile);
      if (!_cloudflareAccepts(lowerPath, header)) {
        lo.g('Cloudflare 가 받지 않는 포맷일 수 있다(원본으로 시도): ${imageFile.path}');
      }
    } catch (e) {
      lo.g('업로드용 이미지 판정 실패(원본으로 시도): $e');
    }
    return imageFile;
  }

  /// 파일 앞 64바이트. 포맷 판정은 확장자가 아니라 이 시그니처로 한다.
  Future<List<int>> _readHeader(File file) async {
    final header = <int>[];
    await for (final chunk in file.openRead(0, 64)) {
      header.addAll(chunk);
    }
    return header;
  }

  /// Cloudflare Images 가 **원본으로 받아 주는 포맷**인가.
  ///
  /// 목록은 추측이 아니라 Cloudflare 가 거절하며 직접 알려 준 것이다
  /// (모모앨범 2026-09-09 운영 계정 실측). 같은 시험에서 gif 는 통과했고
  /// bmp·tiff 는 거절당했다. gif 를 jpeg 로 바꾸면 **움직임이 사라진다** —
  /// 받아 주는 것을 폰에서 굳이 바꾸지 않는 이유가 하나 더 있는 셈이다.
  bool _cloudflareAccepts(String lowerPath, List<int> header) =>
      _isJpegHeader(header) ||
      _isPngHeader(header) ||
      _isGifHeader(header) ||
      _isWebpHeader(header) ||
      _isSvg(lowerPath, header) ||
      _isHeifPath(lowerPath) ||
      _isHeifHeader(header);

  bool _isHeifPath(String path) =>
      path.endsWith('.heic') || path.endsWith('.heif');

  /// ISO-BMFF 박스: [4..8) 이 'ftyp', [8..12) 가 heif 계열 브랜드.
  bool _isHeifHeader(List<int> bytes) {
    if (bytes.length < 12 ||
        String.fromCharCodes(bytes.sublist(4, 8)) != 'ftyp') {
      return false;
    }
    final brand = String.fromCharCodes(bytes.sublist(8, 12));
    return const {'heic', 'heix', 'heis', 'hevc', 'hevx', 'mif1', 'msf1'}
        .contains(brand);
  }

  /// 0xFF 0xD8 0xFF (SOI + 마커).
  bool _isJpegHeader(List<int> b) =>
      b.length >= 3 && b[0] == 0xFF && b[1] == 0xD8 && b[2] == 0xFF;

  /// \x89PNG\r\n\x1a\n.
  bool _isPngHeader(List<int> b) =>
      b.length >= 8 &&
      b[0] == 0x89 &&
      b[1] == 0x50 &&
      b[2] == 0x4E &&
      b[3] == 0x47 &&
      b[4] == 0x0D &&
      b[5] == 0x0A &&
      b[6] == 0x1A &&
      b[7] == 0x0A;

  /// 'GIF87a' 또는 'GIF89a'.
  bool _isGifHeader(List<int> b) =>
      b.length >= 6 && String.fromCharCodes(b.sublist(0, 6)).startsWith('GIF8');

  /// 'RIFF' .... 'WEBP'.
  bool _isWebpHeader(List<int> b) =>
      b.length >= 12 &&
      String.fromCharCodes(b.sublist(0, 4)) == 'RIFF' &&
      String.fromCharCodes(b.sublist(8, 12)) == 'WEBP';

  /// svg 는 텍스트라 시그니처가 없다. 확장자와 앞머리를 같이 본다.
  bool _isSvg(String lowerPath, List<int> b) {
    if (!lowerPath.endsWith('.svg')) return false;
    final head = String.fromCharCodes(b).trimLeft().toLowerCase();
    return head.startsWith('<svg') || head.startsWith('<?xml');
  }

  /// 전송 없이 이미지 티켓만 발급한다(네이티브 백그라운드 전송용).
  Future<ImageUploadTicket?> issueImageTicket() async {
    final resData = await _post('/cloudflare/imageUploadUrl');
    if (resData == null) return null;
    final String uploadUrl = resData['uploadUrl']?.toString() ?? '';
    final String id = resData['id']?.toString() ?? '';
    final String url = resData['deliveryUrl']?.toString() ?? '';
    if (uploadUrl.isEmpty || id.isEmpty) return null;
    return ImageUploadTicket(uploadUrl: uploadUrl, id: id, url: url);
  }

  /// 전송 없이 영상 티켓만 발급한다(네이티브 백그라운드 전송용).
  Future<VideoUploadTicket?> issueVideoTicket() => _issueVideoTicket();

  /// 이미지 삭제(백엔드 프록시 — 앱에 토큰 없음).
  Future<bool> deleteImage(String imageId) async {
    try {
      final dio = await AuthDio.instance.getDio();
      final res = await dio.post('${UrlConfig.baseURL}/cloudflare/deleteImage',
          queryParameters: {'imageId': imageId});
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
  Future<bool> _uploadTo(String uploadUrl, File file,
      {void Function(int, int)? onProgress}) async {
    try {
      final dio = Dio(BaseOptions(
        connectTimeout: const Duration(seconds: 30),
        // 대용량 영상 대비 — 전송은 길게, 응답은 짧게
        sendTimeout: const Duration(minutes: 30),
        receiveTimeout: const Duration(minutes: 2),
      ));
      final form =
          FormData.fromMap({'file': await MultipartFile.fromFile(file.path)});
      final res =
          await dio.post(uploadUrl, data: form, onSendProgress: onProgress);
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
