import 'dart:io';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:get/get_connect/http/src/utils/utils.dart';
import 'package:hashtagable_v3/hashtagable.dart';
import 'package:kakao_flutter_sdk/kakao_flutter_sdk.dart';
import 'package:project1/repo/board/board_repo.dart';
import 'package:project1/repo/board/data/board_all_in_data.dart';
import 'package:project1/repo/board/data/board_mast_in_data.dart';
import 'package:project1/repo/board/data/board_weather_data.dart';
import 'package:project1/repo/cloudinary/cloudinary_page.dart';
import 'package:project1/repo/common/res_data.dart';
import 'package:project1/repo/weather/data/current_weather.dart';
import 'package:project1/repo/weather/mylocator_repo.dart';
import 'package:project1/repo/weather/open_weather_repo.dart';
import 'package:project1/utils/log_utils.dart';
import 'package:project1/utils/utils.dart';
import 'package:project1/widget/custom_button.dart';
import 'package:project1/widget/custom_indicator_offstage.dart';
import 'package:video_compress/video_compress.dart';
import 'package:video_player/video_player.dart';

import 'package:path_provider/path_provider.dart';

// 동영상 압축 FFmpeg로 동영상 압축하기
class VideoRegPage extends StatefulWidget {
  const VideoRegPage({super.key, required this.videoFile, required this.currentWeather});
  final File videoFile;
  final CurrentWeather currentWeather;

  @override
  State<VideoRegPage> createState() => _VideoRegPageState();
}

class _VideoRegPageState extends State<VideoRegPage> {
  late VideoPlayerController _videoController;
  final TextEditingController hashTagController = TextEditingController();

  late Subscription _subscription;
  late MediaInfo? pickedFile;

  final ValueNotifier<CurrentWeather?> currentWeather = ValueNotifier<CurrentWeather?>(null);

  final ValueNotifier<String?> localName = ValueNotifier<String?>(null);
  final ValueNotifier<TotalData?> totalData = ValueNotifier<TotalData?>(null);

  final ValueNotifier<bool> isUploading = ValueNotifier<bool>(false);
  final ValueNotifier<double> uploadingPercentage1 = ValueNotifier<double>(0.0);
  final ValueNotifier<double> uploadingPercentage2 = ValueNotifier<double>(0.0);

  final ValueNotifier<double> progress = ValueNotifier<double>(0.0);
  late Position? position;
  final ValueNotifier<bool> isCompress = ValueNotifier<bool>(false);
  late String? thumbnailFile;

  @override
  void initState() {
    _videoController = VideoPlayerController.file(widget.videoFile);

    initializeVideo();
    super.initState();
    getDate();
    // _subscription = VideoCompress.compressProgress$.subscribe((progress) {
    //   log('VideoCompress progress: $progress');
    // });

    compressVideo();

    currentWeather.value = widget.currentWeather;

    // _videoController.addListener(() {
    //   int max = _videoController.value.duration.inSeconds;

    //   position = _videoController.value.position;
    //   progress.value = (position.inSeconds / max * 100).isNaN
    //       ? 0
    //       : position.inSeconds / max * 100;
    // });
  }

  void initializeVideo() async {
    await _videoController.initialize();
    _videoController.setLooping(true);
    _videoController.play();
  }

  Future<void> getDate() async {
    try {
      // 위치 좌표 가져오기
      MyLocatorRepo myLocatorRepo = MyLocatorRepo();
      position = await myLocatorRepo.getCurrentLocation();
      //Utils.alert('좌표 가져오기 성공');

      // 좌료를 통해 날씨 정보 가져오기
      OpenWheatherRepo repo = OpenWheatherRepo();
      ResData resData = await repo.getWeather(position!);

      if (resData.code != '00') {
        Utils.alert(resData.msg.toString());
        return;
      }
      Lo.g('getDate() resData : ${resData.data}');
      currentWeather.value = CurrentWeather.fromMap(resData.data);
      totalData.value?.currentWeather = CurrentWeather.fromMap(resData.data);
      Lo.g('weatherData : ${currentWeather.toString()}');
      //Utils.alert('날씨 가져오기 성공');

      // 좌료를 통해 동네이름 가져오기
      ResData resData2 = await myLocatorRepo.getLocationName(position!);
      if (resData2.code != '00') {
        Utils.alert(resData2.msg.toString());
        return;
      }
      //Utils.alert('동네이름 가져오기 성공');
      Lo.g('동네이름() resData2 : ${resData2.data['ADDR']}');
      localName.value = resData2.data['ADDR'];
      totalData.value?.localName = resData2.data['ADDR'];
    } catch (e) {
      Lo.g('getDate() error : ' + e.toString());
    }
  }

  // 현재 위치 가져오기
  Future<void> getCurrentLocation() async {
    localName.value = '';
    MyLocatorRepo myLocatorRepo = MyLocatorRepo();
    position = await myLocatorRepo.getCurrentLocation();
    ResData resData2 = await myLocatorRepo.getLocationName(position!);
    if (resData2.code != '00') {
      Utils.alert(resData2.msg.toString());
      return;
    }
    //Utils.alert('동네이름 가져오기 성공');
    Lo.g('동네이름() resData2 : ${resData2.data['ADDR']}');
    localName.value = resData2.data['ADDR'];
    totalData.value?.localName = resData2.data['ADDR'];
  }

  // 날씨 가져오기
  Future<void> getWeather() async {
    currentWeather.value = null;
    // 좌료를 통해 날씨 정보 가져오기
    OpenWheatherRepo repo = OpenWheatherRepo();
    ResData resData = await repo.getWeather(position!);

    if (resData.code != '00') {
      Utils.alert(resData.msg.toString());
      return;
    }
    Lo.g('getDate() resData : ${resData.data}');
    currentWeather.value = CurrentWeather.fromMap(resData.data);
  }

  // 파일 업로드
  Future<void> upload() async {
    isUploading.value = true;
    String today = Utils.getToday();

    //  MediaInfo? pickedFile = await compressVideo();

    if (isCompress.value == false) {
      await compressVideo();
    }

    try {
      log(pickedFile!.path.toString());

      final res = await cloudinaryVideo.uploadFile(
        CloudinaryFile.fromFile(
          pickedFile!.path.toString(),
          resourceType: CloudinaryResourceType.Video,
          folder: today,
          // context: {
          //   'alt': 'Hello',
          //   'caption': 'An example image',
          // },
        ),
        onProgress: (count, total) {
          uploadingPercentage1.value = (count / total) * 100;
        },
      );
      lo.g("영상업로드 업로드 결과 : " + res.toString());
      final res2 = await cloudinaryImage.uploadFile(
        CloudinaryFile.fromFile(
          thumbnailFile.toString(),
          resourceType: CloudinaryResourceType.Image,
          folder: today,
          // context: {
          //   'alt': 'Hello',
          //   'caption': 'An example image',
          // },
        ),
        onProgress: (count, total) {
          uploadingPercentage2.value = (count / total) * 100;
        },
      );
      lo.g("썸네일 업로드 결과 : " + res2.toString());

      // 저장
      BoardRepo boardRepo = BoardRepo();

      BoardMastInData boardMastInData = BoardMastInData();
      boardMastInData.contents = hashTagController.text;
      boardMastInData.depthNo = '0';
      boardMastInData.notiEdAt = '';
      boardMastInData.notiStAt = '';
      boardMastInData.subject = '';
      boardMastInData.typeCd = 'V';
      boardMastInData.typeDtCd = 'V';

      BoardWeatherData boardWeatherData = BoardWeatherData();
      boardWeatherData.boardId = 0;
      boardWeatherData.city = currentWeather.value!.name;
      boardWeatherData.country = currentWeather.value!.sys!.country;
      boardWeatherData.currentTemp = currentWeather.value!.main!.temp?.toStringAsFixed(1);
      boardWeatherData.feelsTemp = currentWeather.value!.main!.feels_like?.toStringAsFixed(1);
      boardWeatherData.humidity = currentWeather.value!.main!.humidity.toString();
      boardWeatherData.icon = currentWeather.value!.weather![0].icon;
      boardWeatherData.lat = currentWeather.value!.coord!.lat.toString();
      boardWeatherData.location = localName.value;
      boardWeatherData.lon = currentWeather.value!.coord!.lon.toString();
      boardWeatherData.speed = currentWeather.value!.wind!.speed.toString();
      boardWeatherData.tempMax = currentWeather.value!.main!.temp_max?.toStringAsFixed(1);
      boardWeatherData.tempMin = currentWeather.value!.main!.temp_min?.toStringAsFixed(1);
      boardWeatherData.thumbnailPath = res2.secureUrl;
      boardWeatherData.videoPath = res.secureUrl;
      boardWeatherData.weatherInfo = currentWeather.value!.weather![0].description;

      BoardAllInData boardAllInData = BoardAllInData();
      boardAllInData.boardMastInVo = boardMastInData;
      boardAllInData.boardWeatherVo = boardWeatherData;

      ResData resData = await boardRepo.save(boardAllInData);

      if (resData.code != '00') {
        Utils.alert(resData.msg.toString());
        return;
      }
      Utils.alert('정상 등록되었습니다!');
      Future.delayed(const Duration(milliseconds: 800), () {
        isUploading.value = false;
        Navigator.pop(context);
      });
      return;

      // {asset_id: 589dcec7931c12efb379ea632472b541, public_id: VID_2024-03-26_09-53-54-688112223_euuauj, created_at: 2024-03-26 12:54:04.000Z, url: http://res.cloudinary.com/dfbxar2j5/video/upload/v1711457644/VID_2024-03-26_09-53-54-688112223_euuauj.mp4, secure_url: https://res.cloudinary.com/dfbxar2j5/video/upload/v1711457644/VID_2024-03-26_09-53-54-688112223_euuauj.mp4, original_filename: VID_2024-03-26 09-53-54-688112223, tags: [], context: {}, data: {asset_id: 589dcec7931c12efb379ea632472b541, public_id: VID_2024-03-26_09-53-54-688112223_euuauj, version: 1711457644, version_id: 399c18d5612ddbc8dba302632442ea62, signature: f6b7e4ec4e869f18d4112882bdf5d37aba8d582d, width: 640, height: 1136, format: mp4, resource_type: video, created_at: 2024-03-26T12:54:04Z, tags: [], pages: 0, bytes: 1612764, type: upload, etag: 116c06206b2f85fb10ca3fdfdfbe273e, placeholder: false, url: http://res.cloudinary.com/dfbxar2j5/video/upload/v1711457644/VID_2024-03-26_09-53-54-6881
    } on CloudinaryException catch (e) {
      debugPrint(e.message);
      debugPrint(e.request.toString());
      isUploading.value = false;
      uploadingPercentage1.value = 0.0;
      uploadingPercentage2.value = 0.0;
    }
  }
  //{asset_id: 9d5df6f19ad1a256301c40bb3c346cad,
  // public_id: VID_2024-03-26_07-49-12-268456455_heecms,
  // created_at: 2024-03-26 10:49:21.000Z,
  //url: http://res.cloudinary.com/dfbxar2j5/video/upload/v1711450161/VID_2024-03-26_07-49-12-268456455_heecms.mp4,
  //secure_url: https://res.cloudinary.com/dfbxar2j5/video/upload/v1711450161/VID_2024-03-26_07-49-12-268456455_heecms.mp4,
  //original_filename: VID_2024-03-26 07-49-12-268456455,
  //tags: [],
  //context: {},
  // data:
  //{asset_id: 9d5df6f19ad1a256301c40bb3c346cad,
  // public_id: VID_2024-03-26_07-49-12-268456455_heecms,
  //version: 1711450161,
  //version_id: 414b6929cdf6492fd5488edb175a0aed,
  //signature: 6f740755d45e05ed94c5b38a469f20426ab1a50a,
  //width: 640, height: 1136, format: mp4,
  // resource_type: video,
  // created_at: 2024-03-26T10:49:21Z, tags: [],
  //pages: 0, bytes: 1523141, type: upload, etag:
  // f85b125536e887b2c67f2c4192e95f8e,
  // placeholder: false, url: http://res.cloudinary.com/dfbxar2j5/video/upload/v1711450161/VID_2024-03-26_07-49-12-2684

  // 비디오 파일 압축 및 썸네일 생성
  Future<void> compressVideo() async {
    try {
      isCompress.value = false;
      log(widget.videoFile.path);

      pickedFile = await VideoCompress.compressVideo(
        widget.videoFile.path,
        quality: VideoQuality.MediumQuality,
        deleteOrigin: false,
        includeAudio: true,
      );
      Lo.g('비디오 압축 결과 : ${pickedFile?.toJson()}');
      File ff = await VideoCompress.getFileThumbnail(widget.videoFile.path, quality: 100);
      thumbnailFile = ff.path;
      // thumbnailFile = await VideoThumbnail.thumbnailFile(
      //   video: pickedFile!.path.toString(),
      //   thumbnailPath: (await getTemporaryDirectory()).path,
      //   imageFormat: ImageFormat.JPEG,
      //   maxHeight: 640,
      //   quality: 70,
      // );

      Lo.g('비디오 썸네일 결과 : ${thumbnailFile.toString()}');

      isCompress.value = true;

      // return pickedFile;
    } catch (e) {
      Lo.g('비디오 압축 에러 : $e');
      VideoCompress.cancelCompression();
      isCompress.value = false;
      //return null;
    }
  }

  // 비디오 파일 압축 삭제
  Future<void> removeVideo() async {
    await VideoCompress.deleteAllCache();

    Lo.g('비디오 파일 압축 삭제');
  }

  @override
  void dispose() {
    _videoController.dispose();

    VideoCompress.deleteAllCache();
    VideoCompress.cancelCompression();

    File(pickedFile!.path.toString()).delete();
    File(thumbnailFile!.toString()).delete();
    _subscription.unsubscribe();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: false,
      // appBar: AppBar(
      //     backgroundColor: Colors.white, centerTitle: false, forceMaterialTransparency: false, elevation: 0, scrolledUnderElevation: 0),
      body: SafeArea(
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
                    const Gap(30),
                    Container(
                      height: 300,
                      width: double.infinity,
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
                                  child: VideoPlayer(_videoController)),
                            ),
                          ),
                          const Positioned(right: 5, bottom: 5, child: Icon(Icons.zoom_in, size: 30, color: Colors.white))
                        ],
                      ),
                    ),
                    const Gap(20),
                    HashTagTextField(
                      controller: hashTagController,
                      basicStyle: const TextStyle(fontSize: 15, color: Colors.black, decorationThickness: 0),
                      decoratedStyle: const TextStyle(fontSize: 15, color: Colors.blue),
                      keyboardType: TextInputType.multiline,
                      maxLines: 3,
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 7, vertical: 7),
                        hintText: "내용을 입력해주세요! #태그 #태그2 #태그3",
                        //   hintStyle: TextStyle(fontSize: 15, color: Colors.grey),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(5),
                            borderSide: const BorderSide(color: Color.fromARGB(255, 59, 104, 81), width: 1.0)),
                      ),

                      /// Called when detection (word starts with #, or # and @) is being typed
                      onDetectionTyped: (text) {
                        print(text);
                      },

                      /// Called when detection is fully typed
                      onDetectionFinished: () {
                        print("detection finished");
                      },
                    ),
                    const Gap(10),
                    // const Row(
                    //   mainAxisAlignment: MainAxisAlignment.end,
                    //   children: [
                    //     Text('# 태그 사용가능.', style: TextStyle(fontSize: 14, color: Colors.black87)),
                    //   ],
                    // ),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.grey[100]!,
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.location_on, color: Colors.red, size: 20),
                              ValueListenableBuilder<String?>(
                                  valueListenable: localName,
                                  builder: (context, value, child) {
                                    if (value == null || value == '') {
                                      return const Text(
                                        '현재위치 가져오는중..',
                                      );
                                    }
                                    return GestureDetector(
                                      onTap: () => getCurrentLocation(),
                                      child: Text(
                                        value.toString(),
                                        style: const TextStyle(fontSize: 14, color: Colors.black),
                                      ),
                                    );
                                  }),
                            ],
                          ),
                          const Gap(10),
                          Row(
                            children: [
                              ValueListenableBuilder<CurrentWeather?>(
                                valueListenable: currentWeather,
                                builder: (context, value, child) {
                                  if (value == null) {
                                    return const SizedBox(
                                        height: 40,
                                        child: Center(
                                          child: Text(
                                            '  날씨정보 가져오는중..',
                                            textAlign: TextAlign.left,
                                          ),
                                        ));
                                  }
                                  return GestureDetector(
                                    onTap: () => getWeather(),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.start,
                                      children: [
                                        const Gap(5),
                                        Text(value.weather![0].description.toString()),
                                        //   Text(OpenWheatherRepo().weatherDescKo[value.weather![0].id]),
                                        const Text(
                                          ' · ',
                                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                                        ),
                                        Text(
                                          '${value.main!.temp!.toStringAsFixed(1)}°',
                                          style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                                        ),
                                        SizedBox(
                                          width: 50,
                                          height: 50,
                                          child: Image.network(
                                            // 'http://openweathermap.org/img/wn/${value.weather![0].icon}@2x.png',
                                            'http://openweathermap.org/img/w/${value.weather![0].icon}.png',
                                            scale: 1,
                                            fit: BoxFit.contain,
                                            alignment: Alignment.centerLeft,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                          ValueListenableBuilder<bool>(
                              valueListenable: isCompress,
                              builder: (context, value, child) {
                                if (!value) {
                                  return const Text(
                                    '영상 압축중..',
                                  );
                                }
                                return Row(
                                  children: [
                                    Text(
                                      "재생시간 : ${(_videoController.value.duration.toString().split('.').first).split(':')[1]}:${(_videoController.value.duration.toString().split('.').first).split(':')[2]}",
                                      style: const TextStyle(fontSize: 14, color: Colors.black),
                                    ),
                                    const Gap(20),
                                    GestureDetector(
                                      onTap: () => compressVideo(),
                                      child: const Text(
                                        "압축완료",
                                        textAlign: TextAlign.left,
                                        style: TextStyle(fontSize: 14, color: Colors.black),
                                      ),
                                    ),
                                  ],
                                );
                              }),
                        ],
                      ),
                    ),
                    const Gap(20),
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
                  icon: Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                )),
          ],
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
            )),
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
