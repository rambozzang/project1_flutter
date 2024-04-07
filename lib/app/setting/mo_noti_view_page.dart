// import 'dart:async';

// import 'package:flutter/cupertino.dart';
// import 'package:flutter/material.dart';
// import 'package:gap/gap.dart';
// import 'package:get/get.dart';
// import 'package:project1/repo/common/res_stream.dart';


// class MoNotiViewPage extends StatefulWidget {
//   const MoNotiViewPage({super.key});

//   @override
//   State<MoNotiViewPage> createState() => _MoNotiViewPageState();
// }

// class _MoNotiViewPageState extends State<MoNotiViewPage> {
//   final formKey = GlobalKey<FormState>();

//   final StreamController<ResStream<SearchPostListRes>> listCtrl = StreamController();

//   late int seq;

//   @override
//   initState() {
//     super.initState();

//     seq = int.parse(Get.arguments['seq'] ?? '0');
//     Lo.g('seq : $seq');
//     if (seq == null) {
//       Utils.alertIcon('이미 삭제된 게시글 입니다.', icontype: 'E');
//       Get.back();
//       return;
//     }

//     getData(seq);
//   }

//   Future<void> getDataInit() async => getData(seq);

//   Future<void> getData(int seq) async {
//     try {
//       listCtrl.sink.add(ResStream.loading());
//       BoardRepo repo = BoardRepo();
//       ResData resData = await repo.getView(seq);

//       if (resData.code != '00') {
//         Utils.alert(resData.msg.toString());
//         listCtrl.sink.add(ResStream.error(resData.msg.toString()));
//         return;
//       }

//       SearchPostListRes boardList = SearchPostListRes.fromMap(resData.data);
//       listCtrl.sink.add(ResStream.completed(boardList, message: '조회가 완료되었습니다.'));
//     } catch (e) {
//       listCtrl.sink.add(ResStream.error(e.toString()));
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     var _isChecked = false;
//     return Scaffold(
//       appBar: AppBar(
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back_ios),
//           onPressed: () => Navigator.pop(context),
//         ),
//         title: Text('공지사항 보기', style: KosStyle.headingH3),
//         centerTitle: true,
//         elevation: 0,
//       ),
//       backgroundColor: Colors.white,
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.symmetric(horizontal: 16.0),
//         child: Utils.commonStreamBody<SearchPostListRes>(listCtrl, buildBody, getDataInit),
//       ),
//     );
//   }

//   Column buildBody(SearchPostListRes data) {
//     return Column(
//       mainAxisAlignment: MainAxisAlignment.start,
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         const Gap(20),
//         Text(
//           '${data.ptupTtl}',
//           style: KosStyle.bodyblack18,
//         ),
//         Text(
//           '${data.ptupDt}',
//           style: KosStyle.styleB1SemanticGray14,
//         ),
//         const Gap(20),
//         const Gap(20),
//         Text("${data.ptupDsc}", style: KosStyle.styleB2),
//       ],
//     );
//   }
// }
