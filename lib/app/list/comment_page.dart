import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:comment_sheet/comment_sheet.dart';
import 'package:flutter/material.dart';
import 'package:project1/app/auth/cntr/auth_cntr.dart';
import 'package:project1/app/list/test_grabin_widget.dart';
import 'package:project1/app/list/test_list_item_widget.dart';

import 'package:project1/utils/log_utils.dart';

class CommentPage {
  Future<dynamic> open(
    BuildContext context,
    String boardId,
  ) async {
    showBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return CommentsPage(contextParent: context);
      },
    );
  }
}

class CommentsPage extends StatefulWidget {
  const CommentsPage({super.key, required this.contextParent});
  final BuildContext contextParent;

  @override
  State<CommentsPage> createState() => _CommentsPageState();
}

class _CommentsPageState extends State<CommentsPage> {
  ScrollController scrollController = ScrollController();
  final CommentSheetController commentSheetController = CommentSheetController();

  // 댓글 입력창
  TextEditingController replyController = TextEditingController();
  FocusNode replyFocusNode = FocusNode();

  @override
  void initState() {
    replyController.clear();
    super.initState();
  }

  @override
  void dispose() {
    replyController.dispose();
    scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Lo.g('CommentsPage build');
    return Scaffold(
        backgroundColor: Colors.transparent,
        body: CommentSheet(
          slivers: [
            // 댓글 리스트
            buildSliverList(),
          ],
          grabbingPosition: WidgetPosition.above,
          initTopPosition: 200,
          calculateTopPosition: calculateTopPosition,
          scrollController: scrollController,
          grabbing: Builder(builder: (contextParent) {
            // 댓글 상단바
            return buildGrabbing(context);
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
            BuildContext contextParent,
            CommentSheetInfo info,
          ) {
            // print("On Pointer Up");
          },
          onAnimationComplete: (
            BuildContext contextParent,
            CommentSheetInfo info,
          ) {
            // print("onAnimationComplete");
            if (info.currentTop >= info.size.maxHeight - 130) {
              Navigator.of(context).pop();
            }
          },
          commentSheetController: commentSheetController,
          onTopChanged: (top) {
            // print("top: $top");
          },
          // 백그라운드 위젯
          // child: const Placeholder(),
          child: const SizedBox.expand(),
          backgroundBuilder: (contextParent) {
            return Container(
              color: const Color(0xFF0F0F0F),
              margin: const EdgeInsets.only(top: 10),
            );
          },
        ));
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
  Widget buildGrabbing(BuildContext context) {
    return const GrabbingWidget();
  }

  // 댓글 리스트
  Widget buildSliverList() {
    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        return ListItemWidget(controller: replyController, focus: replyFocusNode);
      }, childCount: 20),
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
          suffixIconConstraints: BoxConstraints(minWidth: 23, maxHeight: 20),
          suffixIcon: Padding(
            padding: EdgeInsets.only(left: 10, right: 10),
            child: Icon(
              Icons.send,
              color: Colors.white,
            ),
          ),
          border: InputBorder.none,
          //border: OutlineInputBorder(),
          contentPadding: EdgeInsets.only(left: 10, bottom: 15, top: 15),
        ),
      ),
    );
  }
}
