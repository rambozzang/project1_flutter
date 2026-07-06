import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:get/get.dart';
import 'package:project1/app/auth/cntr/auth_cntr.dart';
import 'package:project1/repo/board/board_repo.dart';
import 'package:project1/repo/board/data/board_comment_res_data.dart';
import 'package:project1/repo/common/res_data.dart';
import 'package:project1/utils/utils.dart';

class CommentItemWidget extends StatefulWidget {
  const CommentItemWidget({
    super.key,
    this.focus,
    required this.boardCommentData,
    required this.controller,
    required this.isDarkTheme,
    this.onReply,
  });
  final FocusNode? focus;
  final BoardCommentResData boardCommentData;
  final TextEditingController? controller;
  final bool isDarkTheme;
  // 답글(대댓글) 작성 시작 — 부모 댓글을 넘겨준다.
  final void Function(BoardCommentResData parent)? onReply;

  @override
  State<CommentItemWidget> createState() => _CommentItemWidgetState();
}

class _CommentItemWidgetState extends State<CommentItemWidget> {
  ValueNotifier<int> likeCnt = ValueNotifier<int>(0);
  ValueNotifier<String> likeYn = ValueNotifier<String>('N');

  @override
  void initState() {
    super.initState();
    likeCnt.value = widget.boardCommentData.likeCnt!;
    likeYn.value = widget.boardCommentData.likeYn.toString();
  }

  Future<void> like() async {
    try {
      BoardRepo boardRepo = BoardRepo();
      ResData resData =
          await boardRepo.like(widget.boardCommentData.boardId.toString(), AuthCntr.to.resLoginData.value.custId.toString(), "N");
      if (resData.code != '00') {
        Utils.alert(resData.msg.toString());
        return;
      }
      // Utils.alert('좋아요! 저장되었습니다.');
      likeCnt.value = likeCnt.value + 1;
      likeYn.value = 'Y';
      widget.boardCommentData.likeYn = 'Y';
    } catch (e) {
      // Utils.alert('좋아요 실패! 다시 시도해주세요');
    }
  }

  Future<void> likeCancle() async {
    try {
      BoardRepo boardRepo = BoardRepo();
      ResData resData = await boardRepo.likeCancle(widget.boardCommentData.boardId.toString());
      if (resData.code != '00') {
        Utils.alert(resData.msg.toString());
        return;
      }
      // Utils.alert('좋아요! 취소 되었습니다.');
      likeCnt.value = likeCnt.value - 1;
      likeYn.value = 'N';
      widget.boardCommentData.likeYn = 'N';
    } catch (e) {
      // Utils.alert('좋아요 취소 실패! 다시 시도해주세요');
    }
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Color backgroundColor = widget.isDarkTheme ? Colors.black : Colors.white;
    Color textColorMain = widget.isDarkTheme ? Colors.white : Colors.black;
    Color textColorSub = widget.isDarkTheme ? Colors.white54 : Colors.black87;
    Color iconColor = widget.isDarkTheme ? Colors.white54 : Colors.black87;

    // depthNo >= 2 면 대댓글 — 스카이라운지(bbs_comment_item_widget)와 동일하게
    // ㄴ자 화살표 + 들여쓰기로 원댓글과 계층 구분.
    final bool isReply = (widget.boardCommentData.depthNo ?? 1) >= 2;

    return Material(
      color: backgroundColor,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.only(
          top: 6,
          bottom: 0,
          left: isReply ? 20 : 10,
          right: 10,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isReply)
              const SizedBox(
                width: 25,
                height: 20,
                child: Icon(Icons.subdirectory_arrow_right_outlined, color: Colors.grey, size: 14),
              ),
            Padding(
              padding: const EdgeInsets.only(left: 5, right: 10),
              child: GestureDetector(
                onTap: () => Get.toNamed('/OtherInfoPage/${widget.boardCommentData.custId}'),
                child: ClipOval(
                  child: CachedNetworkImage(
                    imageUrl: widget.boardCommentData.profilePath.toString(),
                    width: 28,
                    height: 28,
                  ),
                ),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        widget.boardCommentData.nickNm.toString(),
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: textColorSub),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 7.0),
                        child: Text(
                          '·',
                          style: TextStyle(color: textColorSub, fontSize: 16),
                        ),
                      ),
                      Text(
                        Utils.timeage(widget.boardCommentData.crtDtm!),
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: textColorSub),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 2, bottom: 4),
                    child: Text(
                      widget.boardCommentData.contents.toString(),
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: textColorMain),
                    ),
                  ),
                  Row(
                    children: [
                      SizedBox(
                        height: 15,
                        width: 23,
                        child: ValueListenableBuilder<String>(
                            valueListenable: likeYn,
                            builder: (contex, value, child) {
                              return IconButton(
                                padding: EdgeInsets.zero,
                                iconSize: 14,
                                icon: value == 'Y'
                                    ? Icon(Icons.thumb_up, color: textColorSub)
                                    : Icon(Icons.thumb_up_outlined, color: iconColor),
                                onPressed: () => value == 'Y' ? likeCancle() : like(),
                              );
                            }),
                      ),
                      const Gap(2),
                      ValueListenableBuilder<int>(
                          valueListenable: likeCnt,
                          builder: (contex, value, child) {
                            return Text(
                              value.toString(),
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: textColorSub),
                            );
                          }),
                      // const Padding(
                      //   padding: EdgeInsets.only(left: 16.0, right: 16.0),
                      //   child: Icon(
                      //     Icons.thumb_down_alt_outlined,
                      //     size: 15,
                      //     color: Colors.white,
                      //   ),
                      // ),
                      const Gap(12),
                      SizedBox(
                        height: 15,
                        width: 22,
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          iconSize: 14,
                          icon: Icon(Icons.comment_outlined, color: iconColor),
                          onPressed: () {
                            // 답글 콜백이 있으면 진짜 대댓글로 저장되도록 위임.
                            // 없으면(레거시 호출부) 기존처럼 입력창에 @닉네임 만 채운다.
                            if (widget.onReply != null) {
                              widget.onReply!(widget.boardCommentData);
                            } else {
                              widget.focus?.requestFocus();
                              widget.controller?.text = '@${widget.boardCommentData.nickNm.toString()} ';
                            }
                          },
                        ),
                      ),
                    ],
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
