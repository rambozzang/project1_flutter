import 'dart:io';
// import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:hashtagable_v3/hashtagable.dart';
import 'package:latlong2/latlong.dart';
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

// 동영상 압축 FFmpeg로 동영상 압축하기
class VideoRegPage extends StatefulWidget {
  const VideoRegPage({super.key, required this.videoFile});
  final File videoFile;

  @override
  State<VideoRegPage> createState() => _VideoRegPageState();
}

class _VideoRegPageState extends State<VideoRegPage> with SingleTickerProviderStateMixin {
  late VideoPlayerController _videoController;
  final TextEditingController hashTagController = TextEditingController();

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

  bool _checked = false;
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  final ValueNotifier<bool> soundOff = ValueNotifier<bool>(false);

  final WeatherService weatherService = WeatherService();

  ValueNotifier<CurrentWeatherData?> currentWeather = ValueNotifier<CurrentWeatherData?>(null);
  ValueNotifier<GeocodeData?> geocodeData = ValueNotifier<GeocodeData?>(null);
  ValueNotifier<MistViewData?> mistData = ValueNotifier<MistViewData?>(null);

  @override
  void initState() {
    super.initState();
    // currentWeather.value = widget.currentWeather;

    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    WidgetsBinding.instance!.addPostFrameCallback((_) {
      initializeVideo();
      initData();
      getDate();
    });
  }

  Future<void> _retryInitialization() async {
    // await _videoController.dispose();
    lo.g('retryInitialization');
    await Future.delayed(const Duration(seconds: 1));
    initializeVideo();
  }

  void _toggleCheckbox() {
    setState(() {
      _checked = !_checked;
      hideYn = _checked ? 'Y' : 'N';
      if (_checked) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  void initializeVideo() async {
    try {
      lo.g("initializeVideo() widget.videoFile : ${widget.videoFile.path}");
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
          // 4. 재시도 로직
          _retryInitialization();
        }
      });
    } catch (e) {
      Utils.alert("비디오초기화 오류 : $e");
      lo.g("initializeVideo() error : $e");
    }
  }

  int retryCount = 3;

  void initData() {
    geocodeData.value = Get.find<WeatherGogoCntr>().currentLocation.value;
    mistData.value = Get.find<WeatherGogoCntr>().mistData.value;
    currentWeather.value = Get.find<WeatherGogoCntr>().currentWeather.value;
  }

  Future<void> getDate() async {
    try {
      // 현재위치와 지명 가져오기
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 5),
      );
      LatLng location = LatLng(position.latitude, position.longitude);

      LocationService locationService = LocationService();
      final (onValue1, onValue2) = await locationService.getLocalName(location);
      if (onValue1 == null || onValue2 == null) {
        return;
      }

      geocodeData.value = GeocodeData(name: onValue2, latLng: location);

      mistData.value = (await locationService.getMistData(onValue1))!;

      WeatherGogoRepo repo = WeatherGogoRepo();
      List<ItemSuperFct> itemFctList = await repo.getSuperFctListJson(location);

      String fcstDate = itemFctList.first.fcstDate!;
      String fcstTime = itemFctList.first.fcstTime!;
      CurrentWeatherData _currentWeatherData = CurrentWeatherData();
      itemFctList.forEach((item) {
        if (item.fcstDate.toString() == fcstDate && item.fcstTime.toString() == fcstTime) {
          if (item?.category == 'T1H') {
            _currentWeatherData.temp = item.fcstValue!;
          } else if (item.category == 'PTY') {
            _currentWeatherData.rain = item.fcstValue!;
          } else if (item.category == 'SKY') {
            _currentWeatherData.sky = item.fcstValue!;
          } else if (item.category == 'REH') {
            _currentWeatherData.humidity = item.fcstValue!;
          } else if (item.category == 'WSD') {
            _currentWeatherData.speed = item.fcstValue!;
          }
        }
      });
      _currentWeatherData.description =
          WeatherDataProcessor.instance.combineWeatherCondition(_currentWeatherData.sky.toString(), _currentWeatherData.rain.toString());

      currentWeather.value = _currentWeatherData;
      lo.g('currentWeather : ${currentWeather.value}');
      isWeathering.value = false;
      // 현재날씨 가져오기
    } catch (e) {
      lo.g("getDate() error : $e");
      isWeathering.value = false;
    }
  }

  // 파일 업로드
  Future<void> upload() async {
    if (isWeathering.value) {
      Utils.alert("현지 위치정보 수신중입니다. 잠시 후 다시 시도해주세요.");
      return;
    }

    isUploading.value = true;

    try {
      BoardSaveMainData boardSaveMainData = BoardSaveMainData();
      boardSaveMainData.contents = hashTagController.text;
      boardSaveMainData.depthNo = '0';
      boardSaveMainData.notiEdAt = '';
      boardSaveMainData.notiStAt = '';
      boardSaveMainData.subject = '';
      boardSaveMainData.typeCd = 'V';
      boardSaveMainData.typeDtCd = 'V';
      boardSaveMainData.hideYn = hideYn;

      BoardSaveWeatherData boardSaveWeatherData = BoardSaveWeatherData();
      boardSaveWeatherData.boardId = 0;

      boardSaveWeatherData.city = '';
      boardSaveWeatherData.country = '';

      boardSaveWeatherData.currentTemp = currentWeather.value!.temp;
      // boardSaveWeatherData.feelsTemp = currentWeather!.feels_like?.toStringAsFixed(1);
      boardSaveWeatherData.humidity = currentWeather.value?.humidity.toString();
      // boardSaveWeatherData.icon = currentWeather.weather![0].icon;
      boardSaveWeatherData.lat = geocodeData.value?.latLng.latitude.toString();
      boardSaveWeatherData.lon = geocodeData.value?.latLng.longitude.toString();
      boardSaveWeatherData.speed = currentWeather.value?.speed.toString();
      boardSaveWeatherData.sky = currentWeather.value?.sky.toString();
      boardSaveWeatherData.rain = currentWeather.value?.rain.toString();

      boardSaveWeatherData.tempMax = ''; // currentWeather.main!.temp_max?.toStringAsFixed(1);
      boardSaveWeatherData.tempMin = ''; // currentWeather.main!.temp_min?.toStringAsFixed(1);

      boardSaveWeatherData.location = Get.find<WeatherGogoCntr>().currentLocation.value.name;
      // boardSaveWeatherData.thumbnailPath = res2.secureUrl;
      // boardSaveWeatherData.videoPath = res.secureUrl;
      boardSaveWeatherData.weatherInfo = currentWeather.value?.description;
      boardSaveData.boardMastInVo = boardSaveMainData;
      boardSaveData.boardWeatherVo = boardSaveWeatherData;
      boardSaveWeatherData.mist10 = Get.find<WeatherGogoCntr>().mistData.value.mist10Grade.toString();
      boardSaveWeatherData.mist25 = Get.find<WeatherGogoCntr>().mistData.value.mist25Grade.toString();
      Lo.g("Root upload() videoFilePath : ${widget.videoFile.path}");
      if (hideYn == "Y") {
        Utils.alert('숨기기 상태로 등록중 입니다!');
      } else {
        Utils.alert('업로드중 입니다! 잠시후 정상 게시됩니다!');
      }

      Future.delayed(const Duration(milliseconds: 500), () {
        Get.back();
      });
    } catch (e) {
      debugPrint(e.toString());
      isUploading.value = false;
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
    _videoController.pause();
    _videoController.dispose();
    _controller.dispose();
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
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: false,
      body: PopScope(
        canPop: false,
        onPopInvoked: (didPop) {
          //didPop == true , 뒤로가기 제스쳐가 감지되면 호출 된다.
          lo.g("isCancle : $isCancle , didPop : $didPop");
          if (!didPop && isCancle == false) {
            cancle();
            return;
          }
        },
        child: SafeArea(
          child: Stack(
            children: [
              SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Gap(50),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          !initVideo
                              ? Container(
                                  height: 300,
                                  width: MediaQuery.of(context).size.width * 0.5 - 50,
                                  alignment: Alignment.center,
                                  child: const CircularProgressIndicator())
                              : Container(
                                  height: 300,
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
                                                    builder: (BuildContext context) =>
                                                        _PlayerVideoAndPopPage(videoPlayerController: _videoController),
                                                  ),
                                                );
                                              },
                                              //  child: Container(color: Colors.red)),
                                              child: VideoPlayer(_videoController)),
                                        ),
                                      ),
                                      const Positioned(left: 5, bottom: 5, child: Icon(Icons.zoom_in, size: 30, color: Colors.white)),
                                      Positioned(
                                        right: 5,
                                        bottom: 5,
                                        // ignore: unnecessary_string_interpolations
                                        child: Text('${formatMilliseconds(durationOfVideo.inMilliseconds)}',
                                            style: const TextStyle(fontSize: 12, color: Colors.white)),
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
                                                    _videoController.setVolume(1); // 소리 켜기
                                                  } else {
                                                    _videoController.setVolume(0); // 소리 끄기
                                                  }
                                                  soundOff.value = !value;
                                                },
                                                icon: value
                                                    ? const Icon(Icons.volume_off_outlined, color: Colors.white)
                                                    : const Icon(Icons.volume_up_outlined, color: Colors.white),
                                              );
                                            }),
                                      ),
                                    ],
                                  ),
                                ),
                          const Gap(5),
                          buildWeatherInfo(),
                        ],
                      ),
                      // const Gap(20),
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text('# 태그 사용가능', style: TextStyle(fontSize: 14, color: Colors.black87)),
                        ],
                      ),
                      HashTagTextField(
                        controller: hashTagController,
                        basicStyle: const TextStyle(fontSize: 15, color: Colors.black, decorationThickness: 0),
                        decoratedStyle: const TextStyle(fontSize: 15, color: Colors.blue),
                        keyboardType: TextInputType.multiline,
                        maxLines: 4,
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
                      Align(
                        alignment: Alignment.centerRight,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // CheckBoxRounded(
                            //   onTap: (bool? value) {
                            //     log("message 1: $value");
                            //     hideYn = value! ? 'Y' : 'N';
                            //     log("message 2: $hideYn");
                            //   },
                            //   size: 20,
                            //   uncheckedWidget: const Icon(Icons.panorama_fish_eye, size: 18),
                            //   animationDuration: const Duration(milliseconds: 150),
                            // ),
                            GestureDetector(
                              onTap: _toggleCheckbox,
                              child: ScaleTransition(
                                scale: _scaleAnimation,
                                child: Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.rectangle,
                                    color: _checked ? Colors.green : Colors.black,
                                  ),
                                  width: 20.0,
                                  height: 20.0,
                                  child: _checked
                                      ? const Icon(Icons.check, color: Colors.white)
                                      : const Icon(Icons.check_box_outline_blank, size: 19.5, color: Colors.white),
                                ),
                              ),
                            ),
                            const Gap(3),
                            const Text(
                              "숨기기로 등록하기",
                              style: TextStyle(fontSize: 13, color: Colors.black87, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ),
                      const Gap(30),
                      const Tooltip(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 25,
                        ),
                        padding: EdgeInsets.all(15),
                        message: "음악 저작권자의 허락 없이 동영상에 음악을 사용하면 법적 책임을 지실 수 있습니다.\n\n" +
                            "1.동영상에 사용된 음악이 저작권자의 허락을 받은 음원인지 확인해야 합니다.\n" +
                            "2.무료 이용이 가능한 저작권 free 음원을 사용하시는 것을 권장드립니다.\n" +
                            "3.만약 저작권자의 허락 없이 음악을 사용하셨다면 동영상 게시가 제한될 수 있습니다.",
                        triggerMode: TooltipTriggerMode.tap,
                        showDuration: Duration(seconds: 10),
                        child: Row(
                          children: [
                            Icon(Icons.info, color: Colors.black, size: 20),
                            Text(
                              '영상에 음악이 포함될 경우 저작권 과금.',
                              style: TextStyle(
                                color: Colors.red,
                                fontSize: 12.0,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                      const Gap(10),
                      const Tooltip(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 25,
                        ),
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
                            Icon(Icons.info, color: Colors.black, size: 20),
                            Text(
                              '불법/성적/학대 영상 업로드 시 법적 조치',
                              style: TextStyle(
                                color: Colors.red,
                                fontSize: 12.0,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                      const Gap(50),
                    ],
                  ),
                ),
              ),
              ValueListenableBuilder<bool>(
                  valueListenable: isUploading,
                  builder: (context, value, child) {
                    return CustomIndicatorOffstage(isLoading: !value, color: const Color(0xFFEA3799), opacity: 0.5);
                  }),
              Positioned(
                  top: 5,
                  right: 5,
                  child: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => cancle(),
                  )),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.only(left: 16, right: 16, top: 5, bottom: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              ElevatedButton(
                onPressed: () {
                  hashTagController.text = hashTagController.text + ' #';
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
              ),
              const Spacer(),
              ValueListenableBuilder<bool>(
                  valueListenable: isWeathering,
                  builder: (context, isWeatherValue, child) {
                    return ValueListenableBuilder<bool>(
                      valueListenable: isUploading,
                      builder: (context, value, child) {
                        return CustomButton(
                            text: !value ? '등록하기' : '처리중..',
                            type: 'L',
                            isEnable: !isWeatherValue,
                            widthValue: 120,
                            heightValue: 50,
                            onPressed: () => !value ? upload() : Utils.alert('처리중입니다..'));
                      },
                    );
                  }),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildWeatherInfo() {
    return Expanded(
        child: Container(
      alignment: Alignment.topLeft,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(
                width: 25,
                child: CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.grey[100],
                  child: ClipOval(
                    child: Get.find<AuthCntr>().resLoginData.value.profilePath == ''
                        ? const Icon(Icons.person, size: 23, color: Colors.black87)
                        : CachedNetworkImage(
                            cacheKey: Get.find<AuthCntr>().resLoginData.value.custId.toString(),
                            imageUrl: Get.find<AuthCntr>().resLoginData.value.profilePath.toString(), //  'https://picsum.photos/200/300',
                            width: 23,
                            height: 23,
                            fit: BoxFit.cover,
                          ),
                  ),
                ),
              ),
              const Gap(5),
              Flexible(
                child: Text(Get.find<AuthCntr>().resLoginData.value.nickNm.toString(),
                    overflow: TextOverflow.clip, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87)),
              ),
            ],
          ),
          const Divider(),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.2),
              borderRadius: BorderRadius.circular(5),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: const Icon(Icons.location_on, color: Colors.white, size: 15)),
                const SizedBox(width: 5),
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
          const Gap(15),
          ValueListenableBuilder<CurrentWeatherData?>(
              valueListenable: currentWeather,
              builder: (context, value, child) {
                if (value == null) {
                  return const SizedBox.shrink();
                }
                return Row(
                  children: [
                    Text(
                      '${value.temp}°C',
                      style: const TextStyle(
                        fontSize: 15,
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Gap(10),
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
          ValueListenableBuilder<CurrentWeatherData?>(
              valueListenable: currentWeather,
              builder: (context, value, child) {
                if (value == null) {
                  return const SizedBox.shrink();
                }
                return Text(
                  value.description ?? '-',
                  style: const TextStyle(fontSize: 14, color: Colors.black),
                  overflow: TextOverflow.clip,
                );
              }),
          const Gap(15),
          ValueListenableBuilder<MistViewData?>(
              valueListenable: mistData,
              builder: (context, value, child) {
                if (value == null) {
                  return const SizedBox.shrink();
                }
                return RichText(
                  text: TextSpan(
                    text: '미세',
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
                      buildTextMist(value!.mist25Grade.toString()),
                    ],
                  ),
                );
              }),
        ],
      ),
    ));
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
        title: const Text(
          '동영상 재생',
          style: TextStyle(fontSize: 16),
        ),
        automaticallyImplyLeading: true,
      ),
      body: Center(
        child: FutureBuilder<bool>(
          future: started(),
          builder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
            if (snapshot.data ?? false) {
              return AspectRatio(
                aspectRatio: widget.videoPlayerController.value.aspectRatio,
                child: VideoPlayer(widget.videoPlayerController),
              );
            } else {
              return const Text('');
            }
          },
        ),
      ),
    );
  }
}
