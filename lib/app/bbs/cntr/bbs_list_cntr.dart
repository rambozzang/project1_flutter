import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:project1/repo/bbs/bbs_repo.dart';
import 'package:project1/repo/bbs/data/bbs_list_data.dart';
import 'package:project1/repo/bbs/data/bbs_list_res_data.dart';
import 'package:project1/repo/bbs/data/bbs_search_req_data.dart';
import 'package:project1/repo/common/code_data.dart';
import 'package:project1/repo/common/comm_repo.dart';
import 'package:project1/repo/common/paging_data.dart';
import 'package:project1/repo/common/res_data.dart';
import 'package:project1/repo/common/res_stream.dart';
import 'package:project1/root/cntr/root_cntr.dart';
import 'package:project1/utils/log_utils.dart';
import 'package:project1/utils/utils.dart';

class BbsListinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<BbsListController>(() => BbsListController());
  }
}

class BbsListController extends GetxController {
  // 스크롤 컨트롤러
  late ScrollController scrollCtrl;

  // 데이터 스크림
  final StreamController<ResStream<List<BbsListData>>> listCtrl = StreamController();

  List<BbsListData> boardList = [];
  RxList<CodeRes> bbsTypeList = <CodeRes>[].obs;

  String typeCd = 'BBS';
  RxString typeDtCd = 'ALL'.obs;
  RxString searchWord = ''.obs;

  String topYn = 'N';

  // bool isLastPage = false;
  int currentPage = 1;
  final int pageSize = 15;
  RxInt toalCount = 0.obs;
  Timer? debounceTimer; // 타이머 변수
  bool isLoading = false;
  bool isLastPage = false;
  RxBool isShowRegButton = true.obs;

  final ValueNotifier<bool> isMoreLoading = ValueNotifier<bool>(false);

  @override
  void onInit() {
    super.onInit();
    getBbsType();
  }

  void onInitScrollCtrl(ScrollController _scrollCtrl) {
    scrollCtrl = _scrollCtrl;
    scrollCtrl.addListener(() {
      RootCntr.to.changeScrollListner(scrollCtrl);

      debounceTimer = Timer(const Duration(milliseconds: 350), () {
        if (scrollCtrl.position.pixels >= scrollCtrl.position.maxScrollExtent * 0.75) {
          if (!isLastPage && isLoading == false) {
            isLoading = true;
            currentPage++;
            lo.g('commentsList  :  currentPage : $currentPage');
            getData(currentPage);
          }
        }
      });
    });
  }

  Future<void> getDataInit() async => getData(1);

  Future<void> getData(int _page, {String? searchType = 'ALL'}) async {
    currentPage = _page;

    if (_page != 1) {
      isMoreLoading.value = true;
    } else {
      listCtrl.sink.add(ResStream.loading());
    }
    try {
      isLoading = true;
      BbsRepo repo = BbsRepo();

      BbsSearchData bbsSearchData = BbsSearchData(
          pageNum: _page,
          pageSize: pageSize,
          typeCd: typeCd,
          typeDtCd: searchType ?? typeDtCd.value,
          depthNo: '0',
          searchWord: searchWord.value,
          searchCustId: '');

      ResData resData = await repo.list(bbsSearchData);

      if (resData.code != '00') {
        Utils.alert(resData.msg.toString());
        listCtrl.sink.add(ResStream.error(resData.msg.toString()));
        return;
      }
      // List<BbsListResData> _list = ((resData.data['list']) as List).map((data) => BbsListResData.fromMap(data)).toList();
      BbsListResData result = BbsListResData.fromMap(resData.data);
      List<BbsListData> _list = result.bbsList;

      if (_page == 1) {
        boardList.clear();
      }
      PagingData pageData = PagingData.fromMap(resData.data['pageData']);

      isLastPage = result.pageData.last;
      toalCount.value = result.pageData.totalElements;

      boardList.addAll(_list);
      isMoreLoading.value = false;

      listCtrl.sink.add(ResStream.completed(boardList, message: '조회가 완료되었습니다.'));
    } catch (e) {
      listCtrl.sink.add(ResStream.error(e.toString()));
      isMoreLoading.value = false;
    } finally {
      isLoading = false;
    }
  }

  // 게시판 타입 조회 하기
  Future<void> getBbsType() async {
    try {
      CommRepo repo = CommRepo();
      CodeReq reqData = CodeReq();
      reqData.pageNum = 0;
      reqData.pageSize = 100;
      reqData.grpCd = 'BBS_TP';
      reqData.code = '';
      reqData.useYn = 'Y';
      ResData res = await repo.searchCode(reqData);

      if (res.code != '00') {
        Utils.alert(res.msg.toString());
        return;
      }
      List<CodeRes> dataList = (res.data as List).map<CodeRes>((e) => CodeRes.fromMap(e)).toList();

      bbsTypeList.value = dataList;

      lo.g('searchRecomWord : ${res.data}');
    } catch (e) {
      lo.g('error searchRecomWord : $e');
    }
  }

  @override
  void onClose() {
    super.onClose();
  }
}
