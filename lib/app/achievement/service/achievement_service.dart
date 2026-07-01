import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:project1/app/achievement/widgets/achievement_unlock_dialog.dart';
import 'package:project1/app/auth/cntr/auth_cntr.dart';
import 'package:project1/repo/achievement/achievement_repo.dart';
import 'package:project1/repo/achievement/data/achievement_data.dart';
import 'package:project1/utils/log_utils.dart';

/// 업적 달성 알림 루프 서비스.
///
/// 로컬에 저장된 "이미 확인한 업적 ID" 집합과 서버의 최신 달성 목록을 비교(diff)해서
/// 새로 달성한 업적이 있으면 축하 다이얼로그를 띄우고, 미확인 배지 수를 노출한다.
///
/// 어떤 상황에서도 절대 크래시하지 않으며(모든 경로 try/catch), 에러 시 조용히 무시한다.
class AchievementService extends GetxService {
  static AchievementService get to => Get.find();

  // SharedPreferences 저장 키
  static const String _kSeenIds = 'achv_seen_ids';
  static const String _kBaselineDone = 'achv_baseline_done';

  final AchievementRepo _repo = AchievementRepo();

  /// 미확인 업적 배지 수 (업적 페이지 진입 시 markAllSeen()으로 0 처리)
  final RxInt unseenCount = 0.obs;

  // 이미 "달성 확인"한 업적 ID 집합 (메모리 캐시)
  final Set<String> _seen = <String>{};

  // 최초 실행 기준선(baseline) 설정 여부.
  // false면 첫 동기화에서 현재 달성분을 모두 "이미 본 것"으로 처리(다이얼로그 스팸 방지).
  bool _baselineDone = false;

  // prefs 로드 완료 여부
  bool _loaded = false;

  SharedPreferences? _prefs;

  /// prefs 를 메모리로 로드한다. 실패해도 throw 하지 않는다.
  Future<AchievementService> init() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      final seenList = _prefs?.getStringList(_kSeenIds) ?? <String>[];
      _seen
        ..clear()
        ..addAll(seenList);
      _baselineDone = _prefs?.getBool(_kBaselineDone) ?? false;
      _loaded = true;
    } catch (e) {
      lo.g('AchievementService.init error: $e');
    }
    return this;
  }

  @override
  void onInit() {
    super.onInit();
    _bootstrap();
    // 로그인 상태가 true 로 바뀌면 동기화
    ever(AuthCntr.to.isLogged, (v) {
      if (v == true) syncAndNotify();
    });
  }

  /// init() 이 먼저 끝난 뒤 최초 동기화를 순서대로 실행하기 위한 헬퍼.
  Future<void> _bootstrap() async {
    try {
      await init();
      if (AuthCntr.to.isLogged.value == true) {
        await syncAndNotify();
      }
    } catch (e) {
      lo.g('AchievementService._bootstrap error: $e');
    }
  }

  /// 서버의 최신 달성 목록과 로컬 상태를 비교해 새 업적을 알린다.
  Future<void> syncAndNotify({bool showDialogs = true}) async {
    try {
      // 1. 비로그인 시 아무것도 하지 않음
      if (AuthCntr.to.isLogged.value != true) return;

      // 2. prefs 미로드 시 로드
      if (!_loaded) await init();

      // 3. 서버 조회
      final res = await _repo.getMyAchievements();
      if (res.code != '00') {
        lo.g('syncAndNotify: getMyAchievements failed code=${res.code} msg=${res.msg}');
        return;
      }
      final MyAchievementsData? data =
          AchievementRepo.parseMyAchievements(res.data);
      if (data == null) return;

      // 4. 현재 달성한 업적 ID 집합
      final Set<String> currentAchievedIds = data.achievements
          .where((a) => a.achieved)
          .map((a) => a.achievementId)
          .toSet();

      // 5. 최초 실행: 기준선만 저장하고 다이얼로그는 띄우지 않음
      if (!_baselineDone) {
        _seen
          ..clear()
          ..addAll(currentAchievedIds);
        _baselineDone = true;
        await _persistSeen();
        await _persistBaseline();
        unseenCount.value = 0;
        return;
      }

      // 6. 새로 달성한 업적 diff
      final Set<String> newIds = currentAchievedIds.difference(_seen);
      if (newIds.isEmpty) return;

      // 새 업적에 해당하는 데이터 조회
      final List<AchievementData> newOnes = data.achievements
          .where((a) => newIds.contains(a.achievementId))
          .toList();

      // 다이얼로그 표시 (Get.dialog 중첩 방지를 위해 하나만 띄운다)
      if (showDialogs && newOnes.isNotEmpty) {
        final AchievementData first = newOnes.first;
        String message = first.achievementDesc;
        if (newIds.length > 1) {
          message = '$message\n외 ${newIds.length - 1}개 업적을 달성했어요!';
        }
        AchievementUnlockDialog.show(
          icon: first.achievementIcon,
          name: first.achievementNm,
          message: message,
        );
      }

      // 배지 수 증가 및 seen 병합/저장
      unseenCount.value += newIds.length;
      _seen.addAll(newIds);
      await _persistSeen();
    } catch (e) {
      lo.g('syncAndNotify error: $e');
    }
  }

  /// 업적 페이지 진입 시 배지 초기화 (seen 집합은 이미 최신이므로 배지만 정리).
  Future<void> markAllSeen() async {
    unseenCount.value = 0;
  }

  Future<void> _persistSeen() async {
    try {
      await _prefs?.setStringList(_kSeenIds, _seen.toList());
    } catch (e) {
      lo.g('AchievementService._persistSeen error: $e');
    }
  }

  Future<void> _persistBaseline() async {
    try {
      await _prefs?.setBool(_kBaselineDone, _baselineDone);
    } catch (e) {
      lo.g('AchievementService._persistBaseline error: $e');
    }
  }
}
