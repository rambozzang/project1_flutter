// import 'package:babstrap_settings_screen/babstrap_settings_screen.dart';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:project1/admob/ad_manager.dart';
import 'package:project1/admob/banner_ad_widget.dart';
import 'package:project1/app/auth/agree_page.dart';
import 'package:project1/app/auth/cntr/auth_cntr.dart';
import 'package:project1/app/shared_album/theme/sa_colors.dart';
import 'package:project1/app/shared_album/theme/sa_text_styles.dart';
// import 'package:flutter_image_compress/flutter_image_compress.dart';

import 'package:project1/root/cntr/root_cntr.dart';
import 'package:project1/utils/log_utils.dart';
import 'package:project1/widget/custom_button.dart';
import 'package:project1/widget/custom_indicator_offstage.dart';

/// 설정 화면 — "우리의 앨범"(shared_album)과 같은 디자인 토큰(SaColors/SaText)을 쓴다.
///
/// 이 화면은 **라이트 고정**이다. 앨범 페이지와 달리 `SaColors.syncWith(context)`를 호출하지
/// 않으므로 `SaColors.isLight` 기본값(true)의 라이트 팔레트가 그대로 적용된다.
/// (다크 대응은 별도 과제. 여기서 syncWith를 부르면 설정 화면 자체가 앨범 테마 설정값을
///  따라가 버려서, 앨범 테마를 고르는 화면이 함께 어두워지는 혼란이 생긴다.)
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
    RootCntr.to.bottomBarStreamController.sink.add(true);
    // 앨범 테마 현재값 표시용(저장값 복원 후 subtitle 갱신)
    SaColors.loadSavedMode().then((_) {
      if (mounted) setState(() {});
    });
  }

  String get _albumThemeLabel {
    switch (SaColors.themeMode) {
      case SaThemeMode.light:
        return '라이트';
      case SaThemeMode.dark:
        return '다크';
      case SaThemeMode.system:
        return '시스템 설정 따름';
    }
  }

  void _showAlbumThemeSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: SaColors.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(26))),
      builder: (context) {
        Widget option(
            SaThemeMode mode, IconData icon, String label, String desc) {
          final bool selected = SaColors.themeMode == mode;
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
            child: Material(
              color: selected
                  ? SaColors.accentTeal.withValues(alpha: 0.08)
                  : SaColors.surface,
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () async {
                  await SaColors.saveMode(mode);
                  if (mounted) setState(() {});
                  if (context.mounted) Navigator.of(context).pop();
                },
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: selected
                            ? SaColors.accentTeal
                            : SaColors.border),
                  ),
                  child: Row(
                    children: [
                      // 아이콘 칩 — pill(원형)
                      Container(
                        width: 36,
                        height: 36,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: selected
                              ? SaColors.accentTeal
                              : SaColors.surfaceElevated,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: PhosphorIcon(icon,
                            size: 18,
                            color: selected
                                ? SaColors.onAccent
                                : SaColors.textSecondary),
                      ),
                      const Gap(12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(label,
                                style: SaText.titleS.copyWith(
                                    fontWeight: selected
                                        ? FontWeight.w700
                                        : FontWeight.w500)),
                            const Gap(2),
                            Text(desc, style: SaText.caption),
                          ],
                        ),
                      ),
                      if (selected)
                        PhosphorIcon(PhosphorIconsBold.check,
                            size: 18, color: SaColors.accentTeal),
                    ],
                  ),
                ),
              ),
            ),
          );
        }

        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text('앨범 테마', style: SaText.titleS),
                ),
              ),
              option(SaThemeMode.system, PhosphorIconsBold.circleHalf,
                  '시스템 설정 따름', '휴대폰 다크모드 설정에 맞춰 자동 전환'),
              option(SaThemeMode.light, PhosphorIconsBold.sun, '라이트',
                  '앨범 화면을 항상 밝게'),
              option(SaThemeMode.dark, PhosphorIconsBold.moon, '다크',
                  '앨범 화면을 항상 어둡게'),
              const Gap(8),
            ],
          ),
        );
      },
    );
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
          backgroundColor: SaColors.bgBase,
          appBar: AppBar(
            forceMaterialTransparency: true,
            automaticallyImplyLeading: false,
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
                    shape: CircleBorder(
                        side: BorderSide(color: SaColors.borderStrong)),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () => Navigator.pop(context),
                      child: Center(
                        child: PhosphorIcon(PhosphorIconsBold.caretLeft,
                            size: 17, color: SaColors.textPrimary),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            title: Text("설정", style: SaText.titleS),
            centerTitle: true,
            // backgroundColor: Colors.transparent,
            elevation: 0,
          ),
          body: SingleChildScrollView(
            // controller:
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Column(
              children: [
                SettingsGroup(
                  settingsGroupTitle: "문의",
                  settingsGroupTitleStyle: SaText.titleS,
                  items: [
                    SettingsItem(
                      onTap: () => Get.toNamed('/NotiPage'),
                      icons: PhosphorIconsBold.signOut,
                      backgroundColor: SaColors.surface,
                      title: "공지사항",
                    ),
                    SettingsItem(
                      onTap: () => Get.toNamed('/FaqPage'),
                      icons: PhosphorIconsBold.repeat,
                      title: "FAQ",
                    ),
                  ],
                ),
                SettingsGroup(
                  settingsGroupTitle: "커뮤니티",
                  settingsGroupTitleStyle: SaText.titleS,
                  items: [
                    SettingsItem(
                      // 라운지 하단탭이 새 앨범 허브(CommunityHubPage)로 바뀌어,
                      // 기존 라운지(게시판 등 '스카이 라운지')는 설정에서 진입하도록 링크 제공.
                      onTap: () => Get.toNamed('/AlramPage'),
                      icons: PhosphorIconsFill.usersThree,
                      iconStyle: IconStyle(
                        iconsColor: Colors.white,
                        withBackground: true,
                        backgroundColor: Colors.teal[300],
                      ),
                      title: '스카이 라운지',
                      subtitle: "게시판 등 기존 라운지 화면",
                      titleMaxLine: 1,
                      subtitleMaxLine: 1,
                    ),
                  ],
                ),
                SettingsGroup(
                  settingsGroupTitle: "설정",
                  settingsGroupTitleStyle: SaText.titleS,
                  items: [
                    SettingsItem(
                      onTap: () => Get.toNamed('/AlramSettingPage'),
                      icons: PhosphorIconsFill.bell,
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
                    // 날씨 상태바 상시 알림은 Android에서만 지원(iOS는 OS 제약으로 불가)
                    if (Platform.isAndroid)
                      SettingsItem(
                        onTap: () => Get.toNamed('/WeatherNotiSettingPage'),
                        icons: PhosphorIconsFill.sun,
                        iconStyle: IconStyle(
                          iconsColor: Colors.white,
                          withBackground: true,
                          backgroundColor: Colors.orange[300],
                        ),
                        title: '날씨 상태바 알림',
                        subtitle: "상태바에 현재 날씨를 상시 표시합니다.",
                        titleMaxLine: 1,
                        subtitleMaxLine: 1,
                      ),
                    SettingsItem(
                      onTap: _showAlbumThemeSheet,
                      icons: PhosphorIconsFill.moonStars,
                      iconStyle: IconStyle(
                        iconsColor: Colors.white,
                        withBackground: true,
                        backgroundColor: Colors.blueGrey[400],
                      ),
                      title: '앨범 테마',
                      subtitle: "현재: $_albumThemeLabel",
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
                // 프리미엄 구독 진입(광고 제거·프리미엄 날씨·전용 테마)
                Obx(() => SettingsGroup(
                      settingsGroupTitle: "SkySnap Premium",
                      settingsGroupTitleStyle: SaText.titleS,
                      items: [
                        SettingsItem(
                          onTap: () => Get.toNamed('/PremiumPage'),
                          icons: PhosphorIconsFill.star,
                          backgroundColor: SaColors.surface,
                          iconStyle: IconStyle(
                            iconsColor: Colors.white,
                            withBackground: true,
                            backgroundColor: Colors.amber,
                          ),
                          title: AuthCntr.to.isPremium.value ? '프리미엄 이용 중' : '프리미엄 구독',
                          subtitle: AuthCntr.to.isPremium.value
                              ? '광고 없이 쾌적하게 이용 중이에요'
                              : '광고 제거 · 프리미엄 날씨 · 전용 앨범 테마',
                          titleMaxLine: 1,
                          subtitleMaxLine: 1,
                        ),
                      ],
                    )),
                const Gap(30),
                SettingsGroup(
                  settingsGroupTitle: "개인정 동의 및 약관",
                  settingsGroupTitleStyle: SaText.titleS,
                  items: [
                    if (kDebugMode) ...[
                      SettingsItem(
                        onTap: () => Get.toNamed('/MaketingPage'),
                        icons: PhosphorIconsBold.pencilSimple,
                        backgroundColor: SaColors.surface,
                        iconStyle: IconStyle(),
                        title: '마케팅 수신 동의 설정',
                        subtitle:
                            "다양한 맴버 혜택을 담은 마케팅 정보를 SMS, 이메일, 앱 푸시로 보내드립니다.",
                        titleMaxLine: 1,
                        subtitleMaxLine: 1,
                      ),
                    ],
                    SettingsItem(
                      onTap: () => Get.toNamed('/ServicePage'),
                      icons: PhosphorIconsFill.info,
                      backgroundColor: SaColors.surface,
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
                      backgroundColor: SaColors.surface,
                      icons: PhosphorIconsFill.info,
                      iconStyle: IconStyle(
                        backgroundColor: Colors.purple,
                      ),
                      title: '개인정보 처리방침',
                      subtitle: "회사 개인정보 처리방침",
                    ),
                    SettingsItem(
                      onTap: () => Get.toNamed('/LocatinServicePage'),
                      icons: PhosphorIconsFill.mapPin,
                      iconStyle: IconStyle(
                        backgroundColor: Colors.green,
                      ),
                      title: '위치기반 서비스 이용약관',
                      subtitle: "위치기반 서비스 이용약관",
                    ),
                    SettingsItem(
                      onTap: () => Get.toNamed('/OpenSourcePage'),
                      icons: PhosphorIconsFill.chartBar,
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
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const AgreePage()));
                        },
                        icons: PhosphorIconsBold.signOut,
                        iconStyle: IconStyle(
                          backgroundColor: Colors.deepOrange,
                        ),
                        title: "회원동의",
                        // 위험(탈퇴 계열) 강조 — SaColors에 대응 토큰이 없어 원본 red 유지.
                        titleStyle: SaText.titleS.copyWith(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SettingsItem(
                        onTap: () => Get.toNamed('/SaPreviewPage'),
                        icons: PhosphorIconsFill.images,
                        backgroundColor: SaColors.surface,
                        iconStyle: IconStyle(),
                        title: '공유앨범 위젯 미리보기 (디자인 검수)',
                        titleMaxLine: 1,
                        subtitleMaxLine: 1,
                      ),
                      SettingsItem(
                        onTap: () => Get.toNamed('/AlbumListPage'),
                        icons: PhosphorIconsBold.stack,
                        backgroundColor: SaColors.surface,
                        iconStyle: IconStyle(),
                        title: '공유앨범 홈 1a (디자인 검수)',
                        titleMaxLine: 1,
                        subtitleMaxLine: 1,
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
      // 좌우는 스크롤뷰의 화면 패딩 16을 그대로 쓴다(중복 인셋 제거).
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "코드랩타이거(CodeLabTiger)\n사업자등록번호 : 770-50-01045",
            style: SaText.caption.copyWith(color: SaColors.textSecondary),
          ),
          const Gap(20),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              'Copyright 2024 TIGER Group',
              style: SaText.caption.copyWith(color: SaColors.textTertiary),
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              'All rights reserved',
              style: SaText.caption.copyWith(color: SaColors.textTertiary),
            ),
          ),
          const Gap(20),
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.asset('assets/images/5124556.jpg',
                    fit: BoxFit.cover, width: double.infinity, height: 75),
              ),
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
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
            content: Container(
                height: 390,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(26),
                  color: SaColors.surface,
                  shape: BoxShape.rectangle,
                  border: Border.all(color: SaColors.border),
                  boxShadow: const [
                    BoxShadow(
                        color: Colors.black,
                        offset: Offset(0, 10),
                        blurRadius: 10),
                  ],
                ),
                child: Column(
                  children: [
                    const Gap(20),
                    // 위험(탈퇴) 강조 — SaColors에 대응 토큰이 없어 원본 red 유지.
                    const PhosphorIcon(PhosphorIconsFill.warning,
                        size: 50, color: Colors.red),
                    const Gap(20),
                    Text(
                      "정말 탈퇴하시겠습니까?",
                      style: SaText.titleM.copyWith(
                          fontSize: 20,
                          color: Colors.red,
                          fontWeight: FontWeight.bold),
                    ),
                    const Gap(20),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18.0),
                      child: Text(
                        "1년간 재가입 불가합니다. 데이터는 모두 삭제되어 복구 불가능합니다.",
                        style: SaText.caption.copyWith(
                            color: SaColors.textPrimary,
                            fontWeight: FontWeight.bold),
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
                          style: SaText.caption.copyWith(
                              color: SaColors.textPrimary,
                              fontWeight: FontWeight.bold),
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

  const SettingsGroup(
      {super.key,
      this.settingsGroupTitle,
      this.settingsGroupTitleStyle,
      required this.items,
      this.iconItemSize = 25});

  @override
  Widget build(BuildContext context) {
    if (iconItemSize != null)
      SettingsScreenUtils.settingsGroupIconSize = iconItemSize;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      color: Colors.transparent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // The title
          (settingsGroupTitle != null)
              ? Padding(
                  padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
                  child: Text(
                    settingsGroupTitle!,
                    style: (settingsGroupTitleStyle == null)
                        ? SaText.titleM
                        : settingsGroupTitleStyle,
                  ),
                )
              : Container(),
          // The SettingsGroup sections — 핸드오프 규격: 카드 r26 / surface / border / 내부 패딩 14
          // 카드 배경은 Container가 아니라 Material이 그린다. Container에 색을 주면 그 위에
          // 얹힌 ListTile의 잉크 리플이 가려진다(프레임워크 assert).
          Material(
            color: SaColors.surface,
            borderRadius: BorderRadius.circular(26),
            clipBehavior: Clip.antiAlias,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(26),
                border: Border.all(color: SaColors.border),
              ),
              padding: const EdgeInsets.all(14),
              child: ListView.separated(
                separatorBuilder: (context, index) {
                  return Divider(
                      color: SaColors.border, height: 13, thickness: 1);
                },
                itemCount: items.length,
                itemBuilder: (BuildContext context, int index) {
                  return items[index];
                },
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                physics: const ScrollPhysics(),
              ),
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

  const SettingsItem(
      {super.key,
      required this.icons,
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
      borderRadius: BorderRadius.circular(14),
      child: ListTile(
        onTap: onTap,
        // 카드가 이미 내부 패딩 14를 가지므로 ListTile 기본 인셋은 제거한다.
        contentPadding: const EdgeInsets.symmetric(vertical: 2),
        leading: (iconStyle != null && iconStyle!.withBackground!)
            ? Container(
                decoration: BoxDecoration(
                  color: iconStyle!.backgroundColor,
                  borderRadius: BorderRadius.circular(iconStyle!.borderRadius!),
                ),
                padding: const EdgeInsets.all(5),
                child: PhosphorIcon(
                  icons,
                  size: SettingsScreenUtils.settingsGroupIconSize,
                  color: iconStyle!.iconsColor,
                ),
              )
            : Padding(
                padding: const EdgeInsets.all(5),
                child: PhosphorIcon(
                  icons,
                  size: SettingsScreenUtils.settingsGroupIconSize,
                  color: SaColors.textPrimary,
                ),
              ),
        title: Text(
          title,
          style: titleStyle ?? SaText.titleS,
          maxLines: titleMaxLine,
          overflow: titleMaxLine != null ? overflow : null,
        ),
        subtitle: (subtitle != null)
            ? Text(
                subtitle!,
                style: subtitleStyle ?? SaText.body.copyWith(fontSize: 13),
                maxLines: subtitleMaxLine,
                overflow:
                    subtitleMaxLine != null ? TextOverflow.ellipsis : null,
              )
            : null,
        trailing: (trailing != null)
            ? trailing
            : PhosphorIcon(PhosphorIconsBold.caretRight,
                size: 16, color: SaColors.textTertiary),
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
    // 칩은 pill — 핸드오프 규격(칩/버튼 999). 아이콘 칩 배경색은 항목 구분용이라 원본 유지.
    borderRadius = 999,
  })  : iconsColor = iconsColor,
        withBackground = withBackground,
        backgroundColor = backgroundColor,
        borderRadius = double.parse(borderRadius!.toString());
}
