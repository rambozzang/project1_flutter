import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
// import 'package:marquee_widget/marquee_widget.dart';

import 'package:preload_page_view/preload_page_view.dart';
import 'package:project1/app/camera/bloc/camera_bloc.dart';
import 'package:project1/app/camera/list_tictok/VideoUrl.dart';
import 'package:project1/app/camera/list_tictok/api_service.dart';
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
  late VideoPlayerController _videoController;
  final ValueNotifier<bool> isLoading = ValueNotifier<bool>(false);
  final PreloadPageController _controller = PreloadPageController();

  final ValueNotifier<String> localName = ValueNotifier<String>('');

  final ValueNotifier<CurrentWeather?> currentWeather =
      ValueNotifier<CurrentWeather?>(null);

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

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return Utils.alert('Location permissions are denied');
      }
    }

    getDate();
  }

  Future<void> getDate() async {
    isLoading.value = false;
    try {
      urls = await ApiService.getVideos();

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
    isLoading.value = true;
  }

  void goRecord() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => BlocProvider(
          create: (context) {
            return CameraBloc(
              cameraUtils: CameraUtils(),
              permissionUtils: PermissionUtils(),
            )..add(const CameraInitialize(recordingLimit: 15));
          },
          child: const CameraPage(),
        ),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      resizeToAvoidBottomInset: true,
      body: Stack(
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
                          return VideoUrl(
                            videoUrl: urls[i],
                          );
                        })
                    : Utils.progressbar();
              }),
          buildLocalName(),
          buildTemp(),
          buildRecodeBtn()
        ],
      ),
    );
  }

  // 현재 온도
  Widget buildTemp() {
    return ValueListenableBuilder<CurrentWeather?>(
        valueListenable: currentWeather,
        builder: (context, value, child) {
          if (value == null) {
            return const SizedBox();
          }
          return Positioned(
            top: 75,
            right: 10,
            left: 10,
            child: Container(
              // height: 120,
              // color: Colors.red,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 60,
                        height: 60,
                        child: Image.network(
                          'http://openweathermap.org/img/wn/${value.weather![0].icon}@2x.png',
                          // 'http://openweathermap.org/img/w/${value.weather![0].icon}.png',
                          scale: 1,
                          fit: BoxFit.contain,
                        ),
                      ),
                      TextScroll(
                        // ${value.weather![0].description.toString()} /
                        '${value.main!.temp.toString()}° ·  ${OpenWheatherRepo().weatherDescKo[value.weather![0].id]}',
                        mode: TextScrollMode.endless,
                        numberOfReps: 200,
                        fadedBorder: true,
                        delayBefore: const Duration(milliseconds: 4000),
                        pauseBetween: const Duration(milliseconds: 2000),
                        velocity:
                            const Velocity(pixelsPerSecond: Offset(100, 0)),
                        style:
                            const TextStyle(fontSize: 14, color: Colors.white),
                        textAlign: TextAlign.right,
                        selectable: true,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        });
  }

  // 동네 이름
  Widget buildLocalName() {
    return ValueListenableBuilder<String>(
        valueListenable: localName,
        builder: (context, value, child) {
          return Positioned(
            top: 55,
            right: 10,
            left: 10,
            child: Center(
              child: SizedBox(
                  width: 200,
                  child: TextScroll(
                    value.toString(),
                    mode: TextScrollMode.endless,
                    numberOfReps: 200,
                    fadedBorder: true,
                    delayBefore: const Duration(milliseconds: 4000),
                    pauseBetween: const Duration(milliseconds: 2000),
                    velocity: const Velocity(pixelsPerSecond: Offset(100, 0)),
                    style: const TextStyle(fontSize: 16, color: Colors.white),
                    textAlign: TextAlign.right,
                    selectable: true,
                  )),
            ),
          );
        });
  }

  // 촬영 하기
  Widget buildRecodeBtn() {
    return Positioned(
      top: 45,
      right: 10,
      child: SizedBox(
          width: 30,
          child: IconButton(
            icon: const Icon(
              Icons.add,
              color: Colors.white,
              size: 20,
            ),
            onPressed: () => goRecord(),
          )),
    );
  }
}
