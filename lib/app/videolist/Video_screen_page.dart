//import 'package:cached_video_player_plus/cached_video_player_plus.dart';

import 'dart:io';
import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:gap/gap.dart';
import 'package:get/get.dart';
import 'package:giffy_dialog/giffy_dialog.dart';
import 'package:hashtagable_v3/hashtagable.dart';
import 'package:like_button/like_button.dart';
import 'package:project1/app/auth/cntr/auth_cntr.dart';

import 'package:project1/app/videolist/cntr/video_list_cntr.dart';
import 'package:project1/app/videocomment/comment_page.dart';
import 'package:project1/app/videolist/video_sigo_page.dart';
import 'package:project1/repo/board/board_repo.dart';
import 'package:project1/repo/board/data/board_weather_list_data.dart';
import 'package:project1/repo/common/res_data.dart';
import 'package:project1/app/weathergogo/services/weather_data_processor.dart';
import 'package:project1/utils/anony_profile.dart';
import 'package:project1/utils/log_utils.dart';
import 'package:project1/utils/utils.dart';
import 'package:share_plus/share_plus.dart';
import 'package:text_scroll/text_scroll.dart';

import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';

class VideoScreenPage extends StatefulWidget {
  const VideoScreenPage({super.key, required this.index, required this.data});

  final BoardWeatherListData data;
  final int index;

  @override
  State<VideoScreenPage> createState() => VideoScreenPageState();
}

class VideoScreenPageState extends State<VideoScreenPage> {
  late VideoPlayerController _controller;

  final TransformationController transformationController = TransformationController();
  final double scale = 1.0;
  final double previousScale = 1.0;

  bool initPlay = false;

  final ValueNotifier<bool> soundOff = ValueNotifier<bool>(false);
  final ValueNotifier<bool> isPlay = ValueNotifier<bool>(true);
  final ValueNotifier<double> progress = ValueNotifier<double>(0.0);
  final ValueNotifier<String> timeDesc = ValueNotifier<String>('0ms');

  ValueNotifier<String> isFollowed = ValueNotifier<String>('N');
  ValueNotifier<bool> initialized = ValueNotifier<bool>(false);

  // double progress = 0;
  Duration position = Duration.zero;

  double bottomHeight = Platform.isIOS ? 92.0 : 80.0;

  // 운영계에서 false 로 변경
  bool isUpdateCount = false;

  @override
  void initState() {
    super.initState();
    initiliazeVideo();
    // initialized.value = false;

    isFollowed.value = widget.data.followYn.toString();
  }

  Future<void> initiliazeVideo() async {
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
          videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true, allowBackgroundPlayback: false),
          formatHint: format)
        ..initialize().then((_) {
          if (mounted) {
            timeDesc.value = '${stopwatch.elapsedMilliseconds}ms';
            setState(() {
              _controller.setLooping(true);
              _controller.pause();
            });
            initialized.value = true;
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
      });
    } catch (e) {
      lo.g('@@@  VideoScreenPage init() ${widget.index} : ${widget.data.boardId} : error : $e');
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

  // 조회수 증가
  Future<void> updateCount() async {
    if (isUpdateCount) return;

    isUpdateCount = true;
    BoardRepo boardRepo = BoardRepo();
    try {
      await boardRepo.updateBoardCount(widget.data.boardId.toString());
    } catch (e) {
      lo.g('@@@ VideoScreenPage  updateCount error : $e');
    }
  }

  Future<void> like() async {
    try {
      BoardRepo boardRepo = BoardRepo();
      ResData resData = await boardRepo.like(widget.data.boardId.toString(), widget.data.custId.toString(), "Y");
      if (resData.code != '00') {
        Utils.alert(resData.msg.toString());
        return;
      }

      int inx = Get.find<VideoListCntr>().currentIndex.value;
      // 현재 리스트에 좋아요 카운트 증가
      Get.find<VideoListCntr>().list[inx].likeCnt = (Get.find<VideoListCntr>().list[inx].likeCnt! + 1);
      // 현재 리스트에 좋아요 여부 변경
      Get.find<VideoListCntr>().list[inx].likeYn = 'Y';
    } catch (e) {
      // Utils.alert('좋아요 실패! 다시 시도해주세요');
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
      int inx = Get.find<VideoListCntr>().currentIndex.value;
      Get.find<VideoListCntr>().list[inx].likeCnt = (Get.find<VideoListCntr>().list[inx].likeCnt! - 1);
      // 현재 리스트에 좋아요 여부 변경
      Get.find<VideoListCntr>().list[inx].likeYn = 'N';
    } catch (e) {
      Utils.alert('좋아요 실패! 다시 시도해주세요');
    }
  }

  Future<void> share() async {
    final result = await Share.share('check out my website https://example.com');

    if (result.status == ShareResultStatus.success) {
      print('Thank you for sharing my website!');
    }
  }

  @override
  void dispose() {
    initialized.value = false;
    initialized.dispose();
    _controller.removeListener(() {});
    _controller.pause();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      // backgroundColor: const Color(0xFF262B49),
      resizeToAvoidBottomInset: false,
      extendBodyBehindAppBar: true,
      extendBody: true,
      body: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: () {
                initPlay = true;
                if (_controller.value.isPlaying) {
                  _controller.pause();
                } else {
                  _controller.play();
                }
              },
              onHorizontalDragEnd: (DragEndDetails details) {
                if (details.primaryVelocity! < 0) {
                  Get.toNamed('/OtherInfoPage/${widget.data.custId.toString()}');
                } else if (details.primaryVelocity! > 0) {
                  // Get.toNamed('/OtherInfoPage/${widget.data.custId.toString()}');
                }
              },
              child: ValueListenableBuilder<bool>(
                valueListenable: initialized,
                builder: (builder, value, child) {
                  return AnimatedSwitcher(
                      key: ValueKey('${widget.data.boardId.toString()}AnimatedSwitcher'),
                      duration: const Duration(milliseconds: 250),
                      switchInCurve: Curves.easeInOut,
                      switchOutCurve: Curves.easeInOut,
                      transitionBuilder: (Widget child, Animation<double> animation) {
                        return FadeTransition(
                          key: ValueKey('${widget.data.boardId.toString()}FadeTransition'),
                          opacity: animation,
                          child: child,
                        );
                      },
                      child: value == false
                          ? const SizedBox.shrink() // buildLoading(ValueKey('${widget.data.boardId.toString()}loading'))
                          : buildVideoScreen(ValueKey('${widget.data.boardId.toString()}videoScreen'), value));
                },
              ),
            ),
          ),
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
          //
          buildSingo()
          // Center(
          //   child: Text(widget.data.boardId.toString(),
          //       style: const TextStyle(fontSize: 30, color: Colors.white, fontWeight: FontWeight.bold)),
          // )
        ],
      ),
    );
  }

  Widget buildVideoScreen(Key key, bool init) {
    return Container(
      key: key, // key를 상위 Container에 적용
      child: VisibilityDetector(
        key: key,
        onVisibilityChanged: (info) {
          initPlay = false;
          if (info.visibleFraction > 0.1) {
            if (init) {
              _controller.play();
              Get.find<VideoListCntr>().soundOff.value ? _controller.setVolume(0) : _controller.setVolume(1);
            }
          } else if (info.visibleFraction < 0.3) {
            // } else {
            if (init) {
              _controller.pause();
              _controller.seekTo(Duration.zero);
              Get.find<VideoListCntr>().soundOff.value ? _controller.setVolume(0) : _controller.setVolume(1);
            }
          }
        },
        child: Center(
          child: SizedBox.expand(
            child: InteractiveViewer(
                transformationController: transformationController,
                boundaryMargin: const EdgeInsets.all(0.0),
                minScale: 1.0,
                maxScale: 4.0,
                scaleEnabled: true,
                panEnabled: true,
                child: VideoPlayer(_controller)),
          ),
        ),
      ),
    );
  }

  Widget buildSingo() {
    return Positioned(
      bottom: (MediaQuery.of(context).size.height - 12) * .5,
      right: 12,
      child: GestureDetector(
        onTap: () => SigoPageSheet().open(
            context, widget.data.boardId.toString(), Get.find<VideoListCntr>().list[widget.index].custId.toString(),
            callBackFunction: Get.find<VideoListCntr>().getSingAfterGetData),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(Icons.warning, color: Colors.white),
            const Gap(5),
            Text(
              '신고',
              style: TextStyle(color: Colors.white, fontSize: 9),
            )
          ],
        ),
      ),
    );
  }

  Widget buildLoading(Key key) {
    String imgPath = widget.data.videoPath!.replaceAll('/manifest/video.m3u8', '/thumbnails/thumbnail.jpg');
    return Container(
      key: key, // key를 상위 Container에 적용
      decoration: BoxDecoration(
        image: DecorationImage(
          image: CachedNetworkImageProvider(
            imgPath,
            cacheKey: imgPath,
          ),
          fit: BoxFit.fill,
        ),
      ),
    );
  }

  Widget buildLoading21111111() {
    String imgPath = widget.data.videoPath!.replaceAll('/manifest/video.m3u8', '/thumbnails/thumbnail.jpg');
    return ClipRect(
      // ClipRect을 사용하여 블러 효과가 자식 위젯 영역을 벗어나지 않도록 합니다.
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 25.0, sigmaY: 25.0),
        child: Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: CachedNetworkImageProvider(
                imgPath,
                cacheKey: imgPath,
              ),
              fit: BoxFit.cover,
            ),
          ),
          child: Container(
            color: Colors.black.withOpacity(0.3), // 약간의 어두운 오버레이 추가
          ),
        ),
      ),
    );
  }

  // 하단 컨텐츠
  Widget buildBottomContent() {
    String locationNm = widget.data.location ?? "";
    // String locationNm =
    //     '${widget.data.location.toString().split(' ')[0]} ${widget.data.location.toString().split(' ')[1]} ${widget.data.location.toString().split(' ')[2]}';
    return Positioned(
      bottom: bottomHeight,
      left: 10,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Gap(5),
          GestureDetector(
            onTap: () => Get.toNamed('/MapPage', arguments: {'lat': double.parse(widget.data.lat!), 'lon': double.parse(widget.data.lon!)}),
            child: Container(
              height: 30,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: IntrinsicWidth(
                child: Row(
                  children: [
                    Container(
                        color: Colors.green, height: 17, width: 17, child: const Icon(Icons.location_on, color: Colors.white, size: 16)),
                    const SizedBox(
                      width: 5,
                    ),
                    SizedBox(
                      width: MediaQuery.of(context).size.width * 0.4,
                      child: TextScroll(
                        locationNm.toString(),
                        // '${locationNm.toString()}, ${widget.data.distance!.toStringAsFixed(1)}km',
                        mode: TextScrollMode.endless,
                        numberOfReps: 20000,
                        fadedBorder: true,
                        delayBefore: const Duration(milliseconds: 4000),
                        pauseBetween: const Duration(milliseconds: 2000),
                        velocity: const Velocity(pixelsPerSecond: Offset(100, 0)),
                        style: const TextStyle(fontSize: 14, color: Colors.white, fontWeight: FontWeight.w600),
                        textAlign: TextAlign.right,
                        selectable: false,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Row(
            children: [
              Text(
                '${widget.data.crtDtm.toString().split(':')[0].replaceAll('-', '/')}:${widget.data.crtDtm.toString().split(':')[1]}',
                style: const TextStyle(fontSize: 14, color: Colors.white, fontWeight: FontWeight.w600),
              ),
              const SizedBox(width: 18, height: 14, child: VerticalDivider(thickness: 1, color: Colors.white)),
              SizedBox(
                height: 30,
                width: 30,
                child: WeatherDataProcessor.instance.getWeatherGogoImage(widget.data!.sky.toString(), widget.data!.rain.toString()),
              ),
              const SizedBox(width: 2),
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
                  style: const TextStyle(fontSize: 14, color: Colors.white, fontWeight: FontWeight.w600),
                  textAlign: TextAlign.right,
                  selectable: true,
                ),
              ),
            ],
          ),
          // const Gap(5),
          widget.data.contents != ""
              ? Padding(
                  padding: const EdgeInsets.only(right: 40, bottom: 12, top: 5),
                  child: HashTagText(
                    text: "${widget.data.contents}",
                    basicStyle: const TextStyle(fontSize: 15, color: Colors.white, fontWeight: FontWeight.w700),
                    decoratedStyle: const TextStyle(
                        fontSize: 16,
                        color: Color.fromARGB(255, 218, 245, 253),
                        // color: Color.fromARGB(255, 205, 240, 122),
                        // color: Color.fromARGB(255, 189, 230, 220),
                        fontWeight: FontWeight.bold),
                    textAlign: TextAlign.left,
                    onTap: (text) {
                      print(text);
                    },
                  ),
                )
              : const SizedBox(
                  height: 5,
                ),
          // const Gap(15),
          _buildProfile(),
          const Gap(10)
        ],
      ),
    );
  }

  Widget _buildProfile() {
    // anonyYn 이면
    if (widget.data.anonyYn == "Y") {
      return Utils.buildRanDomProfile(widget.data.custId ?? '', 35, 16, Colors.white);
    }
    return Row(
      children: [
        GestureDetector(
          onTap: () => Get.toNamed('/OtherInfoPage/${widget.data.custId.toString()}'),
          child: widget.data.profilePath != ''
              ? Container(
                  height: 35,
                  width: 35,
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white, width: 0.5),
                    image: DecorationImage(
                      image: CachedNetworkImageProvider(cacheKey: widget.data.profilePath.toString(), widget.data.profilePath.toString()),
                      fit: BoxFit.cover,
                    ),
                  ),
                )
              : Container(
                  height: 35,
                  width: 35,
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(10),
                    //   border: Border.all(color: Colors.white, width: 0.5),
                  ),
                  child: Center(
                    child: Text(
                      widget.data.nickNm.toString().substring(0, 1),
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
            : GetBuilder<VideoListCntr>(
                init: VideoListCntr(),
                builder: (_) {
                  return ElevatedButton(
                    onPressed: () {
                      if (widget.data.followYn.toString() == 'N') {
                        widget.data.followYn = 'Y';
                        Get.find<VideoListCntr>().follow(widget.data.custId.toString());
                      } else {
                        widget.data.followYn = 'N';
                        Get.find<VideoListCntr>().followCancle(widget.data.custId.toString());
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
                      // backgroundColor: widget.data.followYn.toString().contains('N') ? Colors.black : Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.0), side: const BorderSide(color: Colors.white, width: 0.7)),
                    ),
                    child: Text(
                      widget.data.followYn.toString() == 'N' ? '팔로우' : '팔로잉',
                      // widget.data.followYn.toString().contains('N') ? '팔로우' : '팔로잉',
                      style: TextStyle(
                        color: widget.data.followYn.toString().contains('N') ? Colors.white : Colors.black,
                        fontSize: 14,
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
          const Gap(10),
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
              likeCountPadding: const EdgeInsets.only(top: 5, right: 0, left: 0),
              countPostion: CountPostion.bottom,
              countBuilder: (int? count, bool isLiked, String text) {
                Color color = isLiked ? Colors.redAccent : Colors.white;
                Widget result;
                if (count == 0) {
                  result = Text(
                    "Love",
                    style: TextStyle(color: color, fontSize: 10),
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
          SizedBox(
            width: 40,
            height: 30,
            child: IconButton(
              padding: const EdgeInsets.all(0),
              constraints: const BoxConstraints(),
              icon: const Icon(Icons.message_outlined, color: Colors.white),
              onPressed: () => commentSheet(),
            ),
          ),
          Text(
            widget.data.replyCnt.toString() == 'null' ? '0' : widget.data.replyCnt.toString(),
            style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w600),
          ),

          const Gap(10),
          SizedBox(
            height: 30,
            child: IconButton(
              padding: const EdgeInsets.all(0),
              icon: const Icon(Icons.play_arrow, color: Colors.white),
              onPressed: () => null,
            ),
          ),
          Text(
            widget.data.viewCnt.toString(),
            style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w600),
          ),
          // IconButton(
          //     icon: const Icon(Icons.report_gmailerrorred, color: Colors.white),
          //     onPressed: () => SigoPageSheet().open(context, widget.data.boardId.toString())),
          const Gap(10),
          // const Text(
          //   '조회수',
          //   style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w400),
          // ),

          // const Gap(40),
          // IconButton(
          //   icon: const Icon(Icons.send, color: Colors.white),
          //   onPressed: () => share(),
          // ),
        ],
      ),
    );
  }

  void commentSheet() {
    final aa = CommentPage().open(context, widget.data.boardId.toString());
    lo.g('@@@  CommentPage().open(context, widget.data.boardId.toString()) : $aa');
  }

  // 중앙 play 버튼
  Widget buildCenterPlayButton() {
    return Positioned(
      bottom: MediaQuery.of(context).size.height * 0.5,
      left: (MediaQuery.of(context).size.width - 50) * 0.5,
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
      // child: VideoProgressIndicator(
      //   _controller!,
      //   allowScrubbing: true,
      //   colors: VideoProgressColors(playedColor: Colors.red, bufferedColor: Colors.grey, backgroundColor: Colors.white.withOpacity(0.5)),
      // ),
      child: ValueListenableBuilder<double>(
        valueListenable: progress,
        builder: (context, value, child) {
          return Stack(
            children: [
              Container(height: 2.5, color: Colors.grey, width: MediaQuery.of(context).size.width),
              AnimatedContainer(
                duration: Duration(milliseconds: value == 0.0 ? 50 : 1000),
                height: 2.5,
                width: (MediaQuery.of(context).size.width) * ((value + (value * 0.1)) / 100),
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(4), color: Colors.red),
              ),
            ],
          );
        },
      ),
    );
  }

  // 사운드 on/off 버튼
  Widget buildSoundButton() {
    return Positioned(
      bottom: (MediaQuery.of(context).size.height - 15) * .5,
      left: 0,
      child: Obx(() => IconButton(
            onPressed: () {
              Get.find<VideoListCntr>().soundOff.value = !Get.find<VideoListCntr>().soundOff.value;
              if (Get.find<VideoListCntr>().soundOff.value) {
                _controller.setVolume(0);
              } else {
                _controller.setVolume(1);
              }
            },
            icon: Get.find<VideoListCntr>().soundOff.value
                ? const Icon(Icons.volume_off_outlined, color: Colors.white)
                : const Icon(Icons.volume_up_outlined, color: Colors.white),
          )),
    );
  }
}
