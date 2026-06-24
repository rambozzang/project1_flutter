import 'package:get/get.dart';
import 'package:project1/repo/feel/data/feel_ranking_data.dart';
import 'package:project1/repo/feel/feel_repo.dart';
import 'package:project1/utils/log_utils.dart';

class FeelRankingCntr extends GetxController {
  static FeelRankingCntr get to => Get.find();

  final FeelRepo _repo = FeelRepo();

  final RxList<FeelRankingData> rankingList = <FeelRankingData>[].obs;
  final RxBool isLoading = false.obs;
  final RxString selectedPeriod = 'WEEKLY'.obs;

  final List<Map<String, String>> periods = [
    {'code': 'DAILY',   'name': '오늘'},
    {'code': 'WEEKLY',  'name': '이번주'},
    {'code': 'MONTHLY', 'name': '이번달'},
    {'code': 'ALL',     'name': '전체'},
  ];

  @override
  void onInit() {
    super.onInit();
    ever(selectedPeriod, (_) => fetchRanking());
    fetchRanking();
  }

  Future<void> fetchRanking() async {
    isLoading.value = true;
    try {
      final res = await _repo.getFeelRanking(period: selectedPeriod.value);
      if (res.code == '00') {
        rankingList.value = FeelRepo.parseRanking(res.data);
      } else {
        lo.g('fetchRanking error: ${res.msg}');
      }
    } catch (e) {
      lo.g('fetchRanking exception: $e');
    } finally {
      isLoading.value = false;
    }
  }

  void changePeriod(String period) => selectedPeriod.value = period;
}
