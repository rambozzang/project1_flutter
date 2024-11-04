import 'dart:async';
import 'dart:io';

import 'package:cloudflare/cloudflare.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:korean_profanity_filter/korean_profanity_filter.dart';
import 'package:project1/app/auth/cntr/auth_cntr.dart';
import 'package:project1/app/bbs/cntr/bbs_write_cntr.dart';
import 'package:project1/repo/bbs/bbs_repo.dart';
import 'package:project1/repo/bbs/comment_repo.dart';
import 'package:project1/repo/bbs/data/bbs_file_data_res.dart';
import 'package:project1/repo/bbs/data/bbs_file_req_data.dart';
import 'package:project1/repo/bbs/data/bbs_list_data.dart';
import 'package:project1/repo/bbs/data/bbs_list_res_data.dart';
import 'package:project1/repo/bbs/data/bbs_search_req_data.dart';
import 'package:project1/repo/board/board_repo.dart';
import 'package:project1/repo/board/data/board_comment_data.dart';
import 'package:project1/repo/board/data/board_comment_res_data.dart';
import 'package:project1/repo/board/data/board_comment_update_req_data.dart';
import 'package:project1/repo/cloudflare/cloudflare_repo.dart';
import 'package:project1/repo/common/res_data.dart';
import 'package:project1/repo/common/res_stream.dart';
import 'package:project1/utils/StringUtils.dart';
import 'package:project1/utils/log_utils.dart';
import 'package:project1/utils/utils.dart';
import 'package:rxdart/subjects.dart';
// import 'package:rxdart/rxdart.dart';

// class BbsCommentsBinding extends Bindings {
//   @override
//   void dependencies() {
//     Get.lazyPut<BbsCommentsController>(() => BbsCommentsController());
//   }
// }

class BbsCommentsController extends GetxController {
  // 댓글 관련 변수명 변경
  CloudflareRepo cloudflare = CloudflareRepo();

  // 코멘트 리스트 스크롤
  final ScrollController replayListScrollController = ScrollController();

  // 코멘트 데이터
  final StreamController<ResStream<List<BbsListData>>> replyStreamController = BehaviorSubject();
  // 코멘트 텍스트
  final TextEditingController replyTextController = TextEditingController();
  final FocusNode replyFocusNode = FocusNode();
  // 텍스 입력창 스크롤
  final ScrollController replyTextFeildScrollController = ScrollController();

  late List<BbsListData> commentsList = [];
  RxBool isSending = false.obs;
  RxBool isFirstLoad = false.obs;

  RxInt visibleLines = 1.obs;
  RxBool isCommentActive = false.obs;
  RxBool isCommentsHidden = true.obs;
  Rx<XFile?> commentImage = Rx<XFile?>(null);

  RxBool isModifyMode = false.obs;
  RxBool isDeleting = false.obs;
  // 댓글 수정시 이미지를 변경했는 여부
  RxBool isChangeImage = false.obs;

  final int replayTextMaxline = 3;

  int currentPage = 1;
  final int pageSize = 30;
  RxInt toalCount = 0.obs;
  Timer? debounceTimer; // 타이머 변수
  bool isLoading = false;
  bool isLastPage = false;

  bool isRootDeleted = false;

  // 원글 id
  late String rootId;
  // 댓글 부모 id
  late String parentId;

  late BbsListData bbsListData;
  // 수정버튼 클릭시 데이터 셋팅
  String modifyBoardId = "";

  BbsListData replayParentData = BbsListData();

  CommentRepo commentRepo = CommentRepo();

  @override
  void onInit() {
    super.onInit();
    init();
    replyTextController.clear();
    replyTextController.addListener(onTextChanged);
  }

  Future<void> init() async {
    await cloudflare.init();
  }

  void setParentId(String id) {
    parentId = id;
  }

  void setInitData(BbsListData _bbsListData) {
    bbsListData = _bbsListData;
    rootId = _bbsListData.boardId.toString();
    parentId = _bbsListData.boardId.toString();
    isRootDeleted = _bbsListData.delYn == 'Y';
    fetchComments();
  }

  void setSCrollController(ScrollController main) {
    main.addListener(() => handlereplayListScroll(main));
  }

  void setCommentActive(val) {
    isCommentActive.value = val;
    lo.g('3 1: $val');
  }

  // 코멘트 리스트 감지
  // 스크롤에 따라 bottom bar hide
  void handlereplayListScroll(ScrollController scrollData) {
    if (isModifyMode.value) return;
    if (replyTextController.text.isNotEmpty) return;
    if (scrollData.position.userScrollDirection == ScrollDirection.reverse) {
      isCommentsHidden.value = true;
    } else if (scrollData.position.userScrollDirection == ScrollDirection.forward) {
      isCommentsHidden.value = false;
    }

    // 너무 잡은 호출을 방지하기 위해 디바운스 사용
    debounceTimer = Timer(const Duration(milliseconds: 350), () {
      if (scrollData == null) return;

      if (scrollData.position.pixels >= scrollData.position.maxScrollExtent * 0.75) {
        if (!isLastPage && isLoading == false) {
          isLoading = true;
          currentPage++;
          lo.g('commentsList  :  currentPage : $currentPage');
          getReplyData();
        }
      }
    });
  }

  void onTextChanged() {
    final newLines = '\n'.allMatches(replyTextController.text).length + 1;
    visibleLines.value = newLines.clamp(1, replayTextMaxline).toInt();
    // 자동 스크롤
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (replyTextFeildScrollController.hasClients) {
        replyTextFeildScrollController.animateTo(
          replyTextFeildScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void removeCommentImage() {
    commentImage.value = null;
  }

  // 댓글 리스트에서 각글마다 댓글 아이콘 클릭시 댓글 부모 데이터를 넘김.
  void replayCommentsClick(BbsListData? modifyData) {
    try {
      if (isRootDeleted) {
        Utils.alertIcon('삭제된 게시글입니다..', icontype: 'E');
        return;
      }
      lo.g('modifyData : ${modifyData?.contents}');
      SystemChannels.textInput.invokeMethod('TextInput.show');
      replyFocusNode.requestFocus();

      isCommentsHidden.value = false;
      replyTextController.clear();

      modifyBoardId = "";
      isModifyMode.value = false;

      // 일반 댓글인 경우 부모 댓글이 없어요. 따라서 null 처리
      if (modifyData == null) {
        replayParentData = BbsListData();
        replyTextController.clear();
        parentId = rootId;
      } else {
        replayParentData = modifyData;
        parentId = modifyData!.boardId.toString();
        replyTextController.text = '@${modifyData.nickNm.toString()} ';
      }
    } catch (e) {
      lo.g('replayCommentsClick() error : $e');
    }
  }

  void modifySetting(BbsListData modifyData) async {
    modifyBoardId = modifyData.boardId.toString();

    isCommentsHidden.value = false;
    isCommentActive.value = true;
    replyFocusNode.requestFocus();

    SystemChannels.textInput.invokeMethod('TextInput.show');

    replyTextController.text = modifyData.contents.toString();
    if (modifyData.fileList!.isNotEmpty) {
      commentImage.value = XFile(modifyData.fileList!.first.filePath.toString());
    }
    isModifyMode.value = true;
    replayParentData = BbsListData();
  }

/*
update => 
delte 

*/
  void cancleModifySetting() {
    isSending.value = false;
    modifyBoardId = '';
    isCommentsHidden.value = false;
    isCommentActive.value = false;
    replyFocusNode.unfocus();
    SystemChannels.textInput.invokeMethod('TextInput.hide');
    commentImage.value = null;
    isModifyMode.value = false;
    isDeleting.value = false;
    isChangeImage.value = false;
    replayParentData = BbsListData();
    replyTextController.clear();
    parentId = rootId;
    isLoading = false;
  }

  Future<void> updataComment() async {
    if (replyTextController.text == "" || modifyBoardId == "") {
      Utils.alert("댓글 내용이 넘어오질 않았습니다.");
      return;
    }
    try {
      isSending.value = true;
      String contentsText = replyTextController.text;
      contentsText = contentsText.replaceBadWords('🤬');

      BoardRepo repo = BoardRepo();
      BoardCommentUpdateReqData replyData = BoardCommentUpdateReqData();
      replyData.boardId = modifyBoardId.toString();
      replyData.contents = contentsText;
      replyData.delYn = 'N';
      replyData.hideYn = 'N';
      replyData.fileListData = [];

      lo.g('updataComment() 1');

      // 이미지 처리 로직
      BbsListData originalComment = commentsList.firstWhere((comment) => comment.boardId.toString() == modifyBoardId.toString());

      bool hasOriginalImage = originalComment.fileList != null && originalComment.fileList!.isNotEmpty;
      bool hasImage = commentImage.value != null;
      bool hasNewImage = commentImage.value != null && isChangeImage.value;
      lo.g('updataComment() 2 hasOriginalImage:$hasOriginalImage , hasImage:$hasImage , hasNewImage:$hasNewImage');

      // 원본 파일
      if (hasOriginalImage && hasImage && !hasNewImage) {
        // 1.원본있고 - 그대로  hasOriginalImage && !hasNewImage
        BbsFileDataRes originFile = originalComment.fileList!.first;
        replyData.fileListData = [
          BbsFileData(fileKey: originFile.fileKey!, fileNm: originFile.fileNm!, filePath: originFile.filePath!, fileType: 'image')
        ];
      } else if (hasOriginalImage && hasImage && hasNewImage) {
        // 2.원본있고 - 수정    hasOriginalImage && hasNewImage
        await cloudflare.imageDelete(originalComment.fileList!.first.fileKey.toString());
        ImageData? newImageData = await uploadImage(commentImage.value!);
        replyData.fileListData = [
          BbsFileData(fileKey: newImageData!.imageKey, fileNm: newImageData.fileName, filePath: newImageData.imageUrl, fileType: 'image')
        ];
      } else if (hasOriginalImage && !hasImage) {
        //  3.원본있고 - 삭제    hasOriginalImage && !hasImage
        await cloudflare.imageDelete(originalComment.fileList!.first.fileKey.toString());
        replyData.fileListData = [];
      } else if (!hasOriginalImage && hasImage) {
        // 4.원본없고 - 추가    !hasOriginalImage && hasImage
        ImageData? newImageData = await uploadImage(commentImage.value!);
        replyData.fileListData = [
          BbsFileData(fileKey: newImageData!.imageKey, fileNm: newImageData.fileName, filePath: newImageData.imageUrl, fileType: 'image')
        ];
      } else {
        // 5. 원본에 이미지가 없고 추가하지 않은 경우
        replyData.fileListData = [];
      }

      lo.g('updataComment() 3');
      await commentRepo.update(replyData).then((value) async {
        lo.g('updataComment() ${value.toString()}');
        if (value.code == '00') {
          SystemChannels.textInput.invokeMethod('TextInput.hide');
          replyTextController.clear();
        } else {
          Utils.alert(value.msg.toString());
        }
      });
      lo.g('updataComment() 4');
    } catch (e) {
      lo.g("updataComment() e : ${e.toString()}");
      Utils.alert("댓글 수정중 오류가 발생했습니다.");
    } finally {
      cancleModifySetting();
      fetchComments();
      // replayListScrollController.jumpTo(replayListScrollController.position.maxScrollExtent);
    }
  }

  // 삭제
  Future<void> deleteComment(BbsListData modifyData) async {
    try {
      if (modifyData.boardId == null) {
        Utils.alert("댓글 id가 넘어오질 않았습니다.");
        return;
      }
      isDeleting.value = true;
      // 파일 서버 삭제
      if (modifyData.fileList!.isNotEmpty) {
        String fileKey = modifyData.fileList!.first.fileKey.toString();
        if (!StringUtils.isEmpty(fileKey)) {
          bool isComplete = await cloudflare.imageDelete(fileKey);
          lo.g('Cloudflare 파일 삭제 : $isComplete');
          if (isComplete) {}
        }
      }

      // DB 삭제
      await commentRepo.deleteComment(modifyData.boardId.toString());
    } catch (e) {
    } finally {
      cancleModifySetting();
      fetchComments();
      // replayListScrollController.jumpTo(replayListScrollController.position.maxScrollExtent);
    }
  }

  Future<void> saveComment() async {
    try {
      if (replyTextController.text == "") return;

      if (isModifyMode.value) {
        updataComment();
        return;
      }

      isSending.value = true;
      int depthNo = 0;
      int sortNo = 0;
      if (!replayParentData.isNullOrEmpty()) {
        depthNo = int.parse(replayParentData.depthNo.toString());
        sortNo = int.parse(replayParentData.sortNo.toString());
        parentId = replayParentData.boardId.toString();
      }

      String contentsText = replyTextController.text;
      contentsText = contentsText.replaceBadWords('🤬');

      BoardRepo repo = BoardRepo();
      BoardCommentData replyData = BoardCommentData();
      replyData.custId = AuthCntr.to.resLoginData.value.custId.toString();
      replyData.contents = contentsText;

      replyData.rootId = int.parse(rootId);
      replyData.parentId = int.parse(parentId);

      replyData.depthNo = depthNo; // 백에서 다시 계산
      replyData.sortNo = sortNo; // 백에서 다시 계산

      replyData.typeCd = bbsListData.typeCd.toString();
      replyData.typeDtCd = bbsListData.typeDtCd.toString();
      replyData.fileListData = [];

      // 이미지 업로드
      if (commentImage.value != null) {
        ImageData? imageData = await uploadImage(commentImage.value!);
        List<BbsFileData>? list = [];
        BbsFileData bbsFileData =
            BbsFileData(fileKey: imageData!.imageKey, fileNm: imageData.fileName, filePath: imageData.imageUrl, fileType: 'image');
        list.add(bbsFileData);
        replyData.fileListData = list;
      }

      await commentRepo.saveComment(replyData).then((value) async {
        if (value.code == '00') {
          // Utils.alert("댓글이 등록되었습니다.");

          // 키보드만 내리기
          SystemChannels.textInput.invokeMethod('TextInput.hide');

          replyTextController.clear();
        } else {
          Utils.alert(value.msg.toString());
        }
      });
    } catch (e) {
      Lo.g('saveReply() error : $e');
      Utils.alert("다시 시도해주세요.");
    } finally {
      cancleModifySetting();
      fetchComments();
      replayListScrollController.jumpTo(replayListScrollController.position.maxScrollExtent);
    }
  }

  // 이미지 업로드
  // 이미지 서버에 저장
  Future<ImageData?> uploadImage(XFile image) async {
    File uploadFile = File(image.path);
    // heic, heif 파일은 jpg로 변환 후 업로드 - cloudflare에서 지원하지 않음
    // if (image.name.endsWith('.heic') || image.name.endsWith('.heif')) {
    //   Utils.alert('heic, heif 파일은 업로드 할 수 없습니다.');
    //   return null;
    // }
    CloudflareHTTPResponse<CloudflareImage?>? resthumbnail = await cloudflare.imageFileUpload(uploadFile);
    if (resthumbnail?.isSuccessful == false) {
      Utils.alert('이미지 업로드에 실패했습니다.');
      return null;
    }
    Lo.g('file 업로드 : ${resthumbnail?.body.toString()}');
    return ImageData(
      imageKey: resthumbnail!.body!.id,
      fileName: image.name,
      imageUrl: resthumbnail.body!.variants[0].toString(),
    );
  }

  Future<void> pickImage() async {
    final XFile? pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    lo.g("pickedFile : ${pickedFile!.mimeType}");
    lo.g("pickedFile : ${pickedFile.name}");
    lo.g("pickedFile : ${pickedFile}");

    if (pickedFile != null) {
      final fileSize = await pickedFile.length();
      if (fileSize > 10 * 1024 * 1024) {
        Utils.alert('이미지 크기가 10MB를 초과 할 수 없습니다.');
        return;
      }

      // 수정모드에서 이미지를 픽업하면 수정된 이미지로 간주
      isChangeImage.value = isModifyMode.value ? true : false;

      commentImage.value = pickedFile!;
    }
  }

  Future<void> fetchComments() async {
    // isFirstLoad.value = true;
    currentPage = 1;
    commentsList = [];
    getReplyData();
  }

  Future<void> getReplyData() async {
    try {
      // if (isFirstLoad.value) {
      replyStreamController.sink.add(ResStream.loading());
      // }
      isFirstLoad.value = false;

      BbsSearchData bbsSearchData = BbsSearchData(
          pageNum: currentPage,
          pageSize: pageSize,
          typeCd: bbsListData.typeCd.toString(),
          typeDtCd: bbsListData.typeDtCd.toString(),
          depthNo: '',
          searchWord: '',
          searchCustId: '',
          parentId: '',
          rootId: rootId,
          sortDesc: 'ASC');

      ResData resData = await commentRepo.commentlist(bbsSearchData);

      // ResData resListData = await BoardRepo().searchComment(boardId, currentPage, pageSize);
      if (resData.code != '00') {
        Utils.alert(resData.msg.toString());
        return;
      }

      if (resData.data.length == 0) {
        replyStreamController.sink.add(ResStream.completed([]));
        return;
      }
      BbsListResData result = BbsListResData.fromMap(resData.data);

      isLastPage = result.pageData.last;
      toalCount.value = result.pageData.totalElements;

      List<BbsListData> newlist = result.bbsList;
      commentsList.addAll(newlist);

      replyStreamController.sink.add(ResStream.completed(commentsList));
    } catch (e) {
      Lo.g('getDate() error : $e');
      replyStreamController.sink.add(ResStream.error(e.toString()));
    } finally {
      isLoading = false;
    }
  }
}
