import 'dart:async';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:gap/gap.dart';
import 'package:get/get.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:project1/app/auth/cntr/auth_cntr.dart';
import 'package:project1/app/myinfo/widget/image_avatar.dart';
import 'package:project1/repo/board/board_repo.dart';
import 'package:project1/repo/board/data/board_weather_list_data.dart';
import 'package:project1/repo/board/data/cust_count_data.dart';
import 'package:project1/repo/common/res_data.dart';
import 'package:project1/repo/common/res_stream.dart';
import 'package:project1/repo/cust/cust_repo.dart';
import 'package:project1/repo/cust/data/cust_update_data.dart';
import 'package:project1/root/cntr/root_cntr.dart';
import 'package:project1/utils/utils.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

import 'package:path_provider/path_provider.dart';
import 'package:project1/widget/custom_button.dart';
import 'package:rxdart/rxdart.dart';
import 'package:share_plus/share_plus.dart';

// 사진촬영
// https://dariadobszai.medium.com/set-profile-photo-with-flutter-bloc-or-how-to-bloc-backward-9fb16faa56ed

class MyPage extends StatefulWidget {
  const MyPage({super.key});

  @override
  State<MyPage> createState() => _MyPageState();
}

class _MyPageState extends State<MyPage> with AutomaticKeepAliveClientMixin {
  final ValueNotifier<List<String>> urls = ValueNotifier<List<String>>([]);

  @override
  bool get wantKeepAlive => true;

  XFile? _image; //이미지를 담을 변수 선언
  final ImagePicker picker = ImagePicker(); //ImagePicker 초기화
  // 상태유지

  // 3가지 갯수 가져오기
  StreamController<ResStream<CustCountData>> myCountCntr = StreamController();

  // 내게시물 리스트 가져오기
  int myboardPageNum = 0;
  int myboardageSize = 5000;
  StreamController<ResStream<List<BoardWeatherListData>>> myVideoListCntr = BehaviorSubject();

  // 팔로워 리스트 가져오기
  int followboardPageNum = 0;
  int followboardageSize = 5000;
  StreamController<ResStream<List<BoardWeatherListData>>> followVideoListCntr = BehaviorSubject();

  // 관심태그 리스트 가져오기
  StreamController<ResStream<List<String>>> tagStream = StreamController();

  // 관심태그 추가
  TextEditingController tagController = TextEditingController();

  FocusNode textFocus = FocusNode();
  bool _keyboardVisible = false;

  @override
  void initState() {
    super.initState();
    getCountData();
    getMyBoard();
    getFollowBoard();
    getTag();
    textFocus.addListener(() {
      if (textFocus.hasFocus) {
        RootCntr.to.bottomBarStreamController.sink.add(false);
      } else {
        RootCntr.to.bottomBarStreamController.sink.add(true);
      }
    });
  }

  Future<void> getCountData() async {
    try {
      //  myCountCntr.sink.add(ResStream.loading());
      BoardRepo repo = BoardRepo();
      ResData res = await repo.getCustCount(Get.find<AuthCntr>().resLoginData.value.custId.toString());
      if (res.code != '00') {
        Utils.alert(res.msg.toString());
        return;
      }
      print(res.data);
      CustCountData data = CustCountData.fromMap(res.data);
      myCountCntr.sink.add(ResStream.completed(data));
    } catch (e) {
      Utils.alert(e.toString());
      myCountCntr.sink.add(ResStream.error(e.toString()));
    }
  }

  Future<void> getMyBoard() async {
    try {
      myVideoListCntr.sink.add(ResStream.loading());
      BoardRepo repo = BoardRepo();
      ResData res = await repo.getMyBoard(Get.find<AuthCntr>().resLoginData.value.custId.toString(), myboardPageNum, myboardageSize);
      if (res.code != '00') {
        Utils.alert(res.msg.toString());
        return;
      }
      print(res.data);
      List<BoardWeatherListData> list = ((res.data) as List).map((data) => BoardWeatherListData.fromMap(data)).toList();
      myVideoListCntr.sink.add(ResStream.completed(list));
    } catch (e) {
      Utils.alert(e.toString());
      myVideoListCntr.sink.add(ResStream.error(e.toString()));
    }
  }

  Future<void> getFollowBoard() async {
    try {
      followVideoListCntr.sink.add(ResStream.loading());
      BoardRepo repo = BoardRepo();
      ResData res =
          await repo.getFollowBoard(Get.find<AuthCntr>().resLoginData.value.custId.toString(), followboardPageNum, followboardageSize);
      if (res.code != '00') {
        Utils.alert(res.msg.toString());
        return;
      }
      print(res.data);
      List<BoardWeatherListData> list = ((res.data) as List).map((data) => BoardWeatherListData.fromMap(data)).toList();
      followVideoListCntr.sink.add(ResStream.completed(list));
    } catch (e) {
      Utils.alert(e.toString());
      followVideoListCntr.sink.add(ResStream.error(e.toString()));
    }
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
        _image = XFile(croppedFile.path);
      }

      File aa = await CompressAndGetFile(croppedFile!.path);
      // TODO 파입업로드 후 고객정보 수정
      // 파일업로드후 save() 함수 호출
      //AuthCntr.to.resLoginData.value.profilePath = aa.path;
      Utils.alertIcon('파일업로드 개발중....', icontype: 'E');
      print(aa.lengthSync());
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

  Future<void> share() async {
    // final result = await Share.shareXFiles([XFile('${directory.path}/image.jpg')], text: 'Great picture');

    // if (result.status == ShareResultStatus.success) {
    //     print('Thank you for sharing the picture!');
    // }
    final result = await Share.shareWithResult('check out my website https://example.com');

    if (result.status == ShareResultStatus.success) {
      print('Thank you for sharing my website!');
    }
  }

  // 프로필 사진 업데이트
  Future<void> save() async {
    try {
      CustRepo repo = CustRepo();
      CustUpdataData data = CustUpdataData();
      data.custId = AuthCntr.to.resLoginData.value.custId.toString();
      data.profilePath = AuthCntr.to.resLoginData.value.profilePath.toString();
      ResData res = await repo.updateCust(data);
      if (res.code != '00') {
        Utils.alert(res.msg.toString());
        return;
      }
      Utils.alert('수정되었습니다.');
    } catch (e) {
      Utils.alert(e.toString());
    }
  }

  // 관심태그 삭제
  Future<void> removeTag(String tagNm) async {
    try {
      CustRepo repo = CustRepo();
      ResData res = await repo.deleteTag(AuthCntr.to.resLoginData.value.custId.toString(), tagNm);
      if (res.code != '00') {
        Utils.alert(res.msg.toString());
        return;
      }
      // Utils.alert('삭제되었습니다.');
      getTag();
    } catch (e) {
      Utils.alert(e.toString());
    }
  }

  // 관심태그 추가
  Future<void> addTag(String tagNm) async {
    try {
      CustRepo repo = CustRepo();
      ResData res = await repo.saveTag(AuthCntr.to.resLoginData.value.custId.toString(), tagNm);
      if (res.code != '00') {
        Utils.alert(res.msg.toString());
        return;
      }
      // Utils.alert('추가되었습니다.');
      getTag();
    } catch (e) {
      Utils.alert(e.toString());
    }
  }

  // 관심태그 조회
  Future<void> getTag() async {
    try {
      CustRepo repo = CustRepo();
      ResData res = await repo.getTagList(AuthCntr.to.resLoginData.value.custId.toString());
      if (res.code != '00') {
        Utils.alert(res.msg.toString());
        return;
      }
      List<String> _list = (res.data as List).map((e) => e['tagNm'].toString()).toList();

      tagStream.sink.add(ResStream.completed(_list));
    } catch (e) {
      Utils.alert(e.toString());
      // myCountCntr.sink.add(ResStream.error(e.toString()));
    }
  }

  @override
  void dispose() {
    myCountCntr.close();
    myVideoListCntr.close();
    followVideoListCntr.close();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      initialIndex: 0,
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        appBar: _appBar(),
        body: RefreshIndicator.adaptive(
          notificationPredicate: (notification) {
            if (notification is OverscrollNotification || Platform.isIOS) {
              return notification.depth == 2;
            }
            return notification.depth == 0;
          },
          onRefresh: () async {
            // 3가지 갯수 가져오기
            getCountData();
            getMyBoard();
            getFollowBoard();
            getTag();
          },
          child: NestedScrollView(
            controller: RootCntr.to.hideButtonController2,
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                SliverList(delegate: SliverChildListDelegate([_info(), _buttons(), _buildFavoriteTag()])),
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
    return Container(
      margin: const EdgeInsets.all(10.0),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        shape: BoxShape.rectangle,
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: Utils.commonStreamBody<CustCountData>(myCountCntr, _builtCount, getCountData),
    );
  }

  Widget _buildFavoriteTag() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text('관심태그', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              const Spacer(),
              const Text('*위치기반과 관심사를 기준으로 리스트구성.', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 10, color: Colors.grey)),
              const Gap(10),
              SizedBox(
                height: 20,
                width: 20,
                child: IconButton(
                    padding: const EdgeInsets.all(0),
                    constraints: const BoxConstraints(),
                    style: ButtonStyle(
                      shape: MaterialStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                      padding: MaterialStateProperty.all(EdgeInsets.zero),
                      backgroundColor: MaterialStateProperty.all(Colors.grey),
                    ),
                    onPressed: () {
                      showProfileModifyModal();
                    },
                    icon: const Icon(
                      Icons.add,
                      size: 15,
                      color: Colors.white,
                    )),
              ),
            ],
          ),
          const Gap(4),
          StreamBuilder<ResStream<List<String>>>(
              stream: tagStream.stream,
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  if (snapshot.data!.status == Status.COMPLETED) {
                    List<String> list = snapshot.data!.data!;
                    if (list.isEmpty) {
                      return Container(
                        padding: const EdgeInsets.all(20),
                        alignment: Alignment.center,
                        child: Text(
                          '등록된 관심태그가 없습니다.',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      );
                    }
                    return Wrap(
                      spacing: 6.0,
                      runSpacing: 6.0,
                      direction: Axis.horizontal,
                      crossAxisAlignment: WrapCrossAlignment.start,
                      verticalDirection: VerticalDirection.down,
                      runAlignment: WrapAlignment.start,
                      alignment: WrapAlignment.start,
                      children: list.map((e) => buildChip(e)).toList(),
                    );
                  } else {
                    return Container(
                      padding: const EdgeInsets.all(20),
                      alignment: Alignment.center,
                      child: Text(
                        '등록된 관심태그가 없습니다.',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    );
                  }
                } else {
                  // getTag();
                  return Container(
                    padding: const EdgeInsets.all(20),
                    alignment: Alignment.center,
                    child: Text(
                      '등록된 관심태그가 없습니다.',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  );
                }
                // return Wrap(
                //   spacing: 6.0,
                //   runSpacing: 6.0,
                //   direction: Axis.horizontal,
                //   crossAxisAlignment: WrapCrossAlignment.start,
                //   verticalDirection: VerticalDirection.down,
                //   runAlignment: WrapAlignment.start,
                //   alignment: WrapAlignment.start,
                //   children: <Widget>[
                //     buildChip('#홍제역'),
                //     buildChip('#광화문'),
                //     buildChip('#여의도'),
                //     buildChip('#강남역'),
                //     buildChip('#삼성역'),
                //     buildChip('#마포'),
                //     buildChip('#선릉'),
                //   ],
                // );
              }),
          // const Gap(10),
        ],
      ),
    );
  }

  Widget _builtCount(CustCountData data) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Padding(
          padding: const EdgeInsets.all(15.0),
          child: GestureDetector(
              onTap: () => getImage(ImageSource.gallery),
              child: ImageAvatar(width: 70, url: AuthCntr.to.resLoginData.value.profilePath!, type: AvatarType.MYSTORY)),
        ),
        Expanded(
          flex: 3,
          child: Padding(
            padding: const EdgeInsets.all(10.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(6.0),
                      child: MyPageInfo(
                        count: data.boardCnt!.toInt(),
                        label: '게시물',
                        onTap: () => Get.toNamed('/MainView1/0/${null}'), //Get.toNamed('/MainView1
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(6.0),
                      child: MyPageInfo(
                        count: data.likeCnt!.toInt(),
                        label: '좋아요',
                        onTap: () => Get.toNamed('/MainView1/1/${null}'),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(6.0),
                      child: MyPageInfo(
                        count: data.followCnt!.toInt(),
                        label: '팔로워',
                        onTap: () => Get.toNamed('/MainView1/2/${null}'),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(6.0),
                      child: MyPageInfo(
                        count: data.followerCnt!.toInt(),
                        label: '팔로잉',
                        onTap: () => Get.toNamed('/MainView1/3/${null}'),
                      ),
                    ),
                  ],
                ),
                // const Gap(10),
                data.custInfo!.selfId.toString() == 'null'
                    ? const SizedBox()
                    : Text(
                        '@${data.custInfo!.selfId.toString()}',
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                      ),
                data.custInfo!.selfId.toString() == 'null'
                    ? const SizedBox()
                    : Text(
                        data.custInfo!.selfIntro.toString(),
                        style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
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
          const SizedBox(
            width: 20.0,
          ),
          Expanded(
              flex: 4,
              child: MyPageButton(
                  onTap: () => Get.toNamed('/MyinfoModifyPage')!.then((value) => value == true ? getCountData() : null), label: '프로필 수정')),
          const SizedBox(
            width: 10.0,
          ),
          Expanded(flex: 4, child: MyPageButton(onTap: () => share(), label: '프로필 공유')),
          const SizedBox(
            width: 20.0,
          ),
          // Container(
          //     width: 40,
          //     height: 40,
          //     padding: const EdgeInsets.all(8.0),
          //     decoration: BoxDecoration(color: const Color(0xfff3f3f3), borderRadius: BorderRadius.circular(4.0)),
          //     child: const Icon(Icons.person_add))
        ],
      ),
    );
  }

  Widget _tabBarView() {
    return Expanded(
      child: TabBarView(children: [
        //_myFeeds(),
        Utils.commonStreamList<BoardWeatherListData>(myVideoListCntr, _myFeeds, getMyBoard),
        Utils.commonStreamList<BoardWeatherListData>(followVideoListCntr, _followFeeds, getFollowBoard),
        // _followFeeds(),
      ]),
    );
  }

  Widget _myFeeds(List<BoardWeatherListData> list) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: list.length > 0
          ? GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3, //1 개의 행에 보여줄 item 개수
                childAspectRatio: 3 / 5, //item 의 가로 1, 세로 1 의 비율
                mainAxisSpacing: 6, //수평 Padding
                crossAxisSpacing: 3, //수직 Padding
              ),
              itemCount: list.length,
              itemBuilder: (context, index) => GestureDetector(
                onTap: () {
                  Get.toNamed('/VideoMyinfoListPage', arguments: list[index]);
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(10.0),
                    image: DecorationImage(
                      image: CachedNetworkImageProvider(list[index].thumbnailPath!),
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
                  ),
                ),
              ),
            )
          : Utils.progressbar(),
    );
  }

  Widget _followFeeds(List<BoardWeatherListData> list) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: MasonryGridView.count(
          crossAxisCount: 3,
          mainAxisSpacing: 4,
          crossAxisSpacing: 4,
          // gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 1.0, mainAxisSpacing: 1.0),
          itemCount: list.length,
          itemBuilder: (context, index) => GestureDetector(
                onTap: () {
                  Get.toNamed('/VideoMyinfoListPage', arguments: list[index]);
                },
                child: Container(
                    color: Colors.grey.shade300,
                    height: (index % 5 + 1) * 60,
                    child: CachedNetworkImage(
                      imageUrl: list[index].thumbnailPath!,
                      fit: BoxFit.cover,
                    )),
              )),
    );
  }

  Widget _tabs() {
    return const TabBar(indicatorColor: Colors.black, tabs: [
      Tab(
        // child: Icon(Icons.grid_on),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.grid_on),
            Gap(10),
            Text('내 게시물'),
          ],
        ),
      ),
      Tab(
        // child: Icon(Icons.person_pin),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_pin),
            Gap(10),
            Text('팔로우'),
          ],
        ),
      ),
    ]);
  }

  PreferredSizeWidget _appBar() {
    return AppBar(
      // appbar scroll시 bgColor 변경 방지
      forceMaterialTransparency: true,
      automaticallyImplyLeading: false,
      // scrolledUnderElevation: 0.0,
      centerTitle: true,
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
              style: const TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
            ),
          ),
          IconButton(
            onPressed: () => Get.toNamed('/SettingPage'),
            icon: const Icon(Icons.settings),
          )
        ],
      ),
      actions: [
        // Padding(
        //   padding: EdgeInsets.all(14.0),
        //   child: IconButton(icon: Icon(Icons.menu), onPressed: () => Get.toNamed('SettingPage')),
        // ),
      ],
    );
  }

  void showProfileModifyModal() {
    showModalBottomSheet(
      isScrollControlled: true,
      showDragHandle: false,
      backgroundColor: Colors.white,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.only(topLeft: Radius.circular(10.0), topRight: Radius.circular(10.0))),
      context: context,
      builder: (BuildContext context) {
        return Padding(
          padding: MediaQuery.of(context).viewInsets,
          child: SizedBox(
            height: 210,
            child: Column(
              children: [
                Container(
                  height: 45,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(topLeft: Radius.circular(10.0), topRight: Radius.circular(10.0)),
                  ),
                  child: Row(
                    children: [
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20),
                        child: Text('관심태그 추가', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                      const Spacer(),
                      IconButton(
                        style: ButtonStyle(
                          padding: MaterialStateProperty.all(EdgeInsets.zero),
                          minimumSize: MaterialStateProperty.all(Size.zero),
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                ),
                Container(
                  height: 150,
                  // padding: const EdgeInsets.only(
                  //   right: 16,
                  //   left: 16,
                  // ),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  color: Colors.white,

                  child: Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
                    const Gap(10),
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 0),
                      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
                      height: 54,
                      child: TextFormField(
                        controller: tagController,
                        focusNode: textFocus,
                        autofocus: true,
                        maxLines: 1,
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 0),
                          filled: true,
                          fillColor: Colors.grey[100],
                          //  suffixIcon: const Icon(Icons.search, color: Colors.grey),
                          enabledBorder: OutlineInputBorder(
                            // width: 0.0 produces a thin "hairline" border
                            borderSide: const BorderSide(color: Colors.grey, width: 0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          border: OutlineInputBorder(
                            // width: 0.0 produces a thin "hairline" border
                            //  borderSide: const BorderSide(color: Colors.grey, width: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: const BorderSide(color: Colors.grey, width: 0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          label: const Text("Tag 를 입력해주세요."),
                          labelStyle: const TextStyle(color: Colors.black38),
                        ),
                        onFieldSubmitted: (text) {
                          // Perform search
                          addTag(text);
                          tagController.text = '';
                          Navigator.pop(context);
                        },
                      ),
                    ),
                    const Spacer(),
                    CustomButton(
                        text: '등록하기',
                        type: 'XL',
                        heightValue: 55,
                        isEnable: true,
                        onPressed: () {
                          addTag(tagController.text);
                          tagController.text = '';
                          Navigator.pop(context);
                        }),
                    const Gap(23)
                  ]),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // 최그
  Widget buildChip(String label) {
    return SizedBox(
        height: 40,
        child: Chip(
          elevation: 10,
          padding: EdgeInsets.zero,
          backgroundColor: const Color.fromARGB(255, 140, 131, 221), // Color.fromARGB(255, 76, 70, 124),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: const BorderSide(color: Colors.transparent),
          ),
          label: Text(
            '  $label',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
          ),
          labelPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
          onDeleted: () => removeTag(label),
          deleteButtonTooltipMessage: '삭제',
          deleteIconColor: Colors.white60,
        ));
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
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          )),
        ));
  }
}

class MyPageInfo extends StatelessWidget {
  final int count;
  final String label;
  final void Function() onTap;
  const MyPageInfo({super.key, required this.count, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    // return TextButton(
    //   style: TextButton.styleFrom(
    //       minimumSize: Size.zero, padding: EdgeInsets.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap, elevation: 8),
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        minimumSize: Size.zero,
        //   backgroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 1, horizontal: 6),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: const VisualDensity(horizontal: 0, vertical: 0),
        elevation: 0.2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
        backgroundColor: Colors.grey.shade100,
      ),
      onPressed: onTap,
      child: Column(
        children: [
          Text(
            count.toString(),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black),
          ),
          Text(
            label,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: Colors.black54),
          ),
        ],
      ),
    );
  }
}

class DraggablePage extends StatefulWidget {
  const DraggablePage({super.key});

  @override
  State<DraggablePage> createState() => _DraggablePageState();
}

class _DraggablePageState extends State<DraggablePage> {
  DraggableScrollableController draggableScrollableController = DraggableScrollableController();
  bool isChecked = false;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      maxChildSize: 0.8,
      minChildSize: 0.2,
      controller: draggableScrollableController,
      builder: (BuildContext context, ScrollController scrollController) => Scaffold(
        appBar: AppBar(
          title: ScrollConfiguration(
            behavior: const ScrollBehavior(),
            child: SingleChildScrollView(controller: scrollController, child: const Text('Draggable scrollable sheet example')),
          ),
          backgroundColor: Colors.teal,
        ),
        body: Center(
          child: Column(
            children: <Widget>[
              Row(
                children: [
                  const Text('Are you sure?'),
                  Checkbox(
                      value: isChecked,
                      onChanged: (bool? value) {
                        setState(() {
                          isChecked = value!;
                        });
                      })
                ],
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('Back'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
