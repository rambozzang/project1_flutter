import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:project1/repo/board/board_repo.dart';
import 'package:project1/repo/board/data/board_weather_list_data.dart';
import 'package:project1/repo/common/res_data.dart';
import 'package:project1/repo/common/res_stream.dart';
import 'package:project1/repo/mist_gogoapi/data/mist_data.dart';
import 'package:project1/repo/mist_gogoapi/mist_repo.dart';
import 'package:project1/repo/weather/data/current_weather.dart';
import 'package:project1/repo/weather/mylocator_repo.dart';
import 'package:project1/repo/weather/open_weather_repo.dart';
import 'package:project1/utils/log_utils.dart';
import 'package:project1/utils/utils.dart';
import 'package:dio/src/response.dart' as dioRes;
import 'package:video_player/video_player.dart';

class VideoListBinding implements Bindings {
  @override
  void dependencies() {
    Get.lazyPut<VideoListCntr>(() => VideoListCntr());
  }
}

class VideoListCntr extends GetxController {
  // 비디오 리스트
  StreamController<ResStream<List<BoardWeatherListData>>> videoListCntr = StreamController();

  // 동영상을 담은 리스트
  List<BoardWeatherListData> list = <BoardWeatherListData>[].obs;

  // 비디오 컨트롤러 맵
  Map<int, VideoPlayerController> videoPlayerControllerList = <int, VideoPlayerController>{};

  // 현재 위치
  late Position? position;
  int pageNum = 0;
  int pagesize = 5;
  var soundOff = false.obs;
  int playAtFirst = 0;
  int preLoadingNum = 2;
  var isLoadingMore = true.obs;

  //현재 영상의 index값 저장
  var currentIndex = 0.obs;
  // 현재 날씨
  Rx<CurrentWeather?> currentWeather = CurrentWeather().obs;
  // 동네 이름
  var localName = ''.obs;
  // 미세먼지 10등급
  var mist10Grade = ''.obs;
  // 미세먼지 25등급
  var mist25Grade = ''.obs;
  // 업데이트 시간
  var updateTime = ''.obs;

  @override
  void onInit() {
    super.onInit();
    getData();
    // 미세먼지 가져오기
    localName.listen((value) => getMistData(value));
  }

  // 좌료를 통해 날씨 정보 가져오기
  Future<void> getNowWeather(Position posi) async {
    try {
      OpenWheatherRepo repo = OpenWheatherRepo();
      ResData resData = await repo.getWeather(posi);
      if (resData.code != '00') {
        Utils.alert(resData.msg.toString());
        return;
      }
      Lo.g('getDate() resData : ${resData.data}');
      currentWeather.value = CurrentWeather.fromMap(resData.data);
      updateTime.value = Utils.getTime();
      Lo.g('weatherData : ${currentWeather.toString()}');
    } catch (e) {
      Lo.g('getData() error : $e');
    }
  }

  //  좌료를 통해 동네이름 주소 가져오기
  Future<void> getLocalName(Position posi) async {
    try {
      // 좌료를 통해 동네이름 가져오기
      MyLocatorRepo myLocatorRepo = MyLocatorRepo();
      ResData resData2 = await myLocatorRepo.getLocationName(posi);
      if (resData2.code != '00') {
        Utils.alert(resData2.msg.toString());
        return;
      }
      // Utils.alert('동네이름 가져오기 성공');
      Lo.g('동네이름() resData2 : ${resData2.data['ADDR']}');
      var localNm = resData2.data['ADDR'].toString().split(' ')[0];
      localNm = '${Utils.localReplace(localNm)}, ${resData2.data['ADDR'].toString().split(' ')[1]}';
      localName.value = localNm;
      // localName.value = resData2.data['ADDR'];

      // Google 동네이름 가져오기
      // ResData resData3 = await myLocatorRepo.getPlaceAddress(posi);
      // if (resData2.code != '00') {
      //   Utils.alert(resData3.msg.toString());
      //   return;
      // }
      // Utils.alert('동네이름 가져오기 성공');
      // Lo.g('동네이름() resData3 : ${resData3.toString()}');
      // Lo.g('동네이름() resData3 : ${resData3.data['results'][0]['address_components'][1]['long_name']}');
      // localName.value = resData3.data['results'][0]['address_components'][1]['long_name'];
    } catch (e) {
      Lo.g('getData() error : $e');
    }
  }

  Future<void> getData() async {
    try {
      videoListCntr.sink.add(ResStream.loading());

      // 위치 좌표 가져오기
      MyLocatorRepo myLocatorRepo = MyLocatorRepo();
      position = await myLocatorRepo.getCurrentLocation();
      // 비디오 리스트 가져오기
      BoardRepo boardRepo = BoardRepo();
      ResData resListData = await boardRepo.list(position!.latitude.toString(), position!.longitude.toString(), pageNum, pagesize);

      if (resListData.code != '00') {
        Utils.alert(resListData.msg.toString());
        return;
      }

      list = ((resListData.data) as List).map((data) => BoardWeatherListData.fromMap(data)).toList();

      /// Initialize 1st video
      await _initializeControllerAtIndex(0);

      /// Play 1st video
      _playControllerAtIndex(0);

      // 1번째 비디오를 플레이 화면에 바로 노출하도록 스트림 전송
      videoListCntr.sink.add(ResStream.completed(list));

      /// Initialize 2nd video
      await _initializeControllerAtIndex(1);
      // Initialize 3nd video
      await _initializeControllerAtIndex(2);

      if (position != null) {
        //현재 날씨 가져오기
        getNowWeather(position!);
        // 동네이름 가져오기
        getLocalName(position!);
      }
      //Utils.alert('날씨 가져오기 성공');
    } catch (e) {
      Lo.g('getDate() error : ' + e.toString());
      videoListCntr.sink.add(ResStream.error(e.toString()));
    }
  }

  // 미세먼지 가져오기
  void getMistData(String localName) async {
    try {
      MistRepo mistRepo = MistRepo();

      // 동이름 가져오기
      String _localName = localName.split(' ')[1];
      Lo.g('_localName :  $_localName');

      dioRes.Response? res = await mistRepo.getMistData(_localName);
      MistData mistData = MistData.fromJson(jsonEncode(res!.data['response']['body']));

      mist10Grade.value = '${mistRepo.getMist10Grade(mistData.items![0].pm10Value!)}(${mistData.items![0].pm10Value!}㎍/㎥)';
      mist25Grade.value = '${mistRepo.getMist25Grade(mistData.items![0].pm25Value!)}(${mistData.items![0].pm25Value!}㎍/㎥)';
    } catch (e) {
      Lo.g('getMistData() error : $e');
    }
  }

  // 참고 싸이트 : https://github.com/octomato/preload_page_view/issues/43
  Future<void> getMoreData(int index, int length) async {
    final isBottom = index >= list.length - 2;
    // if (isBottom && !postCubit.state.hasReachedMax && !postCubit.state.isLoading) {
    //    getAllPost();
    // }
    var len = list.length;
    lo.g('🚀🚀🚀 getMoreData index : $index');
    lo.g('🚀🚀🚀 getMoreData list.length : ${list.length}');
    lo.g('🚀🚀🚀 isBottom: ${isBottom}');
    if (!isBottom) {
      return;
    }

    pageNum++;

    BoardRepo boardRepo = BoardRepo();
    ResData resListData = await boardRepo.list(position!.latitude.toString(), position!.longitude.toString(), pageNum, pagesize);

    if (resListData.code != '00') {
      Utils.alert(resListData.msg.toString());
      return;
    }
    List<BoardWeatherListData> _list = ((resListData.data) as List).map((data) => BoardWeatherListData.fromMap(data)).toList();
    list.addAll(_list);

    videoListCntr.sink.add(ResStream.completed(list));
  }

  void playNext(int index) {
    lo.g('🚀 playNext index: $index');
    _playControllerAtIndex(index);
    _manageControllersForNext(index);
    // _logAllControllers();
  }

  void playPrevious(int index) {
    lo.g('🚀 playPrevious index: $index');
    _playControllerAtIndex(index);
    _manageControllersForPrevious(index);
    // _logAllControllers();
  }

  Future<void> _initializeControllerAtIndex(int index) async {
    if (videoPlayerControllerList.containsKey(index) || !_isValidIndex(index)) return;
    if (list[index].videoPath == null) return;

    // 캐쉬 이용시
    // final sfile = await DefaultCacheManager().getSingleFile(list[index].videoPath.toString(), key: list[index].boardId.toString());
    // videoPlayerControllerList[index] = VideoPlayerController.file(sfile);

    // 다운로드 중에 play
    VideoPlayerController? _controller = VideoPlayerController.networkUrl(
        Uri.parse('https://customer-r151saam0lb88khc.cloudflarestream.com/246b9a3bfd9b4bbca1dc739a3b4d35cb/manifest/video.m3u8'));
    // _controller.initialize();
    videoPlayerControllerList[index] = _controller;

    //  lo.g('sfile : ${sfile.lengthSync() / 1000 / 1000}Mb');
    lo.g('🚀 INITIALIZED $index');
  }

  void _stopControllerAtIndex(int index) {
    if (!_isValidIndex(index)) return;

    videoPlayerControllerList[index]?.pause();
    videoPlayerControllerList[index]?.seekTo(const Duration());
    lo.g('🚀 STOPPED $index');
  }

  void _disposeControllerAtIndex(int index) {
    // lo.g('_disposeControllerAtIndex: $index');
    if (!_isValidIndex(index)) return;

    videoPlayerControllerList[index]?.dispose();
    videoPlayerControllerList.remove(index);
    lo.g('🚀 DISPOSED $index');
  }

  void _playControllerAtIndex(int index) async {
    if (!_isValidIndex(index)) return;

    if (videoPlayerControllerList[index] == null) {
      await _initializeControllerAtIndex(index);
    }

    // final _controller = videoPlayerControllerList[index];
    // _controller?.play();
    videoPlayerControllerList[index]!.play();
    // videoListCntr.sink.add(ResStream.completed(list));
    lo.g('🚀 PLAYING $index');
  }

  void _manageControllersForNext(int index) async {
    // preLoadingNum

    _stopControllerAtIndex(index - 1);
    _stopControllerAtIndex(index - 2);
    _disposeControllerAtIndex(index - 3);

    _logAllControllers(index);
    videoListCntr.sink.add(ResStream.completed(list));
    await _initializeControllerAtIndex(index + 1);
    videoListCntr.sink.add(ResStream.completed(list));
    await _initializeControllerAtIndex(index + 2);
    await _initializeControllerAtIndex(index + 3);
    await _initializeControllerAtIndex(index + 4);

    _logAllControllers(index);
  }

  void _manageControllersForPrevious(int index) async {
    _stopControllerAtIndex(index + 1);
    _stopControllerAtIndex(index + 2);
    _disposeControllerAtIndex(index + 3);

    _logAllControllers(index);
    videoListCntr.sink.add(ResStream.completed(list));
    await _initializeControllerAtIndex(index - 1);

    await _initializeControllerAtIndex(index - 2);
    videoListCntr.sink.add(ResStream.completed(list));
  }

  bool _isValidIndex(int index) => index >= 0 && index < list.length;

  void _logAllControllers(int index) {
    lo.g('---------------------------------------------------');
    for (var entry in videoPlayerControllerList.entries) {
      lo.g('🚀 videoPlayerControllerList: ${entry.key} ${index == entry.key ? 'Playing' : ' '}');
    }
    lo.g('---------------------------------------------------');
  }

  void onDispose() {
    videoListCntr.close();

    super.dispose();
  }
}
