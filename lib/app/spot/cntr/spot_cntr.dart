import 'package:get/get.dart';
import 'package:project1/app/weathergogo/cntr/weather_gogo_cntr.dart';
import 'package:project1/repo/spot/data/spot_data.dart';
import 'package:project1/repo/spot/spot_repo.dart';

/// 스팟별 날씨 피드 컨트롤러.
/// 카테고리(캠핑/낚시/골프) 선택 → 현위치 기준 스팟 목록 + 현재 날씨 로드.
class SpotCntr extends GetxController {
  final SpotRepo _repo = SpotRepo();

  final RxString category = 'camping'.obs; // camping | fishing | golf
  final RxList<SpotData> spots = <SpotData>[].obs;
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetch();
  }

  void changeCategory(String cat) {
    if (category.value == cat) return;
    category.value = cat;
    fetch();
  }

  Future<void> fetch() async {
    try {
      isLoading.value = true;
      final loc = _currentLatLon();
      final list = await _repo.getSpotList(category.value, loc.$1, loc.$2);
      spots.assignAll(list);
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
