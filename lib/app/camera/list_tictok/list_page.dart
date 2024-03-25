import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';

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
import 'package:project1/repo/weather/open_weather_repo.dart';
import 'package:project1/utils/log_utils.dart';
import 'package:project1/utils/utils.dart';
import 'package:project1/widget/custom2_button.dart';
import 'package:project1/widget/custom_button.dart';
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

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    permissionLocation();

    // getDate();
  }

  void permissionLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Utils.alert('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
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

  getDate() async {
    isLoading.value = false;
    urls = await ApiService.getVideos();

    try {
      OpenWheatherRepo repo = OpenWheatherRepo();
      ResData resData = await repo.getWeather();
      if (resData.code != '00') {
        Utils.alert(resData.msg.toString());
        return;
      }
      Lo.g('getDate() resData : ' + resData.data.toString());

      // WeatherData weatherData = WeatherData.fromJson(resData.toString());
      CurrentWeather currentWeather = CurrentWeather.fromJson(jsonEncode(resData.data.toString()));

      Lo.g('weatherData : ${currentWeather.toString()}');
      Utils.alert('날씨 가져오기 성공');
      return;
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
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            ValueListenableBuilder<bool>(
                valueListenable: isLoading,
                builder: (context, value, child) {
                  return value
                      // ? PageView.builder(
                      //     allowImplicitScrolling: true,
                      //     controller: PageController(viewportFraction: 0.999),
                      //     itemCount: urls.length,
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
            Positioned(
              top: 5,
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
                  )
                  // child: CustomButton(
                  //     listColors: [const Color.fromARGB(255, 251, 250, 250), const Color.fromARGB(255, 226, 226, 226)],
                  //     text: '+',
                  //     type: 'S',
                  //     onPressed: () => goRecord()),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
