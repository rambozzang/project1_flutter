import 'dart:async';

import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import 'package:permission_handler/permission_handler.dart';
import 'package:project1/app/auth/cntr/auth_cntr.dart';
import 'package:project1/repo/alram/alram_deny_repo.dart';
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

  final StreamController<ResStream<List<Map<String, String>>>> streamController = StreamController();

  final ValueNotifier<Map<String, bool>> isCheckedAlim = ValueNotifier<Map<String, bool>>({});

  List<Map<String, String>> list = [];
  AlramDenyRepo repo = AlramDenyRepo();

  @override
  initState() {
    super.initState();

    checkPermission();
    getData();
  }

  Future<void> checkPermission() async {
    var requestStatus = await Permission.notification.request();
    var status = await Permission.notification.status;
    if (requestStatus.isGranted) {
      lo.g("isGranted");
      isPermisstion.value = true;
    } else if (requestStatus.isPermanentlyDenied || status.isPermanentlyDenied) {
      lo.g("isPermanentlyDenied");
      isPermisstion.value = false;
    } else if (status.isRestricted) {
      lo.g("isRestricted");
      isPermisstion.value = false;
    } else if (status.isDenied) {
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

  Future<void> getData() async {
    try {
      CustRepo repo = CustRepo();

      ResData resData = await repo.getCustInfo(AuthCntr.to.custId.value);

      if (resData.code != '00') {
        Utils.alert(resData.msg.toString());
        return;
      }

      CustData custData = CustData.fromMap(resData.data);
      isCheckedPush.value = custData.alramYn == 'Y';
      if (custData.alramYn == 'Y') {
        searchAlramCdList();
      }
    } catch (e) {
      Utils.alert(e.toString());
    }
  }

  Future<void> searchAlramCdList() async {
    try {
      ResData res = await repo.getDenyalramCdlist();

      if (res.code != '00') {
        Utils.alert(res.msg.toString());
        return;
      }
      list = (res.data as List).map<Map<String, String>>((e) => Map<String, String>.from(e)).toList();
      streamController.sink.add(ResStream.completed(list));
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
      List<CodeRes> list = (res.data as List).map<CodeRes>((e) => CodeRes.fromMap(e)).toList();

      lo.g('searchRecomWord : ${res.data}');
    } catch (e) {
      lo.g('error searchRecomWord : $e');
    }
  }

  // 고객 전체 알람설정
  Future<void> updateAlramSetting(String alramYn) async {
    if (isPermisstion.value == false) {
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
      ResData resData = await repo.denyCustAlram(AuthCntr.to.custId.value, alramYn);
      if (resData.code != '00') {
        Utils.alert(resData.msg.toString());
        return;
      }
      if (alramYn == 'Y') {
        // streamController.sink.add(ResStream.completed(list));
        searchAlramCdList();
      } else {
        streamController.sink.add(ResStream.completed([]));
      }
      // isCheckedPush.value = almYn == 'Y' ? true : false;
    } catch (e) {
      Utils.alert(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        forceMaterialTransparency: true,
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
          const Gap(10),
          ValueListenableBuilder<bool>(
              valueListenable: isPermisstion,
              builder: (context, val, snapshot) {
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
                          child: Text(val ? '끄기' : '켜기', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
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
          buildItem(),
          Divider(
            height: 15,
            thickness: 3,
            color: Colors.grey.withOpacity(0.3),
          ),
          Utils.commonStreamList<Map<String, String>>(streamController, buildAlramList, searchAlram,
              noDataWidget: const Center(
                child: Padding(
                  padding: EdgeInsets.all(40.0),
                  child: Text(
                    '전체 알람이 꺼져있습니다.',
                    style: TextStyle(color: Colors.grey, fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                ),
              )),
        ]),
      ),
    );
  }

  // 고객 전체 알람설정
  Widget buildItem() {
    return Container(
      padding: const EdgeInsets.symmetric(
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
                          isCheckedPush.value = value;
                        },
                      );
                    }),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 15.0, vertical: 0.0),
            child: Text("개인별 설정은 내정보 > 팔로잉 갯수 > 팔로잉 리스트에서 설정이 가능합니다.",
                style: TextStyle(color: Colors.black, fontSize: 14, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget buildAlramList(List<Map<String, String>> list) {
    return ListView.builder(
      shrinkWrap: true,
      itemCount: list.length,
      physics: const BouncingScrollPhysics(),
      itemBuilder: (BuildContext context, int index) {
        return buildAlramListItem(list[index], list[index]['denyYn'] == 'N' ? ValueNotifier<bool>(true) : ValueNotifier<bool>(false));
      },
    );
  }

  // Alram Deny 테이블 알람 설정
  Widget buildAlramListItem(Map<String, String> data, ValueNotifier<bool> isChecked) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 16.0,
        vertical: 7,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // const Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // const Icon(
              //   Icons.notifications,
              //   color: Colors.black,
              //   size: 27,
              // ),
              // const Gap(7),
              Text(
                data['alramNm2'] ?? '',
                style: const TextStyle(color: Colors.black, fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              Transform.scale(
                scale: 0.75,
                child: CupertinoSwitch(
                  value: isChecked.value,
                  activeColor: CupertinoColors.activeOrange,
                  onChanged: (bool value) {
                    if (value) {
                      deleteAlram(data['alramCd'].toString());
                    } else {
                      addAlram(data['alramCd'].toString());
                    }

                    data['denyYn'] = value ? 'N' : 'Y';
                    isChecked.value = !value;
                    setState(() {});
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> addAlram(String alramCd) async {
    try {
      ResData resData = await repo.adddeny(alramCd);
      if (resData.code != '00') {
        Utils.alert(resData.msg.toString());
        return;
      }
    } catch (e) {
      Utils.alert(e.toString());
    }
  }

  Future<void> deleteAlram(String alramCd) async {
    try {
      ResData resData = await repo.deleteAlram(alramCd);
      if (resData.code != '00') {
        Utils.alert(resData.msg.toString());
        return;
      }
    } catch (e) {
      Utils.alert(e.toString());
    }
  }
}
