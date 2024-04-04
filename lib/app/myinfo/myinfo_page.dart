import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_connect/http/src/utils/utils.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:project1/app/auth/cntr/auth_cntr.dart';
import 'package:project1/app/list/api_service.dart';
import 'package:project1/app/myinfo/widget/image_avatar.dart';
import 'package:project1/utils/utils.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

import 'package:path_provider/path_provider.dart';

// 사진촬영
// https://dariadobszai.medium.com/set-profile-photo-with-flutter-bloc-or-how-to-bloc-backward-9fb16faa56ed

class MyPage extends StatefulWidget {
  const MyPage({super.key});

  @override
  State<MyPage> createState() => _MyPageState();
}

class _MyPageState extends State<MyPage> {
  final ValueNotifier<List<String>> urls = ValueNotifier<List<String>>([]);

  XFile? _image; //이미지를 담을 변수 선언
  final ImagePicker picker = ImagePicker(); //ImagePicker 초기화

  @override
  void initState() {
    super.initState();
    getData();
  }

  Future<void> getData() async {
    urls.value = await ApiService.getVideos();
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
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      initialIndex: 0,
      child: Scaffold(
        appBar: _appBar(),
        body: RefreshIndicator.adaptive(
          notificationPredicate: (notification) {
            if (notification is OverscrollNotification || Platform.isIOS) {
              return notification.depth == 2;
            }
            return notification.depth == 0;
          },
          onRefresh: () async {
            await Future.delayed(const Duration(seconds: 1));
          },
          child: NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                SliverList(delegate: SliverChildListDelegate([_info(), _buttons()])),
              ];
            },
            body: Column(
              children: [
                _tabs(),
                _tabBarView(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _info() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Padding(
          padding: const EdgeInsets.all(15.0),
          child: GestureDetector(
              onTap: () => getImage(ImageSource.gallery),
              child: ImageAvatar(width: 100, url: AuthCntr.to.resLoginData.value.profilePath!, type: AvatarType.MYSTORY)),
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
    );
  }

  Widget _buttons() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(flex: 4, child: MyPageButton(onTap: () {}, label: '프로필 편집')),
          const SizedBox(
            width: 10.0,
          ),
          Expanded(flex: 4, child: MyPageButton(onTap: () {}, label: '프로필 공유')),
          const SizedBox(
            width: 10.0,
          ),
          Container(
              width: 40,
              height: 40,
              padding: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(color: const Color(0xfff3f3f3), borderRadius: BorderRadius.circular(4.0)),
              child: const Icon(Icons.person_add))
        ],
      ),
    );
  }

  Widget _tabBarView() {
    return Expanded(
      child: TabBarView(children: [
        _myFeeds(),
        _tagImages(),
      ]),
    );
  }

  Widget _myFeeds() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: ValueListenableBuilder<List<String>>(
          valueListenable: urls,
          builder: (context, value, child) {
            return value.length > 0
                ? GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3, //1 개의 행에 보여줄 item 개수
                      childAspectRatio: 3 / 5, //item 의 가로 1, 세로 1 의 비율
                      mainAxisSpacing: 6, //수평 Padding
                      crossAxisSpacing: 3, //수직 Padding
                    ),
                    itemCount: 50,
                    itemBuilder: (context, index) => Container(
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          borderRadius: BorderRadius.circular(10.0),
                          image: DecorationImage(
                            image: NetworkImage(value[index]),
                            fit: BoxFit.cover,
                          ),
                        ),
                        child: const Align(
                          alignment: Alignment.bottomRight,
                          child: Row(
                            children: [
                              Icon(
                                Icons.play_arrow_outlined,
                                color: Colors.white,
                              ),
                              Text(
                                '12,000',
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        )),
                  )
                : Utils.progressbar();
          }),
    );
  }

  Widget _tagImages() {
    return GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 1.0, mainAxisSpacing: 1.0),
        itemCount: 50,
        itemBuilder: (context, index) => Container(
              color: Colors.red,
            ));
  }

  Widget _tabs() {
    return const TabBar(indicatorColor: Colors.black, tabs: [
      Tab(
        child: Icon(Icons.grid_on),
      ),
      Tab(
        child: Icon(Icons.person_pin),
      ),
    ]);
  }

  PreferredSizeWidget _appBar() {
    return AppBar(
      // appbar scroll시 bgColor 변경 방지
      forceMaterialTransparency: true,
      // scrolledUnderElevation: 0.0,
      title: Row(
        children: [
          InkWell(
            onTap: () {
              showModalBottomSheet(
                  showDragHandle: true,
                  shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.only(topLeft: Radius.circular(10.0), topRight: Radius.circular(10.0))),
                  context: context,
                  builder: (context) => Container(
                        height: 400,
                      ));
            },
            child: Text(
              AuthCntr.to.resLoginData.value.custNm.toString(),
              style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      actions: [
        Padding(
          padding: EdgeInsets.all(14.0),
          child: IconButton(icon: Icon(Icons.menu), onPressed: () => Get.toNamed('SettingPage')),
        ),
      ],
    );
  }
}

class MyPageButton extends StatelessWidget {
  final void Function()? onTap;
  final String label;
  const MyPageButton({super.key, this.onTap, required this.label});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
        onTap: onTap,
        child: Container(
          height: 40,
          decoration: BoxDecoration(color: const Color(0xfff3f3f3), borderRadius: BorderRadius.circular(8.0)),
          child: Center(
              child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
          )),
        ));
  }
}

class MyPageInfo extends StatelessWidget {
  final int count;
  final String label;
  const MyPageInfo({super.key, required this.count, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 15),
        ),
      ],
    );
  }
}
