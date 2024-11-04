import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';
import 'package:project1/app/weathergogo/cntr/weather_gogo_cntr.dart';
import 'package:project1/app/weathergogo/services/location_service.dart';
import 'package:project1/repo/board/board_repo.dart';
import 'package:project1/repo/board/data/board_weather_list_data.dart';
import 'package:project1/repo/common/res_data.dart';
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

  final Rx<Position?> position = Rx<Position?>(null);
  final onCameraChangeStreamController = StreamController<NCameraUpdateReason>.broadcast();

  final StreamController<List<BoardWeatherListData>> listItemsController = StreamController<List<BoardWeatherListData>>.broadcast();

  RxBool soundOn = false.obs;
  RxBool isLoading = false.obs;
  RxString addr1 = ''.obs;
  RxString addr2 = ''.obs;

  Rx<int> searchDay = 30.obs;
  late Rx<LatLng?> southWest = Rx<LatLng?>(null);
  late Rx<LatLng?> northEast = Rx<LatLng?>(null);

  List<BoardWeatherListData> listItems = [];
  RxBool isLoadingList = false.obs;

  int _page = 0;
  final int _limit = 100;
  bool isMore = true;
  bool isFirstCallParamLatLon = false;

  final Rx<double> initialLat = Rx<double>(0.0);
  final Rx<double> initialLon = Rx<double>(0.0);

  @override
  void onInit() {
    super.onInit();
    init();
  }

  void init() async {
    lo.g('init');

    await NaverMapSdk.instance.initialize(
        clientId: '1gvb59zfma',
        onAuthFailed: (ex) {
          Lo.g("********* 네이버맵 인증오류 : $ex *********");
          Utils.alert("네이버 지도 인증 실패 ClientID 확인해주세요~");
        });
    await getLocation();
    isInit.value = true;
  }

  Future<void> getLocation() async {
    if (isFirstCallParamLatLon) {
      // 주소가 넘어오는경우
      position.value = setPosition(initialLat.value, initialLon.value);
    } else {
      // 현재 위치 가져오기
      // MyLocatorRepo myLocatorRepo = MyLocatorRepo();
      // position.value = await myLocatorRepo.getCurrentLocation();
      final weatherGogoCntr = Get.find<WeatherGogoCntr>();
      double lat = weatherGogoCntr.currentLocation.value.latLng.latitude;
      double lon = weatherGogoCntr.currentLocation.value.latLng.longitude;
      position.value = setPosition(lat, lon);
    }

    // await locationUpdate(currentCoord: NLatLng(position.value!.latitude, position.value!.longitude));
  }

  // 화면에서 호출
  Future<List<BoardWeatherListData>> buildMarker(int sDay) async {
    try {
      isLoadingList.value = true;
      searchDay.value = sDay;
      isLoading.value = true;

      LatLng southWest1, northEast1;
      if (initialLat.value != 0.0 && initialLon.value != 0.0) {
        lo.g('111111 ');
        // 파라미터로 전달된 위치를 중심으로 10km 반경의 경계 계산
        final center = LatLng(initialLat.value, initialLon.value);
        const distance = Distance();
        const radius = 3000; // 5km in meters
        // Calculate southwest and northeast points
        southWest1 = distance.offset(center, radius * math.sqrt2, 225);
        northEast1 = distance.offset(center, radius * math.sqrt2, 45);
      } else {
        // 현재 지도 뷰의 경계 사용
        var bounds = await getbounds();
        southWest1 = bounds.$1;
        northEast1 = bounds.$2;
      }

      southWest.value = southWest1;
      northEast.value = northEast1;

      mapController.clearOverlays();

      BoardRepo boardRepo = BoardRepo();
      lo.g('sday $sDay');
      lo.g(' southWest.value ${southWest.value}');
      lo.g(' northEast.value ${northEast.value}');

      ResData resListData = await boardRepo.searchBoardListByMaplonlatAndDay(
        southWest.value!,
        northEast.value!,
        sDay,
        0,
        _limit,
      );
      if (resListData.code != '00') {
        Utils.alert(resListData.msg.toString());
        isLoadingList.value = false;
        return [];
      }

      List<BoardWeatherListData> list = ((resListData.data) as List).map((data) => BoardWeatherListData.fromMap(data)).toList();

      if (list.length != _limit) {
        isMore = false;
      }

      listItems = list;
      lo.g('listItems: ${listItems.length}');

      listItemsController.sink.add(list);

      try {
        LocationService locationService = LocationService();
        LatLng latLng = LatLng(position.value!.latitude, position.value!.longitude);
        final (onValue1, onValue2) = await locationService.getLocalName(latLng);
        addr1.value = onValue1!;
        addr2.value = onValue2!;
      } catch (e) {
        lo.g('동네 이름, 미세 먼지 정보 오류 $e');
      }

      isLoading.value = false;
      isLoadingList.value = false;
      isFirstCallParamLatLon = false;

      if (list.isEmpty) {
        Utils.alert('근처에 영상이 없습니다.');
      }
      return list;
    } catch (e) {
      lo.g('buildMarker 오류 $e');
      isLoading.value = false;
      isLoadingList.value = false;
      return [];
    }
  }

  Future<void> loadMoreItems() async {
    if (!isMore) return;

    try {
      var (southWest1, northEast1) = await getbounds();

      southWest.value = southWest1;
      northEast.value = northEast1;

      BoardRepo boardRepo = BoardRepo();
      ResData resListData = await boardRepo.searchBoardListByMaplonlatAndDay(
        southWest.value!,
        northEast.value!,
        searchDay.value,
        _page,
        _limit,
      );

      if (resListData.code == '00') {
        List<BoardWeatherListData> newItems = ((resListData.data) as List).map((data) => BoardWeatherListData.fromMap(data)).toList();

        if (newItems.length != _limit) {
          isMore = false;
        }

        listItems.addAll(newItems);
        _page++;

        listItemsController.sink.add(listItems);
      } else {
        Utils.alert(resListData.msg.toString());
      }
    } catch (e) {
      lo.g('loadMoreItems 오류 $e');
    }
  }

  Future<void> locationUpdate({required NLatLng currentCoord}) async {
    final locationOverlay = mapController.getLocationOverlay();
    locationOverlay
      ..setCircleRadius(100.0)
      ..setCircleColor(Colors.grey.withOpacity(0.17))
      ..setPosition(currentCoord)
      ..setIsVisible(true);

    position.value = setPosition(currentCoord.latitude, currentCoord.longitude);

    final cameraUpdate = NCameraUpdate.withParams(target: currentCoord)
      ..setAnimation(animation: NCameraAnimation.linear, duration: const Duration(milliseconds: 500));
    await mapController.updateCamera(cameraUpdate);
  }

  // 검색후 화면에서 호출
  Future<void> setPositionlocationUpdate({required NLatLng currentCoord}) async {
    position.value = Position(
      latitude: currentCoord.latitude,
      longitude: currentCoord.longitude,
      altitudeAccuracy: 0,
      headingAccuracy: 0,
      timestamp: DateTime.now(),
      accuracy: 0,
      altitude: 0,
      heading: 0,
      speed: 0,
      speedAccuracy: 0,
    );
    await locationUpdate(currentCoord: currentCoord);
  }

  Future<(LatLng, LatLng)> getbounds() async {
    final NLatLngBounds bounds = await mapController.getContentBounds().then((value) {
      return value;
    });
    LatLng southWest = LatLng(bounds.southWest.latitude, bounds.southWest.longitude);
    LatLng northEast = LatLng(bounds.northEast.latitude, bounds.northEast.longitude);
    double lat1 = (southWest.latitude + northEast.latitude) / 2;
    double lon1 = (southWest.longitude + northEast.longitude) / 2;
    position.value = setPosition(lat1, lon1);

    return (southWest, northEast);
  }

  void setInitialLocation(double lat, double lon) {
    initialLat.value = lat;
    initialLon.value = lon;
    isFirstCallParamLatLon = true;
  }

  Position? setPosition(lat, lon) {
    return Position(
      latitude: lat,
      longitude: lon,
      altitudeAccuracy: 0,
      headingAccuracy: 0,
      timestamp: DateTime.now(),
      accuracy: 0,
      altitude: 0,
      heading: 0,
      speed: 0,
      speedAccuracy: 0,
    );
  }

  @override
  void onClose() {
    mapController.dispose();
    onCameraChangeStreamController.close();
    listItemsController.close();
    super.onClose();
  }
}
