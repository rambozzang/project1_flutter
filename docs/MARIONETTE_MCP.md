# Marionette MCP (AI 에이전트가 실행 중인 앱 조작)

AI 에이전트(Claude Code 등)가 **디버그 모드로 돌아가는 SkySnap 앱**에 붙어 위젯 트리를 읽고,
탭·입력·스크롤·스크린샷·로그 조회·핫리로드를 수행할 수 있게 하는 설정.
"Flutter용 Playwright MCP" 라고 보면 된다.

## 구성 요소

| 위치 | 내용 |
|---|---|
| `pubspec.yaml` | `marionette_flutter: ^0.6.0` (일반 의존성 — 릴리즈에선 트리 셰이킹으로 빠짐) |
| `lib/services/marionette_service.dart` | 바인딩 초기화 + 로그 수집기 연결 |
| `lib/main.dart` | `kDebugMode` 분기로 `MarionetteBinding` / `WidgetsFlutterBinding` 선택 |
| 전역 MCP 설정 | `~/.claude.json` 의 `mcpServers.marionette` → `marionette_mcp` (stdio) |

MCP 서버 바이너리는 전역 설치돼 있다. 재설치가 필요하면:

```bash
dart pub global activate marionette_mcp
```

## 단일 바인딩 규칙 (중요)

`MarionetteBinding` 은 `WidgetsFlutterBinding` 의 서브클래스다. 둘 중 **하나만** 초기화돼야 하고,
`main()` 의 **첫 줄**에서 다른 어떤 초기화(Firebase·SystemChrome 등)보다 먼저 와야 한다.

```dart
void main() async {
  if (kDebugMode) {
    MarionetteService.ensureInitialized();
  } else {
    WidgetsFlutterBinding.ensureInitialized();
  }
  // ... 이하 기존 초기화
}
```

`main()` 앞부분을 건드릴 때 이 분기를 깨뜨리지 말 것.

## 사용 절차

1. 디버그 모드로 앱 실행

   ```bash
   flutter run -d <device-id> --debug
   ```

2. 콘솔에 찍히는 VM Service URI 를 확인

   ```
   A Dart VM Service on SM N976N is available at: http://127.0.0.1:55860/AJWW7JhVXkg=/
   ```

3. 에이전트에게 `ws://` + `/ws` 형태로 연결시킨다 (스킴과 끝의 `ws` 에 주의)

   ```
   ws://127.0.0.1:55860/AJWW7JhVXkg=/ws
   ```

4. `get_interactive_elements` 로 조작 가능한 요소를 확인한 뒤 `tap` / `enter_text` / `scroll_to` 등을 호출.

## 함정

- **에이전트가 백그라운드로 `flutter run` 을 띄우면 stdin EOF 를 받고 빌드 직후 조용히 종료(exit 0)된다.**
  stdin 을 열어둬야 한다: `sleep 2147483647 | flutter run -d <device> --debug`
  (macOS 의 BSD `sleep` 은 `infinity` 를 못 받아 `usage:` 를 뱉고 바로 죽는다 — 큰 숫자를 준다. 2026-09-20 확인)
- **실기기 iPhone(3x) 의 `take_screenshots` 는 앱 쪽 캡처는 성공해도(3.6MB) MCP 응답이 `Internal server error` 로 실패한다.**
  레이아웃은 `get_interactive_elements` 의 bounds 로 확인하고, 픽셀은 안드로이드 실기기나 시뮬레이터로 본다.
- **`take_screenshots` 는 `VisibilityDetector` 로 켜고 끄는 애니메이션을 멈출 수 있다.** 캡처가 레이어 트리를 따로 합성하면서
  가시성 콜백이 `visibleFraction 0` 을 보고하고, 이후 프레임이 안 그려져 다시 켜지지 않는다(2026-09-20, 날씨 홈 지도 타일).
  움직임을 검증할 때는 `adb exec-out screencap -p` 로 OS 스크린샷을 두 장 찍어 비교한다. 실제 기기 사용에는 영향이 없다.
- **안드로이드 실기기 logcat 에는 기기에 설치된 다른 Flutter 앱 로그가 섞여 들어온다.**
  `I/flutter (PID)` 의 PID 로 구분할 것. (`adb shell ps -A | grep skysnap`)
  MCP `get_logs` 는 VM Service 를 통해 이 앱 로그만 가져오므로 섞이지 않는다.
- 포트는 실행할 때마다 바뀐다. 핫리스타트가 아니라 앱을 새로 띄웠다면 다시 `connect` 해야 한다.
- **앱을 백그라운드로 내리고 다른 앱을 쓰면 `Lost connection to device.` 로 `flutter run` 이 끊긴다.**
  앱 프로세스는 남아 있어도 VM Service 연결은 죽으므로, `flutter run` 부터 다시 띄우고 새 URI 로 `connect` 해야 한다.
  MCP 로 조작하는 동안에는 기기에서 SkySnap 을 포그라운드에 둘 것.

## 로그 수집 (`get_logs`)

`MarionetteService` 가 전역 `debugPrint` 를 감싸서 수집기로 넘긴다.
앱의 로깅 유틸(`lib/utils/log_utils.dart` 의 `Lo.g` / `lo.e` / `log()`)과 `pretty_dio_logger`,
프레임워크 경고가 전부 `debugPrint` 를 타므로 별도 작업 없이 `get_logs` 에 잡힌다.

## 커스텀 위젯

`lib/widget/` 의 `CustomButton`·`CustomSecButton`·`CustomIconButton` 은 내부에서 `InkWell` 을,
`Custom2Button` 은 `ElevatedButton` 을 쓰므로 기본 매처로 전부 탐지된다.
`InkWell`/`GestureDetector` 를 거치지 않는 커스텀 인터랙션 위젯을 새로 만들면
`MarionetteConfiguration(isInteractiveWidget: ..., extractText: ...)` 에 등록해야 에이전트 눈에 보인다.

텍스트로 못 찾는 위젯은 소스에 `ValueKey` 를 달아주는 쪽이 확실하다.

```dart
ElevatedButton(key: const ValueKey('submit_button'), ...)
```
