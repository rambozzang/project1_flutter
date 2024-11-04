import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:project1/app/short/comment/cntr/short_comments_cntr.dart';
import 'package:project1/repo/bbs/bbs_repo.dart';
import 'package:project1/repo/bbs/data/bbs_list_data.dart';
import 'package:project1/repo/bbs/data/bbs_list_res_data.dart';
import 'package:project1/repo/bbs/data/bbs_search_req_data.dart';
import 'package:project1/repo/common/paging_data.dart';
import 'package:project1/repo/common/res_data.dart';
import 'package:project1/repo/common/res_stream.dart';
import 'package:project1/root/cntr/root_cntr.dart';
import 'package:project1/utils/utils.dart';

class ShortListBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ShortListController>(() => ShortListController());
  }
}

class ShortListController extends GetxController {
  // 스크롤 컨트롤러
  ScrollController scrollCtrl = ScrollController();

  // 데이터 스크림
  final StreamController<ResStream<List<BbsListData>>> listCtrl = StreamController();

  List<BbsListData> boardList = [];

  String typeCd = 'LOCA';
  String typeDtCd = 'SHRT';

  String topYn = 'N';

  // bool isLastPage = false;
  int pageNum = 1;
  int pageSzie = 10;
  final ValueNotifier<bool> isLastPage = ValueNotifier<bool>(false);
  final ValueNotifier<bool> isMoreLoading = ValueNotifier<bool>(false);
  late final shortCommentsController;
  @override
  void onInit() {
    super.onInit();

    shortCommentsController = Get.put(ShortCommentsController());
    // shortCommentsController.setParentSBoardId(_boardId);
    shortCommentsController.setSCrollController(scrollCtrl);

    shortCommentsController.fetchComments();
  }

  Future<void> getDataInit() async => getData(1);

  Future<void> getData(int _page) async {
    if (_page != 1) {
      isMoreLoading.value = true;
    } else {
      listCtrl.sink.add(ResStream.loading());
    }
    try {
      BbsRepo repo = BbsRepo();

      BbsSearchData bbsSearchData = BbsSearchData(
          pageNum: _page, pageSize: pageSzie, typeCd: typeCd, typeDtCd: typeDtCd, depthNo: '0', searchWord: '', searchCustId: '');

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
      pageNum = pageData.currPageNum! + 1;
      isLastPage.value = pageData.last!;
      boardList.addAll(_list);
      isMoreLoading.value = false;

      listCtrl.sink.add(ResStream.completed(boardList, message: '조회가 완료되었습니다.'));
    } catch (e) {
      listCtrl.sink.add(ResStream.error(e.toString()));
      isMoreLoading.value = false;
    }
  }

  @override
  void onClose() {
    super.onClose();
  }
}
