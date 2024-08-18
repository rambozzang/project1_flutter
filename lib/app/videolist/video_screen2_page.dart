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
import 'package:project1/app/videolist/cntr/M3u8Parsing.dart';

import 'package:project1/app/videolist/cntr/video_list_cntr.dart';
import 'package:project1/app/videocomment/comment_page.dart';
import 'package:project1/app/videolist/video_sigo_page.dart';
import 'package:project1/repo/board/board_repo.dart';
import 'package:project1/repo/board/data/board_weather_list_data.dart';
import 'package:project1/app/weathergogo/services/weather_data_processor.dart';
import 'package:project1/utils/log_utils.dart';
import 'package:project1/utils/utils.dart';
import 'package:text_scroll/text_scroll.dart';

import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';

// video_player 오류  https://github.com/flutter/flutter/issues/61309 , https://github.com/flutter/flutter/issues/25558

class VideoScreenPage2 extends StatefulWidget {
  const VideoScreenPage2({super.key, required this.index, required this.data});

  final BoardWeatherListData data;
  final int index;
  // final VoidCallback onMounted;
  // final VideoPlayerController? controller;

  @override
  State<VideoScreenPage2> createState() => VideoScreenPage2State();
}

class VideoScreenPage2State extends State<VideoScreenPage2> {
  bool initPlay = false;
  //late VideoPlayerController _controller;
  late VideoPlayerController _controller;
  final GlobalKey _key = GlobalKey();

  final ValueNotifier<bool> initialized = ValueNotifier<bool>(false);
  // final ValueNotifier<bool> soundOff = ValueNotifier<bool>(false);
  final ValueNotifier<bool> isPlay = ValueNotifier<bool>(true);
  final ValueNotifier<double> progress = ValueNotifier<double>(0.0);
  final ValueNotifier<String> isFollowed = ValueNotifier<String>('N');
  final ValueNotifier<String> timeDesc = ValueNotifier<String>('0ms');

  Duration position = Duration.zero;
  final double bottomHeight = Platform.isIOS ? 92.0 : 80.0;
  bool isUpdateCount = true;
  late int loadingImageIndex;

  @override
  void initState() {
    _initializeVideo();
    super.initState();
    loadingImageIndex = Random().nextInt(6);
    isFollowed.value = widget.data.followYn.toString();
  }

  String _getFinalUrl() {
    return Platform.isAndroid ? widget.data.videoPath.toString().replaceAll('m3u8', 'm3u8') : widget.data.videoPath.toString();
  }

  Future<void> _initializeVideo() async {
    final stopwatch = Stopwatch()..start();

    final String masterPlaylistUrl = widget.data.videoPath.toString();
    // final String lowestQualityStreamUrl = await M3U8Parser.getLowestQualityStreamUrl(masterPlaylistUrl);
    final String finalUrl = _getFinalUrl();
    final VideoFormat format = Platform.isAndroid ? VideoFormat.hls : VideoFormat.hls;
    lo.g('VideoPlayer2 initialization finalUrl: ${finalUrl}');

    try {
      _controller = VideoPlayerController.networkUrl(
        Uri.parse(finalUrl),
        httpHeaders: _getHttpHeaders(),
        formatHint: format,
      );

      await _controller.initialize();

      if (!mounted) return;

      _controller
        ..setLooping(true)
        ..addListener(_videoListener);

      initialized.value = true;
      lo.g('VideoPlayer2 initialization time: ${stopwatch.elapsedMilliseconds}ms');
      timeDesc.value = '${stopwatch.elapsedMilliseconds}ms';

      _controller.pause();
    } catch (e) {
      print('Error initializing video: $e');
    }
  }

  void _videoListener() {
    isPlay.value = _controller.value.isPlaying;
    final int max = _controller.value.duration.inSeconds;
    position = _controller.value.position;
    progress.value = (position.inSeconds / max * 100).isNaN ? 0 : position.inSeconds / max * 100;
    if (isPlay.value) {
      _updateCount();
    }
  }

  Map<String, String> _getHttpHeaders() {
    final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
    final lastModified = _formatHttpDate(sevenDaysAgo);

    return {
      'Connection': 'keep-alive',
      'Cache-Control': 'max-age=3600, stale-while-revalidate=86400',
      'Etg': widget.data.boardId.toString(),
      'Last-Modified': lastModified,
      'If-None-Match': widget.data.boardId.toString(),
      'If-Modified-Since': lastModified,
      'Vary': 'Accept-Encoding, User-Agent',
    };
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

  Future<void> _updateCount() async {
    if (isUpdateCount) return;
    isUpdateCount = true;
    try {
      await BoardRepo().updateBoardCount(widget.data.boardId.toString());
    } catch (e) {
      print('Error updating count: $e');
    }
  }

  Future<void> _like() async {
    try {
      final boardRepo = BoardRepo();
      final resData = await boardRepo.like(widget.data.boardId.toString(), widget.data.custId.toString(), "Y");
      if (resData.code != '00') {
        Utils.alert(resData.msg.toString());
        return;
      }
      _updateLikeStatus(true);
    } catch (e) {
      print('Error liking: $e');
    }
  }

  Future<void> _likeCancle() async {
    try {
      final boardRepo = BoardRepo();
      final resData = await boardRepo.likeCancle(widget.data.boardId.toString());
      if (resData.code != '00') {
        Utils.alert(resData.msg.toString());
        return;
      }
      _updateLikeStatus(false);
    } catch (e) {
      Utils.alert('좋아요 취소 실패! 다시 시도해주세요');
    }
  }

  void _updateLikeStatus(bool isLiked) {
    final videoListCntr = Get.find<VideoListCntr>();
    final int inx = videoListCntr.currentIndex.value;
    videoListCntr.list[inx].likeCnt = isLiked ? videoListCntr.list[inx].likeCnt! + 1 : videoListCntr.list[inx].likeCnt! - 1;
    videoListCntr.list[inx].likeYn = isLiked ? 'Y' : 'N';
  }

  @override
  void dispose() {
    _controller.removeListener(_videoListener);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF262B49),
      resizeToAvoidBottomInset: true,
      extendBodyBehindAppBar: true,
      extendBody: true,
      body: Stack(
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
              switchInCurve: Curves.easeIn,
              switchOutCurve: Curves.ease,
              child: ValueListenableBuilder<bool>(
                valueListenable: initialized,
                builder: (context, value, child) {
                  return value == false
                      ? buildLoading()
                      : VisibilityDetector(
                          onVisibilityChanged: (info) {
                            initPlay = false;
                            if (info.visibleFraction > 0.1) {
                              if (value) {
                                _controller.play();

                                Get.find<VideoListCntr>().soundOff.value ? _controller.setVolume(0) : _controller.setVolume(1);
                              }
                            } else if (info.visibleFraction < 0.3) {
                              // } else {
                              if (value) {
                                _controller.pause();
                                _controller.seekTo(Duration.zero);
                                Get.find<VideoListCntr>().soundOff.value ? _controller.setVolume(0) : _controller.setVolume(1);
                              }
                            }
                          },
                          key: _key,
                          child: SizedBox.expand(
                            child: FittedBox(
                              fit: BoxFit.cover,
                              child: SizedBox(
                                width: _controller.value.size.width,
                                height: _controller.value.size.height,
                                child: VideoPlayer(_controller),
                              ),
                            ),
                          ),
                        );
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
          // 신고
          buildSingo()
          // Center(
          //   child: Text(widget.data.boardId.toString(),
          //       style: const TextStyle(fontSize: 30, color: Colors.white, fontWeight: FontWeight.bold)),
          // )
        ],
      ),
    );
  }

  Widget buildSingo() {
    return Positioned(
      bottom: (MediaQuery.of(context).size.height - 12) * .5,
      right: 12,
      child: GestureDetector(
        onTap: () => SigoPageSheet().open(context, widget.data.boardId.toString(),
            Get.find<VideoListCntr>().list[widget.index].custId.toString(), Get.find<VideoListCntr>().getData),
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

  Widget buildLoading() {
    return SizedBox.expand(
      child: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: CachedNetworkImageProvider(widget.data.thumbnailPath.toString()),
            // image: ExactAssetImage(
            //   'assets/images/$loadingImageIndex.jpg',
            // ),
            fit: BoxFit.cover,
          ),
        ),
        // child: BackdropFilter(
        //   filter: ImageFilter.blur(sigmaX: 35.0, sigmaY: 35.0),
        //   child: const Text("", style: TextStyle(color: Colors.white, fontSize: 9)),
        // ),
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
                child: Lottie.asset(
                  WeatherDataProcessor.instance.getWeatherGogoImage(widget.data!.sky.toString(), widget.data!.rain.toString()),
                  height: 138.0,
                  width: 138.0,
                ),
                // child: CachedNetworkImage(
                //   width: 50,
                //   height: 50,
                //   imageUrl: 'http://openweathermap.org/img/wn/${widget.data.icon}@2x.png',
                //   imageBuilder: (context, imageProvider) => Container(
                //     decoration: BoxDecoration(
                //       image: DecorationImage(
                //           image: imageProvider,
                //           fit: BoxFit.cover,
                //           colorFilter: const ColorFilter.mode(Colors.transparent, BlendMode.colorBurn)),
                //     ),
                //   ),
                //   placeholder: (context, url) => const CircularProgressIndicator(strokeWidth: 0.6, color: Colors.white),
                //   errorWidget: (context, url, error) => const Icon(Icons.error),
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
              const Icon(Icons.location_on, color: Colors.white, size: 16),
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.75,
                child: TextScroll(
                  '${locationNm.toString()} - 거리: ${widget.data.distance!.toStringAsFixed(1)}km',
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
                    decoratedStyle: const TextStyle(
                        fontSize: 17,
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
              : const SizedBox(),
          const Gap(5),
          Row(
            children: [
              GestureDetector(
                onTap: () => Get.toNamed('/OtherInfoPage/${widget.data.custId.toString()}'),
                child: Container(
                    height: 35,
                    width: 35,
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      // color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white, width: 0.5),
                      image: DecorationImage(
                        image: CachedNetworkImageProvider(widget.data.profilePath.toString()),
                        fit: BoxFit.cover,
                      ),
                    ),
                    child: widget.data.profilePath == null ? const Icon(Icons.person, color: Colors.white) : null),
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
          ),
          const Gap(10)
        ],
      ),
    );
  }

  // 오른쪽 메뉴바
  Widget buildRightMenuBar() {
    return Positioned(
      bottom: bottomHeight,
      right: 0,
      child: Column(
        children: [
          if (kDebugMode) ...[
            ValueListenableBuilder<String>(
              valueListenable: timeDesc,
              builder: (context, value, child) {
                return Text('2: $value', style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w600));
              },
            ),
            const Gap(10),
          ],
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
                  _likeCancle();
                } else {
                  _like();
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
                    style: TextStyle(color: color),
                  );
                } else {
                  result = SizedBox(
                    width: 30,
                    height: 18,
                    // color: Colors.red,
                    child: Text(
                      text,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
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
            style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w600),
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
            style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w600),
          ),
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
          const Gap(5),
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
