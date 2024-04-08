// import 'dart:async';

// import 'package:flutter/material.dart';
// import 'package:gap/gap.dart';
// import 'package:get/get.dart';
// import 'package:project1/repo/common/res_stream.dart';

// class MoOpenSourcePage extends StatefulWidget {
//   const MoOpenSourcePage({super.key});

//   @override
//   State<MoOpenSourcePage> createState() => _MoOpenSourcePageState();
// }

// class _MoOpenSourcePageState extends State<MoOpenSourcePage> {
//   final formKey = GlobalKey<FormState>();

//   final StreamController<ResStream<List<BoardResDetailData>>> listCtrl = StreamController();

//   List<BoardResDetailData> boardList = [];

//   String ptupDsc = 'OPEN';
//   String ptupTrgtDsc = 'OPEN';
//   int page = 0;
//   int pageSzie = 20;
//   String topYn = 'N';

//   @override
//   initState() {
//     super.initState();
//     getData();
//   }

//   Future<void> getData() async {
//     try {
//       listCtrl.sink.add(ResStream.loading());
//       BoardRepo repo = BoardRepo();
//       BoardReqData reqData = BoardReqData();
//       reqData.ptupDsc = ptupDsc;
//       reqData.ptupTrgtDsc = ptupTrgtDsc;
//       reqData.searchWord = '';
//       reqData.topYn = topYn;
//       reqData.page = page;
//       reqData.pageSize = pageSzie;

//       ResData resData = await repo.searchList(reqData);

//       if (resData.code != '00') {
//         Utils.alert(resData.msg.toString());
//         listCtrl.sink.add(ResStream.error(resData.msg.toString()));
//         return;
//       }

//       BoardResData boardResData = BoardResData.fromMap(resData.data);

//       boardList = boardResData.list!;
//       listCtrl.sink.add(ResStream.completed(boardList, message: '조회가 완료되었습니다.'));
//     } catch (e) {
//       listCtrl.sink.add(ResStream.error(e.toString()));
//     }
//   }

//   @override
//   void dispose() {
//     listCtrl.close();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back_ios),
//           onPressed: () => Navigator.pop(context),
//         ),
//         title: Text('오픈소스 라이센스', style: KosStyle.headingH3),
//         centerTitle: true,
//         elevation: 0,
//       ),
//       backgroundColor: Colors.white,
//       body: SingleChildScrollView(
//         physics: const BouncingScrollPhysics(),
//         child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
//           const Gap(10),
//           Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 16.0),
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 const Gap(24),
//                 // 공통 스트림 빌더
//                 Utils.commonStreamList<BoardResDetailData>(listCtrl, buildList, getData),
//                 const Gap(200),
//               ],
//             ),
//           ),
//           const Gap(300),
//         ]),
//       ),
//     );
//   }

// // 오픈 소스 리스트
//   Widget buildList(List<BoardResDetailData> list) {
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

// // 오픈 소스 리스트
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
//               shadowColor: Colors.grey[50],
//               // fixedSize: Size(0, 0),
//               minimumSize: Size.zero, // Set this
//               padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
//               tapTargetSize: MaterialTapTargetSize.shrinkWrap,
//               visualDensity: const VisualDensity(horizontal: 0, vertical: 0),
//               elevation: 0,
//               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
//               backgroundColor: Colors.grey[200],
//             ),
//             onPressed: () => lo.g('data.ptupSeq'),
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
//                         Text(
//                           data.ptupTtl.toString(),
//                           softWrap: true,
//                           overflow: TextOverflow.fade,
//                           style: KosStyle.heading14,
//                         ),
//                         const Gap(6),
//                       ],
//                     ),
//                     const Gap(10),
//                     Text(
//                       '출처 : Google inc.',
//                       style: KosStyle.styleB1SemanticGray13,
//                     ),
//                   ],
//                 ),
//                 const Spacer(),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
