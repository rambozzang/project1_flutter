import 'package:flutter/foundation.dart';
import 'package:marionette_flutter/marionette_flutter.dart';

/// Marionette MCP(AI 에이전트가 실행 중인 앱을 조작) 부팅 설정.
///
/// 디버그 빌드에서만 호출한다. `MarionetteBinding` 은 `WidgetsFlutterBinding` 의
/// 서브클래스라 바인딩은 하나만 떠야 하고(단일 바인딩 규칙), 반드시 main() 의
/// 첫 줄에서 다른 어떤 코드보다 먼저 초기화해야 한다.
///
/// 릴리즈 빌드는 main() 의 `kDebugMode` 분기에서 기존 `WidgetsFlutterBinding`
/// 을 그대로 쓰므로 이 파일의 코드는 트리 셰이킹으로 빠진다.
abstract class MarionetteService {
  MarionetteService._();

  /// `get_logs` MCP 툴이 읽어가는 로그 버퍼.
  static final PrintLogCollector _logCollector = PrintLogCollector();

  /// Marionette 바인딩을 올리고 앱 로그를 MCP 쪽으로 흘려보낸다.
  static void ensureInitialized() {
    MarionetteBinding.ensureInitialized(
      MarionetteConfiguration(logCollector: _logCollector),
    );

    // 앱 로그(Lo.g / lo.e / log())·dio 로거·프레임워크 경고가 전부 debugPrint 를
    // 타므로, 원래 구현을 유지한 채 수집기로 한 벌 더 넘긴다.
    final DebugPrintCallback originalDebugPrint = debugPrint;
    debugPrint = (String? message, {int? wrapWidth}) {
      originalDebugPrint(message, wrapWidth: wrapWidth);
      if (message != null) {
        _logCollector.addLog(message);
      }
    };
  }
}
