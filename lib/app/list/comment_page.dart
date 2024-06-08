import 'dart:async';
import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:comment_sheet/comment_sheet.dart';
import 'package:flutter/material.dart';
import 'package:project1/app/auth/cntr/auth_cntr.dart';
import 'package:project1/app/list/test_grabin_widget.dart';
import 'package:project1/app/list/test_list_item_widget.dart';
import 'package:project1/repo/board/board_repo.dart';
import 'package:project1/repo/board/data/board_main_detail_data.dart';
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
    showBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return CommentsPage(contextParent: context, boardId: boardId);
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

  final StreamController<ResStream<List<BoardDetailData>>> listCtrl = StreamController.broadcast();

  // 댓글 입력창
  TextEditingController replyController = TextEditingController();
  FocusNode replyFocusNode = FocusNode();

  int pageNum = 0;
  int pageSize = 500;
  late List<BoardDetailData> list = [];

  @override
  void initState() {
    replyController.clear();
    super.initState();
    // 루트페이지 바텀바 숨김
    RootCntr.to.bottomBarStreamController.sink.add(false);
    getData(widget.boardId);
  }

  Future<void> getFakeData() => getData(widget.boardId);
  Future<void> getData(boardId) async {
    try {
      listCtrl.sink.add(ResStream.loading());
      ResData resListData = await BoardRepo().searchComment('1', pageNum, pageSize);
      if (resListData.code != '00') {
        Utils.alert(resListData.msg.toString());
        return;
      }
      list = ((resListData.data['boardInfoList']) as List).map((data) => BoardDetailData.fromMap(data)).toList();
      //listCtrl.sink.add(ResStream.completed([]));
      listCtrl.sink.add(ResStream.completed(list));
    } catch (e) {
      Lo.g('getDate() error : $e');
      listCtrl.sink.add(ResStream.error(e.toString()));
    }
  }

  void onClose(bool didPop) {
    if (didPop) {
      Lo.g('PopScope 2 didPop');

      // Navigator.pop(context);
    } else {
      Lo.g('PopScope 3 not didPop');
      return;
    }
    //Navigator.pop(widget.contextParent);

    // Navigator.of(context).pop(false);
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
    Lo.g('CommentsPage build');
    return PopScope(
      canPop: false,
      onPopInvoked: (bool didPop) async => onClose(didPop),
      child: Scaffold(
          backgroundColor: Colors.transparent,
          body: CommentSheet(
            slivers: [
              // 댓글 리스트
              //  buildSliverList(),
              StreamBuilder<ResStream<List<BoardDetailData>>>(
                stream: listCtrl.stream,
                builder: (BuildContext context, AsyncSnapshot<ResStream<List<BoardDetailData>>> snapshot) {
                  if (snapshot.hasData) {
                    switch (snapshot.data?.status) {
                      case Status.LOADING:
                        return SliverList(
                            delegate: SliverChildBuilderDelegate(childCount: 0, (BuildContext context, int index) {
                          return Center(
                              child: Padding(
                            padding: const EdgeInsets.all(68.0),
                            child: Utils.progressbar(),
                          ));
                        }));
                      case Status.COMPLETED:
                        var list = snapshot.data!.data;
                        return SliverList(
                            delegate: SliverChildBuilderDelegate(childCount: list!.length, (BuildContext context, int index) {
                          return list!.isEmpty
                              ? const NoDataWidget()
                              : ListItemWidget(
                                  controller: replyController,
                                  focus: replyFocusNode,
                                  boardDetailData: list[index],
                                );
                        }));
                      case Status.ERROR:
                        return SliverList(
                            delegate: SliverChildBuilderDelegate(childCount: 0, (BuildContext context, int index) {
                          return ErrorPage(
                            errorMessage: snapshot.data!.message ?? '',
                            onRetryPressed: () => getData(widget.boardId),
                          );
                        }));
                      case null:
                        return SliverList(
                            delegate: SliverChildBuilderDelegate(childCount: 0, (BuildContext context, int index) {
                          return const SizedBox(
                            width: 200,
                            height: 300,
                            child: Text("조회 중 오류가 발생했습니다."),
                          );
                        }));
                    }
                  }
                  return SliverList(
                      delegate: SliverChildBuilderDelegate(childCount: 0, (BuildContext context, int index) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(48.0),
                        child: Text("조회 된 데이터가 없습니다."),
                      ),
                    );
                  }));
                },
              )
              // Utils.commonStreamList<BoardDetailData>(listCtrl, buildSliverList, getFakeData)
            ],
            grabbingPosition: WidgetPosition.above,
            initTopPosition: 200,
            calculateTopPosition: calculateTopPosition,
            scrollController: scrollController,
            grabbing: Builder(builder: (context) {
              // 댓글 상단바
              return StreamBuilder<ResStream<List<BoardDetailData>>>(
                  stream: listCtrl.stream,
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      if (snapshot.data?.status == Status.COMPLETED) {
                        var list = snapshot.data!.data;
                        return buildGrabbing(context, list!.length);
                      }
                    }
                    return buildGrabbing(context, 0);
                  });
            }),

            topWidget: (info) {
              // 실제 줄어드는 위젯 위치
              // return Container(
              //   color: Colors.transparent,
              // );122
              return Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: 0,
                  // height: max(0, info.currentTop),
                  child: Container(
                    color: Colors.transparent,
                  ));
            },
            topPosition: WidgetPosition.below,
            bottomWidget: buildBottomWidget(),
            onPointerUp: (
              BuildContext context,
              CommentSheetInfo info,
            ) {
              // print("On Pointer Up");
            },
            onAnimationComplete: (
              BuildContext context,
              CommentSheetInfo info,
            ) {
              // print("onAnimationComplete");
              if (info.currentTop >= info.size.maxHeight - 130) {
                Navigator.of(context).pop();
                return;
              }
            },
            commentSheetController: commentSheetController,
            onTopChanged: (top) {
              // print("top: $top");
            },
            // 백그라운드 위젯
            // child: const Placeholder(),
            child: const SizedBox.expand(),
            backgroundBuilder: (context) {
              return Container(
                color: const Color(0xFF0F0F0F),
                margin: const EdgeInsets.only(top: 10),
              );
            },
          )),
    );
  }

  double calculateTopPosition(CommentSheetInfo info) {
    final vy = info.velocity.getVelocity().pixelsPerSecond.dy;
    final top = info.currentTop;
    double p0 = 0;
    double p1 = 200;
    double p2 = info.size.maxHeight - 130;

    if (top > p1) {
      if (vy > 0) {
        if (info.isAnimating && info.animatingTarget == p1 && top < p1 + 10) {
          return p1;
        } else {
          return p2;
        }
      } else {
        return p1;
      }
    } else if (top == p1) {
      return p1;
    } else if (top == p0) {
      return p0;
    } else {
      if (vy > 0) {
        if (info.isAnimating && info.animatingTarget == p0 && top < p0 + 10) {
          return p0;
        } else {
          return p1;
        }
      } else {
        return p0;
      }
    }
  }

  // 댓글 상단바
  Widget buildGrabbing(BuildContext context, int listLength) {
    return GrabbingWidget(listLength: listLength);
  }

  // 댓글 리스트
  Widget buildSliverList(List<BoardDetailData> list) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        childCount: list.length,
        (BuildContext context, int index) {
          return ListItemWidget(
            controller: replyController,
            focus: replyFocusNode,
            boardDetailData: list[index],
          );
        },
      ),
    );
  }

  // 댓글 입력창
  Widget buildBottomWidget() {
    return Container(
      color: Colors.transparent,
      height: 63,
      padding: const EdgeInsets.only(left: 5, right: 5),
      child: TextFormField(
        keyboardType: TextInputType.text,
        controller: replyController,
        focusNode: replyFocusNode,
        style: const TextStyle(color: Colors.white, decorationThickness: 0),
        decoration: InputDecoration(
          hintText: '댓글을 입력해주세요',
          hintStyle: const TextStyle(color: Colors.white),
          isDense: true,
          prefixIconConstraints: const BoxConstraints(minWidth: 25, maxHeight: 25),
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 5, right: 5),
            child: Container(
              width: 23.0,
              height: 23.0,
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
          suffixIconConstraints: const BoxConstraints(minWidth: 23, maxHeight: 20),
          suffixIcon: const Padding(
            padding: EdgeInsets.only(left: 10, right: 10),
            child: Icon(
              Icons.send,
              color: Colors.white,
            ),
          ),
          border: InputBorder.none,
          //border: OutlineInputBorder(),
          contentPadding: const EdgeInsets.only(left: 10, bottom: 15, top: 15),
        ),
      ),
    );
  }
}
