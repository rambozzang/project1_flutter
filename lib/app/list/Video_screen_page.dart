//import 'package:cached_video_player_plus/cached_video_player_plus.dart';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:gap/gap.dart';
import 'package:get/get.dart';
import 'package:hashtagable_v3/hashtagable.dart';
import 'package:like_button/like_button.dart';

import 'package:marquee_widget/marquee_widget.dart';
import 'package:project1/app/auth/cntr/auth_cntr.dart';
import 'package:project1/app/list/comment_page.dart';
import 'package:project1/repo/board/board_repo.dart';
import 'package:project1/repo/board/data/board_list_data.dart';
import 'package:project1/repo/common/res_data.dart';
import 'package:project1/utils/utils.dart';
import 'package:text_scroll/text_scroll.dart';

import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';

class VideoSreenPage extends StatefulWidget {
  const VideoSreenPage({super.key, required this.data});

  final BoardListData data;

  @override
  State<VideoSreenPage> createState() => _VideoSreenPageState();
}

class _VideoSreenPageState extends State<VideoSreenPage> {
  late VideoPlayerController _controller;
  //late CachedVideoPlayerPlusController _controller;
  bool initialized = false;

  final ValueNotifier<bool> soundOff = ValueNotifier<bool>(false);
  final ValueNotifier<bool> isPlay = ValueNotifier<bool>(true);
  final ValueNotifier<double> progress = ValueNotifier<double>(0.0);

  // double progress = 0;
  Duration position = Duration.zero;

  @override
  void initState() {
    initiliazeVideo();
    super.initState();
  }

  Future initiliazeVideo() async {
    //  _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl))

    // _controller = CachedVideoPlayerPlusController.networkUrl(
    //   Uri.parse(widget.videoUrl),
    //   invalidateCacheIfOlderThan: const Duration(days: 69),)

    final file = await DefaultCacheManager().getSingleFile(widget.data.videoPath.toString(), key: widget.data.videoPath.toString());
    _controller = VideoPlayerController.file(file)
      ..initialize().then((_) {
        if (mounted) {
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

      // aspectRatio = _controller.value.aspectRatio;
      position = _controller.value.position;
      progress.value = (position.inSeconds / max * 100).isNaN ? 0 : position.inSeconds / max * 100;
    });
  }

  Future<void> like() async {
    try {
      BoardRepo boardRepo = BoardRepo();
      ResData resData = await boardRepo.like(widget.data.boardId.toString());
      if (resData.code != '00') {
        Utils.alert(resData.msg.toString());
        return;
      }
      //Utils.alert('정상 등록되었습니다!');
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
      //Utils.alert('정상 등록되었습니다!');
    } catch (e) {
      Utils.alert('좋아요 실패! 다시 시도해주세요');
    }
  }

  @override
  void dispose() {
    if (initialized) {
      initialized = false;
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
      onVisibilityChanged: (info) {
        if (info.visibleFraction > 0.5) {
          if (initialized) {
            _controller.play();
          }
        } else if (info.visibleFraction < 0.4) {
          if (initialized) {
            _controller.pause();
            _controller.seekTo(Duration.zero);
          }
        }
      },
      key: UniqueKey(),
      child: initialized
          ? Stack(
              children: [
                GestureDetector(
                  onTap: () {
                    if (_controller.value.isPlaying) {
                      _controller.pause();
                    } else {
                      _controller.play();
                    }
                  },
                  child: SizedBox.expand(
                    child: FittedBox(
                      fit: BoxFit.cover,
                      child: SizedBox(
                        width: _controller.value.size.width,
                        height: _controller.value.size.height,
                        //   child: CachedVideoPlayerPlus(_controller),
                        child: VideoPlayer(_controller),
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
                // Join 버튼
                buildJoinButton(),
                // 재생 progressbar
                buildPlayProgress(),
              ],
            )
          : Center(child: Utils.progressbar()),
    );
  }

  // 하단 컨텐츠
  Widget buildBottomContent() {
    String locationNm =
        '${widget.data.location.toString().split(' ')[0]} ${widget.data.location.toString().split(' ')[1]} ${widget.data.location.toString().split(' ')[2]}';
    return Positioned(
      bottom: 10,
      right: 20,
      left: 20,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
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
              const Gap(10),
              Text(
                widget.data.nickNm.toString(),
                style: const TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
              ),
              const Gap(15),
              ElevatedButton(
                onPressed: () {},
                clipBehavior: Clip.none,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  elevation: 1.5,
                  minimumSize: const Size(0, 0),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                ),
                child: const Text(
                  '구독',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 14,
                  ),
                ),
              ),
              // const SizedBox(width: 35, height: 23, child: VerticalDivider(thickness: 1, color: Colors.white)),
              // const Column(
              //   crossAxisAlignment: CrossAxisAlignment.start,
              //   children: [
              //     Text(
              //       '2024.03.03',
              //       style: TextStyle(fontSize: 13, color: Colors.white, fontWeight: FontWeight.w600),
              //     ),
              //     Text(
              //       '17:02:13',
              //       style: TextStyle(fontSize: 13, color: Colors.white, fontWeight: FontWeight.w600),
              //     ),
              //   ],
              // ),
            ],
          ),
          const Gap(5),
          Text(
            widget.data.chgDtm.toString(),
            style: const TextStyle(fontSize: 13, color: Colors.white, fontWeight: FontWeight.w600),
          ),
          Row(
            children: [
              Text(
                '${widget.data.weatherInfo} ${widget.data.currentTemp}°',
                style: const TextStyle(fontSize: 15, color: Colors.white, fontWeight: FontWeight.w700),
              ),
              SizedBox(
                height: 30,
                width: 30,
                child: CachedNetworkImage(
                  width: 50,
                  height: 50,
                  imageUrl: 'http://openweathermap.org/img/wn/10n@2x.png',
                  //   imageUrl:  //'http://openweathermap.org/img/w/${value.weather![0].icon}.png',
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
                // child: Image.network(
                //     width: 40,
                //     height: 40,
                //     'http://openweathermap.org/img/wn/10n@2x.png',
                //     //'http://openweathermap.org/img/w/${value.weather![0].icon}.png',
                //     scale: 0.6,
                //     fit: BoxFit.contain,
                //     alignment: Alignment.topCenter),
              ),
              const SizedBox(width: 10, height: 13, child: VerticalDivider(thickness: 1, color: Colors.white)),
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.5,
                child: TextScroll(
                  locationNm.toString(),
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
              // Te11xt(
              //   ' ${widget.data.location}',
              //   style: const TextStyle(fontSize: 15, color: Colors.white, fontWeight: FontWeight.w700),
              // ),
            ],
          ),
          // const Text(
          //   '2024.03.03 · 서울시 서대문구',
          //   style: TextStyle(fontSize: 15, color: Colors.white, fontWeight: FontWeight.w700),
          // ),
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
          SizedBox(
            width: Get.width * 0.78,
            child: const TextScroll(
              '여기서는 TextButton, FilledButton, ElevatedButton의 크기를 변경하는 방법에 대해서 알아보겠습니다. ',
              mode: TextScrollMode.endless,
              numberOfReps: 200,
              fadedBorder: false,
              delayBefore: Duration(milliseconds: 4000),
              pauseBetween: Duration(milliseconds: 2000),
              velocity: Velocity(pixelsPerSecond: Offset(100, 0)),
              style: TextStyle(fontSize: 16, color: Colors.white),
              textAlign: TextAlign.right,
              selectable: true,
            ),
            // child: Marquee(
            //   //scrollAxis: Axis.horizontal,
            //   textDirection: TextDirection.rtl,
            //   animationDuration: const Duration(seconds: 1),
            //   backDuration: const Duration(milliseconds: 5000),
            //   pauseDuration: const Duration(milliseconds: 1500),
            //   directionMarguee: DirectionMarguee.TwoDirection,
            //   child: const Row(
            //     children: [
            //       Text(
            //         ' 여기서는 TextButton, FilledButton, ElevatedButton의 크기를 변경하는 방법에 대해서 알아보겠습니다',
            //         style: TextStyle(fontSize: 13, color: Colors.white, fontWeight: FontWeight.w600),
            //       ),
            //       Gap(10),
            //       Icon(Icons.music_note, color: Colors.red, size: 15),
            //     ],
            //   ),
            // ),
          )
        ],
      ),
    );
  }

  // 오른쪽 메뉴바
  Widget buildRightMenuBar() {
    return Positioned(
      bottom: 20,
      right: 10,
      child: Column(
        children: [
          // IconButton(
          //   icon: const Icon(Icons.favorite_border, color: Colors.white),
          //   onPressed: () {},
          // ),
          // const Text(
          //   '1.2M',
          //   style: TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w600),
          // ),
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
            // onTap:  {
            //   // if (widget.data.likeYn == 'Y') {
            //   //   likeCancle();
            //   // } else {
            //   //   like();
            //   // }
            //   // return Future.value(!widget.data.likeYn.toString().contains('Y'));
            // },
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
                    style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                );
              }
              return result;
            },
          ),
          const Gap(10),
          IconButton(
            icon: const Icon(Icons.message_outlined, color: Colors.white),
            onPressed: () => CommentPage().open(context, widget.data.boardId.toString()),
          ),
          const Text(
            '1.2M',
            style: TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w600),
          ),
          const Gap(10),
          IconButton(
            icon: const Icon(Icons.send, color: Colors.white),
            onPressed: () {},
          ),
          const Gap(5),
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onPressed: () => Get.toNamed('/MyinfoPage'),
          ),
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

  // Join 버튼
  Widget buildJoinButton() {
    return Positioned(
      right: 10,
      top: Get.height / 2,
      child: ConstrainedBox(
        constraints: const BoxConstraints.tightFor(width: 65, height: 40),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white.withOpacity(0.15),
            padding: const EdgeInsets.all(1.0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.0),
            ),
            elevation: 1.0,
          ),
          onPressed: () {
            Get.toNamed('/OnboardingPage');
          },
          child: const Text(
            'Join',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  // 사운드 on/off 버튼
  Widget buildSoundButton() {
    return Positioned(
      top: Get.height / 2,
      left: 10,
      child: IconButton(
        onPressed: () {
          soundOff.value = !soundOff.value;
          if (soundOff.value) {
            _controller.setVolume(0);
          } else {
            _controller.setVolume(1);
          }
        },
        icon: ValueListenableBuilder<bool>(
            valueListenable: soundOff,
            builder: (context, value, child) {
              return value
                  ? const Icon(Icons.volume_off_outlined, color: Colors.white)
                  : const Icon(Icons.volume_up_outlined, color: Colors.white);
            }),
      ),
    );
  }
}
