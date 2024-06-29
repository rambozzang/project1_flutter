import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';
import 'package:project1/app/auth/cntr/auth_cntr.dart';
import 'package:project1/app/weather/provider/weather_cntr.dart';
import 'package:project1/repo/board/board_repo.dart';
import 'package:project1/repo/board/data/board_weather_list_data.dart';
import 'package:project1/repo/common/res_data.dart';
import 'package:project1/repo/common/res_stream.dart';
import 'package:project1/repo/weather/data/current_weather.dart';
import 'package:project1/repo/weather/mylocator_repo.dart';
import 'package:project1/repo/weather/open_weather_repo.dart';
import 'package:project1/utils/log_utils.dart';
import 'package:project1/utils/utils.dart';

class VideoMyinfoListCntr extends GetxController {
  final String datatype;
  final String custId;
  final String boardId;
  final String? searchWord;

  VideoMyinfoListCntr(this.datatype, this.custId, this.boardId, this.searchWord);

  // 비디오 리스트
  StreamController<ResStream<List<BoardWeatherListData>>> videoMyListCntr = StreamController();
  // 현재 위치
  late Position? position;
  int pageNum = 0;
  int pagesize = 15;

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

  @override
  void onInit() {
    super.onInit();
    getData();
  }

  Future<void> getData() async {
    try {
      lo.g('00000');
      list = [];
      BoardWeatherListData boarIdData = BoardWeatherListData();
      lo.g('11111111');

      videoMyListCntr.sink.add(ResStream.loading());
      lo.g('2222222');
      // 위치 좌표 가져오기
      // MyLocatorRepo myLocatorRepo = MyLocatorRepo();
      //  position = await myLocatorRepo.getCurrentLocation();

      BoardRepo boardRepo = BoardRepo();
      lo.g('3333333333');
      late ResData resListData;

      lo.g('getData(): datatype : ' + datatype);
      lo.g('getData(): boardId : ' + boardId);

      // boardId가 있으면 해당 게시물만 가져오기
      if (datatype == 'ONE') {
        resListData = await boardRepo.getBoardByBoardId(boardId);
        if (resListData.code != '00') {
          Utils.alert(resListData.msg.toString());
          return;
        }
        boarIdData = BoardWeatherListData.fromMap(resListData.data);
        list.add(boarIdData);
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
        position = Get.find<WeatherCntr>().positionData;

        resListData = await boardRepo.getSearchBoard(
            position!.latitude.toString(), position!.longitude.toString(), pageNum, pagesize, searchWord ?? "");
      } else {
        position = Get.find<WeatherCntr>().positionData;

        resListData = await boardRepo.searchBoardBylatlon(position!.latitude.toString(), position!.longitude.toString(), pageNum, pagesize);
      }

      if (resListData.code != '00') {
        Utils.alert(resListData.msg.toString());
        return;
      }

      List<BoardWeatherListData> _list = ((resListData.data) as List).map((data) => BoardWeatherListData.fromMap(data)).toList();

      if (_list.length == 1) {
        videoMyListCntr.sink.add(ResStream.completed(_list));
        return;
      }

      //  boardid 가 있으면 해당 게시물이 맨 앞으로 오도록
      if (boardId != '') {
        bool isExist = false;
        // _List 에서 boardid 와 같은 데이터를 찾아서 맨 앞으로 이동
        for (int i = 0; i < _list.length; i++) {
          if (_list[i].boardId == int.parse(boardId)) {
            BoardWeatherListData data = _list[i];
            _list.removeAt(i);
            _list.insert(0, data);
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
            boarIdData = BoardWeatherListData.fromMap(resListData.data);
            _list.insert(0, boarIdData);
          }
        }
      }

      list.addAll(_list);

      // videoListCntr.sink.add(ResStream.completed(list));
      List<BoardWeatherListData> initList = list.sublist(0, list.length > 1 ? 2 : 1);
      lo.g("initList.length : ${initList.length}");

      videoMyListCntr.sink.add(ResStream.completed(initList));
      Future.delayed(const Duration(milliseconds: 1000), () {
        // 1번째 비디오를 플레이 화면에 바로 노출하도록 나머지 스트림 전송
        videoMyListCntr.sink.add(ResStream.completed(list));
      });

      //Utils.alert('날씨 가져오기 성공');
    } catch (e) {
      Lo.g('getDate() error : ' + e.toString());
      videoMyListCntr.sink.add(ResStream.error(e.toString()));
    }
  }

  // 참고 싸이트 : https://github.com/octomato/preload_page_view/issues/43
  Future<void> getMoreData(int index, int length) async {
    // index :  3 , length :  5  =>  3 > 0 true;
    // index:    , length : 15 =>  3 > 10 false;
    // pagesize

    bool isBottom = index > length - 7;
    isBottom = length < pagesize ? false : isBottom;
    // false 이면 바로 리턴 (더이상 데이터가 없음)
    if (!isBottom) {
      return;
    }

    pageNum++;

    BoardRepo boardRepo = BoardRepo();

    late ResData resListData;
    if (datatype == "MUYFEED") {
      resListData = await boardRepo.getMyBoard(Get.find<AuthCntr>().resLoginData.value.custId.toString(), pageNum, pagesize);
    } else if (datatype == "FOLLOW") {
      resListData = await boardRepo.getFollowBoard(Get.find<AuthCntr>().resLoginData.value.custId.toString(), pageNum, pagesize);
    } else if (datatype == "LIKE") {
      resListData = await boardRepo.searchBoardBylatlon(position!.latitude.toString(), position!.longitude.toString(), pageNum, pagesize);
    } else if (datatype == "SEARCHLIST") {
      resListData = await boardRepo.getSearchBoard(
          position!.latitude.toString(), position!.longitude.toString(), pageNum, pagesize, searchWord ?? "");
    } else if (datatype == "ONE") {
      videoMyListCntr.sink.add(ResStream.completed(list));
      return;
    } else {
      resListData = await boardRepo.searchBoardBylatlon(position!.latitude.toString(), position!.longitude.toString(), pageNum, pagesize);
    }

    if (resListData.code != '00') {
      Utils.alert(resListData.msg.toString());
      return;
    }
    List<BoardWeatherListData> _list = ((resListData.data) as List).map((data) => BoardWeatherListData.fromMap(data)).toList();
    list.addAll(_list);
    videoMyListCntr.sink.add(ResStream.completed(list));
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
    videoMyListCntr.sink.close();
    videoMyListCntr.close();
    super.dispose();
  }
}
