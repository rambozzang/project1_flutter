/// Cloudflare Stream 영상 URL 을 **정적 JPG 포스터 URL** 로 정규화한다.
///
/// 과거 업로드 코드가 `animatedThumbnail`(= `/thumbnails/thumbnail.gif`)을 그대로
/// 저장해서, DB 에는 애니메이션 GIF 썸네일이 상당수 남아 있다. 이 GIF 는 한 장이
/// 수 MB 라 목록 화면 몇 칸만 보여도 사진 수백 장 분량을 내려받게 되고, 정지
/// 화면이어야 할 그리드에서 혼자 움직여 시선을 뺏는다. 그래서 **표시 시점에**
/// 항상 정적 JPG 로 바꿔 요청한다.
///
/// 이름이 `CfMediaUrl` 이지만 다루는 건 Stream 뿐이다. 이 앱에는 Cloudflare
/// Images variant(`public`/`grid` 같은 이름 치환) 기능이 없어서 사진 URL
/// (`imagedelivery.net`)은 손대지 않고 그대로 통과시킨다.
class CfMediaUrl {
  CfMediaUrl._();

  /// Cloudflare Stream 이 서빙하는 호스트.
  ///
  /// - `cloudflarestream.com` — 백엔드 `CloudflareSvc` 의 `cloudflare.stream-domain`
  ///   기본값이 `customer-r151saam0lb88khc.cloudflarestream.com` 이라 실제로는
  ///   서브도메인으로 들어온다.
  /// - `videodelivery.net` — Cloudflare Stream 의 구 배포 도메인. 이 저장소에서는
  ///   쓰는 곳을 찾지 못했지만, DB 에 남아 있을 수 있는 옛 URL 을 위해 함께 본다.
  ///   (판별만 넓힐 뿐 다른 호스트에는 영향이 없다)
  static const List<String> streamHosts = [
    'cloudflarestream.com',
    'videodelivery.net',
  ];

  /// Cloudflare Stream 이 서빙하는 URL 인가.
  ///
  /// `url.contains(host)` 로 검사하면 `cloudflarestream.com.evil.io` 같은 주소도
  /// 통과하므로, 반드시 파싱한 **호스트**를 정확히 비교한다.
  static bool isCfStream(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null || uri.scheme != 'https') return false;
    final host = uri.host.toLowerCase();
    return streamHosts.any((h) => host == h || host.endsWith('.$h'));
  }

  /// Stream 의 GIF/JPG/manifest URL 을 정적 JPG 썸네일 URL 로 정규화한다.
  ///
  /// 이미 붙어 있는 `time` 같은 안전한 옵션은 보존하되 GIF 전용 `duration`,
  /// `fps` 는 제거한다. **Cloudflare Stream 이 아닌 주소는 절대 변경하지 않는다** —
  /// 이 앱의 URL 에는 사진(`imagedelivery.net`), 외부 이미지, 서버 파일 경로가
  /// 섞여 있어서 호스트 확인 없이 경로를 갈아치우면 멀쩡한 URL 이 깨진다.
  static String streamPoster(
    String url, {
    int width = 900,
    int? height,
  }) {
    if (!isCfStream(url)) return url;
    final uri = Uri.tryParse(url);
    if (uri == null) return url;

    var path = uri.path;
    final thumbnailPattern = RegExp(
      r'/thumbnails/thumbnail\.(gif|jpe?g|png)$',
      caseSensitive: false,
    );
    if (thumbnailPattern.hasMatch(path)) {
      path = path.replaceFirst(thumbnailPattern, '/thumbnails/thumbnail.jpg');
    } else if (path.endsWith('/manifest/video.m3u8') || path.endsWith('/manifest/video.mpd')) {
      path = path.replaceFirst(RegExp(r'/manifest/video\.(m3u8|mpd)$'), '/thumbnails/thumbnail.jpg');
    } else {
      // Stream 이지만 우리가 아는 썸네일·재생 경로가 아니면 판단하지 않는다.
      return url;
    }

    final query = Map<String, String>.from(uri.queryParameters)
      ..remove('duration')
      ..remove('fps')
      ..['width'] = width.clamp(1, 2000).toString()
      ..['fit'] = 'crop';
    if (height != null) {
      query['height'] = height.clamp(1, 2000).toString();
    } else {
      query.remove('height');
    }
    return uri.replace(path: path, queryParameters: query).toString();
  }
}
