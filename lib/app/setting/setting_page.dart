import 'dart:io';

import 'package:babstrap_settings_screen/babstrap_settings_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:gap/gap.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:project1/app/auth/cntr/auth_cntr.dart';
import 'package:project1/app/myinfo/myinfo_page.dart';
import 'package:project1/app/myinfo/widget/image_avatar.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

import 'package:path_provider/path_provider.dart';
import 'package:project1/root/cntr/root_cntr.dart';
import 'package:project1/widget/ads_page.dart';

class SettingPage extends StatefulWidget {
  const SettingPage({Key? key}) : super(key: key);

  @override
  State<SettingPage> createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage> {
  XFile? _image; //이미지를 담을 변수 선언
  final ImagePicker picker = ImagePicker(); //ImagePicker 초기화

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
  }

  //이미지를 가져오는 함수
  Future getImage(ImageSource imageSource) async {
    //pickedFile에 ImagePicker로 가져온 이미지가 담긴다.
    final XFile? pickedFile = await picker.pickImage(source: imageSource);
    if (pickedFile != null) {
      _image = XFile(pickedFile.path); //가져온 이미지를 _image에 저장

      CroppedFile? croppedFile = await ImageCropper().cropImage(
        sourcePath: pickedFile.path,
        aspectRatioPresets: [
          CropAspectRatioPreset.square,
          CropAspectRatioPreset.ratio3x2,
          CropAspectRatioPreset.original,
          CropAspectRatioPreset.ratio4x3,
          CropAspectRatioPreset.ratio16x9
        ],
        uiSettings: [
          AndroidUiSettings(
              toolbarTitle: 'Cropper',
              toolbarColor: Colors.deepOrange,
              toolbarWidgetColor: Colors.white,
              initAspectRatio: CropAspectRatioPreset.original,
              lockAspectRatio: false),
          IOSUiSettings(
            title: 'Cropper',
          ),
          WebUiSettings(
            context: context,
          ),
        ],
      );

      if (croppedFile != null) {
        setState(() {
          _image = XFile(croppedFile.path);
        });
      }

      File aa = await CompressAndGetFile(croppedFile!.path);

      print(aa.lengthSync());
      AuthCntr.to.resLoginData.value.profilePath = aa.path;
    }
  }

  Future<File> CompressAndGetFile(String path) async {
    var tmpDir = await getTemporaryDirectory();
    var targetName = DateTime.now().millisecondsSinceEpoch;
    XFile? compressFile = await FlutterImageCompress.compressAndGetFile(
      path,
      "${tmpDir.absolute.path}/$targetName.jpg",
      quality: 88,
      rotate: 180,
    );
    // print(file.lengthSync());
    print(compressFile?.length());
    final bytes = await File(compressFile!.path);
    return bytes;
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
            // _info(),

            // user card
            // SimpleUserCard(
            //   userName: AuthCntr.to.resLoginData.value.custNm.toString(),
            //   userMoreInfo: Text(
            //     "Voir le profil",
            //     style: const TextStyle(color: Colors.blue),
            //   ),
            //   imageRadius: 20,
            //   userProfilePic: CachedNetworkImageProvider(AuthCntr.to.resLoginData.value.profilePath!),
            // ),
            // You can add a settings title
            SettingsGroup(
              settingsGroupTitle: "문의",
              settingsGroupTitleStyle: const TextStyle(color: Colors.black, fontWeight: FontWeight.w700, fontSize: 16),
              items: [
                SettingsItem(
                  onTap: () => Get.toNamed('/NotiPage'),
                  icons: Icons.exit_to_app_rounded,
                  title: "공지사항",
                ),
                SettingsItem(
                  onTap: () => Get.toNamed('/FaqPage'),
                  icons: CupertinoIcons.repeat,
                  title: "FAQ",
                ),
                // SettingsItem(
                //   onTap: () => Get.toNamed('/FaqPage'),
                //   icons: CupertinoIcons.arrow_turn_down_right,
                //   title: "1대1 건의사항",
                // ),
              ],
            ),

            SettingsGroup(
              settingsGroupTitle: "설정",
              settingsGroupTitleStyle: const TextStyle(color: Colors.black, fontWeight: FontWeight.w700, fontSize: 16),
              items: [
                SettingsItem(
                  onTap: () {},
                  icons: CupertinoIcons.pencil_outline,
                  iconStyle: IconStyle(),
                  title: '마케팅 수신 동의 설정',
                  subtitle: "다양한 맴버 혜택을 담은 마케팅 정보를 SMS, 이메일, 앱 푸시로 보내드립니다.",
                  titleMaxLine: 1,
                  subtitleMaxLine: 1,
                ),
                // SettingsItem(
                //   onTap: () {},
                //   icons: Icons.dark_mode_rounded,
                //   iconStyle: IconStyle(
                //     iconsColor: Colors.white,
                //     withBackground: true,
                //     backgroundColor: Colors.red,
                //   ),
                //   title: 'Dark mode',
                //   subtitle: "Automatic",
                //   trailing: Switch.adaptive(
                //     value: false,
                //     onChanged: (value) {},
                //   ),
                // ),
              ],
            ),
            buildAddmob(),
            SettingsGroup(
              items: [
                SettingsItem(
                  onTap: () => Get.toNamed('/AgreePage'),
                  icons: Icons.fingerprint,
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
                SettingsItem(
                  onTap: () => Get.toNamed('/TestDioPage'),
                  icons: CupertinoIcons.link_circle,
                  title: "TestDioPage",
                  titleStyle: const TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                // SettingsItem(
                //   onTap: () => Get.toNamed('/FollowListPage'),
                //   icons: CupertinoIcons.delete_solid,
                //   title: "FollowListPage",
                //   titleStyle: const TextStyle(
                //     color: Colors.red,
                //     fontWeight: FontWeight.bold,
                //   ),
                // ),
              ],
            ),
            const Gap(20),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  const Text(
                    "CodeLabTiger\n서울시 서대문구 종로35길 125 TigerGroup (05510)  대표자 : tigerBk, 사업자등록번호 : 110-81-28774 ",
                    style: TextStyle(fontSize: 13, color: Colors.black54),
                  ),
                  const Gap(20),
                  const Text(
                    'Copyright 2024 TIGER Group..',
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
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          color: Colors.white,
                          child: Text(
                            "02-1588-1234",
                            style: TextStyle(fontSize: 15, color: Colors.black, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),

                  // 출처 <a href="https://kr.freepik.com/free-vector/flat-design-illustration-customer-support_12982910.htm#query=%EA%B3%A0%EA%B0%9D%EC%84%BC%ED%84%B0&position=1&from_view=keyword&track=ais&uuid=aa7b7691-daa1-46c6-88d0-55653a755271">Freepik</a>
                ],
              ),
            ),
            const Gap(100),
          ],
        ),
      ),
    );
  }
}
