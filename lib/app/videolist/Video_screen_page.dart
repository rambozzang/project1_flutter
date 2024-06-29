//import 'package:cached_video_player_plus/cached_video_player_plus.dart';

import 'dart:io';
import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:get/get.dart';
import 'package:hashtagable_v3/hashtagable.dart';
import 'package:like_button/like_button.dart';
import 'package:project1/app/auth/cntr/auth_cntr.dart';

import 'package:project1/app/videolist/cntr/video_list_cntr.dart';
import 'package:project1/app/videocomment/comment_page.dart';
import 'package:project1/repo/board/board_repo.dart';
import 'package:project1/repo/board/data/board_weather_list_data.dart';
import 'package:project1/repo/common/res_data.dart';
import 'package:project1/utils/log_utils.dart';
import 'package:project1/utils/utils.dart';
import 'package:share_plus/share_plus.dart';
import 'package:text_scroll/text_scroll.dart';

import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';

// video_player 오류  https://github.com/flutter/flutter/issues/61309 , https://github.com/flutter/flutter/issues/25558
class VideoScreenPage extends StatefulWidget {
  const VideoScreenPage({super.key, required this.index, required this.data});

  final BoardWeatherListData data;
  final int index;
  // final VoidCallback onMounted;
  // final VideoPlayerController? controller;

  @override
  State<VideoScreenPage> createState() => VideoScreenPageState();
}

class VideoScreenPageState extends State<VideoScreenPage> {
  //late VideoPlayerController _controller;
  late VideoPlayerController _controller;

  GlobalKey _key = GlobalKey();
  bool initialized = false;

  bool initPlay = false;

  final ValueNotifier<bool> soundOff = ValueNotifier<bool>(false);
  final ValueNotifier<bool> isPlay = ValueNotifier<bool>(true);
  final ValueNotifier<double> progress = ValueNotifier<double>(0.0);

  ValueNotifier<String> isFollowed = ValueNotifier<String>('N');

  // double progress = 0;
  Duration position = Duration.zero;

  double bottomHeight = Platform.isIOS ? 92.0 : 80.0;

  bool isUpdateCount = false;

  @override
  void initState() {
    super.initState();
    initiliazeVideo();

    isFollowed.value = widget.data.followYn.toString();
  }

  Future<void> initiliazeVideo() async {
    if (initialized) {
      return;
    }
    try {
      Stopwatch stopwatch = Stopwatch()..start();
      lo.g('@@@  VideoScreenPageState initiliazeVideo() ${widget.data.boardId} : 1.Start ');
      String finalUrl = widget.data.videoPath.toString();

      _controller = VideoPlayerController.networkUrl(Uri.parse(finalUrl),
          httpHeaders: {
            'Connection': 'keep-alive',
            'Cache-Control': 'max-age=604800',
          },
          formatHint: VideoFormat.hls)
        ..initialize().then((_) {
          if (mounted) {
            stopwatch.stop();
            lo.g('@@@  VideoScreenPageState initiliazeVideo() ${widget.data.boardId} : 2.Mounted =>. ${stopwatch.elapsed}');
            setState(() {
              _controller.setLooping(true);
              _controller.pause();
              initialized = true;
            });
            Get.find<VideoListCntr>().onPageMounted(widget.data.boardId!);
            if (isPlay.value) {
              updateCount();
            }
          }
        });

      _controller.addListener(() {
        isPlay.value = _controller.value.isPlaying;
        int max = _controller.value.duration.inSeconds;
        position = _controller.value.position;
        progress.value = (position.inSeconds / max * 100).isNaN ? 0 : position.inSeconds / max * 100;
      });
    } catch (e) {
      lo.g('======>>>>>> DefaultCacheManager().getSingleFile error : $e');
    } finally {}
  }

  // 조회수 증가
  Future<void> updateCount() async {
    if (isUpdateCount) return;

    isUpdateCount = true;
    BoardRepo boardRepo = BoardRepo();
    try {
      await boardRepo.updateBoardCount(widget.data.boardId.toString());
    } catch (e) {
      lo.g('@@@  updateCount error : $e');
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
    // final result = await Share.shareXFiles([XFile('${directory.path}/image.jpg')], text: 'Great picture');

    // if (result.status == ShareResultStatus.success) {
    //     print('Thank you for sharing the picture!');
    // }
    final result = await Share.share('check out my website https://example.com');

    if (result.status == ShareResultStatus.success) {
      print('Thank you for sharing my website!');
    }
  }

  @override
  void dispose() {
    initialized = false;
    _controller.removeListener(() {});
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
      body: VisibilityDetector(
        onVisibilityChanged: (info) {
          initPlay = false;
          if (info.visibleFraction > 0.4) {
            if (initialized) {
              _controller.play();

              Get.find<VideoListCntr>().soundOff.value ? _controller.setVolume(0) : _controller.setVolume(1);
            }
          } else if (info.visibleFraction < 0.4) {
            // } else {
            if (initialized) {
              _controller.pause();
              _controller.seekTo(Duration.zero);
              Get.find<VideoListCntr>().soundOff.value ? _controller.setVolume(0) : _controller.setVolume(1);
            }
          }
        },
        key: _key,
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
                    : SizedBox.expand(
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
            // Center(
            //   child: Text(widget.data.boardId.toString(),
            //       style: const TextStyle(fontSize: 30, color: Colors.white, fontWeight: FontWeight.bold)),
            // )
          ],
        ),
      ),
    );
  }

  Widget buildLoading() {
    // return const Center(
    //   child: CircularProgressIndicator(
    //     valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
    //   ),
    // );
    return SizedBox.expand(
      //   child: BackdropFilter(
      // filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
      child: CachedNetworkImage(
        // cacheKey: widget.data.boardId.toString(),
        imageUrl: widget.data.thumbnailPath.toString(),
        fit: BoxFit.cover,
        placeholder: (context, url) => SizedBox(width: 60, height: 60, child: Utils.progressbar(color: Colors.white)),
      ),
      // ),
    );
  }

  // 하단 컨텐츠
  Widget buildBottomContent() {
    String locationNm = widget.data.location ?? "";
    // String locationNm =
    //     '${widget.data.location.toString().split(' ')[0]} ${widget.data.location.toString().split(' ')[1]} ${widget.data.location.toString().split(' ')[2]}';
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

              // ValueListenableBuilder<String>(
              //   valueListenable: isFollowed,
              //   builder: (context, value, child) {
              //     if (widget.data.custId == Get.find<AuthCntr>().custId.value) {
              //       return const SizedBox.shrink();
              //     }
              //     return ElevatedButton(
              //       onPressed: () => value.toString().contains('N') ? follow() : followCancle(),
              //       clipBehavior: Clip.none,
              //       style: ElevatedButton.styleFrom(
              //         padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
              //         elevation: 0.5,
              //         minimumSize: const Size(0, 0),
              //         tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              //         backgroundColor: value.toString().contains('N') ? Colors.transparent : Colors.white,
              //         // backgroundColor: widget.data.followYn.toString().contains('N') ? Colors.black : Colors.white,
              //         shape: RoundedRectangleBorder(
              //             borderRadius: BorderRadius.circular(10.0), side: const BorderSide(color: Colors.white, width: 0.7)),
              //       ),
              //       child: Text(
              //         value.toString().contains('N') ? '팔로우' : '팔로잉',
              //         style: TextStyle(
              //           color: value.toString().contains('N') ? Colors.white : Colors.black,
              //           fontSize: 15,
              //         ),
              //       ),
              //     );
              //   },
              // )
            ],
          ),
          const Gap(5),
          Row(
            children: [
              Text(
                '${widget.data.crtDtm.toString().split(':')[0].replaceAll('-', '/')} ${widget.data.crtDtm.toString().split(':')[1]}',
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
                  '${locationNm.toString()} ${widget.data.distance!.toStringAsFixed(1)}km ',
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
          LikeButton(
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
          const Gap(3),
          // const Text(
          //   '조회수',
          //   style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w400),
          // ),

          const Gap(40),
          // IconButton(
          //   icon: const Icon(Icons.send, color: Colors.white),
          //   onPressed: () => share(),
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
                Container(height: 2, color: Colors.grey, width: MediaQuery.of(context).size.width),
                AnimatedContainer(
                  duration: Duration(milliseconds: value == 0.0 ? 50 : 1000),
                  height: 2,
                  width: (MediaQuery.of(context).size.width) * ((value + (value * 0.1)) / 100),
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

  // 사운드 on/off 버튼
  Widget buildSoundButton() {
    return Positioned(
      bottom: (MediaQuery.of(context).size.height - 15) * .5,
      left: 10,
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
