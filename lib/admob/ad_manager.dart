import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:project1/admob/ad_unit_ids.dart';
import 'package:project1/root/cntr/root_cntr.dart';
import 'package:project1/utils/log_utils.dart';

class AdManager {
  static final AdManager _instance = AdManager._internal();
  factory AdManager() => _instance;
  AdManager._internal();

  final Map<String, AdManagerBannerAd> _bannerAds = {};
  late final Map<String, String> _adUnitIds;
  final Map<String, Timer> _adTimers = {}; // 광고 갱신을 위한 타이머
  bool _initialized = false;
  final Completer<void> _initCompleter = Completer<void>();

  static Future<void> initialize({required TargetPlatform targetPlatform}) async {
    await MobileAds.instance.initialize();
    _instance._adUnitIds = Platform.isIOS ? AdUnitIds.ios : AdUnitIds.android;
    _instance._initialized = true;
    if (!_instance._initCompleter.isCompleted) {
      _instance._initCompleter.complete();
    }
  }

  bool isTestMode() {
    if (kDebugMode) {
      return true;
    } else {
      // In a real app, you might want to use a more sophisticated method
      // to determine if it's in test mode, such as checking for specific device IDs
      return false;
    }
  }

  Future<void> loadBannerAd(String screenName) async {
    // 초기화가 완료될 때까지 대기한다. (main.dart에서 unawaited로 호출될 수 있음)
    if (!_initialized) {
      try {
        await _initCompleter.future.timeout(const Duration(seconds: 30));
      } catch (e) {
        // 저사양 콜드스타트에서 SDK 초기화가 늦으면 예외로 죽지 않고 재시도를 예약한다.
        // (이전: 10초 초과 시 예외 → 첫 탭(날씨 메인)만 앱 재시작 전까지 배너 영구 공백)
        lo.g('AdManager init 대기 초과($screenName), 10초 후 재시도: $e');
        Future.delayed(const Duration(seconds: 10), () => loadBannerAd(screenName));
        return;
      }
    }

    if (_bannerAds.containsKey(screenName)) {
      // 이미 로드된 광고가 있으면 상태만 다시 업데이트한다.
      Get.find<RootCntr>().updateAdLoadingStatus(screenName, true);
      return;
    }

    // 화면 진입 등 명시적 재요청은 재시도 카운터를 리셋해 백오프를 처음부터 다시 준다.
    _retryAttempts.remove(screenName);
    await _createAndLoadBannerAd(screenName);
  }

  /// 배너 슬롯이 화면에 보이는데 광고가 없으면 재로드를 시도한다(30초 디바운스).
  /// 날씨 메인처럼 initState가 1회뿐인 탭(IndexedStack)에서 콜드스타트 실패를 자가치유한다.
  void ensureBannerAd(String screenName) {
    if (_bannerAds.containsKey(screenName)) return;
    if (_loading[screenName] == true) return;
    final last = _lastAttempt[screenName];
    if (last != null && DateTime.now().difference(last) < const Duration(seconds: 30)) return;
    loadBannerAd(screenName);
  }

  void _startAdTimer(String screenName) {
    _adTimers[screenName]?.cancel(); // 기존 타이머가 있으면 취소
    _adTimers[screenName] = Timer.periodic(const Duration(minutes: 5), (timer) {
      _createAndLoadBannerAd(screenName); // 5분마다 광고 갱신
    });
  }

  /// 디버그 모드에서는 Google 공식 테스트 광고 ID를 사용한다.
  String _resolveAdUnitId(String screenName) {
    if (kDebugMode) {
      return Platform.isIOS
          ? 'ca-app-pub-3940256099942544/2934735716'
          : 'ca-app-pub-3940256099942544/6300978111';
    }
    final adUnitId = _adUnitIds[screenName];
    if (adUnitId == null) {
      throw Exception('Ad unit ID not found for screen: $screenName');
    }
    return adUnitId;
  }

  Future<void> _createAndLoadBannerAd(String screenName) async {
    // 동일 화면 중복 로드 방지(ensure/재시도가 겹쳐 불려도 요청은 1건).
    if (_loading[screenName] == true) return;
    _loading[screenName] = true;
    _lastAttempt[screenName] = DateTime.now();
    try {
      final adUnitId = _resolveAdUnitId(screenName);

      // 기존 광고가 있다면 정리 후 새로 로드한다.
      _bannerAds[screenName]?.dispose();
      _bannerAds.remove(screenName);
      _adTimers[screenName]?.cancel();

      final ad = AdManagerBannerAd(
        adUnitId: adUnitId,
        request: const AdManagerAdRequest(nonPersonalizedAds: true),
        sizes: [AdSize.banner],
        listener: AdManagerBannerAdListener(
          onAdLoaded: (Ad ad) {
            lo.g('$AdManagerBannerAd loaded for $screenName.');
            _loading[screenName] = false;
            Get.find<RootCntr>().updateAdLoadingStatus(screenName, true);
            _startAdTimer(screenName);
            _handleAdRetry(screenName, reset: true); // 재시도 카운터 리셋
          },
          onAdFailedToLoad: (Ad ad, LoadAdError error) {
            lo.g('$AdManagerBannerAd failedToLoad for $screenName: $error');
            _loading[screenName] = false;
            Get.find<RootCntr>().updateAdLoadingStatus(screenName, false);
            ad.dispose();
            _bannerAds.remove(screenName);
            _handleAdRetry(screenName); // 재시도 로직 호출
          },
          onAdOpened: (Ad ad) => lo.g('$AdManagerBannerAd onAdOpened for $screenName.'),
          onAdClosed: (Ad ad) => lo.g('$AdManagerBannerAd onAdClosed for $screenName.'),
        ),
      );

      await ad.load();
      _bannerAds[screenName] = ad;
    } catch (e) {
      lo.g('Error creating banner ad for $screenName: $e');
      _loading[screenName] = false;
      Get.find<RootCntr>().updateAdLoadingStatus(screenName, false);
      _handleAdRetry(screenName); // 예외(초기화 지연 등)도 백오프 재시도
    }
  }

  final Map<String, int> _retryAttempts = {};
  final Map<String, bool> _loading = {};
  final Map<String, DateTime> _lastAttempt = {};
  final int maxRetryAttempts = 5;

  void _handleAdRetry(String screenName, {bool reset = false}) {
    if (reset) {
      _retryAttempts.remove(screenName);
      return;
    }

    _retryAttempts[screenName] = (_retryAttempts[screenName] ?? 0) + 1;

    if (_retryAttempts[screenName]! <= maxRetryAttempts) {
      // 지수 백오프(최대 60초 캡) — 콜드스타트 네트워크 혼잡 구간을 넘길 수 있게.
      final int seconds = min(pow(2, _retryAttempts[screenName]!).toInt(), 60);
      Future.delayed(Duration(seconds: seconds), () {
        if (_bannerAds[screenName] == null) {
          _createAndLoadBannerAd(screenName);
        }
      });
    } else {
      // 소진 후에도 영구 포기하지 않는다 — 5분 쿨다운 후 카운터를 리셋하고 재시도.
      // (이전: 3회 소진 시 영구 공백 → initState가 1회뿐인 날씨 메인 탭은 앱 재시작 전까지 광고 없음)
      _retryAttempts.remove(screenName);
      Future.delayed(const Duration(minutes: 5), () {
        if (_bannerAds[screenName] == null) {
          _createAndLoadBannerAd(screenName);
        }
      });
    }
  }

  void _cleanupAd(String screenName) {
    _bannerAds[screenName]?.dispose();
    _bannerAds.remove(screenName);
    _adTimers[screenName]?.cancel();
    _adTimers.remove(screenName);
    _retryAttempts.remove(screenName);
  }

  void disposeAllAds() {
    for (final screenName in _bannerAds.keys.toList()) {
      _cleanupAd(screenName);
    }
    disposeInterstitialAd();
    Get.find<RootCntr>().adLoadingStatus.clear();
  }

  AdManagerBannerAd? getBannerAd(String screenName) {
    return _bannerAds[screenName];
  }

  void disposeBannerAd(String screenName) {
    _bannerAds[screenName]?.dispose();
    _bannerAds.remove(screenName);
    _adTimers[screenName]?.cancel(); // 타이머 취소
    _adTimers.remove(screenName);
    Get.find<RootCntr>().updateAdLoadingStatus(screenName, false);
  }

  InterstitialAd? _interstitialAd;
  bool _isInterstitialAdReady = false;

  bool get isInterstitialReady => _isInterstitialAdReady;

  /// 전면광고 로드. 영상 피드(틱톡형) 5장마다 노출에 사용.
  /// 광고 유닛은 'VideoPage'(전면광고)로 고정 — 안드 .../9035579155, iOS .../8309654992
  Future<void> loadInterstitialAd({String screenName = 'VideoPage'}) async {
    final adUnitId = _adUnitIds[screenName] ?? '';
    if (adUnitId.isEmpty) {
      lo.g('InterstitialAd adUnitId 없음: $screenName');
      return;
    }
    await InterstitialAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (InterstitialAd ad) {
          _interstitialAd = ad;
          _isInterstitialAdReady = true;
          Get.find<RootCntr>().updateInterstitialAdStatus(true);

          // 광고가 닫히거나 표시 실패하면 즉시 다음 광고를 미리 로드한다(연속 노출 대비).
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (InterstitialAd ad) {
              ad.dispose();
              _interstitialAd = null;
              _isInterstitialAdReady = false;
              loadInterstitialAd(screenName: screenName);
            },
            onAdFailedToShowFullScreenContent: (InterstitialAd ad, AdError error) {
              ad.dispose();
              _interstitialAd = null;
              _isInterstitialAdReady = false;
              loadInterstitialAd(screenName: screenName);
            },
          );
        },
        onAdFailedToLoad: (LoadAdError error) {
          lo.g('InterstitialAd failed to load: $error');
          _isInterstitialAdReady = false;
          Get.find<RootCntr>().updateInterstitialAdStatus(false);
        },
      ),
    );
  }

  void showInterstitialAd() {
    if (_isInterstitialAdReady && _interstitialAd != null) {
      _interstitialAd?.show();
      _isInterstitialAdReady = false;
      Get.find<RootCntr>().updateInterstitialAdStatus(false);
    }
  }

  void disposeInterstitialAd() {
    _interstitialAd?.dispose();
    _interstitialAd = null;
    _isInterstitialAdReady = false;
    Get.find<RootCntr>().updateInterstitialAdStatus(false);
  }
}
