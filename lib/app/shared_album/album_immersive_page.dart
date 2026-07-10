import 'dart:async';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:preload_page_view/preload_page_view.dart' hide PageScrollPhysics;
import 'package:project1/app/shared_album/theme/sa_colors.dart';
import 'package:project1/app/shared_album/theme/sa_text_styles.dart';
import 'package:project1/app/shared_album/theme/sa_weather_gradients.dart';
import 'package:project1/app/shared_album/widget/sa_glass_chip.dart';
import 'package:project1/app/videocomment/comment_page.dart';
import 'package:project1/app/videolist/video_list_page.dart' show FastPageScrollPhysics;
import 'package:project1/repo/board/data/board_weather_list_data.dart';
import 'package:project1/repo/community/community_repo.dart';
import 'package:project1/repo/weather/like_repo.dart';
import 'package:project1/utils/log_utils.dart';
import 'package:project1/utils/utils.dart';
import 'package:project1/utils/sns_share.dart';
import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';

/// 앨범 상세 — 1e 몰입 뷰(틱톡식 세로 풀스크린).
/// 세로 PageView로 미디어 전환, 탭=재생/일시정지, 더블탭=좋아요(하트 애니메이션).
/// 우측 액션 레일(아바타/좋아요/댓글/공유) + 좌하단 정보(업로더·캡션·날씨 칩) + 영상 스크러버.
/// 주의: 풀스크린 미디어 규칙 — SafeArea 금지, cover 표시, 오버레이만 viewPadding 보정.
///
/// 반응성은 기본 피드(video_list_page)와 동일 구성:
/// PreloadPageView(preloadPagesCount=5, 인접 영상 미리 초기화·버퍼링) + FastPageScrollPhysics(민감 스와이프)
/// + 페이지별 자체 플레이어 + VisibilityDetector 재생/정지 + Android=DASH·캐시 헤더.
class AlbumImmersivePage extends StatefulWidget {
  const AlbumImmersivePage({super.key});

  @override
  State<AlbumImmersivePage> createState() => _AlbumImmersivePageState();
}

class _AlbumImmersivePageState extends State<AlbumImmersivePage> with SingleTickerProviderStateMixin {
  final CommunityRepo _repo = CommunityRepo();
  final LikeRepo _likeRepo = LikeRepo();

  late final int _communityId;
  late final String _albumName;
  late final PreloadPageController _pageCtrl;

  List<BoardWeatherListData> _items = [];
  int _index = 0;
  static const int _pageSize = 30;
  int _pageNum = 1; // 1d에서 첫 페이지를 받아오므로 다음 페이지부터
  bool _hasMore = true;
  bool _loadingMore = false;

  // 기본 피드와 동일한 프리로드 페이지 수(video_list_cntr.preLoadingCount)
  static const int _preloadCount = 5;

  // 현재 화면에 보이는 페이지의 플레이어(스크러버 표시용) — 각 페이지가 자기 플레이어를 소유한다
  final ValueNotifier<VideoPlayerController?> _activeVideo = ValueNotifier<VideoPlayerController?>(null);

  // 더블탭 하트 애니메이션
  late final AnimationController _heartCtrl;

  // "↑ 다음" 힌트: 첫 진입 시에만 잠깐 표시(bob 애니메이션)
  bool _showSwipeHint = true;

  @override
  void initState() {
    super.initState();
    final args = Get.arguments as Map<String, dynamic>? ?? {};
    _communityId = (args['communityId'] as num?)?.toInt() ?? 0;
    _albumName = args['albumName']?.toString() ?? '앨범';
    _items = (args['items'] as List<BoardWeatherListData>?) ?? [];
    _index = (args['initialIndex'] as num?)?.toInt() ?? 0;
    if (_index >= _items.length) _index = 0;
    _pageNum = (_items.length / _pageSize).ceil().clamp(1, 999);
    _pageCtrl = PreloadPageController(initialPage: _index);
    _heartCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _heartCtrl.addStatusListener((s) {
      if (s == AnimationStatus.completed) _heartCtrl.reset();
    });
    if (_items.isEmpty) {
      _loadMore(first: true);
    }
    Timer(const Duration(seconds: 4), () {
      if (mounted) setState(() => _showSwipeHint = false);
    });
  }

  @override
  void dispose() {
    _activeVideo.dispose();
    _pageCtrl.dispose();
    _heartCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadMore({bool first = false}) async {
    if (_loadingMore || (!_hasMore && !first)) return;
    _loadingMore = true;
    try {
      final res = await _repo.getFeedRes(_communityId, first ? 0 : _pageNum, _pageSize);
      if (res.code == '00' && res.data is List) {
        final list = (res.data as List).map((e) => BoardWeatherListData.fromMap(e)).toList();
        _items.addAll(list);
        _hasMore = list.length >= _pageSize;
        _pageNum++;
      } else {
        _hasMore = false;
      }
    } catch (e) {
      lo.g('몰입뷰 피드 추가 로드 실패: $e');
      _hasMore = false;
    } finally {
      _loadingMore = false;
      if (mounted) setState(() {});
    }
  }

  void _onPageChanged(int index) {
    setState(() => _index = index);
    // 기본 피드와 동일 시점에 다음 페이지 로드(프리로드 수 + 1 남았을 때)
    if (index >= _items.length - (_preloadCount + 1)) _loadMore();
  }

  Future<void> _toggleLike(BoardWeatherListData item) async {
    final bool liked = item.likeYn == 'Y';
    // 낙관적 갱신
    setState(() {
      item.likeYn = liked ? 'N' : 'Y';
      item.likeCnt = (item.likeCnt ?? 0) + (liked ? -1 : 1);
      if ((item.likeCnt ?? 0) < 0) item.likeCnt = 0;
    });
    try {
      if (liked) {
        await _likeRepo.cancle(item.boardId.toString());
      } else {
        await _likeRepo.save(item.boardId.toString(), item.custId ?? '');
      }
    } catch (e) {
      lo.g('좋아요 처리 실패: $e');
    }
  }

  void _onDoubleTap(BoardWeatherListData item) {
    if (item.likeYn != 'Y') _toggleLike(item);
    _heartCtrl.forward(from: 0);
  }

  String _fmtCount(int? n) {
    final v = n ?? 0;
    if (v >= 10000) return '${(v / 10000).toStringAsFixed(1)}만';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}천';
    return '$v';
  }

  String _fmtDuration(Duration d) {
    final m = d.inMinutes;
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  String _gradientKey() {
    const keys = ['rain', 'sunset', 'storm', 'night', 'aurora', 'golden', 'fog', 'snow'];
    return keys[_communityId % keys.length];
  }

  @override
  Widget build(BuildContext context) {
    final pad = MediaQuery.of(context).viewPadding;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: SaColorsDark.bgBase,
        body: _items.isEmpty
            ? Center(child: CircularProgressIndicator(strokeWidth: 2, color: SaColorsDark.accentTeal))
            : Stack(
                children: [
                  // 풀스크린 미디어(세로 스와이프) — SafeArea 없이 화면 전체.
                  // 기본 피드와 동일: 인접 페이지 미리 빌드(영상 미리 버퍼링) + 민감한 페이지 물리
                  PreloadPageView.builder(
                    controller: _pageCtrl,
                    scrollDirection: Axis.vertical,
                    physics: const FastPageScrollPhysics(),
                    preloadPagesCount: _preloadCount,
                    onPageChanged: _onPageChanged,
                    itemCount: _items.length,
                    itemBuilder: (context, index) => _ImmersiveMediaItem(
                      key: ValueKey('sa_immersive_${_items[index].boardId}'),
                      item: _items[index],
                      gradientKey: _gradientKey(),
                      onDoubleTap: () => _onDoubleTap(_items[index]),
                      onVisibleVideo: (ctrl) => _activeVideo.value = ctrl,
                      onHiddenVideo: (ctrl) {
                        if (_activeVideo.value == ctrl) _activeVideo.value = null;
                      },
                    ),
                  ),
                  // 상/하 스크림
                  _scrim(top: true),
                  _scrim(top: false),
                  // 더블탭 하트
                  Center(child: _buildHeartBurst()),
                  // 상단 바
                  Positioned(left: 16, right: 16, top: pad.top + 8, child: _buildTopBar()),
                  // 우상단 진행 표시
                  Positioned(right: 16, top: pad.top + 60, child: _buildProgress()),
                  // 우측 액션 레일
                  Positioned(right: 12, bottom: pad.bottom + 110, child: _buildActionRail(_items[_index])),
                  // 좌하단 정보
                  Positioned(left: 16, right: 78, bottom: pad.bottom + 72, child: _buildInfo(_items[_index])),
                  // 하단 스크러버(영상일 때만) + 스와이프 힌트
                  Positioned(left: 16, right: 16, bottom: pad.bottom + 20, child: _buildBottomBar()),
                ],
              ),
      ),
    );
  }

  Widget _scrim({required bool top}) {
    return Positioned(
      left: 0,
      right: 0,
      top: top ? 0 : null,
      bottom: top ? null : 0,
      height: top ? 160 : 250,
      child: IgnorePointer(
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: top ? Alignment.topCenter : Alignment.bottomCenter,
              end: top ? Alignment.bottomCenter : Alignment.topCenter,
              colors: [Colors.black.withOpacity(0.55), Colors.transparent],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeartBurst() {
    return AnimatedBuilder(
      animation: _heartCtrl,
      builder: (context, _) {
        if (_heartCtrl.value == 0) return const SizedBox.shrink();
        final double t = _heartCtrl.value;
        final double scale = 0.6 + Curves.elasticOut.transform(t) * 0.8;
        final double opacity = t < 0.7 ? 1.0 : (1 - (t - 0.7) / 0.3);
        return Opacity(
          opacity: opacity.clamp(0.0, 1.0),
          child: Transform.scale(
            scale: scale,
            child: PhosphorIcon(PhosphorIconsFill.heart, size: 96, color: SaColorsDark.accentPink),
          ),
        );
      },
    );
  }

  Widget _buildTopBar() {
    return Row(
      children: [
        _glassCircle(PhosphorIconsBold.caretLeft, () => Get.back()),
        const Spacer(),
        SaGlassChip(label: _albumName),
        const Spacer(),
        // 뷰 전환 세그먼트(몰입=active) — 그리드 탭 시 갤러리로 복귀
        Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.28),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: SaColorsDark.borderStrong),
          ),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => Get.back(),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                  child: PhosphorIcon(PhosphorIconsBold.squaresFour, size: 13, color: SaColorsDark.textSecondary),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(color: SaColorsDark.accentTeal, borderRadius: BorderRadius.circular(999)),
                child: PhosphorIcon(PhosphorIconsBold.frameCorners, size: 13, color: SaColorsDark.onAccent),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _glassCircle(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.28),
          shape: BoxShape.circle,
          border: Border.all(color: SaColorsDark.borderStrong),
        ),
        child: PhosphorIcon(icon, size: 16, color: SaColorsDark.textPrimary),
      ),
    );
  }

  // 진행 표시: 12개 이하면 세로 점 도트, 많으면 "n/total" mono
  Widget _buildProgress() {
    if (_items.length > 12) {
      return SaGlassChip(label: '${_index + 1}/${_items.length}', mono: true);
    }
    return Column(
      children: [
        for (int i = 0; i < _items.length; i++)
          Container(
            width: i == _index ? 6 : 4,
            height: i == _index ? 6 : 4,
            margin: const EdgeInsets.symmetric(vertical: 2.5),
            decoration: BoxDecoration(
              color: i == _index ? SaColorsDark.accentTeal : Colors.white.withOpacity(0.35),
              shape: BoxShape.circle,
            ),
          ),
      ],
    );
  }

  Widget _buildActionRail(BoardWeatherListData item) {
    final bool liked = item.likeYn == 'Y';
    return Column(
      children: [
        // 업로더 아바타
        GestureDetector(
          onTap: () => Get.toNamed('/OtherInfoPage/${item.custId}'),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 1.6),
            ),
            child: ClipOval(
              child: (item.profilePath ?? '').isNotEmpty
                  ? CachedNetworkImage(imageUrl: item.profilePath!, fit: BoxFit.cover)
                  : ColoredBox(
                      color: SaColorsDark.surfaceElevated,
                      child: Icon(Icons.person, size: 22, color: SaColorsDark.textTertiary)),
            ),
          ),
        ),
        const SizedBox(height: 18),
        _railButton(
          icon: PhosphorIconsFill.heart,
          color: liked ? SaColorsDark.accentPink : Colors.white,
          label: _fmtCount(item.likeCnt),
          onTap: () => _toggleLike(item),
        ),
        const SizedBox(height: 16),
        _railButton(
          icon: PhosphorIconsFill.chatCircle,
          color: Colors.white,
          label: _fmtCount(item.replyCnt),
          onTap: () => CommentPage().open(context, item.boardId.toString()),
        ),
        const SizedBox(height: 16),
        _railButton(
          icon: PhosphorIconsFill.shareFat,
          color: Colors.white,
          label: '공유',
          onTap: () {
            final String caption = (item.contents ?? '').isNotEmpty ? item.contents! : '$_albumName 앨범의 순간';
            final String text = '$caption\n- SkySnap 공유앨범 [$_albumName]';
            if (item.typeDtCd == 'V') {
              // mp4 우선, 없으면 썸네일로 폴백(SNS는 HLS를 못 받음).
              SnsShare.shareMedia(context, videoUrl: item.mp4, imageUrl: item.thumbnailPath, text: text);
            } else {
              final img = (item.imageUrls?.isNotEmpty ?? false) ? item.imageUrls!.first : item.thumbnailPath;
              SnsShare.shareMedia(context, imageUrl: img, text: text);
            }
          },
        ),
      ],
    );
  }

  Widget _railButton({required IconData icon, required Color color, required String label, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, size: 30, color: color, shadows: const [Shadow(color: Colors.black54, blurRadius: 8)]),
          const SizedBox(height: 4),
          Text(label, style: SaText.mono(fontSize: 10, color: Colors.white)),
        ],
      ),
    );
  }

  Widget _buildInfo(BoardWeatherListData item) {
    final List<String> weatherParts = [
      if ((item.city ?? '').isNotEmpty) item.city!,
      if ((item.currentTemp ?? '').isNotEmpty) '${item.currentTemp}°',
      if ((item.humidity ?? '').isNotEmpty) '습도 ${item.humidity}%',
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Flexible(
              child: Text(item.nickNm ?? item.custNm ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  // 몰입뷰는 항상 다크 — 모드 무관 흰색 고정(영상 위 텍스트)
                  style: SaText.titleS.copyWith(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white)),
            ),
            const SizedBox(width: 8),
            if ((item.crtDtm ?? '').isNotEmpty)
              Text(Utils.timeage(item.crtDtm!), style: SaText.mono(fontSize: 10, color: Colors.white70)),
          ],
        ),
        if ((item.contents ?? '').isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(item.contents!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: SaText.body.copyWith(color: Colors.white.withOpacity(0.9), fontSize: 13.5)),
        ],
        if (weatherParts.isNotEmpty) ...[
          const SizedBox(height: 10),
          SaGlassChip(
            label: weatherParts.join(' · '),
            icon: PhosphorIcon(PhosphorIconsFill.cloudRain, size: 12, color: SaColorsDark.textPrimary),
          ),
        ],
      ],
    );
  }

  // 스크러버는 현재 페이지 플레이어(ValueNotifier)만 구독 — 페이지 전체 rebuild 없음(기본 피드 방식)
  Widget _buildBottomBar() {
    return ValueListenableBuilder<VideoPlayerController?>(
      valueListenable: _activeVideo,
      builder: (context, v, _) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (v != null && v.value.isInitialized) ...[
              Expanded(
                child: ValueListenableBuilder<VideoPlayerValue>(
                  valueListenable: v,
                  builder: (context, val, __) {
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: val.duration.inMilliseconds == 0 ? 0 : val.position.inMilliseconds / val.duration.inMilliseconds,
                        minHeight: 3,
                        backgroundColor: Colors.white.withOpacity(0.18),
                        valueColor: AlwaysStoppedAnimation<Color>(SaColorsDark.accentTeal),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 10),
              ValueListenableBuilder<VideoPlayerValue>(
                valueListenable: v,
                builder: (context, val, __) => Text('${_fmtDuration(val.position)} / ${_fmtDuration(val.duration)}',
                    style: SaText.mono(fontSize: 10, color: Colors.white70)),
              ),
            ] else
              const Spacer(),
            if (_showSwipeHint) ...[
              const SizedBox(width: 10),
              _SwipeHint(),
            ],
          ],
        );
      },
    );
  }
}

/// 몰입뷰 미디어 1페이지 — 기본 피드(VideoScreenPage)와 동일하게 페이지가 자기 플레이어를 소유한다.
/// PreloadPageView가 인접 페이지를 미리 빌드하므로 initState에서 초기화(버퍼링)가 미리 진행되고,
/// VisibilityDetector가 화면에 보일 때만 재생/숨으면 정지+처음으로 되감기 한다.
class _ImmersiveMediaItem extends StatefulWidget {
  const _ImmersiveMediaItem({
    super.key,
    required this.item,
    required this.gradientKey,
    required this.onDoubleTap,
    required this.onVisibleVideo,
    required this.onHiddenVideo,
  });

  final BoardWeatherListData item;
  final String gradientKey;
  final VoidCallback onDoubleTap;
  final ValueChanged<VideoPlayerController?> onVisibleVideo;
  final ValueChanged<VideoPlayerController?> onHiddenVideo;

  @override
  State<_ImmersiveMediaItem> createState() => _ImmersiveMediaItemState();
}

class _ImmersiveMediaItemState extends State<_ImmersiveMediaItem> {
  VideoPlayerController? _controller;
  final ValueNotifier<bool> _initialized = ValueNotifier<bool>(false);

  bool get _isVideo => widget.item.typeDtCd == 'V';

  @override
  void initState() {
    super.initState();
    if (_isVideo) _initVideo();
  }

  /// 기본 피드(VideoScreenPage.initiliazeVideo)와 동일 구성:
  /// Android=DASH(.mpd)+formatHint / iOS=HLS, 캐시 헤더, mixWithOthers.
  Future<void> _initVideo() async {
    final item = widget.item;
    String url = (item.hls?.isNotEmpty == true) ? item.hls! : (item.videoPath ?? '');
    if (url.isEmpty) {
      url = item.mp4 ?? '';
      if (url.isEmpty) return;
    }
    VideoFormat? format;
    if (url.contains('.m3u8')) {
      if (Platform.isAndroid) {
        url = url.replaceAll('.m3u8', '.mpd');
        format = VideoFormat.dash;
      } else {
        format = VideoFormat.hls;
      }
    }
    try {
      final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
      final lastModified = _formatHttpDate(sevenDaysAgo);
      final ctrl = VideoPlayerController.networkUrl(
        Uri.parse(url),
        httpHeaders: {
          'Connection': 'keep-alive',
          'Cache-Control': 'max-age=3600, stale-while-revalidate=86400',
          'Etg': item.boardId.toString(),
          'Last-Modified': lastModified,
          'If-None-Match': item.boardId.toString(),
          'If-Modified-Since': lastModified,
          'Vary': 'Accept-Encoding, User-Agent',
        },
        videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true, allowBackgroundPlayback: false),
        formatHint: format,
      );
      _controller = ctrl;
      await ctrl.initialize();
      if (!mounted) {
        ctrl.dispose();
        return;
      }
      ctrl
        ..setLooping(true)
        ..pause(); // 재생은 VisibilityDetector가 보일 때 시작
      _initialized.value = true;
    } catch (e) {
      lo.g('몰입뷰 영상 초기화 실패($url): $e');
    }
  }

  String _formatHttpDate(DateTime date) {
    const weekDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final weekDay = weekDays[date.weekday - 1];
    final month = months[date.month - 1];
    return '$weekDay, ${date.day.toString().padLeft(2, '0')} $month ${date.year} '
        '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}:'
        '${date.second.toString().padLeft(2, '0')} GMT';
  }

  @override
  void dispose() {
    final ctrl = _controller;
    if (ctrl != null) {
      widget.onHiddenVideo(ctrl);
      ctrl.dispose();
    }
    _initialized.dispose();
    super.dispose();
  }

  void _onTap() {
    final v = _controller;
    if (v == null || !_initialized.value) return;
    v.value.isPlaying ? v.pause() : v.play();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _onTap,
      onDoubleTap: widget.onDoubleTap,
      child: Container(
        decoration: BoxDecoration(gradient: SaWeatherGradients.of(widget.gradientKey)),
        child: _isVideo ? _buildVideo() : _buildPhoto(),
      ),
    );
  }

  Widget _buildVideo() {
    return ValueListenableBuilder<bool>(
      valueListenable: _initialized,
      builder: (context, ready, _) {
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: ready
              ? VisibilityDetector(
                  key: ValueKey('sa_vis_${widget.item.boardId}'),
                  onVisibilityChanged: (info) {
                    final ctrl = _controller;
                    if (ctrl == null || !mounted) return;
                    if (info.visibleFraction > 0.1) {
                      ctrl.play();
                      widget.onVisibleVideo(ctrl);
                    } else if (info.visibleFraction < 0.3) {
                      ctrl.pause();
                      ctrl.seekTo(Duration.zero);
                      widget.onHiddenVideo(ctrl);
                    }
                  },
                  child: SizedBox.expand(
                    child: FittedBox(
                      fit: BoxFit.cover,
                      clipBehavior: Clip.hardEdge,
                      child: SizedBox(
                        width: _controller!.value.size.width,
                        height: _controller!.value.size.height,
                        child: VideoPlayer(_controller!),
                      ),
                    ),
                  ),
                )
              : _thumbnail(key: ValueKey('sa_thumb_${widget.item.boardId}')),
        );
      },
    );
  }

  // 멀티 이미지 현재 페이지(사진 게시물 가로 스와이프)
  int _photoIndex = 0;

  Widget _buildPhoto() {
    final item = widget.item;
    final List<String> imgs = (item.imageUrls?.isNotEmpty ?? false)
        ? item.imageUrls!
        : [if ((item.thumbnailPath ?? '').isNotEmpty) item.thumbnailPath!];
    if (imgs.isEmpty) return const SizedBox.expand();
    if (imgs.length == 1) {
      return CachedNetworkImage(
        imageUrl: imgs.first,
        cacheKey: imgs.first,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
      );
    }
    // 멀티 이미지: 가로 PageView(세로 피드와 축이 달라 제스처 충돌 없음) + n/N 카운터 + 도트
    return Stack(
      fit: StackFit.expand,
      children: [
        PageView.builder(
          itemCount: imgs.length,
          onPageChanged: (i) => setState(() => _photoIndex = i),
          itemBuilder: (_, i) => CachedNetworkImage(
              imageUrl: imgs[i], cacheKey: imgs[i], fit: BoxFit.cover),
        ),
        Positioned(
          top: MediaQuery.of(context).viewPadding.top + 12,
          right: 14,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.45), borderRadius: BorderRadius.circular(999)),
            child: Text('${_photoIndex + 1}/${imgs.length}',
                style: SaText.mono(fontSize: 11, color: Colors.white)),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: MediaQuery.of(context).viewPadding.bottom + 96,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (int i = 0; i < imgs.length; i++)
                Container(
                  width: i == _photoIndex ? 16 : 6,
                  height: 6,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    color: i == _photoIndex ? Colors.white : Colors.white.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  // 영상 버퍼링 동안 정지 썸네일(jpg)을 즉시 표시 — 기본 피드와 동일한 체감 속도 확보
  Widget _thumbnail({required Key key}) {
    final item = widget.item;
    String img = item.thumbnailPath ?? '';
    // 애니메이션 gif 썸네일이면 정지 jpg로 변환(로딩 가볍게, 기본 피드와 동일)
    if (img.endsWith('thumbnail.gif')) img = img.replaceAll('thumbnail.gif', 'thumbnail.jpg');
    if (img.isEmpty && (item.videoPath ?? '').contains('/manifest/')) {
      img = item.videoPath!.replaceAll('/manifest/video.m3u8', '/thumbnails/thumbnail.jpg');
    }
    if (img.isEmpty) return SizedBox.expand(key: key);
    return SizedBox.expand(
      key: key,
      child: CachedNetworkImage(imageUrl: img, cacheKey: img, fit: BoxFit.cover),
    );
  }
}

/// "↑ 다음" 힌트 — 6px bob(2s) 애니메이션
class _SwipeHint extends StatefulWidget {
  @override
  State<_SwipeHint> createState() => _SwipeHintState();
}

class _SwipeHintState extends State<_SwipeHint> with SingleTickerProviderStateMixin {
  late final AnimationController _bob =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1000))..repeat(reverse: true);

  @override
  void dispose() {
    _bob.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _bob,
      builder: (context, child) => Transform.translate(
        offset: Offset(0, -6 * Curves.easeInOut.transform(_bob.value)),
        child: child,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const PhosphorIcon(PhosphorIconsBold.arrowUp, size: 12, color: Colors.white70),
          const SizedBox(width: 4),
          Text('다음', style: SaText.mono(fontSize: 10, color: Colors.white70)),
        ],
      ),
    );
  }
}
