import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:project1/services/weather_notification_service.dart';
import 'package:project1/utils/utils.dart';

/// 날씨 상태바 알림 설정 (Android 전용 메뉴에서만 진입).
/// 상시 알림 켜기/끄기, 갱신 주기 선택, 즉시 갱신을 제공한다.
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        forceMaterialTransparency: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('날씨 상태바 알림', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
      ),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Gap(10),
            if (!_hasPermission)
              GestureDetector(
                onTap: () => openAppSettings(),
                child: Container(
                  height: 60,
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: Colors.grey[200],
                  ),
                  child: const Row(
                    children: [
                      Text('기기 알림이 꺼져있습니다.', style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold)),
                      Spacer(),
                      Text('켜기', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                      Gap(5),
                      Icon(Icons.arrow_forward_ios, size: 19),
                    ],
                  ),
                ),
              ),
            const Gap(10),
            Row(
              children: [
                const Icon(Icons.wb_sunny_outlined, color: Colors.grey, size: 27),
                const Gap(7),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('날씨 상태바 알림', style: TextStyle(color: Colors.black, fontSize: 14, fontWeight: FontWeight.bold)),
                      Text('상태바에 현재 온도와 날씨를 상시 표시합니다.',
                          style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
                Transform.scale(
                  scale: 0.8,
                  child: CupertinoSwitch(
                    value: _enabled,
                    activeTrackColor: CupertinoColors.activeGreen,
                    onChanged: _busy ? null : _toggle,
                  ),
                ),
              ],
            ),
            Divider(height: 30, thickness: 3, color: Colors.grey.withOpacity(0.3)),
            const Text('갱신 주기', style: TextStyle(color: Colors.black, fontSize: 14, fontWeight: FontWeight.bold)),
            const Gap(4),
            const Text('배터리 절약을 위해 주기가 길수록 좋습니다. 시스템 상황에 따라 몇 분 지연될 수 있습니다.',
                style: TextStyle(color: Colors.grey, fontSize: 12)),
            const Gap(10),
            Row(
              children: [
                for (final (min, label) in _intervals) ...[
                  ChoiceChip(
                    label: Text(label),
                    selected: _intervalMin == min,
                    onSelected: _busy ? null : (_) => _changeInterval(min),
                    selectedColor: Colors.black,
                    labelStyle: TextStyle(
                      color: _intervalMin == min ? Colors.white : Colors.black87,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    backgroundColor: Colors.grey[100],
                    showCheckmark: false,
                  ),
                  const Gap(8),
                ],
              ],
            ),
            Divider(height: 30, thickness: 3, color: Colors.grey.withOpacity(0.3)),
            const Text('위치', style: TextStyle(color: Colors.black, fontSize: 14, fontWeight: FontWeight.bold)),
            const Gap(4),
            const Text('마지막으로 확인된 위치의 날씨를 표시합니다. 앱을 사용하면 위치가 자동으로 갱신됩니다.',
                style: TextStyle(color: Colors.grey, fontSize: 12)),
            const Gap(20),
            if (_enabled)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _busy ? null : _refreshNow,
                  icon: const Icon(Icons.refresh, size: 18, color: Colors.black),
                  label: const Text('지금 갱신', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600)),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.grey.withOpacity(0.4)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
