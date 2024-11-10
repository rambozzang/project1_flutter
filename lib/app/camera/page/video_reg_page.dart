import 'dart:io';
// import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:hashtagable_v3/widgets/hashtag_text_field.dart';
import 'package:latlong2/latlong.dart';
import 'package:pretty_animated_text/pretty_animated_text.dart';
import 'package:project1/app/auth/cntr/auth_cntr.dart';
import 'package:project1/app/weather/models/geocode.dart';
import 'package:project1/app/weathergogo/services/location_service.dart';
import 'package:project1/app/weathergogo/services/weather_data_processor.dart';
import 'package:project1/repo/board/data/board_save_data.dart';
import 'package:project1/repo/board/data/board_save_main_data.dart';
import 'package:project1/repo/board/data/board_save_weather_data.dart';
import 'package:project1/repo/weather/data/current_weather.dart';
import 'package:project1/app/weathergogo/cntr/data/current_weather_data.dart';
import 'package:project1/app/weathergogo/cntr/weather_gogo_cntr.dart';
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
      getDate();
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
        itemFctList.forEach((item) {
          if (item.fcstDate.toString() == fcstDate && item.fcstTime.toString() == fcstTime) {
            if (item?.category == 'T1H') {
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
        });
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
    if (isWeathering.value) {
      Utils.alert("현지 위치정보 수신중입니다. 잠시 후 다시 시도해주세요.");
      getDate();
      return;
    }

    isUploading.value = true;
    try {
      final mainData = _createBoardSaveMainData();

      final weatherData = _createBoardSaveWeatherData();

      boardSaveData.boardMastInVo = mainData;
      boardSaveData.boardWeatherVo = weatherData;

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

    super.dispose();
    //실제 Root 페이지 에서 동영상 업로드 처리
    if (!isCancle) {
      Get.find<RootCntr>().goTimer(widget.videoFile, boardSaveData);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // backgroundColor: Colors.grey[500],
      resizeToAvoidBottomInset: false,
      body: _buildBody(),
      bottomNavigationBar: _buildBottomBar(),
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
              _buildCloseButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Gap(50),
            _buildVideoAndWeatherSection(),
            const Gap(10),

            const Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text('# 태그 사용가능', style: TextStyle(fontSize: 14, color: Colors.black87)),
              ],
            ),
            // 해시태그 입력란 추가
            HashTagTextField(
              controller: hashTagController,
              basicStyle: const TextStyle(fontSize: 15, color: Colors.black, decorationThickness: 0),
              decoratedStyle: const TextStyle(fontSize: 15, color: Colors.blue),
              keyboardType: TextInputType.multiline,
              focusNode: hashTagFocusNode,
              maxLines: 4,
              //  onTapOutside: (_) =>  ,
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(horizontal: 7, vertical: 7),
                hintText: "내용을 입력해주세요! \n#태그1 #태그2 #태그3",
                hintStyle: const TextStyle(fontSize: 15, color: Colors.grey),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(5),
                    borderSide: const BorderSide(color: Color.fromARGB(255, 59, 104, 81), width: 1.0)),
              ),
              onDetectionTyped: (text) {
                print(text);
              },
              onDetectionFinished: () {
                print("detection finished");
              },
            ),
            const Gap(10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _buildHideCheckbox(),
                const Gap(15),
                _buildAnonyCheckbox(),
              ],
            ),
            _hideChecked
                ? Tooltip(
                    margin: const EdgeInsets.symmetric(horizontal: 10),
                    padding: const EdgeInsets.all(6),
                    message: "숨기기로 등록 시, 다른 사용자에게 노출되지 않습니다.1",
                    textStyle: const TextStyle(color: Colors.white, fontSize: 12.0),
                    triggerMode: TooltipTriggerMode.tap,
                    showDuration: const Duration(seconds: 10),
                    child: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 5, top: 10),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Icon(Icons.remove_red_eye_outlined, color: Colors.grey, size: 14),
                          Text(
                            '다른 사용자에게 노출되지 않습니다.',
                            style: TextStyle(color: Colors.grey, fontSize: 11.0),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
            _anonyChecked
                ? Tooltip(
                    margin: const EdgeInsets.symmetric(horizontal: 10),
                    padding: const EdgeInsets.all(6),
                    message: "익명으로 등록 시, 닉네임이 랜덤으로 생성되어 노출됩니다.",
                    textStyle: const TextStyle(color: Colors.white, fontSize: 12.0),
                    triggerMode: TooltipTriggerMode.tap,
                    showDuration: const Duration(seconds: 10),
                    child: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 5, top: 10),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Icon(Icons.person_off, color: Colors.grey, size: 15),
                          Text(
                            '자신의 닉네임이 노출되지 않습니다.',
                            style: TextStyle(color: Colors.grey, fontSize: 11.0),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
            const Gap(20),
            // 저작권 주의사항 1
            const Tooltip(
              margin: EdgeInsets.symmetric(horizontal: 25),
              padding: EdgeInsets.all(15),
              message:
                  "음악 저작권자의 허락 없이 동영상에 음악을 사용하면 법적 책임을 지실 수 있습니다.\n\n1.동영상에 사용된 음악이 저작권자의 허락을 받은 음원인지 확인해야 합니다.\n2.무료 이용이 가능한 저작권 free 음원을 사용하시는 것을 권장드립니다.\n3.만약 저작권자의 허락 없이 음악을 사용하셨다면 동영상 게시가 제한될 수 있습니다.",
              triggerMode: TooltipTriggerMode.tap,
              showDuration: Duration(seconds: 10),
              child: Row(
                children: [
                  Icon(Icons.info, color: Colors.red, size: 20),
                  Text(
                    '영상에 음악이 포함될 경우 저작권 과금.',
                    style: TextStyle(color: Colors.red, fontSize: 12.0),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const Gap(10),
            // 저작권 주의사항 2
            const Tooltip(
              margin: EdgeInsets.symmetric(horizontal: 25),
              padding: EdgeInsets.all(15),
              message: """
안전하고 적절한 환경 제공을 위해 다음 콘텐츠를 엄격히 금지합니다:

• 불법 콘텐츠 (저작권 침해, 사기 등)
• 성적으로 노골적인 콘텐츠 (포르노그래피 등)
• 폭력적 콘텐츠 (과도한 폭력, 학대 등)
• 혐오 발언 (차별적 콘텐츠)

위반 시 조치:
1. 콘텐츠 즉시 삭제
2. 계정 영구 정지 가능
3. 법 집행 기관 신고 가능
4. 민형사상 법적 조치 가능

부적절한 콘텐츠 발견 시 즉시 신고 바랍니다.
              """,
              triggerMode: TooltipTriggerMode.tap,
              showDuration: Duration(seconds: 10),
              child: Row(
                children: [
                  Icon(Icons.info, color: Colors.red, size: 20),
                  Text(
                    '불법/성적/학대 영상 업로드 시 법적 조치',
                    style: TextStyle(color: Colors.red, fontSize: 12.0),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const Gap(50),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoAndWeatherSection() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildVideoPlayer(),
        const Gap(5),
        buildWeatherInfo(),
      ],
    );
  }

  Widget _buildVideoPlayer() {
    if (!initVideo) {
      return Container(
        height: 260,
        color: Colors.white,
        width: MediaQuery.of(context).size.width * 0.5 - 50,
        alignment: Alignment.center,
        child: const CircularProgressIndicator(),
      );
    }

    return Container(
      height: 260,
      alignment: Alignment.center,
      child: Stack(
        children: [
          AspectRatio(
            aspectRatio: 9 / 16,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: GestureDetector(
                onTap: () {
                  Navigator.push<_PlayerVideoAndPopPage>(
                    context,
                    MaterialPageRoute<_PlayerVideoAndPopPage>(
                      builder: (BuildContext context) => _PlayerVideoAndPopPage(videoPlayerController: _videoController),
                    ),
                  );
                },
                child: VideoPlayer(_videoController),
              ),
            ),
          ),
          Positioned(
            left: 5,
            bottom: 5,
            child: IconButton(
              onPressed: () {
                Navigator.push<_PlayerVideoAndPopPage>(
                  context,
                  MaterialPageRoute<_PlayerVideoAndPopPage>(
                    builder: (BuildContext context) => _PlayerVideoAndPopPage(videoPlayerController: _videoController),
                  ),
                );
              },
              icon: const Icon(Icons.zoom_in, size: 30, color: Colors.white),
            ),
          ),
          Positioned(
            right: 5,
            bottom: 5,
            child: Text(
              formatMilliseconds(durationOfVideo.inMilliseconds),
              style: const TextStyle(fontSize: 12, color: Colors.white),
            ),
          ),
          Positioned(
            top: 5,
            right: 0,
            child: ValueListenableBuilder<bool>(
              valueListenable: soundOff,
              builder: (context, value, snapshot) {
                return IconButton(
                  onPressed: () {
                    if (value) {
                      _videoController.setVolume(1);
                    } else {
                      _videoController.setVolume(0);
                    }
                    soundOff.value = !value;
                  },
                  icon: value
                      ? const Icon(Icons.volume_off_outlined, color: Colors.white)
                      : const Icon(Icons.volume_up_outlined, color: Colors.white),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget buildWeatherInfo() {
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
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.only(left: 16, right: 16, top: 5, bottom: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            _buildHashtagButton(),
            const Spacer(),
            // _buildReWeatherButton(),
            _buildUploadButton(),
          ],
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
    return ElevatedButton(
      onPressed: () {
        // 포커스
        FocusScope.of(context).requestFocus(hashTagFocusNode);
        // 키보드 보이기

        hashTagController.text = '${hashTagController.text} #';
      },
      clipBehavior: Clip.none,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        elevation: 1.5,
        minimumSize: const Size(0, 0),
        backgroundColor: Colors.grey[200],
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
      ),
      child: const Text(
        '# 태그추가',
        style: TextStyle(
          color: Colors.black,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildUploadButton() {
    return ValueListenableBuilder<bool>(
      valueListenable: isWeathering,
      builder: (context, isWeatherValue, child) {
        if (isWeatherValue) return const Text("날씨정보 수신중..", style: TextStyle(fontSize: 13, color: Colors.grey));
        return ValueListenableBuilder<bool>(
          valueListenable: isUploading,
          builder: (context, value, child) {
            return CustomButton(
                text: !value ? '등록하기' : '처리중..',
                type: 'L',
                isEnable: !isWeatherValue,
                widthValue: 120,
                heightValue: 50,
                onPressed: () async {
                  //  !value ? upload() : Utils.alert('처리중입니다..'),

                  lo.g("등록하기 : $value");
                  if (!value) {
                    await upload();
                    return;
                  } else {
                    Utils.alert('처리중입니다..');
                  }
                });
          },
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

class _PlayerVideoAndPopPage extends StatefulWidget {
  final VideoPlayerController videoPlayerController;

  const _PlayerVideoAndPopPage({super.key, required this.videoPlayerController});
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
