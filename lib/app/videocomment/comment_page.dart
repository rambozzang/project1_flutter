import 'dart:async';
import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:comment_sheet/comment_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:project1/app/auth/cntr/auth_cntr.dart';
import 'package:project1/app/videocomment/comment_header_widget.dart';
import 'package:project1/app/videocomment/list_item_widget.dart';
import 'package:project1/repo/board/board_repo.dart';
import 'package:project1/repo/board/data/board_comment_res_data.dart';
import 'package:project1/repo/board/data/board_main_detail_data.dart';
import 'package:project1/repo/board/data/board_comment_data.dart';
import 'package:project1/repo/common/res_data.dart';
import 'package:project1/repo/common/res_stream.dart';
import 'package:project1/root/cntr/root_cntr.dart';

import 'package:project1/utils/log_utils.dart';
import 'package:project1/utils/utils.dart';
import 'package:project1/widget/error_page.dart';
import 'package:project1/widget/no_data_widget.dart';

class CommentPage {
  Future<dynamic> open(
    BuildContext context,
    String boardId,
  ) async {
    // showBottomSheet(
    //   context: context,
    //   backgroundColor: Colors.transparent,
    //   builder: (BuildContext context) {
    //     return CommentsPage2(contextParent: context, boardId: boardId);
    //   },
    // );

    showModalBottomSheet(
      isScrollControlled: true,
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(15.0),
        ),
      ),
      backgroundColor: Colors.black, //.withOpacity(0.8),
      builder: (BuildContext context) {
        return SizedBox(height: MediaQuery.of(context).size.height * 0.65, child: CommentsPage(contextParent: context, boardId: boardId));
      },
    );
  }
}

class CommentsPage extends StatefulWidget {
  const CommentsPage({super.key, required this.contextParent, required this.boardId});
  final BuildContext contextParent;
  final String boardId;

  @override
  State<CommentsPage> createState() => _CommentsPageState();
}

class _CommentsPageState extends State<CommentsPage> {
  ScrollController scrollController = ScrollController();
  final CommentSheetController commentSheetController = CommentSheetController();

  final StreamController<ResStream<List<BoardCommentResData>>> listCtrl = StreamController.broadcast();

  // 댓글 입력창
  TextEditingController replyController = TextEditingController();
  FocusNode replyFocusNode = FocusNode();

  int pageNum = 0;
  int pageSize = 500;
  late List<BoardCommentResData> list = [];

  ValueNotifier<bool> isSend = ValueNotifier<bool>(false);
  bool isFirst = true;

  @override
  void initState() {
    replyController.clear();
    super.initState();
    // 루트페이지 바텀바 숨김
    RootCntr.to.bottomBarStreamController.sink.add(false);
    getData(widget.boardId);
  }

  Future<void> getFakeData() async {
    isFirst = true;
    getData(widget.boardId);
  }

  Future<void> getData(boardId) async {
    try {
      if (isFirst) {
        listCtrl.sink.add(ResStream.loading());
      }
      isFirst = false;
      ResData resListData = await BoardRepo().searchComment(boardId, pageNum, pageSize);
      if (resListData.code != '00') {
        Utils.alert(resListData.msg.toString());
        return;
      }
      list = ((resListData.data) as List).map((data) => BoardCommentResData.fromMap(data)).toList();
      //listCtrl.sink.add(ResStream.completed([]));
      listCtrl.sink.add(ResStream.completed(list));
    } catch (e) {
      Lo.g('getDate() error : $e');
      listCtrl.sink.add(ResStream.error(e.toString()));
    }
  }

  Future<void> saveComment() async {
    try {
      if (replyController.text == "") return;

      isSend.value = true;

      BoardRepo repo = BoardRepo();
      BoardCommentData replyData = BoardCommentData();
      replyData.custId = AuthCntr.to.resLoginData.value.custId.toString();
      replyData.parentId = int.parse(widget.boardId);
      replyData.contents = replyController.text;
      replyData.depthNo = 1;
      replyData.sortNo = 1;
      replyData.typeCd = 'V';
      replyData.typeDtCd = 'V';

      await repo.saveComment(replyData).then((value) async {
        if (value.code == '00') {
          Utils.alert("댓글이 등록되었습니다.");

          // 키보드만 내리기
          SystemChannels.textInput.invokeMethod('TextInput.hide');

          replyController.clear();
          await getData(widget.boardId);

          scrollController.jumpTo(scrollController.position.maxScrollExtent);
        } else {
          Utils.alert(value.msg.toString());
        }
      });
      isSend.value = false;
    } catch (e) {
      Lo.g('saveReply() error : $e');
      Utils.alert("다시 시도해주세요.");

      isSend.value = false;
    }
  }

  void onClose(bool didPop) {
    if (didPop) {
      Lo.g('PopScope 2 didPop');
      return;
    } else {
      Lo.g('PopScope 3 not didPop');
      return;
    }
  }

  @override
  void dispose() {
    replyController.dispose();
    scrollController.dispose();
    RootCntr.to.bottomBarStreamController.sink.add(true);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Lo.g('CommentsPage2 build');
    return Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Column(
          children: [
            StreamBuilder<ResStream<List<BoardCommentResData>>>(
                stream: listCtrl.stream,
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    if (snapshot.data?.status == Status.COMPLETED) {
                      var list = snapshot.data!.data;
                      return CommentHeaderWidget(listLength: list!.length, getData: () => getFakeData());
                    }
                  }
                  return CommentHeaderWidget(listLength: 0, getData: () => getFakeData());
                }),
            Expanded(
              child: SingleChildScrollView(
                controller: scrollController,
                child: StreamBuilder<ResStream<List<BoardCommentResData>>>(
                  stream: listCtrl.stream,
                  builder: (BuildContext context, AsyncSnapshot<ResStream<List<BoardCommentResData>>> snapshot) {
                    if (snapshot.hasData) {
                      switch (snapshot.data?.status) {
                        case Status.LOADING:
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.all(68.0),
                              child: Utils.progressbar(),
                            ),
                          );
                        case Status.COMPLETED:
                          List list = snapshot.data!.data as List<BoardCommentResData>;
                          return ListView.builder(
                            shrinkWrap: true,
                            // physics: const AlwaysScrollableScrollPhysics(),
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: list.length == 0 ? 1 : list.length,
                            itemBuilder: (BuildContext context, int index) {
                              return list.isEmpty
                                  ? const Center(
                                      child: Padding(
                                        padding: EdgeInsets.all(68.0),
                                        child: Text(
                                          '댓글이 없습니다.',
                                          style: TextStyle(color: Colors.white, fontSize: 13),
                                        ),
                                      ),
                                    )
                                  : ListItemWidget(
                                      focus: replyFocusNode,
                                      boardCommentData: list[index],
                                      controller: replyController,
                                    );
                            },
                          );
                        case Status.ERROR:
                          return ErrorPage(
                            errorMessage: snapshot.data!.message ?? '',
                            onRetryPressed: () => getData(widget.boardId),
                          );
                        case null:
                          return const SizedBox(
                            width: 200,
                            height: 300,
                            child: Text("조회 중 오류가 발생했습니다."),
                          );
                      }
                    }
                    return Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Utils.progressbar(),
                    );
                  },
                ),
              ),
            ),
            buildBottomWidget(),
          ],
        ));
  }

  // 댓글 입력창
  Widget buildBottomWidget() {
    return Container(
      color: Colors.grey[900],
      height: 64,
      padding: const EdgeInsets.only(left: 5, right: 5),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: Container(
              width: 40.0,
              height: 40.0,
              decoration: BoxDecoration(
                color: const Color(0xff7c94b6),
                image: DecorationImage(
                  image: CachedNetworkImageProvider(AuthCntr.to.resLoginData.value.profilePath!),
                  fit: BoxFit.cover,
                ),
                borderRadius: const BorderRadius.all(Radius.circular(30.0)),
                border: Border.all(
                  color: Colors.green,
                  width: 0.4,
                ),
              ),
            ),
            // child: Icon(
            //   Icons.emoji_emotions_outlined,
            //   color: Colors.white,
            // ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                vertical: 8,
              ),
              child: TextField(
                keyboardType: TextInputType.text,
                controller: replyController,
                focusNode: replyFocusNode,
                // cursorHeight: 5,
                textAlignVertical: TextAlignVertical.center,
                style: const TextStyle(color: Colors.white, decorationThickness: 0),
                onSubmitted: (value) => saveComment(),
                decoration: const InputDecoration(
                  hintText: '댓글 좀...',
                  hintStyle: TextStyle(color: Colors.white),

                  prefixIconConstraints: BoxConstraints(minWidth: 27, maxHeight: 27),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey, width: 0.4),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white, width: 1.0),
                  ),

                  // suffixIconConstraints: const BoxConstraints(minWidth: 23, maxHeight: 20),
                  // suffixIcon: Padding(
                  //   padding: const EdgeInsets.only(left: 10, right: 10),
                  //   child: IconButton(
                  //     onPressed: () => saveComment(),
                  //     icon: const Icon(Icons.send),
                  //     color: Colors.white,
                  //   ),
                  // ),
                  border: InputBorder.none,
                  //border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.only(left: 10, bottom: 5, top: 15),
                ),
              ),
            ),
          ),
          ElevatedButton(
            clipBehavior: Clip.none,
            style: ElevatedButton.styleFrom(
              //  shadowColor: Colors.transparent,
              // fixedSize: Size(0, 0),
              minimumSize: Size.zero, // Set this
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: const VisualDensity(horizontal: 0, vertical: 0),
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(5),
              ),
              backgroundColor: Colors.transparent,
            ),
            onPressed: () => saveComment(),
            child: ValueListenableBuilder<bool>(
                valueListenable: isSend,
                builder: (context, value, snapshot) {
                  return Transform.scale(
                    scale: value ? 0.8 : 1.0,
                    child: Opacity(
                      opacity: value ? 0.5 : 1.0,
                      child: !value
                          ? const Icon(
                              Icons.send,
                              color: Colors.white,
                            )
                          : LoadingAnimationWidget.fourRotatingDots(
                              color: Colors.pink,
                              size: 30,
                            ),
                      // : const Icon(
                      //     Icons.close,
                      //     color: Colors.grey,
                      //   ),
                    ),
                  );
                }),
          ),
        ],
      ),
    );
  }
}
