import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:project1/utils/log_utils.dart';

/// 스토어 리뷰(별점) 요청 게이팅.
///
/// OS(App Store/Play)가 자체적으로 노출 빈도를 제한하지만, 앱 차원에서도
/// "충분히 가치를 경험한 긍정적 순간"에만, 과하지 않게 요청한다.
///   - 최소 [_minUploadsBeforeAsk]회 업로드 성공 후
///   - 마지막 요청으로부터 [_cooldownDays]일 경과 후
class ReviewService {
  ReviewService._();
  static final ReviewService instance = ReviewService._();

  final InAppReview _review = InAppReview.instance;

  static const String _kUploadCount = 'review_upload_count';
  static const String _kLastAskedMs = 'review_last_asked_ms';
  static const int _minUploadsBeforeAsk = 2;
  static const int _cooldownDays = 60;

  /// 업로드 성공 등 긍정적 순간에 호출. 조건 충족 시에만 리뷰 시트를 띄운다.
  Future<void> onPositiveMoment() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final count = (prefs.getInt(_kUploadCount) ?? 0) + 1;
      await prefs.setInt(_kUploadCount, count);
      if (count < _minUploadsBeforeAsk) return;

      final now = DateTime.now().millisecondsSinceEpoch;
      final lastAsked = prefs.getInt(_kLastAskedMs) ?? 0;
      if (lastAsked != 0) {
        final elapsedDays = (now - lastAsked) / (1000 * 60 * 60 * 24);
        if (elapsedDays < _cooldownDays) return;
      }

      if (await _review.isAvailable()) {
        await prefs.setInt(_kLastAskedMs, now);
        await _review.requestReview();
      }
    } catch (e) {
      lo.g('ReviewService 실패(무시): $e');
    }
  }
}
