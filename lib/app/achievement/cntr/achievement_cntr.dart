import 'package:get/get.dart';
import 'package:project1/repo/achievement/achievement_repo.dart';
import 'package:project1/repo/achievement/data/achievement_data.dart';
import 'package:project1/utils/log_utils.dart';

class AchievementCntr extends GetxController {
  static AchievementCntr get to => Get.find();

  final AchievementRepo _repo = AchievementRepo();

  final Rx<MyAchievementsData?> myData = Rx<MyAchievementsData?>(null);
  final RxBool isLoading = false.obs;
  final RxString selectedCategory = 'ALL'.obs;

  final List<Map<String, String>> categories = [
    {'code': 'ALL',     'name': '전체'},
    {'code': 'WEATHER', 'name': '날씨'},
    {'code': 'POST',    'name': '게시물'},
    {'code': 'STREAK',  'name': '연속'},
    {'code': 'POPULAR', 'name': '인기'},
    {'code': 'COUNT',   'name': '횟수'},
  ];

  List<AchievementData> get filteredAchievements {
    final data = myData.value?.achievements ?? [];
    if (selectedCategory.value == 'ALL') return data;
    return data.where((a) => a.category == selectedCategory.value).toList();
  }

  @override
  void onInit() {
    super.onInit();
    fetchAchievements();
  }

  Future<void> fetchAchievements() async {
    isLoading.value = true;
    try {
      final res = await _repo.getMyAchievements();
      if (res.code == '00') {
        myData.value = AchievementRepo.parseMyAchievements(res.data);
      } else {
        lo.g('fetchAchievements error: ${res.msg}');
      }
    } catch (e) {
      lo.g('fetchAchievements exception: $e');
    } finally {
      isLoading.value = false;
    }
  }
}
