import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:project1/utils/log_utils.dart';

/// 앱 전역 이벤트/화면 추적 단일 진입점(Firebase Analytics 래퍼).
///
/// - 어떤 호출도 실패해도 앱 흐름을 막지 않도록 전부 try/catch로 감싼다(계측은 부가 기능).
/// - 화면 추적(screen_view)은 [observer]를 GetMaterialApp.navigatorObservers에 등록해 자동화한다.
/// - 최초 접근은 반드시 Firebase.initializeApp() 이후여야 한다(main에서 firebase 초기화 뒤 init 호출).
class AnalyticsService {
  AnalyticsService._();
  static final AnalyticsService instance = AnalyticsService._();

  final FirebaseAnalytics _fa = FirebaseAnalytics.instance;

  /// GetMaterialApp.navigatorObservers 에 넣어 네임드 라우트 진입을 자동 screen_view 로 기록.
  FirebaseAnalyticsObserver get observer => FirebaseAnalyticsObserver(analytics: _fa);

  Future<void> init() async {
    try {
      await _fa.setAnalyticsCollectionEnabled(true);
    } catch (e) {
      lo.g('Analytics init 실패(무시): $e');
    }
  }

  // ── 사용자 식별/속성 ──
  Future<void> setUser({String? custId, String? loginType, bool? isPremium}) async {
    try {
      if (custId != null && custId.isNotEmpty) await _fa.setUserId(id: custId);
      if (loginType != null && loginType.isNotEmpty) {
        await _fa.setUserProperty(name: 'login_type', value: loginType);
      }
      if (isPremium != null) {
        await _fa.setUserProperty(name: 'is_premium', value: isPremium ? 'Y' : 'N');
      }
    } catch (e) {
      lo.g('Analytics setUser 실패(무시): $e');
    }
  }

  /// 로그아웃/탈퇴 시 사용자 식별 해제.
  Future<void> clearUser() => _safe(() => _fa.setUserId(id: null));

  // ── 인증 퍼널 ──
  Future<void> logLogin(String method) => _safe(() => _fa.logLogin(loginMethod: method));
  Future<void> logSignUp(String method) => _safe(() => _fa.logSignUp(signUpMethod: method));

  // ── 콘텐츠 생성(핵심 활성화 지표) ──
  Future<void> logContentUpload({required String contentType, String? feel}) => _log('content_upload', {
        'content_type': contentType, // 'video' | 'photo'
        if (feel != null && feel.isNotEmpty) 'feel': feel,
      });

  // ── 콘텐츠 소비/참여 ──
  Future<void> logVideoView({required String boardId, String? feedType}) =>
      _log('video_view', {'board_id': boardId, if (feedType != null && feedType.isNotEmpty) 'feed_type': feedType});
  Future<void> logLike(String boardId) => _log('content_like', {'board_id': boardId});
  Future<void> logFollow(String targetCustId) => _log('user_follow', {'target_cust_id': targetCustId});
  Future<void> logShare({required String boardId, required String contentType}) =>
      _safe(() => _fa.logShare(contentType: contentType, itemId: boardId, method: 'system_sheet'));

  // ── 권한 ──
  Future<void> logPermission(String name, bool granted) =>
      _log('permission_result', {'permission': name, 'granted': granted.toString()});

  // ── 공용(임의 이벤트) ──
  Future<void> log(String name, [Map<String, Object?>? params]) => _log(name, params);

  Future<void> _log(String name, [Map<String, Object?>? params]) async {
    try {
      final clean = <String, Object>{};
      params?.forEach((k, v) {
        if (v != null) clean[k] = v;
      });
      await _fa.logEvent(name: name, parameters: clean.isEmpty ? null : clean);
    } catch (e) {
      lo.g('Analytics 이벤트($name) 실패(무시): $e');
    }
  }

  Future<void> _safe(Future<void> Function() fn) async {
    try {
      await fn();
    } catch (e) {
      lo.g('Analytics 호출 실패(무시): $e');
    }
  }
}
