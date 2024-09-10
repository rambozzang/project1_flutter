import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:project1/app/auth/cntr/auth_cntr.dart';
import 'package:project1/app/auth/PermissionHandler.dart';
import 'package:project1/repo/common/res_data.dart';
import 'package:project1/utils/log_utils.dart';
import 'package:project1/utils/utils.dart';
import 'package:project1/widget/custom_indicator_offstage.dart';
import 'package:permission_handler/permission_handler.dart';

class AgreePage extends StatefulWidget {
  const AgreePage({super.key});

  @override
  _AgreePageState createState() => _AgreePageState();
}

class _AgreePageState extends State<AgreePage> with WidgetsBindingObserver {
  bool allChecked = false;
  List<Map<String, dynamic>> agreements = [
    {'id': 1, 'title': '(필수) 서비스이용약관 동의', 'checked': false, 'url': '/ServicePage'},
    {'id': 2, 'title': '(필수) 개인정보 수집 및 이용 동의', 'checked': false, 'url': '/PrivecyPage'},
    {'id': 3, 'title': '(필수) 위치정보 이용 동의', 'checked': false, 'url': '/LocatinServicePage'},
    {'id': 4, 'title': '(필수) 14세 이상 동의', 'checked': false, 'url': ''},
  ];
  late String custId;

  final ValueNotifier<bool> isLoading = ValueNotifier<bool>(false);
  bool _needToCheckPermission = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    custId = Get.parameters['custId']!;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _needToCheckPermission) {
      _needToCheckPermission = false;
      _checkLocationPermission();
    }
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

  Future<bool> requestLocationPermission() async {
    LocationPermission locationPermission = await Geolocator.checkPermission();

    bool locationPermissionGranted = locationPermission == LocationPermission.always || locationPermission == LocationPermission.whileInUse;

    if (!locationPermissionGranted) {
      _needToCheckPermission = true;
      bool? openSettings = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('위치 권한 필요'),
            content: const Text('앱을 사용하려면 위치 권한이 필요합니다. 설정에서 위치 권한을 허용해주세요.'),
            actions: <Widget>[
              TextButton(
                child: const Text('설정으로 이동'),
                onPressed: () => Navigator.of(context).pop(true),
              ),
            ],
          );
        },
      );
      lo.e('openSettings 1: $openSettings');

      if (openSettings == true) {
        _needToCheckPermission = true;
        openAppSettings();
        return false; // 설정 화면으로 이동했으므로 false 반환
      }
      lo.e('openSettings 2 : $openSettings');
    }
    lo.e('openSettings 3 : $locationPermissionGranted');
    return locationPermissionGranted;
  }

  Future<void> _checkLocationPermission() async {
    // PermissionHandler handler = PermissionHandler();
    // bool locationPermissionGranted = await handler.completed();

    LocationPermission locationPermission = await Geolocator.checkPermission();

    if (locationPermission == LocationPermission.always || locationPermission == LocationPermission.whileInUse) {
      _proceedWithSignUp();
    } else {
      _showRetryDialog();
    }
  }

  Future<void> _showRetryDialog() async {
    bool? retry = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('위치 권한 필요'),
          content: const Text('앱을 사용하려면 위치 권한이 반드시 필요합니다. 다시 시도하시겠습니까?'),
          actions: <Widget>[
            TextButton(
              child: const Text('종료'),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            TextButton(
              child: const Text('다시 시도'),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    );

    if (retry == true) {
      bool locationPermissionGranted = await requestLocationPermission();
      if (locationPermissionGranted) {
        await _proceedWithSignUp();
      }
    } else {
      // 사용자가 종료를 선택한 경우
      Get.offAllNamed('/JoinPage');
    }
  }

  Future<void> _proceedWithSignUp() async {
    try {
      isLoading.value = true;
      ResData resData = await Get.find<AuthCntr>().signUpProc(custId);

      if (resData.code != "00") {
        throw Exception(resData.msg.toString());
      }

      Get.offAllNamed('/AuthPage');
    } catch (e) {
      Utils.alert(e.toString());
      await Future.delayed(const Duration(milliseconds: 2000));
      Get.offAllNamed('/JoinPage');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> completed() async {
    // bool locationPermissionGranted = await requestLocationPermission();
    _needToCheckPermission = true;
    PermissionHandler handler = PermissionHandler();

    bool locationPermissionGranted = await handler.completed();

    if (locationPermissionGranted) {
      await _proceedWithSignUp();
    }
    // 권한이 거부되었거나 설정 화면으로 이동한 경우, AppLifecycleState.resumed에서 처리될 것임
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
                    Stack(
                      children: [
                        Positioned(
                          bottom: 5,
                          child: Container(
                            height: 10,
                            width: 250,
                            color: const Color.fromARGB(255, 105, 144, 74).withOpacity(0.5),
                          ),
                        ),
                        const Text(
                          'SkySnap 서비스',
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      '서비스 시작 및 가입을 위해 먼저 가입 및 정보 제공에\n동의해 주세요.',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 14, color: Colors.black),
                    ),
                    const SizedBox(height: 30),
                    Expanded(
                      child: ListView(
                        children: [
                          InkWell(
                            onTap: toggleAllAgreements,
                            child: Container(
                              padding: const EdgeInsets.all(15),
                              decoration: BoxDecoration(
                                // color: Colors.indigo[100],
                                gradient: const LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomRight,
                                    // colors: [Color.fromARGB(255, 29, 33, 56), Color.fromARGB(255, 45, 52, 91)],
                                    colors: [Color.fromARGB(255, 59, 114, 197), Color.fromARGB(255, 117, 158, 219)]),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  Icon(
                                    allChecked ? Icons.check_box : Icons.check_box_outline_blank,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 10),
                                  const Text(
                                    '전체동의',
                                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
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
                                        agreement['url'] == ''
                                            ? const SizedBox()
                                            : InkWell(
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
                              completed();
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: const Color.fromARGB(255, 47, 54, 95),
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
