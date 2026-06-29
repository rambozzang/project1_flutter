import 'dart:async';

import 'package:get/get.dart';
import 'package:project1/app/weathergogo/cntr/weather_gogo_cntr.dart';
import 'package:project1/repo/spot/data/spot_data.dart';
import 'package:project1/repo/spot/spot_repo.dart';

/// 스팟별 날씨 피드 컨트롤러.
/// 카테고리(캠핑/낚시/골프) 선택 → 현위치 기준 스팟 목록 + 각 스팟 현재 날씨 로드.
class SpotCntr extends GetxController {
  final SpotRepo _repo = SpotRepo();

  final RxString category = 'camping'.obs; // camping | fishing | golf
  final RxList<SpotData> spots = <SpotData>[].obs;
  final RxBool isLoading = false.obs;
  final RxnString errorMsg = RxnString();

  StreamSubscription? _locationSub;

  @override
  void onInit() {
    super.onInit();
    _observeLocation();
    fetch();
  }

  @override
  void onClose() {
    _locationSub?.cancel();
    super.onClose();
  }

  /// WeatherGogoCntr의 현재 위치 변화를 구독한다.
  /// 위치가 업데이트되면 스팟 목록을 다시 불러온다.
  void _observeLocation() {
    try {
      final weatherCntr = Get.find<WeatherGogoCntr>();
      _locationSub = weatherCntr.currentLocation.stream.listen((_) {
        final loc = _currentLatLon();
        // (0,0)은 아직 위치를 못 받은 초기값이므로 무시한다.
        if (loc.$1 == 0.0 && loc.$2 == 0.0) return;
        fetch();
      });
    } catch (_) {
      // WeatherGogoCntr이 아직 준비되지 않은 경우 fetch()에서 기본값 사용
    }
  }

  void changeCategory(String cat) {
    if (category.value == cat) return;
    category.value = cat;
    fetch();
  }

  Future<void> fetch() async {
    try {
      isLoading.value = true;
      errorMsg.value = null;
      final loc = _currentLatLon();
      final list = await _repo.getSpotList(category.value, loc.$1, loc.$2);
      spots.assignAll(list);
      if (list.isEmpty) {
        errorMsg.value = '주변 스팟이 아직 없어요';
      }
    } catch (e) {
      spots.clear();
      errorMsg.value = '스팟 정보를 불러오지 못했어요';
    } finally {
      isLoading.value = false;
    }
  }

  // 현위치(없으면 서울시청 기본값)
  (double, double) _currentLatLon() {
    try {
      final cntr = Get.find<WeatherGogoCntr>();
      final ll = cntr.currentLocation.value.latLng;
      return (ll.latitude, ll.longitude);
    } catch (_) {
      return (37.5665, 126.9780);
    }
  }
}
