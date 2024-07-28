import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:project1/app/auth/cntr/auth_cntr.dart';
import 'package:project1/app/auth/permission_page.dart';
import 'package:project1/repo/common/res_data.dart';
import 'package:project1/utils/utils.dart';
import 'package:project1/widget/custom_indicator_offstage.dart';

class AgreePage extends StatefulWidget {
  const AgreePage({super.key});

  @override
  _AgreePageState createState() => _AgreePageState();
}

class _AgreePageState extends State<AgreePage> {
  bool allChecked = false;
  List<Map<String, dynamic>> agreements = [
    {'id': 1, 'title': '(필수) 서비스이용약관 동의', 'checked': false, 'url': '/ServicePage'},
    {'id': 2, 'title': '(필수) 개인정보 수집 및 이용 동의', 'checked': false, 'url': '/PrivecyPage'},
    {'id': 3, 'title': '(필수) 개인정보처리방침 동의', 'checked': false, 'url': '/PrivecyPage'},
    {'id': 4, 'title': '(필수) 위치정보 이용 동의', 'checked': false, 'url': '/LocatinServicePage'},
  ];
  late String custId;

  final ValueNotifier<bool> isLoading = ValueNotifier<bool>(false);

  @override
  void initState() {
    super.initState();

    custId = Get.parameters['custId']!;
  }

  void toggleAgreement(int id) {
    setState(() {
      agreements = agreements.map((agreement) {
        if (agreement['id'] == id) {
          agreement['checked'] = !agreement['checked'];
        }
        return agreement;
      }).toList();
      allChecked = agreements.every((agreement) => agreement['checked']);
    });
  }

  void toggleAllAgreements() {
    setState(() {
      allChecked = !allChecked;
      agreements = agreements.map((agreement) {
        agreement['checked'] = allChecked;
        return agreement;
      }).toList();
    });
  }

  void showAgreementDetails(String title, String content) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: SingleChildScrollView(
            child: Text(content),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('닫기'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void complated() async {
    // await handleNotificationPermission();
    PermissionHandler handler = PermissionHandler();
    await handler.complated();
    isLoading.value = true;

    // Get.back(result: true);
    ResData resData = await Get.find<AuthCntr>().signUpProc(custId);
    if (resData.code != "00") {
      Utils.alert(resData.msg.toString());
      // 3초 딜레이
      await Future.delayed(const Duration(milliseconds: 2000), () {
        Get.offAllNamed('/JoinPage');
      }); // To preven

      return;
    }
    Get.offAllNamed('/AuthPage');
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) {
          return;
        }
      },
      child: Stack(
        children: [
          Scaffold(
            body: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '서비스 가입',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '서비스 시작 및 가입을 위해 먼저\n가입 및 정보 제공에 동의해 주세요.',
                      style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 20),
                    Expanded(
                      child: ListView(
                        children: [
                          InkWell(
                            onTap: toggleAllAgreements,
                            child: Container(
                              padding: const EdgeInsets.all(15),
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  Icon(
                                    allChecked ? Icons.check_box : Icons.check_box_outline_blank,
                                    color: Colors.black,
                                  ),
                                  const SizedBox(width: 10),
                                  const Text(
                                    '전체동의',
                                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 15),
                          ...agreements
                              .map((agreement) => Container(
                                    padding: const EdgeInsets.symmetric(vertical: 15),
                                    decoration: BoxDecoration(
                                      border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
                                    ),
                                    child: Row(
                                      children: [
                                        InkWell(
                                          onTap: () => toggleAgreement(agreement['id']),
                                          child: Icon(
                                            agreement['checked'] ? Icons.check_box : Icons.check_box_outline_blank,
                                            color: Colors.black,
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            agreement['title'],
                                            style: const TextStyle(fontSize: 14),
                                          ),
                                        ),
                                        InkWell(
                                          onTap: () {
                                            Get.toNamed(agreement['url']);
                                          },
                                          child: const Text(
                                            '보기',
                                            style: TextStyle(fontSize: 13, color: Colors.blue),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ))
                              .toList(),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: allChecked
                          ? () {
                              complated();
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Colors.black54,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('확인', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ),
          ),
          ValueListenableBuilder<bool>(
            valueListenable: isLoading,
            builder: (context, value, child) {
              return CustomIndicatorOffstage(
                isLoading: !value,
                color: const Color(0xFFEA3799),
                opacity: 0.5,
              );
            },
          )
        ],
      ),
    );
  }
}
