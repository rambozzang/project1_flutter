// 업로드 전 판단 규칙. 플러그인·플랫폼 채널에 기대지 않는 순수 함수만 둔다(테스트 가능).
//
// 클라이언트 압축의 목적은 **업로드 바이트 절감 하나**다. 화질·규격은 어차피
// Cloudflare Stream 이 서버에서 다시 트랜스코딩한다. 그래서 압축은 결과 파일이
// 실제로 작아질 때만 돌린다 — 그렇지 않으면 몇 분간 CPU 만 태우고(iOS 는 오히려
// 커질 수도 있다) 사용자는 게시가 늦어지는 것만 본다.

/// Cloudflare Direct Creator Upload 기본(multipart) 방식의 파일 크기 상한.
/// 이 앱은 tus 이어올리기를 쓰지 않으므로(`native_background_upload.dart`) 이보다
/// 큰 파일은 서버가 거부한다. 압축 뒤에도 넘으면 재시도해도 결과가 같다.
const int kDirectUploadMaxMegabytes = 200;
const int kDirectUploadMaxBytes = kDirectUploadMaxMegabytes * 1024 * 1024;

/// 압축 프리셋 `VideoQuality.Res1920x1080Quality` 의 출력 규격.
/// 두 플랫폼 모두 긴 변 1920·짧은 변 1080 안으로 **줄이기만** 한다(작은 영상은 그대로).
const int kCompressLongSide = 1920;
const int kCompressShortSide = 1080;

/// 출력 비트레이트 추정치(bps/픽셀/프레임). Android 플러그인(otaliastudios transcoder
/// `DefaultVideoStrategy`)의 산식 0.07×2 를 그대로 쓴다 — 1080p30 ≈ 8.7Mbps, 720p30 ≈ 3.9Mbps.
/// iOS 의 `AVAssetExportPreset1920x1080` 도 같은 자릿수(1080p ≈ 10Mbps)다.
const double _bitsPerPixelPerFrame = 0.14;
const int _outputFrameRate = 30;

/// 원본이 추정 출력보다 이만큼은 커야 압축한다. 20% 남짓 줄자고 몇 분 태울 일은 아니다.
const double _minGainRatio = 1.25;

/// 프리셋을 거친 뒤 예상되는 비트레이트(bps). [width]/[height] 는 원본 규격.
double expectedCompressedBitrate(int width, int height) {
  final int longSide = width > height ? width : height;
  final int shortSide = width > height ? height : width;
  if (longSide <= 0 || shortSide <= 0) return 0;
  // 긴 변·짧은 변 각각의 상한 중 더 세게 줄여야 하는 쪽을 따른다(비율 유지, 확대는 없음).
  final double scale = [
    1.0,
    kCompressLongSide / longSide,
    kCompressShortSide / shortSide,
  ].reduce((a, b) => a < b ? a : b);
  return _bitsPerPixelPerFrame *
      (longSide * scale) *
      (shortSide * scale) *
      _outputFrameRate;
}

/// 압축 여부. 해상도가 프리셋보다 크면 다운스케일 자체가 이득이라 무조건 압축하고,
/// 그 안이면 원본 비트레이트가 추정 출력의 [_minGainRatio] 배를 넘을 때만 압축한다.
/// [bitrate] 는 bps. 규격을 모르면(0) 압축하지 않는다 — 원본 그대로가 덜 위험하다.
bool needsVideoCompression({
  required int width,
  required int height,
  required double bitrate,
}) {
  final int longSide = width > height ? width : height;
  final int shortSide = width > height ? height : width;
  if (longSide <= 0 || shortSide <= 0) return false;
  if (longSide > kCompressLongSide || shortSide > kCompressShortSide) {
    return true;
  }
  return bitrate > expectedCompressedBitrate(width, height) * _minGainRatio;
}

/// 압축을 거친 뒤에도 [kDirectUploadMaxBytes] 를 넘는 파일. 재시도로 달라질 게 없는 종료형 실패.
class UploadTooLargeException implements Exception {
  const UploadTooLargeException(this.bytes);

  final int bytes;

  int get megabytes => (bytes / (1024 * 1024)).round();

  @override
  String toString() => '$megabytes MB > $kDirectUploadMaxMegabytes MB';
}
