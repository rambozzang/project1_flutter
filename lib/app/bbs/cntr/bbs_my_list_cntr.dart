import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:project1/repo/bbs/bbs_repo.dart';
import 'package:project1/repo/bbs/data/bbs_list_data.dart';
import 'package:project1/repo/bbs/data/bbs_list_res_data.dart';
import 'package:project1/repo/bbs/data/bbs_search_req_data.dart';
import 'package:project1/repo/common/paging_data.dart';
import 'package:project1/repo/common/res_data.dart';
import 'package:project1/repo/common/res_stream.dart';
import 'package:project1/root/cntr/root_cntr.dart';
import 'package:project1/utils/log_utils.dart';
import 'package:project1/utils/utils.dart';

class BbsMyListinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<BbsMyListController>(() => BbsMyListController());
  }
}

class BbsMyListController extends GetxController {
  // 스크롤 컨트롤러
  ScrollController scrollCtrl = ScrollController();

  // 데이터 스크림
  final StreamController<ResStream<List<BbsListData>>> listCtrl = StreamController();

  RxList<BbsListData> boardList = <BbsListData>[].obs;

  String typeCd = 'BBS';
  String typeDtCd = 'ALL';

  String topYn = 'N';

  // bool isLastPage = false;
  int currentPage = 1;
  final int pageSize = 15;
  RxInt toalCount = 0.obs;
  Timer? debounceTimer; // 타이머 변수
  bool isLoading = false;
  bool isLastPage = false;
  late String searchCustid;

  final ValueNotifier<bool> isMoreLoading = ValueNotifier<bool>(false);

  @override
  void onInit() {
    super.onInit();

    scrollCtrl.addListener(() {
      RootCntr.to.changeScrollListner(scrollCtrl);

      debounceTimer = Timer(const Duration(milliseconds: 350), () {
        if (scrollCtrl.position.pixels >= scrollCtrl.position.maxScrollExtent * 0.75) {
          if (!isLastPage && isLoading == false) {
            isLoading = true;
            currentPage++;
            lo.g('commentsList  :  currentPage : $currentPage');
            getData(currentPage, searchCustid);
          }
        }
      });
    });
  }

  Future<void> getDataInit() async => getData(1, searchCustid);

  Future<void> getData(int _page, String _searchCustid) async {
    currentPage = _page;
    searchCustid = _searchCustid;
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
          typeDtCd: typeDtCd,
          depthNo: '0',
          searchWord: '',
          searchCustId: _searchCustid);

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

  @override
  void onClose() {
    super.onClose();
  }
}
