//import 'package:cached_video_player_plus/cached_video_player_plus.dart';

import 'dart:io';
import 'dart:math';
import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:gap/gap.dart';
import 'package:get/get.dart';
import 'package:giffy_dialog/giffy_dialog.dart';
import 'package:hashtagable_v3/hashtagable.dart';
import 'package:like_button/like_button.dart';
import 'package:project1/app/auth/cntr/auth_cntr.dart';

import 'package:project1/app/videocomment/comment_page.dart';
import 'package:project1/app/videolist/video_sigo_page.dart';
import 'package:project1/app/videomylist/video_manger_page.dart';
import 'package:project1/app/videomylist/cntr/video_myinfo_list_cntr.dart';
import 'package:project1/repo/board/board_repo.dart';
import 'package:project1/repo/board/data/board_weather_list_data.dart';
import 'package:project1/repo/common/res_data.dart';
import 'package:project1/app/weathergogo/services/weather_data_processor.dart';
import 'package:project1/utils/StringUtils.dart';
import 'package:project1/utils/log_utils.dart';
import 'package:project1/utils/utils.dart';
import 'package:project1/widget/custom_button.dart';
import 'package:text_scroll/text_scroll.dart';

import 'package:video_player/video_player.dart';
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

  double bottomHeight = Platform.isIOS ? 22.0 : 10.0;

  bool isUpdateCount = true;
  final ValueNotifier<String> timeDesc = ValueNotifier<String>('0ms');

  bool initPlay = false;
  int loadingImageIndex = 0;

  @override
  void initState() {
    super.initState();

    initiliazeVideo();
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

  final TransformationController _transformationController = TransformationController();
  @override
  void dispose() {
    initialized = false;
    _controller.removeListener(() {});
    _controller.setVolume(0);
    _controller.pause();
    _controller.dispose();
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
                GestureDetector(
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
                        ? const SizedBox.shrink() //buildLoading(ValueKey('${widget.data.boardId.toString()}loading'))
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
                            child: InteractiveViewer(
                              transformationController: _transformationController,
                              minScale: 1.0,
                              maxScale: 4.0,
                              child: SizedBox.expand(
                                child: VideoPlayer(_controller),
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
                // 중앙 play 버튼
                buildCenterPlayButton(),
                // 사운드 on/off 버튼
                buildSoundButton(),
                // 하단 컨텐츠
                buildBottomContent(),
                // 오른쪽 메뉴바
                buildRightMenuBar(),

                // 재생 progressbar
                buildPlayProgress(),
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
                          '${initialized}',
                          style: const TextStyle(color: Colors.transparent, fontSize: 1),
                        )
                      ],
                    ),
                  ),
                )
              ],
            ),
          ),
          Get.find<AuthCntr>().custId.value == widget.data.custId.toString()
              ? Container(
                  height: 100,
                  color: Colors.black.withOpacity(0.5),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Gap(10),
                      widget.data.hideYn == 'Y'
                          ? const Row(
                              children: [
                                Icon(Icons.lock, color: Colors.red, size: 20),
                                Text(
                                  '숨기기 게시물',
                                  style: TextStyle(color: Colors.red, fontSize: 15),
                                ),
                              ],
                            )
                          : const Text(
                              '게시물 관리',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                              ),
                            ),
                      const Spacer(),
                      SizedBox(
                        width: 80,
                        child: CustomButton(
                          text: ' 게시물수정 ',
                          type: 'XS',
                          isEnable: true,
                          onPressed: () async {
                            Map<String, dynamic>? returnMap = await VideoManagePageSheet().open(context, widget.data.boardId.toString(),
                                widget.data.hideYn.toString(), widget.data.anonyYn.toString(), widget.data.contents.toString());
                            if (returnMap == null) {
                              return;
                            }
                            if (returnMap['isDelete'] == 'Y') {
                              Get.back();
                              return;
                            }
                            widget.data.contents = returnMap['contents'];
                            widget.data.hideYn = returnMap['hideYn'];

                            setState(() {});
                          },
                        ),
                      )
                    ],
                  ),
                )
              : const SizedBox.shrink(),
        ],
      ),
    );
  }

  void changeContents(String contents) {
    widget.data.contents = contents;
    setState(() {});
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

  // 하단 컨텐츠
  Widget buildBottomContent() {
    String profilePath = widget.data.profilePath ?? '';

    String locationNm = widget.data.location.toString();

    return Positioned(
      bottom: bottomHeight,
      left: 10,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Gap(5),
          Row(
            children: [
              Text(
                '${widget.data.crtDtm.toString().split(':')[0].replaceAll('-', '/')}:${widget.data.crtDtm.toString().split(':')[1]}',
                style: const TextStyle(fontSize: 13, color: Colors.white, fontWeight: FontWeight.w600),
              ),
              const SizedBox(width: 20, height: 13, child: VerticalDivider(thickness: 1, color: Colors.white)),
              SizedBox(
                  height: 30,
                  width: 30,
                  child: WeatherDataProcessor.instance.getWeatherGogoImage(widget.data!.sky.toString(), widget.data!.rain.toString())
                  // child: Lottie.asset(
                  //   WeatherDataProcessor.instance.getWeatherGogoImage(widget.data!.sky.toString(), widget.data!.rain.toString()),
                  //   height: 138.0,
                  //   width: 138.0,
                  // ),
                  ),
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.35,
                child: TextScroll(
                  '${widget.data.weatherInfo?.split('.')[0]} ${widget.data.currentTemp}°',
                  mode: TextScrollMode.endless,
                  numberOfReps: 20000,
                  fadedBorder: true,
                  delayBefore: const Duration(milliseconds: 4000),
                  pauseBetween: const Duration(milliseconds: 2000),
                  velocity: const Velocity(pixelsPerSecond: Offset(100, 0)),
                  style: const TextStyle(fontSize: 15, color: Colors.white, fontWeight: FontWeight.w700),
                  textAlign: TextAlign.right,
                  selectable: true,
                ),
              ),
            ],
          ),
          Row(
            children: [
              const Icon(Icons.location_on, color: Colors.white, size: 15),
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.75,
                child: TextScroll(
                  '${locationNm.toString()} ${widget.data.distance?.toStringAsFixed(1)}km ',
                  mode: TextScrollMode.endless,
                  numberOfReps: 20000,
                  fadedBorder: true,
                  delayBefore: const Duration(milliseconds: 4000),
                  pauseBetween: const Duration(milliseconds: 2000),
                  velocity: const Velocity(pixelsPerSecond: Offset(100, 0)),
                  style: const TextStyle(fontSize: 15, color: Colors.white, fontWeight: FontWeight.w700),
                  textAlign: TextAlign.right,
                  selectable: true,
                ),
              ),
            ],
          ),
          const Gap(5),
          widget.data.contents != ""
              ? Padding(
                  padding: const EdgeInsets.only(right: 40),
                  child: HashTagText(
                    text: "${widget.data.contents}",
                    basicStyle: const TextStyle(fontSize: 14, color: Colors.white, fontWeight: FontWeight.w700),
                    decoratedStyle: const TextStyle(fontSize: 17, color: Color.fromARGB(255, 218, 245, 253), fontWeight: FontWeight.bold),
                    textAlign: TextAlign.left,
                    onTap: (text) {
                      print(text);
                    },
                  ),
                )
              : const SizedBox(),
          const Gap(15),
          buildProfile()
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
  Widget buildRightMenuBar() {
    return Positioned(
      bottom: bottomHeight,
      right: 0,
      child: Column(
        children: [
          kDebugMode
              ? ValueListenableBuilder<String>(
                  valueListenable: timeDesc,
                  builder: (context, value, child) {
                    return Text('1: $value', style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w600));
                  },
                )
              : const SizedBox.shrink(),
          IgnorePointer(
            ignoring: widget.data.custId.toString() == AuthCntr.to.custId.value.toString() ? true : false,
            child: LikeButton(
              size: 27,
              circleColor: const CircleColor(start: Color(0xff00ddff), end: Color(0xff0099cc)),
              bubblesColor: const BubblesColor(
                dotPrimaryColor: Color(0xff33b5e5),
                dotSecondaryColor: Color(0xff0099cc),
              ),
              isLiked: widget.data.likeYn.toString().contains('Y') ? true : false,
              likeBuilder: (bool isLiked) {
                return Icon(
                  isLiked ? Icons.favorite : Icons.favorite_border,
                  color: isLiked ? Colors.redAccent : Colors.white,
                  size: 27,
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
              animationDuration: const Duration(milliseconds: 1500),
              likeCount: widget.data.likeCnt,
              likeCountPadding: const EdgeInsets.only(top: 5, right: 15, left: 15),
              countPostion: CountPostion.bottom,
              countBuilder: (int? count, bool isLiked, String text) {
                Color color = isLiked ? Colors.redAccent : Colors.white;
                Widget result;
                if (count == 0) {
                  result = Text(
                    "love",
                    style: TextStyle(color: color, fontSize: 12),
                  );
                } else {
                  result = SizedBox(
                    width: 30,
                    height: 18,
                    // color: Colors.red,
                    child: Text(
                      text,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                  );
                }
                return result;
              },
            ),
          ),
          const Gap(10),
          IconButton(
            icon: const Icon(Icons.message_outlined, color: Colors.white),
            onPressed: () => commentSheet(),
          ),
          Text(
            widget.data.replyCnt == null ? '0' : widget.data.replyCnt.toString(),
            style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w600),
          ),

          const Gap(10),
          IconButton(
            icon: const Icon(Icons.play_arrow_outlined, color: Colors.white),
            onPressed: () => null,
          ),
          Text(
            widget.data.viewCnt.toString(),
            style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w600),
          ),
          const Gap(5),
          // IconButton(
          //   icon: const Icon(Icons.send, color: Colors.white),
          //   onPressed: () {},
          // ),
          // const Gap(5),
          // IconButton(
          //   icon: const Icon(Icons.more_vert, color: Colors.white),
          //   onPressed: () => Get.toNamed('/MyinfoPage'),
          // ),
        ],
      ),
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

  // 재생 progressbar
  Widget buildPlayProgress() {
    return Positioned(
      bottom: 0,
      left: 1,
      right: 1,
      child: ValueListenableBuilder<double>(
          valueListenable: progress,
          builder: (context, value, child) {
            return Stack(
              children: [
                Container(height: 2, color: Colors.grey, width: MediaQuery.of(context).size.width),
                AnimatedContainer(
                  duration: Duration(milliseconds: value == 0.0 ? 200 : 1000),
                  height: 2,
                  width: (MediaQuery.of(context).size.width) * (value / 100),
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(4), color: Colors.red),
                ),
              ],
            );
          }),
      // child:
      //     VideoProgressIndicator(_controller, allowScrubbing: true),
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
