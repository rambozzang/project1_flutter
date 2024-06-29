import 'dart:async';
import 'dart:isolate';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:project1/app/weather/provider/weather_cntr.dart';
import 'package:project1/repo/board/board_repo.dart';
import 'package:project1/repo/board/data/board_weather_list_data.dart';
import 'package:project1/repo/common/res_data.dart';
import 'package:project1/repo/common/res_stream.dart';
import 'package:project1/repo/weather/mylocator_repo.dart';
import 'package:project1/utils/log_utils.dart';
import 'package:project1/utils/utils.dart';
import 'package:rxdart/subjects.dart';
import 'package:video_player/video_player.dart';

// class VideoListBinding implements Bindings {
//   @override
//   void dependencies() {
//     Get.lazyPut<VideoListCntr>(() => VideoListCntr());
//   }
// }

class VideoListCntr2 extends GetxController {
  // 비디오 리스트
  StreamController<ResStream<List<BoardWeatherListData>>> videoListCntr = StreamController();

  // 동영상을 담은 리스트
  List<BoardWeatherListData> list = <BoardWeatherListData>[].obs;

  // 비디오 컨트롤러 맵
  Map<int, VideoPlayerController> videoPlayerControllerList = <int, VideoPlayerController>{};

  // // 현재 위치
  // late Position? position;
  int pageNum = 0;
  int pagesize = 15;
  var soundOff = false.obs;
  int playAtFirst = 0;
  int preLoadingNum = 2;
  var isLoadingMore = true.obs;

  //현재 영상의 index값 저장
  var currentIndex = 0.obs;

  get position => null;

  // StreamController<List<int>> mountedListCntr = StreamController<List<int>>.broadcast();
  RxList<int> mountedList = <int>[].obs;

  @override
  void onInit() {
    super.onInit();
    getData();
  }

  void onPageMounted(int boardId) {
    mountedList.add(boardId);

    log("mountedList : ${mountedList.toString()}");

    // mountedListCntr.sink.add(mountedList);
    update();
  }

  Future<void> getData() async {
    log("getData() : ");
    try {
      videoListCntr.sink.add(ResStream.loading());
      late String lat;
      late String lon;

      // 위치 좌표 가져오기
      // if (Get.find<WeatherCntr>().currentLocation.value!.latLng.latitude == 0.0) {
      //   Position? position = await MyLocatorRepo().getCurrentLocation();
      //   lat = position!.latitude.toString();
      //   lon = position!.longitude.toString();
      // } else {
      //   lat = Get.find<WeatherCntr>().currentLocation.value?.latLng.latitude.toString() ?? '';
      //   lon = Get.find<WeatherCntr>().currentLocation.value?.latLng.longitude.toString() ?? '';
      // }
      var currentLocation = Get.find<WeatherCntr>().currentLocation.value?.latLng;

      lat = currentLocation?.latitude.toString() ?? '';
      lon = currentLocation?.longitude.toString() ?? '';

      // 비디오 리스트 가져오기
      BoardRepo boardRepo = BoardRepo();
      ResData resListData = await boardRepo.searchBoardBylatlon(lat.toString(), lon.toString(), pageNum, pagesize);

      if (resListData.code != '00') {
        Utils.alert(resListData.msg.toString());
        return;
      }
      // 리스트 초기화
      mountedList.clear();
      list.clear();

      list = ((resListData.data) as List).map((data) => BoardWeatherListData.fromMap(data)).toList();

      if (list.length == 0) {
        Utils.alert('데이터가 없습니다.');
        Get.find<WeatherCntr>().getWeatherData();
        return;
      }

      /// Initialize 1st video
      await _initializeControllerAtIndex(0);

      /// Play 1st video
      _playControllerAtIndex(0);

      List<BoardWeatherListData> initList = list.sublist(0, list.length > 1 ? 3 : 1);
      lo.g("initList.length : ${initList.length}");

      videoListCntr.sink.add(ResStream.completed(initList));
      Future.delayed(const Duration(milliseconds: 1500), () async {
        /// Initialize 2nd video
        await _initializeControllerAtIndex(1);
        // Initialize 3nd video
        await _initializeControllerAtIndex(2);

        // 1번째 비디오를 플레이 화면에 바로 노출하도록 나머지 스트림 전송
        videoListCntr.sink.add(ResStream.completed(list));
      });

      // 리스트가 다 구성이 끝나면 날씨 데이터 가져온다.
      Future.delayed(const Duration(milliseconds: 3000), () async {
        Get.find<WeatherCntr>().getWeatherData();
      });
    } catch (e) {
      Lo.g('getDate() error : $e');
      videoListCntr.sink.add(ResStream.error(e.toString()));
    } finally {
      // 리스트가 다 구성이 끝나면 날씨 데이터 가져온다.
      // Get.find<WeatherCntr>().getWeatherData();
    }
  }

  // 참고 싸이트 : https://github.com/octomato/preload_page_view/issues/43
  Future<void> getMoreData(int index, int length) async {
    try {
      bool isBottom = index >= list.length - 4;
      isBottom = length < pagesize ? false : isBottom;
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
      var currentLocation = Get.find<WeatherCntr>().currentLocation.value?.latLng;
      String lat = currentLocation?.latitude.toString() ?? '';
      String lon = currentLocation?.longitude.toString() ?? '';

      BoardRepo boardRepo = BoardRepo();
      ResData resListData = await boardRepo.searchBoardBylatlon(lat.toString(), lon.toString(), pageNum, pagesize);

      if (resListData.code != '00') {
        Utils.alert(resListData.msg.toString());
        return;
      }
      List<BoardWeatherListData> _list = ((resListData.data) as List).map((data) => BoardWeatherListData.fromMap(data)).toList();
      list.addAll(_list);

      videoListCntr.sink.add(ResStream.completed(list));
    } catch (e) {
      lo.g('getMoreData() error : $e');
    }
  }

  Future<void> follow(String custId) async {
    try {
      // isFollowed.value = 'Y';
      BoardRepo boardRepo = BoardRepo();
      ResData resData = await boardRepo.follow(custId.toString());
      if (resData.code != '00') {
        Utils.alert(resData.msg.toString());
        return;
      }
      Utils.alert('팔로우 되었습니다!');
      // 현재 리스트에 팔로우여부 변경
      // list[currentIndex.value].followYn = 'Y';

      list.forEach((element) {
        if (element.custId == custId) {
          element.followYn = 'Y';
        }
      });
      update();
    } catch (e) {
      Utils.alert('실패! 다시 시도해주세요');
    }
  }

  Future<void> followCancle(String custId) async {
    try {
      // isFollowed.value = 'N';
      BoardRepo boardRepo = BoardRepo();
      ResData resData = await boardRepo.followCancle(custId.toString());
      if (resData.code != '00') {
        Utils.alert(resData.msg.toString());
        return;
      }

      Utils.alert('팔로우	취소되었습니다!');
      // 현재 리스트에 팔로우여부 변경
      //  list[currentIndex.value].followYn = 'N';
      list.forEach((element) {
        if (element.custId == custId) {
          element.followYn = 'N';
        }
      });
      update();
    } catch (e) {
      Utils.alert('실패! 다시 시도해주세요');
    }
  }

  void onDispose() {
    videoListCntr.close();

    super.dispose();
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
    VideoPlayerController? _controller = VideoPlayerController.networkUrl(Uri.parse(list[index].videoPath.toString()));
    // _controller.initialize();
    videoPlayerControllerList[index] = _controller;
    videoPlayerControllerList[index]!.initialize().then((_) {});

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

    mountedList.remove(list[index].boardId);

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
    _stopControllerAtIndex(index - 3);
    _stopControllerAtIndex(index - 4);
    _disposeControllerAtIndex(index - 3);

    _logAllControllers(index);
    videoListCntr.sink.add(ResStream.completed(list));
    await _initializeControllerAtIndex(index + 1);
    videoListCntr.sink.add(ResStream.completed(list));
    await _initializeControllerAtIndex(index + 2);
    await _initializeControllerAtIndex(index + 3);
    await _initializeControllerAtIndex(index + 4);
    await _initializeControllerAtIndex(index + 5);
    await _initializeControllerAtIndex(index + 6);

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
}
