// import 'dart:async';

// import 'package:bot_toast/bot_toast.dart';
// import 'package:flutter/material.dart';
// import 'package:gap/gap.dart';
// import 'package:get/get.dart';
// import 'package:intl/intl.dart';
// import 'package:permission_handler/permission_handler.dart';
// import 'package:project1/repo/alram/alram_repo.dart';
// import 'package:project1/repo/alram/data/alram_res_data.dart';
// import 'package:project1/repo/common/res_data.dart';
// import 'package:project1/repo/common/res_stream.dart';
// import 'package:project1/utils/log_utils.dart';
// import 'package:project1/utils/utils.dart';

// class MoAlramPage extends StatefulWidget {
//   const MoAlramPage({super.key});

//   @override
//   State<MoAlramPage> createState() => _MoAlramPageState();
// }

// class _MoAlramPageState extends State<MoAlramPage> with WidgetsBindingObserver {
//   final formKey = GlobalKey<FormState>();

//   final List<AppLifecycleState> stateHistoryList = <AppLifecycleState>[];
//   final ValueNotifier<bool> isPermisstion = ValueNotifier<bool>(false);

//   final StreamController<ResStream<List<AlramResData>>> listCtrl = StreamController();

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
//     var requestStatusCamera = await Permission.camera.request();
//     var requestStatusMicrophone = await Permission.microphone.request();
//     var requestStatusStorage = await Permission.storage.request();
//     var requestStatus = await Permission.location.request();
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

//   Future<void> getData({String? tpltGbCd}) async {
//     try {
//       listCtrl.sink.add(ResStream.loading());
//       AlramRepo repo = AlramRepo();
//       int days = 30;
//       ResData resData = await repo.searchuserhistlst(days, tpltGbCd ?? 'P');

//       if (resData.code != '00') {
//         Utils.alert(resData.msg.toString());
//         listCtrl.sink.add(ResStream.error(resData.msg.toString()));
//         return;
//       }
//       lo.g(resData.toString());

//       AlramResPageData result = AlramResPageData.fromMap(resData.data);
//       // lo.g(result.almLst[0]));
//       // List<AlramResData> list = (result.almLst as List).map((data) => AlramResData.fromMap(data)).toList();
//       listCtrl.sink.add(ResStream.completed(result.almLst, message: '조회가 완료되었습니다.'));
//     } catch (e) {
//       listCtrl.sink.add(ResStream.error(e.toString()));
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back_ios),
//           onPressed: () => Navigator.pop(context),
//         ),
//         title: Text('알림', style: KosStyle.headingH3),
//         centerTitle: true,
//         elevation: 0,
//       ),
//       backgroundColor: Colors.white,
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.symmetric(horizontal: 16.0),
//         child: Column(children: [
//           const Gap(10),
//           ValueListenableBuilder<bool>(
//               valueListenable: isPermisstion,
//               builder: (context, val, snapshot) {
//                 lo.g('val : $val');
//                 if (val) {
//                   return const SizedBox.shrink();
//                 }
//                 return Container(
//                   padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 0),
//                   decoration: BoxDecoration(
//                     color: Colors.grey[100],
//                     borderRadius: BorderRadius.circular(20),
//                   ),
//                   child: Row(children: [
//                     Text('기기 알림이 꺼져있습니다', style: KosStyle.styleB1SemanticGray13),
//                     const Spacer(),
//                     TextButton(
//                       onPressed: () => Get.toNamed('/MoAlramSettingPage'),
//                       child: const Text('알림 켜기', style: TextStyle(color: C.mainOrange500, fontWeight: FontWeight.bold)),
//                     ),
//                   ]),
//                 );
//               }),
//           const Gap(15),

//           //   Padding(
//           //     padding: const EdgeInsets.symmetric(vertical: 17),
//           //     child: const Divider(),
//           //   ),
//           Utils.commonStreamList<AlramResData>(listCtrl, buildList, getData),
//         ]),
//       ),
//     );
//   }

//   // 공지사항 리스트
//   Widget buildList(List<AlramResData> list) {
//     return SizedBox(
//       width: double.infinity,
//       //   height: 322,
//       //padding: const EdgeInsets.all(20),
//       child: ListView.builder(
//         shrinkWrap: true,
//         itemCount: list.length,
//         physics: const BouncingScrollPhysics(),
//         itemBuilder: (BuildContext context, int index) {
//           return buildItem(list[index]);
//         },
//       ),
//     );
//   }

// // 공지사항 아이템
//   Widget buildItem(AlramResData data) {
//     // final int millisecondsSinceEpoch = int.parse(data.sndDtm.toString());
//     // final DateTime dateTime = DateTime.fromMillisecondsSinceEpoch(millisecondsSinceEpoch);
//     final dateTime = DateTime.parse(data.sndDtm.toString());
//     final format = DateFormat('yyyy/MM/dd HH:mm');
//     // print(format.format(dateTime)); // 2021-08-11 11:38
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 1),
//       child: Column(
//         children: [
//           Divider(
//             height: 1,
//             thickness: 1,
//             color: Colors.grey[300],
//           ),
//           const Gap(10),
//           ElevatedButton(
//             clipBehavior: Clip.none,
//             style: ElevatedButton.styleFrom(
//               shadowColor: Colors.grey[300],
//               // fixedSize: Size(0, 0),
//               minimumSize: Size.zero, // Set this
//               padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
//               tapTargetSize: MaterialTapTargetSize.shrinkWrap,
//               visualDensity: const VisualDensity(horizontal: 0, vertical: 0),
//               elevation: 0,
//               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
//               backgroundColor: Colors.white,
//             ),
//             onPressed: () => lo.g('data.msgNo'),
//             child: Container(
//               color: Colors.white,
//               padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 6),
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: [
//                       Row(
//                         mainAxisAlignment: MainAxisAlignment.start,
//                         children: [
//                           CustomBadge(text: data.tpltCntsKndGbNm.toString(), onPressed: () {}),
//                           const Gap(4),
//                           Text(
//                             data.msgTitle.toString(),
//                             softWrap: true,
//                             overflow: TextOverflow.fade,
//                             style: KosStyle.heading14,
//                           ),
//                         ],
//                       ),
//                       Text(
//                         format.format(dateTime),
//                         style: KosStyle.styleB1SemanticGray11,
//                       ),
//                     ],
//                   ),
//                   const Gap(10),
//                   Text(
//                     data.msgTransCnts.toString(),
//                     style: KosStyle.styleB1SemanticGray13,
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
