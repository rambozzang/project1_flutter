import 'dart:io';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:gap/gap.dart';
import 'package:geolocator/geolocator.dart';
import 'package:project1/app/cloudinary/cloudinary_page.dart';
import 'package:project1/repo/common/res_data.dart';
import 'package:project1/repo/weather/data/current_weather.dart';
import 'package:project1/repo/weather/mylocator_repo.dart';
import 'package:project1/repo/weather/open_weather_repo.dart';
import 'package:project1/utils/log_utils.dart';
import 'package:project1/utils/utils.dart';
import 'package:project1/widget/custom_button.dart';
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

  final ValueNotifier<CurrentWeather?> currentWeather = ValueNotifier<CurrentWeather?>(null);

  final ValueNotifier<String> localName = ValueNotifier<String>('');
  final ValueNotifier<TotalData?> totalData = ValueNotifier<TotalData?>(null);

  final ValueNotifier<bool> isUploading = ValueNotifier<bool>(false);
  final ValueNotifier<double> uploadingPercentage = ValueNotifier<double>(0.0);

  @override
  void initState() {
    _videoController = VideoPlayerController.file(widget.videoFile);
    initializeVideo();
    super.initState();
    getDate();
    _subscription = VideoCompress.compressProgress$.subscribe((progress) {
      log('VideoCompress progress: $progress');
    });
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
      Utils.alert('좌표 가져오기 성공');

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
      Utils.alert('날씨 가져오기 성공');

      // 좌료를 통해 동네이름 가져오기
      ResData resData2 = await myLocatorRepo.getLocationName(position);
      if (resData2.code != '00') {
        Utils.alert(resData2.msg.toString());
        return;
      }
      Utils.alert('동네이름 가져오기 성공');
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
    MediaInfo? _pickedFile = await compressVideo();

    if (_pickedFile == null) return;

    try {
      final res = await cloudinary.uploadFile(
        CloudinaryFile.fromFile(
          _pickedFile!.path.toString(),
          folder: 'hello-folder',
          context: {
            'alt': 'Hello',
            'caption': 'An example image',
          },
        ),
        onProgress: (count, total) {
          uploadingPercentage.value = (count / total) * 100;
        },
      );
      debugPrint(res.toString());
    } on CloudinaryException catch (e) {
      debugPrint(e.message);
      debugPrint(e.request.toString());
      isUploading.value = false;
    }

    isUploading.value = false;
    uploadingPercentage.value = 0.0;
  }

  // 비디오 파일 압축
  Future<MediaInfo?> compressVideo() async {
    MediaInfo? info = await VideoCompress.compressVideo(
      widget.videoFile.path,
      quality: VideoQuality.MediumQuality,
      deleteOrigin: false,
      includeAudio: true,
    );
    Lo.g('비디오 압축 결과 : ${info?.toJson()}');
    return info;
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
      body: SafeArea(
        child: Padding(
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
                        const Positioned(right: 5, bottom: 5, child: Icon(Icons.zoom_in, size: 30, color: Colors.white))
                      ],
                    ),
                  ),
                  // Transform.scale(
                  //   scale: 0.5,
                  //   child: Flexible(
                  //     child: AspectRatio(
                  //       aspectRatio: 9 / 16,
                  //       child: Container(
                  //         color: Colors.black,
                  //         child: VideoPlayer(_videoController),
                  //       ),
                  //     ),
                  //   ),
                  // ),
                  // ElevatedButton(
                  //     onPressed: () => getDate(), child: Text('aaaa')),
                  const Gap(20),
                  Row(
                    children: [
                      ValueListenableBuilder<String?>(
                          valueListenable: localName,
                          builder: (context, value, child) {
                            if (value == null) {
                              return const SizedBox();
                            }
                            return Text(
                              value.toString(),
                              style: const TextStyle(fontSize: 14, color: Colors.green),
                            );
                          }),
                      const Gap(10),
                      ValueListenableBuilder<CurrentWeather?>(
                        valueListenable: currentWeather,
                        builder: (context, value, child) {
                          if (value == null) {
                            return const SizedBox();
                          }
                          return Text('${value.weather![0].description.toString()}  ${value.main!.temp.toString()}°');
                        },
                      ),
                    ],
                  ),

                  const Gap(20),
                  const TextField(
                    decoration: InputDecoration(hintStyle: TextStyle(color: Colors.grey), hintText: "내용을 입력해주세요!"),
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
      ),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
            padding: const EdgeInsets.only(left: 16, right: 16, top: 5, bottom: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Spacer(),
                CustomButton(text: '등록하기', type: 'L', widthValue: 120, heightValue: 60, onPressed: () => upload()),
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
