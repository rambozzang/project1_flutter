import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:project1/app/auth/cntr/auth_cntr.dart';
import 'package:project1/app/auth/PermissionHandler.dart';
import 'package:project1/repo/common/res_data.dart';
import 'package:project1/utils/log_utils.dart';
import 'package:project1/utils/utils.dart';
import 'package:project1/widget/custom_indicator_offstage.dart';
import 'package:permission_handler/permission_handler.dart';

/// 로딩화면(AuthPage)과 동일한 흰 구름 로고(인라인 SVG).
const String _logoSvg = '''
<svg viewBox="0 0 100 100" width="96" height="96">
  <g fill="#ffffff">
    <circle cx="38" cy="50" r="19"/>
    <circle cx="60" cy="45" r="23"/>
    <circle cx="27" cy="59" r="13"/>
    <circle cx="74" cy="59" r="14"/>
    <rect x="25" y="55" width="54" height="20" rx="10"/>
    <path d="M45 71 L37 90 L56 73 Z"/>
  </g>
</svg>
''';

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
      lo.e('didChangeAppLifecycleState _needToCheckPermission : $_needToCheckPermission');

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
    lo.e('checkLocationPermission 1');
    // 권한 상태 확인 전 잠시 대기
    await Future.delayed(const Duration(milliseconds: 500));
    lo.e('checkLocationPermission 2');

    LocationPermission locationPermission = await Geolocator.checkPermission();
    lo.e('checkLocationPermission 3 : $locationPermission');

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
        _needToCheckPermission = false;
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

    lo.e('completed() 1 ');
    PermissionHandler handler = PermissionHandler();
    lo.e('completed() 2 ');
    bool locationPermissionGranted = await handler.completed();
    lo.e('completed() 3 : $locationPermissionGranted');

    if (locationPermissionGranted) {
      _needToCheckPermission = false;
      await _proceedWithSignUp();
    } else {
      _checkLocationPermission();
    }

    // 권한이 거부되었거나 설정 화면으로 이동한 경우, AppLifecycleState.resumed에서 처리될 것임
  }

  // 로딩화면(AuthPage)과 동일한 대각선 3색 그라데이션 + 액센트.
  static const _gradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFCB6B), Color(0xFFFF8F8F), Color(0xFFFF6FA6)],
    stops: [0.0, 0.5, 1.0],
  );
  static const Color _accent = Color(0xFFEA3799);

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
            backgroundColor: const Color(0xFFFF8F8F),
            body: Container(
              decoration: const BoxDecoration(gradient: _gradient),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 14, 24, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 6),
                      // 로고 + 브랜드 (로딩화면과 동일한 흰 구름 + skysnap)
                      Row(
                        children: [
                          SvgPicture.string(_logoSvg, width: 42, height: 42),
                          const SizedBox(width: 10),
                          Text(
                            'skysnap',
                            style: GoogleFonts.quicksand(
                              fontSize: 30,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 26),
                      Text(
                        '반가워요! 👋',
                        style: GoogleFonts.nunito(
                          fontSize: 24,
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '서비스 시작을 위해\n아래 약관에 동의해 주세요.',
                        style: GoogleFonts.nunito(
                          fontSize: 15,
                          height: 1.4,
                          color: Colors.white.withValues(alpha: 0.92),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 24),
                      // 약관 카드 (흰 배경 — 그라데이션 위에서 가독성 확보)
                      Expanded(
                        child: SingleChildScrollView(
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.10),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                _allAgreeTile(),
                                const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 14),
                                  child: Divider(height: 1, thickness: 1, color: Color(0xFFEFEFF2)),
                                ),
                                ...agreements.map(_agreeTile),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      _confirmButton(),
                    ],
                  ),
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

  /// 전체 동의 타일(강조).
  Widget _allAgreeTile() {
    return InkWell(
      onTap: toggleAllAgreements,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        decoration: BoxDecoration(
          color: allChecked ? _accent.withValues(alpha: 0.08) : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            _checkIcon(allChecked, big: true),
            const SizedBox(width: 12),
            Text(
              '전체 동의',
              style: GoogleFonts.nunito(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: Colors.black.withValues(alpha: 0.85),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 개별 동의 항목 타일(제목 + 보기 링크).
  Widget _agreeTile(Map<String, dynamic> agreement) {
    final bool checked = agreement['checked'] as bool;
    final String url = agreement['url'] as String;
    return InkWell(
      onTap: () => toggleAgreement(agreement['id']),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Row(
          children: [
            _checkIcon(checked, big: false),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                agreement['title'] as String,
                style: GoogleFonts.nunito(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w600,
                  color: Colors.black.withValues(alpha: 0.78),
                ),
              ),
            ),
            if (url.isNotEmpty)
              GestureDetector(
                onTap: () => Get.toNamed(url),
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Row(
                    children: [
                      Text(
                        '보기',
                        style: GoogleFonts.nunito(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: _accent,
                        ),
                      ),
                      const Icon(Icons.chevron_right, size: 16, color: _accent),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// 원형 체크 아이콘(체크 시 액센트 채움).
  Widget _checkIcon(bool checked, {required bool big}) {
    final double size = big ? 26 : 24;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: checked ? _accent : Colors.white,
        shape: BoxShape.circle,
        border: Border.all(
          color: checked ? _accent : const Color(0xFFCBD0D6),
          width: 2,
        ),
      ),
      child: Icon(
        Icons.check,
        size: big ? 17 : 15,
        color: checked ? Colors.white : Colors.transparent,
      ),
    );
  }

  /// 확인 버튼 — 그라데이션 위에서 도드라지도록 흰 배경 + 액센트 글자.
  Widget _confirmButton() {
    final bool enabled = allChecked;
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: enabled ? () => completed() : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          disabledBackgroundColor: Colors.white.withValues(alpha: 0.35),
          foregroundColor: _accent,
          disabledForegroundColor: Colors.white.withValues(alpha: 0.75),
          elevation: enabled ? 6 : 0,
          shadowColor: Colors.black.withValues(alpha: 0.25),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: Text(
          '동의하고 시작하기',
          style: GoogleFonts.nunito(fontSize: 17, fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}
