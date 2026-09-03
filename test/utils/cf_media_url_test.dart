import 'package:flutter_test/flutter_test.dart';
import 'package:project1/utils/cf_media_url.dart';

/// 백엔드(CloudflareSvc)가 조립하는 실제 Stream 베이스.
/// `cloudflare.stream-domain` 기본값이 customer-r151saam0lb88khc.cloudflarestream.com 이다.
const String _base = 'https://customer-r151saam0lb88khc.cloudflarestream.com/abc123uid';

void main() {
  group('streamPoster — Stream URL 정규화', () {
    test('애니메이션 GIF 썸네일은 정적 JPG 로 바뀐다', () {
      final out = CfMediaUrl.streamPoster('$_base/thumbnails/thumbnail.gif');
      expect(Uri.parse(out).path, endsWith('/thumbnails/thumbnail.jpg'));
      expect(out, isNot(contains('.gif')));
    });

    test('이미 JPG 면 경로는 그대로 유지된다', () {
      final out = CfMediaUrl.streamPoster('$_base/thumbnails/thumbnail.jpg');
      expect(Uri.parse(out).path, endsWith('/thumbnails/thumbnail.jpg'));
    });

    test('png/jpeg 썸네일도 jpg 로 통일된다', () {
      expect(Uri.parse(CfMediaUrl.streamPoster('$_base/thumbnails/thumbnail.png')).path,
          endsWith('/thumbnails/thumbnail.jpg'));
      expect(Uri.parse(CfMediaUrl.streamPoster('$_base/thumbnails/thumbnail.jpeg')).path,
          endsWith('/thumbnails/thumbnail.jpg'));
    });

    test('HLS manifest(m3u8) 는 썸네일 JPG 로 바뀐다', () {
      final out = CfMediaUrl.streamPoster('$_base/manifest/video.m3u8');
      expect(Uri.parse(out).path, endsWith('/thumbnails/thumbnail.jpg'));
      expect(out, isNot(contains('manifest')));
    });

    test('DASH manifest(mpd) 는 썸네일 JPG 로 바뀐다', () {
      final out = CfMediaUrl.streamPoster('$_base/manifest/video.mpd');
      expect(Uri.parse(out).path, endsWith('/thumbnails/thumbnail.jpg'));
      expect(out, isNot(contains('manifest')));
    });

    test('GIF 전용 쿼리(duration·fps)는 제거하고 time 은 보존한다', () {
      final out = CfMediaUrl.streamPoster(
        '$_base/thumbnails/thumbnail.gif?time=3s&duration=5s&fps=8',
      );
      final q = Uri.parse(out).queryParameters;
      expect(q.containsKey('duration'), isFalse);
      expect(q.containsKey('fps'), isFalse);
      expect(q['time'], '3s');
    });

    test('width 를 붙이고, height 를 주면 함께 붙는다', () {
      final noHeight = Uri.parse(CfMediaUrl.streamPoster('$_base/thumbnails/thumbnail.gif')).queryParameters;
      expect(noHeight['width'], '900');
      expect(noHeight.containsKey('height'), isFalse);

      final sized = Uri.parse(
        CfMediaUrl.streamPoster('$_base/thumbnails/thumbnail.gif', width: 120, height: 120),
      ).queryParameters;
      expect(sized['width'], '120');
      expect(sized['height'], '120');
    });

    test('두 번 정규화해도 결과가 같다(멱등)', () {
      final once = CfMediaUrl.streamPoster('$_base/thumbnails/thumbnail.gif?duration=5s');
      expect(CfMediaUrl.streamPoster(once), once);
    });

    test('Stream 이지만 썸네일·manifest 가 아닌 경로는 건드리지 않는다', () {
      const watch = '$_base/watch';
      expect(CfMediaUrl.streamPoster(watch), watch);
    });
  });

  // ── 회귀 방지 핵심 ──────────────────────────────────────────────
  // 이 앱의 URL 중 상당수는 Cloudflare Stream 이 아니다(사진=imagedelivery,
  // 외부 이미지, 서버 파일 경로). 호스트 확인 없이 경로를 갈아치우면 멀쩡한
  // URL 이 깨진다.
  group('streamPoster — Cloudflare Stream 이 아니면 절대 변경하지 않는다', () {
    test('Cloudflare Images(imagedelivery.net) 사진은 무변경', () {
      const url = 'https://imagedelivery.net/abcdefg/d4098ecd-1111-2222/public';
      expect(CfMediaUrl.streamPoster(url), url);
    });

    test('임의 호스트의 gif 는 무변경', () {
      const url = 'https://example.com/a.gif';
      expect(CfMediaUrl.streamPoster(url), url);
    });

    test('경로가 똑같아도 호스트가 다르면 무변경', () {
      const url = 'https://example.com/uid/thumbnails/thumbnail.gif?duration=5s&fps=8';
      expect(CfMediaUrl.streamPoster(url), url);
    });

    test('호스트를 부분 문자열로만 포함하는 사칭 도메인은 무변경', () {
      const url = 'https://cloudflarestream.com.evil.io/uid/thumbnails/thumbnail.gif';
      expect(CfMediaUrl.streamPoster(url), url);
    });

    test('빈 문자열은 그대로', () {
      expect(CfMediaUrl.streamPoster(''), '');
    });

    test('URL 이 아닌 문자열도 안전하게 원본 반환', () {
      expect(CfMediaUrl.streamPoster('그냥 문자열'), '그냥 문자열');
      expect(CfMediaUrl.streamPoster('/data/files/thumb.gif'), '/data/files/thumb.gif');
      expect(CfMediaUrl.streamPoster('http://['), 'http://[');
    });
  });

  group('isCfStream — 호스트 판별', () {
    test('실제 배포 서브도메인과 legacy videodelivery.net 을 인식한다', () {
      expect(CfMediaUrl.isCfStream('$_base/thumbnails/thumbnail.jpg'), isTrue);
      expect(CfMediaUrl.isCfStream('https://videodelivery.net/uid/thumbnails/thumbnail.jpg'), isTrue);
    });

    test('그 외 호스트는 false', () {
      expect(CfMediaUrl.isCfStream('https://imagedelivery.net/h/i/public'), isFalse);
      expect(CfMediaUrl.isCfStream(''), isFalse);
    });
  });
}
