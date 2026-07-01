import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:project1/app/auth/cntr/auth_cntr.dart';
import 'package:project1/repo/feel/data/feel_ranking_data.dart';
import 'package:project1/repo/feel/feel_repo.dart';
import 'package:project1/utils/log_utils.dart';

class FeelRankingCntr extends GetxController {
  static FeelRankingCntr get to => Get.find();

  final FeelRepo _repo = FeelRepo();

  final RxList<FeelRankingData> rankingList = <FeelRankingData>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isLoadingMore = false.obs;
  final RxBool hasMore = true.obs;
  final RxString selectedPeriod = 'WEEKLY'.obs;

  /// 우리 동네 체감 통계 (best-effort, 실패 시 빈 상태 유지).
  final RxList<AreaFeelStat> areaStats = <AreaFeelStat>[].obs;

  int pageNum = 0;
  final int pageSize = 20;

  final List<Map<String, String>> periods = [
    {'code': 'DAILY',   'name': '오늘'},
    {'code': 'WEEKLY',  'name': '이번주'},
    {'code': 'MONTHLY', 'name': '이번달'},
    {'code': 'ALL',     'name': '전체'},
  ];

  /// 로그인한 사용자가 현재 로딩된 리스트에서 몇 위인지 반환한다.
  /// 찾으면 (해당 데이터, 1-based 순위)를, 없으면 null 을 반환한다.
  ({FeelRankingData data, int position})? get myRank {
    final myId = AuthCntr.to.custId.value;
    if (myId.isEmpty) return null;
    for (var i = 0; i < rankingList.length; i++) {
      final item = rankingList[i];
      if (item.custId.isNotEmpty && item.custId == myId) {
        return (data: item, position: i + 1);
      }
    }
    return null;
  }

  @override
  void onInit() {
    super.onInit();
    ever(selectedPeriod, (_) => fetchRanking());
    fetchRanking();
  }

  Future<void> fetchRanking() async {
    isLoading.value = true;
    pageNum = 0;
    hasMore.value = true;
    try {
      final res = await _repo.getFeelRanking(
        period: selectedPeriod.value,
        pageNum: pageNum,
        pageSize: pageSize,
      );
      if (res.code == '00') {
        final list = FeelRepo.parseRanking(res.data);
        rankingList.value = list;
        if (list.length < pageSize) hasMore.value = false;
      } else {
        lo.g('fetchRanking error: ${res.msg}');
      }
    } catch (e) {
      lo.g('fetchRanking exception: $e');
    } finally {
      isLoading.value = false;
    }
    // 새로고침/기간변경 시 지역 통계도 재시도 (fire-and-forget, 실패해도 무시).
    fetchAreaStats();
  }

  Future<void> loadMore() async {
    if (isLoading.value || isLoadingMore.value || !hasMore.value) return;
    isLoadingMore.value = true;
    final nextPage = pageNum + 1;
    try {
      final res = await _repo.getFeelRanking(
        period: selectedPeriod.value,
        pageNum: nextPage,
        pageSize: pageSize,
      );
      if (res.code == '00') {
        final list = FeelRepo.parseRanking(res.data);
        if (list.isEmpty || list.length < pageSize) {
          hasMore.value = false;
        }
        // 이미 로딩된 항목과의 중복(custId 기준) 방지.
        final existingIds = rankingList
            .map((e) => e.custId)
            .where((id) => id.isNotEmpty)
            .toSet();
        final toAdd = list
            .where((e) => e.custId.isEmpty || !existingIds.contains(e.custId))
            .toList();
        if (toAdd.isNotEmpty) rankingList.addAll(toAdd);
        pageNum = nextPage;
      } else {
        lo.g('loadMore error: ${res.msg}');
      }
    } catch (e) {
      lo.g('loadMore exception: $e');
    } finally {
      isLoadingMore.value = false;
    }
  }

  /// 위치 기반 지역 체감 통계 (best-effort). 위치 거부/미구현 응답/에러 등
  /// 어떤 실패에도 areaStats 를 비운 채로 남겨두고 메인 랭킹에 영향을 주지 않는다.
  Future<void> fetchAreaStats() async {
    try {
      // 랭킹 화면에서 갑작스런 위치 권한 팝업이 뜨지 않도록,
      // 이미 허용된 경우에만 위치를 조회한다. (미허용 시 조용히 스킵)
      final perm = await Geolocator.checkPermission();
      if (perm != LocationPermission.always &&
          perm != LocationPermission.whileInUse) {
        return;
      }
      final position = await Geolocator.getCurrentPosition();
      final res = await _repo.getAreaFeelStats(
        loX: position.longitude.toString(),
        loY: position.latitude.toString(),
      );
      if (res.code == '00') {
        areaStats.value = FeelRepo.parseAreaStats(res.data);
      } else {
        lo.g('fetchAreaStats error: ${res.msg}');
      }
    } catch (e) {
      lo.g('fetchAreaStats exception: $e');
    }
  }

  void changePeriod(String period) => selectedPeriod.value = period;
}
