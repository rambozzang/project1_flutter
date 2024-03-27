import 'dart:io';
import 'dart:isolate';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:gap/gap.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:hashtagable_v3/hashtagable.dart';
import 'package:project1/app/camera/page/video_indicator.dart';
import 'package:project1/app/cloudinary/cloudinary_page.dart';
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

// 동영상 압축 FFmpeg로 동영상 압축하기
class VideoPage extends StatefulWidget {
  const VideoPage({super.key, required this.videoFile});
  final File videoFile;

  @override
  State<VideoPage> createState() => _VideoPageState();
}

class _VideoPageState extends State<VideoPage> {
  late VideoPlayerController _videoController;

  late Subscription _subscription;
  late MediaInfo? pickedFile;

  final ValueNotifier<CurrentWeather?> currentWeather =
      ValueNotifier<CurrentWeather?>(null);

  final ValueNotifier<String?> localName = ValueNotifier<String?>(null);
  final ValueNotifier<TotalData?> totalData = ValueNotifier<TotalData?>(null);

  final ValueNotifier<bool> isUploading = ValueNotifier<bool>(false);
  final ValueNotifier<double> uploadingPercentage = ValueNotifier<double>(0.0);

  final ValueNotifier<double> progress = ValueNotifier<double>(0.0);
  late Position? position;

  @override
  void initState() {
    _videoController = VideoPlayerController.file(widget.videoFile);

    initializeVideo();
    super.initState();
    getDate();
    _subscription = VideoCompress.compressProgress$.subscribe((progress) {
      log('VideoCompress progress: $progress');
    });

    compressVideo();

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

    //  MediaInfo? pickedFile = await compressVideo();

    if (pickedFile == null) {
      await compressVideo();
    }

    try {
      log(pickedFile!.path.toString());
      final res = await cloudinary.uploadFile(
        CloudinaryFile.fromFile(
          pickedFile!.path.toString(),
          resourceType: CloudinaryResourceType.Video,
          // folder: 'hello-folder',
          // context: {
          //   'alt': 'Hello',
          //   'caption': 'An example image',
          // },
        ),
        onProgress: (count, total) {
          uploadingPercentage.value = (count / total) * 100;
        },
      );
      log(res.toString());

      Utils.alert("정상 등록되었습니다!");
      isUploading.value = false;
      Get.back();
      return;

      // {asset_id: 589dcec7931c12efb379ea632472b541, public_id: VID_2024-03-26_09-53-54-688112223_euuauj, created_at: 2024-03-26 12:54:04.000Z, url: http://res.cloudinary.com/dfbxar2j5/video/upload/v1711457644/VID_2024-03-26_09-53-54-688112223_euuauj.mp4, secure_url: https://res.cloudinary.com/dfbxar2j5/video/upload/v1711457644/VID_2024-03-26_09-53-54-688112223_euuauj.mp4, original_filename: VID_2024-03-26 09-53-54-688112223, tags: [], context: {}, data: {asset_id: 589dcec7931c12efb379ea632472b541, public_id: VID_2024-03-26_09-53-54-688112223_euuauj, version: 1711457644, version_id: 399c18d5612ddbc8dba302632442ea62, signature: f6b7e4ec4e869f18d4112882bdf5d37aba8d582d, width: 640, height: 1136, format: mp4, resource_type: video, created_at: 2024-03-26T12:54:04Z, tags: [], pages: 0, bytes: 1612764, type: upload, etag: 116c06206b2f85fb10ca3fdfdfbe273e, placeholder: false, url: http://res.cloudinary.com/dfbxar2j5/video/upload/v1711457644/VID_2024-03-26_09-53-54-6881
    } on CloudinaryException catch (e) {
      debugPrint(e.message);
      debugPrint(e.request.toString());
      isUploading.value = false;
    }

    isUploading.value = false;
    uploadingPercentage.value = 0.0;
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

  // 비디오 파일 압축
  Future<void> compressVideo() async {
    try {
      log(widget.videoFile.path);

      pickedFile = await VideoCompress.compressVideo(
        widget.videoFile.path,
        quality: VideoQuality.MediumQuality,
        deleteOrigin: false,
        includeAudio: true,
      );
      Lo.g('비디오 압축 결과 : ${pickedFile?.toJson()}');

      // return pickedFile;
    } catch (e) {
      Lo.g('비디오 압축 에러 : $e');
      VideoCompress.cancelCompression();
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
    _subscription.unsubscribe();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      //   resizeToAvoidBottomInset: false,
      //resizeToAvoidBottomInset: false,
      appBar: AppBar(
          backgroundColor: Colors.white,
          centerTitle: false,
          forceMaterialTransparency: false,
          elevation: 0,
          scrolledUnderElevation: 0),
      body: Expanded(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                                    builder: (BuildContext context) =>
                                        _PlayerVideoAndPopPage(),
                                  ),
                                );
                              },
                              child: VideoPlayer(_videoController)),
                        ),
                      ),
                      const Positioned(
                          right: 5,
                          bottom: 5,
                          child: Icon(Icons.zoom_in,
                              size: 30, color: Colors.white))
                    ],
                  ),
                ),
                const Gap(20),
                Column(
                  children: [
                    // Text(_videoController.value.duration.toString().split('.').first,
                    //     style: const TextStyle(fontSize: 14, color: Colors.black)),
                    Row(
                      children: [
                        const Icon(Icons.location_on,
                            color: Colors.red, size: 20),
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
                                  style: const TextStyle(
                                      fontSize: 14, color: Colors.black),
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
                                  Text(
                                    '  ${value.main!.temp!.toStringAsFixed(1)}°',
                                    style: TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.bold),
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
                                  const Text(
                                    ' · ',
                                    style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  //  Text(value.weather![0].description.toString()),
                                  Text(OpenWheatherRepo()
                                      .weatherDescKo[value.weather![0].id]),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
                const Gap(10),
                HashTagTextField(
                  basicStyle: const TextStyle(
                      fontSize: 15,
                      color: Colors.black,
                      decorationThickness: 0),
                  decoratedStyle:
                      const TextStyle(fontSize: 15, color: Colors.blue),
                  keyboardType: TextInputType.multiline,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: "내용을 입력해주세요! #태그 #태그2 #태그3",
                    //   hintStyle: TextStyle(fontSize: 15, color: Colors.grey),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(5),
                        borderSide: const BorderSide(
                            color: Color.fromARGB(255, 59, 104, 81),
                            width: 1.0)),
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
                const Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text('# Tag 사용 가능.',
                        style: TextStyle(fontSize: 14, color: Colors.black87)),
                  ],
                ),
                const Gap(200),
              ],
            ),
          ),
        ),
      ),

      bottomNavigationBar: Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
            padding:
                const EdgeInsets.only(left: 16, right: 16, top: 5, bottom: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
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
                        onPressed: () => !value ? upload() : null);
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

    _videoPlayerController =
        VideoPlayerController.asset('assets/Butterfly-209.mp4');
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
