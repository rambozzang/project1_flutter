import 'dart:io';

import 'package:babstrap_settings_screen/babstrap_settings_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
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
                  onTap: () {},
                  icons: Icons.exit_to_app_rounded,
                  title: "공지사항",
                ),
                SettingsItem(
                  onTap: () {},
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
                  onTap: () {},
                  icons: CupertinoIcons.pencil_outline,
                  iconStyle: IconStyle(),
                  title: '마케팅 수신 동의 설정',
                  subtitle: "다양한 맴버 혜택을 담은 마케팅 정보를 SMS, 이메일, 앱 푸시로 보내드립니다.",
                  titleMaxLine: 1,
                  subtitleMaxLine: 1,
                ),
                SettingsItem(
                  onTap: () {},
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
                  onTap: () {},
                  icons: Icons.dark_mode_rounded,
                  iconStyle: IconStyle(
                    iconsColor: Colors.white,
                    withBackground: true,
                    backgroundColor: Colors.red,
                  ),
                  title: 'Dark mode',
                  subtitle: "Automatic",
                  trailing: Switch.adaptive(
                    value: false,
                    onChanged: (value) {},
                  ),
                ),
              ],
            ),
            SettingsGroup(
              items: [
                SettingsItem(
                  onTap: () {},
                  icons: Icons.info_rounded,
                  iconStyle: IconStyle(
                    backgroundColor: Colors.purple,
                  ),
                  title: '개인정보 처리방침',
                  subtitle: "Learn more about Ziar'App",
                ),
                SettingsItem(
                  onTap: () {},
                  icons: CupertinoIcons.delete_solid,
                  title: "회원탈퇴",
                  titleStyle: const TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SettingsItem(
                  onTap: () => Get.toNamed('/MainView1'),
                  icons: CupertinoIcons.delete_solid,
                  title: "TestPage",
                  titleStyle: const TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Gap(250),
          ],
        ),
      ),
    );
  }

  Widget _info() {
    return Container(
      margin: const EdgeInsets.all(10.0),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        shape: BoxShape.rectangle,
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Padding(
            padding: const EdgeInsets.all(15.0),
            child: GestureDetector(
                onTap: () => getImage(ImageSource.gallery),
                child: ImageAvatar(width: 70, url: AuthCntr.to.resLoginData.value.profilePath!, type: AvatarType.MYSTORY)),
          ),
          const Expanded(
            flex: 3,
            child: Padding(
              padding: EdgeInsets.all(10.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Padding(
                    padding: EdgeInsets.all(10.0),
                    child: MyPageInfo(
                      count: 35,
                      label: '게시물',
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.all(10.0),
                    child: MyPageInfo(count: 167, label: '팔로워'),
                  ),
                  Padding(
                    padding: EdgeInsets.all(10.0),
                    child: MyPageInfo(count: 144, label: '팔로잉'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
