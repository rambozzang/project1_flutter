import 'dart:async';

import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:project1/repo/board/board_repo.dart';
import 'package:project1/repo/board/data/board_weather_list_data.dart';
import 'package:project1/repo/common/res_data.dart';
import 'package:project1/repo/common/res_stream.dart';
import 'package:project1/repo/weather/data/current_weather.dart';
import 'package:project1/repo/weather/mylocator_repo.dart';
import 'package:project1/repo/weather/open_weather_repo.dart';
import 'package:project1/utils/log_utils.dart';
import 'package:project1/utils/utils.dart';

class VideoMyinfoListBinding implements Bindings {
  @override
  void dependencies() {
    Get.lazyPut<VideoMyinfoListCntr>(() => VideoMyinfoListCntr());
  }
}

class VideoMyinfoListCntr extends GetxController {
  // 비디오 리스트
  StreamController<ResStream<List<BoardWeatherListData>>> videoListCntr = StreamController();
  // 현재 위치
  late Position? position;
  int pageNum = 0;
  int pagesize = 5;

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

  @override
  void onInit() {
    super.onInit();
    getData();
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
      Lo.g('weatherData : ${currentWeather.toString()}');
    } catch (e) {
      Lo.g('getData() error : $e');
    }
  }

  // 동네이름 주소 가져오기
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
      localName.value = resData2.data['ADDR'];

      // Google 동네이름 가져오기
      // ResData resData3 = await myLocatorRepo.getPlaceAddress(position);
      // if (resData2.code != '00') {
      //   Utils.alert(resData3.msg.toString());
      //   return;
      // }
      // Utils.alert('동네이름 가져오기 성공');
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

      BoardRepo boardRepo = BoardRepo();
      ResData resListData = await boardRepo.list(position!.latitude.toString(), position!.longitude.toString(), pageNum, pagesize);

      if (resListData.code != '00') {
        Utils.alert(resListData.msg.toString());
        return;
      }
      list = ((resListData.data) as List).map((data) => BoardWeatherListData.fromMap(data)).toList();
      videoListCntr.sink.add(ResStream.completed(list));
      if (position != null) {
        // getNowWeather(position!);
        // getLocalName(position!);
      }

      //Utils.alert('날씨 가져오기 성공');
    } catch (e) {
      Lo.g('getDate() error : ' + e.toString());
      videoListCntr.sink.add(ResStream.error(e.toString()));
    }
  }

  // 참고 싸이트 : https://github.com/octomato/preload_page_view/issues/43
  Future<void> getMoreData(int index, int length) async {
    final isBottom = index > length - 3;
    // if (isBottom && !postCubit.state.hasReachedMax && !postCubit.state.isLoading) {
    //    getAllPost();
    // }
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

  void onDispose() {
    super.dispose();
  }
}
