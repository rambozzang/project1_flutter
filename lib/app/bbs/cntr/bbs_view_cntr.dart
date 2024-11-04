import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:project1/app/bbs/comments/cntr/bbs_comments_cntr.dart';
import 'package:project1/repo/bbs/bbs_repo.dart';
import 'package:project1/repo/bbs/data/bbs_list_data.dart';
import 'package:project1/repo/board/board_repo.dart';
import 'package:project1/repo/cloudflare/cloudflare_repo.dart';
import 'package:project1/repo/common/res_data.dart';
import 'package:project1/repo/common/res_stream.dart';
import 'package:project1/utils/log_utils.dart';
import 'package:project1/utils/utils.dart';

class BbsViewBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<BbsViewController>(() => BbsViewController());
  }
}

class BbsViewController extends GetxController {
  final ScrollController scrollController = ScrollController();
  final StreamController<ResStream<BbsListData>> dataStreamController = StreamController();

  final FocusNode htmlFocus = FocusNode();

  final ValueNotifier<bool> isLike = ValueNotifier<bool>(false);
  final ValueNotifier<int> isCount = ValueNotifier<int>(0);
  BbsRepo bbsrepo = BbsRepo();
  // 운영계에서 false 로 변경
  bool _isUpdateCount = false;
  late BbsListData bbsViewData;

  late final commentsController;

  CloudflareRepo cloudflare = CloudflareRepo();

  RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    init();
  }

  Future<void> init() async {
    await cloudflare.init();
  }

  Future<void> fetchDataInit(String _boardId) async {
    fetchData(_boardId);
    incrementViewCount(_boardId);
  }

  Future<void> fetchData(String boardId) async {
    try {
      dataStreamController.sink.add(ResStream.loading());

      ResData resData = await bbsrepo.detail(boardId);

      if (resData.code != '00') {
        Utils.alert(resData.msg.toString());
        dataStreamController.sink.add(ResStream.error(resData.msg.toString()));
        return;
      }
      if (resData.data == null) {
        Utils.alert("삭제된 게시물입니다.");
        Get.back(result: true);
        return;
      }

      BbsListData boardList = BbsListData.fromMap(resData.data);

      bbsViewData = boardList;

      isLike.value = boardList.likeYn == 'Y';
      isCount.value = int.parse(boardList.likeCnt.toString());
      dataStreamController.sink.add(ResStream.completed(boardList, message: '조회가 완료되었습니다.'));
    } catch (e) {
      dataStreamController.sink.add(ResStream.error(e.toString()));
      Get.back(result: true);
      return;
    }
  }

  // 조회수 증가
  Future<void> incrementViewCount(_boardId) async {
    if (_isUpdateCount) return;

    _isUpdateCount = true;
    BoardRepo boardRepo = BoardRepo();
    try {
      await boardRepo.updateBoardCount(_boardId.toString());
    } catch (e) {
      lo.g('@@@ VideoScreenPage  updateCount error : $e');
    }
  }

  Future<void> like() async {
    try {
      BoardRepo boardRepo = BoardRepo();
      ResData resData = await boardRepo.like(bbsViewData.boardId.toString(), bbsViewData.crtCustId.toString(), "Y", alramCd: '08');
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
      isLoading.value = true;
      // 병렬로 모든 이미지 삭제 처리
      await Future.wait(bbsViewData.fileList!.map((image) async {
        bool result = await cloudflare.imageDelete(image.fileKey!);
        lo.g('@@@ cloudflare delete image result : $result');
      }));

      ResData resData = await bbsrepo.delete(boardId.toString());
      if (resData.code != '00') {
        Utils.alert(resData.msg.toString());
        isLoading.value = false;
        return;
      }
      Utils.alert('게시글이 삭제되었습니다.');
    } catch (e) {
      Utils.alert('게시글 삭제에 실패했습니다.');
    } finally {
      isLoading.value = false;
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
