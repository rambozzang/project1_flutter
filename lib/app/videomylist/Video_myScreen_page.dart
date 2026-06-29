//import 'package:cached_video_player_plus/cached_video_player_plus.dart';

import 'dart:io';
import 'dart:math';
import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:get/get.dart';
import 'package:hashtagable_v3/hashtagable.dart';
import 'package:like_button/like_button.dart';
import 'package:project1/app/auth/cntr/auth_cntr.dart';

import 'package:project1/app/videocomment/comment_page.dart';
import 'package:project1/app/videolist/video_sigo_page.dart';
import 'package:project1/app/videomylist/video_manger_page.dart';
import 'package:project1/app/videomylist/cntr/video_myinfo_list_cntr.dart';
import 'package:project1/app/videolist/video_list_page.dart' show FastPageScrollPhysics;
import 'package:project1/repo/board/board_repo.dart';
import 'package:project1/repo/board/data/board_weather_list_data.dart';
import 'package:project1/repo/common/res_data.dart';
import 'package:project1/app/weathergogo/services/weather_data_processor.dart';
import 'package:project1/utils/StringUtils.dart';
import 'package:project1/utils/log_utils.dart';
import 'package:project1/utils/utils.dart';
import 'package:video_player/video_player.dart';

// import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';

class VideoMySreenPage extends StatefulWidget {
  const VideoMySreenPage({super.key, required this.data, required this.index});

  final BoardWeatherListData data;
  final int index;

  @override
  State<VideoMySreenPage> createState() => _VideoMySreenPageState();
}

class _VideoMySreenPageState extends State<VideoMySreenPage> {
  late VideoPlayerController _controller;
  bool initialized = false;

  final ValueNotifier<bool> soundOff = ValueNotifier<bool>(false);
  final ValueNotifier<bool> isPlay = ValueNotifier<bool>(true);
  final ValueNotifier<double> progress = ValueNotifier<double>(0.0);

  ValueNotifier<String> isFollowed = ValueNotifier<String>('N');

  // double progress = 0;
  Duration position = Duration.zero;

  /// 하단 컨텐츠/메뉴의 기준선.
  /// iOS 홈 인디케이터 영역이 크므로 카드를 더 위로 띄워 메뉴/프로그레스바와 겹치지 않게 한다.
  double get bottomHeight {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    return bottomPadding + (Platform.isIOS ? 76 : 44);
  }

  bool isUpdateCount = true;
  final ValueNotifier<String> timeDesc = ValueNotifier<String>('0ms');

  bool initPlay = false;
  int loadingImageIndex = 0;

  // 사진 게시물(typeDtCd='I' 또는 imageUrls 보유) — VideoPlayer를 만들지 않는다.
  bool get isPhotoPost => widget.data.typeDtCd == 'I' || (widget.data.imageUrls?.isNotEmpty ?? false);
  List<String> get _photoUrls {
    final urls = widget.data.imageUrls;
    if (urls != null && urls.isNotEmpty) return urls;
    // 백엔드가 아직 imageUrls 배열을 안 주면 thumbnailPath(첫 사진)라도 표시(폴백).
    final thumb = widget.data.thumbnailPath;
    if (thumb != null && thumb.isNotEmpty) return [thumb];
    return const [];
  }
  final PageController _photoController = PageController();
  final ValueNotifier<int> _photoIndex = ValueNotifier<int>(0);

  @override
  void initState() {
    super.initState();

    // 사진 게시물은 VideoPlayer를 초기화하지 않는다(null videoPath로 실패→재귀 방지).
    if (!isPhotoPost) {
      initiliazeVideo();
    }
    isFollowed.value = widget.data.followYn.toString();
    loadingImageIndex = Random().nextInt(6);
  }

  Future<void> initiliazeVideo() async {
    //  Ios : m3u8
    String finalUrl = widget.data.videoPath.toString();
    VideoFormat format = VideoFormat.hls;
    // 안드로이드인 경우 daah 사용
    if (Platform.isAndroid) {
      finalUrl = widget.data.videoPath.toString().replaceAll('.m3u8', '.mpd');
      format = VideoFormat.dash;
    }

    final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
    final lastModified = _formatHttpDate(sevenDaysAgo);

    try {
      Stopwatch stopwatch = Stopwatch()..start();
      lo.g(
          '@@@  VideoScreenPage init(${Get.find<VideoMyinfoListCntr>().currentIndex.value}) ${widget.index} : ${widget.data.boardId} : 1.Start ');

      _controller = VideoPlayerController.networkUrl(Uri.parse(finalUrl),
          httpHeaders: {
            'Connection': 'keep-alive',
            'Cache-Control': 'max-age=3600, stale-while-revalidate=86400',
            'Etg': widget.data.boardId.toString(),
            'Last-Modified': lastModified,
            'If-None-Match': widget.data.boardId.toString(),
            'If-Modified-Since': lastModified,
            'Vary': 'Accept-Encoding, User-Agent',
          },
          videoPlayerOptions: VideoPlayerOptions(
            mixWithOthers: true,
            allowBackgroundPlayback: false,
          ),
          formatHint: format)
        ..initialize().then((_) {
          if (mounted) {
            lo.g('VideoScreenPage initialization time: ${stopwatch.elapsedMilliseconds}ms');
            timeDesc.value = '${stopwatch.elapsedMilliseconds}ms';

            lo.g(
                '@@@  VideoScreenPage init(${Get.find<VideoMyinfoListCntr>().currentIndex.value}) ${widget.index} : ${widget.data.boardId} : 2.Mounted =>. ${stopwatch.elapsed}');
            setState(() {
              _controller.setLooping(true);
              _controller.pause();
              initialized = true;
            });
            //   Get.find<VideoListCntr>().onPageMounted(widget.data.boardId!);
          }
        });

      _controller.addListener(() {
        isPlay.value = _controller.value.isPlaying;
        int max = _controller.value.duration.inSeconds;
        position = _controller.value.position;
        progress.value = (position.inSeconds / max * 100).isNaN ? 0 : position.inSeconds / max * 100;
        if (isPlay.value) {
          updateCount();
        }
        if (_controller.value.hasError) {
          lo.g('Video error: ${_controller.value.errorDescription}');
          // 4. 재시도 로직
          // _retryInitialization();
        }
      });
    } catch (e) {
      lo.g('initiliazeMyVideo error : ${e.toString()}');
      Utils.alert('영상 초기화 실패! ${e.toString()}');
      initiliazeVideo();
    } finally {}
  }

  String _formatHttpDate(DateTime date) {
    final weekDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final weekDay = weekDays[date.weekday - 1];
    final month = months[date.month - 1];
    return '$weekDay, ${date.day.toString().padLeft(2, '0')} $month ${date.year} '
        '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}:'
        '${date.second.toString().padLeft(2, '0')} GMT';
  }

  void updateCount() async {
    if (isUpdateCount) return;
    BoardRepo boardRepo = BoardRepo();
    await boardRepo.updateBoardCount(widget.data.boardId.toString());
    isUpdateCount = true;
  }

  Future<void> like() async {
    try {
      BoardRepo boardRepo = BoardRepo();
      ResData resData = await boardRepo.like(widget.data.boardId.toString(), widget.data.custId.toString(), "Y");
      if (resData.code != '00') {
        Utils.alert(resData.msg.toString());
        return;
      }

      // 현재 리스트에 좋아요 카운트 증가
      Get.find<VideoMyinfoListCntr>().list[Get.find<VideoMyinfoListCntr>().currentIndex.value].likeCnt =
          (Get.find<VideoMyinfoListCntr>().list[Get.find<VideoMyinfoListCntr>().currentIndex.value].likeCnt! + 1);
      // 현재 리스트에 좋아요 여부 변경
      Get.find<VideoMyinfoListCntr>().list[Get.find<VideoMyinfoListCntr>().currentIndex.value].likeYn = 'Y';
    } catch (e) {
      Utils.alert('좋아요 실패! 다시 시도해주세요');
    }
  }

  Future<void> likeCancle() async {
    try {
      BoardRepo boardRepo = BoardRepo();
      ResData resData = await boardRepo.likeCancle(widget.data.boardId.toString());
      if (resData.code != '00') {
        Utils.alert(resData.msg.toString());
        return;
      }
      // 현재 리스트에 좋아요 카운트 감소
      Get.find<VideoMyinfoListCntr>().list[Get.find<VideoMyinfoListCntr>().currentIndex.value].likeCnt =
          (Get.find<VideoMyinfoListCntr>().list[Get.find<VideoMyinfoListCntr>().currentIndex.value].likeCnt! - 1);
      // 현재 리스트에 좋아요 여부 변경
      Get.find<VideoMyinfoListCntr>().list[Get.find<VideoMyinfoListCntr>().currentIndex.value].likeYn = 'N';
    } catch (e) {
      Utils.alert('좋아요 실패! 다시 시도해주세요');
    }
  }

  // 로딩 중 썸네일 표시 (VideoScreenPage와 동일한 방식)
  Widget _buildThumbnail(Key key) {
    String imgPath = widget.data.videoPath!.replaceAll('/manifest/video.m3u8', '/thumbnails/thumbnail.jpg');
    return Container(
      key: key,
      decoration: BoxDecoration(
        image: DecorationImage(
          image: CachedNetworkImageProvider(imgPath, cacheKey: imgPath),
          fit: BoxFit.fill,
        ),
      ),
    );
  }

  final TransformationController _transformationController = TransformationController();
  @override
  void dispose() {
    initialized = false;
    _photoController.dispose();
    _photoIndex.dispose();
    // 사진 게시물은 _controller(late)를 초기화하지 않았으므로 접근 금지.
    if (!isPhotoPost) {
      _controller.removeListener(() {});
      _controller.setVolume(0);
      _controller.pause();
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      resizeToAvoidBottomInset: false,
      extendBodyBehindAppBar: true,
      extendBody: true,
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                isPhotoPost
                    ? Positioned.fill(child: _buildPhotoCarousel())
                    : GestureDetector(
                  onTap: () {
                    initPlay = true;
                    if (_controller.value.isPlaying) {
                      _controller.pause();
                    } else {
                      _controller.play();
                    }
                  },
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    switchInCurve: Curves.fastOutSlowIn,
                    switchOutCurve: Curves.fastLinearToSlowEaseIn,
                    transitionBuilder: (Widget child, Animation<double> animation) {
                      return FadeTransition(
                        opacity: animation,
                        child: child,
                      );
                    },
                    child: initialized == false
                        ? _buildThumbnail(ValueKey('${widget.data.boardId.toString()}loading'))
                        : VisibilityDetector(
                            onVisibilityChanged: (info) {
                              initPlay = false;
                              if (info.visibleFraction > 0.1) {
                                if (initialized) {
                                  _controller.play();
                                  Get.find<VideoMyinfoListCntr>().soundOff.value ? _controller.setVolume(0) : _controller.setVolume(1);
                                }
                              } else if (info.visibleFraction < 0.3) {
                                if (initialized) {
                                  _controller.pause();
                                  _controller.seekTo(Duration.zero);
                                  Get.find<VideoMyinfoListCntr>().soundOff.value ? _controller.setVolume(0) : _controller.setVolume(1);
                                }
                              }
                            },
                            key: ValueKey('${widget.data.boardId.toString()}videoScreen'),
                            child: SizedBox.expand(
                              // 왜곡 없이 화면 채우고 상·하 균등 크롭 (하단 짤림 방지)
                              child: FittedBox(
                                fit: BoxFit.cover,
                                clipBehavior: Clip.hardEdge,
                                child: SizedBox(
                                  width: _controller.value.size.width,
                                  height: _controller.value.size.height,
                                  child: VideoPlayer(_controller),
                                ),
                              ),
                            ),
                            // child: SizedBox.expand(
                            //   child: FittedBox(
                            //     fit: BoxFit.cover,
                            //     child: SizedBox(
                            //       width: _controller.value.size.width,
                            //       height: _controller.value.size.height,
                            //       child: VideoPlayer(_controller),
                            //     ),
                            //   ),
                            // ),
                          ),
                  ),
                ),
                // // 오른쪽 상단 close 버튼
                // buildCloseButton(),
                // 중앙 play 버튼 (영상 전용)
                if (!isPhotoPost) buildCenterPlayButton(),
                // 사운드 on/off 버튼 (영상 전용)
                if (!isPhotoPost) buildSoundButton(),
                // 하단 컨텐츠
                buildBottomContent(),
                // 오른쪽 메뉴바
                buildRightMenuBar(),
                // 본인 게시물 관리
                buildOwnerActions(),

                // 재생 progressbar (영상 전용)
                if (!isPhotoPost) buildPlayProgress(),
                Positioned(
                  top: (MediaQuery.of(context).size.height - 60) * .5,
                  right: 14,
                  child: GestureDetector(
                    onTap: () => SigoPageSheet().open(
                        context, widget.data.boardId.toString(), Get.find<VideoMyinfoListCntr>().list[widget.index].custId.toString(),
                        callBackFunction: Get.find<VideoMyinfoListCntr>().getSingAfterGetData),
                    child: Column(
                      children: [
                        const Icon(Icons.warning, color: Colors.white),
                        const Text(
                          '신고',
                          style: TextStyle(color: Colors.white, fontSize: 9),
                        ),
                        Text(
                          '$initialized',
                          style: const TextStyle(color: Colors.transparent, fontSize: 1),
                        )
                      ],
                    ),
                  ),
                )
              ],
            ),
          ),
          // 본인 게시물 관리 UI는 상단 buildOwnerActions()로 이동
        ],
      ),
    );
  }

  void changeContents(String contents) {
    widget.data.contents = contents;
    setState(() {});
  }

  // 사진 게시물 가로 캐러셀(세로 피드와 직교 → 제스처 충돌 없음)
  Widget _buildPhotoCarousel() {
    final List<String> imgs = _photoUrls;
    if (imgs.isEmpty) return Container(color: Colors.black);
    return PageView.builder(
      controller: _photoController,
      physics: const FastPageScrollPhysics(), // 더 민감·빠른 좌우 스와이프
      itemCount: imgs.length,
      onPageChanged: (i) => _photoIndex.value = i,
      itemBuilder: (context, i) {
        return CachedNetworkImage(
          imageUrl: imgs[i],
          cacheKey: imgs[i],
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          placeholder: (_, __) => Container(color: Colors.black),
          errorWidget: (_, __, ___) => Container(
            color: Colors.black,
            child: const Center(child: Icon(Icons.broken_image, color: Colors.white24, size: 48)),
          ),
        );
      },
    );
  }

  // 사진 점 인디케이터 — 하단 컨텐츠(위치정보) 위에 표시(여러 장일 때만)
  Widget _buildPhotoDots() {
    final List<String> imgs = _photoUrls;
    if (!isPhotoPost || imgs.length <= 1) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 2),
      child: ValueListenableBuilder<int>(
        valueListenable: _photoIndex,
        builder: (context, cur, _) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.38),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(imgs.length, (i) {
                final bool active = i == cur;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: active ? 7 : 6,
                  height: active ? 7 : 6,
                  decoration: BoxDecoration(
                    color: active ? Colors.white : Colors.white.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                );
              }),
            ),
          );
        },
      ),
    );
  }

  Widget buildLoading(Key key) {
    // String imgPath = widget.data.videoPath?.replaceAll('/manifest/video.m3u8', '/thumbnails/thumbnail.jpg') ?? '';
    // Uri? imgUri = Uri.tryParse(imgPath);
    // ImageProvider imageProvider;
    // if (imgUri == null || !imgUri.hasScheme || !imgUri.hasAuthority) {
    //   // 유효하지 않은 URI일 경우, 기본 이미지 사용
    //   imageProvider = const AssetImage('assets/images/default_thumbnail.jpg');
    // } else {
    //   imageProvider = CachedNetworkImageProvider(imgPath, cacheKey: widget.data.boardId.toString());
    // }

    return ClipRect(
      key: key,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 25.0, sigmaY: 25.0),
        child: Container(
          // decoration: BoxDecoration(
          //   image: DecorationImage(
          //     image: imageProvider,
          //     fit: BoxFit.cover,
          //   ),
          // ),
          child: Container(
            color: Colors.black.withOpacity(0.1),
          ),
        ),
      ),
    );
  }

  Widget buildCloseButton() {
    return Positioned(
      top: 40,
      right: 10,
      child: IconButton(
        icon: const Icon(Icons.close, color: Colors.white),
        iconSize: 30,
        onPressed: () {
          Get.back();
        },
      ),
    );
  }

  // 본인 게시물 관리 버튼 (상단 우측, close 버튼 왼쪽)
  Widget buildOwnerActions() {
    if (Get.find<AuthCntr>().custId.value != widget.data.custId.toString()) {
      return const SizedBox.shrink();
    }
    return Positioned(
      top: 40,
      right: 56,
      child: IconButton(
        icon: widget.data.hideYn == 'Y'
            ? const Icon(Icons.lock_outline, color: Colors.redAccent, size: 24)
            : const Icon(Icons.more_horiz, color: Colors.white, size: 26),
        onPressed: () async {
          final returnMap = await VideoManagePageSheet().open(
            context,
            widget.data.boardId.toString(),
            widget.data.hideYn.toString(),
            widget.data.anonyYn.toString(),
            widget.data.contents.toString(),
          );
          if (returnMap == null) return;
          if (returnMap['isDelete'] == 'Y') {
            Get.back();
            return;
          }
          widget.data.contents = returnMap['contents'];
          widget.data.hideYn = returnMap['hideYn'];
          setState(() {});
        },
      ),
    );
  }


  // 하단 컨텐츠
  Widget buildBottomContent() {

    final weatherText = '${widget.data.weatherInfo?.split('.').firstOrNull ?? ''} ${widget.data.currentTemp ?? '-'}°';
    final locationText = '${widget.data.location} ${widget.data.distance?.toStringAsFixed(1) ?? '0.0'}km';
    final createdAt = widget.data.crtDtm.toString();
    final timeLabel = createdAt.length >= 16
        ? '${createdAt.substring(0, 10).replaceAll('-', '/')} ${createdAt.substring(11, 16)}'
        : createdAt;

    return Positioned(
      bottom: bottomHeight,
      left: 14,
      right: 86, // 오른쪽 메뉴 공간 확보
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildPhotoDots(),
          const Gap(8),
          // 시간 / 날씨 한 줄
          Row(
            children: [
              Text(timeLabel, style: const TextStyle(fontSize: 12, color: Colors.white70, fontWeight: FontWeight.w600)),
              const SizedBox(width: 8, height: 12, child: VerticalDivider(thickness: 1, color: Colors.white54)),
              SizedBox(width: 24, height: 24, child: WeatherDataProcessor.instance.getWeatherGogoImage(
                  widget.data.sky.toString(), widget.data.rain.toString())),
              const Gap(6),
              Flexible(
                child: Text(weatherText,
                    style: const TextStyle(fontSize: 14, color: Colors.white, fontWeight: FontWeight.w700),
                    overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
          const Gap(4),
          // 위치
          Row(
            children: [
              const Icon(Icons.location_on, color: Colors.white70, size: 14),
              const Gap(4),
              Flexible(
                child: Text(locationText,
                    style: const TextStyle(fontSize: 14, color: Colors.white, fontWeight: FontWeight.w700),
                    overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
          const Gap(6),
          // 본문
          if (widget.data.contents?.isNotEmpty == true)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: HashTagText(
                text: widget.data.contents!,
                basicStyle: const TextStyle(fontSize: 14, color: Colors.white, fontWeight: FontWeight.w600),
                decoratedStyle: const TextStyle(fontSize: 14, color: Color.fromARGB(255, 218, 245, 253), fontWeight: FontWeight.bold),
                textAlign: TextAlign.left,
                onTap: (text) => lo.g('hashTag tap: $text'),
              ),
            ),
          const Gap(12),
          buildProfile(),
        ],
      ),
    );
  }

  Widget buildProfile() {
    // anonyYn 이면
    if (widget.data.anonyYn == "Y") {
      return Utils.buildRanDomProfile(widget.data.custId ?? '', 35, 16, Colors.white);
    }
    return Row(
      children: [
        GestureDetector(
          onTap: () => Get.toNamed('/OtherInfoPage/${widget.data.custId.toString()}'),
          child: !StringUtils.isEmpty(widget.data.profilePath)
              ? Container(
                  width: 35.0,
                  height: 35.0,
                  decoration: BoxDecoration(
                    color: const Color(0xff7c94b6),
                    image: DecorationImage(
                      image: CachedNetworkImageProvider(cacheKey: widget.data.profilePath.toString(), widget.data.profilePath.toString()),
                      fit: BoxFit.cover,
                    ),
                    borderRadius: const BorderRadius.all(Radius.circular(50.0)),
                    border: Border.all(
                      color: Colors.green,
                      width: 2.0,
                    ),
                  ),
                )
              : Container(
                  height: 35,
                  width: 35,
                  decoration: BoxDecoration(
                    color: Colors.green,
                    // color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Center(
                    child: Text(
                      (widget.data.nickNm == null || widget.data.nickNm == '') ? 'S' : widget.data.nickNm!.substring(0, 1),
                      style: const TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
        ),
        const Gap(10),
        GestureDetector(
          onTap: () => Get.toNamed('/OtherInfoPage/${widget.data.custId.toString()}'),
          child: Text(
            widget.data.nickNm.toString(),
            style: const TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        const Gap(15),
        widget.data.custId.toString() == AuthCntr.to.custId.value.toString()
            ? const SizedBox.shrink()
            : GetBuilder<VideoMyinfoListCntr>(
                builder: (_) {
                  return ElevatedButton(
                    onPressed: () {
                      if (widget.data.followYn.toString() == 'N') {
                        widget.data.followYn = 'Y';
                        Get.find<VideoMyinfoListCntr>().follow(widget.data.custId.toString());
                      } else {
                        widget.data.followYn = 'N';
                        Get.find<VideoMyinfoListCntr>().followCancle(widget.data.custId.toString());
                      }
                      setState(() {});
                    },
                    clipBehavior: Clip.none,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
                      elevation: 0.5,
                      minimumSize: const Size(0, 0),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      backgroundColor: widget.data.followYn.toString() == 'N' ? Colors.transparent : Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.0), side: const BorderSide(color: Colors.white, width: 0.7)),
                    ),
                    child: Text(
                      widget.data.followYn.toString() == 'N' ? '팔로우' : '팔로잉',
                      style: TextStyle(
                        color: widget.data.followYn.toString().contains('N') ? Colors.white : Colors.black,
                        fontSize: 15,
                      ),
                    ),
                  );
                },
              ),
      ],
    );
  }

  // 오른쪽 메뉴바
  // 오른쪽 메뉴 — 좋아요/댓글/조회수 세로 정렬.
  Widget buildRightMenuBar() {
    return Positioned(
      bottom: bottomHeight,
      right: 10,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          IgnorePointer(
            ignoring: widget.data.custId.toString() == AuthCntr.to.custId.value.toString(),
            child: LikeButton(
              size: 28,
              circleColor: const CircleColor(start: Color(0xff00ddff), end: Color(0xff0099cc)),
              bubblesColor: const BubblesColor(
                dotPrimaryColor: Color(0xff33b5e5),
                dotSecondaryColor: Color(0xff0099cc),
              ),
              isLiked: widget.data.likeYn.toString().contains('Y'),
              likeBuilder: (bool isLiked) {
                return Icon(
                  isLiked ? Icons.favorite : Icons.favorite_border,
                  color: isLiked ? Colors.redAccent : Colors.white,
                  size: 28,
                );
              },
              onTap: (isLiked) {
                if (isLiked) {
                  likeCancle();
                } else {
                  like();
                }
                return Future.value(!isLiked);
              },
              animationDuration: const Duration(milliseconds: 1200),
              likeCount: widget.data.likeCnt ?? 0,
              likeCountPadding: const EdgeInsets.only(top: 4),
              countPostion: CountPostion.bottom,
              countBuilder: (int? count, bool isLiked, String text) {
                return Text('${count ?? 0}',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: isLiked ? Colors.redAccent : Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600));
              },
            ),
          ),
          const Gap(14),
          _menuItem(Icons.message_outlined, widget.data.replyCnt ?? 0),
          const Gap(14),
          _menuItem(Icons.visibility_outlined, widget.data.viewCnt ?? 0),
        ],
      ),
    );
  }

  Widget _menuItem(IconData icon, int count) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white, size: 26),
        const Gap(2),
        Text(
          count.toString(),
          style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  // 중앙 play 버튼
  Widget buildCenterPlayButton() {
    return Center(
      // child: _controller.value.isPlaying ? const SizedBox() : const Icon(Icons.play_arrow, color: Colors.white, size: 50),
      child: ValueListenableBuilder<bool>(
        valueListenable: isPlay,
        builder: (context, value, child) {
          if (initPlay == false) return const SizedBox.shrink();
          return AnimatedOpacity(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeIn,
            opacity: value ? 0.0 : 1.0,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              child: value
                  ? IconButton(
                      onPressed: () => _controller.pause(),
                      icon: Icon(Icons.play_arrow_outlined, color: Colors.white.withOpacity(0.5), size: 40))
                  : IconButton(
                      onPressed: () => _controller.play(), icon: Icon(Icons.pause, color: Colors.white.withOpacity(0.5), size: 40)),
            ),
          );
        },
      ),
    );
  }

  // 재생 progressbar — 화면 최하단에 고정, 높이 3px.
  Widget buildPlayProgress() {
    final safeBottom = MediaQuery.of(context).padding.bottom;
    return Positioned(
      bottom: safeBottom,
      left: 0,
      right: 0,
      child: ValueListenableBuilder<double>(
        valueListenable: progress,
        builder: (context, value, child) {
          return SizedBox(
            height: 3,
            child: Stack(
              children: [
                Container(color: Colors.white.withOpacity(0.2)),
                AnimatedContainer(
                  duration: Duration(milliseconds: value == 0.0 ? 200 : 1000),
                  width: MediaQuery.of(context).size.width * (value / 100),
                  decoration: const BoxDecoration(color: Colors.redAccent),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void commentSheet() {
    final aa = CommentPage().open(context, widget.data.boardId.toString());
    lo.g('@@@  CommentPage().open(context, widget.data.boardId.toString()) : $aa');
  }

  // 사운드 on/off 버튼
  Widget buildSoundButton() {
    return Positioned(
      top: (MediaQuery.of(context).size.height - 60) * .5,
      left: 2,
      child: Obx(() => IconButton(
            onPressed: () {
              Get.find<VideoMyinfoListCntr>().soundOff.value = !Get.find<VideoMyinfoListCntr>().soundOff.value;
              if (Get.find<VideoMyinfoListCntr>().soundOff.value) {
                _controller.setVolume(0);
              } else {
                _controller.setVolume(1);
              }
            },
            icon: Get.find<VideoMyinfoListCntr>().soundOff.value
                ? const Icon(Icons.volume_off_outlined, color: Colors.white)
                : const Icon(Icons.volume_up_outlined, color: Colors.white),
          )),
    );
  }
}
