import 'dart:async';

import 'package:get/get.dart';
import 'package:project1/app/auth/cntr/auth_cntr.dart';
import 'package:project1/app/weather/cntr/weather_cntr.dart';
import 'package:project1/repo/board/board_repo.dart';
import 'package:project1/repo/board/data/board_weather_list_data.dart';
import 'package:project1/repo/common/res_data.dart';
import 'package:project1/repo/common/res_stream.dart';
import 'package:project1/app/weathergogo/cntr/weather_gogo_cntr.dart';
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
  int preLoadingCount = 5;

  //현재 영상의 index값 저장
  var currentIndex = 0.obs;

  get position => null;
  RxBool isLoading = false.obs;

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
    isLoadingMore.value = true;

    pageNum = 0;
    getDataWithPagination(isInitialLoad: true);
    update();
  }

  void getData() async {
    pageNum = 0;
    searchType.value = 'TOTAL';

    getDataWithPagination(isInitialLoad: true);
  }

  void getSingAfterGetData(String? singoCd) async {
    lo.g('getSingAfterGetData() 신고 코드 : $singoCd');
    if (singoCd == '07' || singoCd == '08') {
      getData();
    }
  }

  Future<void> getDataWithPagination({bool isInitialLoad = false}) async {
    log("getDataWithPagination() : list length  = ${list.length}");
    try {
      if (isLoading.value == true) {
        return;
      }
      isLoading.value = true;

      if (isInitialLoad) {
        pageNum = 0;
        list.clear();
        videoListCntr.sink.add(ResStream.loading());
      } else {
        if (!isLoadingMore.value) {
          return;
        }
        pageNum++;
      }

      var currentLocation = Get.find<WeatherGogoCntr>().currentLocation.value.latLng;
      String lat = currentLocation?.latitude.toString() ?? '';
      String lon = currentLocation?.longitude.toString() ?? '';

      BoardRepo boardRepo = BoardRepo();
      final apiCallMap = {
        'TOTAL': () => boardRepo.getTotalBoardList(lat, lon, pageNum, pagesize),
        'LOCAL': () => boardRepo.getLocalBoardList(lat, lon, pageNum, pagesize),
        'TAG': () => boardRepo.getTagBoardList(lat, lon, pageNum, pagesize),
        'FOLLOW': () => boardRepo.getFollowBoardList(lat, lon, pageNum, pagesize),
        'DIST': () => boardRepo.getDistinceBoardList(lat, lon, pageNum, pagesize),
      };

      ResData resListData = await apiCallMap[searchType.value]!();

      if (resListData.code != '00') {
        Utils.alert(resListData.msg.toString());
        isLoading.value = false;
        return;
      }

      List<BoardWeatherListData> _list = ((resListData.data) as List).map((data) => BoardWeatherListData.fromMap(data)).toList();

      if (_list.isEmpty) {
        if (isInitialLoad) {
          videoListCntr.sink.add(ResStream.completed([]));
        }
        isLoadingMore.value = false;
        isLoading.value = false;
        return;
      }

      if (isInitialLoad) {
        list = _list;
        mountedList.clear();
      } else {
        list.addAll(_list);
      }

      if (_list.length < pagesize) {
        isLoadingMore.value = false;
      }

      lo.g('list : ${list.length}');

      videoListCntr.sink.add(ResStream.completed(list));

      if (isInitialLoad && Get.find<WeatherGogoCntr>().currentWeather.value.temp == '0.0') {
        Future.delayed(const Duration(milliseconds: 3000), () {
          Get.find<WeatherGogoCntr>().getInitWeatherData(true);
        });
      }
    } catch (e) {
      lo.g('getDataWithPagination() error : $e');
      isLoading.value = false;
      if (isInitialLoad) {
        videoListCntr.sink.add(ResStream.error(e.toString()));
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> follow(String custId) async {
    try {
      // isFollowed.value = 'Y';
      BoardRepo boardRepo = BoardRepo();
      ResData resData = await boardRepo.follow(custId.toString());
      if (resData.code != '00') {
        Utils.alert(resData.msg.toString());
        return false;
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
      return true;
    } catch (e) {
      Utils.alert('실패! 다시 시도해주세요');
      return false;
    }
  }

  Future<bool> followCancle(String custId) async {
    try {
      // isFollowed.value = 'N';
      BoardRepo boardRepo = BoardRepo();
      ResData resData = await boardRepo.followCancle(custId.toString());
      if (resData.code != '00') {
        Utils.alert(resData.msg.toString());
        return false;
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
      return true;
    } catch (e) {
      Utils.alert('실패! 다시 시도해주세요');
      return false;
    }
  }

  void onDispose() {
    videoListCntr.close();

    super.dispose();
  }
}
