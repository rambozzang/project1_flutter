import 'dart:async';

import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:get/get.dart';
import 'package:kakao_flutter_sdk/kakao_flutter_sdk.dart';
import 'package:project1/app/auth/cntr/auth_cntr.dart';
import 'package:project1/repo/common/res_data.dart';
import 'package:project1/repo/common/res_stream.dart';
import 'package:project1/repo/cust/cust_repo.dart';
import 'package:project1/repo/cust/data/cust_data.dart';
import 'package:project1/repo/cust/data/cust_update_data.dart';
import 'package:project1/utils/utils.dart';
import 'package:project1/widget/custom_button.dart';

class MyinfoModifyPage extends StatefulWidget {
  const MyinfoModifyPage({super.key});

  @override
  State<MyinfoModifyPage> createState() => _MyinfoModifyPageState();
}

class _MyinfoModifyPageState extends State<MyinfoModifyPage> with AutomaticKeepAliveClientMixin<MyinfoModifyPage> {
  @override
  bool get wantKeepAlive => true;

  final formKey = GlobalKey<FormState>();
  TextEditingController nickNmController = TextEditingController();
  TextEditingController custNmController = TextEditingController();
  TextEditingController selfIntroController = TextEditingController();
  TextEditingController selfIdController = TextEditingController();

  FocusNode nameFocus = FocusNode();

  FocusNode hpFocus = FocusNode();

  final StreamController<ResStream<CustData>> dataCntr = StreamController();

  @override
  initState() {
    super.initState();
    getData();
  }

  Future<void> getData() async {
    try {
      dataCntr.sink.add(ResStream.loading());
      CustRepo repo = CustRepo();
      ResData res = await repo.getCustInfo(AuthCntr.to.resLoginData.value.custId.toString());
      if (res.code != '00') {
        Utils.alert(res.msg.toString());
        dataCntr.sink.add(ResStream.error(res.msg.toString()));
        return;
      }
      CustData data = CustData.fromMap(res.data);
      dataCntr.sink.add(ResStream.completed(data));
    } catch (e) {
      Utils.alert(e.toString());
      dataCntr.sink.add(ResStream.error(e.toString()));
    }
  }

  Future<void> save() async {
    try {
      dataCntr.sink.add(ResStream.loading());
      CustRepo repo = CustRepo();
      CustUpdataData data = CustUpdataData();
      data.custId = AuthCntr.to.resLoginData.value.custId.toString();
      data.nickNm = nickNmController.text;
      data.custNm = custNmController.text;
      data.selfIntro = selfIntroController.text;
      // data.selfId = selfIdController.text;

      ResData res = await repo.updateCust(data);
      if (res.code != '00') {
        Utils.alert(res.msg.toString());
        dataCntr.sink.add(ResStream.error(res.msg.toString()));
        return;
      }
      Utils.alert('수정되었습니다.');
      AuthCntr.to.resLoginData.value.nickNm = nickNmController.text;
      AuthCntr.to.resLoginData.value.custNm = custNmController.text;

      Get.back(result: true);
    } catch (e) {
      Utils.alert(e.toString());
      dataCntr.sink.add(ResStream.error(e.toString()));
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      appBar: AppBar(
        forceMaterialTransparency: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('기본 정보 수정'),
        centerTitle: true,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Form(
          key: formKey,
          child: SingleChildScrollView(
              child: Column(
            children: [
              const Gap(24),
              Utils.commonStreamBody<CustData>(dataCntr, buildBody, getData),
            ],
          )),
        ),
      ),
      bottomNavigationBar:
          bottomContainer(context, CustomButton(text: '수정완료', type: 'XL', heightValue: 55, isEnable: true, onPressed: () => save())),
    );
  }

  Widget buildBody(CustData data) {
    nickNmController.text = data.nickNm ?? '';
    custNmController.text = data.custNm ?? '';
    selfIntroController.text = data.selfIntro ?? '';
    // selfIdController.text = data.selfId ?? '';

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 15.0),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 0),
            padding: const EdgeInsets.only(top: 5),
            height: 54,
            child: TextFormField(
              controller: nickNmController,
              // focusNode: textFocus,
              maxLines: 1,
              // cursorHeight: 14,
              style: const TextStyle(decorationThickness: 0), // 한글밑줄제거
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                filled: true,
                fillColor: Colors.grey[100],
                // suffixIcon: const Icon(Icons.search, color: Colors.grey),
                enabledBorder: OutlineInputBorder(
                  // width: 0.0 produces a thin "hairline" border
                  borderSide: const BorderSide(color: Colors.grey, width: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
                border: OutlineInputBorder(
                  // width: 0.0 produces a thin "hairline" border
                  //  borderSide: const BorderSide(color: Colors.grey, width: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Colors.grey, width: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
                label: const Text("낙네임를 입력해주세요"),
                labelStyle: const TextStyle(color: Colors.black38),
              ),
              onFieldSubmitted: (text) {
                // Perform search
              },
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 15.0),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 0),
            padding: const EdgeInsets.only(top: 5),
            height: 54,
            child: TextFormField(
              controller: custNmController,
              // focusNode: textFocus,
              maxLines: 1,
              // cursorHeight: 14,
              style: const TextStyle(decorationThickness: 0), // 한글밑줄제거
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                filled: true,
                fillColor: Colors.grey[100],
                // suffixIcon: const Icon(Icons.search, color: Colors.grey),
                enabledBorder: OutlineInputBorder(
                  // width: 0.0 produces a thin "hairline" border
                  borderSide: const BorderSide(color: Colors.grey, width: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
                border: OutlineInputBorder(
                  // width: 0.0 produces a thin "hairline" border
                  //  borderSide: const BorderSide(color: Colors.grey, width: 0.1),
                  borderRadius: BorderRadius.circular(2),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Colors.grey, width: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
                label: const Text("고객명을 입력해주세요"),
                labelStyle: const TextStyle(color: Colors.black38),
              ),
              onFieldSubmitted: (text) {
                // Perform search
              },
            ),
          ),
        ),
        // Padding(
        //   padding: const EdgeInsets.symmetric(vertical: 15.0),
        //   child: Container(
        //     margin: const EdgeInsets.symmetric(horizontal: 0),
        //     padding: const EdgeInsets.only(top: 5),
        //     height: 54,
        //     child: TextFormField(
        //       controller: selfIdController,
        //       // focusNode: textFocus,
        //       maxLines: 1,
        //       // cursorHeight: 12,
        //       style: const TextStyle(decorationThickness: 0), // 한글밑줄제거
        //       decoration: InputDecoration(
        //         contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        //         filled: true,
        //         fillColor: Colors.grey[100],
        //         // suffixIcon: const Icon(Icons.search, color: Colors.grey),
        //         enabledBorder: OutlineInputBorder(
        //           // width: 0.0 produces a thin "hairline" border
        //           borderSide: const BorderSide(color: Colors.grey, width: 0.2),
        //           borderRadius: BorderRadius.circular(2),
        //         ),
        //         border: OutlineInputBorder(
        //           // width: 0.0 produces a thin "hairline" border
        //           //  borderSide: const BorderSide(color: Colors.grey, width: 0.1),
        //           borderRadius: BorderRadius.circular(2),
        //         ),
        //         focusedBorder: OutlineInputBorder(
        //           borderSide: const BorderSide(color: Colors.grey, width: 0.2),
        //           borderRadius: BorderRadius.circular(2),
        //         ),
        //         label: const Text("사용할 @ID를 입력해주세요"),
        //         labelStyle: const TextStyle(color: Colors.black38),
        //       ),
        //       onFieldSubmitted: (text) {
        //         // Perform search
        //       },
        //     ),
        //   ),
        // ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 15.0),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 0),
            padding: const EdgeInsets.only(top: 15),
            height: 154,
            child: TextFormField(
              controller: selfIntroController,
              // focusNode: textFocus,
              // cursorHeight: 12,
              maxLines: 6,
              style: const TextStyle(decorationThickness: 0), // 한글밑줄제거
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                filled: true,
                fillColor: Colors.grey[100],
                // suffixIcon: const Icon(Icons.search, color: Colors.grey),
                enabledBorder: OutlineInputBorder(
                  // width: 0.0 produces a thin "hairline" border
                  borderSide: const BorderSide(color: Colors.grey, width: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
                border: OutlineInputBorder(
                  // width: 0.0 produces a thin "hairline" border
                  //  borderSide: const BorderSide(color: Colors.grey, width: 0.1),
                  borderRadius: BorderRadius.circular(2),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Colors.grey, width: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
                label: const Text("자기소개를 입력해주세요"),
                labelStyle: const TextStyle(color: Colors.black38),
              ),
              onFieldSubmitted: (text) {
                // Perform search
              },
            ),
          ),
        ),
        // const Gap(10),
      ],
    );
  }

  Widget bottomContainer(BuildContext context, Widget child) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: child,
        ),
      ),
    );
  }
}
