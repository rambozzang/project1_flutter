//import 'package:cached_video_player_plus/cached_video_player_plus.dart';

import 'dart:io';
import 'dart:math';
import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:gap/gap.dart';
import 'package:get/get.dart';
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

  bool initPlay = false;
  int loadingImageIndex = 0;

  @override
  void initState() {
    super.initState();

    initiliazeVideo();
    isFollowed.value = widget.data.followYn.toString();
    loadingImageIndex = Random().nextInt(6);
  }

  Future initiliazeVideo() async {
    if (initialized) {
      return;
    }
    final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
    final lastModified = _formatHttpDate(sevenDaysAgo);

    try {
      lo.g('@@@  VideoMyScreenPageState initiliazeVideo() Loading : ${widget.data.boardId}');
      lo.g('@@@  VideoMyScreenPageState initiliazeVideo() Loading : ${widget.data.videoPath.toString()}');

      _controller = VideoPlayerController.networkUrl(
        Uri.parse(widget.data.videoPath.toString()),
        httpHeaders: {
          'Connection': 'keep-alive',
          'Cache-Control': 'max-age=604800',
          'Etg': widget.data.boardId.toString(),
          'Last-Modified': lastModified, // Set Last-Modified header
        },
        formatHint: VideoFormat.hls,
      )..initialize().then((_) {
          if (mounted) {
            lo.g('@@@  VideoMyScreenPageState initiliazeVideo() Mounted : ${widget.data.boardId}');
            setState(() {
              _controller.setLooping(true);
              _controller.pause();
              initialized = true;
            });
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
      lo.g('initiliazeMyVideo error : ${e.toString()}');
      initiliazeVideo();
    } finally {}
  }

  String _formatHttpDate(DateTime date) {
    // Format the date as per HTTP-date format defined in RFC7231
    // Example: Tue, 15 Nov 1994 08:12:31 GMT
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

  @override
  void dispose() {
    initialized = false;
    _controller.pause();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF262B49),
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
                    child: initialized == false
                        ? buildLoading()
                        : VisibilityDetector(
                            onVisibilityChanged: (info) {
                              initPlay = false;
                              if (info.visibleFraction > 0.5) {
                                if (initialized) {
                                  _controller.play();
                                  Get.find<VideoMyinfoListCntr>().soundOff.value ? _controller.setVolume(0) : _controller.setVolume(1);
                                }
                              } else if (info.visibleFraction < 0.4) {
                                if (initialized) {
                                  _controller.pause();
                                  _controller.seekTo(Duration.zero);
                                  Get.find<VideoMyinfoListCntr>().soundOff.value ? _controller.setVolume(0) : _controller.setVolume(1);
                                }
                              }
                            },
                            key: GlobalKey(),
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
                  right: 26,
                  child: GestureDetector(
                    onTap: () => SigoPageSheet().open(context, widget.data.boardId.toString()),
                    child: const Column(
                      children: [
                        Icon(Icons.warning, color: Colors.white),
                        Text(
                          '신고',
                          style: TextStyle(color: Colors.white, fontSize: 9),
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
                            onPressed: () =>
                                VideoManagePageSheet().open(context, widget.data.boardId.toString(), widget.data.hideYn.toString())),
                      )
                    ],
                  ),
                )
              : const SizedBox.shrink(),
        ],
      ),
    );
  }

  Widget buildLoading() {
    return SizedBox.expand(
      child: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: ExactAssetImage(
              // 'assets/images/girl-6356393_640.jpg',
              'assets/images/$loadingImageIndex.jpg',
            ),
            fit: BoxFit.cover,
          ),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20.0, sigmaY: 25.0),
          child: Stack(
            children: [
              // Positioned.fill(
              //   child: CachedNetworkImage(
              //      cacheKey: widget.data.boardId.toString(),
              //     imageUrl: widget.data.thumbnailPath.toString(),
              //     fit: BoxFit.cover,
              //     placeholder: (context, url) => SizedBox(width: 60, height: 60, child: Utils.progressbar(color: Colors.white)),
              //   ),
              // ),
              // Positioned.fill(

              //   child: Image.asset(
              //     'assets/images/girl-6356393_640.jpg',
              //     fit: BoxFit.cover,
              //     filterQuality: FilterQuality.high,
              //   ),
              // ),
              Positioned(
                  top: MediaQuery.of(context).size.height * 0.5,
                  left: 10,
                  right: 10,
                  child: const Center(child: Text(" ", style: TextStyle(color: Colors.white, fontSize: 9))))
            ],
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
    String locationNm = widget.data.location.toString();

    return Positioned(
      bottom: bottomHeight,
      right: 20,
      left: 20,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => Get.toNamed('/OtherInfoPage/${widget.data.custId.toString()}'),
                child: Container(
                  width: 35.0,
                  height: 35.0,
                  decoration: BoxDecoration(
                    color: const Color(0xff7c94b6),
                    image: DecorationImage(
                      image: CachedNetworkImageProvider(widget.data.profilePath!),
                      fit: BoxFit.cover,
                    ),
                    borderRadius: const BorderRadius.all(Radius.circular(50.0)),
                    border: Border.all(
                      color: Colors.green,
                      width: 2.0,
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
                      //  init: VideoMyinfoListCntr(),
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
                            // backgroundColor: widget.data.followYn.toString().contains('N') ? Colors.black : Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10.0), side: const BorderSide(color: Colors.white, width: 0.7)),
                          ),
                          child: Text(
                            widget.data.followYn.toString() == 'N' ? '팔로우' : '팔로잉',
                            // widget.data.followYn.toString().contains('N') ? '팔로우' : '팔로잉',
                            style: TextStyle(
                              color: widget.data.followYn.toString().contains('N') ? Colors.white : Colors.black,
                              fontSize: 15,
                            ),
                          ),
                        );
                      },
                    ),
              // ValueListenableBuilder<String>(
              //     valueListenable: isFollowed,
              //     builder: (context, value, child) {
              //       return ElevatedButton(
              //         onPressed: () => value.toString().contains('N') ? follow() : followCancle(),
              //         clipBehavior: Clip.none,
              //         style: ElevatedButton.styleFrom(
              //           padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              //           elevation: 1.5,
              //           minimumSize: const Size(0, 0),
              //           tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              //           backgroundColor: widget.data.followYn.toString().contains('N') ? Colors.white : Colors.grey,
              //           shape: RoundedRectangleBorder(
              //             borderRadius: BorderRadius.circular(20.0),
              //           ),
              //         ),
              //         child: Text(
              //           value.toString().contains('N') ? '팔로우' : '팔로잉',
              //           style: const TextStyle(
              //             color: Colors.black,
              //             fontSize: 14,
              //           ),
              //         ),
              //       );
              //     })
            ],
          ),
          const Gap(5),
          Row(
            children: [
              Text(
                '${widget.data.crtDtm.toString().split(':')[0].replaceAll('-', '/')}:${widget.data.crtDtm.toString().split(':')[1]}',
                style: const TextStyle(fontSize: 13, color: Colors.white, fontWeight: FontWeight.w600),
              ),
              const SizedBox(width: 20, height: 13, child: VerticalDivider(thickness: 1, color: Colors.white)),
              // Text(
              //   '${widget.data.weatherInfo?.split('.')[0]} ${widget.data.currentTemp}°',
              //   style: const TextStyle(fontSize: 15, color: Colors.white, fontWeight: FontWeight.w700),
              // ),
              SizedBox(
                height: 30,
                width: 30,
                child: CachedNetworkImage(
                  width: 50,
                  height: 50,
                  imageUrl: 'http://openweathermap.org/img/wn/${widget.data.icon}@2x.png',
                  imageBuilder: (context, imageProvider) => Container(
                    decoration: BoxDecoration(
                      image: DecorationImage(
                          image: imageProvider,
                          fit: BoxFit.cover,
                          colorFilter: const ColorFilter.mode(Colors.transparent, BlendMode.colorBurn)),
                    ),
                  ),
                  placeholder: (context, url) => const CircularProgressIndicator(strokeWidth: 0.6, color: Colors.white),
                  errorWidget: (context, url, error) => const Icon(Icons.error),
                ),
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
                  // '${locationNm.toString()} ${widget.data.distance!.toStringAsFixed(1)}km ',
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
          const Gap(15),
          // SizedBox(
          //   width: Get.width * 0.78,
          //   child: const TextScroll(
          //     '여기서는 TextButton, FilledButton, ElevatedButton의 크기를 변경하는 방법에 대해서 알아보겠습니다. ',
          //     mode: TextScrollMode.endless,
          //     numberOfReps: 200,
          //     fadedBorder: false,
          //     delayBefore: Duration(milliseconds: 4000),
          //     pauseBetween: Duration(milliseconds: 2000),
          //     velocity: Velocity(pixelsPerSecond: Offset(100, 0)),
          //     style: TextStyle(fontSize: 16, color: Colors.white),
          //     textAlign: TextAlign.right,
          //     selectable: true,
          //   ),
          // )
        ],
      ),
    );
  }

  // 오른쪽 메뉴바
  Widget buildRightMenuBar() {
    return Positioned(
      bottom: bottomHeight,
      right: 10,
      child: Column(
        children: [
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
          IconButton(
            icon: const Icon(Icons.message_outlined, color: Colors.white),
            onPressed: () => commentSheet(),
          ),
          Text(
            widget.data.replyCnt == null ? '0' : widget.data.replyCnt.toString(),
            style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w600),
          ),

          const Gap(10),
          IconButton(
            icon: const Icon(Icons.play_arrow_outlined, color: Colors.white),
            onPressed: () => null,
          ),
          Text(
            widget.data.viewCnt.toString(),
            style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w600),
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
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      // color: const Color.fromRGBO(215, 215, 215, 1),
                      // color: const Color.fromRGBO(215, 215, 215, 1),
                      //color: const Color.fromARGB(255, 110, 186, 111),
                      // color: const Color.fromARGB(255, 38, 162, 40),
                      // color: const Color.fromARGB(255, 34, 112, 26),
                      color: Colors.red
                      // color: Color.fromARGB(255, 13, 104, 43),
                      ),
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
      left: 10,
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
