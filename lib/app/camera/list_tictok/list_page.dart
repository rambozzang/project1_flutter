import 'dart:convert';
import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:comment_sheet/comment_sheet.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get_connect/http/src/utils/utils.dart';
// import 'package:marquee_widget/marquee_widget.dart';

import 'package:preload_page_view/preload_page_view.dart';
import 'package:project1/app/camera/bloc/camera_bloc.dart';
import 'package:project1/app/camera/list_tictok/VideoUrl.dart';
import 'package:project1/app/camera/list_tictok/api_service.dart';
import 'package:project1/app/camera/list_tictok/test_grabin_widget.dart';
import 'package:project1/app/camera/list_tictok/test_list_item_widget.dart';
import 'package:project1/app/camera/page/camera_page.dart';
import 'package:project1/app/camera/utils/camera_utils.dart';
import 'package:project1/app/camera/utils/permission_utils.dart';
import 'package:project1/repo/common/res_data.dart';
import 'package:project1/repo/weather/data/current_weather.dart';
import 'package:project1/repo/weather/data/weather_data.dart';
import 'package:project1/repo/weather/mylocator_repo.dart';
import 'package:project1/repo/weather/open_weather_repo.dart';
import 'package:project1/utils/log_utils.dart';
import 'package:project1/utils/utils.dart';
import 'package:project1/widget/custom2_button.dart';
import 'package:project1/widget/custom_button.dart';
import 'package:text_scroll/text_scroll.dart';
import 'package:video_player/video_player.dart';

class ListPage extends StatefulWidget {
  const ListPage({super.key});

  @override
  State<ListPage> createState() => _ListPageState();
}

class _ListPageState extends State<ListPage> {
  late List<String> urls;
  //late VideoPlayerController _videoController;

  final ValueNotifier<bool> isLoading = ValueNotifier<bool>(false);
  final PreloadPageController _controller = PreloadPageController();
  final ValueNotifier<String> localName = ValueNotifier<String>('');
  final ValueNotifier<CurrentWeather?> currentWeather = ValueNotifier<CurrentWeather?>(null);
  //
  final CommentSheetController commentSheetController = CommentSheetController();
  ScrollController scrollController = ScrollController();

  // 댓글 입력창
  TextEditingController replyController = TextEditingController();
  FocusNode replyFocusNode = FocusNode();

  //현재 영상의 index값 저장
  int currentIndex = 0;

  @override
  void initState() {
    super.initState();
    permissionLocation();

    // getDate();
  }

  Future<void> permissionLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Utils.alert('Location services are disabled.');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    lo.g(permission.toString());

    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        return Utils.alert('Location permissions are denied');
      }
    }

    getDate();
  }

  Future<void> getDate() async {
    isLoading.value = false;
    try {
      urls = await ApiService.getVideos();

      isLoading.value = true;

      OpenWheatherRepo repo = OpenWheatherRepo();

      // 위치 좌표 가져오기
      MyLocatorRepo myLocatorRepo = MyLocatorRepo();
      Position? position = await myLocatorRepo.getCurrentLocation();
      // Utils.alert('좌표 가져오기 성공');

      // 좌료를 통해 날씨 정보 가져오기
      ResData resData = await repo.getWeather(position!);

      if (resData.code != '00') {
        Utils.alert(resData.msg.toString());
        return;
      }
      Lo.g('getDate() resData : ${resData.data}');
      currentWeather.value = CurrentWeather.fromMap(resData.data);
      Lo.g('weatherData : ${currentWeather.toString()}');
      //Utils.alert('날씨 가져오기 성공');

      // 좌료를 통해 동네이름 가져오기
      ResData resData2 = await myLocatorRepo.getLocationName(position);
      if (resData2.code != '00') {
        Utils.alert(resData2.msg.toString());
        return;
      }
      // Utils.alert('동네이름 가져오기 성공');
      Lo.g('동네이름() resData2 : ${resData2.data['ADDR']}');
      localName.value = resData2.data['ADDR'];

      // Google 동네이름 가져오기
      // ResData resData3 = await myLocatorRepo.getPlaceAddress(position);
      // if (resData2.code != '00') {
      //   Utils.alert(resData3.msg.toString());
      //   return;
      // }
      // Utils.alert('동네이름 가져오기 성공');
      // Lo.g('동네이름() resData3 : ${resData3.data['results'][0]['address_components'][1]['long_name']}');
      // localName.value = resData3.data['results'][0]['address_components'][1]['long_name'];
    } catch (e) {
      Lo.g('getDate() error : ' + e.toString());
    }
  }

  void goRecord() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => BlocProvider(
          create: (context) {
            return CameraBloc(
              cameraUtils: CameraUtils(),
              permissionUtils: PermissionUtils(),
              currentWeather: currentWeather.value!,
            )..add(const CameraInitialize(recordingLimit: 15));
          },
          child: const CameraPage(),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    scrollController.dispose();
    replyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      resizeToAvoidBottomInset: true,
      body: Builder(
        builder: (context) {
          return CustomScrollView(
            physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
            slivers: [
              LoadingCupertinoSliverRefreshControl(
                onRefresh: () async {
                  await Future.delayed(const Duration(seconds: 3));
                },
              ),
              SliverFillRemaining(
                child: Stack(
                  children: [
                    ValueListenableBuilder<bool>(
                        valueListenable: isLoading,
                        builder: (context, value, child) {
                          return value
                              ? PreloadPageView.builder(
                                  controller: _controller,
                                  preloadPagesCount: 4,
                                  scrollDirection: Axis.vertical,
                                  itemCount: urls.length,
                                  itemBuilder: (context, i) {
                                    currentIndex = i;
                                    return VideoUrl(
                                      videoUrl: urls[i],
                                    );
                                  })
                              : Utils.progressbar();
                        }),
                    buildLocalName(),
                    buildTemp(),
                    buildRecodeBtn(),
                    Positioned(
                      bottom: 140,
                      right: 10,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          // 투명하게
                          shadowColor: Colors.transparent,
                          backgroundColor: Colors.transparent,
                          // padding: const EdgeInsets.all(1.0),
                          // shape: RoundedRectangleBorder(
                          //   borderRadius: BorderRadius.circular(15.0),
                          // ),
                        ),
                        onPressed: () {
                          openSheet(context);
                        },
                        child: const SizedBox(
                          width: 40,
                          height: 40,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // 상단 현재 온도
  Widget buildTemp() {
    return ValueListenableBuilder<CurrentWeather?>(
        valueListenable: currentWeather,
        builder: (context, value, child) {
          if (value == null) {
            return const SizedBox();
          }
          return Positioned(
            top: 84,
            right: 10,
            left: 10,
            child: Container(
              height: 98,
              width: double.infinity,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      // const Text(
                      //   '현재',
                      //   style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
                      // ),
                      Text(
                        value.weather![0].description.toString(),
                        style: const TextStyle(fontSize: 14, color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      Row(
                        //  crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${value.main!.temp?.toStringAsFixed(1)}°',
                            textAlign: TextAlign.right,
                            style: const TextStyle(fontSize: 25, color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                          CachedNetworkImage(
                            width: 50,
                            height: 50,
                            // color: Colors.white,
                            imageUrl: 'http://openweathermap.org/img/wn/${value.weather![0].icon}@2x.png',
                            //   imageUrl:  'http://openweathermap.org/img/w/${value.weather![0].icon}.png',
                            imageBuilder: (context, imageProvider) => Container(
                              decoration: BoxDecoration(
                                image: DecorationImage(
                                    image: imageProvider,
                                    fit: BoxFit.cover,
                                    colorFilter: const ColorFilter.mode(Colors.transparent, BlendMode.colorBurn)),
                              ),
                            ),
                            placeholder: (context, url) => const CircularProgressIndicator(strokeWidth: 1, color: Colors.white),
                            errorWidget: (context, url, error) => const Icon(Icons.error),
                          ),
                          // Image.network(
                          //     width: 50,
                          //     height: 50,
                          //     'http://openweathermap.org/img/wn/${value.weather![0].icon}@2x.png',
                          //     //'http://openweathermap.org/img/w/${value.weather![0].icon}.png',
                          //     scale: 1,
                          //     fit: BoxFit.contain,
                          //     alignment: Alignment.topCenter),
                        ],
                      ),
                      Text(
                        '체감온도 ${value.main!.feels_like?.toStringAsFixed(1)}°',
                        style: const TextStyle(fontSize: 14, color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  SizedBox(
                    width: Get.width * 0.5,
                    // child: Column(
                    //   crossAxisAlignment: CrossAxisAlignment.end,
                    //   children: [
                    //     Text(
                    //       ' ${value.weather![0].description.toString()}',
                    //       style: const TextStyle(
                    //           fontSize: 15,
                    //           color: Colors.white,
                    //           fontWeight: FontWeight.bold),
                    //     ),
                    //     Text(
                    //       ' ${OpenWheatherRepo().weatherDescKo[value.weather![0].id]}',
                    //       style: const TextStyle(
                    //           fontSize: 16,
                    //           color: Colors.white,
                    //           fontWeight: FontWeight.bold),
                    //     ),
                    //     Text(
                    //       '습도:  ${value.main!.humidity.toString()}%',
                    //       style: const TextStyle(
                    //           fontSize: 15,
                    //           color: Colors.white,
                    //           fontWeight: FontWeight.bold),
                    //     ),
                    //     Text(
                    //       '풍속:  ${value.wind!.speed.toString()}km/h',
                    //       style: const TextStyle(
                    //           fontSize: 15,
                    //           color: Colors.white,
                    //           fontWeight: FontWeight.bold),
                    //     ),
                    //   ],
                    // ),
                  ),
                ],
              ),
            ),
          );
        });
  }

  // 상단 동네 이름
  Widget buildLocalName() {
    return ValueListenableBuilder<String>(
        valueListenable: localName,
        builder: (context, value, child) {
          return Positioned(
            top: 50,
            left: 3,
            child: Container(
                width: 200,
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.location_on, color: Colors.white, size: 20),
                    SizedBox(
                      width: 170,
                      child: TextScroll(
                        value.toString(),
                        mode: TextScrollMode.endless,
                        numberOfReps: 200,
                        fadedBorder: true,
                        delayBefore: const Duration(milliseconds: 4000),
                        pauseBetween: const Duration(milliseconds: 2000),
                        velocity: const Velocity(pixelsPerSecond: Offset(100, 0)),
                        style: const TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.w500),
                        textAlign: TextAlign.right,
                        selectable: true,
                      ),
                    ),
                  ],
                )),
          );
        });
  }

  // 상단 촬영 하기
  Widget buildRecodeBtn() {
    return Positioned(
      top: 35,
      right: 10,
      child: SizedBox(
          width: 40,
          child: IconButton(
            icon: const Icon(
              Icons.add,
              color: Colors.white,
              size: 30,
            ),
            onPressed: () => goRecord(),
          )),
    );
  }

  void openSheet(context) {
    replyController.clear();
    showBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return CommentSheet(
          slivers: [
            // 댓글 리스트
            buildSliverList(),
          ],
          grabbingPosition: WidgetPosition.above,
          initTopPosition: 200,
          calculateTopPosition: calculateTopPosition,
          scrollController: scrollController,
          grabbing: Builder(builder: (context) {
            // 댓글 상단바
            return buildGrabbing(context);
          }),
          topWidget: (info) {
            // 실제 줄어드는 위젯 위치
            return Positioned(top: 0, left: 0, right: 0, height: max(0, info.currentTop), child: const SizedBox.shrink()
                // child: const Placeholder(
                //   color: Colors.red,
                // ),
                // child: AspectRatio(
                //   aspectRatio: 9 / 16,
                //   child: ClipRRect(
                //     borderRadius: BorderRadius.circular(15),
                //     child: VideoUrl(
                //       videoUrl: urls[currentIndex],
                //     ),
                //   ),
                // ),
                );
          },
          topPosition: WidgetPosition.below,
          bottomWidget: buildBottomWidget(),
          onPointerUp: (
            BuildContext context,
            CommentSheetInfo info,
          ) {
            // print("On Pointer Up");
          },
          onAnimationComplete: (
            BuildContext context,
            CommentSheetInfo info,
          ) {
            // print("onAnimationComplete");
            if (info.currentTop >= info.size.maxHeight - 100) {
              Navigator.of(context).pop();
            }
          },
          commentSheetController: commentSheetController,
          onTopChanged: (top) {
            // print("top: $top");
          },
          // 백그라운드 위젯
          // child: const Placeholder(),
          child: const SizedBox.expand(),
          backgroundBuilder: (context) {
            return Container(
              color: const Color(0xFF0F0F0F),
              margin: const EdgeInsets.only(top: 10),
            );
          },
        );
      },
    );
  }

  double calculateTopPosition(CommentSheetInfo info) {
    final vy = info.velocity.getVelocity().pixelsPerSecond.dy;
    final top = info.currentTop;
    double p0 = 0;
    double p1 = 200;
    double p2 = info.size.maxHeight - 100;

    if (top > p1) {
      if (vy > 0) {
        if (info.isAnimating && info.animatingTarget == p1 && top < p1 + 10) {
          return p1;
        } else {
          return p2;
        }
      } else {
        return p1;
      }
    } else if (top == p1) {
      return p1;
    } else if (top == p0) {
      return p0;
    } else {
      if (vy > 0) {
        if (info.isAnimating && info.animatingTarget == p0 && top < p0 + 10) {
          return p0;
        } else {
          return p1;
        }
      } else {
        return p0;
      }
    }
  }

  // 댓글 상단바
  Widget buildGrabbing(BuildContext context) {
    return const GrabbingWidget();
  }

  // 댓글 리스트
  Widget buildSliverList() {
    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        return ListItemWidget(controller: replyController, focus: replyFocusNode);
      }, childCount: 20),
    );
  }

  // 댓글 입력창

  Widget buildBottomWidget() {
    return Container(
      color: Colors.transparent,
      height: 63,
      padding: const EdgeInsets.only(left: 5, right: 5),
      child: TextFormField(
        keyboardType: TextInputType.text,
        controller: replyController,
        focusNode: replyFocusNode,
        style: const TextStyle(color: Colors.white, decorationThickness: 0),
        decoration: const InputDecoration(
          hintText: '댓글을 입력해주세요',
          hintStyle: TextStyle(color: Colors.white),
          isDense: true,
          prefixIconConstraints: BoxConstraints(minWidth: 23, maxHeight: 20),
          prefixIcon: Padding(
            padding: EdgeInsets.only(left: 10, right: 10),
            child: Icon(
              Icons.emoji_emotions_outlined,
              color: Colors.white,
            ),
          ),
          suffixIconConstraints: BoxConstraints(minWidth: 23, maxHeight: 20),
          suffixIcon: Padding(
            padding: EdgeInsets.only(left: 10, right: 10),
            child: Icon(
              Icons.send,
              color: Colors.white,
            ),
          ),
          border: InputBorder.none,
          //border: OutlineInputBorder(),
          contentPadding: EdgeInsets.only(left: 10, bottom: 15, top: 15),
        ),
      ),
    );
  }
}
