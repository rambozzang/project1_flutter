import 'dart:io';
// import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:hashtagable_v3/widgets/hashtag_text_field.dart';
import 'package:latlong2/latlong.dart';
import 'package:pretty_animated_text/pretty_animated_text.dart';
import 'package:project1/app/feel/widgets/feel_selector_widget.dart';
import 'package:project1/app/weather/models/geocode.dart';
import 'package:project1/app/weathergogo/services/location_service.dart';
import 'package:project1/app/weathergogo/services/weather_data_processor.dart';
import 'package:project1/repo/board/data/board_save_data.dart';
import 'package:project1/repo/board/data/board_save_main_data.dart';
import 'package:project1/repo/board/data/board_save_weather_data.dart';
import 'package:project1/repo/weather/data/current_weather.dart';
import 'package:project1/app/weathergogo/cntr/data/current_weather_data.dart';
import 'package:project1/app/weathergogo/cntr/weather_gogo_cntr.dart';
import 'package:project1/app/weathergogo/theme/sky_gradient.dart';
import 'package:project1/repo/weather/data/weather_view_data.dart';
import 'package:project1/repo/weather_gogo/models/response/super_fct/super_fct_model.dart';
import 'package:project1/repo/weather_gogo/repository/weather_gogo_caching.dart';
import 'package:project1/repo/weather_gogo/repository/weather_gogo_repo.dart';
import 'package:project1/root/cntr/root_cntr.dart';
import 'package:project1/utils/log_utils.dart';
import 'package:project1/utils/utils.dart';
import 'package:project1/widget/custom_button.dart';
import 'package:project1/widget/custom_indicator_offstage.dart';
// import 'package:video_compress/video_compress.dart';
import 'package:video_player/video_player.dart';

import 'package:intl/intl.dart' as intl;

// 동영상 압축 FFmpeg로 동영상 압축하기
class VideoRegPage extends StatefulWidget {
  const VideoRegPage({super.key, required this.videoFile});
  final File videoFile;

  @override
  State<VideoRegPage> createState() => _VideoRegPageState();
}

class _VideoRegPageState extends State<VideoRegPage> with TickerProviderStateMixin {
  late VideoPlayerController _videoController;
  final TextEditingController hashTagController = TextEditingController();
  final FocusNode hashTagFocusNode = FocusNode();
  // late Subscription _subscription;
  // late MediaInfo? pickedFile;

  // ValueNotifier<CurrentWeather?> currentWeather = ValueNotifier<CurrentWeather?>(null);

  ValueNotifier<String?> localName = ValueNotifier<String?>(null);
  ValueNotifier<TotalData?> totalData = ValueNotifier<TotalData?>(null);

  final ValueNotifier<bool> isUploading = ValueNotifier<bool>(false);
  final ValueNotifier<bool> isWeathering = ValueNotifier<bool>(false);

  late Position? position;

  late String? thumbnailFile;
  BoardSaveData boardSaveData = BoardSaveData();

  // 사용자가 선택한 체감 날씨 태그 (HELL/HOT/.../WINDY)
  String? selectedFeelCd;

  bool isCancle = false;
  Duration durationOfVideo = Duration.zero;
  bool initVideo = false;
  String hideYn = 'N';
  String anonyYn = 'N';

  bool _hideChecked = false;
  bool _anonyChecked = false;
  late AnimationController _hideController;
  late AnimationController _anonyController;

  late Animation<double> _hideScaleAnimation;
  late Animation<double> _anonyScaleAnimation;

  final ValueNotifier<bool> soundOff = ValueNotifier<bool>(false);

  final WeatherService weatherService = WeatherService();

  ValueNotifier<CurrentWeatherData?> currentWeather = ValueNotifier<CurrentWeatherData?>(null);
  ValueNotifier<GeocodeData?> geocodeData = ValueNotifier<GeocodeData?>(null);
  ValueNotifier<MistViewData?> mistData = ValueNotifier<MistViewData?>(null);

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      initializeVideo();
      // 날씨는 화면에서 미리 받지 않는다.
      // 게시 시 백그라운드 업로드와 병렬로 수집되어 저장된다. (WeatherForBoard)
    });
    _initAnimationController();
  }

  void _initAnimationController() {
    _hideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _hideScaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(
        parent: _hideController,
        curve: Curves.easeInOut,
      ),
    );

    _anonyController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _anonyScaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(
        parent: _anonyController,
        curve: Curves.easeInOut,
      ),
    );
  }

  Future<void> _retryInitialization() async {
    lo.g('retryInitialization');
    await Future.delayed(const Duration(seconds: 1));
    initializeVideo();
  }

  void _toggleHideCheckbox() {
    setState(() {
      _hideChecked = !_hideChecked;
      hideYn = _hideChecked ? 'Y' : 'N';
      if (_hideChecked) {
        _hideController.forward();
      } else {
        _hideController.reverse();
      }
    });
  }

  void _toggleAnonyCheckbox() {
    setState(() {
      _anonyChecked = !_anonyChecked;
      anonyYn = _anonyChecked ? 'Y' : 'N';
      if (_anonyChecked) {
        _anonyController.forward();
      } else {
        _anonyController.reverse();
      }
    });
  }

  void initializeVideo() async {
    try {
      lo.g("initializeVideo() widget.videoFile : ${widget.videoFile.path}");
      // 초기화 전 딜레이 추가
      await Future.delayed(const Duration(milliseconds: 300));

      _videoController = VideoPlayerController.file(
        widget.videoFile,
        videoPlayerOptions: VideoPlayerOptions(mixWithOthers: false, allowBackgroundPlayback: false),
      );
      await _videoController.initialize().then((a) {
        setState(() {
          _videoController.setLooping(true);
          _videoController.play();
          initVideo = true;
          durationOfVideo = _videoController.value.duration;
        });
      });

      _videoController.addListener(() {
        if (_videoController.value.hasError) {
          lo.g('Video error: ${_videoController.value.errorDescription}');
          // 재시도 로직
          _retryInitialization();
        }
      });
    } catch (e) {
      Utils.alert("비디오초기화 오류 : $e");
      lo.g("initializeVideo() error : $e");
      _retryInitialization();
    }
  }

  int retryCount = 3;

  void initData() {
    geocodeData.value = Get.find<WeatherGogoCntr>().currentLocation.value;
    mistData.value = Get.find<WeatherGogoCntr>().mistData.value;
    currentWeather.value = Get.find<WeatherGogoCntr>().currentWeather.value;
  }

  int retry = 3;
  Future<void> getDate() async {
    try {
      isWeathering.value = true;

      // 현재위치와 지명 가져오기
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 5),
      );
      LatLng location = LatLng(position.latitude, position.longitude);

      LocationService locationService = LocationService();
      var (onValue1, onValue2) = await locationService.getLocalName(location);

      // 지명 조회 실패시 재시도
      if (onValue1 == null || onValue2 == null) {
        if (Get.find<WeatherGogoCntr>().currentLocation.value.addr == null ||
            Get.find<WeatherGogoCntr>().currentLocation.value.name == '') {
          if (retry > 0 && onValue1 == '') {
            retry--;
            lo.g("지명 조회 재시도 (남은 시도: $retry)");
            await Future.delayed(const Duration(milliseconds: 300));
            return await getDate();
          }
        } else {
          onValue2 = Get.find<WeatherGogoCntr>().currentLocation.value.name;
          onValue1 = Get.find<WeatherGogoCntr>().currentLocation.value.addr!.split(' ')[0];
        }
      }

      // 미세먼지 가져오기
      geocodeData.value = GeocodeData(name: onValue2!, latLng: location);
      mistData.value = (await locationService.getMistData(onValue1!))!;

      // 현재 위치 날씨 가져오기
      WeatherGogoRepo repo = WeatherGogoRepo();

      // 기본 날씨
      CurrentWeatherData currentWeatherData = Get.find<WeatherGogoCntr>().currentWeather.value;
      lo.g("currentWeatherData : ${currentWeatherData.toString()}");
      isWeathering.value = false;
      String fcstDate = currentWeatherData.fcstDate ?? intl.DateFormat('yyyyMMdd').format(DateTime.now());
      String fcstTime = currentWeatherData.fcsTime!;

      currentWeather.value = currentWeatherData;

      // location = const LatLng(0.0, 0.0);
      // List<ItemSuperFct> itemFctList = [];
      List<ItemSuperFct> itemFctList = [];
      try {
        itemFctList = await repo.getSuperFctListJson(location);
      } catch (e) {
        lo.g("getDate() error : $e");
        isWeathering.value = false;
        currentWeather.value = currentWeatherData;
      }

      if (itemFctList.isNotEmpty) {
        fcstDate = itemFctList.first.fcstDate!;
        fcstTime = itemFctList.first.fcstTime!;
        // 날씨 데이터 처리...
        for (var item in itemFctList) {
          if (item.fcstDate.toString() == fcstDate && item.fcstTime.toString() == fcstTime) {
            if (item.category == 'T1H') {
              currentWeatherData.temp = item.fcstValue!;
            } else if (item.category == 'PTY') {
              currentWeatherData.rain = item.fcstValue!;
            } else if (item.category == 'SKY') {
              currentWeatherData.sky = item.fcstValue!;
            } else if (item.category == 'REH') {
              currentWeatherData.humidity = item.fcstValue!;
            } else if (item.category == 'WSD') {
              currentWeatherData.speed = item.fcstValue!;
            }
          }
        }
      }

      // 필수 날씨 데이터가 없는 경우 체크
      // if (currentWeatherData.temp == null || currentWeatherData.sky == null || currentWeatherData.rain == null) {
      //   return await getDate();
      // }

      currentWeatherData.description =
          WeatherDataProcessor.instance.combineWeatherCondition(currentWeatherData.sky.toString(), currentWeatherData.rain.toString());

      currentWeather.value = currentWeatherData;
      lo.g('currentWeather : ${currentWeather.value}');

      isWeathering.value = false;
      return;
    } catch (e) {
      lo.g("getDate() error : $e");

      if (retry > 0) {
        retry--;
        lo.g("에러로 인한 재시도 (남은 시도: $retry)");
        await Future.delayed(const Duration(seconds: 1));
        return await getDate();
      } else {
        // 모든 재시도 실패 시
        // Utils.alert("날씨 정보를 가져오는데 실패했습니다. 잠시 후 다시 시도해주세요.");
        isWeathering.value = false; // 버튼 비활성화 유지
      }
    }
  }

  // ��일 업로드
  Future<void> upload() async {
    isUploading.value = true;
    try {
      // 본문(캡션/공개여부)만 담는다.
      // 날씨(boardWeatherVo)는 게시 후 백그라운드 업로드와 병렬로 수집되어
      // 저장 직전에 합쳐진다. (RootCntr.uploadCloudflare + WeatherForBoard)
      boardSaveData.boardMastInVo = _createBoardSaveMainData();
      // 날씨 본체는 백그라운드에서 수집하지만, 사용자가 고른 체감 태그는 여기서 실어 보낸다.
      // (RootCntr.uploadCloudflare 가 저장 직전 weatherVo.feelCd 로 보존한다.)
      boardSaveData.boardWeatherVo = BoardSaveWeatherData()..feelCd = selectedFeelCd;

      _showUploadAlert();

      Future.delayed(const Duration(milliseconds: 500), () {
        Get.back();
      });
    } catch (e) {
      debugPrint(e.toString());
      isUploading.value = false;
    }
  }

  BoardSaveMainData _createBoardSaveMainData() {
    return BoardSaveMainData()
      ..contents = hashTagController.text
      ..depthNo = '0'
      ..notiEdAt = ''
      ..notiStAt = ''
      ..subject = ''
      ..typeCd = 'V'
      ..typeDtCd = 'V'
      ..anonyYn = anonyYn
      ..hideYn = hideYn;
  }

  BoardSaveWeatherData _createBoardSaveWeatherData() {
    final weather = currentWeather.value ?? CurrentWeatherData();
    final location = Get.find<WeatherGogoCntr>();

    return BoardSaveWeatherData()
      ..boardId = 0
      ..city = ''
      ..country = ''
      ..currentTemp = weather.temp ?? '0'
      ..humidity = weather.humidity?.toString() ?? '1'
      ..lat = geocodeData.value?.latLng.latitude.toString() ?? '1'
      ..lon = geocodeData.value?.latLng.longitude.toString() ?? '1'
      ..speed = weather.speed?.toString() ?? '1'
      ..sky = weather.sky?.toString() ?? '1'
      ..rain = weather.rain?.toString() ?? '0'
      ..tempMax = ''
      ..tempMin = ''
      ..location = location.currentLocation.value.name ?? '대한민국'
      ..weatherInfo = weather.description ?? '맑음'
      ..mist10 = location.mistData.value.mist10Grade.toString()
      ..mist25 = location.mistData.value.mist25Grade.toString();
  }

  void _showUploadAlert() {
    if (hideYn == "Y") {
      Utils.alert('숨기기 상태로 등록중 입니다!');
    } else if (anonyYn == "Y") {
      Utils.alert('익명으로 등록중 입니다!');
    } else {
      Utils.alert('업로드중 입니다! 잠시후 정상 게시됩니다!');
    }
  }

  void cancle() {
    FocusScope.of(context).unfocus();
    sleep(const Duration(milliseconds: 500));
    if (isUploading.value == true) {
      return;
    }
    Utils.showConfirmDialog('나가기', '영상이 삭제됩니다. 나가겠습니까?', BackButtonBehavior.none, confirm: () async {
      Lo.g('cancel');
      isCancle = true;
      Navigator.of(context).pop();
    }, cancel: () async {
      Lo.g('cancel');
    }, backgroundReturn: () {});
  }

  @override
  void dispose() {
    _videoController.removeListener(() {});
    _videoController.setVolume(0);
    _videoController.dispose();
    _hideController.dispose();
    _anonyController.dispose();
    hashTagController.dispose();
    isUploading.dispose();
    _policyOpen.dispose();

    super.dispose();
    //실제 Root 페이지 에서 동영상 업로드 처리
    if (!isCancle) {
      Get.find<RootCntr>().goTimer(widget.videoFile, boardSaveData);
    }
  }

  // ── 디자인 토큰 (앱의 하늘/다크 무드와 통일) ──
  static const Color _bgTop = Color(0xFF121A38);
  static const Color _bgMid = Color(0xFF1A2348);
  static const Color _bgBot = Color(0xFF0B0F22);
  static const Color _surface = Color(0x14FFFFFF); // 흰색 8% — 은은한 표면
  static const Color _surfaceBorder = Color(0x1FFFFFFF); // 흰색 12% — 헤어라인
  static const Color _accent = Color(0xFF4C8DFF); // 하늘빛 블루 액센트
  static const Color _textHi = Color(0xFFF2F5FA);
  static const Color _textLo = Color(0xFF9AA6C2);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgBot,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        title: const Text('새 영상',
            style: TextStyle(color: _textHi, fontSize: 17, fontWeight: FontWeight.w700, letterSpacing: -0.2)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _textHi, size: 20),
          onPressed: () => cancle(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.close_rounded, color: _textLo, size: 24),
            onPressed: () => cancle(),
          ),
        ],
      ),
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          // 앱의 '시간대별 하늘'과 동일한 배경 → 화면 통일감
          Positioned.fill(child: Container(decoration: SkyGradient.decoration(DateTime.now()))),
          // 가독성을 위한 은은한 다크 스크림 (상·하단을 조금 더 어둡게)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.45),
                    Colors.black.withOpacity(0.20),
                    Colors.black.withOpacity(0.55),
                  ],
                  stops: const [0.0, 0.45, 1.0],
                ),
              ),
            ),
          ),
          Column(
            children: [
              Expanded(child: _buildBody()),
              _buildBottomBar(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) => _handlePopInvoked(didPop),
      // onPopInvoked: _handlePopInvoked,
      child: GestureDetector(
        onTap: () => hashTagFocusNode.unfocus(),
        child: SafeArea(
          child: Stack(
            children: [
              _buildMainContent(),
              _buildLoadingIndicator(),
              // _buildCloseButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 인스타그램식 컴포저: 썸네일(좌) + 캡션(우)
          _buildComposerRow(),
          const Gap(10),
          _igDivider(),
          // 설정 행들 (좌: 아이콘+설명, 우: 스위치)
          _settingRow(
            icon: _hideChecked ? Icons.lock_outline_rounded : Icons.public_rounded,
            title: '비공개로 게시',
            subtitle: _hideChecked ? '나만 볼 수 있어요' : '모두에게 공개돼요',
            value: _hideChecked,
            onChanged: (_) => _toggleHideCheckbox(),
          ),
          _igDivider(),
          _settingRow(
            icon: _anonyChecked ? Icons.person_off_outlined : Icons.person_outline_rounded,
            title: '익명으로 게시',
            subtitle: _anonyChecked ? '닉네임을 숨겨요' : '내 닉네임이 표시돼요',
            value: _anonyChecked,
            onChanged: (_) => _toggleAnonyCheckbox(),
          ),
          _igDivider(),
          _autoWeatherRow(),
          _igDivider(),
          // 체감 날씨 태그 선택 (사용자 주관 입력 — 자동 수집되는 날씨와 별개)
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: FeelSelectorWidget(
              selectedFeelCd: selectedFeelCd,
              onSelected: (code) => setState(() => selectedFeelCd = code),
            ),
          ),
          _igDivider(),
          _policyRow(),
          const Gap(8),
        ],
      ),
    );
  }

  // ── 인스타그램식 상단 컴포저 (썸네일 + 캡션) ──
  Widget _buildComposerRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildVideoThumb(),
        const Gap(12),
        Expanded(child: _buildCaptionField()),
      ],
    );
  }

  // 컴팩트 영상 썸네일 (탭 → 전체화면)
  Widget _buildVideoThumb() {
    const double w = 104, h = 164;
    void openFull() {
      Navigator.push<_PlayerVideoAndPopPage>(
        context,
        MaterialPageRoute<_PlayerVideoAndPopPage>(
          builder: (BuildContext context) => _PlayerVideoAndPopPage(videoPlayerController: _videoController),
        ),
      );
    }

    if (!initVideo) {
      return Container(
        width: w,
        height: h,
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _surfaceBorder),
        ),
        alignment: Alignment.center,
        child: const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: _accent)),
      );
    }

    return GestureDetector(
      onTap: openFull,
      child: SizedBox(
        width: w,
        height: h,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Stack(
            fit: StackFit.expand,
            children: [
              FittedBox(
                fit: BoxFit.cover,
                clipBehavior: Clip.hardEdge,
                child: SizedBox(
                  width: _videoController.value.size.width,
                  height: _videoController.value.size.height,
                  child: VideoPlayer(_videoController),
                ),
              ),
              // 재생시간 + 전체화면 힌트
              Positioned(
                left: 6,
                bottom: 6,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(color: Colors.black.withOpacity(0.5), borderRadius: BorderRadius.circular(7)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.play_arrow_rounded, size: 12, color: Colors.white),
                      const Gap(2),
                      Text(formatMilliseconds(durationOfVideo.inMilliseconds),
                          style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
              const Positioned(top: 6, right: 6, child: Icon(Icons.fullscreen_rounded, size: 18, color: Colors.white)),
            ],
          ),
        ),
      ),
    );
  }

  // ── 설정 행 (인스타식: 아이콘 + 제목/부제 + 스위치) ──
  Widget _settingRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 22, color: value ? _accent : _textLo),
          const Gap(14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 15, color: _textHi, fontWeight: FontWeight.w600)),
                Text(subtitle, style: const TextStyle(fontSize: 12, color: _textLo)),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeColor: Colors.white,
            activeTrackColor: _accent,
            inactiveThumbColor: Colors.white,
            inactiveTrackColor: const Color(0x33FFFFFF),
          ),
        ],
      ),
    );
  }

  // 위치·날씨 자동 첨부 안내 행
  Widget _autoWeatherRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          const Icon(Icons.auto_awesome_rounded, size: 22, color: _accent),
          const Gap(14),
          const Expanded(
            child: Text('촬영한 곳의 날씨·위치가 자동으로 함께 기록돼요.',
                style: TextStyle(fontSize: 14, color: _textHi, height: 1.3)),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: _accent.withOpacity(0.16), borderRadius: BorderRadius.circular(8)),
            child: const Text('자동', style: TextStyle(fontSize: 11, color: _accent, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  // 게시 정책 행 (탭 → 펼치기)
  Widget _policyRow() {
    return ValueListenableBuilder<bool>(
      valueListenable: _policyOpen,
      builder: (context, open, _) {
        return Column(
          children: [
            InkWell(
              onTap: () => _policyOpen.value = !open,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Row(
                  children: [
                    const Icon(Icons.shield_outlined, size: 22, color: _textLo),
                    const Gap(14),
                    const Expanded(
                      child: Text('게시 정책 · 저작권 안내',
                          style: TextStyle(fontSize: 15, color: _textHi, fontWeight: FontWeight.w600)),
                    ),
                    AnimatedRotation(
                      turns: open ? 0.5 : 0,
                      duration: const Duration(milliseconds: 220),
                      child: const Icon(Icons.keyboard_arrow_down_rounded, color: _textLo, size: 22),
                    ),
                  ],
                ),
              ),
            ),
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 220),
              crossFadeState: open ? CrossFadeState.showSecond : CrossFadeState.showFirst,
              firstChild: const SizedBox(width: double.infinity, height: 0),
              secondChild: const Padding(
                padding: EdgeInsets.only(left: 36, bottom: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _PolicyLine(icon: Icons.music_note_rounded, text: '음악 저작권: 허락 없는 음원 사용 시 게시가 제한되거나 법적 책임이 따를 수 있어요. 저작권 free 음원을 권장합니다.'),
                    Gap(10),
                    _PolicyLine(icon: Icons.gavel_rounded, text: '금지 콘텐츠: 불법·성적·폭력·혐오 영상은 즉시 삭제되며 계정 정지 및 법적 조치 대상이 됩니다.'),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _igDivider() => Container(height: 1, color: const Color(0x14FFFFFF));

  // 섹션 라벨 (좌측 정렬, 절제된 톤)
  Widget _buildSectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 2),
      child: Text(
        text,
        style: const TextStyle(fontSize: 13, color: _textLo, fontWeight: FontWeight.w700, letterSpacing: 0.2),
      ),
    );
  }

  // 촬영 위치·날씨가 자동으로 함께 기록된다는 안내 (날씨 UI를 없앤 대신)
  Widget _buildAutoWeatherHint() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: _accent.withOpacity(0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _accent.withOpacity(0.28)),
      ),
      child: const Row(
        children: [
          Icon(Icons.auto_awesome_rounded, size: 16, color: _accent),
          Gap(8),
          Expanded(
            child: Text(
              '촬영한 곳의 날씨와 위치가 게시할 때 자동으로 함께 기록돼요.',
              style: TextStyle(fontSize: 12.5, height: 1.35, color: _textHi),
            ),
          ),
        ],
      ),
    );
  }

  // ── 캡션 입력 (인스타식: 썸네일 옆 무테두리 멀티라인) ──
  Widget _buildCaptionField() {
    return GestureDetector(
      onTap: () => FocusScope.of(context).requestFocus(hashTagFocusNode),
      child: Container(
        height: 164, // 썸네일 높이에 맞춰 정렬
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _surfaceBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 입력칸임을 분명히 알리는 라벨
            Row(
              children: [
                const Icon(Icons.edit_note_rounded, size: 17, color: _accent),
                const Gap(5),
                const Text('문구 입력', style: TextStyle(fontSize: 12.5, color: _accent, fontWeight: FontWeight.w700)),
                const Spacer(),
                Text('# 태그',
                    style: TextStyle(fontSize: 11, color: _textLo.withOpacity(0.9), fontWeight: FontWeight.w600)),
              ],
            ),
            const Gap(6),
            Expanded(
              child: HashTagTextField(
                controller: hashTagController,
                basicStyle: const TextStyle(fontSize: 15, height: 1.4, color: _textHi, decorationThickness: 0),
                decoratedStyle: const TextStyle(fontSize: 15, height: 1.4, color: _accent, fontWeight: FontWeight.w600),
                keyboardType: TextInputType.multiline,
                focusNode: hashTagFocusNode,
                cursorColor: _accent,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                decoration: const InputDecoration(
                  isCollapsed: true,
                  contentPadding: EdgeInsets.zero,
                  hintText: "이 순간을 설명해 주세요…\n예) 노을이 예술 #오늘하늘",
                  hintStyle: TextStyle(fontSize: 14, height: 1.4, color: _textLo),
                  border: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  enabledBorder: InputBorder.none,
                ),
                onDetectionTyped: (text) {},
                onDetectionFinished: () {},
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── 옵션: 비공개 / 익명 토글 필 ──
  Widget _buildOptionPills() {
    return Row(
      children: [
        Expanded(
          child: _optionPill(
            active: _hideChecked,
            onTap: _toggleHideCheckbox,
            icon: _hideChecked ? Icons.lock_rounded : Icons.public_rounded,
            label: _hideChecked ? '비공개' : '전체공개',
            sub: _hideChecked ? '나만 볼 수 있어요' : '모두에게 보여요',
            activeColor: _accent,
          ),
        ),
        const Gap(12),
        Expanded(
          child: _optionPill(
            active: _anonyChecked,
            onTap: _toggleAnonyCheckbox,
            icon: _anonyChecked ? Icons.person_off_rounded : Icons.person_rounded,
            label: _anonyChecked ? '익명' : '내 이름',
            sub: _anonyChecked ? '닉네임 숨김' : '닉네임 표시',
            activeColor: _accent,
          ),
        ),
      ],
    );
  }

  Widget _optionPill({
    required bool active,
    required VoidCallback onTap,
    required IconData icon,
    required String label,
    required String sub,
    required Color activeColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: active ? activeColor.withOpacity(0.16) : _surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: active ? activeColor.withOpacity(0.9) : _surfaceBorder, width: 1.2),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: active ? activeColor : _textLo),
            const Gap(10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w700, color: active ? _textHi : _textHi.withOpacity(0.85))),
                  Text(sub, style: const TextStyle(fontSize: 11, color: _textLo)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── 게시 정책 (한 줄 → 펼치기) ──
  final ValueNotifier<bool> _policyOpen = ValueNotifier<bool>(false);

  Widget _buildPolicySection() {
    return Container(
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _surfaceBorder),
      ),
      child: ValueListenableBuilder<bool>(
        valueListenable: _policyOpen,
        builder: (context, open, _) {
          return Column(
            children: [
              InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => _policyOpen.value = !open,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                  child: Row(
                    children: [
                      const Icon(Icons.shield_outlined, size: 18, color: _textLo),
                      const Gap(10),
                      const Expanded(
                        child: Text('게시 정책 · 저작권 안내',
                            style: TextStyle(fontSize: 13, color: _textHi, fontWeight: FontWeight.w600)),
                      ),
                      AnimatedRotation(
                        turns: open ? 0.5 : 0,
                        duration: const Duration(milliseconds: 220),
                        child: const Icon(Icons.keyboard_arrow_down_rounded, color: _textLo, size: 22),
                      ),
                    ],
                  ),
                ),
              ),
              AnimatedCrossFade(
                duration: const Duration(milliseconds: 220),
                crossFadeState: open ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                firstChild: const SizedBox(width: double.infinity, height: 0),
                secondChild: const Padding(
                  padding: EdgeInsets.fromLTRB(14, 0, 14, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _PolicyLine(icon: Icons.music_note_rounded, text: '음악 저작권: 허락 없는 음원 사용 시 게시가 제한되거나 법적 책임이 따를 수 있어요. 저작권 free 음원을 권장합니다.'),
                      Gap(10),
                      _PolicyLine(icon: Icons.gavel_rounded, text: '금지 콘텐츠: 불법·성적·폭력·혐오 영상은 즉시 삭제되며 계정 정지 및 법적 조치 대상이 됩니다.'),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildVideoPlayer() {
    const double h = 340;
    if (!initVideo) {
      return Container(
        height: h,
        width: h * 9 / 16,
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _surfaceBorder),
        ),
        alignment: Alignment.center,
        child: const CircularProgressIndicator(strokeWidth: 2.4, color: _accent),
      );
    }

    void openFull() {
      Navigator.push<_PlayerVideoAndPopPage>(
        context,
        MaterialPageRoute<_PlayerVideoAndPopPage>(
          builder: (BuildContext context) => _PlayerVideoAndPopPage(videoPlayerController: _videoController),
        ),
      );
    }

    return SizedBox(
      height: h,
      child: AspectRatio(
        aspectRatio: 9 / 16,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 영상
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: GestureDetector(
                onTap: openFull,
                child: FittedBox(
                  fit: BoxFit.cover,
                  clipBehavior: Clip.hardEdge,
                  child: SizedBox(
                    width: _videoController.value.size.width,
                    height: _videoController.value.size.height,
                    child: VideoPlayer(_videoController),
                  ),
                ),
              ),
            ),
            // 테두리 하이라이트
            IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _surfaceBorder, width: 1),
                ),
              ),
            ),
            // 상단 그라데이션 (컨트롤 가독성)
            IgnorePointer(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  height: 64,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.black.withOpacity(0.35), Colors.transparent],
                    ),
                  ),
                ),
              ),
            ),
            // 음소거 토글 (우상단 글래스 칩)
            Positioned(
              top: 10,
              right: 10,
              child: ValueListenableBuilder<bool>(
                valueListenable: soundOff,
                builder: (context, value, snapshot) {
                  return _glassChip(
                    onTap: () {
                      _videoController.setVolume(value ? 1 : 0);
                      soundOff.value = !value;
                    },
                    child: Icon(value ? Icons.volume_off_rounded : Icons.volume_up_rounded, size: 18, color: Colors.white),
                  );
                },
              ),
            ),
            // 전체화면 (좌하단)
            Positioned(
              left: 10,
              bottom: 10,
              child: _glassChip(
                onTap: openFull,
                child: const Icon(Icons.fullscreen_rounded, size: 20, color: Colors.white),
              ),
            ),
            // 재생시간 (우하단)
            Positioned(
              right: 10,
              bottom: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.45),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  formatMilliseconds(durationOfVideo.inMilliseconds),
                  style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _glassChip({required VoidCallback onTap, required Widget child}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.4),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white24),
        ),
        child: child,
      ),
    );
  }

  // ── 자동 첨부 날씨 스트립 (영상 촬영 시점의 날씨가 함께 게시됩니다) ──
  Widget buildWeatherInfo() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _surfaceBorder),
      ),
      child: Row(
        children: [
          // 위치 + 온도/날씨
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Icon(Icons.location_on_rounded, size: 14, color: _accent),
                    const Gap(4),
                    Flexible(
                      child: ValueListenableBuilder<GeocodeData?>(
                        valueListenable: geocodeData,
                        builder: (context, value, child) {
                          return Text(
                            value?.name ?? '위치 확인 중…',
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 13, color: _textHi, fontWeight: FontWeight.w700),
                          );
                        },
                      ),
                    ),
                  ],
                ),
                const Gap(6),
                ValueListenableBuilder<CurrentWeatherData?>(
                  valueListenable: currentWeather,
                  builder: (context, value, child) {
                    if (value == null) {
                      return const Text('기상정보를 가져오는 중…',
                          style: TextStyle(fontSize: 12, color: _textLo, fontWeight: FontWeight.w500));
                    }
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text('${value.temp}',
                            style: const TextStyle(fontSize: 24, height: 1, color: _textHi, fontWeight: FontWeight.w800)),
                        const Padding(
                          padding: EdgeInsets.only(top: 2),
                          child: Text('°', style: TextStyle(fontSize: 18, color: _textHi, fontWeight: FontWeight.w800)),
                        ),
                        const Gap(8),
                        Flexible(
                          child: Text(value.description ?? '-',
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 13, color: _textLo, fontWeight: FontWeight.w600)),
                        ),
                      ],
                    );
                  },
                ),
                const Gap(6),
                ValueListenableBuilder<MistViewData?>(
                  valueListenable: mistData,
                  builder: (context, value, child) {
                    if (value == null) return const SizedBox.shrink();
                    return Row(
                      children: [
                        _mistDot('미세', value.mist10Grade.toString()),
                        const Gap(10),
                        _mistDot('초미세', value.mist25Grade.toString()),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
          const Gap(10),
          // 새로고침 (고스트 버튼)
          ValueListenableBuilder<bool>(
            valueListenable: isWeathering,
            builder: (context, busy, _) {
              return GestureDetector(
                onTap: busy ? null : () => getDate(),
                child: Container(
                  width: 38,
                  height: 38,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: _accent.withOpacity(0.14),
                    shape: BoxShape.circle,
                    border: Border.all(color: _accent.withOpacity(0.4)),
                  ),
                  child: busy
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: _accent))
                      : const Icon(Icons.refresh_rounded, size: 18, color: _accent),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _mistDot(String label, String grade) {
    Color c = const Color(0xFF4C8DFF);
    switch (grade) {
      case '보통':
        c = const Color(0xFF35C56A);
        break;
      case '나쁨':
        c = const Color(0xFFF2A33C);
        break;
      case '매우나쁨':
        c = const Color(0xFFF2564B);
        break;
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 7, height: 7, decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
        const Gap(5),
        Text('$label ', style: const TextStyle(fontSize: 11, color: _textLo)),
        Text(grade, style: TextStyle(fontSize: 11, color: c, fontWeight: FontWeight.w700)),
      ],
    );
  }

  Widget _legacyWeatherInfoUNUSED() {
    return Expanded(
      child: Container(
        height: 260,
        alignment: Alignment.topLeft,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row(
            //   children: [
            //     SizedBox(
            //       width: 34,
            //       child: CircleAvatar(
            //         radius: 16,
            //         backgroundColor: Colors.grey[100],
            //         child: ClipOval(
            //           child: Get.find<AuthCntr>().resLoginData.value.profilePath == ''
            //               ? const Icon(Icons.person, size: 35, color: Colors.black87)
            //               : CachedNetworkImage(
            //                   cacheKey: Get.find<AuthCntr>().resLoginData.value.custId.toString(),
            //                   imageUrl: Get.find<AuthCntr>().resLoginData.value.profilePath.toString(), //  'https://picsum.photos/200/300',
            //                   width: 35,
            //                   height: 35,
            //                   fit: BoxFit.cover,
            //                 ),
            //         ),
            //       ),
            //     ),
            //     const Gap(3),
            //     Flexible(
            //       child: Text(Get.find<AuthCntr>().resLoginData.value.nickNm.toString(),
            //           overflow: TextOverflow.clip,
            //           style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87)),
            //     ),
            //   ],
            // ),
            Divider(
              height: 3,
              thickness: 3,
              color: Colors.purple.withOpacity(0.5),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                // color: Colors.grey.withOpacity(0.2),
                borderRadius: BorderRadius.circular(5),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  // Container(
                  //     padding: const EdgeInsets.all(4),
                  //     decoration: BoxDecoration(
                  //       color: Colors.green.withOpacity(0.9),
                  //       borderRadius: BorderRadius.circular(5),
                  //     ),
                  //     child: const Icon(Icons.location_on, color: Colors.white, size: 13)),
                  // const SizedBox(width: 5),
                  Flexible(
                    child: ValueListenableBuilder<GeocodeData?>(
                        valueListenable: geocodeData,
                        builder: (context, value, child) {
                          if (value == null) {
                            return const SizedBox.shrink();
                          }
                          return Text(value.name,
                              overflow: TextOverflow.clip,
                              style: const TextStyle(fontSize: 13, color: Colors.black, fontWeight: FontWeight.bold));
                        }),
                  ),
                ],
              ),
            ),
            const Gap(5),
            ValueListenableBuilder<CurrentWeatherData?>(
                valueListenable: currentWeather,
                builder: (context, value, child) {
                  if (value == null) {
                    return const OffsetText(
                      text: '기상정보를 가져오는 중입니다...',
                      duration: Duration(milliseconds: 1200),
                      type: AnimationType.word,
                      slideType: SlideAnimationType.leftRight,
                      textStyle: TextStyle(fontSize: 10, color: Colors.black, fontWeight: FontWeight.bold),
                    );
                    // return const Text("기상정보를 가져오는 중입니다.", style: TextStyle(fontSize: 10, color: Colors.black, fontWeight: FontWeight.bold));
                  }
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Text(
                                '${value.temp}',
                                style: const TextStyle(
                                  fontSize: 18,
                                  height: 1,
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Text(
                                '°C',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Gap(5),
                              Text(
                                value.description ?? '-',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.black,
                                  height: 1,
                                ),
                                overflow: TextOverflow.clip,
                              )
                            ],
                          ),
                        ],
                      ),
                      const Gap(10),
                      // SizedBox(
                      //   height: 60,
                      //   width: 60,
                      //   child: WeatherDataProcessor.instance.getWeatherGogoImage(value.sky.toString(), value.rain.toString()),
                      //   // child: Lottie.asset(
                      //   //   WeatherDataProcessor.instance.getWeatherGogoImage(value.sky.toString(), value.rain.toString()),
                      //   //   height: 138.0,
                      //   //   width: 138.0,
                      //   // ),
                      // ),

                      // Text(
                      //   '습도:${value.humidity}%',
                      //   style: const TextStyle(
                      //     fontSize: 15,
                      //     color: Colors.black,
                      //   ),
                      // ),
                    ],
                  );
                }),
            const Gap(5),
            ValueListenableBuilder<MistViewData?>(
              valueListenable: mistData,
              builder: (context, value, child) {
                if (value == null) {
                  return const SizedBox.shrink();
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RichText(
                      text: TextSpan(
                        text: ' 미세',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.black,
                          fontWeight: FontWeight.w500,
                        ),
                        children: <TextSpan>[
                          buildTextMist(value.mist10Grade.toString()),
                          const TextSpan(
                            text: ' 초미세',
                            style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13, color: Colors.black),
                          ),
                          buildTextMist(value.mist25Grade.toString()),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),

            // 날씨 정보 다시 조회 버튼
            const Spacer(),
            Align(
              alignment: Alignment.centerRight,
              child: SizedBox(
                height: 25,
                width: 80,
                child: ElevatedButton(
                    // padding: const EdgeInsets.all(0),
                    // constraints: const BoxConstraints(),
                    style: ButtonStyle(
                        shape: WidgetStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(6))),
                        padding: WidgetStateProperty.all(EdgeInsets.zero),
                        backgroundColor: WidgetStateProperty.all(
                          // const Color.fromARGB(255, 95, 96, 103),
                          const Color.fromARGB(255, 50, 125, 237),
                        ),
                        shadowColor: const WidgetStatePropertyAll(Color.fromARGB(255, 50, 125, 237))),
                    onPressed: () async => getDate(),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Text(
                          '날씨 다시조회',
                          style: TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.w500),
                        ),
                        Icon(
                          Icons.refresh_rounded,
                          size: 13,
                          color: Colors.white,
                        ),
                      ],
                    )),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String formatMilliseconds(int milliseconds) {
    // Convert milliseconds to total seconds
    int totalSeconds = (milliseconds / 1000).floor();

    // Calculate minutes and remaining seconds
    int minutes = (totalSeconds / 60).floor();
    int seconds = totalSeconds % 60;

    // Format minutes and seconds with leading zeros if necessary
    String formattedMinutes = minutes.toString().padLeft(2, '0');
    String formattedSeconds = seconds.toString().padLeft(2, '0');

    return '$formattedMinutes:$formattedSeconds';
  }

  TextSpan buildTextMist(String mist) {
    /*
      if (value >= 0 && value <= 30) {
      return '좋음';
    } else if (value >= 31 && value <= 80) {
      return '보통';
    } else if (value >= 81 && value <= 150) {
      return '나쁨';
    } else {
      return '매우나쁨';
    }
    */
    Color color = Colors.blue;
    switch (mist) {
      case '좋음':
        color = Colors.blue;
        break;
      case '보통':
        color = Colors.green;
        break;
      case '나쁨':
        color = Colors.orange;
        break;
      case '매우나쁨':
        color = Colors.red;
        break;
      default:
        color = Colors.blue;
    }

    return TextSpan(
      text: mist,
      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: color),
    );
  }

  Widget _buildHideCheckbox() {
    return Align(
      alignment: Alignment.centerRight,
      child: GestureDetector(
        onTap: _toggleHideCheckbox,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            ScaleTransition(
              scale: _hideScaleAnimation,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.rectangle,
                  color: _hideChecked ? Colors.green : Colors.white,
                ),
                width: 20.5,
                height: 20.5,
                child: _hideChecked
                    ? const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 19.5,
                      )
                    : const Icon(Icons.check_box_outline_blank, size: 23.5, color: Colors.black87),
              ),
            ),
            const Gap(6),
            const Text(
              "숨기기로 등록",
              style: TextStyle(fontSize: 12, color: Colors.black87, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  // 익명

  Widget _buildAnonyCheckbox() {
    return Align(
      alignment: Alignment.centerRight,
      child: GestureDetector(
        onTap: _toggleAnonyCheckbox,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            ScaleTransition(
              scale: _anonyScaleAnimation,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.rectangle,
                  color: _anonyChecked ? Colors.purple : Colors.white,
                ),
                width: 20.5,
                height: 20.5,
                child: _anonyChecked
                    ? const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 19.5,
                      )
                    : const Icon(Icons.check_box_outline_blank, size: 23.5, color: Colors.black87),
              ),
            ),
            const Gap(6),
            const Text(
              "익명으로 등록",
              style: TextStyle(fontSize: 12, color: Colors.black87, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return ValueListenableBuilder<bool>(
      valueListenable: isUploading,
      builder: (context, value, child) {
        return CustomIndicatorOffstage(isLoading: !value, color: const Color(0xFFEA3799), opacity: 0.5);
      },
    );
  }

  Widget _buildCloseButton() {
    return Positioned(
      top: 5,
      right: 5,
      child: IconButton(
        icon: const Icon(Icons.close),
        onPressed: () => cancle(),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      decoration: const BoxDecoration(
        color: _bgBot,
        border: Border(top: BorderSide(color: _surfaceBorder)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
          child: Row(
            children: [
              _buildHashtagButton(),
              const Gap(12),
              Expanded(child: _buildUploadButton()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReWeatherButton() {
    return ValueListenableBuilder<bool>(
      valueListenable: isWeathering,
      builder: (context, isWeatherValue, child) {
        if (!isWeatherValue) return const SizedBox.shrink();
        return CustomButton(
          text: '날씨정보',
          type: 'L',
          isEnable: true,
          widthValue: 120,
          heightValue: 50,
          onPressed: () {
            retry = 3;
            getDate();
          },
        );
      },
    );
  }

  Widget _buildHashtagButton() {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).requestFocus(hashTagFocusNode);
        hashTagController.text = '${hashTagController.text} #';
      },
      child: Container(
        height: 52,
        width: 52,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _surfaceBorder),
        ),
        child: const Text('#', style: TextStyle(color: _textHi, fontSize: 22, fontWeight: FontWeight.w800)),
      ),
    );
  }

  Widget _buildUploadButton() {
    return ValueListenableBuilder<bool>(
      valueListenable: isUploading,
      builder: (context, uploading, child) {
        final bool busy = uploading;
        final String label = uploading ? '게시 중…' : '게시하기';
        return GestureDetector(
          onTap: () async {
            if (uploading) {
              Utils.alert('처리중입니다..');
              return;
            }
            lo.g("등록하기");
            await upload();
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 52,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: busy ? _surface : _accent,
              borderRadius: BorderRadius.circular(16),
              border: busy ? Border.all(color: _surfaceBorder) : null,
              boxShadow: busy
                  ? null
                  : [BoxShadow(color: Colors.black.withOpacity(0.25), blurRadius: 12, offset: const Offset(0, 4))],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (busy) ...[
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: _accent),
                  ),
                  const Gap(10),
                ] else ...[
                  const Icon(Icons.cloud_upload_rounded, size: 20, color: Colors.white),
                  const Gap(8),
                ],
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: busy ? _textLo : Colors.white,
                    letterSpacing: -0.2,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _handlePopInvoked(bool didPop) {
    //didPop == true , 뒤로가기 제스쳐가 감지되면 호출 된다.
    lo.g("isCancle : $isCancle , didPop : $didPop");
    if (!didPop && isCancle == false) {
      cancle();
      return;
    }
  }
}

class TotalData {
  String? localName;
  CurrentWeather? currentWeather;
}

/// 게시 정책 한 줄 항목 (아이콘 + 안내문)
class _PolicyLine extends StatelessWidget {
  const _PolicyLine({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 15, color: const Color(0xFF9AA6C2)),
        const Gap(8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 12, height: 1.5, color: Color(0xFF9AA6C2)),
          ),
        ),
      ],
    );
  }
}

class _PlayerVideoAndPopPage extends StatefulWidget {
  final VideoPlayerController videoPlayerController;

  const _PlayerVideoAndPopPage({required this.videoPlayerController});
  @override
  _PlayerVideoAndPopPageState createState() => _PlayerVideoAndPopPageState();
}

class _PlayerVideoAndPopPageState extends State<_PlayerVideoAndPopPage> {
  bool startedPlaying = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    // 아래코드를 살리면 원복 컨트롤러도 같이 종료됨
    // widget.videoPlayerController.dispose();
    super.dispose();
  }

  Future<bool> started() async {
    await widget.videoPlayerController.initialize();
    await widget.videoPlayerController.play();
    startedPlaying = true;
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        forceMaterialTransparency: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          '동영상 재생',
          style: TextStyle(fontSize: 15),
        ),
      ),
      body: FutureBuilder<bool>(
        future: started(),
        builder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
          if (snapshot.data ?? false) {
            return Container(
              padding: const EdgeInsets.only(left: 8, right: 8, bottom: 3),
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height,
              child: ClipRRect(borderRadius: BorderRadius.circular(15), child: VideoPlayer(widget.videoPlayerController)),
            );
          } else {
            return const Text('');
          }
        },
      ),
    );
  }
}
