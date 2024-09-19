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
  int preLoadingCount = 4;

  //현재 영상의 index값 저장
  var currentIndex = 0.obs;

  get position => null;
  bool isLoading = false;

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
    update();
  }

  void getData() async {
    pageNum = 0;
    searchType.value = 'TOTAL';
    getDataProcess();
  }

  void getSingAfterGetData(String? singoCd) async {
    lo.g('getSingAfterGetData() 신고 코드 : $singoCd');
    if (singoCd == '07' || singoCd == '08') {
      getData();
    }
  }

  Future<void> getDataProcess() async {
    log("getData() : ");
    try {
      if (isLoading == true) {
        //  Utils.alert(resListData.msg.toString());
        return;
      }
      isLoading = true;
      videoListCntr.sink.add(ResStream.loading());
      late String lat;
      late String lon;

      // 위치 좌표 가져오기

      var currentLocation = Get.find<WeatherGogoCntr>().currentLocation.value?.latLng;

      lat = currentLocation?.latitude.toString() ?? '';
      lon = currentLocation?.longitude.toString() ?? '';

      // 비디오 리스트 가져오기
      BoardRepo boardRepo = BoardRepo();
      // 각 searchType에 대한 API 호출 매핑
      final apiCallMap = {
        'TOTAL': () => boardRepo.getTotalBoardList(lat, lon, pageNum, pagesize),
        'LOCAL': () => boardRepo.getLocalBoardList(lat, lon, pageNum, pagesize),
        'TAG': () => boardRepo.getTagBoardList(lat, lon, pageNum, pagesize),
        'FOLLOW': () => boardRepo.getFollowBoardList(lat, lon, pageNum, pagesize),
        'DIST': () => boardRepo.getDistinceBoardList(lat, lon, pageNum, pagesize),
      };

      // API 호출
      ResData resListData = await apiCallMap[searchType.value]!();

      if (resListData.code != '00') {
        Utils.alert(resListData.msg.toString());
        isLoading = false;
        return;
      }
      // 리스트 초기화
      mountedList.clear();

      List<BoardWeatherListData> _list = ((resListData.data) as List).map((data) => BoardWeatherListData.fromMap(data)).toList();

      if (_list.isEmpty) {
        // Utils.alert('데이터가 없습니다.');
        isLoading = false;
        videoListCntr.sink.add(ResStream.completed([]));
        return;
      }

      list = _list;
      videoListCntr.sink.add(ResStream.completed(_list));

      // List<BoardWeatherListData> initList = _list.sublist(0, _list.length > 1 ? 2 : 1);
      // videoListCntr.sink.add(ResStream.completed(initList));
      // Future.delayed(const Duration(milliseconds: 2000), () {
      //   // 1번째 비디오를 플레이 화면에 바로 노출하도록 나머지 스트림 전송
      //   videoListCntr.sink.add(ResStream.completed(_list));
      // });
      // videoListCntr.sink.add(ResStream.completed(list));
      isLoading = false;
    } catch (e) {
      // Lo.g('getDate() error : $e');
      isLoading = false;
      videoListCntr.sink.add(ResStream.error(e.toString()));
    } finally {
      isLoading = false;
      // 리스트가 다 구성이 끝나면 날씨 데이터 가져온다.
      // 날씨 정보가 없을때만 다시 가져온다.  - 최초시만 가져온다.
      if (Get.find<WeatherGogoCntr>().currentWeather.value.temp == '0.0') {
        Future.delayed(const Duration(milliseconds: 3000), () {
          Get.find<WeatherGogoCntr>().getInitWeatherData(true);
        });
      }
    }
  }

  // 참고 싸이트 : https://github.com/octomato/preload_page_view/issues/43
  Future<void> getMoreData(int index, int length) async {
    currentIndex.value = index;
    try {
      bool isBottom = index >= list.length - (preLoadingCount + 1);
      isBottom = length < pagesize ? false : isBottom;
      // if (isBottom && !postCubit.state.hasReachedMax && !postCubit.state.isLoading) {
      //    getAllPost();
      // }
      var len = list.length;

      if (!isBottom) {
        return;
      }

      if (!isLoadingMore.value) {
        return;
      }

      pageNum++;
      var currentLocation = Get.find<WeatherGogoCntr>().currentLocation.value?.latLng;
      String lat = currentLocation?.latitude.toString() ?? '';
      String lon = currentLocation?.longitude.toString() ?? '';

      BoardRepo boardRepo = BoardRepo();
      // ResData resListData = await boardRepo.searchBoardBylatlon(lat.toString(), lon.toString(), pageNum, pagesize);
      // 각 searchType에 대한 API 호출 매핑
      final apiCallMap = {
        'TOTAL': () => boardRepo.getTotalBoardList(lat, lon, pageNum, pagesize),
        'LOCAL': () => boardRepo.getLocalBoardList(lat, lon, pageNum, pagesize),
        'TAG': () => boardRepo.getTagBoardList(lat, lon, pageNum, pagesize),
        'DIST': () => boardRepo.getDistinceBoardList(lat, lon, pageNum, pagesize),
      };

      // API 호출
      ResData resListData = await apiCallMap[searchType.value]!();

      if (resListData.code != '00') {
        Utils.alert(resListData.msg.toString());
        return;
      }
      List<BoardWeatherListData> _list = ((resListData.data) as List).map((data) => BoardWeatherListData.fromMap(data)).toList();

      if (_list.isEmpty || _list.length < pagesize) {
        isLoadingMore.value = false;
      }

      list.addAll(_list);

      videoListCntr.sink.add(ResStream.completed(list));
    } catch (e) {
      lo.g('getMoreData() error : $e');
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
