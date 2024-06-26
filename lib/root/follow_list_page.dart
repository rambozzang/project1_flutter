import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_svg/svg.dart';
import 'package:gap/gap.dart';
import 'package:get/get.dart';
import 'package:get/get_connect/http/src/utils/utils.dart';
import 'package:project1/app/auth/cntr/auth_cntr.dart';
import 'package:project1/repo/board/board_repo.dart';
import 'package:project1/repo/board/data/follow_data.dart';
import 'package:project1/repo/common/res_data.dart';
import 'package:project1/repo/common/res_stream.dart';
import 'package:project1/utils/utils.dart';

class FollowListPage extends StatefulWidget {
  const FollowListPage({super.key, required this.followType});
  final int followType; // 0: 팔로잉, 1: 팔로워

  @override
  State<FollowListPage> createState() => _FollowListPageState();
}

class _FollowListPageState extends State<FollowListPage> {
  ScrollController scrollController = ScrollController();

  StreamController<ResStream<List<FollowData>>> listCntr = StreamController();
  List<FollowData> followList = [];

  @override
  void initState() {
    super.initState();
    getInitFollowList();
  }

  getInitFollowList() {
    getFollowList(widget.followType);
  }

  // followType 0: 팔로잉, 1: 팔로워
  // follow list 가져오기
  void getFollowList(int followType) async {
    try {
      listCntr.sink.add(ResStream.loading());
      BoardRepo repo = BoardRepo();
      ResData res = await repo.getFollowList(followType, AuthCntr.to.resLoginData.value.custId.toString());
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

  void addAlram(String yn) async {
    try {
      BoardRepo repo = BoardRepo();
      ResData res = await repo.changeFollowAlram(AuthCntr.to.resLoginData.value.custId.toString(), yn);
      if (res.code == '00') {
        listCntr.sink.add(ResStream.completed(followList));
      }
    } catch (e) {
      Utils.alert("알람 설정 실패");
    }
  }

  void addFollow() {
    // 팔로우 추가
    Utils.alert("팔로우 추가");
  }

  @override
  @override
  Widget build(BuildContext context) {
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
      body: Container(
        // color: Colors.white.withOpacity(.94),
        padding: const EdgeInsets.symmetric(vertical: 0.0, horizontal: 8.0),
        child: SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 8),
          child: Column(
            children: [
              buildSearchInputBox(),
              Container(
                  //    height: 200,
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(40),
                  ),
                  child: Utils.commonStreamList<FollowData>(listCntr, buildList, getInitFollowList))
            ],
          ),
        ),
      ),
    );
  }

  Widget buildList(List<FollowData> list) {
    return ListView.builder(
        shrinkWrap: true,
        itemCount: list.length,
        physics: const BouncingScrollPhysics(),
        itemBuilder: (BuildContext context, int index) {
          return buildItem(list[index]);
        });
  }

  Widget buildItem(FollowData data) {
    return InkWell(
      onTap: () => Get.toNamed('/OtherInfoPage/${data.custId}'),
      child: Container(
        //height: 50,
        decoration: BoxDecoration(
          //  color: Colors.white,
          borderRadius: BorderRadius.circular(10),
        ),
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
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
                    image: CachedNetworkImageProvider(data.profilePath.toString()),
                    fit: BoxFit.cover,
                  ),
                ),
                child: const Icon(Icons.person, color: Colors.white)),
            const Gap(10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('@${data.selfId ?? data.custNm}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Text('${data.nickNm} ', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal)),
              ],
            ),
            const Spacer(),
            GestureDetector(
              onTap: () {
                addFollow();
              },
              child: Container(
                height: 30,
                width: 60,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Center(child: Text("구독중", style: TextStyle(fontSize: 12, fontWeight: FontWeight.normal))),
              ),
            ),
            IconButton(
              onPressed: () => addAlram(data.alramYn.toString() == 'Y' ? 'Y' : 'N'),
              icon: Icon(Icons.alarm_add, color: data.alramYn.toString() == 'Y' ? Colors.grey.shade400 : Colors.black),
            )
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
