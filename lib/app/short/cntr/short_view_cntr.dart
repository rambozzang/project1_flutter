import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';
import 'package:project1/app/auth/cntr/auth_cntr.dart';
import 'package:project1/app/short/comment/cntr/short_comments_cntr.dart';
import 'package:project1/app/weather/models/geocode.dart';
import 'package:project1/app/weathergogo/cntr/weather_gogo_cntr.dart';
import 'package:project1/app/weathergogo/services/location_service.dart';

import 'package:project1/repo/bbs/bbs_repo.dart';
import 'package:project1/repo/bbs/data/bbs_list_data.dart';
import 'package:project1/repo/board/board_repo.dart';
import 'package:project1/repo/common/res_data.dart';
import 'package:project1/repo/common/res_stream.dart';
import 'package:project1/repo/cust/cust_repo.dart';
import 'package:project1/repo/cust/data/cust_tag_data.dart';
import 'package:project1/utils/StringUtils.dart';
import 'package:project1/utils/log_utils.dart';
import 'package:project1/utils/utils.dart';
import 'package:rxdart/rxdart.dart';

class ShortViewBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ShortViewController>(() => ShortViewController());
  }
}

class ShortViewController extends GetxController {
  final ScrollController scrollController = ScrollController();
  final StreamController<ResStream<BbsListData>> dataStreamController = BehaviorSubject();

  final FocusNode htmlFocus = FocusNode();

  final ValueNotifier<bool> isLike = ValueNotifier<bool>(false);
  final ValueNotifier<int> isCount = ValueNotifier<int>(0);
  final ValueNotifier<bool> isFavLocal = ValueNotifier<bool>(false);

  // 운영계에서 false 로 변경
  bool _isUpdateCount = false;
  late BbsListData bbsViewData;

  late final commentsController;
  late String searchAddress;
  late String searchLat;
  late String searchLng;

  @override
  void onInit() {
    super.onInit();
  }

  Future<void> fetchDataInit(String _address, String _lat, String _lng) async {
    // 전체 주소 가져오기 경기도 성남시 분당구

    lo.g('@@@ ShortViewController fetchDataInit _address : $_address');

    if (StringUtils.isEmpty(_address)) {
      if (StringUtils.isEmpty(_lat) || StringUtils.isEmpty(_lng)) {
        Utils.alert('날씨 정보를 조회 후 다시 시도해주세요.');
        Get.back();
        return;
      }
      // kakao 로 주소 다시 가져오기
      LocationService locationService = LocationService();
      // 도, 시 , 구 주소 가져오기
      String address = await locationService.getAdressName(LatLng(double.parse(_lat), double.parse(_lng)));
      lo.g('@@@ ShortViewController fetchDataInit address : $address');
      searchAddress = _address;
    } else {
      searchAddress = _address;
    }
    lo.g('@@@ ShortViewController fetchDataInit searchAddress : $searchAddress');
    searchLat = _lat;
    searchLng = _lng;
    fetchData(searchAddress, _lat, _lng);

    // 댓글 관련
    commentsController = Get.put(ShortCommentsController());
    commentsController.setSCrollController(scrollController);
  }

  // 조회수 증가
  Future<void> updateCount(boardId) async {
    BoardRepo boardRepo = BoardRepo();
    try {
      await boardRepo.updateBoardCount(boardId.toString());
    } catch (e) {
      lo.g('@@@ VideoScreenPage  updateCount error : $e');
    }
  }

  Future<void> fetchData(String _address, String _lat, String _lng) async {
    try {
      dataStreamController.sink.add(ResStream.loading());
      BbsRepo repo = BbsRepo();
      ResData resData = await repo.detailbylatlng(_address, _lat, _lng);
      // ResData resData = await repo.detail(boardId);

      if (resData.code != '00') {
        Utils.alert(resData.msg.toString());
        dataStreamController.sink.add(ResStream.error(resData.msg.toString()));
        return;
      }

      if (resData.data == null) {
        Utils.alert("삭제된 게시물입니다.");
        Get.back();
        return;
      }

      BbsListData boardList = BbsListData.fromMap(resData.data);

      // 댓글 초기화 및 데이터 조회
      commentsController.setInitData(boardList);

      incrementViewCount();

      bbsViewData = boardList;
      isLike.value = boardList.likeYn == 'Y';
      isCount.value = int.parse(boardList.likeCnt.toString());
      dataStreamController.sink.add(ResStream.completed(boardList, message: '조회가 완료되었습니다.'));
      // updateCount(boardList.boardId.toString());
    } catch (e) {
      dataStreamController.sink.add(ResStream.error(e.toString()));
    }
  }

  // 조회수 증가
  Future<void> incrementViewCount() async {
    if (_isUpdateCount) return;

    _isUpdateCount = true;
    BoardRepo boardRepo = BoardRepo();
    try {
      await boardRepo.updateBoardCount(bbsViewData.boardId.toString());
    } catch (e) {
      lo.g('@@@ VideoScreenPage  updateCount error : $e');
    }
  }

  Future<void> like() async {
    try {
      BoardRepo boardRepo = BoardRepo();
      ResData resData = await boardRepo.like(bbsViewData.boardId.toString(), bbsViewData.crtCustId.toString(), "Y");
      if (resData.code != '00') {
        Utils.alert(resData.msg.toString());
        return;
      }
    } catch (e) {
      // Utils.alert('좋아요 실패! 다시 시도해주세요');
    }
  }

  Future<void> likeCancel() async {
    try {
      BoardRepo boardRepo = BoardRepo();
      ResData resData = await boardRepo.likeCancle(bbsViewData.boardId.toString());
      if (resData.code != '00') {
        Utils.alert(resData.msg.toString());
        return;
      }
    } catch (e) {
      Utils.alert('좋아요 실패! 다시 시도해주세요');
    }
  }

  // 게시글 삭제
  Future<void> delete(String boardId) async {
    try {
      BbsRepo bbsrepo = BbsRepo();
      ResData resData = await bbsrepo.delete(boardId.toString());
      if (resData.code != '00') {
        Utils.alert(resData.msg.toString());
        return;
      }
      Utils.alert('게시글이 삭제되었습니다.');
      Get.back();
    } catch (e) {
      Utils.alert('게시글 삭제에 실패했습니다.');
    }
  }

  //관심 지역 추가
  Future<void> addLocalTag() async {
    try {
      CustRepo repo = CustRepo();
      CustTagData data = CustTagData();

      data.custId = AuthCntr.to.resLoginData.value.custId.toString();
      data.tagNm = searchAddress.contains(",") ? searchAddress.split(",")[0] : searchAddress;
      data.tagType = 'LOCAL';
      data.lat = searchLat;
      data.lon = searchLat;
      data.addr = searchAddress.toString();
      ResData res = await repo.saveTag(data);
      if (res.code != '00') {
        Utils.alert(res.msg.toString());
        return;
      }
      Utils.alert('추가되었습니다.');
      Get.find<WeatherGogoCntr>().getLocalTag();
      //   getTag();
    } catch (e) {
      Utils.alert(e.toString());
    }
  }

  @override
  void onClose() {
    isLike.dispose();
    dataStreamController.sink.close();
    dataStreamController.close();
    super.onClose();
  }
}
