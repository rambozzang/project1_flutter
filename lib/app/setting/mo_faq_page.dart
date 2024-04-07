// import 'dart:async';

// import 'package:flutter/material.dart';
// import 'package:gap/gap.dart';
// import 'package:get/get.dart';
// import 'package:project1/repo/common/res_stream.dart';
// import 'package:project1/utils/utils.dart';

// class MoFaqPage extends StatefulWidget {
//   const MoFaqPage({super.key});

//   @override
//   State<MoFaqPage> createState() => _MoFaqPageState();
// }

// class _MoFaqPageState extends State<MoFaqPage> {
//   final formKey = GlobalKey<FormState>();

//   TextEditingController controller = TextEditingController();

//   List<String> badgeList = ['TOP10', '사건수임', '견적서', '사전정보', '보험가입', '지급정보', '대출금', '상환말소', '접수번호', '서류등록', '회원정보', '기타'];
//   // List<Map<String, dynamic>> badgeList2 = [
//   //   {'name': 'TOP10', 'value': 'TOP10'},
//   //   {'name': '사건수임', 'value': '사건수임'},
//   //   {'name': '견적서', 'value': '견적서'},
//   //   {'name': '사전정보', 'value': '사전정보'},
//   //   {'name': '보험가입', 'value': '보험가입'},
//   //   {'name': '지급정보', 'value': '지급정보'},
//   //   {'name': '대출금', 'value': '대출금'},
//   //   {'name': '상환말소', 'value': '상환말소'},
//   //   {'name': '접수번호', 'value': '접수번호'},
//   //   {'name': '서류등록', 'value': '서류등록'},
//   //   {'name': '회원정보', 'value': '회원정보'},
//   //   {'name': '기타', 'value': '기타'},
//   // ];
//   late List<SearchCommCodeRes> badgeList2 = [];

//   final StreamController<ResStream<List<SearchCommCodeRes>>> codeCtrl = StreamController();
//   final StreamController<ResStream<List<BoardResDetailData>>> listCtrl = StreamController();

//   List<BoardResDetailData> boardList = [];

//   // 뱃지 선택 리스트
//   final ValueNotifier<List<String>> badgeSelectedList = ValueNotifier<List<String>>(['']);
// //   final ValueNotifier<List<String>> badgeSelectedList = ValueNotifier(<String>[]);

//   String ptupDsc = 'FAQ';
//   String ptupTrgtDsc = '';
//   int page = 0;
//   int pageSzie = 2000;
//   String topYn = 'N';

//   @override
//   initState() {
//     super.initState();
//     getCodeData();
//     getData();
//   }

//   Future<void> getCodeData() async {
//     try {
//       SearchCommCodeReq inVo = SearchCommCodeReq();
//       inVo.grpCd = 'FAQ_GB';
//       inVo.useYn = 'Y';
//       ResData resData = await CommRepo().searchCommCode(inVo);
//       if (resData.code != '00') {
//         Utils.alert(resData.msg.toString());
//         return;
//       }
//       badgeList2 = ((resData.data) as List).map((data) => SearchCommCodeRes.fromMap(data)).toList();
//       Lo.g('other:' + badgeList2.toString());
//       codeCtrl.sink.add(ResStream.completed(badgeList2, message: '조회가 완료되었습니다.'));
//     } catch (e) {}
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

//       boardList = boardResData.list!; // ((resData.data) as List).map((data) => SearchPostListRes.fromMap(data)).toList();
//       listCtrl.sink.add(ResStream.completed(boardList, message: '조회가 완료되었습니다.'));
//     } catch (e) {
//       listCtrl.sink.add(ResStream.error(e.toString()));
//     }
//   }

//   Future<void> SearchData(String word) async {
//     try {
//       listCtrl.sink.add(ResStream.loading());
//       BoardRepo repo = BoardRepo();

//       BoardReqData reqData = BoardReqData();
//       reqData.ptupDsc = ptupDsc;
//       reqData.ptupTrgtDsc = ptupTrgtDsc;
//       reqData.searchWord = word;
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

//   Future<void> badgeSearchData(String word) async {
//     try {
//       listCtrl.sink.add(ResStream.loading());
//       BoardRepo repo = BoardRepo();

//       BoardReqData reqData = BoardReqData();

//       reqData.ptupDsc = ptupDsc;
//       reqData.ptupTrgtDsc = word;
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
//     codeCtrl.close();
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
//         title: Text('자주 찾는 질문', style: KosStyle.headingH3),
//         centerTitle: true,
//         elevation: 0,
//       ),
//       backgroundColor: Colors.white,
//       body: SingleChildScrollView(
//         //  padding: const EdgeInsets.symmetric(horizontal: 16.0),
//         child: Column(children: [
//           const Gap(10),
//           buildSearchInputBox(),
//           const Gap(10),
//           buildBadgeList(),
//           const Gap(20),
//           const Divider(
//             height: 1,
//             thickness: 10,
//             color: C.semanticGrayTabBg,
//           ),
//           const Gap(10),
//           Utils.commonStreamList<BoardResDetailData>(listCtrl, buildList, getData),
//         ]),
//       ),
//     );
//   }

//   // 검색창
//   Widget buildSearchInputBox() {
//     return Container(
//         height: 62,
//         width: double.infinity,
//         color: Colors.white,
//         padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
//         child: TextField(
//           controller: controller,
//           textInputAction: TextInputAction.search,
//           decoration: InputDecoration(
//             hintText: '궁금한 것을 빠르게 검색해보세요.',
//             hintStyle: KosStyle.bodyB1,
//             //  prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
//             contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 4),
//             border: OutlineInputBorder(
//               borderRadius: BorderRadius.circular(16),
//               borderSide: const BorderSide(color: Colors.grey, width: 1),
//             ),
//             focusedBorder: OutlineInputBorder(
//               borderRadius: BorderRadius.circular(16),
//               borderSide: const BorderSide(color: C.mainOrange300, width: 2),
//             ),
//             enabledBorder: OutlineInputBorder(
//               borderRadius: BorderRadius.circular(16),
//               borderSide: const BorderSide(color: C.semanticGrayLine, width: 1),
//             ),
//             errorBorder: OutlineInputBorder(
//               borderRadius: BorderRadius.circular(16),
//               borderSide: const BorderSide(color: C.semanticErr300, width: 1),
//             ),
//             focusedErrorBorder: OutlineInputBorder(
//               borderRadius: BorderRadius.circular(16),
//               borderSide: const BorderSide(color: C.semanticErr300, width: 1),
//             ),
//             suffixIcon: IconButton(
//               icon: const Icon(Icons.search_rounded, color: Colors.grey),
//               onPressed: () {
//                 SearchData(controller.text);
//               },
//             ),
//           ),
//         ));
//   }

//   // 자주 찾는 질문 뱃지 리스트
//   Widget buildBadgeList() {
//     return Container(
//       //   width: 400,
//       //   height: 522,
//       alignment: Alignment.center,
//       child: StreamBuilder<ResStream<List<SearchCommCodeRes>>>(
//           stream: codeCtrl.stream,
//           builder: (context, snapshot) {
//             if (!snapshot.hasData) {
//               return const SizedBox.shrink();
//             }
//             return Wrap(
//               direction: Axis.horizontal,
//               children: snapshot.data!.data!.map((item) {
//                 return Row(
//                   mainAxisSize: MainAxisSize.min,
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   crossAxisAlignment: CrossAxisAlignment.center,
//                   children: [buildBadgeItem(item), const Gap(10)],
//                 );
//               }).toList(),
//             );
//           }),
//       //   padding: const EdgeInsets.all(20),
//       // child: Wrap(
//       //   direction: Axis.horizontal,
//       //   children: [
//       //     ListView.builder(
//       //       shrinkWrap: true,
//       //       itemCount: badgeList2.length,
//       //       physics: const BouncingScrollPhysics(),
//       //       itemBuilder: (BuildContext context, int index) {
//       //         return Row(
//       //           mainAxisSize: MainAxisSize.min,
//       //           mainAxisAlignment: MainAxisAlignment.center,
//       //           crossAxisAlignment: CrossAxisAlignment.center,
//       //           children: [
//       //             buildBadgeItem(badgeList2[index]),
//       //           ],
//       //         );
//       //       },
//       //     ),
//       //   ],
//       // ),
//     );
//   }

//   Widget buildBadgeItem(dynamic text) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 1),
//       child: ValueListenableBuilder<List<String>>(
//           valueListenable: badgeSelectedList,
//           builder: (context, val, snapshot) {
//             return CustomSecButton(
//               text: text.codeNm.toString(),
//               type: 'L',
//               widthValue: (Get.width / 4) - 17,
//               heightValue: 45,
//               colorValue: val.contains(text.code.toString()) ? Colors.amber[100] : C.semanticGrayTabBg,
//               // color: val.contains(text) ? Colors.white : C.semanticGrayTabBg,
//               onPressed: () {
//                 // if (val.contains(text)) {
//                 //   badgeSelectedList.value = List.from(badgeSelectedList.value)..remove(text);
//                 // } else {
//                 //   badgeSelectedList.value = List.from(badgeSelectedList.value)..add(text);
//                 // }
//                 badgeSelectedList.value = [];
//                 badgeSelectedList.value = List.from(badgeSelectedList.value)..add(text.code.toString());
//                 badgeSearchData(text.code.toString());
//               },
//             );
//           }),
//     );
//   }

//   // 자주 찾는 질문 리스트
//   Widget buildList(List<BoardResDetailData> list) {
//     return SizedBox(
//       width: double.infinity,
//       //   height: 322,
//       // padding: const EdgeInsets.symmetric(horizontal: 16.0),
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

// // 자주 찾는 질문 아이템
//   Widget buildItem(BoardResDetailData data) {
//     return Column(
//       children: [
//         ExpansionTile(
//           leading: null,
//           backgroundColor: Colors.white,
//           collapsedBackgroundColor: Colors.white,

//           //  maintainState: true,
//           clipBehavior: Clip.antiAlias,
//           // dense: true,
//           // visualDensity: VisualDensity.compact,
//           tilePadding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 0.0),
//           title: Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 6.0),
//             child: Text(
//               data.ptupTtl.toString(),
//               softWrap: true,
//               style: KosStyle.bodyB4,
//             ),
//           ),
//           shape: Border(
//             top: BorderSide(color: Colors.grey.shade300, width: 1),
//             bottom: BorderSide(color: Colors.grey.shade300, width: 1),
//           ),
//           childrenPadding: const EdgeInsets.symmetric(horizontal: .0, vertical: 0.0),
//           children: [
//             ListTile(
//               style: ListTileStyle.drawer,
//               dense: true,
//               // shape: const Border(
//               //   top: BorderSide(),
//               //   bottom: BorderSide(),
//               // ),
//               visualDensity: VisualDensity.compact,
//               trailing: null,
//               selectedTileColor: Colors.grey[100],
//               contentPadding: const EdgeInsets.symmetric(horizontal: 0.0, vertical: 0.0),
//               horizontalTitleGap: 0,
//               minVerticalPadding: 0,
//               title: Container(
//                 color: Colors.grey[100],
//                 width: double.infinity,
//                 padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
//                 child: Padding(
//                   padding: const EdgeInsets.symmetric(horizontal: 10),
//                   child: Text(
//                     data.ptupCnts.toString(),
//                     softWrap: true,
//                     // overflow: TextOverflow.fade,
//                     style: KosStyle.bodyB1,
//                   ),
//                 ),
//               ),
//             ),
//           ],
//         ),
//         Divider(
//           height: 1,
//           thickness: 1,
//           color: Colors.grey[300],
//         ),
//       ],
//     );
//   }
// }
