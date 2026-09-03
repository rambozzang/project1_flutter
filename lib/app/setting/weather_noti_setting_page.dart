import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:project1/app/shared_album/theme/sa_colors.dart';
import 'package:project1/app/shared_album/theme/sa_text_styles.dart';
import 'package:project1/services/weather_notification_service.dart';
import 'package:project1/utils/utils.dart';

/// 날씨 상태바 알림 설정 (Android 전용 메뉴에서만 진입).
/// 상시 알림 켜기/끄기, 갱신 주기 선택, 즉시 갱신을 제공한다.
///
/// 설정 화면(setting_page)과 같은 디자인 토큰(SaColors/SaText)을 쓴다.
/// 라이트 고정: `SaColors.syncWith(context)`를 부르지 않는다.
class WeatherNotiSettingPage extends StatefulWidget {
  const WeatherNotiSettingPage({super.key});

  @override
  State<WeatherNotiSettingPage> createState() => _WeatherNotiSettingPageState();
}

class _WeatherNotiSettingPageState extends State<WeatherNotiSettingPage> with WidgetsBindingObserver {
  static const List<(int, String)> _intervals = [(30, '30분'), (60, '1시간'), (180, '3시간')];

  bool _hasPermission = false;
  bool _enabled = false;
  int _intervalMin = 60;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // 시스템 설정에서 권한을 바꾸고 돌아온 경우 재확인
    if (state == AppLifecycleState.resumed && !_hasPermission) _checkPermission();
  }

  Future<void> _load() async {
    await _checkPermission();
    final bool enabled = await WeatherNotificationService.isEnabled();
    final int interval = await WeatherNotificationService.intervalMin();
    if (!mounted) return;
    setState(() {
      _enabled = enabled;
      _intervalMin = interval;
    });
  }

  Future<void> _checkPermission() async {
    final status = await Permission.notification.request();
    if (!mounted) return;
    setState(() => _hasPermission = status.isGranted);
  }

  Future<void> _toggle(bool value) async {
    if (_busy) return;
    if (value && !_hasPermission) {
      Utils.showConfirmDialog('알림 권한이 필요합니다.', '핸드폰 설정화면으로 이동하여 알림을 허용해주세요.', BackButtonBehavior.none, cancel: () {}, confirm: () async {
        await openAppSettings();
      }, backgroundReturn: () {
        _checkPermission();
      });
      return;
    }
    setState(() => _busy = true);
    try {
      if (value) {
        await WeatherNotificationService.enable(intervalMinutes: _intervalMin);
      } else {
        await WeatherNotificationService.disable();
      }
      if (mounted) setState(() => _enabled = value);
    } catch (e) {
      Utils.alert('설정 변경에 실패했습니다: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _changeInterval(int min) async {
    setState(() => _intervalMin = min);
    if (_enabled) {
      // 주기 변경은 기존 작업을 update 정책으로 재등록
      await WeatherNotificationService.enable(intervalMinutes: min);
    }
  }

  Future<void> _refreshNow() async {
    if (_busy || !_enabled) return;
    setState(() => _busy = true);
    try {
      await WeatherNotificationService.refreshNotification();
      Utils.alert('날씨 알림을 갱신했습니다.');
    } catch (e) {
      Utils.alert('갱신에 실패했습니다: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// 섹션 제목 — setting_page의 SettingsGroup 제목과 같은 규격(titleS / 좌우 4 / 아래 8).
  Widget _groupTitle(String text) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
        child: Text(text, style: SaText.titleS),
      );

  /// 카드 — 핸드오프 규격: r26 / surface / border / 내부 패딩 14.
  /// 배경은 Container가 아니라 Material이 그린다(잉크 리플이 가려지지 않도록).
  Widget _card({required Widget child}) => Material(
        color: SaColors.surface,
        borderRadius: BorderRadius.circular(26),
        clipBehavior: Clip.antiAlias,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: SaColors.border),
          ),
          padding: const EdgeInsets.all(14),
          child: child,
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        forceMaterialTransparency: true,
        automaticallyImplyLeading: false,
        // 뒤로가기 — setting_page와 같은 원형 surface 버튼(pill). 화면 좌측 패딩 16에 맞춘다.
        leadingWidth: 72,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16),
          child: Center(
            child: SizedBox(
              width: 40,
              height: 40,
              child: Material(
                color: SaColors.surface,
                shape: CircleBorder(side: BorderSide(color: SaColors.borderStrong)),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () => Navigator.pop(context),
                  child: Center(
                    child: PhosphorIcon(PhosphorIconsBold.caretLeft, size: 17, color: SaColors.textPrimary),
                  ),
                ),
              ),
            ),
          ),
        ),
        title: Text('날씨 상태바 알림', style: SaText.titleS),
        centerTitle: true,
        elevation: 0,
      ),
      backgroundColor: SaColors.bgBase,
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!_hasPermission) ...[
              GestureDetector(
                onTap: () => openAppSettings(),
                child: _card(
                  child: Row(
                    children: [
                      Text('기기 알림이 꺼져있습니다.', style: SaText.titleS),
                      const Spacer(),
                      Text('켜기', style: SaText.caption.copyWith(color: SaColors.accentTeal, fontWeight: FontWeight.w800)),
                      const Gap(5),
                      PhosphorIcon(PhosphorIconsBold.caretRight, size: 16, color: SaColors.textTertiary),
                    ],
                  ),
                ),
              ),
              const Gap(20),
            ],
            _card(
              child: Row(
                children: [
                  PhosphorIcon(PhosphorIconsBold.sun, color: SaColors.textSecondary, size: 27),
                  const Gap(7),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('날씨 상태바 알림', style: SaText.titleS),
                        Text('상태바에 현재 온도와 날씨를 상시 표시합니다.', style: SaText.caption),
                      ],
                    ),
                  ),
                  Transform.scale(
                    scale: 0.8,
                    // 스위치 on 색은 OS 관례(iOS 초록)라 SaColors로 치환하지 않고 원본 유지.
                    child: CupertinoSwitch(
                      value: _enabled,
                      activeTrackColor: CupertinoColors.activeGreen,
                      onChanged: _busy ? null : _toggle,
                    ),
                  ),
                ],
              ),
            ),
            const Gap(20),
            _groupTitle('갱신 주기'),
            _card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('배터리 절약을 위해 주기가 길수록 좋습니다. 시스템 상황에 따라 몇 분 지연될 수 있습니다.', style: SaText.caption),
                  const Gap(10),
                  Row(
                    children: [
                      for (final (min, label) in _intervals) ...[
                        // 칩은 pill(999) — 핸드오프 규격
                        ChoiceChip(
                          label: Text(label),
                          selected: _intervalMin == min,
                          onSelected: _busy ? null : (_) => _changeInterval(min),
                          selectedColor: SaColors.accentTeal,
                          labelStyle: SaText.caption.copyWith(
                            color: _intervalMin == min ? SaColors.onAccent : SaColors.textSecondary,
                            fontSize: 13,
                          ),
                          backgroundColor: SaColors.surfaceElevated,
                          side: BorderSide(color: _intervalMin == min ? SaColors.accentTeal : SaColors.border),
                          shape: const StadiumBorder(),
                          showCheckmark: false,
                        ),
                        const Gap(8),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const Gap(20),
            _groupTitle('위치'),
            _card(
              child: Text('마지막으로 확인된 위치의 날씨를 표시합니다. 앱을 사용하면 위치가 자동으로 갱신됩니다.', style: SaText.caption),
            ),
            const Gap(20),
            if (_enabled)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _busy ? null : _refreshNow,
                  icon: PhosphorIcon(PhosphorIconsBold.arrowsClockwise, size: 18, color: SaColors.textPrimary),
                  label: Text('지금 갱신', style: SaText.caption.copyWith(color: SaColors.textPrimary, fontSize: 14)),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: SaColors.surface,
                    side: BorderSide(color: SaColors.borderStrong),
                    // 버튼은 pill(999) — 핸드오프 규격
                    shape: const StadiumBorder(),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            const Gap(40),
          ],
        ),
      ),
    );
  }
}
