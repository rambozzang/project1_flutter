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
import 'package:project1/repo/weather/mylocator_repo.dart';
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
    super.initState();
    permissionLocation();

    // getDate();
  }

  Future<void> permissionLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Utils.alert('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
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

      // 좌료를 통해 날씨 정보 가져오기
      ResData resData = await repo.getWeather(position!);

      if (resData.code != '00') {
        Utils.alert(resData.msg.toString());
        return;
      }
      Lo.g('getDate() resData : ${resData.data}');
      CurrentWeather currentWeather = CurrentWeather.fromMap(resData.data);
      Lo.g('weatherData : ${currentWeather.toString()}');
      Utils.alert('날씨 가져오기 성공');

      // 좌료를 통해 동네이름 가져오기
      ResData resData2 = await myLocatorRepo.getLocationName(position);
      if (resData2.code != '00') {
        Utils.alert(resData2.msg.toString());
        return;
      }
      Lo.g('동네이름() resData2 : ${resData2.data}');
    } catch (e) {
      Lo.g('getDate() error : ' + e.toString());
    }
    isLoading.value = true;
  }

  // https://www.data.go.kr/data/15101106/openapi.do?recommendDataYn=Y
  // 7C166CC8-B88A-3DD1-816A-FF86922C17AF
  // https://api.vworld.kr/req/address?service=address&request=getcoord&version=2.0&crs=epsg:4326&address=%ED%9A%A8%EB%A0%B9%EB%A1%9C72%EA%B8%B8%2060&refine=true&simple=false&format=xml&type=road&key=[KEY]

  // Future<dynamic> getPlaceAddress({double lat = 0.0, double lng = 0.0}) async {
  // final url =
  //     'https://maps.googleapis.com/maps/api/geocode/json?latlng=$lat,$lng&key=$GOOGLE_API_KEY&language=ko';
  // http.Response response = await http.get(Uri.parse(url));

  //     return jsonDecode(response.body)['results'][0]['address_components'][1]
  //         ['long_name'];
  //   }

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
            buildRecodeBtn()
          ],
        ),
      ),
    );
  }

  Widget buildRecodeBtn() {
    return Positioned(
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
          )),
    );
  }
}
