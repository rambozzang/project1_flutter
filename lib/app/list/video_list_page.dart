import 'dart:async';
import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:comment_sheet/comment_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';

import 'package:preload_page_view/preload_page_view.dart';
import 'package:project1/app/auth/cntr/auth_cntr.dart';
import 'package:project1/app/camera/bloc/camera_bloc.dart';
import 'package:project1/app/list/Video_screen_page.dart';
import 'package:project1/app/list/api_service.dart';
import 'package:project1/app/list/comment_page.dart';
import 'package:project1/app/list/test_grabin_widget.dart';
import 'package:project1/app/list/test_list_item_widget.dart';
import 'package:project1/app/camera/page/camera_page.dart';
import 'package:project1/app/camera/utils/camera_utils.dart';
import 'package:project1/app/camera/utils/permission_utils.dart';
import 'package:project1/repo/board/board_repo.dart';
import 'package:project1/repo/board/data/board_list_data.dart';
import 'package:project1/repo/common/res_data.dart';
import 'package:project1/repo/common/res_stream.dart';
import 'package:project1/repo/weather/data/current_weather.dart';
import 'package:project1/repo/weather/mylocator_repo.dart';
import 'package:project1/repo/weather/open_weather_repo.dart';
import 'package:project1/utils/log_utils.dart';
import 'package:project1/utils/utils.dart';
import 'package:text_scroll/text_scroll.dart';

class ListPage extends StatefulWidget {
  const ListPage({super.key});

  @override
  State<ListPage> createState() => _ListPageState();
}

class _ListPageState extends State<ListPage> {
  late List<String> urls;
  //late VideoPlayerController _videoController;

  final PreloadPageController _controller = PreloadPageController();
  final ValueNotifier<String> localName = ValueNotifier<String>('');
  final ValueNotifier<CurrentWeather?> currentWeather = ValueNotifier<CurrentWeather?>(null);
  //
  final CommentSheetController commentSheetController = CommentSheetController();
  ScrollController scrollController = ScrollController();

  // 댓글 입력창
  TextEditingController replyController = TextEditingController();
  FocusNode replyFocusNode = FocusNode();

  // 동영상을 담은 리스트
  late List<BoardListData> list = [];
  //final ValueNotifier<List<BoardListData>> list = ValueNotifier<List<BoardListData>>([]);

  final StreamController<ResStream<List<BoardListData>>> streamController = StreamController();

  // 현재 위치
  late Position? position;
  int pageNum = 0;
  int pagesize = 5;

  bool isLoadingMore = true;

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

    getData();
  }

  // 참고 싸이트 : https://github.com/octomato/preload_page_view/issues/43
  Future<void> getMoreData(int index, int length) async {
    final isBottom = index > length - 3;
    // if (isBottom && !postCubit.state.hasReachedMax && !postCubit.state.isLoading) {
    //    getAllPost();
    // }
    if (!isBottom) {
      return;
    }

    pageNum++;

    BoardRepo boardRepo = BoardRepo();
    ResData resListData = await boardRepo.list(position!.latitude.toString(), position!.longitude.toString(), pageNum, pagesize);

    if (resListData.code != '00') {
      Utils.alert(resListData.msg.toString());
      return;
    }
    List<BoardListData> _list = ((resListData.data) as List).map((data) => BoardListData.fromMap(data)).toList();
    list.addAll(_list);
    streamController.sink.add(ResStream.completed(list));
  }

  Future<void> getData() async {
    try {
      streamController.sink.add(ResStream.loading());

      // 위치 좌표 가져오기
      MyLocatorRepo myLocatorRepo = MyLocatorRepo();
      position = await myLocatorRepo.getCurrentLocation();

      //  urls = await ApiService.getVideos();
      BoardRepo boardRepo = BoardRepo();
      ResData resListData = await boardRepo.list(position!.latitude.toString(), position!.longitude.toString(), pageNum, pagesize);

      if (resListData.code != '00') {
        Utils.alert(resListData.msg.toString());
        return;
      }
      list = ((resListData.data) as List).map((data) => BoardListData.fromMap(data)).toList();
      streamController.sink.add(ResStream.completed(list));

      //  urls = resListData.data['data'];
      // Lo.g('getDate() urls : $urls');

      OpenWheatherRepo repo = OpenWheatherRepo();

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
      ResData resData2 = await myLocatorRepo.getLocationName(position!);
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
    // Get.toNamed('/TestPage');
    // return;
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
                    Utils.commonStreamList<BoardListData>(streamController, buildVideoBody, getData),

                    // ValueListenableBuilder<List<BoardListData>>(
                    //     valueListenable: list,
                    //     builder: (context, value, child) {
                    //       return value
                    //           ? PreloadPageView.builder(
                    //               controller: _controller,
                    //               preloadPagesCount: 4,
                    //               scrollDirection: Axis.vertical,
                    //               itemCount: list.length,
                    //               itemBuilder: (context, i) {
                    //                 currentIndex = i;
                    //                 return VideoSreenPage(data: list[i]);
                    //               })
                    //           : Utils.progressbar();
                    //     }),
                    buildLocalName(),
                    buildTemp(),
                    buildRecodeBtn(),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget buildVideoBody(List<BoardListData> data) {
    return PreloadPageView.builder(
        controller: _controller,
        preloadPagesCount: 3,
        scrollDirection: Axis.vertical,
        itemCount: data.length,
        physics: const AlwaysScrollableScrollPhysics(),
        onPageChanged: (int position) {
          print('page changed. current: $position');
          getMoreData(position, data.length);
        },
        itemBuilder: (context, i) {
          if (isLoadingMore && position == data.length) {
            return Utils.progressbar();
          }
          return VideoSreenPage(data: data[i]);
        });
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
            top: 80,
            right: 10,
            left: 10,
            child: Container(
              //     height: 98,
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
                      Text(
                        '최저 ${value.main!.temp_min?.toStringAsFixed(1)}° · 최고 ${value.main!.temp_max?.toStringAsFixed(1)}°',
                        style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w600),
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
            top: 45,
            left: 3,
            child: Container(
                //  width: 240,
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Row(
                  children: [
                    Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: const Icon(Icons.location_on, color: Colors.white, size: 15)),
                    const SizedBox(width: 5),
                    SizedBox(
                      width: 200,
                      child: TextScroll(
                        value.toString(),
                        mode: TextScrollMode.endless,
                        numberOfReps: 20000,
                        fadedBorder: true,
                        delayBefore: const Duration(milliseconds: 4000),
                        pauseBetween: const Duration(milliseconds: 2000),
                        velocity: const Velocity(pixelsPerSecond: Offset(100, 0)),
                        style: const TextStyle(fontSize: 13, color: Colors.white, fontWeight: FontWeight.w500),
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
}
