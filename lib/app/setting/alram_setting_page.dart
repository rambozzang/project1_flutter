import 'dart:async';

import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import 'package:permission_handler/permission_handler.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:project1/app/auth/cntr/auth_cntr.dart';
import 'package:project1/app/shared_album/theme/sa_colors.dart';
import 'package:project1/app/shared_album/theme/sa_text_styles.dart';
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

/// 알림(PUSH) 설정 — 설정 화면(setting_page)과 같은 디자인 토큰(SaColors/SaText)을 쓴다.
/// 라이트 고정: `SaColors.syncWith(context)`를 부르지 않는다.
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

  // 기상특보 알림 범위: 'ALL'(전체·기본) | 'LOCAL'(관심지역만)
  final ValueNotifier<String> warnScope = ValueNotifier<String>('ALL');

  // 기상특보 알림(카테고리 10) 활성 여부 — 꺼져 있으면 범위 선택을 비활성화한다.
  final ValueNotifier<bool> warnAlarmOn = ValueNotifier<bool>(true);

  @override
  initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
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
      await openAppSettings();
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
      warnScope.value = (custData.warnScope == 'LOCAL') ? 'LOCAL' : 'ALL';
      // 전체 알람이 꺼져 있으면 특보 범위도 비활성. 켜져 있으면 카테고리 로드 시 실제 상태로 갱신.
      warnAlarmOn.value = custData.alramYn == 'Y';
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
      // 기상특보(카테고리 10) on/off 반영 — denyYn 'Y'=꺼짐.
      final warn = list.where((e) => e['alramCd'] == '10');
      if (warn.isNotEmpty) warnAlarmOn.value = warn.first['denyYn'] != 'Y';
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
        warnAlarmOn.value = false; // 전체 알람 끄면 특보 범위도 비활성
      }
      // isCheckedPush.value = almYn == 'Y' ? true : false;
    } catch (e) {
      Utils.alert(e.toString());
    }
  }

  // 기상특보 알림 범위 저장('ALL'|'LOCAL')
  Future<void> updateWarnScope(String scope) async {
    try {
      ResData resData = await CustRepo().updateWarnScope(AuthCntr.to.custId.value, scope);
      if (resData.code != '00') {
        Utils.alert(resData.msg.toString());
        return;
      }
      BotToast.showText(text: scope == 'LOCAL' ? '관심지역 특보만 받습니다.' : '전체 특보를 받습니다.');
    } catch (e) {
      Utils.alert(e.toString());
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    lo.g('state : $state , isPermisstion.value : ${isPermisstion.value}');
    if (state == AppLifecycleState.resumed && !isPermisstion.value) {
      checkPermission();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    streamController.close();
    super.dispose();
  }

  /// 카드 — 핸드오프 규격: r26 / surface / border / 내부 패딩 14.
  /// 배경은 Container가 아니라 Material이 그린다(잉크 리플이 가려지지 않도록).
  Widget _card({required Widget child}) => Material(
        color: SaColors.surface,
        borderRadius: BorderRadius.circular(26),
        clipBehavior: Clip.antiAlias,
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: SaColors.border),
          ),
          padding: const EdgeInsets.all(14),
          child: child,
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        forceMaterialTransparency: true,
        automaticallyImplyLeading: false,
        // 뒤로가기 — setting_page와 같은 원형 surface 버튼(pill). 화면 좌측 패딩 16에 맞춘다.
        leadingWidth: 72,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16),
          child: Center(
            child: SizedBox(
              width: 40,
              height: 40,
              child: Material(
                color: SaColors.surface,
                shape: CircleBorder(side: BorderSide(color: SaColors.borderStrong)),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () => Navigator.pop(context),
                  child: Center(
                    child: PhosphorIcon(PhosphorIconsBold.caretLeft, size: 17, color: SaColors.textPrimary),
                  ),
                ),
              ),
            ),
          ),
        ),
        title: Text('알림 설정', style: SaText.titleS),
        centerTitle: true,
        elevation: 0,
      ),
      backgroundColor: SaColors.bgBase,
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        child: Column(children: [
          ValueListenableBuilder<bool>(
              valueListenable: isPermisstion,
              builder: (context, val, snapshot) {
                if (val) {
                  return const SizedBox.shrink();
                }
                return GestureDetector(
                  onTap: () => request(),
                  child: _card(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Text('기기 알림이 꺼져있습니다.', style: SaText.titleS),
                        const Spacer(),
                        TextButton(
                          onPressed: () => request(),
                          child: Text(val ? '끄기' : '켜기',
                              style: SaText.caption.copyWith(color: SaColors.accentTeal, fontWeight: FontWeight.w800)),
                        ),
                        const Gap(5),
                        PhosphorIcon(PhosphorIconsBold.caretRight, size: 16, color: SaColors.textTertiary),
                      ],
                    ),
                  ),
                );
              }),
          ValueListenableBuilder<bool>(
              valueListenable: isPermisstion,
              builder: (context, val, snapshot) {
                if (!val) {
                  return const SizedBox.shrink();
                }

                return Column(
                  children: [
                    buildItem(),
                    const Gap(20),
                    Utils.commonStreamList<Map<String, String>>(streamController, buildAlramList, searchAlram,
                        noDataWidget: Center(
                          child: Padding(
                            padding: const EdgeInsets.all(40.0),
                            child: Text('전체 알람이 꺼져있습니다.', style: SaText.body),
                          ),
                        )),
                    // 기상특보 알림 범위는 맨 아래 '기상특보 알림' 토글과 함께 배치(혼동 방지).
                    const Gap(20),
                    buildWarnScope(),
                    const Gap(40),
                  ],
                );
              }),
        ]),
      ),
    );
  }

  // 고객 전체 알람설정
  Widget buildItem() {
    return _card(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              PhosphorIcon(
                PhosphorIconsBold.bellRinging,
                color: SaColors.textSecondary,
                size: 27,
              ),
              const Gap(7),
              Text("알람설정", style: SaText.titleS),
              const Spacer(),
              Transform.scale(
                scale: 0.8,
                child: ValueListenableBuilder<bool?>(
                    valueListenable: isCheckedPush,
                    builder: (context, value, child) {
                      Lo.g('isCheckedPush.value : $value');
                      if (isCheckedPush.value == null) return const SizedBox.shrink();
                      // 스위치 on 색은 OS 관례(iOS 초록)라 SaColors로 치환하지 않고 원본 유지.
                      return CupertinoSwitch(
                        value: isCheckedPush.value ?? false,
                        activeTrackColor: CupertinoColors.activeGreen,
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
          const Gap(6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2.0, vertical: 0.0),
            child: Text("개인별 설정은 내정보 > 팔로잉 갯수 > 팔로잉 리스트에서 설정이 가능합니다.", style: SaText.caption),
          ),
        ],
      ),
    );
  }

  // 기상특보 알림 범위 세그먼트(전체/관심지역만) — 기본 전체.
  // 기상특보 알림이 꺼져 있으면(warnAlarmOn=false) 딤 처리 + 터치 차단.
  Widget buildWarnScope() {
    return ValueListenableBuilder<bool>(
      valueListenable: warnAlarmOn,
      builder: (context, enabled, _) {
        return Opacity(
          opacity: enabled ? 1.0 : 0.4,
          child: IgnorePointer(
            ignoring: !enabled,
            child: _card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // 섹션 구분 아이콘 — 경고 상태가 아니라 '기상특보' 항목 표시라 중립색 유지.
                      PhosphorIcon(PhosphorIconsBold.warning, color: SaColors.textSecondary, size: 25),
                      const Gap(7),
                      Text("기상특보 알림 범위", style: SaText.titleS),
                    ],
                  ),
                  const Gap(10),
                  ValueListenableBuilder<String>(
                    valueListenable: warnScope,
                    builder: (context, scope, _) {
                      return Row(
                        children: [
                          _scopeChip('전체', 'ALL', scope),
                          const Gap(8),
                          _scopeChip('관심지역만', 'LOCAL', scope),
                        ],
                      );
                    },
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 8, left: 2),
                    child: Text(
                      enabled
                          ? '전체: 모든 지역 특보 수신 · 관심지역만: 등록한 관심지역 특보만 수신'
                          : '기상특보 알림을 켜면 범위를 설정할 수 있어요.',
                      style: SaText.caption,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _scopeChip(String label, String value, String current) {
    final bool selected = current == value;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (current == value) return;
          warnScope.value = value;
          updateWarnScope(value);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 11),
          alignment: Alignment.center,
          // 칩은 pill(999) — 핸드오프 규격
          decoration: BoxDecoration(
            color: selected ? SaColors.accentTeal : SaColors.surfaceElevated,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: selected ? SaColors.accentTeal : SaColors.border),
          ),
          child: Text(label,
              style: SaText.caption.copyWith(
                color: selected ? SaColors.onAccent : SaColors.textSecondary,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              )),
        ),
      ),
    );
  }

  Widget buildAlramList(List<Map<String, String>> list) {
    return _card(
      child: ListView.separated(
        shrinkWrap: true,
        itemCount: list.length,
        padding: EdgeInsets.zero,
        physics: const BouncingScrollPhysics(),
        separatorBuilder: (context, index) => Divider(color: SaColors.border, height: 13, thickness: 1),
        itemBuilder: (BuildContext context, int index) {
          return buildAlramListItem(list[index], list[index]['denyYn'] == 'N' ? ValueNotifier<bool>(true) : ValueNotifier<bool>(false));
        },
      ),
    );
  }

  // Alram Deny 테이블 알람 설정
  Widget buildAlramListItem(Map<String, String> data, ValueNotifier<bool> isChecked) {
    return Container(
      // 카드가 이미 내부 패딩 14를 가지므로 좌우 인셋은 두지 않는다.
      padding: const EdgeInsets.symmetric(
        horizontal: 0.0,
        vertical: 2,
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
              Expanded(
                child: Text(
                  data['alramNm2'] ?? '',
                  style: SaText.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              Transform.scale(
                scale: 0.75,
                // 스위치 on 색(주황)은 항목 구분용이라 SaColors로 치환하지 않고 원본 유지.
                child: CupertinoSwitch(
                  value: isChecked.value,
                  activeTrackColor: CupertinoColors.activeOrange,
                  onChanged: (bool value) {
                    if (value) {
                      deleteAlram(data['alramCd'].toString());
                    } else {
                      addAlram(data['alramCd'].toString());
                    }

                    data['denyYn'] = value ? 'N' : 'Y';
                    isChecked.value = !value;
                    // 기상특보(10) 토글이면 범위 선택 활성/비활성 갱신.
                    if (data['alramCd'].toString() == '10') warnAlarmOn.value = value;
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
