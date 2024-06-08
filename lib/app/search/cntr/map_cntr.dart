import 'dart:async';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:flutter_svg/svg.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';
import 'package:project1/app/list/cntr/video_list_cntr.dart';
import 'package:project1/repo/cctv/cctv_repo.dart';
import 'package:project1/repo/cctv/data/cctv_res_data.dart';
import 'package:project1/repo/weather/mylocator_repo.dart';
import 'package:project1/utils/log_utils.dart';
import 'package:project1/utils/utils.dart';

class MapBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<MapCntr>(() => MapCntr());
  }
}

class MapCntr extends GetxController {
  final isInit = false.obs;
  late NaverMapController mapController;
  late Position? position;
  final onCameraChangeStreamController = StreamController<NCameraUpdateReason>.broadcast();

  @override
  void onInit() {
    super.onInit();
    init();
  }

  void init() async {
    await NaverMapSdk.instance.initialize(
        clientId: 'oqpkzdp38l',
        onAuthFailed: (ex) {
          Lo.g("********* 네이버맵 인증오류 : $ex *********");
        });
    isInit.value = true;
  }

  // 만약 위치 이동시 마다 이벤트를 받고 싶다면 아래와 같이 사용
  // https://github.com/note11g/flutter_naver_map/issues/100
  Future<void> getLocation() async {
    // 위치 좌표 가져오기
    MyLocatorRepo myLocatorRepo = MyLocatorRepo();
    position = await myLocatorRepo.getCurrentLocation();
    // 카메라 포지션
    locationUpdate(currentCoord: NLatLng(position!.latitude, position!.longitude));
  }

  Future<void> locationUpdate({required NLatLng currentCoord}) async {
    final locationOverlay = await mapController?.getLocationOverlay();
    const iconImage = NOverlayImage.fromAssetImage('assets/images/map/default_pin.png');
    locationOverlay
      ?..setIcon(iconImage)
      ..setIconSize(const Size.fromRadius(40))
      ..setCircleRadius(100.0)
      ..setCircleColor(Colors.grey.withOpacity(0.17))
      ..setPosition(currentCoord)
      ..setIsVisible(true);

    final cameraUpdate = NCameraUpdate.withParams(target: currentCoord)
      ..setAnimation(animation: NCameraAnimation.linear, duration: const Duration(milliseconds: 500)); // 2초는 너무 길 수도 있어요.
    await mapController.updateCamera(cameraUpdate);
  }
  // void markerClick(NaverMapController controller, Marker marker) {
  //   Lo.g("마커 클릭됨! : ${marker.captionText}");
  // }

  Future<void> buildMarker111(BuildContext context) async {
    Size size = const Size(40, 40);
    const iconImage1 = NOverlayImage.fromAssetImage('assets/images/map/fog.png');
    const iconImage2 = NOverlayImage.fromAssetImage('assets/images/map/rain.png');
    const iconImage3 = NOverlayImage.fromAssetImage('assets/images/map/sun1.png');

    Get.find<VideoListCntr>().list.forEach((element) async {
      // final NOverlayImage icon = await buildMarket(size, element, context);
      final NOverlayImage icon = NOverlayImage.fromAssetImage('assets/images/map/blue_pin.png');

      final marker = NMarker(
        id: element.boardId.toString(),
        position: NLatLng(double.parse(element.lat.toString()), double.parse(element.lon.toString())),
        icon: icon,
        size: size,
        captionOffset: 0,
      );
      mapController.addOverlay(marker);
      final onMarkerInfoWindow = NInfoWindow.onMarker(id: marker.info.id, text: "${element.currentTemp}°");
      marker.openInfoWindow(onMarkerInfoWindow);
      marker.setOnTapListener((overlay) async {
        // 마커 클릭 시 이벤트 정의
        //HapticFeedback.selectionClick();

        Utils.alert("마커 클릭됨! : ${overlay.toString()}");
      });
    });
  }

  Future<NOverlayImage> buildMarket(size, element, context) {
    return NOverlayImage.fromWidget(
      size: size,
      context: context!,
      widget: Column(
        children: [
          Container(
            width: size.width,
            height: size.height,
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(20),
              image: const DecorationImage(
                image: AssetImage('assets/images/map/blue_pin.png'),
                fit: BoxFit.fill,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  '${element.weatherInfo}',
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Row(
                  children: [
                    makeMarkerIcon(element.weatherInfo),
                    // Image.asset('assets/images/map/fog.png', width: 30, height: 30),
                    Text(
                      '${element.currentTemp}°',
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget makeMarkerIcon(String weather) {
    switch (weather) {
      case '맑음':
        return const Icon(Icons.wb_sunny, color: Colors.yellow);
      case '비':
        return const Icon(Icons.beach_access, color: Colors.blue);
      case '눈':
        return const Icon(Icons.ac_unit, color: Colors.white);
      case '흐림':
        return const Icon(Icons.cloud, color: Colors.grey);
      case '안개':
        return const Icon(Icons.cloud_queue, color: Colors.grey);
      case '번개':
        return const Icon(Icons.flash_on, color: Colors.yellow);
      default:
        return const Icon(Icons.wb_sunny, color: Colors.yellow);
    }
  }

  // Future<void> _setCustomMarkerIcon( BuildContext context, Position position) async {
  //   // final directory = await getApplicationDocumentsDirectory();
  //   // final String profilePath =
  //   //     "${directory.path}/${widget.userName}_profile_image.png";

  //   // final directoryPath = Directory(directory.path);

  //   // if (await directoryPath.exists()) {
  //   //   directory.list().listen((file) {
  //   //     print(file.path);
  //   //   });
  //   // } else {
  //   //   print("디렉토리가 존재하지 않습니다.");
  //   // }

  //   final iconImage = NOverlayImage.fromFile(CachedNetworkImage(profilePath, imageUrl: '',));
  //   const subIcon =
  //       NOverlayImage.fromAssetImage('asset/images/map/subIcon.png');

  //   final locationOverlay = await mapController!.getLocationOverlay();
  //   locationOverlay.setIcon(iconImage);
  //   locationOverlay.setIconSize(const Size.fromRadius(30));
  //   locationOverlay.setCircleRadius(50.0);
  //   locationOverlay.setCircleColor(Colors.yellow.withOpacity(0.3));

  //   // // TODO:: subIcon 구현
  //   locationOverlay.setSubIcon(subIcon);
  //   locationOverlay.setBearing(50.0);
  //   locationOverlay.setIsVisible(true);

  //   locationOverlay.setPosition(NLatLng(position.latitude, position.longitude));

  //   // 카메라 포지션 객체 생성
  //   NCameraPosition nCameraPosition = NCameraPosition(
  //     target: NLatLng(position.latitude, position.longitude),
  //     zoom: 17,
  //   );

  //   // 카메라 업데이트 객체 생성 및 애니메이션 설정
  //   NCameraUpdate.fromCameraPosition(nCameraPosition).setAnimation(
  //     animation: NCameraAnimation.linear,
  //     duration: const Duration(seconds: 2),
  //   );

  // }

  @override
  void onClose() {
    super.onClose();
  }
}
