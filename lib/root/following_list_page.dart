import 'dart:async';

import 'package:bot_toast/bot_toast.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:gap/gap.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:project1/app/videolist/cntr/video_list_cntr.dart';
import 'package:project1/repo/alram/alram_repo.dart';
import 'package:project1/repo/alram/data/alram_devy_data.dart';
import 'package:project1/repo/board/board_repo.dart';
import 'package:project1/repo/board/data/follow_data.dart';
import 'package:project1/repo/common/res_data.dart';
import 'package:project1/repo/common/res_stream.dart';
import 'package:project1/utils/log_utils.dart';
import 'package:project1/utils/utils.dart';

/*
 내가 팔로우 한 사람들  0: 팔로잉
*/
class FollowingListPage extends StatefulWidget {
  const FollowingListPage({super.key, required this.custId});
  final String custId;

  @override
  State<FollowingListPage> createState() => _FollowingListPageState();
}

class _FollowingListPageState extends State<FollowingListPage> {
  // with AutomaticKeepAliveClientMixin {
  // @override
  // bool get wantKeepAlive => true;

  ScrollController scrollController = ScrollController();

  StreamController<ResStream<List<FollowData>>> listCntr = StreamController();
  List<FollowData> followList = [];

  int followType = 0;

  final ValueNotifier<bool> isPermisstion = ValueNotifier<bool>(false);

  @override
  void initState() {
    super.initState();
    getInitFollowList();
    checkPermission();
  }

  /*
 isGranted - 권한 동의 상태 시 true
  isLimited - 권한이 제한적으로 동의 상태 시 true (ios 14버전 이상)
  isPermanentlyDeined - 영구적으로 권한 거부 상태 시 true (android 전용, 다시 묻지 않음)
  Permission.location.status는 영구 거부 해도 denied 반환
  openAppSettings() - 앱 설정 화면으로 이동
  isRestricted - 권한 요청을 표시하지 않도록 선택 시 true (ios 전용)
  isDenied - 권한 거부 상태 시 ture
 */
  Future<void> checkPermission() async {
    var requestStatus = await Permission.notification.request();
    var status = await Permission.notification.status;
    // if (requestStatus.isGranted && status.isLimited) {
    if (requestStatus.isGranted) {
      // isLimited - 제한적 동의 (ios 14 < )
      // 요청 동의됨
      lo.g("isGranted");
      isPermisstion.value = true;
    } else if (requestStatus.isPermanentlyDenied || status.isPermanentlyDenied) {
      // 권한 요청 거부, 해당 권한에 대한 요청에 대해 다시 묻지 않음 선택하여 설정화면에서 변경해야함. android
      lo.g("isPermanentlyDenied");
      // openAppSettings();
      isPermisstion.value = false;
    } else if (status.isRestricted) {
      // 권한 요청 거부, 해당 권한에 대한 요청을 표시하지 않도록 선택하여 설정화면에서 변경해야함. ios
      lo.g("isRestricted");
      //  openAppSettings();
      isPermisstion.value = false;
    } else if (status.isDenied) {
      // 권한 요청 거절
      lo.g("isDenied");
      isPermisstion.value = false;
    }
    lo.g("requestStatus ${requestStatus.name}");
    lo.g("status ${status.name}");
  }

  Future<void> request(context) async {
    Utils.showConfirmDialog('알림 설정을 변경 하시겠습니까?', '알림 설정을 변경 하시겠습니까?', BackButtonBehavior.none, cancel: () {}, confirm: () async {
      openAppSettings();
    }, backgroundReturn: () {
      checkPermission();
    });
  }

  getInitFollowList() {
    getFollowList(followType);
  }

  // followType 0: 팔로잉
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

        if (yn == 'Y') {
          BotToast.showText(text: '알람이 설정되었습니다.');
        } else {
          BotToast.showText(text: '알람이 거부되었습니다.');
        }
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

  // 알람 거부/ 거부 해제 하기
  void denyAlram(String cudtId, String denyYn) async {
    try {
      AlramRepo repo = AlramRepo();
      AlramDenyData data = AlramDenyData();
      data.denyCustId = cudtId;
      data.denyType = 'P'; // 전체 ALL or 개별 P
      data.denyYn = denyYn;

      ResData res = await repo.denyAlram(data);
      if (res.code == '00') {
        listCntr.sink.add(ResStream.completed(followList));
        if (denyYn == 'Y') {
          BotToast.showText(text: '알람 거부 되었습니다.');
        } else {
          BotToast.showText(text: '알람 거부 해제 되었습니다.');
        }
      }
    } catch (e) {
      Utils.alert("알람 거부 실패");
    }
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
        child: Padding(
          // color: Colors.white.withOpacity(.94),
          padding: const EdgeInsets.symmetric(vertical: 0.0, horizontal: 8.0),
          child: Column(
            children: [
              ValueListenableBuilder<bool>(
                  valueListenable: isPermisstion,
                  builder: (context, val, snapshot) {
                    lo.g('val : $val');
                    if (val) {
                      return const SizedBox.shrink();
                    }
                    return Container(
                      height: 50,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              const Text(
                                '기기 알림이 꺼져있습니다.',
                                style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              const Spacer(),
                              TextButton(
                                onPressed: () => request(context),
                                child: Text(val ? '끄기' : '껴기', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                              ),
                              // const Gap(5),
                              // const Icon(
                              //   Icons.arrow_forward_ios,
                              //   size: 19,
                              // ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }),
              SingleChildScrollView(
                // controller: scrollController,
                padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // buildSearchInputBox(),
                    // const Divider(),
                    Text(
                      "내가 팔로우한 사람들",
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade600),
                    ),
                    Utils.commonStreamList<FollowData>(listCntr, buildList, getInitFollowList)
                  ],
                ),
              ),
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
    // 버튼 이름
    String btnName = "";
    // 1: 팔로워, 0: 팔로잉

    // 나를 팔로우한 사람들
    if (data.followYn == 'Y') {
      btnName = "맞팔로우";
    } else {
      btnName = "팔로우 취소";
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
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
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
                child: data.profilePath == null ? const Icon(Icons.person, color: Colors.white) : null),
            const Gap(10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${data.nickNm} ', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                Text('@${data.selfId ?? data.custNm}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal)),
              ],
            ),
            const Spacer(),
            GestureDetector(
              onTap: () {
                // 2가지 , 맞팔 취소, 팔로우 취소
                followCancle(data.custId.toString(), data.followYn.toString());
              },
              child: Container(
                height: 30,
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
            SizedBox(
              width: 30,
              child: IconButton(
                onPressed: () => addAlram(data.custId.toString(), data.alramYn.toString() == 'Y' ? 'N' : 'Y'),
                icon: Icon(Icons.alarm_add, color: data.alramYn.toString() == 'Y' ? Colors.deepOrange : Colors.grey.shade400),
              ),
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
