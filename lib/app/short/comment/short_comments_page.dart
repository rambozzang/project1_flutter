import 'package:animate_icons/animate_icons.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:get/get.dart';
import 'package:project1/app/short/comment/cntr/short_comments_cntr.dart';
import 'package:project1/app/short/comment/short_comment_item_widget.dart';
import 'package:project1/repo/bbs/data/bbs_list_data.dart';
import 'package:project1/utils/utils.dart';

import 'package:intl/intl.dart' as intl;

class ShortCommentsPage extends GetView<ShortCommentsController> {
  const ShortCommentsPage({super.key, required boardId, required mainScrollController});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            buildTitle(),
            Utils.commonStreamList<BbsListData>(
                controller.replyStreamController,
                buildList,
                loadingWidget: const SizedBox.shrink(),
                noDataWidget: buildNoData(),
                controller.fetchComments),
            const Gap(30),
            const Gap(30),
          ],
        ),

        // Obx(() => CustomIndicatorOffstage(isLoading: !controller.isDeleting.value, color: const Color(0xFFEA3799), opacity: 0.5))
      ],
    );
  }

  Widget buildTitle() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Gap(6),
            Container(
              height: 26,
              padding: const EdgeInsets.symmetric(horizontal: 7),
              decoration: BoxDecoration(
                color: Colors.purple[600],
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  // const Icon(Icons.chat_outlined, color: Colors.white, size: 13),
                  const Text(
                    "게시글",
                    style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 6.0),
                    child: Obx(() => Text(
                          controller.toalCount.value.toString(),
                          style: const TextStyle(
                            fontWeight: FontWeight.w400,
                            color: Colors.white,
                            fontSize: 13,
                          ),
                        )),
                  ),
                ],
              ),
            ),
            const Spacer(),
            const Text("자동 업데이트", style: TextStyle(color: Colors.black54, fontSize: 9)),
            SizedBox(
              width: 45,
              child: Transform.scale(
                scale: 0.7,
                child: Obx(() => CupertinoSwitch(
                      value: controller.isRealTimeUpdate.value,
                      activeColor: CupertinoColors.activeOrange,
                      onChanged: (bool value) {
                        print('value: $value');
                        controller.fetchRealTimeUpdate(!value);
                      },
                    )),
              ),
            ),
            AnimateIcons(
              startIcon: Icons.refresh,
              endIcon: Icons.refresh,
              controller: AnimateIconController(),
              startTooltip: 'Icons.refresh',
              endTooltip: 'Icons.refresh_rounded',
              size: 23.0,
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
            // const Gap(6),
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
          cacheExtent: 600,
          addAutomaticKeepAlives: false,
          addRepaintBoundaries: true,
          controller: controller.replayListScrollController,
          itemCount: list.isEmpty ? 1 : list.length,
          itemBuilder: (BuildContext context, int index) {
            bool showDate = false;
            String currentDate = list[index].crtDtm!.substring(0, 10);

            // depthNo가 1인 경우만 표시
            if (list[index].depthNo == '1') {
              // 현재 아이템의 날짜
              // 이전 아이템의 날짜 (첫 번째 아이템이 아닌 경우에만)
              String? previousDate;
              if (index > 0) {
                // depthNo가 1인 데이터로만 계산
                for (int i = index - 1; i >= 0; i--) {
                  if (list[i].depthNo == '1') {
                    previousDate = list[i].crtDtm!.substring(0, 10);
                    break;
                  }
                }
                // previousDate =  list[index - 1].crtDtm!.substring(0, 10);
              }
              // 날짜 표시 여부 결정
              // 첫 번째 아이템이거나 이전 아이템과 날짜가 다른 경우에만 표시
              showDate = index == 0 || previousDate != currentDate;
            }

            // 오늘 날짜인 경우  표시 안함.
            if (currentDate == intl.DateFormat('yyyy-MM-dd').format(DateTime.now())) {
              showDate = false;
            }

            currentDate = intl.DateFormat('yyyy.MM.dd(EE)', 'ko').format(DateTime.parse(currentDate));

            return KeyedSubtree(
              key: ValueKey(list[index].boardId),
              child: ShortCommentItemWidget(
                isDarkTheme: false,
                callback: controller.replayCommentsClick,
                bbsListData: list[index],
                controller: controller.replyTextController,
                displayDate: showDate ? currentDate : null,
              ),
            );
          },
        ),
        const Gap(30),
        SizedBox(
          height: 33,
          child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 2.0, horizontal: 15.0),
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(
                    Radius.circular(15),
                  ),
                ),
                side: const BorderSide(width: 1, color: Colors.black45),
                elevation: 3,
              ),
              onPressed: () => controller.replayCommentsClick(null), // controller.isDeleting.value = !controller.isDeleting.value, //
              child: const Text(
                '글쓰기',
                style: TextStyle(color: Colors.black54, fontSize: 14),
              )),
        ),
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
              '동네 소식을 전해 주세요.',
              style: TextStyle(color: Colors.black87, fontSize: 13),
            ),
            const Gap(45),
            SizedBox(
              height: 33,
              child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 2.0, horizontal: 15.0),
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(
                        Radius.circular(15),
                      ),
                    ),
                    side: const BorderSide(width: 1, color: Colors.black45),
                    elevation: 3,
                  ),
                  onPressed: () => controller.replayCommentsClick(null), // controller.isDeleting.value = !controller.isDeleting.value, //
                  child: const Text(
                    '글쓰기',
                    style: TextStyle(color: Colors.black54, fontSize: 14),
                  )),
            ),
            const Gap(45),
          ],
        ),
      ),
    );
  }
}
