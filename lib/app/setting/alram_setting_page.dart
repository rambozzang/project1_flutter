import 'dart:async';

import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import 'package:permission_handler/permission_handler.dart';
import 'package:project1/app/auth/cntr/auth_cntr.dart';
import 'package:project1/repo/alram/alram_repo.dart';
import 'package:project1/repo/common/code_data.dart';
import 'package:project1/repo/common/comm_repo.dart';
import 'package:project1/repo/common/res_data.dart';
import 'package:project1/repo/common/res_stream.dart';
import 'package:project1/repo/cust/cust_repo.dart';
import 'package:project1/repo/cust/data/cust_data.dart';
import 'package:project1/utils/log_utils.dart';
import 'package:project1/utils/utils.dart';

class AlramSettingPage extends StatefulWidget {
  const AlramSettingPage({super.key});

  @override
  State<AlramSettingPage> createState() => _AlramSettingPageState();
}

class _AlramSettingPageState extends State<AlramSettingPage> with WidgetsBindingObserver {
  final formKey = GlobalKey<FormState>();

  final ValueNotifier<bool> isPermisstion = ValueNotifier<bool>(false);

  final ValueNotifier<bool?> isCheckedPush = ValueNotifier<bool?>(null);

  final StreamController<ResStream<List<CodeRes>>> streamController = StreamController();

  @override
  initState() {
    super.initState();

    checkPermission();
    getData();

    // WidgetsBinding.instance.addObserver(this);
  }

  // @override
  // void didChangeAppLifecycleState(AppLifecycleState state) {
  //   checkPermission();
  // }

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

  Future<void> request() async {
    Utils.showConfirmDialog('핸드폰 알림 설정을 변경 하시겠습니까?', '핸드폰 설정화면으로 이동됩니다.', BackButtonBehavior.none, cancel: () {}, confirm: () async {
      openAppSettings();
    }, backgroundReturn: () {
      checkPermission();
    });
  }

  // 고객정보 조회를 통해 전체 알람 여부를 판단.
  Future<void> getData() async {
    try {
      CustRepo repo = CustRepo();

      ResData resData = await repo.getCustInfo(AuthCntr.to.custId.value);

      if (resData.code != '00') {
        Utils.alert(resData.msg.toString());
        return;
      }

      CustData custData = CustData.fromMap(resData.data);
      // null이면 알람이 설정되어 있음

      isCheckedPush.value = custData.alramYn == 'Y' ? true : false;
    } catch (e) {
      Utils.alert(e.toString());
    }
  }

  Future<void> searchAlram() async {
    try {
      streamController.sink.add(ResStream.loading());
      CommRepo repo = CommRepo();
      CodeReq reqData = CodeReq();
      reqData.pageNum = 0;
      reqData.pageSize = 100;
      reqData.grpCd = 'ALRAM';
      reqData.code = '';
      reqData.useYn = 'Y';
      ResData res = await repo.searchCode(reqData);

      if (res.code != '00') {
        Utils.alert(res.msg.toString());
        return;
      }
      List<CodeRes> list = (res.data as List)!.map<CodeRes>((e) => CodeRes.fromMap(e)).toList();

      // alramlist.value = list.map((e) => e.codeNm!).toList();
      streamController.sink.add(ResStream.completed(list));

      lo.g('searchRecomWord : ${res.data}');
    } catch (e) {
      lo.g('error searchRecomWord : $e');
    }
  }

  // Update
  Future<void> updateAlramSetting(String almYn) async {
    if (isPermisstion.value == false) {
      isCheckedPush.value = almYn == 'N' ? true : false;
      Utils.showConfirmDialog('먼저 핸드폰 알림 설정을 변경하셔야합니다.', '핸드폰 설정화면으로 이동하여 변경하시겠습니까?', BackButtonBehavior.none, cancel: () {},
          confirm: () async {
        openAppSettings();
      }, backgroundReturn: () {
        checkPermission();
      });

      return;
    }

    try {
      AlramRepo repo = AlramRepo();

      ResData resData = await repo.denyCustAlram(AuthCntr.to.custId.value, almYn);

      if (resData.code != '00') {
        Utils.alert(resData.msg.toString());
        return;
      }
      isCheckedPush.value = almYn == 'Y' ? true : false;
    } catch (e) {
      Utils.alert(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('알림 설정', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
      ),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 1.0,
            ),
            child: Container(
                //       height: 60.h,
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text('알림을 끄시면 해당 휴대폰 전체 알림은 발송되지 않습니다.',
                    style: TextStyle(color: Colors.black54, fontSize: 14, fontWeight: FontWeight.bold))),
          ),
          const Gap(20),
          ValueListenableBuilder<bool>(
              valueListenable: isPermisstion,
              builder: (context, val, snapshot) {
                lo.g('val : $val');
                if (val) {
                  return const SizedBox.shrink();
                }
                return GestureDetector(
                  onTap: () => request(),
                  child: Container(
                    height: 60,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: Colors.grey[200],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        const Text(
                          '기기 알림이 꺼져있습니다.',
                          style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: () => request(),
                          child: Text(val ? '끄기' : '껴기', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                        ),
                        const Gap(5),
                        const Icon(
                          Icons.arrow_forward_ios,
                          size: 19,
                        ),
                      ],
                    ),
                  ),
                );
              }),
          // const Gap(25),
          buildItem(),
          // Utils.commonStreamList<CodeRes>(streamController, buildList, searchAlram)
        ]),
      ),
    );
  }

  Widget buildList(List<CodeRes> list) {
    return ListView.builder(
      shrinkWrap: true,
      itemCount: list.length,
      physics: const BouncingScrollPhysics(),
      itemBuilder: (BuildContext context, int index) {
        return buildListItem(list[index]);
      },
    );
  }

// 공지사항 아이템
  Widget buildListItem(CodeRes data) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 0),
      child: Column(
        children: [
          Divider(
            height: 1,
            thickness: 1,
            color: Colors.grey[300],
          ),
          const Gap(10),
          ElevatedButton(
            clipBehavior: Clip.none,
            style: ElevatedButton.styleFrom(
              shadowColor: Colors.transparent,
              // fixedSize: Size(0, 0),
              minimumSize: Size.zero, // Set this
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: const VisualDensity(horizontal: 0, vertical: 0),
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
              backgroundColor: Colors.transparent,
            ),
            onPressed: null,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              //   crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          data.codeNm.toString(),
                          softWrap: true,
                          overflow: TextOverflow.fade,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black),
                        ),
                        const Gap(6),
                        // const Align(alignment: Alignment.centerRight, child: Icon(Icons.new_label_sharp, size: 14, color: Colors.red)),
                      ],
                    ),
                    const Gap(10),
                    Text(
                      '${data.code}',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black),
                    ),
                  ],
                ),
                const Spacer(),
                Icon(Icons.arrow_forward_ios, size: 19, color: Colors.grey[400]),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildItem() {
    return Container(
      // height: 70,
      padding: const EdgeInsets.symmetric(
        // horizontal: 16.0,
        vertical: 10,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              const Icon(
                Icons.notifications_active_outlined,
                color: Colors.grey,
                size: 27,
              ),
              const Gap(7),
              const Text("알람설정", style: TextStyle(color: Colors.black, fontSize: 14, fontWeight: FontWeight.bold)),
              const Spacer(),
              Transform.scale(
                scale: 0.8,
                child: ValueListenableBuilder<bool?>(
                    valueListenable: isCheckedPush,
                    builder: (context, value, child) {
                      Lo.g('isCheckedPush.value : $value');
                      if (isCheckedPush.value == null) return const SizedBox.shrink();
                      return CupertinoSwitch(
                        value: isCheckedPush.value ?? false,
                        activeColor: CupertinoColors.activeGreen,
                        onChanged: (bool value) {
                          Lo.g('onChanged.value : $value');

                          updateAlramSetting(value ? 'Y' : 'N');
                        },
                      );
                    }),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 15.0, vertical: 0.0),
            child: Text("개인별 설정은 내정보 > 팔로잉 갯수 > 팔로잉 리스트에서 설정이 가능합니다.",
                style: TextStyle(color: Colors.black, fontSize: 14, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
