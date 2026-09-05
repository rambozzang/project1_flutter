import 'package:flutter_test/flutter_test.dart';
import 'package:project1/services/upload_policy.dart';

void main() {
  const double mbps = 1000 * 1000;

  group('needsVideoCompression', () {
    test('4K는 비트레이트와 무관하게 압축한다 (다운스케일 자체가 이득)', () {
      expect(
          needsVideoCompression(width: 2160, height: 3840, bitrate: 5 * mbps),
          isTrue);
      expect(
          needsVideoCompression(width: 3840, height: 2160, bitrate: 5 * mbps),
          isTrue);
    });

    test('1080p 저비트레이트는 재인코딩해도 작아지지 않으니 원본 그대로', () {
      expect(
          needsVideoCompression(width: 1080, height: 1920, bitrate: 8 * mbps),
          isFalse);
      // 가로 영상도 같은 판단
      expect(
          needsVideoCompression(width: 1920, height: 1080, bitrate: 8 * mbps),
          isFalse);
    });

    test('1080p 고비트레이트(60fps 폰 촬영 등)는 압축한다', () {
      expect(
          needsVideoCompression(width: 1080, height: 1920, bitrate: 16 * mbps),
          isTrue);
    });

    test('720p는 출력 추정치(약 3.9Mbps)에 맞춰 더 낮은 비트레이트부터 압축한다', () {
      expect(
          needsVideoCompression(width: 720, height: 1280, bitrate: 4 * mbps),
          isFalse);
      expect(
          needsVideoCompression(width: 720, height: 1280, bitrate: 8 * mbps),
          isTrue);
    });

    test('규격을 모르면 압축하지 않는다', () {
      expect(needsVideoCompression(width: 0, height: 0, bitrate: 50 * mbps),
          isFalse);
    });
  });

  group('expectedCompressedBitrate', () {
    test('1080p30 기준 약 8.7Mbps', () {
      expect(expectedCompressedBitrate(1080, 1920),
          closeTo(8.7 * mbps, 0.1 * mbps));
    });

    test('4K는 1080p로 줄인 뒤의 값이라 1080p와 같다', () {
      expect(expectedCompressedBitrate(2160, 3840),
          closeTo(expectedCompressedBitrate(1080, 1920), 1));
    });

    test('비율이 다른 영상은 더 세게 줄여야 하는 변을 따른다 (2160x2160 → 1080x1080)', () {
      expect(expectedCompressedBitrate(2160, 2160),
          closeTo(0.14 * 1080 * 1080 * 30, 1));
    });
  });

  group('UploadTooLargeException', () {
    test('MB 단위로 읽히는 메시지', () {
      const e = UploadTooLargeException(250 * 1024 * 1024);
      expect(e.megabytes, 250);
      expect(e.toString(), contains('250'));
      expect(e.toString(), contains('$kDirectUploadMaxMegabytes'));
    });

    test('상한은 Cloudflare 기본 업로드 한도인 200MB', () {
      expect(kDirectUploadMaxBytes, 200 * 1024 * 1024);
    });
  });
}
