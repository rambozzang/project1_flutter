import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:gap/gap.dart';
import 'package:geolocator/geolocator.dart';
import 'package:project1/repo/common/res_data.dart';
import 'package:project1/repo/weather/data/current_weather.dart';
import 'package:project1/repo/weather/mylocator_repo.dart';
import 'package:project1/repo/weather/open_weather_repo.dart';
import 'package:project1/utils/log_utils.dart';
import 'package:project1/utils/utils.dart';

import 'package:video_player/video_player.dart';

class VideoPage extends StatefulWidget {
  const VideoPage({super.key, required this.videoFile});
  final File videoFile;

  @override
  State<VideoPage> createState() => _VideoPageState();
}

class _VideoPageState extends State<VideoPage> {
  late VideoPlayerController _videoController;

  final ValueNotifier<CurrentWeather?> currentWeather =
      ValueNotifier<CurrentWeather?>(null);

  final ValueNotifier<String> localName = ValueNotifier<String>('');
  final ValueNotifier<TotalData?> totalData = ValueNotifier<TotalData?>(null);

  @override
  void initState() {
    _videoController = VideoPlayerController.file(widget.videoFile);
    initializeVideo();
    super.initState();
    getDate();
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

  @override
  void dispose() {
    _videoController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      //  backgroundColor: Colors.white,
      //resizeToAvoidBottomInset: false,
      appBar: AppBar(
        //    backgroundColor: Colors.white,
        title: const Text(""),
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
                    child: AspectRatio(
                      aspectRatio: 9 / 16,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: VideoPlayer(_videoController),
                      ),
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
                            return Text(
                                '${value.weather![0].description.toString()}  ${value.main!.temp.toString()}°');
                          }),
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
      ),
    );
  }
}

class TotalData {
  String? localName;
  CurrentWeather? currentWeather;
}
