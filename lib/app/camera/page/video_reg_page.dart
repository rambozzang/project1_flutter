import 'dart:io';
// import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:hashtagable_v3/hashtagable.dart';
import 'package:project1/app/weather/provider/weather_cntr.dart';
import 'package:project1/repo/board/data/board_save_data.dart';
import 'package:project1/repo/board/data/board_save_main_data.dart';
import 'package:project1/repo/board/data/board_save_weather_data.dart';
import 'package:project1/repo/weather/data/current_weather.dart';
import 'package:project1/root/cntr/root_cntr.dart';
import 'package:project1/utils/log_utils.dart';
import 'package:project1/utils/utils.dart';
import 'package:project1/widget/custom_button.dart';
import 'package:project1/widget/custom_indicator_offstage.dart';
import 'package:video_compress/video_compress.dart';
import 'package:video_player/video_player.dart';

// 동영상 압축 FFmpeg로 동영상 압축하기
class VideoRegPage extends StatefulWidget {
  const VideoRegPage({super.key, required this.videoFile});
  final File videoFile;

  @override
  State<VideoRegPage> createState() => _VideoRegPageState();
}

class _VideoRegPageState extends State<VideoRegPage> {
  late VideoPlayerController _videoController;
  final TextEditingController hashTagController = TextEditingController();

  // late Subscription _subscription;
  late MediaInfo? pickedFile;

  final ValueNotifier<CurrentWeather?> currentWeather = ValueNotifier<CurrentWeather?>(null);

  final ValueNotifier<String?> localName = ValueNotifier<String?>(null);
  final ValueNotifier<TotalData?> totalData = ValueNotifier<TotalData?>(null);

  final ValueNotifier<bool> isUploading = ValueNotifier<bool>(false);
  final ValueNotifier<double> uploadingPercentage1 = ValueNotifier<double>(0.0);
  final ValueNotifier<double> uploadingPercentage2 = ValueNotifier<double>(0.0);

  final ValueNotifier<double> progress = ValueNotifier<double>(0.0);
  late Position? position;
  final ValueNotifier<bool> isCompress = ValueNotifier<bool>(true);
  late String? thumbnailFile;
  BoardSaveData boardSaveData = BoardSaveData();

  bool isCancle = false;

  @override
  void initState() {
    super.initState();
    // currentWeather.value = widget.currentWeather;

    _videoController = VideoPlayerController.file(widget.videoFile);

    initializeVideo();

    getDate();
  }

  void initializeVideo() async {
    await _videoController.initialize();
    _videoController.setLooping(true);
    _videoController.play();
  }

  Future<void> getDate() async {
    try {
      await Get.find<WeatherCntr>().getWeatherData();
    } catch (e) {}
  }

  // 파일 업로드
  Future<void> upload() async {
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

      CurrentWeather? currentWeather = Get.find<WeatherCntr>().currentWeather.value;

      BoardSaveWeatherData boardSaveWeatherData = BoardSaveWeatherData();
      boardSaveWeatherData.boardId = 0;
      boardSaveWeatherData.city = currentWeather!.name;
      boardSaveWeatherData.country = currentWeather.sys!.country;
      boardSaveWeatherData.currentTemp = currentWeather.main!.temp?.toStringAsFixed(1);
      boardSaveWeatherData.feelsTemp = currentWeather.main!.feels_like?.toStringAsFixed(1);
      boardSaveWeatherData.humidity = currentWeather.main!.humidity.toString();
      boardSaveWeatherData.icon = currentWeather.weather![0].icon;
      boardSaveWeatherData.lat = currentWeather.coord!.lat.toString();
      boardSaveWeatherData.lon = currentWeather.coord!.lon.toString();
      boardSaveWeatherData.speed = currentWeather.wind!.speed.toString();
      boardSaveWeatherData.tempMax = currentWeather.main!.temp_max?.toStringAsFixed(1);
      boardSaveWeatherData.tempMin = currentWeather.main!.temp_min?.toStringAsFixed(1);
      boardSaveWeatherData.location = Get.find<WeatherCntr>().currentLocation.value!.name;
      // boardSaveWeatherData.thumbnailPath = res2.secureUrl;
      // boardSaveWeatherData.videoPath = res.secureUrl;
      boardSaveWeatherData.weatherInfo = currentWeather.weather![0].description;
      boardSaveData.boardMastInVo = boardSaveMainData;
      boardSaveData.boardWeatherVo = boardSaveWeatherData;
      Lo.g("Root upload() videoFilePath : ${widget.videoFile.path}");

      Utils.alert('임시 등록되었습니다! 잠시후 정상 게시됩니다!');
      Future.delayed(const Duration(milliseconds: 500), () {
        Get.back();
      });
    } catch (e) {
      debugPrint(e.toString());
      isUploading.value = false;
      uploadingPercentage1.value = 0.0;
      uploadingPercentage2.value = 0.0;
    }
  }

  void cancle() {
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
    _videoController.dispose();
    VideoCompress.cancelCompression();

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
                          Container(
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
                                              builder: (BuildContext context) => _PlayerVideoAndPopPage(),
                                            ),
                                          );
                                        },
                                        //  child: Container(color: Colors.red)),
                                        child: VideoPlayer(_videoController)),
                                  ),
                                ),
                                const Positioned(right: 5, bottom: 5, child: Icon(Icons.zoom_in, size: 30, color: Colors.white)),
                              ],
                            ),
                          ),
                          const Gap(5),
                          Expanded(
                            child: Container(
                              alignment: Alignment.topLeft,
                              // height: 300,
                              // width: MediaQuery.of(context).size.width * 0.5 - 50,
                              // alignment: Alignment.center,
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(15),
                                // color: Colors.purple[50],
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // const Text('현재 위치', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87)),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 7),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(5),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                            padding: const EdgeInsets.all(2),
                                            decoration: BoxDecoration(
                                              color: Colors.green.withOpacity(0.9),
                                              borderRadius: BorderRadius.circular(5),
                                            ),
                                            child: const Icon(Icons.location_on, color: Colors.white, size: 15)),
                                        const SizedBox(width: 5),
                                        Text(Get.find<WeatherCntr>().currentLocation.value!.name,
                                            style: const TextStyle(fontSize: 16, color: Colors.black, fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      Text('${Get.find<WeatherCntr>().currentWeather.value!.main!.temp!.toStringAsFixed(1)}°C',
                                          style: const TextStyle(fontSize: 16, color: Colors.black)),
                                      CachedNetworkImage(
                                        cacheKey: Get.find<WeatherCntr>().currentWeather.value?.weather![0].icon ?? '10n',
                                        width: 50,
                                        height: 50,
                                        imageUrl:
                                            'http://openweathermap.org/img/wn/${Get.find<WeatherCntr>().currentWeather.value?.weather![0].icon ?? '10n'}@2x.png',
                                        imageBuilder: (context, imageProvider) => Container(
                                          decoration: BoxDecoration(
                                            image: DecorationImage(
                                                image: imageProvider,
                                                fit: BoxFit.cover,
                                                colorFilter: const ColorFilter.mode(Colors.transparent, BlendMode.colorBurn)),
                                          ),
                                        ),
                                        placeholder: (context, url) => const CircularProgressIndicator(strokeWidth: 1, color: Colors.white),
                                        errorWidget: (context, url, error) => const Icon(Icons.error),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    Get.find<WeatherCntr>().currentWeather.value!.weather![0].description!,
                                    style: const TextStyle(fontSize: 16, color: Colors.black),
                                    overflow: TextOverflow.clip,
                                  ),
                                  const Gap(6),
                                  Text(
                                    '미세: ${Get.find<WeatherCntr>().mistViewData.value!.mist10Grade!.toString()}',
                                    style: const TextStyle(fontWeight: FontWeight.w400, fontSize: 14, color: Colors.black87),
                                  ),
                                  Text('초미세: ${Get.find<WeatherCntr>().mistViewData.value!.mist25Grade!.toString()}',
                                      style: const TextStyle(fontWeight: FontWeight.w400, fontSize: 14, color: Colors.black87)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Gap(20),
                      HashTagTextField(
                        controller: hashTagController,
                        basicStyle: const TextStyle(fontSize: 15, color: Colors.black, decorationThickness: 0),
                        decoratedStyle: const TextStyle(fontSize: 15, color: Colors.blue),
                        keyboardType: TextInputType.multiline,
                        maxLines: 4,
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 7, vertical: 7),
                          hintText: "내용을 입력해주세요! #태그 #태그2 #태그3",
                          //   hintStyle: TextStyle(fontSize: 15, color: Colors.grey),
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
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text('# 태그 사용가능.', style: TextStyle(fontSize: 14, color: Colors.black87)),
                        ],
                      ),
                      const Gap(20),
                      const Gap(10),
                    ],
                  ),
                ),
              ),
              ValueListenableBuilder<double>(
                  valueListenable: uploadingPercentage1,
                  builder: (context, value, child) {
                    return Stack(
                      children: [
                        Container(
                          height: 5,
                          width: MediaQuery.of(context).size.width,
                          color: Colors.grey[200],
                        ),
                        Container(
                          height: 5,
                          width: MediaQuery.of(context).size.width * (value / 100),
                          color: const Color(0xFFEA3799),
                        ),
                      ],
                    );
                  }),
              ValueListenableBuilder<double>(
                  valueListenable: uploadingPercentage2,
                  builder: (context, value, child) {
                    return Stack(
                      children: [
                        Container(
                          height: 5,
                          width: MediaQuery.of(context).size.width,
                          color: Colors.grey[200],
                        ),
                        Container(
                          height: 5,
                          width: MediaQuery.of(context).size.width * (value / 100),
                          color: const Color.fromARGB(255, 34, 39, 133),
                        ),
                      ],
                    );
                  }),
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
                valueListenable: isUploading,
                builder: (context, value, child) {
                  return CustomButton(
                      text: !value ? '등록하기' : '처리중..',
                      type: 'L',
                      // isEnable: !value,
                      widthValue: 120,
                      heightValue: 50,
                      onPressed: () => !value ? upload() : Utils.alert('처리중입니다..'));
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class TotalData {
  String? localName;
  CurrentWeather? currentWeather;
}

class _PlayerVideoAndPopPage extends StatefulWidget {
  @override
  _PlayerVideoAndPopPageState createState() => _PlayerVideoAndPopPageState();
}

class _PlayerVideoAndPopPageState extends State<_PlayerVideoAndPopPage> {
  late VideoPlayerController _videoPlayerController;
  bool startedPlaying = false;

  @override
  void initState() {
    super.initState();

    _videoPlayerController = VideoPlayerController.asset('assets/Butterfly-209.mp4');
    _videoPlayerController.addListener(() {
      if (startedPlaying && !_videoPlayerController.value.isPlaying) {
        Navigator.pop(context);
      }
    });
  }

  @override
  void dispose() {
    _videoPlayerController.dispose();
    super.dispose();
  }

  Future<bool> started() async {
    await _videoPlayerController.initialize();
    await _videoPlayerController.play();
    startedPlaying = true;
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      child: Center(
        child: FutureBuilder<bool>(
          future: started(),
          builder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
            if (snapshot.data ?? false) {
              return AspectRatio(
                aspectRatio: _videoPlayerController.value.aspectRatio,
                child: VideoPlayer(_videoPlayerController),
              );
            } else {
              return const Text('waiting for video to load');
            }
          },
        ),
      ),
    );
  }
}
