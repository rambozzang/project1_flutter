import 'dart:async';

import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';
import 'package:project1/app/auth/cntr/auth_cntr.dart';
import 'package:project1/app/weathergogo/cntr/weather_gogo_cntr.dart';
import 'package:project1/repo/board/board_repo.dart';
import 'package:project1/repo/board/data/board_weather_list_data.dart';
import 'package:project1/repo/common/res_data.dart';
import 'package:project1/repo/common/res_stream.dart';
import 'package:project1/repo/weather/data/current_weather.dart';
import 'package:project1/utils/log_utils.dart';
import 'package:project1/utils/utils.dart';

class VideoMyinfoListCntr extends GetxController {
  final String datatype;
  final String custId;
  final String boardId;
  final String? searchWord;
  final String? southWest;
  final String? northEast;
  final int? searchDay;

  VideoMyinfoListCntr(this.datatype, this.custId, this.boardId, this.searchWord, {this.southWest, this.northEast, this.searchDay});

  // 비디오 리스트
  StreamController<ResStream<List<BoardWeatherListData>>> videoMyListCntr = StreamController();
  // 현재 위치
  late Position? position;
  int pageNum = 0;
  int pagesize = 15;
  bool isLastPage = false;

  var soundOff = false.obs;

  var isLoadingMore = true.obs;
  //현재 영상의 index값 저장
  var currentIndex = 0.obs;
  // 동영상을 담은 리스트
  List<BoardWeatherListData> list = <BoardWeatherListData>[].obs;
  // 현재 날씨
  Rx<CurrentWeather?> currentWeather = CurrentWeather().obs;
  // 동네 이름
  var localName = ''.obs;

  var isloading = true.obs;

  int preLoadingCount = 3;
  @override
  void onInit() {
    super.onInit();
    getInitData();
  }

  Future<void> getInitData() async {
    await getDataWithPagination(isInitialLoad: true);
  }

  Future<void> getDataWithPagination({bool isInitialLoad = false}) async {
    try {
      if (isInitialLoad) {
        videoMyListCntr.sink.add(ResStream.loading());
        list.clear();
        pageNum = 0;
      } else {
        if (!isLoadingMore.value || isLastPage) {
          return;
        }
        pageNum++;
      }

      BoardRepo boardRepo = BoardRepo();
      late ResData resListData;

      if (datatype == 'ONE') {
        resListData = await boardRepo.getBoardByBoardId(boardId);
        if (resListData.code != '00') {
          Utils.alert('해당 게시물은 존재하지 않습니다.');
          return;
        }
        BoardWeatherListData boarIdData = BoardWeatherListData.fromMap(resListData.data);
        list = [boarIdData];
        videoMyListCntr.sink.add(ResStream.completed(list));
        return;
      }

      if (datatype == "MYFEED") {
        resListData = await boardRepo.getMyBoard(custId.toString(), pageNum, pagesize);
      } else if (datatype == "FOLLOW") {
        resListData = await boardRepo.getFollowBoard(custId.toString(), pageNum, pagesize);
      } else if (datatype == "LIKE") {
        resListData = await boardRepo.getLikeBoard(custId.toString(), pageNum, pagesize);
      } else if (datatype == "SEARCHLIST") {
        position = Get.find<WeatherGogoCntr>().positionData.value;

        resListData = await boardRepo.getSearchBoard(
            position!.latitude.toString(), position!.longitude.toString(), pageNum, pagesize, searchWord ?? "");
      } else if (datatype == "LOCAL") {
        // 좌료로 bounds 를 구하기
        var (southWest, northEast) = await getbounds();
        resListData = await boardRepo.searchBoardListByMaplonlatAndDay(
          southWest,
          northEast,
          searchDay ?? 10,
          pageNum,
          pagesize,
        );
      } else {
        position = Get.find<WeatherGogoCntr>().positionData.value;

        resListData = await boardRepo.searchBoardBylatlon(position!.latitude.toString(), position!.longitude.toString(), pageNum, pagesize);
      }

      if (resListData.code != '00') {
        Utils.alert('해당 게시물은 존재하지 않습니다.');
        isLastPage = true;
        return;
      }

      List<BoardWeatherListData> _list = ((resListData.data) as List).map((data) => BoardWeatherListData.fromMap(data)).toList();

      if (_list.isEmpty || _list.length < pagesize) {
        isLastPage = true;
        isLoadingMore.value = false;
      }

      if (isInitialLoad) {
        list = _list;
      } else {
        list.addAll(_list);
      }

      // boardId 관련 로직 (기존 getData 메서드에서 가져옴)
      if (boardId != '' && isInitialLoad) {
        bool isExist = false;
        // _List 에서 boardid 와 같은 데이터를 찾아서 맨 앞으로 이동
        for (int i = 0; i < list.length; i++) {
          if (list[i].boardId == int.parse(boardId)) {
            BoardWeatherListData data = list[i];
            list.removeAt(i);
            list.insert(0, data);
            isExist = true;
            break;
          }
        }
        // 리스트에 boardid 와 같은 데이터가 없으면 다시 해단건만 또 호출
        if (!isExist) {
          //만약에 위에서 boardid 와 같은 데이터를 찾지 못했으면
          // 한건만 가져와 넣어준다 (페이징이 한참 후인 경우 해당 )
          resListData = await boardRepo.getBoardByBoardId(boardId);
          if (resListData.code == '00') {
            BoardWeatherListData boarIdData = BoardWeatherListData.fromMap(resListData.data);
            list.insert(0, boarIdData);
          }
        }
      }
      lo.g('list : ${list.length}');

      videoMyListCntr.sink.add(ResStream.completed(list));
    } catch (e) {
      Lo.g('getDataWithPagination() error : $e');
      videoMyListCntr.sink.add(ResStream.error(e.toString()));
    }
  }

  void getSingAfterGetData(String? singoCd) async {
    lo.g('getSingAfterGetData() 신고 코드 : $singoCd');
    if (singoCd == '07' || singoCd == '08') {
      // getData(pageNum);
      getInitData();
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

  Future<(LatLng, LatLng)> getbounds() async {
    // 현재 위치 가져오기 (예: WeatherGogoCntr에서)
    final currentLocation = Get.find<WeatherGogoCntr>().currentLocation.value;

    if (currentLocation == null) {
      throw Exception('Current location is not available');
    }

    // 현재 위치의 위도와 경도
    double lat = currentLocation.latLng.latitude;
    double lon = currentLocation.latLng.longitude;

    // 범위 설정 (예: 위도와 경도로 각각 0.1도, 대략 11km)
    double latDelta = 0.1;
    double lonDelta = 0.1;

    // 경계 계산
    LatLng southWest = LatLng(lat - latDelta, lon - lonDelta);
    LatLng northEast = LatLng(lat + latDelta, lon + lonDelta);

    return (southWest, northEast);
  }

  void onDispose() {
    videoMyListCntr.sink.close();
    videoMyListCntr.close();
    super.dispose();
  }
}
