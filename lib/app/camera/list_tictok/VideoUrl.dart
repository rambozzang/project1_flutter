//import 'package:cached_video_player_plus/cached_video_player_plus.dart';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:gap/gap.dart';
import 'package:get/get.dart';
import 'package:get/get_connect/http/src/utils/utils.dart';
import 'package:marquee_widget/marquee_widget.dart';
import 'package:project1/app/auth/cntr/auth_cntr.dart';
import 'package:project1/app/camera/page/video_indicator.dart';
import 'package:project1/utils/log_utils.dart';
import 'package:project1/utils/utils.dart';
import 'package:project1/widget/custom_button.dart';

import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';

class VideoUrl extends StatefulWidget {
  const VideoUrl({super.key, required this.videoUrl});

  final String videoUrl;

  @override
  State<VideoUrl> createState() => _VideoUrlState();
}

class _VideoUrlState extends State<VideoUrl> {
  late VideoPlayerController _controller;
  //late CachedVideoPlayerPlusController _controller;
  bool initialized = false;

  final ValueNotifier<bool> soundOff = ValueNotifier<bool>(false);
  final ValueNotifier<bool> isPlay = ValueNotifier<bool>(true);
  final ValueNotifier<double> progress = ValueNotifier<double>(0.0);

  late String url = '';

  double? aspectRatio;
  // double progress = 0;
  Duration position = Duration.zero;

  initiliazeVideo() async {
    //  _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl))

    // _controller = CachedVideoPlayerPlusController.networkUrl(
    //   Uri.parse(widget.videoUrl),
    //   invalidateCacheIfOlderThan: const Duration(days: 69),)

    final file = await DefaultCacheManager().getSingleFile(widget.videoUrl, key: widget.videoUrl);
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

  @override
  void initState() {
    initiliazeVideo();
    super.initState();
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
                Center(
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
                                      onPressed: () => _controller.play(),
                                      icon: Icon(Icons.pause, color: Colors.white.withOpacity(0.5), size: 40)),
                            ),
                          );
                        })),
                Positioned(
                  top: 40,
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
                ),
                Positioned(
                  bottom: 25,
                  right: 20,
                  left: 20,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 40.0,
                            height: 40.0,
                            decoration: BoxDecoration(
                              color: const Color(0xff7c94b6),
                              image: DecorationImage(
                                image: NetworkImage(AuthCntr.to.resLoginData.value.profilePath!),
                                fit: BoxFit.cover,
                              ),
                              borderRadius: const BorderRadius.all(Radius.circular(50.0)),
                              border: Border.all(
                                color: Colors.green,
                                width: 2.0,
                              ),
                            ),
                          ),
                          const Gap(15),
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '이문세',
                                style: TextStyle(fontSize: 14, color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                              Text(
                                '2024.03.03 · 서울시 서대문구',
                                style: TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w600),
                              )
                            ],
                          ),
                          const SizedBox(width: 35, height: 35, child: VerticalDivider(thickness: 1, color: Colors.white)),
                          const Text(
                            '흐림',
                            style: TextStyle(fontSize: 13, color: Colors.white, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      const Gap(15),
                      SizedBox(
                        width: 200,
                        child: Marquee(
                          //scrollAxis: Axis.horizontal,
                          textDirection: TextDirection.rtl,
                          animationDuration: const Duration(seconds: 1),
                          backDuration: const Duration(milliseconds: 5000),
                          pauseDuration: const Duration(milliseconds: 1500),
                          directionMarguee: DirectionMarguee.TwoDirection,
                          child: const Row(
                            children: [
                              Text(
                                'This project is a starting point for a Dart package',
                                style: TextStyle(fontSize: 13, color: Colors.white, fontWeight: FontWeight.w600),
                              ),
                              Gap(10),
                              Icon(Icons.music_note, color: Colors.red, size: 15),
                            ],
                          ),
                        ),
                      )
                    ],
                  ),
                ),
                Positioned(
                  bottom: 20,
                  right: 10,
                  child: Column(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.favorite_border, color: Colors.white),
                        onPressed: () {},
                      ),
                      const Text(
                        '1.2M',
                        style: TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w600),
                      ),
                      const Gap(10),
                      IconButton(
                        icon: const Icon(Icons.message_outlined, color: Colors.white),
                        onPressed: () {},
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
                        onPressed: () {},
                      ),
                    ],
                  ),
                ),
                Positioned(
                  right: 10,
                  top: _controller.value.size.height / 2,
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
                ),
                Positioned(
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
                              duration: Duration(milliseconds: value == 0.0 ? 250 : 1000),
                              height: 2,
                              width: (MediaQuery.of(context).size.width) * (value / 100),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(4),
                                // color: const Color.fromRGBO(215, 215, 215, 1),
                                // color: const Color.fromRGBO(215, 215, 215, 1),
                                color: const Color.fromARGB(255, 110, 186, 111),
                                // color: const Color.fromARGB(255, 38, 162, 40),
                                // color: Color.fromARGB(255, 34, 112, 26),
                                // color: Color.fromARGB(255, 13, 104, 43),
                              ),
                            ),
                          ],
                        );
                      }),
                  // child:
                  //     VideoProgressIndicator(_controller, allowScrubbing: true),
                ),
              ],
            )
          : Center(child: Utils.progressbar()),
    );
  }
}
