import 'package:project1/utils/log_utils.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// 웹뷰 엔진을 **미리 깨워 둔다.**
///
/// ## 왜
/// 레이더·위성은 외부 사이트를 웹뷰로 띄운다. 탭한 뒤 지도가 보이기까지
/// 걸리는 시간에는 남의 사이트를 받는 시간 말고도 **그 앱에서 처음으로
/// 웹뷰를 만드는 비용**이 섞여 있다. 안드로이드는 이때 크로미움을 초기화하고
/// 렌더러 프로세스를 띄운다.
///
/// 그 비용은 앱에서 **첫 웹뷰 한 번만** 든다. 그래서 사용자가 카드를 볼 때
/// 미리 빈 페이지로 한 번 깨워 두면, 정작 탭했을 때는 그 단계가 이미 끝나
/// 있다.
///
/// ## 왜 `about:blank` 인가
/// 예전에 날씨 화면에 지도 웹뷰를 상시 박아 뒀다가 Feed 를 보는 동안에도
/// 크로미움이 CPU 14% 를 계속 먹은 적이 있다(2026-09-20). 그건 **실제
/// 사이트를 계속 돌려서** 생긴 일이고, 빈 페이지는 그리거나 실행할 것이
/// 없어 CPU 를 쓰지 않는다. 엔진만 올려 두는 것이 목적이다.
///
/// ## 한계
/// 네트워크로 받는 시간(남의 사이트 JS·타일)은 줄지 않는다. 줄어드는 건
/// 엔진 기동분뿐이다.
abstract class WebViewWarmup {
  WebViewWarmup._();

  static bool _warmed = false;

  /// 깨워 둔 컨트롤러를 붙들고 있는다. 놓으면 네이티브 웹뷰가 회수돼
  /// 다음에 다시 초기화 비용을 낸다 — 이 참조가 예열의 실체다.
  static WebViewController? _engine;

  /// 예열됐는지(진단용).
  static bool get isWarmed => _warmed && _engine != null;

  /// 한 번만 실행된다. 두 번째부터는 즉시 반환한다.
  static void warm() {
    if (_warmed) return;
    _warmed = true;
    try {
      _engine = WebViewController()..loadRequest(Uri.parse('about:blank'));
      lo.g('[webview] 엔진 예열 시작');
    } catch (e) {
      // 예열은 최적화일 뿐이다. 실패해도 실제 진입에는 영향이 없어야 한다.
      _engine = null;
      lo.g('[webview] 엔진 예열 실패(무시): $e');
    }
  }
}
