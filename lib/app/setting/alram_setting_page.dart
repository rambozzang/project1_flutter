// import 'dart:async';

// import 'package:bot_toast/bot_toast.dart';
// import 'package:flutter/cupertino.dart';
// import 'package:flutter/material.dart';
// import 'package:gap/gap.dart';

// import 'package:permission_handler/permission_handler.dart';
// import 'package:project1/repo/alram/alram_repo.dart';
// import 'package:project1/repo/common/res_data.dart';
// import 'package:project1/repo/common/res_stream.dart';
// import 'package:project1/utils/log_utils.dart';
// import 'package:project1/utils/utils.dart';

// class AlramSettingPage extends StatefulWidget {
//   const AlramSettingPage({super.key});

//   @override
//   State<AlramSettingPage> createState() => _AlramSettingPageState();
// }

// class _AlramSettingPageState extends State<AlramSettingPage> with WidgetsBindingObserver {
//   final formKey = GlobalKey<FormState>();

//   final ValueNotifier<bool> isPermisstion = ValueNotifier<bool>(false);

//   final ValueNotifier<Map<String, bool>> isCheckedPush = ValueNotifier<Map<String, bool>>({});
//   final ValueNotifier<Map<String, bool>> isCheckedAlim = ValueNotifier<Map<String, bool>>({});

//   // final StreamController<ResStream<List<AlramSettingResData>>> listCtrl = StreamController();

//   String? tpltGbCd_check_nm;

//   final List<AppLifecycleState> stateHistoryList = <AppLifecycleState>[];

//   @override
//   initState() {
//     super.initState();

//     getData();

//     checkPermission();

//     WidgetsBinding.instance.addObserver(this);
//     if (WidgetsBinding.instance.lifecycleState != null) {
//       stateHistoryList.add(WidgetsBinding.instance.lifecycleState!);
//     }
//   }

//   @override
//   void didChangeAppLifecycleState(AppLifecycleState state) {
//     checkPermission();
//   }

//   /*
//  isGranted - 권한 동의 상태 시 true
//   isLimited - 권한이 제한적으로 동의 상태 시 true (ios 14버전 이상)
//   isPermanentlyDeined - 영구적으로 권한 거부 상태 시 true (android 전용, 다시 묻지 않음)
//   Permission.location.status는 영구 거부 해도 denied 반환
//   openAppSettings() - 앱 설정 화면으로 이동
//   isRestricted - 권한 요청을 표시하지 않도록 선택 시 true (ios 전용)
//   isDenied - 권한 거부 상태 시 ture
//  */
//   Future<void> checkPermission() async {
//     var requestStatus = await Permission.notification.request();
//     var status = await Permission.notification.status;
//     // if (requestStatus.isGranted && status.isLimited) {
//     if (requestStatus.isGranted) {
//       // isLimited - 제한적 동의 (ios 14 < )
//       // 요청 동의됨
//       lo.g("isGranted");
//       isPermisstion.value = true;
//     } else if (requestStatus.isPermanentlyDenied || status.isPermanentlyDenied) {
//       // 권한 요청 거부, 해당 권한에 대한 요청에 대해 다시 묻지 않음 선택하여 설정화면에서 변경해야함. android
//       lo.g("isPermanentlyDenied");
//       // openAppSettings();
//       isPermisstion.value = false;
//     } else if (status.isRestricted) {
//       // 권한 요청 거부, 해당 권한에 대한 요청을 표시하지 않도록 선택하여 설정화면에서 변경해야함. ios
//       lo.g("isRestricted");
//       //  openAppSettings();
//       isPermisstion.value = false;
//     } else if (status.isDenied) {
//       // 권한 요청 거절
//       lo.g("isDenied");
//       isPermisstion.value = false;
//     }
//     lo.g("requestStatus ${requestStatus.name}");
//     lo.g("status ${status.name}");
//   }

//   Future<void> request(context) async {
//     Utils.showConfirmDialog('알림 설정을 변경 하시겠습니까?', '알림 설정을 변경 하시겠습니까?', BackButtonBehavior.none, cancel: () {}, confirm: () async {
//       openAppSettings();
//     }, backgroundReturn: () {
//       checkPermission();
//     });
//   }

//   Future<void> getData() async {
//     // try {
//     //   listCtrl.sink.add(ResStream.loading());
//     //   AlramRepo repo = AlramRepo();
//     //   ResData resData = await repo.searchnotiflst();

//     //   if (resData.code != '00') {
//     //     Utils.alert(resData.msg.toString());
//     //     listCtrl.sink.add(ResStream.error(resData.msg.toString()));
//     //     return;
//     //   }

//     //   List<AlramSettingResData> list = ((resData.data) as List).map((data) => AlramSettingResData.fromMap(data)).toList();
//     //   listCtrl.sink.add(ResStream.completed(list, message: '조회가 완료되었습니다.'));
//     // } catch (e) {
//     //   listCtrl.sink.add(ResStream.error(e.toString()));
//     // }
//   }

//   // Update
//   Future<void> updateAlramSetting(String tpltGbCd, String tpltCntsKndGbCd, String almYn) async {
//     // try {
//     //   AlramRepo repo = AlramRepo();
//     //   ResData resData = await repo.modifynotif(tpltGbCd, tpltCntsKndGbCd, almYn);

//     //   if (resData.code != '00') {
//     //     Utils.alert(resData.msg.toString());
//     //     return;
//     //   }
//     // } catch (e) {
//     //   Utils.alert(e.toString());
//     // }
//   }

//   Future<void> allCheck() async {
//     // isPermisstion.value = !isPermisstion.value;
//     // AlramRepo repo = AlramRepo();
//     // ResData resData = await repo.modifyallnotif(isPermisstion.value ? 'Y' : 'N');

//     // // /notif/modifyallnotif
//     // if (resData.code != '00') {
//     //   Utils.alert(resData.msg.toString());
//     //   return;
//     // }
//     getData();

//     // if (isPermisstion.value) {
//     //   for (var key in isCheckedPush.value.keys) {
//     //     isCheckedPush.value[key] = true;
//     //   }
//     //   for (var key in isCheckedAlim.value.keys) {
//     //     isCheckedAlim.value[key] = true;
//     //   }
//     // } else {
//     //   for (var key in isCheckedPush.value.keys) {
//     //     isCheckedPush.value[key] = false;
//     //   }
//     //   for (var key in isCheckedAlim.value.keys) {
//     //     isCheckedAlim.value[key] = false;
//     //   }
//     // }
//     // setState(() {});
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back_ios),
//           onPressed: () => Navigator.pop(context),
//         ),
//         title: const Text('알림 설정', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
//         centerTitle: true,
//         elevation: 0,
//       ),
//       backgroundColor: Colors.white,
//       body: SingleChildScrollView(
//         // padding: const EdgeInsets.symmetric(horizontal: 16.0),
//         child: Column(children: [
//           Padding(
//             padding: const EdgeInsets.symmetric(
//               horizontal: 16.0,
//             ),
//             child: Container(
//                 //       height: 60.h,
//                 width: double.infinity,
//                 padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10),
//                 decoration: BoxDecoration(
//                   borderRadius: BorderRadius.circular(10),
//                 ),
//                 child: const Text(
//                   '알림을 끄시면 해당 휴대폰 알림은 발송되지 않지만 앱내 알림 화면에서는 확인 가능합니다.',
//                   style:  TextStyle(
//                     color: Colors.black,
//                     fontSize: 14,
//                     fontWeight: FontWeight.bold
//                 ))),
//           ),
//           const Gap(20),
//           ValueListenableBuilder<bool>(
//               valueListenable: isPermisstion,
//               builder: (context, val, snapshot) {
//                 lo.g('val : $val');
//                 if (val) {
//                   return const SizedBox.shrink();
//                 }
//                 return Container(
//                   height: 60.h,
//                   padding: const EdgeInsets.symmetric(
//                     horizontal: 16.0,
//                   ),
//                   child: Column(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Row(
//                         mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                         children: [
//                           Text(
//                             '기기 알림이 꺼져있습니다.',
//                             style: TextStyle(
//                     color: Colors.black,
//                     fontSize: 18,
//                     fontWeight: FontWeight.bold
//                 ),
//                           ),
//                           const Spacer(),
//                           TextButton(
//                             onPressed: () => request(context),
//                             child: Text(val ? '끄기' : '껴기', style: const TextStyle(color: C.mainOrange500, fontWeight: FontWeight.bold)),
//                           ),
//                           // const Gap(5),
//                           // const Icon(
//                           //   Icons.arrow_forward_ios,
//                           //   size: 19,
//                           // ),
//                         ],
//                       ),
//                     ],
//                   ),
//                 );
//               }),

//           Utils.commonStreamList<>(listCtrl, buildBody, getData),
//           //buildBody()
//         ]),
//       ),
//     );
//   }

//   Widget buildBody(List<AlramSettingResData> list) {
//     return SizedBox(
//       width: double.infinity,
//       //   height: 322,
//       //padding: const EdgeInsets.all(20),
//       child: Column(
//         children: [
//           ListView.builder(
//             shrinkWrap: true,
//             itemCount: list.length,
//             physics: const BouncingScrollPhysics(),
//             itemBuilder: (BuildContext context, int index) {
//               // return buildItem(list[index]);
//               var data = list[index];
//               return buildItem(data.tpltGbCd.toString(), data.tpltCntsKndGbCd.toString(), data.tpltTtl.toString(),
//                   data.tpltSubTtl.toString(), data.almYn == 'Y' ? ValueNotifier<bool>(true) : ValueNotifier<bool>(false));
//             },
//           ),
//         ],
//       ),
//     );
//   }

//   Widget buildItem(String tpltGbCd, String tpltCntsKndGbCd, String title, String subTitle, ValueNotifier<bool> isChecked) {
//     String tpltGbNm = tpltGbCd == 'K' ? '알림톡(카카오톡)' : 'Push 알림';
//     // 푸쉬 알림톡 제목 표시 여부 판단
//     tpltGbCd_check_nm = tpltGbCd_check_nm == '' || tpltGbCd_check_nm == tpltGbCd ? tpltGbCd : '';

//     return Container(
//       // height: 70,
//       padding: const EdgeInsets.symmetric(
//         horizontal: 16.0,
//         vertical: 10,
//       ),
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           if (tpltGbCd_check_nm == '') ...[
//             const Gap(15),
//             Stack(
//               children: [
//                 // Positioned(
//                 //     bottom: 4, child: Container(color: C.mainOrange300, height: 7, width: 400, margin: const EdgeInsets.only(top: 30))),
//                 Text(
//                   tpltGbNm,
//                   style: TextStyle(
//                     color: Colors.black,
//                     fontSize: 14,
//                     fontWeight: FontWeight.bold
//                 )
//                 ),
//               ],
//             ),
//             const Gap(10),
//           ],
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//             children: [
//               const Icon(
//                 Icons.notifications,
//                 color: Colors.purple,
//                 size: 27,
//               ),
//               const Gap(7),
//               Text(
//                 title,
//                 style:  TextStyle(
//                     color: Colors.black,
//                     fontSize: 14,
//                     fontWeight: FontWeight.bold
//                 )
//               ),
//               const Spacer(),
//               Transform.scale(
//                 scale: 0.8,
//                 child: ValueListenableBuilder<Map<String, bool>>(
//                     valueListenable: tpltGbCd == 'P' ? isCheckedPush : isCheckedAlim,
//                     builder: (context, value, child) {
//                       return CupertinoSwitch(
//                         value: (tpltGbCd == 'P' ? isCheckedPush.value[tpltCntsKndGbCd] : isCheckedAlim.value[tpltCntsKndGbCd]) ??
//                             isChecked.value,
//                         activeColor: CupertinoColors.activeOrange,
//                         onChanged: (bool value) {
//                           Lo.g('value : $value');
//                           if (tpltGbCd == 'P') {
//                             isCheckedPush.value[tpltCntsKndGbCd] = value;
//                           } else {
//                             isCheckedAlim.value[tpltCntsKndGbCd] = value;
//                           }
//                           updateAlramSetting(tpltGbCd, tpltCntsKndGbCd, value ? 'Y' : 'N');
//                           setState(() {});
//                         },
//                       );
//                     }),
//               ),
//             ],
//           ),
//           Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 0.0),
//             child: Text(
//               subTitle == 'null' ? '' : subTitle,
//               style:  TextStyle(
//                     color: Colors.black,
//                     fontSize: 14,
//                     fontWeight: FontWeight.bold
//                 )
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   // Widget buildBody2(List<AlramResData> list) {
//   //   return Container(
//   //     child: Column(
//   //       children: [
//   //         const Gap(20),
//   //         Padding(
//   //           padding: const EdgeInsets.symmetric(
//   //             horizontal: 16.0,
//   //           ),
//   //           child: Container(
//   //               //       height: 60.h,
//   //               width: double.infinity,
//   //               padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10),
//   //               decoration: BoxDecoration(
//   //                 borderRadius: BorderRadius.circular(10),
//   //                 color: C.semanticGrayTabBg,
//   //               ),
//   //               child: Text(
//   //                 '알림을 끄시면 해당 휴대폰 알림은 발송되지 않지만 앱내 알림 화면에서는 확인 가능합니다.',
//   //                 style: KosStyle.styleB1SemanticGray14,
//   //               )),
//   //         ),
//   //         const Gap(20),
//   //         Container(
//   //           height: 60.h,
//   //           padding: const EdgeInsets.symmetric(
//   //             horizontal: 16.0,
//   //           ),
//   //           child: Column(
//   //             mainAxisAlignment: MainAxisAlignment.center,
//   //             crossAxisAlignment: CrossAxisAlignment.start,
//   //             children: [
//   //               Row(
//   //                 mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//   //                 children: [
//   //                   Text(
//   //                     '기기 알림이 꺼져있습니다.',
//   //                     style: KosStyle.bodyblack18,
//   //                   ),
//   //                   const Spacer(),
//   //                   TextButton(
//   //                     onPressed: () => allCheck(),
//   //                     child: ValueListenableBuilder<bool>(
//   //                         valueListenable: isPermisstion,
//   //                         builder: (context, val, snapshot) {
//   //                           return Text(val ? '끄기' : '껴기', style: TextStyle(color: C.mainOrange500, fontWeight: FontWeight.bold));
//   //                         }),
//   //                   ),
//   //                   // const Gap(5),
//   //                   // const Icon(
//   //                   //   Icons.arrow_forward_ios,
//   //                   //   size: 19,
//   //                   // ),
//   //                 ],
//   //               ),
//   //             ],
//   //           ),
//   //         ),
//   //         buildList(),
//   //         Container(
//   //           height: 60.h,
//   //           padding: const EdgeInsets.symmetric(
//   //             horizontal: 16.0,
//   //           ),
//   //           child: Column(
//   //             mainAxisAlignment: MainAxisAlignment.center,
//   //             crossAxisAlignment: CrossAxisAlignment.start,
//   //             children: [
//   //               Row(
//   //                 mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//   //                 children: [
//   //                   Text(
//   //                     '마케팅 목적 개인정보 활용 동의',
//   //                     style: KosStyle.bodyB4,
//   //                   ),
//   //                   const Spacer(),
//   //                   const Icon(
//   //                     Icons.arrow_forward_ios,
//   //                     size: 15,
//   //                   ),
//   //                 ],
//   //               ),
//   //             ],
//   //           ),
//   //         ),
//   //       ],
//   //     ),
//   //   );
//   // }

//   // Widget buildList() {
//   //   return Column(
//   //     children: [
//   //       const Gap(20),
//   //       buildItem('업무 알림', '진행중인 업무와 관련된 중요한 알림을 알려드립니다.', isChecked01),
//   //       buildItem('사건등록 알림', '협약지점·관심지역 사건에 대한 정보를 알려드립니다.', isChecked02),
//   //       const Gap(20),
//   //       const Divider(
//   //         height: 1,
//   //         thickness: 10,
//   //         color: C.semanticGrayTabBg,
//   //       ),
//   //       const Gap(20),
//   //       buildItem('혜택*마케팅 알림', '다양한 혜택 및 마케팅 알림을 받을 수 있습니다. 업무 관련 알림 수신과는 무관합니다.', isChecked03),
//   //       const Gap(20),
//   //     ],
//   //   );
//   // }
// }
