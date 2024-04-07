// import 'dart:async';

// import 'package:bot_toast/bot_toast.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/widgets.dart';
// import 'package:gap/gap.dart';
// import 'package:get/get.dart';
// import 'package:project1/repo/common/res_stream.dart';


// class MoNotiPage extends StatefulWidget {
//   const MoNotiPage({super.key});

//   @override
//   State<MoNotiPage> createState() => _MoNotiPageState();
// }

// class _MoNotiPageState extends State<MoNotiPage> {
//   final formKey = GlobalKey<FormState>();

//   // 스크롤 컨트롤러
//   ScrollController scrollCtrl = ScrollController();

//   // 데이터 스크림
//   final StreamController<ResStream<List<BoardResDetailData>>> listCtrl = StreamController();

//   List<BoardResDetailData> boardList = [];

//   String ptupDsc = 'NOTI';
//   String ptupTrgtDsc = 'NOTI';
//   late int page = 0;
//   int pageSzie = 8;
//   String topYn = 'N';

//   // bool isLastPage = false;
//   final ValueNotifier<bool> isLastPage = ValueNotifier<bool>(false);
//   final ValueNotifier<bool> isMoreLoading = ValueNotifier<bool>(false);

//   @override
//   initState() {
//     super.initState();
//     getData(0);
//     scrollCtrl.addListener(() {
//       //  Lo.g("${scrollCtrl.position.pixels} == ${scrollCtrl.position.maxScrollExtent}");

//       if (scrollCtrl.position.pixels == scrollCtrl.position.maxScrollExtent) {
//         if (!isLastPage.value) {
//           getMoreData(page);
//         }
//       }
//     });
//   }

//   Future<void> getMoreData(int _page) async {
//     isMoreLoading.value = true;
//     page++;
//     BoardRepo repo = BoardRepo();
//     BoardReqData reqData = BoardReqData();
//     reqData.ptupDsc = ptupDsc;
//     reqData.ptupTrgtDsc = ptupTrgtDsc;
//     reqData.searchWord = '';
//     reqData.topYn = topYn;
//     reqData.page = page;
//     reqData.pageSize = pageSzie;
//     ResData resData = await repo.searchList(reqData);

//     if (resData.code != '00') {
//       isMoreLoading.value = false;
//       return;
//     }

//     BoardResData boardResData = BoardResData.fromMap(resData.data);
//     page = boardResData.pageData!.currPageNum!;
//     isLastPage.value = boardResData.pageData!.last!;

//     boardList.addAll(boardResData.list!);
//     listCtrl.sink.add(ResStream.completed(boardList, message: '조회가 완료되었습니다.'));
//     isMoreLoading.value = false;
//   }

//   Future<void> getDataInit() async => getData(1);

//   Future<void> getData(int _page) async {
//     try {
//       listCtrl.sink.add(ResStream.loading());
//       BoardRepo repo = BoardRepo();
//       BoardReqData reqData = BoardReqData();
//       reqData.ptupDsc = ptupDsc;
//       reqData.ptupTrgtDsc = ptupTrgtDsc;
//       reqData.searchWord = '';
//       reqData.topYn = topYn;
//       reqData.page = _page;
//       reqData.pageSize = pageSzie;

//       ResData resData = await repo.searchList(reqData);

//       if (resData.code != '00') {
//         Utils.alert(resData.msg.toString());
//         listCtrl.sink.add(ResStream.error(resData.msg.toString()));
//         return;
//       }

//       BoardResData boardResData = BoardResData.fromMap(resData.data);
//       page = boardResData.pageData!.currPageNum!;
//       isLastPage.value = boardResData.pageData!.last!;

//       boardList = boardResData.list!;
//       listCtrl.sink.add(ResStream.completed(boardList, message: '조회가 완료되었습니다.'));
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
//         title: Text('공지사항', style: KosStyle.headingH3),
//         centerTitle: true,
//         elevation: 0,
//       ),
//       backgroundColor: Colors.white,
//       body: RefreshIndicator(
//         onRefresh: () async => await getData(1),
//         child: SingleChildScrollView(
//           controller: scrollCtrl,
//           padding: const EdgeInsets.symmetric(horizontal: 16.0),
//           child: Column(children: [
//             const Gap(24),
//             // 공통 스트림 빌더
//             Utils.commonStreamList<BoardResDetailData>(listCtrl, buildList, getDataInit),
//             const Gap(30),
//           ]),
//         ),
//       ),
//     );
//   }

//   // 공지사항 리스트
//   Widget buildList(List<BoardResDetailData> list) {
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
//               return buildItem(list[index]);
//             },
//           ),
//           ValueListenableBuilder<bool>(
//               valueListenable: isMoreLoading,
//               builder: (context, val, snapshot) {
//                 if (val) {
//                   return Utils.progressbar();
//                 } else {
//                   return SizedBox.shrink();
//                 }
//               }),
//           if (!isLastPage.value) ...[
//             const Gap(10),
//             Text('가져오는 중....', style: KosStyle.styleB1SemanticGray13),
//           ]
//         ],
//       ),
//     );
//   }

// // 공지사항 아이템
//   Widget buildItem(BoardResDetailData data) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 3),
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
//               shadowColor: Colors.transparent,
//               // fixedSize: Size(0, 0),
//               minimumSize: Size.zero, // Set this
//               padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
//               tapTargetSize: MaterialTapTargetSize.shrinkWrap,
//               visualDensity: const VisualDensity(horizontal: 0, vertical: 0),
//               elevation: 0,
//               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
//               backgroundColor: Colors.transparent,
//             ),
//             onPressed: () => Get.toNamed('/MoNotiViewPage', arguments: {'seq': data.ptupSeq.toString()}),
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.start,
//               //   crossAxisAlignment: CrossAxisAlignment.center,
//               children: [
//                 Column(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Row(
//                       mainAxisAlignment: MainAxisAlignment.start,
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         if (data.topYn == 'Y') ...[
//                           CustomBadge(
//                             text: 'Top',
//                             bgColor: Colors.red[700],
//                           ),
//                           const Gap(5),
//                         ],
//                         if (data.newYn == 'Y') ...[
//                           CustomBadge(
//                             text: 'New',
//                             bgColor: Colors.blue,
//                           ),
//                           const Gap(5),
//                         ],
//                         Text(
//                           data.ptupTtl.toString(),
//                           softWrap: true,
//                           overflow: TextOverflow.fade,
//                           style: KosStyle.heading14,
//                         ),
//                         const Gap(6),
//                         // const Align(alignment: Alignment.centerRight, child: Icon(Icons.new_label_sharp, size: 14, color: Colors.red)),
//                       ],
//                     ),
//                     const Gap(10),
//                     Text(
//                       '${data.ptupDt.toString().substring(0, 4)}.${data.ptupDt.toString().substring(4, 6)}.${data.ptupDt.toString().substring(6, 8)}',
//                       style: KosStyle.styleB1SemanticGray13,
//                     ),
//                   ],
//                 ),
//                 const Spacer(),
//                 Icon(Icons.arrow_forward_ios, size: 19, color: Colors.grey[400]),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
