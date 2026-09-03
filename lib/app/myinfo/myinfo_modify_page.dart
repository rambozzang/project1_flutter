import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:get/get.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:project1/app/auth/cntr/auth_cntr.dart';
import 'package:project1/app/shared_album/theme/sa_colors.dart';
import 'package:project1/app/shared_album/theme/sa_text_styles.dart';
import 'package:project1/repo/common/res_data.dart';
import 'package:project1/repo/common/res_stream.dart';
import 'package:project1/repo/cust/cust_repo.dart';
import 'package:project1/repo/cust/data/cust_data.dart';
import 'package:project1/repo/cust/data/cust_update_data.dart';
import 'package:project1/utils/log_utils.dart';
import 'package:project1/utils/utils.dart';
import 'package:project1/widget/custom_button.dart';
import 'package:project1/widget/custom_indicator_offstage.dart';

/// 내 정보 수정 — "우리의 앨범"(shared_album)과 같은 디자인 토큰(SaColors/SaText)을 쓴다.
///
/// 설정 화면과 마찬가지로 **라이트 고정**이다. `SaColors.syncWith(context)`를 호출하지
/// 않으므로 `SaColors.isLight` 기본값(true)의 라이트 팔레트가 그대로 적용된다.
class MyinfoModifyPage extends StatefulWidget {
  const MyinfoModifyPage({super.key});

  @override
  State<MyinfoModifyPage> createState() => _MyinfoModifyPageState();
}

class _MyinfoModifyPageState extends State<MyinfoModifyPage> with AutomaticKeepAliveClientMixin<MyinfoModifyPage> {
  @override
  bool get wantKeepAlive => true;

  final formKey = GlobalKey<FormState>();
  TextEditingController emailController = TextEditingController();
  TextEditingController nickNmController = TextEditingController();
  TextEditingController custNmController = TextEditingController();
  TextEditingController selfIntroController = TextEditingController();
  TextEditingController selfIdController = TextEditingController();

  FocusNode nameFocus = FocusNode();

  FocusNode hpFocus = FocusNode();

  final StreamController<ResStream<CustData>> dataCntr = StreamController();

  ValueNotifier<bool> isExitprocess = ValueNotifier<bool>(false);

  // 버튼 상태관리
  ValueNotifier<bool> isProgressing = ValueNotifier(false);

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
      emailController.text = data.email ?? '';
      nickNmController.text = data.nickNm ?? '';
      custNmController.text = data.custNm ?? '';
      selfIntroController.text = data.selfIntro ?? '';
      dataCntr.sink.add(ResStream.completed(data));
    } catch (e) {
      Utils.alert(e.toString());
      dataCntr.sink.add(ResStream.error(e.toString()));
    }
  }

  Future<void> save() async {
    try {
      isProgressing.value = true;
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
        isProgressing.value = false;
        return;
      }
      Utils.alert('수정되었습니다.');

      Get.find<AuthCntr>().upDateNickNmAndCustName(nickNmController.text, custNmController.text);

      Get.back(result: true);
    } catch (e) {
      Utils.alert(e.toString());
      isProgressing.value = false;
      dataCntr.sink.add(ResStream.error(e.toString()));
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: SaColors.bgBase,
      appBar: AppBar(
        forceMaterialTransparency: true,
        // 앨범 홈의 원형 surface 버튼과 같은 톤(pill). 화면 좌측 패딩 16에 맞춘다.
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
        title: Text('내 정보 수정', style: SaText.titleS),
        centerTitle: true,
        elevation: 0,
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    children: [
                      const Gap(24),
                      Utils.commonStreamBody<CustData>(dataCntr, buildBody, getData),
                    ],
                  )),
            ),
          ),
          ValueListenableBuilder<bool>(
            valueListenable: isExitprocess,
            builder: (context, value, child) {
              return value
                  ? CustomIndicatorOffstage(
                      isLoading: !value,
                      color: const Color(0xFFEA3799),
                      opacity: 0.5,
                    )
                  : const SizedBox();
            },
          ),
        ],
      ),
      bottomNavigationBar: bottomContainer(
          context,
          ValueListenableBuilder<bool>(
              valueListenable: isProgressing,
              builder: (context, value, child) {
                return CustomButton(
                    text: '변경사항 저장', isProgressing: value, type: 'XL', heightValue: 50, isEnable: true, onPressed: () => save());
              })),
    );
  }

  Widget buildBody(CustData data) {
    // selfIdController.text = data.selfId ?? '';

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 15.0),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 0),
            padding: const EdgeInsets.only(top: 5),
            height: 90,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('계정 Email', style: SaText.caption.copyWith(color: SaColors.textTertiary)),
                const Gap(4),
                TextFormField(
                  controller: emailController,
                  // focusNode: textFocus,
                  readOnly: true,
                  maxLines: 1,
                  // cursorHeight: 14,
                  // 한글밑줄제거 + 본문 타이포는 토큰(bodyMedium)으로
                  style: SaText.bodyMedium.copyWith(decorationThickness: 0),
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    counterStyle: SaText.caption.copyWith(color: SaColors.textTertiary),
                    filled: true,
                    fillColor: SaColors.surface,
                    // suffixIcon: const Icon(Icons.search, color: Colors.grey),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: SaColors.borderStrong),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(13),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: SaColors.accentTeal),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    // label: const Text("계정 Email - 수정불가"),
                    labelStyle: SaText.body.copyWith(fontSize: 13, color: SaColors.textTertiary),
                  ),
                  onFieldSubmitted: (text) {},
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 15.0),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 0),
            padding: const EdgeInsets.only(top: 5),
            // 토큰 본문 글자(14.5/height 1.45)와 내부 패딩 12가 글자 수 카운터와 함께 들어갈 높이.
            height: 86,
            child: TextFormField(
              controller: nickNmController,
              // focusNode: textFocus,
              maxLines: 1,
              // cursorHeight: 14,
              maxLength: 15,
              // 한글밑줄제거 + 본문 타이포는 토큰(bodyMedium)으로
              style: SaText.bodyMedium.copyWith(decorationThickness: 0),
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                counterStyle: SaText.caption.copyWith(color: SaColors.textTertiary),
                filled: true,
                fillColor: SaColors.surface,
                // suffixIcon: const Icon(Icons.search, color: Colors.grey),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: SaColors.borderStrong),
                  borderRadius: BorderRadius.circular(13),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(13),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: SaColors.accentTeal),
                  borderRadius: BorderRadius.circular(13),
                ),
                label: const Text("낙네임를 입력해주세요"),
                labelStyle: SaText.body.copyWith(fontSize: 13, color: SaColors.textTertiary),
              ),
              onFieldSubmitted: (text) {
                // Perform search
              },
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 0.0),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 0),
            padding: const EdgeInsets.only(top: 5),
            // 토큰 본문 글자(14.5/height 1.45)와 내부 패딩 12가 글자 수 카운터와 함께 들어갈 높이.
            height: 86,
            child: TextFormField(
              controller: custNmController,
              // focusNode: textFocus,
              maxLines: 1,
              // cursorHeight: 14,
              maxLength: 15,
              // 한글밑줄제거 + 본문 타이포는 토큰(bodyMedium)으로
              style: SaText.bodyMedium.copyWith(decorationThickness: 0),
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                counterStyle: SaText.caption.copyWith(color: SaColors.textTertiary),
                filled: true,
                fillColor: SaColors.surface,
                // suffixIcon: const Icon(Icons.search, color: Colors.grey),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: SaColors.borderStrong),
                  borderRadius: BorderRadius.circular(13),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(13),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: SaColors.accentTeal),
                  borderRadius: BorderRadius.circular(13),
                ),
                label: const Text("고객명을 입력해주세요"),
                labelStyle: SaText.body.copyWith(fontSize: 13, color: SaColors.textTertiary),
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
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 0),
          padding: const EdgeInsets.only(top: 15),
          // 7줄 * 토큰 본문 행높이(14.5*1.45) + 내부 패딩 12 + 글자 수 카운터가 들어갈 높이.
          height: 225,
          child: TextFormField(
            controller: selfIntroController,
            // focusNode: textFocus,
            // cursorHeight: 12,
            maxLines: 7,
            maxLength: 100,
            // 한글밑줄제거 + 본문 타이포는 토큰(bodyMedium)으로
            style: SaText.bodyMedium.copyWith(decorationThickness: 0),
            decoration: InputDecoration(
              alignLabelWithHint: true, // label 과 입력창을 같은 높이로 맞춤
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              counterStyle: SaText.caption.copyWith(color: SaColors.textTertiary),
              filled: true,
              fillColor: SaColors.surface,
              // suffixIcon: const Icon(Icons.search, color: Colors.grey),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: SaColors.borderStrong),
                borderRadius: BorderRadius.circular(13),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(13),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: SaColors.accentTeal),
                borderRadius: BorderRadius.circular(13),
              ),
              label: const Text("자기소개를 입력해주세요"),
              labelStyle: SaText.body.copyWith(fontSize: 13, color: SaColors.textTertiary),
            ),
            onFieldSubmitted: (text) {
              // Perform search
            },
          ),
        ),
        const Gap(50),
        if (kDebugMode ||
            Get.find<AuthCntr>().custId.value == '3523487940' ||
            Get.find<AuthCntr>().custId.value == 'AAq0s2u7wvXkekyymwPyTe0XwkH3' ||
            Get.find<AuthCntr>().custId.value == 'ArvPO0n2nNf1SDTZAutlnAhXNRp2' ||
            Get.find<AuthCntr>().custId.value == 'T5bNV8_g9vKxWCpAA_uKmvQQ9qlukx_V5af5T_Gmk94' ||
            Get.find<AuthCntr>().custId.value == 'ZfMbSYO6ZJMahuBWpTMHpbTmHND3' ||
            Get.find<AuthCntr>().custId.value == '5p3DvtPFzjMghS1oef3JlqEfgpj1' ||
            Get.find<AuthCntr>().custId.value == '3728884228') ...[
          TextButton(
            onPressed: () async {
              await AuthCntr.to.logout();
            },
            child: Text('로그아웃', style: SaText.caption.copyWith(color: SaColors.textSecondary)),
          ),
        ],

        Align(
            alignment: Alignment.centerRight,
            child: InkWell(
                onTap: () => outAlertDialog(context),
                child: Text('회원 탈퇴하기', style: SaText.caption.copyWith(color: SaColors.textTertiary)))),

        const Gap(70),
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

  // 탈퇴하기 showAlertDialog
  void outAlertDialog(BuildContext context) {
    bool checkValue = false;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(builder: (context, setState) {
          return AlertDialog(
            contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
            content: Container(
                height: 390,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(26),
                  color: SaColors.surface,
                  shape: BoxShape.rectangle,
                  border: Border.all(color: SaColors.border),
                  boxShadow: const [
                    BoxShadow(color: Colors.black, offset: Offset(0, 10), blurRadius: 10),
                  ],
                ),
                child: Column(
                  children: [
                    const Gap(20),
                    // 위험(탈퇴) 강조 — SaColors 에 대응 토큰이 없어 원본 red 유지.
                    const PhosphorIcon(PhosphorIconsFill.warning, size: 50, color: Colors.red),
                    const Gap(20),
                    Text(
                      "정말 탈퇴하시겠습니까?",
                      style: SaText.titleM.copyWith(fontSize: 20, color: Colors.red, fontWeight: FontWeight.bold),
                    ),
                    const Gap(20),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18.0),
                      child: Text(
                        "1년간 재가입 불가합니다. 데이터는 모두 삭제되어 복구 불가능합니다.",
                        style: SaText.caption.copyWith(color: SaColors.textPrimary, fontWeight: FontWeight.bold),
                      ),
                    ),
                    Row(
                      children: [
                        Checkbox(
                            value: checkValue,
                            onChanged: (vlue) {
                              lo.g(vlue.toString());
                              setState(() {
                                checkValue = vlue!;
                              });
                            }),
                        Text(
                          '진짜 다시 확인해주세요!!',
                          style: SaText.caption.copyWith(color: SaColors.textPrimary, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const Gap(20),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CustomButton(
                          heightValue: 50,
                          isEnable: checkValue ? true : false,
                          onPressed: () {
                            Navigator.pop(context);
                            isExitprocess.value = true;
                            Get.back();
                            AuthCntr.to.leave();
                          },
                          listColors: const [Colors.red, Colors.redAccent],
                          type: 'S',
                          text: "탈퇴하기",
                        ),
                        const Gap(10),
                        CustomButton(
                          isEnable: true,
                          heightValue: 50,
                          onPressed: () {
                            Get.back();
                          },
                          type: 'S',
                          // listColors: const [Colors.deep, Colors.grey],
                          text: "취소",
                        ),
                      ],
                    ),
                    const Gap(10),
                  ],
                )),
          );
        });
      },
    );
  }
}
