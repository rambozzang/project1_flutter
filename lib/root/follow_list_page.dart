import 'dart:async';

import 'package:bot_toast/bot_toast.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:gap/gap.dart';
import 'package:get/get.dart';
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
class FollowListPage extends StatefulWidget {
  const FollowListPage({super.key, required this.custId});
  final String custId;

  @override
  State<FollowListPage> createState() => _FollowListPageState();
}

class _FollowListPageState extends State<FollowListPage> with AutomaticKeepAliveClientMixin {
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
      ResData res = await repo.getFollowList(followType, widget.custId.toString());
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
      backgroundColor: Colors.white.withOpacity(.94),
      appBar: AppBar(
        forceMaterialTransparency: true,
        automaticallyImplyLeading: false,
        // backgroundColor: Colors.white,
        title: const Text(
          "사용자 리스트",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        // backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          getInitFollowList();
        },
        child: Container(
          // color: Colors.white.withOpacity(.94),
          padding: const EdgeInsets.symmetric(vertical: 0.0, horizontal: 8.0),
          child: SingleChildScrollView(
            // controller: scrollController,
            padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // buildSearchInputBox(),
                // const Divider(),
                Text(
                  "나를 팔로우한 사람들",
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade600),
                ),
                Utils.commonStreamList<FollowData>(listCntr, buildList, getInitFollowList),
                const Gap(200)
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget buildList(List<FollowData> list) {
    return ListView.builder(
        shrinkWrap: true,
        itemCount: list.length,
        controller: scrollController,
        physics: const BouncingScrollPhysics(),
        itemBuilder: (BuildContext context, int index) {
          return buildItem(list[index]);
        });
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

    return InkWell(
      onTap: () => Get.toNamed('/OtherInfoPage/${data.custId}'),
      child: Container(
        //height: 50,
        decoration: BoxDecoration(
          //  color: Colors.white,
          borderRadius: BorderRadius.circular(10),
        ),
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 1),
        child: Row(
          children: [
            Container(
                height: 45,
                width: 45,
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  // color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(10),
                  image: DecorationImage(
                    image: CachedNetworkImageProvider(cacheKey: data.profilePath.toString(), data.profilePath.toString()),
                    fit: BoxFit.cover,
                  ),
                ),
                child: data.profilePath == null ? const Icon(Icons.person, color: Colors.white) : null),
            const Gap(10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${data.nickNm}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                Text('${data.custNm}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal)),
              ],
            ),
            const Spacer(),
            GestureDetector(
              onTap: () {
                // 2가지 , 맞팔 취소, 팔로우 추가
                data.followYn == 'Y' ? followCancle(data.custId.toString(), data.followYn.toString()) : addFollow(data.custId.toString());
              },
              child: Container(
                height: 40,
                // width: 60,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                decoration: BoxDecoration(
                  color: data.followYn == 'Y' ? const Color.fromARGB(255, 21, 85, 169) : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                    child: Text(btnName,
                        style: TextStyle(
                            fontSize: 12, fontWeight: FontWeight.normal, color: data.followYn == 'Y' ? Colors.white : Colors.black))),
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
