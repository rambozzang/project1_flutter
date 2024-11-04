import 'package:animate_icons/animate_icons.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:get/get.dart';
import 'package:project1/app/bbs/comments/cntr/bbs_comments_cntr.dart';
import 'package:project1/app/bbs/comments/bbs_comment_item_widget.dart';
import 'package:project1/repo/bbs/data/bbs_list_data.dart';
import 'package:project1/utils/log_utils.dart';
import 'package:project1/utils/utils.dart';

class BbsCommentsPage extends StatefulWidget {
  final String tagNm;
  final ScrollController mainScrollController;
  final BbsListData bbsListData;

  const BbsCommentsPage({super.key, required this.tagNm, required this.mainScrollController, required this.bbsListData});

  @override
  State<BbsCommentsPage> createState() => _BbsCommentsPageState();
}

class _BbsCommentsPageState extends State<BbsCommentsPage> with AutomaticKeepAliveClientMixin {
  late final BbsCommentsController controller;

  late bool isDelete;
  late String boardId;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    controller = Get.put(BbsCommentsController(), tag: widget.tagNm);
    super.initState();
    isDelete = widget.bbsListData.delYn == 'Y';
    boardId = widget.bbsListData.boardId.toString();

    init();
  }

  init() {
    controller.setInitData(widget.bbsListData);

    controller.setSCrollController(widget.mainScrollController);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    // BbsCommentsController
    return Stack(
      children: [
        Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            buildTitle(),
            Utils.commonStreamList<BbsListData>(
                controller.replyStreamController, buildList, noDataWidget: buildNoData(), controller.fetchComments),
            const Gap(60),
          ],
        ),
        // Obx(() {
        //   if (controller.isDeleting.value) {
        //     return CustomIndicatorOffstage(isLoading: controller.isDeleting.value, color: const Color(0xFFEA3799), opacity: 0.5);
        //   }
        //   return const SizedBox.shrink();
        // })
        // Obx(() => CustomIndicatorOffstage(isLoading: !controller.isDeleting.value, color: const Color(0xFFEA3799), opacity: 0.5))
      ],
    );
  }

  Widget buildTitle() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Gap(5),
        Divider(
          height: 6,
          thickness: 6,
          color: Colors.grey.withOpacity(0.3),
        ),
        Row(
          children: [
            const Padding(
              padding: EdgeInsets.only(left: 15),
              child: Text(
                "댓글",
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                  fontSize: 14,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 4.0),
              child: Obx(() => Text(
                    controller.toalCount.toString(),
                    style: const TextStyle(
                      fontWeight: FontWeight.w400,
                      color: Colors.black,
                      fontSize: 13,
                    ),
                  )),
            ),
            const Spacer(),
            AnimateIcons(
              startIcon: Icons.refresh,
              endIcon: Icons.refresh,
              controller: AnimateIconController(),
              startTooltip: 'Icons.refresh',
              endTooltip: 'Icons.refresh_rounded',
              size: 24.0,
              onStartIconPress: () {
                controller.fetchComments();
                return true;
              },
              onEndIconPress: () {
                controller.fetchComments();
                return true;
              },
              duration: const Duration(milliseconds: 200),
              startIconColor: Colors.black,
              endIconColor: Colors.black,
              clockwise: true,
            ),
          ],
        ),
        // Divider(
        //   height: 1,
        //   thickness: 1,
        //   color: Colors.grey.withOpacity(0.3),
        // ),
      ],
    );
  }

  Widget buildList(List<BbsListData> list) {
    return Column(
      children: [
        ListView.builder(
          shrinkWrap: true,
          // physics: const AlwaysScrollableScrollPhysics(),
          controller: controller.replayListScrollController,
          // physics: const NeverScrollableScrollPhysics(),
          itemCount: list.isEmpty ? 1 : list.length,
          itemBuilder: (BuildContext context, int index) {
            return BBsCommentItemWidget(
              tagNm: widget.tagNm,
              isDarkTheme: false,
              callback: controller.replayCommentsClick,
              bbsListData: list[index],
              controller: controller.replyTextController,
            );
          },
        ),
        const Gap(30),
        OutlinedButton(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 3.0, horizontal: 10.0),
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(
                  Radius.circular(15),
                ),
              ),
              side: const BorderSide(width: 1, color: Colors.black45),
              elevation: 3,
            ),
            onPressed: () {
              if (isDelete == true || isDelete == 'true') {
                Utils.alertIcon('삭제된 게시글입니다..', icontype: 'E');
                return;
              }
              controller.replayCommentsClick(null);
            },
            child: const Text(
              '댓글 달기',
              style: TextStyle(color: Colors.black54, fontSize: 14),
            ))
      ],
    );
  }

  Widget buildNoData() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(68.0),
        child: Column(
          children: [
            const Text(
              '댓글이 없습니다.',
              style: TextStyle(color: Colors.black87, fontSize: 13),
            ),
            const Gap(45),
            OutlinedButton(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 3.0, horizontal: 10.0),
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(
                      Radius.circular(15),
                    ),
                  ),
                  side: const BorderSide(width: 1, color: Colors.black45),
                  elevation: 3,
                ),
                onPressed: () {
                  lo.g("widget.isDelete : ${isDelete}");
                  if (isDelete == true || isDelete == 'true') {
                    Utils.alertIcon('삭제된 게시글입니다..', icontype: 'E');
                    return;
                  }
                  controller.replayCommentsClick(null);
                },
                child: const Text(
                  '댓글 달기',
                  style: TextStyle(color: Colors.black54, fontSize: 14),
                )),
            const Gap(45),
          ],
        ),
      ),
    );
  }
}
