import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:get/get.dart';
import 'package:project1/app/auth/cntr/auth_cntr.dart';
import 'package:project1/repo/board/board_repo.dart';
import 'package:project1/repo/board/data/board_Comment_data.dart';
import 'package:project1/repo/board/data/board_comment_res_data.dart';
import 'package:project1/repo/board/data/board_main_detail_data.dart';
import 'package:project1/repo/common/res_data.dart';
import 'package:project1/utils/utils.dart';
import 'package:timeago/timeago.dart' as timeago;

class ListItemWidget extends StatefulWidget {
  const ListItemWidget({
    super.key,
    this.focus,
    required this.boardCommentData,
    required this.controller,
  });
  final FocusNode? focus;
  final BoardCommentResData boardCommentData;
  final TextEditingController? controller;

  @override
  State<ListItemWidget> createState() => _ListItemWidgetState();
}

class _ListItemWidgetState extends State<ListItemWidget> {
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
      Utils.alert('좋아요! 저장되었습니다.');
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
      Utils.alert('좋아요! 취소 되었습니다.');
      likeCnt.value = likeCnt.value - 1;
      likeYn.value = 'N';
      widget.boardCommentData.likeYn = 'N';
    } catch (e) {
      Utils.alert('좋아요 취소 실패! 다시 시도해주세요');
    }
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black, // const Color(0xFF0F0F0F),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.only(top: 12, bottom: 0, left: 10, right: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                        '@${widget.boardCommentData.nickNm.toString()}',
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w400, color: Color(0xFFAEAEAE)),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 7.0),
                        child: Text(
                          '·',
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                      ),
                      Text(
                        Utils.timeage(widget.boardCommentData.crtDtm!),
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w400, color: Color(0xFFAEAEAE)),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 6, bottom: 12),
                    child: Text(
                      widget.boardCommentData.contents.toString(),
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w400, color: Color(0xFFF6F6F6)),
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
                                iconSize: 16,
                                icon: value == 'Y'
                                    ? const Icon(Icons.thumb_up, color: Colors.white)
                                    : const Icon(Icons.thumb_up_outlined, color: Colors.white),
                                onPressed: () => value == 'Y' ? likeCancle() : like(),
                              );
                            }),
                      ),
                      const Gap(4),
                      ValueListenableBuilder<int>(
                          valueListenable: likeCnt,
                          builder: (contex, value, child) {
                            return Text(
                              value.toString(),
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w400, color: Color(0xFFF6F6F6)),
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
                      const Gap(17),
                      SizedBox(
                        height: 15,
                        width: 22,
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          iconSize: 16,
                          icon: const Icon(Icons.comment_outlined, color: Colors.white),
                          onPressed: () {
                            widget.focus?.requestFocus();
                            widget.controller?.text = '@${widget.boardCommentData.nickNm.toString()} ';
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
