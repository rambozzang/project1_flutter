import 'dart:async';

import 'package:bot_toast/bot_toast.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:get/get.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:project1/app/shared_album/theme/sa_colors.dart';
import 'package:project1/app/shared_album/theme/sa_text_styles.dart';
import 'package:project1/app/videolist/cntr/video_list_cntr.dart';
import 'package:project1/repo/board/board_repo.dart';
import 'package:project1/repo/board/data/follow_data.dart';
import 'package:project1/repo/common/res_data.dart';
import 'package:project1/repo/common/res_stream.dart';
import 'package:project1/utils/log_utils.dart';
import 'package:project1/utils/utils.dart';

/*
 나를 팔로우 한 사람들  1: 팔로워
*/

/// 차단 사용자 리스트 — "우리의 앨범"(shared_album)과 같은 디자인 토큰(SaColors/SaText)을 쓴다.
///
/// 설정 화면과 마찬가지로 **라이트 고정**이다. `SaColors.syncWith(context)`를 호출하지
/// 않으므로 `SaColors.isLight` 기본값(true)의 라이트 팔레트가 그대로 적용된다.
class BlockListPage extends StatefulWidget {
  const BlockListPage({super.key});

  @override
  State<BlockListPage> createState() => _BlockListPageState();
}

class _BlockListPageState extends State<BlockListPage> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  ScrollController scrollController = ScrollController();

  StreamController<ResStream<List<FollowData>>> listCntr = StreamController();
  List<FollowData> followList = [];

  int followType = 1;

  @override
  void initState() {
    super.initState();
    getInitFollowList();
  }

  getInitFollowList() {
    getFollowList(followType);
  }

  // followType  1: 팔로워
  // follow list 가져오기
  void getFollowList(int followType) async {
    try {
      listCntr.sink.add(ResStream.loading());
      BoardRepo repo = BoardRepo();
      ResData res = await repo.getFollowList(followType, '');
      if (res.code != '00') {
        Utils.alert(res.msg.toString());
        listCntr.sink.add(ResStream.error(res.msg.toString()));
        return;
      }
      followList.clear();

      followList = ((res.data) as List).map((data) => FollowData.fromMap(data)).toList();
      listCntr.sink.add(ResStream.completed(followList));
    } catch (e) {
      Utils.alert("팔로우 리스트 가져오기 실패");
      listCntr.sink.add(ResStream.error(e.toString()));
    }
  }

  void addAlram(String denyCustId, String yn) async {
    try {
      BoardRepo repo = BoardRepo();
      ResData res = await repo.changeFollowAlram(denyCustId.toString(), yn);
      if (res.code == '00') {
        followList.firstWhere((element) => element.custId.toString() == denyCustId).alramYn = yn;

        listCntr.sink.add(ResStream.completed(followList));
      }
    } catch (e) {
      Utils.alert("알람 설정 실패");
    }
  }

  Future<void> addFollow(String cudtId) async {
    // 팔로우 추가
    Utils.alert("팔로우 추가");
    Get.find<VideoListCntr>().follow(cudtId.toString());
    getInitFollowList();
  }

  void followCancle(String cudtId, String followYn) async {
    // 0: 팔로잉, 1: 팔로워
    String title = "맞팔로우 중입니다. 팔로우 취소합니다?";
    if (followYn == 'N') {
      title = "팔로우 취소 합니다?";
    }
    // 팔로우 추가
    Utils.showConfirmDialog("취소", title, BackButtonBehavior.none, confirm: () async {
      Lo.g('cancel');
      Get.find<VideoListCntr>().followCancle(cudtId.toString());
      getInitFollowList();
    }, cancel: () async {
      Lo.g('cancel');
    }, backgroundReturn: () {});
  }

  @override
  void dispose() {
    listCntr.close();
    scrollController.dispose();

    super.dispose();
  }

  @override
  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: SaColors.bgBase,
      appBar: AppBar(
        forceMaterialTransparency: true,
        automaticallyImplyLeading: false,
        // backgroundColor: Colors.white,
        title: Text("차단 사용자 리스트", style: SaText.titleS),
        centerTitle: true,
        // backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          getInitFollowList();
        },
        child: SingleChildScrollView(
          // controller: scrollController,
          // 화면 좌우 패딩 16 — 중복 인셋(바깥 Container 8 + 안쪽 8)을 한 곳으로 모았다.
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // buildSearchInputBox(),
              // const Divider(),
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
                child: Text("나를 팔로우한 사람들", style: SaText.caption.copyWith(color: SaColors.textTertiary)),
              ),
              Utils.commonStreamList<FollowData>(listCntr, buildList, getInitFollowList),
              const Gap(200)
            ],
          ),
        ),
      ),
    );
  }

  Widget buildList(List<FollowData> list) {
    // 목록 전체를 카드 하나로 감싼다(설정 화면 SettingsGroup 과 같은 규격: r26 / surface / border / 내부 패딩 14).
    // 배경은 Container 가 아니라 Material 이 그린다 — Container 에 색을 주면 항목의 잉크 리플이 가려진다.
    return Material(
      color: SaColors.surface,
      borderRadius: BorderRadius.circular(26),
      clipBehavior: Clip.antiAlias,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: SaColors.border),
        ),
        padding: const EdgeInsets.all(14),
        child: ListView.separated(
            shrinkWrap: true,
            itemCount: list.length,
            controller: scrollController,
            physics: const BouncingScrollPhysics(),
            separatorBuilder: (context, index) => Divider(color: SaColors.border, height: 13, thickness: 1),
            itemBuilder: (BuildContext context, int index) {
              return buildItem(list[index]);
            }),
      ),
    );
  }

  Widget buildItem(FollowData data) {
    // 버튼 이름
    String btnName = "";
    // 1: 팔로워, 0: 팔로잉

    // 내가 팔로우한 사람들
    if (data.followYn == 'Y') {
      btnName = "맞팔로우";
    } else {
      btnName = "팔로우 하기";
    }

    final bool isMutual = data.followYn == 'Y';

    return InkWell(
      onTap: () => Get.toNamed('/OtherInfoPage/${data.custId}'),
      child: Container(
        //height: 50,
        margin: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Container(
                height: 45,
                width: 45,
                decoration: BoxDecoration(
                  color: SaColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(14),
                  image: DecorationImage(
                    image: CachedNetworkImageProvider(cacheKey: data.profilePath.toString(), data.profilePath.toString()),
                    fit: BoxFit.cover,
                  ),
                ),
                child: data.profilePath == null
                    ? PhosphorIcon(PhosphorIconsFill.user, color: SaColors.textTertiary, size: 22)
                    : null),
            const Gap(12),
            // 이름 칸이 남는 폭을 차지하게 두고 넘치면 말줄임 — 긴 닉네임에서 줄이 터지지 않게.
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${data.nickNm}', style: SaText.titleS, maxLines: 1, overflow: TextOverflow.ellipsis),
                  Text('${data.custNm}',
                      style: SaText.caption.copyWith(fontWeight: FontWeight.w400), maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            const Gap(8),
            GestureDetector(
              onTap: () {
                // 2가지 , 맞팔 취소, 팔로우 추가
                isMutual ? followCancle(data.custId.toString(), data.followYn.toString()) : addFollow(data.custId.toString());
              },
              child: Container(
                height: 40,
                // width: 60,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                decoration: BoxDecoration(
                  // 맞팔로우(선택 상태) = accent, 그 외 = 중립 표면. 버튼은 pill.
                  color: isMutual ? SaColors.accentTeal : SaColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Center(
                    child: Text(btnName,
                        style: SaText.caption.copyWith(color: isMutual ? SaColors.onAccent : SaColors.textSecondary))),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 검색창
  Widget buildSearchInputBox() {
    return Container(
        height: 62,
        width: double.infinity,
        color: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: TextField(
          // controller: controller,
          textInputAction: TextInputAction.search,
          style: const TextStyle(decorationThickness: 0), // 한글밑줄제거
          decoration: InputDecoration(
            hintText: '궁금한 것을 빠르게 검색해보세요.',
            // hintStyle: KosStyle.bodyB1,
            //  prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
            contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 4),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Colors.grey, width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(width: 2),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(width: 1),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(width: 1),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(width: 1),
            ),
            suffixIcon: IconButton(
              icon: const Icon(Icons.search_rounded, color: Colors.grey),
              onPressed: () {
                //    SearchData(controller.text);
              },
            ),
          ),
        ));
  }
}
