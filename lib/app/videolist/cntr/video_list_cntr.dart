import 'dart:async';

import 'package:get/get.dart';
import 'package:project1/app/weather/cntr/weather_cntr.dart';
import 'package:project1/repo/board/board_repo.dart';
import 'package:project1/repo/board/data/board_weather_list_data.dart';
import 'package:project1/repo/common/res_data.dart';
import 'package:project1/repo/common/res_stream.dart';
import 'package:project1/utils/log_utils.dart';
import 'package:project1/utils/utils.dart';

// class VideoListBinding implements Bindings {
//   @override
//   void dependencies() {
//     Get.lazyPut<VideoListCntr>(() => VideoListCntr());
//   }
// }

class VideoListCntr extends GetxController {
  // 비디오 리스트
  StreamController<ResStream<List<BoardWeatherListData>>> videoListCntr = StreamController();

  // 동영상을 담은 리스트
  List<BoardWeatherListData> list = <BoardWeatherListData>[].obs;

  // // 현재 위치
  // late Position? position;
  int pageNum = 0;
  int pagesize = 15;
  var soundOff = false.obs;
  int playAtFirst = 0;

  var isLoadingMore = true.obs;
  int preLoadingCount = 3;

  //현재 영상의 index값 저장
  var currentIndex = 0.obs;

  get position => null;

  // StreamController<List<int>> mountedListCntr = StreamController<List<int>>.broadcast();
  RxList<int> mountedList = <int>[].obs;

  var searchType = 'TOTAL'.obs;

  @override
  void onInit() {
    super.onInit();
    getData();
  }

  void onPageMounted(int boardId) {
    mountedList.add(boardId);
    log("mountedList : ${mountedList.toString()}");
    update();
  }

  void swichSearchType(String type) {
    searchType.value = type;
    pageNum = 0;
    getDataProcess();
  }

  getData() {
    pageNum = 0;
    searchType.value = 'TOTAL';
    getDataProcess();
  }

  Future<void> getDataProcess() async {
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
      // ResData resListData = await boardRepo.searchBoardBylatlon(lat.toString(), lon.toString(), pageNum, pagesize);
      late ResData resListData;
      if ('TOTAL'.contains(searchType.value)) {
        resListData = await boardRepo.getTotalBoardList(lat.toString(), lon.toString(), pageNum, pagesize);
      } else if ('LOCAL'.contains(searchType.value)) {
        resListData = await boardRepo.getLocalBoardList(lat.toString(), lon.toString(), pageNum, pagesize);
      } else if ('TAG'.contains(searchType.value)) {
        resListData = await boardRepo.getTagBoardList(lat.toString(), lon.toString(), pageNum, pagesize);
      } else if ('DIST'.contains(searchType.value)) {
        resListData = await boardRepo.getDistinceBoardList(lat.toString(), lon.toString(), pageNum, pagesize);
      } else {
        resListData = await boardRepo.getTotalBoardList(lat.toString(), lon.toString(), pageNum, pagesize);
      }

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

      videoListCntr.sink.add(ResStream.completed(list));

      // 날씨 정보가 없을때만 다시 가져온다.  - 최초시만 가져온다.
      if (Get.find<WeatherCntr>().oneCallCurrentWeather.value?.dt == null) {
        Get.find<WeatherCntr>().getWeatherData();
      }
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
      bool isBottom = index >= list.length - (preLoadingCount + 1);
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
      // ResData resListData = await boardRepo.searchBoardBylatlon(lat.toString(), lon.toString(), pageNum, pagesize);
      late ResData resListData;
      if ('TOTAL'.contains(searchType.value)) {
        resListData = await boardRepo.getTotalBoardList(lat.toString(), lon.toString(), pageNum, pagesize);
      } else if ('LOCAL'.contains(searchType.value)) {
        resListData = await boardRepo.getLocalBoardList(lat.toString(), lon.toString(), pageNum, pagesize);
      } else if ('TAG'.contains(searchType.value)) {
        resListData = await boardRepo.getTagBoardList(lat.toString(), lon.toString(), pageNum, pagesize);
      } else if ('DIST'.contains(searchType.value)) {
        resListData = await boardRepo.getDistinceBoardList(lat.toString(), lon.toString(), pageNum, pagesize);
      } else {
        resListData = await boardRepo.getTotalBoardList(lat.toString(), lon.toString(), pageNum, pagesize);
      }

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
}
