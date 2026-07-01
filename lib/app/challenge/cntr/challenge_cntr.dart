import 'package:get/get.dart';
import 'package:project1/app/auth/cntr/auth_cntr.dart';
import 'package:project1/repo/challenge/challenge_repo.dart';
import 'package:project1/repo/challenge/data/challenge_complete_data.dart';
import 'package:project1/repo/challenge/data/challenge_me_data.dart';
import 'package:project1/repo/challenge/data/challenge_today_data.dart';
import 'package:project1/repo/common/res_data.dart';
import 'package:project1/utils/log_utils.dart';
import 'package:project1/utils/utils.dart';

class ChallengeCntr extends GetxController {
  static ChallengeCntr get to => Get.find();

  final ChallengeRepo _challengeRepo = ChallengeRepo();

  final Rx<ChallengeTodayData?> todayChallenge = Rx<ChallengeTodayData?>(null);
  final Rx<ChallengeMeData?> myChallengeStatus = Rx<ChallengeMeData?>(null);
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    // 이미 로그인된 상태에서 컨트롤러가 생성되는 경우(챌린지 화면 진입 등)
    // 즉시 로드한다. ever는 값이 '변할 때'만 실행되므로 이것만으로는
    // 로드가 트리거되지 않아 화면이 빈 채로 남는 문제가 있었다.
    if (AuthCntr.to.isLogged.value == true) {
      loadAll();
    }
    ever(AuthCntr.to.isLogged, (isLogged) {
      if (isLogged == true) {
        loadAll();
      }
    });
  }

  /// 오늘의 챌린지 → 내 챌린지 현황 순서로 로드한다.
  /// (내 현황 조회는 todayChallenge.challengeId 에 의존하므로 반드시 순차 실행)
  Future<void> loadAll() async {
    await fetchTodayChallenge();
    await fetchMyChallengeStatus();
  }

  Future<void> fetchTodayChallenge() async {
    final custId = AuthCntr.to.custId.value;
    if (custId.isEmpty) return;

    isLoading.value = true;
    try {
      ResData resData = await _challengeRepo.getTodayChallenge(custId);
      if (resData.code == '00') {
        todayChallenge.value = ChallengeRepo.parseTodayData(resData.data);
      } else {
        lo.g('fetchTodayChallenge error: ${resData.msg}');
      }
    } catch (e) {
      lo.g('fetchTodayChallenge exception: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<ChallengeCompleteData?> completeChallenge() async {
    final custId = AuthCntr.to.custId.value;
    final challengeId = todayChallenge.value?.challengeId;
    if (custId.isEmpty || challengeId == null) return null;

    try {
      ResData resData = await _challengeRepo.completeChallenge(challengeId, custId);
      if (resData.code == '00') {
        final result = ChallengeRepo.parseCompleteData(resData.data);
        await fetchTodayChallenge();
        await fetchMyChallengeStatus();
        return result;
      } else {
        Utils.alert(resData.msg ?? '챌린지 완료 처리 중 오류가 발생했습니다.');
      }
    } catch (e) {
      lo.g('completeChallenge exception: $e');
      Utils.alert('챌린지 완료 처리 중 오류가 발생했습니다.');
    }
    return null;
  }

  Future<void> fetchMyChallengeStatus() async {
    final custId = AuthCntr.to.custId.value;
    final challengeId = todayChallenge.value?.challengeId;
    if (custId.isEmpty || challengeId == null) return;

    try {
      ResData resData = await _challengeRepo.getMyChallengeStatus(custId, challengeId);
      if (resData.code == '00') {
        myChallengeStatus.value = ChallengeRepo.parseMeData(resData.data);
      } else {
        lo.g('fetchMyChallengeStatus error: ${resData.msg}');
      }
    } catch (e) {
      lo.g('fetchMyChallengeStatus exception: $e');
    }
  }
}
