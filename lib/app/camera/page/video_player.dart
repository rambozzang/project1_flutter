import 'dart:io';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:gap/gap.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
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

  final ValueNotifier<String> localName = ValueNotifier<String>('');
  final ValueNotifier<TotalData?> totalData = ValueNotifier<TotalData?>(null);

  final ValueNotifier<bool> isUploading = ValueNotifier<bool>(false);
  final ValueNotifier<double> uploadingPercentage = ValueNotifier<double>(0.0);

  final ValueNotifier<double> progress = ValueNotifier<double>(0.0);
  Duration position = Duration.zero;

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
      OpenWheatherRepo repo = OpenWheatherRepo();

      // 위치 좌표 가져오기
      MyLocatorRepo myLocatorRepo = MyLocatorRepo();
      Position? position = await myLocatorRepo.getCurrentLocation();
      //Utils.alert('좌표 가져오기 성공');

      // 좌료를 통해 날씨 정보 가져오기
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
      ResData resData2 = await myLocatorRepo.getLocationName(position);
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
    _subscription.unsubscribe();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      //  backgroundColor: Colors.white,
      //resizeToAvoidBottomInset: false,
      appBar: AppBar(
        backgroundColor: Colors.white,
        centerTitle: false,
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    //  const Gap(10),
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
                              child: VideoPlayer(_videoController),
                            ),
                          ),
                          // Positioned(
                          //   bottom: 0.2,
                          //   left: 9,
                          //   right: 9,
                          //   child: ValueListenableBuilder<double>(
                          //       valueListenable: progress,
                          //       builder: (context, value, child) {
                          //         log('progress : ${(MediaQuery.of(context).size.width) * (value / 100)}');

                          //         return Stack(
                          //           children: [
                          //             Container(
                          //                 margin: const EdgeInsets.symmetric(
                          //                     horizontal: 4),
                          //                 height: 4,
                          //                 color: Colors.grey,
                          //                 width: MediaQuery.of(context)
                          //                     .size
                          //                     .width),
                          //             AnimatedContainer(
                          //               duration:
                          //                   const Duration(milliseconds: 600),
                          //               margin: const EdgeInsets.symmetric(
                          //                   horizontal: 4),
                          //               height: 4,
                          //               width: (MediaQuery.of(context)
                          //                       .size
                          //                       .width) *
                          //                   (value / 100),
                          //               decoration: BoxDecoration(
                          //                 borderRadius:
                          //                     BorderRadius.circular(4),
                          //                 color: const Color.fromRGBO(
                          //                     215, 215, 215, 1),
                          //               ),
                          //             ),
                          //           ],
                          //         );
                          //       }),
                          // ),
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
                        ValueListenableBuilder<String?>(
                            valueListenable: localName,
                            builder: (context, value, child) {
                              if (value == null) {
                                return const SizedBox();
                              }
                              return Text(
                                value.toString(),
                                style: const TextStyle(
                                    fontSize: 14, color: Colors.green),
                              );
                            }),
                        const Gap(10),
                        ValueListenableBuilder<CurrentWeather?>(
                          valueListenable: currentWeather,
                          builder: (context, value, child) {
                            if (value == null) {
                              return const SizedBox();
                            }
                            return Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                    '${value.weather![0].description.toString()}'),
                                Text('${value.main!.temp.toString()}°'),
                              ],
                            );
                          },
                        ),
                      ],
                    ),

                    const Gap(20),
                    const TextField(
                      decoration: InputDecoration(
                          hintStyle: TextStyle(color: Colors.grey),
                          hintText: "내용을 입력해주세요!"),
                    ),
                    const Gap(20),
                    const Text('Tag을 입력해주세요!'),
                    // TextFieldTags<String>(
                    //     textfieldTagsController: _stringTagController,
                    //     initialTags: ['python', 'java'],
                    //     textSeparators: const [' ', ','],
                    //     validator: (String tag) {
                    //       if (tag == 'php') {
                    //         return 'Php not allowed';
                    //       }
                    //       return null;
                    //     },
                    //     inputFieldBuilder: (context, inputFieldValues) {
                    //       return TextField(
                    //         controller: inputFieldValues.textEditingController,
                    //         focusNode: inputFieldValues.focusNode,
                    //       );
                    //     }),
                    const Gap(200),
                  ],
                ),
              ),
            ),
          ),
          ValueListenableBuilder<bool>(
              valueListenable: isUploading,
              builder: (context, value, child) {
                return CustomIndicatorOffstage(
                    isLoading: !value,
                    color: const Color(0xFFEA3799),
                    opacity: 0.0);
              })
        ],
      ),
      bottomNavigationBar: Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
            padding:
                const EdgeInsets.only(left: 16, right: 16, top: 5, bottom: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Spacer(),
                CustomButton(
                    text: '등록하기',
                    type: 'L',
                    widthValue: 120,
                    heightValue: 60,
                    onPressed: () => upload()),
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
