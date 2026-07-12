import 'dart:io';
import 'dart:ui' as ui;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:geolocator/geolocator.dart';
import 'package:project1/config/url_config.dart';
import 'package:project1/repo/kakao/kakao_repo.dart';
import 'package:project1/repo/weather_gogo/adapter/adapter_map.dart';
import 'package:workmanager/workmanager.dart';

/// 날씨 상태바 상시 알림 (Android 전용).
///
/// - WorkManager 주기 작업이 백그라운드 isolate에서 실행되어
///   백엔드 날씨 캐시 API(무인증 공개 엔드포인트)를 조회한 뒤 ongoing 알림을 갱신한다.
///   → 토큰이 필요 없어 AuthCntr(GetX) 없이도 백그라운드에서 동작한다.
/// - 위치는 마지막 위치(lastKnown) → 직전 저장 위치 → 서울 순으로 폴백.
///   백그라운드 위치 권한(ACCESS_BACKGROUND_LOCATION) 없이 동작하도록 설계(스토어 심사 리스크 회피).
/// - 설정은 FlutterSecureStorage(WEATHER_NOTI_*)에 저장 — 백그라운드 isolate에서도 읽기 가능.
/// - iOS는 상시 알림이 OS 차원에서 불가하므로 전 기능 Android 전용.

const String kWeatherNotiTaskName = 'weatherNotiTask';
const String _kUniqueWorkName = 'weather_noti_periodic';

const String _kEnabledKey = 'WEATHER_NOTI_ENABLED';
const String _kIntervalKey = 'WEATHER_NOTI_INTERVAL_MIN';
const String _kLastLatKey = 'WEATHER_NOTI_LAST_LAT';
const String _kLastLonKey = 'WEATHER_NOTI_LAST_LON';

const int _kNotificationId = 910001;

/// WorkManager 백그라운드 진입점. main()의 Workmanager().initialize()에 전달된다.
/// 백그라운드 isolate에서 실행되므로 앱 전역 상태(GetX 등)에 의존하면 안 된다.
@pragma('vm:entry-point')
void weatherNotiDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      await WeatherNotificationService.refreshNotification();
    } catch (e) {
      debugPrint('[WeatherNoti] task error: $e');
    }
    // 실패해도 true 반환: 다음 주기에 자연 갱신되므로 WorkManager 재시도 백오프를 피한다.
    return true;
  });
}

class WeatherNotificationService {
  WeatherNotificationService._();

  // 기존 SecureStorage mixin과 동일 옵션이어야 같은 저장소 파일을 공유한다.
  static const FlutterSecureStorage _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static Future<bool> isEnabled() async {
    if (!Platform.isAndroid) return false;
    return (await _storage.read(key: _kEnabledKey)) == 'Y';
  }

  static Future<int> intervalMin() async {
    final String? v = await _storage.read(key: _kIntervalKey);
    return int.tryParse(v ?? '') ?? 60;
  }

  /// 알림 켜기: 설정 저장 + 주기 작업 등록 + 즉시 1회 표시.
  static Future<void> enable({required int intervalMinutes}) async {
    if (!Platform.isAndroid) return;
    await _storage.write(key: _kEnabledKey, value: 'Y');
    await _storage.write(key: _kIntervalKey, value: intervalMinutes.toString());
    await Workmanager().registerPeriodicTask(
      _kUniqueWorkName,
      kWeatherNotiTaskName,
      frequency: Duration(minutes: intervalMinutes),
      constraints: Constraints(networkType: NetworkType.connected),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.update,
    );
    await refreshNotification();
  }

  /// 알림 끄기: 주기 작업 해제 + 알림 제거.
  static Future<void> disable() async {
    if (!Platform.isAndroid) return;
    await _storage.write(key: _kEnabledKey, value: 'N');
    await Workmanager().cancelByUniqueName(_kUniqueWorkName);
    await FlutterLocalNotificationsPlugin().cancel(_kNotificationId);
  }

  /// 현재 위치 기준으로 날씨를 조회해 상시 알림을 갱신한다.
  /// 포그라운드(설정 화면의 '지금 갱신')와 백그라운드(WorkManager) 양쪽에서 호출된다.
  static Future<void> refreshNotification() async {
    if (!Platform.isAndroid) return;
    if (!await isEnabled()) return;

    final (double lat, double lon) = await _resolveLocation();
    final MapAdapter grid = MapAdapter.changeMap(lon, lat);

    final dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
    ));

    // 초단기실황: T1H(기온)·PTY(강수형태)·REH(습도)·RN1(시간당 강수량)
    final Map<String, String> nct = await _fetchCategoryMap(
        dio, '/weather/current', grid.x, grid.y, (e) => e['obsrValue']);
    // 초단기예보: SKY(하늘상태)는 실황에 없어 예보 첫 시간대 값을 쓴다.
    final Map<String, String> fct = await _fetchCategoryMap(
        dio, '/weather/superfct', grid.x, grid.y, (e) => e['fcstValue']);

    final double? temp = double.tryParse(nct['T1H'] ?? '');
    if (temp == null) {
      debugPrint('[WeatherNoti] 기온 없음 → 알림 갱신 생략 (nx=${grid.x}, ny=${grid.y})');
      return;
    }
    final int pty = int.tryParse(nct['PTY'] ?? '0') ?? 0;
    final int sky = int.tryParse(fct['SKY'] ?? '1') ?? 1;
    final String? reh = nct['REH'];
    final String? rn1 = nct['RN1'];

    final String condition = _conditionText(pty, sky);

    // 동네 이름 + 시도(초미세먼지 조회용) — Kakao 역지오코딩(무인증 REST 키, 백그라운드 안전).
    String? dong;
    String? sido;
    try {
      final (String s, String gu, String d) = await KakaoRepo().getAddressbylatlon(lat, lon);
      sido = s;
      dong = d.isNotEmpty ? d : (gu.isNotEmpty ? gu : null);
    } catch (e) {
      debugPrint('[WeatherNoti] 역지오코딩 실패: $e');
    }

    // 초미세먼지(PM2.5) — /weather/mist?sidoName= (plain Dio; AuthDio는 GetX 의존이라 백그라운드 불가).
    String? pm25;
    if (sido != null && sido.isNotEmpty) {
      pm25 = await _fetchPm25(dio, _convertSido(sido));
    }

    // 제목: "맑음 34.5°C"
    final String title = '$condition ${temp.toStringAsFixed(1)}°C';
    // 본문: "초미세먼지 좋음 3㎍/㎥" (측정값 없으면 습도·강수로 폴백)
    final String body;
    if (pm25 != null && pm25.isNotEmpty && pm25 != '-') {
      body = '초미세먼지 ${_pm25GradeText(pm25)} ${pm25}㎍/㎥';
    } else {
      body = [
        if (reh != null) '습도 $reh%',
        if (rn1 != null && rn1 != '0' && pty > 0) '강수 ${rn1}mm',
      ].join(' · ');
    }

    // 헤더(앱 이름 옆 subText)에 동네 이름 → "앱이름 · 홍제1동".
    await _show(title, body, _iconName(pty, sky), await _emojiPng(_emojiFor(pty, sky)), subText: dong);
  }

  /// /weather/mist 응답에서 대표(첫) 관측소의 PM2.5 값을 뽑는다.
  /// 백엔드 래퍼 구조: { code:'00', data:{ items:[ {pm25Value,...}, ... ] } }.
  static Future<String?> _fetchPm25(Dio dio, String sidoName) async {
    try {
      final res = await dio.get('${UrlConfig.baseURL}/weather/mist', queryParameters: {'sidoName': sidoName});
      final body = res.data;
      if (body is! Map || body['code'] != '00') return null;
      final data = body['data'];
      final items = (data is Map) ? data['items'] : null;
      if (items is List && items.isNotEmpty && items.first is Map) {
        return (items.first as Map)['pm25Value']?.toString();
      }
      return null;
    } catch (e) {
      debugPrint('[WeatherNoti] 미세먼지 조회 실패: $e');
      return null;
    }
  }

  // 환경부 초미세먼지(PM2.5) 등급: 0~15 좋음 / 16~35 보통 / 36~75 나쁨 / 76~ 매우나쁨.
  static String _pm25GradeText(String v) {
    final n = int.tryParse(v.trim());
    if (n == null) return '-';
    if (n <= 15) return '좋음';
    if (n <= 35) return '보통';
    if (n <= 75) return '나쁨';
    return '매우나쁨';
  }

  // Kakao 시도명 → AirKorea sidoName(축약형). 예: 서울특별시→서울, 강원특별자치도→강원.
  static String _convertSido(String s) {
    const map = {
      '서울특별시': '서울', '부산광역시': '부산', '대구광역시': '대구', '인천광역시': '인천',
      '광주광역시': '광주', '대전광역시': '대전', '울산광역시': '울산', '세종특별자치시': '세종',
      '경기도': '경기', '강원도': '강원', '강원특별자치도': '강원', '충청북도': '충북', '충청남도': '충남',
      '전라북도': '전북', '전북특별자치도': '전북', '전라남도': '전남', '경상북도': '경북', '경상남도': '경남',
      '제주특별자치도': '제주',
    };
    return map[s] ?? s;
  }

  /// lastKnown → 직전 저장 위치 → 서울시청 순 폴백.
  static Future<(double, double)> _resolveLocation() async {
    try {
      final Position? pos = await Geolocator.getLastKnownPosition();
      if (pos != null) {
        await _storage.write(key: _kLastLatKey, value: pos.latitude.toString());
        await _storage.write(key: _kLastLonKey, value: pos.longitude.toString());
        return (pos.latitude, pos.longitude);
      }
    } catch (e) {
      debugPrint('[WeatherNoti] lastKnown 실패: $e');
    }
    final double? lat = double.tryParse(await _storage.read(key: _kLastLatKey) ?? '');
    final double? lon = double.tryParse(await _storage.read(key: _kLastLonKey) ?? '');
    if (lat != null && lon != null) return (lat, lon);
    return (37.5665, 126.9780);
  }

  /// {category: value} 형태로 변환. 예보(fct)는 같은 카테고리가 시간대별로 여러 건이라
  /// 첫 값(가장 이른 시간대)만 유지한다.
  static Future<Map<String, String>> _fetchCategoryMap(Dio dio, String path,
      int nx, int ny, String? Function(Map<String, dynamic>) pick) async {
    try {
      final res = await dio.get('${UrlConfig.baseURL}$path',
          queryParameters: {'nx': nx, 'ny': ny});
      final data = res.data;
      if (data is! Map || data['code'] != '00' || data['data'] is! List) return {};
      final Map<String, String> out = {};
      for (final item in data['data'] as List) {
        final Map<String, dynamic> e = Map<String, dynamic>.from(item as Map);
        final String? cat = e['category'] as String?;
        final String? val = pick(e)?.toString();
        if (cat != null && val != null && !out.containsKey(cat)) out[cat] = val;
      }
      return out;
    } catch (e) {
      debugPrint('[WeatherNoti] $path 조회 실패: $e');
      return {};
    }
  }

  // PTY(강수형태) 우선, 없으면 SKY(하늘상태).
  static String _conditionText(int pty, int sky) {
    switch (pty) {
      case 1:
        return '비';
      case 2:
        return '비/눈';
      case 3:
        return '눈';
      case 5:
        return '빗방울';
      case 6:
        return '빗방울·눈날림';
      case 7:
        return '눈날림';
    }
    switch (sky) {
      case 3:
        return '구름많음';
      case 4:
        return '흐림';
    }
    return '맑음';
  }

  static String _iconName(int pty, int sky) {
    if (pty == 3 || pty == 7) return 'ic_stat_w_snow';
    if (pty > 0) return 'ic_stat_w_rain';
    if (sky >= 3) return 'ic_stat_w_cloud';
    return 'ic_stat_w_sunny';
  }

  // 알림 패널 우측에 표시할 컬러 이모지 (상태바 아이콘은 OS 제약상 단색이라 별도)
  static String _emojiFor(int pty, int sky) {
    if (pty == 3 || pty == 7) return '❄️';
    if (pty == 2 || pty == 6) return '🌨️';
    if (pty > 0) return '🌧️';
    if (sky == 4) return '☁️';
    if (sky == 3) return '⛅';
    return '☀️';
  }

  /// 이모지를 128x128 PNG로 렌더링(별도 이미지 에셋 불필요).
  /// workmanager 콜백은 헤드리스 엔진의 루트 isolate라 dart:ui 사용 가능.
  static Future<Uint8List?> _emojiPng(String emoji) async {
    try {
      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);
      final pb = ui.ParagraphBuilder(ui.ParagraphStyle(fontSize: 96, textAlign: ui.TextAlign.center))..addText(emoji);
      final paragraph = pb.build()..layout(const ui.ParagraphConstraints(width: 128));
      canvas.drawParagraph(paragraph, ui.Offset(0, (128 - paragraph.height) / 2));
      final image = await recorder.endRecording().toImage(128, 128);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      return bytes?.buffer.asUint8List();
    } catch (e) {
      debugPrint('[WeatherNoti] 이모지 렌더링 실패: $e');
      return null;
    }
  }

  static Future<void> _show(String title, String body, String icon, Uint8List? largeIconPng,
      {String? subText}) async {
    final plugin = FlutterLocalNotificationsPlugin();
    // 백그라운드 isolate에서도 안전하도록 매번 초기화(이미 초기화됐어도 무해).
    await plugin.initialize(
      const InitializationSettings(android: AndroidInitializationSettings('@mipmap/ic_launcher')),
    );
    try {
      await plugin.show(_kNotificationId, title, body, _details(icon, largeIconPng, subText));
    } on PlatformException catch (e) {
      // 일부 릴리즈 빌드/Android 버전에서 상태바 아이콘 리소스를 못 찾는 경우(invalid_icon):
      // 실패 대신 기본(런처) 아이콘으로 폴백해 알림 자체는 표시되게 한다.
      // (icon=null → initialize()의 기본 아이콘 @mipmap/ic_launcher 사용 — 래스터라 전 버전 안전)
      debugPrint('[WeatherNoti] 아이콘 실패 → 기본 아이콘 폴백: $e');
      await plugin.show(_kNotificationId, title, body, _details(null, largeIconPng, subText));
    }
  }

  static NotificationDetails _details(String? icon, Uint8List? largeIconPng, String? subText) {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        'weather_ongoing',
        '날씨 상태바 알림',
        channelDescription: '상태바에 현재 날씨를 상시 표시합니다.',
        importance: Importance.low, // 무음 + 상태바 아이콘 유지
        priority: Priority.low,
        ongoing: true,
        autoCancel: false,
        onlyAlertOnce: true,
        showWhen: false,
        subText: subText, // 헤더(앱 이름 옆)에 "HH:mm 갱신" 표시
        icon: icon,
        largeIcon: largeIconPng != null ? ByteArrayAndroidBitmap(largeIconPng) : null,
        silent: true,
      ),
    );
  }
}
