// import 'package:babstrap_settings_screen/babstrap_settings_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:project1/admob/ad_manager.dart';
import 'package:project1/admob/banner_ad_widget.dart';
import 'package:project1/app/auth/agree_page.dart';
import 'package:project1/app/auth/cntr/auth_cntr.dart';
// import 'package:flutter_image_compress/flutter_image_compress.dart';

import 'package:project1/root/cntr/root_cntr.dart';
import 'package:project1/utils/log_utils.dart';
import 'package:project1/widget/custom_button.dart';
import 'package:project1/widget/custom_indicator_offstage.dart';

class SettingPage extends StatefulWidget {
  const SettingPage({super.key});

  @override
  State<SettingPage> createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage> {
  XFile? _image; //이미지를 담을 변수 선언
  final ImagePicker picker = ImagePicker(); //ImagePicker 초기화

  ValueNotifier<bool> isExitprocess = ValueNotifier<bool>(false);

  ValueNotifier<bool> isAdLoading = ValueNotifier<bool>(false);

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  Future<void> _loadAd() async {
    await AdManager().loadBannerAd('SettingPage');
    isAdLoading.value = true;
  }

  @override
  void dispose() {
    // AdManager().disposeBannerAd('SettingPage');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          //  backgroundColor: Colors.white.withOpacity(.94),
          appBar: AppBar(
            forceMaterialTransparency: true,
            automaticallyImplyLeading: false,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios),
              onPressed: () => Navigator.pop(context),
            ),
            title: const Text(
              "설정",
              style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
            ),
            centerTitle: true,
            // backgroundColor: Colors.transparent,
            elevation: 0,
          ),
          body: SingleChildScrollView(
            controller: RootCntr.to.hideButtonController3,
            padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 8),
            child: Column(
              children: [
                SettingsGroup(
                  settingsGroupTitle: "문의",
                  settingsGroupTitleStyle: const TextStyle(color: Colors.black, fontWeight: FontWeight.w700, fontSize: 16),
                  items: [
                    SettingsItem(
                      onTap: () => Get.toNamed('/NotiPage'),
                      icons: Icons.exit_to_app_rounded,
                      backgroundColor: Colors.white,
                      title: "공지사항",
                    ),
                    SettingsItem(
                      onTap: () => Get.toNamed('/FaqPage'),
                      icons: CupertinoIcons.repeat,
                      title: "FAQ",
                    ),
                  ],
                ),
                SettingsGroup(
                  settingsGroupTitle: "설정",
                  settingsGroupTitleStyle: const TextStyle(color: Colors.black, fontWeight: FontWeight.w700, fontSize: 16),
                  items: [
                    SettingsItem(
                      onTap: () => Get.toNamed('/AlramSettingPage'),
                      icons: CupertinoIcons.bell,
                      iconStyle: IconStyle(
                        iconsColor: Colors.white,
                        withBackground: true,
                        backgroundColor: Colors.indigo[300],
                      ),
                      title: '알림(PUSH) 설정',
                      subtitle: "신규글 등록, 좋아요,댓글 알림을 수신합니다.",
                      titleMaxLine: 1,
                      subtitleMaxLine: 1,
                    ),
                  ],
                ),
                ValueListenableBuilder<bool>(
                    valueListenable: isAdLoading,
                    builder: (context, value, child) {
                      if (!value) return const SizedBox.shrink();
                      return const BannerAdWidget(screenName: 'SettingPage');
                    }),
                const Gap(30),
                SettingsGroup(
                  settingsGroupTitle: "개인정 동의 및 약관",
                  settingsGroupTitleStyle: const TextStyle(color: Colors.black, fontWeight: FontWeight.w700, fontSize: 16),
                  items: [
                    if (kDebugMode) ...[
                      SettingsItem(
                        onTap: () => Get.toNamed('/MaketingPage'),
                        icons: CupertinoIcons.pencil_outline,
                        backgroundColor: Colors.white,
                        iconStyle: IconStyle(),
                        title: '마케팅 수신 동의 설정',
                        subtitle: "다양한 맴버 혜택을 담은 마케팅 정보를 SMS, 이메일, 앱 푸시로 보내드립니다.",
                        titleMaxLine: 1,
                        subtitleMaxLine: 1,
                      ),
                    ],
                    SettingsItem(
                      onTap: () => Get.toNamed('/ServicePage'),
                      icons: Icons.info_rounded,
                      backgroundColor: Colors.white,
                      iconStyle: IconStyle(
                        iconsColor: Colors.white,
                        withBackground: true,
                        backgroundColor: Colors.red,
                      ),
                      title: '서비스 이용약관',
                      // subtitle: "Lock Ziar'App to improve your privacy",
                    ),
                    SettingsItem(
                      onTap: () => Get.toNamed('/PrivecyPage'),
                      backgroundColor: Colors.white,
                      icons: Icons.info_rounded,
                      iconStyle: IconStyle(
                        backgroundColor: Colors.purple,
                      ),
                      title: '개인정보 처리방침',
                      subtitle: "회사 개인정보 처리방침",
                    ),
                    SettingsItem(
                      onTap: () => Get.toNamed('/LocatinServicePage'),
                      icons: Icons.location_on_rounded,
                      iconStyle: IconStyle(
                        backgroundColor: Colors.green,
                      ),
                      title: '위치기반 서비스 이용약관',
                      subtitle: "위치기반 서비스 이용약관",
                    ),
                    SettingsItem(
                      onTap: () => Get.toNamed('/OpenSourcePage'),
                      icons: Icons.insert_chart,
                      iconStyle: IconStyle(
                        backgroundColor: Colors.deepOrange,
                      ),
                      title: '오픈 소스 라이센스',
                      subtitle: "라이센스 목록",
                    ),
                    // SettingsItem(
                    //   onTap: () async {
                    //     outAlertDialog(context);
                    //   },
                    //   icons: Icons.exit_to_app_rounded,
                    //   iconStyle: IconStyle(
                    //     backgroundColor: Colors.deepOrange,
                    //   ),
                    //   title: "탈퇴하기",
                    //   subtitle: "재가입 불가, 데이터 영구삭재.",
                    //   titleStyle: const TextStyle(
                    //     color: Colors.red,
                    //     fontWeight: FontWeight.bold,
                    //   ),
                    // ),
                    // 릴리즈 버전에서만 보이는 버튼
                    if (kDebugMode) ...[
                      SettingsItem(
                        onTap: () async {
                          // bool? result = await Get.dialog<bool>(
                          //   PrivacyPolicyDialog(),
                          //   barrierDismissible: true,
                          // );
                          // AgreePage() 페이지로 이동 머터리얼 라우터를 이용
                          Navigator.push(context, MaterialPageRoute(builder: (context) => AgreePage()));
                        },
                        icons: Icons.exit_to_app_rounded,
                        iconStyle: IconStyle(
                          backgroundColor: Colors.deepOrange,
                        ),
                        title: "회원동의",
                        titleStyle: const TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SettingsItem(
                        onTap: () => Get.toNamed('/TestDioPage'),
                        icons: CupertinoIcons.link_circle,
                        title: "TestDioPage",
                        titleStyle: const TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SettingsItem(
                        onTap: () => Get.toNamed('/WeatherComparePage'),
                        icons: CupertinoIcons.link_circle,
                        title: "WeatherComparePage",
                        titleStyle: const TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SettingsItem(
                        onTap: () => Get.toNamed('/SupaTestPage'),
                        icons: CupertinoIcons.link_circle,
                        title: "SupaTestPage",
                        titleStyle: const TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      //
                    ]
                  ],
                ),
                const Gap(20),
                buildCompany(),
                const Gap(100),
              ],
            ),
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
    );
  }

  Widget buildCompany() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
          const Text(
            "코드랩타이거(CodeLabTiger)\n서울시 서대문구 TigerGroup, 사업자등록번호 : 770-50-01045",
            style: TextStyle(fontSize: 13, color: Colors.black54),
          ),
          const Gap(20),
          const Text(
            'Copyright 2024 TIGER Group',
            style: TextStyle(fontSize: 13, color: Colors.black),
          ),
          const Text(
            'All rights reserved',
            style: TextStyle(fontSize: 13, color: Colors.black),
          ),
          const Gap(20),
          Stack(
            children: [
              Image.asset('assets/images/5124556.jpg', fit: BoxFit.cover, width: double.infinity, height: 75),
              // Positioned(
              //   right: 0,
              //   bottom: 0,
              //   child: Container(
              //     color: Colors.white,
              //     child: const Text(
              //       "010-1588-1234",
              //       style: TextStyle(fontSize: 15, color: Colors.black, fontWeight: FontWeight.bold),
              //     ),
              //   ),
              // ),
            ],
          ),

          // 출처 <a href="https://kr.freepik.com/free-vector/flat-design-illustration-customer-support_12982910.htm#query=%EA%B3%A0%EA%B0%9D%EC%84%BC%ED%84%B0&position=1&from_view=keyword&track=ais&uuid=aa7b7691-daa1-46c6-88d0-55653a755271">Freepik</a>
        ],
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
                  borderRadius: BorderRadius.circular(20),
                  color: Colors.white,
                  shape: BoxShape.rectangle,
                  boxShadow: const [
                    BoxShadow(color: Colors.black, offset: Offset(0, 10), blurRadius: 10),
                  ],
                ),
                child: Column(
                  children: [
                    const Gap(20),
                    const Icon(Icons.warning, size: 50, color: Colors.red),
                    const Gap(20),
                    const Text(
                      "정말 탈퇴하시겠습니까?",
                      style: TextStyle(fontSize: 20, color: Colors.red, fontWeight: FontWeight.bold),
                    ),
                    const Gap(20),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 18.0),
                      child: Text(
                        "1년간 재가입 불가합니다. 데이터는 모두 삭제되어 복구 불가능합니다.",
                        style: TextStyle(fontSize: 12, color: Colors.black87, fontWeight: FontWeight.bold),
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
                        const Text(
                          '진짜 다시 확인해주세요!!',
                          style: TextStyle(fontSize: 12, color: Colors.black87, fontWeight: FontWeight.bold),
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
                          listColors: const [Colors.grey, Colors.grey],
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

/// This component group the Settings items (BabsComponentSettingsItem)
/// All one BabsComponentSettingsGroup have a title and the developper can improve the design.
class SettingsGroup extends StatelessWidget {
  final String? settingsGroupTitle;
  final TextStyle? settingsGroupTitleStyle;
  final List<SettingsItem> items;
  // Icons size
  final double? iconItemSize;

  SettingsGroup({this.settingsGroupTitle, this.settingsGroupTitleStyle, required this.items, this.iconItemSize = 25});

  @override
  Widget build(BuildContext context) {
    if (this.iconItemSize != null) SettingsScreenUtils.settingsGroupIconSize = iconItemSize;

    return Container(
      margin: EdgeInsets.only(bottom: 20),
      color: Colors.transparent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // The title
          (settingsGroupTitle != null)
              ? Padding(
                  padding: const EdgeInsets.only(bottom: 5),
                  child: Text(
                    settingsGroupTitle!,
                    style:
                        (settingsGroupTitleStyle == null) ? TextStyle(fontSize: 25, fontWeight: FontWeight.bold) : settingsGroupTitleStyle,
                  ),
                )
              : Container(),
          // The SettingsGroup sections
          Container(
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(15),
            ),
            child: ListView.separated(
              separatorBuilder: (context, index) {
                return Divider();
              },
              itemCount: items.length,
              itemBuilder: (BuildContext context, int index) {
                return items[index];
              },
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              physics: ScrollPhysics(),
            ),
          ),
        ],
      ),
    );
  }
}

class SettingsScreenUtils {
  static double? settingsGroupIconSize;
  static TextStyle? settingsGroupTitleStyle;
}

class SettingsItem extends StatelessWidget {
  final IconData icons;
  final IconStyle? iconStyle;
  final String title;
  final TextStyle? titleStyle;
  final String? subtitle;
  final TextStyle? subtitleStyle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final int? titleMaxLine;
  final int? subtitleMaxLine;
  final TextOverflow? overflow;

  SettingsItem(
      {required this.icons,
      this.iconStyle,
      required this.title,
      this.titleStyle,
      this.subtitle,
      this.subtitleStyle,
      this.backgroundColor,
      this.trailing,
      this.onTap,
      this.titleMaxLine,
      this.subtitleMaxLine,
      this.overflow = TextOverflow.ellipsis});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(15),
      child: ListTile(
        onTap: onTap,
        leading: (iconStyle != null && iconStyle!.withBackground!)
            ? Container(
                decoration: BoxDecoration(
                  color: iconStyle!.backgroundColor,
                  borderRadius: BorderRadius.circular(iconStyle!.borderRadius!),
                ),
                padding: EdgeInsets.all(5),
                child: Icon(
                  icons,
                  size: SettingsScreenUtils.settingsGroupIconSize,
                  color: iconStyle!.iconsColor,
                ),
              )
            : Padding(
                padding: EdgeInsets.all(5),
                child: Icon(
                  icons,
                  size: SettingsScreenUtils.settingsGroupIconSize,
                ),
              ),
        title: Text(
          title,
          style: titleStyle ?? TextStyle(fontWeight: FontWeight.bold),
          maxLines: titleMaxLine,
          overflow: titleMaxLine != null ? overflow : null,
        ),
        subtitle: (subtitle != null)
            ? Text(
                subtitle!,
                style: subtitleStyle ?? Theme.of(context).textTheme.bodyMedium!,
                maxLines: subtitleMaxLine,
                overflow: subtitleMaxLine != null ? TextOverflow.ellipsis : null,
              )
            : null,
        trailing: (trailing != null) ? trailing : Icon(Icons.navigate_next),
      ),
    );
  }
}

class IconStyle {
  Color? iconsColor;
  bool? withBackground;
  Color? backgroundColor;
  double? borderRadius;

  IconStyle({
    iconsColor = Colors.white,
    withBackground = true,
    backgroundColor = Colors.blue,
    borderRadius = 8,
  })  : this.iconsColor = iconsColor,
        this.withBackground = withBackground,
        this.backgroundColor = backgroundColor,
        this.borderRadius = double.parse(borderRadius!.toString());
}
