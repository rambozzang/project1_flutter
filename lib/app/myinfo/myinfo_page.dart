import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloudflare/cloudflare.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:gap/gap.dart';
import 'package:get/get.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:project1/app/auth/cntr/auth_cntr.dart';
import 'package:project1/app/myinfo/widget/image_avatar.dart';
import 'package:project1/app/weather/widgets/customShimmer.dart';
import 'package:project1/repo/board/board_repo.dart';
import 'package:project1/repo/board/data/board_weather_list_data.dart';
import 'package:project1/repo/board/data/cust_count_data.dart';
import 'package:project1/repo/chatting/chat_repo.dart';
import 'package:project1/repo/chatting/data/update_data.dart';
import 'package:project1/repo/cloudflare/cloudflare_repo.dart';
import 'package:project1/repo/common/res_data.dart';
import 'package:project1/repo/common/res_stream.dart';
import 'package:project1/repo/cust/cust_repo.dart';
import 'package:project1/root/cntr/root_cntr.dart';
import 'package:project1/utils/log_utils.dart';
import 'package:project1/utils/utils.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

import 'package:path_provider/path_provider.dart';
import 'package:project1/widget/custom_button.dart';
import 'package:project1/widget/custom_indicator_offstage.dart';
import 'package:rxdart/rxdart.dart';
import 'package:share_plus/share_plus.dart';
import 'package:http/http.dart' as http;

// 사진촬영
// https://dariadobszai.medium.com/set-profile-photo-with-flutter-bloc-or-how-to-bloc-backward-9fb16faa56ed

class MyPage extends StatefulWidget {
  const MyPage({super.key});

  @override
  State<MyPage> createState() => _MyPageState();
}

class _MyPageState extends State<MyPage> with AutomaticKeepAliveClientMixin, SingleTickerProviderStateMixin {
  final ValueNotifier<List<String>> urls = ValueNotifier<List<String>>([]);

  @override
  bool get wantKeepAlive => true;

  XFile? _image; //이미지를 담을 변수 선언
  final ImagePicker picker = ImagePicker(); //ImagePicker 초기화
  // 상태유지

  // 3가지 갯수 가져오기
  StreamController<ResStream<CustCountData>> myCountCntr = StreamController();

  ScrollController mainScrollController = ScrollController();

  // 내게시물 리스트 가져오기
  int myboardPageNum = 0;
  int myboardageSize = 10;
  List<BoardWeatherListData> myboardlist = [];
  StreamController<ResStream<List<BoardWeatherListData>>> myVideoListCntr = BehaviorSubject();
  ScrollController myboardScrollCtrl = ScrollController();
  bool isMyBoardLastPage = false;
  final ValueNotifier<bool> isMyBoardMoreLoading = ValueNotifier<bool>(false);

  // 팔로워 리스트 가져오기
  int followboardPageNum = 0;
  int followboardageSize = 10;
  List<BoardWeatherListData> followboardlist = [];
  StreamController<ResStream<List<BoardWeatherListData>>> followVideoListCntr = BehaviorSubject();
  ScrollController followboardScrollCtrl = ScrollController();
  bool isFollowLastPage = false;
  final ValueNotifier<bool> isFollowMoreLoading = ValueNotifier<bool>(false);

  // 관심태그 리스트 가져오기
  StreamController<ResStream<List<String>>> tagStream = StreamController();

  // 관심태그 추가
  TextEditingController tagController = TextEditingController();

  //
  final ValueNotifier<bool> isLoading = ValueNotifier<bool>(false);

  late TabController tabController;

  FocusNode textFocus = FocusNode();
  bool _keyboardVisible = false;

  @override
  void initState() {
    super.initState();
    getCountData();
    getInitMyBoard();
    getInitFollowBoard();
    getTag();
    textFocus.addListener(() {
      if (textFocus.hasFocus) {
        RootCntr.to.bottomBarStreamController.sink.add(false);
      } else {
        RootCntr.to.bottomBarStreamController.sink.add(true);
      }
    });
    tabController = TabController(vsync: this, length: 2);

    mainScrollController.addListener(() {
      RootCntr.to.changeScrollListner(mainScrollController);
      if (mainScrollController.position.pixels == mainScrollController.position.maxScrollExtent) {
        if (!isMyBoardLastPage && tabController.index == 0) {
          myboardPageNum++;
          isMyBoardMoreLoading.value = true;
          getMyBoard(myboardPageNum);
        }
        if (!isFollowLastPage && tabController.index == 1) {
          followboardPageNum++;
          isFollowMoreLoading.value = true;
          getFollowBoard(followboardPageNum);
        }
      }
    });

    // mainScrollController.addListener(() {
    //   if (myboardScrollCtrl.position.pixels == myboardScrollCtrl.position.maxScrollExtent) {
    //     if (!isMyBoardLastPage) {
    //       myboardPageNum++;
    //       isMyBoardMoreLoading.value = true;
    //       getMyBoard(myboardPageNum);
    //     }
    //   }
    // });

    // mainScrollController.addListener(() {
    //   if (followboardScrollCtrl.position.pixels == followboardScrollCtrl.position.maxScrollExtent) {
    //     if (!isFollowLastPage) {
    //       followboardPageNum++;
    //       isFollowMoreLoading.value = true;
    //       getFollowBoard(followboardPageNum);
    //     }
    //   }
    // });
  }

  Future<void> getCountData() async {
    try {
      myCountCntr.sink.add(ResStream.loading());
      BoardRepo repo = BoardRepo();
      ResData res = await repo.getCustCount(Get.find<AuthCntr>().resLoginData.value.custId.toString());
      if (res.code != '00') {
        Utils.alert(res.msg.toString());
        return;
      }
      CustCountData data = CustCountData.fromMap(res.data);

      Get.find<AuthCntr>().resLoginData.value.custData = data.custInfo;

      myCountCntr.sink.add(ResStream.completed(data));
    } catch (e) {
      Utils.alert(e.toString());
      myCountCntr.sink.add(ResStream.error(e.toString()));
    }
  }

  Future<void> getInitMyBoard() async {
    myboardPageNum = 0;
    getMyBoard(myboardPageNum);
  }

  Future<void> getMyBoard(int page) async {
    try {
      if (page == 0) {
        myVideoListCntr.sink.add(ResStream.loading());
        myboardlist.clear();
      }
      BoardRepo repo = BoardRepo();
      ResData res = await repo.getMyBoard(Get.find<AuthCntr>().resLoginData.value.custId.toString(), myboardPageNum, myboardageSize);
      if (res.code != '00') {
        Utils.alert(res.msg.toString());
        isMyBoardLastPage = true;
        return;
      }
      print(res.data);
      List<BoardWeatherListData> list = ((res.data) as List).map((data) => BoardWeatherListData.fromMap(data)).toList();
      myboardlist.addAll(list);

      if (list.length < myboardageSize) {
        isMyBoardLastPage = true;
      }
      isMyBoardMoreLoading.value = false;

      myVideoListCntr.sink.add(ResStream.completed(myboardlist));
    } catch (e) {
      Utils.alert(e.toString());
      myVideoListCntr.sink.add(ResStream.error(e.toString()));
    }
  }

  Future<void> getInitFollowBoard() async {
    followboardPageNum = 0;
    getFollowBoard(followboardPageNum);
  }

  Future<void> getFollowBoard(int page) async {
    try {
      if (page == 0) {
        followVideoListCntr.sink.add(ResStream.loading());
        followboardlist.clear();
      }
      BoardRepo repo = BoardRepo();
      ResData res =
          await repo.getFollowBoard(Get.find<AuthCntr>().resLoginData.value.custId.toString(), followboardPageNum, followboardageSize);
      if (res.code != '00') {
        Utils.alert(res.msg.toString());
        return;
      }
      print(res.data);
      List<BoardWeatherListData> list = ((res.data) as List).map((data) => BoardWeatherListData.fromMap(data)).toList();
      followboardlist.addAll(list);

      if (list.length < followboardageSize) {
        isFollowLastPage = true;
      }
      isFollowMoreLoading.value = false;

      followVideoListCntr.sink.add(ResStream.completed(followboardlist));
    } catch (e) {
      Utils.alert(e.toString());
      followVideoListCntr.sink.add(ResStream.error(e.toString()));
    }
  }

  //이미지를 가져오는 함수
  Future getImage(ImageSource imageSource) async {
    isLoading.value = true;

    try {
      //pickedFile에 ImagePicker로 가져온 이미지가 담긴다.
      final XFile? pickedFile = await picker.pickImage(source: imageSource);
      if (pickedFile != null) {
        _image = XFile(pickedFile.path); //가져온 이미지를 _image에 저장

        CroppedFile? croppedFile = await ImageCropper().cropImage(
          sourcePath: pickedFile.path,
          compressFormat: ImageCompressFormat.jpg,
          compressQuality: 80,
          uiSettings: [
            AndroidUiSettings(
              toolbarTitle: '사진 편집기',
              toolbarColor: const Color(0xFF262B49),
              toolbarWidgetColor: Colors.white,
              initAspectRatio: CropAspectRatioPreset.original,
              lockAspectRatio: false,
              aspectRatioPresets: [
                CropAspectRatioPreset.square,
                CropAspectRatioPreset.ratio3x2,
                CropAspectRatioPreset.original,
                CropAspectRatioPreset.ratio4x3,
                CropAspectRatioPreset.ratio16x9
              ],
            ),
            IOSUiSettings(
              title: '사진 편집기',
              aspectRatioPresets: [
                CropAspectRatioPreset.square,
                CropAspectRatioPreset.ratio3x2,
                CropAspectRatioPreset.original,
                CropAspectRatioPreset.ratio4x3,
                CropAspectRatioPreset.ratio16x9
              ],
            ),
            WebUiSettings(
              context: context,
            ),
          ],
        );

        if (croppedFile != null) {
          _image = XFile(croppedFile.path);
        }

        // File aa = await CompressAndGetFile(croppedFile!.path);

        File aa = File(croppedFile!.path);

        // 1. 파일 업로드
        final String resthumbnail = await uploadImage(aa);

        AuthCntr.to.resLoginData.value.profilePath = resthumbnail;

        CustRepo repo = CustRepo();
        ResData res = await repo.modiProfilePath(AuthCntr.to.resLoginData.value.custId.toString(), resthumbnail);
        if (res.code != '00') {
          Utils.alert(res.msg.toString());
          isLoading.value = false;
          return;
        }
        isLoading.value = false;
        getCountData();

        // chatting 서버 이미지도 변경한다.
        ChatRepo chatRepo = ChatRepo();
        ChatUpdateData chatUpdateData = ChatUpdateData();
        chatUpdateData.firstName = AuthCntr.to.resLoginData.value.nickNm;
        chatUpdateData.uid = AuthCntr.to.resLoginData.value.chatId.toString();
        chatUpdateData.imageUrl = resthumbnail;
        chatRepo.updateUserino(chatUpdateData);

        Utils.alert('프로필 사진이 변경되었습니다.');
      } else {
        isLoading.value = false;
      }
    } catch (e) {
      Utils.alert(e.toString());
      isLoading.value = false;
    }
  }

  // 이미지 서버에 저장
  Future<String> uploadImage(File uploadFile) async {
    // 썸네일 업로드
    CloudflareRepo cloudflare = CloudflareRepo();
    await cloudflare.init();
    CloudflareHTTPResponse<CloudflareImage?>? resthumbnail = await cloudflare.imageFileUpload(uploadFile);
    if (resthumbnail?.isSuccessful == false) {
      Utils.alert('썸네일 업로드에 실패했습니다.');
      return Future.error('썸네일 업로드에 실패했습니다.');
    }
    Lo.g('썸네일 : ${resthumbnail?.body.toString()}');
    return resthumbnail!.body!.variants[0].toString();
  }

  Future<File> CompressAndGetFile(String path) async {
    var tmpDir = await getTemporaryDirectory();
    var targetName = DateTime.now().millisecondsSinceEpoch;
    XFile? compressFile = await FlutterImageCompress.compressAndGetFile(
      path,
      "${tmpDir.absolute.path}/$targetName.jpg",
      quality: 70,
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
    // final result = await Share.shareWithResult('check out my website https://example.com');
    final result = await Share.share('check out my website https://example.com');

    if (result.status == ShareResultStatus.success) {
      print('Thank you for sharing my website!');
    }
  }

  // 프로필 사진 업데이트
  // Future<void> save() async {
  //   try {
  //     CustRepo repo = CustRepo();
  //     CustUpdataData data = CustUpdataData();
  //     data.custId = AuthCntr.to.resLoginData.value.custId.toString();
  //     data.profilePath = AuthCntr.to.resLoginData.value.profilePath.toString();
  //     ResData res = await repo.updateCust(data);
  //     if (res.code != '00') {
  //       Utils.alert(res.msg.toString());
  //       return;
  //     }
  //     Utils.alert('수정되었습니다.');
  //   } catch (e) {
  //     Utils.alert(e.toString());
  //   }
  // }

  List<String> _taglist = [];
  // 관심태그 삭제
  Future<void> removeTag(String tagNm) async {
    try {
      CustRepo repo = CustRepo();
      _taglist.remove(tagNm);
      tagStream.sink.add(ResStream.completed(_taglist));

      ResData res = await repo.deleteTag(AuthCntr.to.resLoginData.value.custId.toString(), tagNm);
      if (res.code != '00') {
        Utils.alert(res.msg.toString());
        return;
      }
      // Utils.alert('삭제되었습니다.');
      //  getTag();
    } catch (e) {
      Utils.alert(e.toString());
    }
  }

  // 관심태그 추가
  Future<void> addTag(String tagNm) async {
    try {
      CustRepo repo = CustRepo();
      _taglist.add(tagNm);
      // Utils.alert('추가되었습니다.');
      tagStream.sink.add(ResStream.completed(_taglist));
      ResData res = await repo.saveTag(AuthCntr.to.resLoginData.value.custId.toString(), tagNm);
      if (res.code != '00') {
        Utils.alert(res.msg.toString());
        return;
      }

      //   getTag();
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
      _taglist = (res.data as List).map((e) => e['tagNm'].toString()).toList();

      tagStream.sink.add(ResStream.completed(_taglist));
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
    tabController.dispose();

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
        body: Stack(
          children: [
            RefreshIndicator.adaptive(
              notificationPredicate: (notification) {
                if (notification is OverscrollNotification || Platform.isIOS) {
                  return notification.depth == 2;
                }
                return notification.depth == 0;
              },
              onRefresh: () async {
                // 3가지 갯수 가져오기
                getCountData();
                getInitMyBoard();
                getInitFollowBoard();
                getTag();
              },
              child: NestedScrollView(
                controller: mainScrollController,
                headerSliverBuilder: (context, innerBoxIsScrolled) {
                  return [
                    SliverList(delegate: SliverChildListDelegate([_info(), _buildFavoriteTag()])),
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
            ValueListenableBuilder<bool>(
                valueListenable: isLoading,
                builder: (context, value, child) {
                  return CustomIndicatorOffstage(isLoading: !value, color: const Color(0xFFEA3799), opacity: 0.5);
                })
          ],
        ),
      ),
    );
  }

  Widget _info() {
    return Container(
      margin: const EdgeInsets.all(10.0),
      child: Utils.commonStreamBody<CustCountData>(
        myCountCntr,
        _builtCount,
        getCountData,
        loadingWidget: loadingWidget(),
      ),
    );
  }

  Widget loadingWidget() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Expanded(
          flex: 1,
          child: SizedBox(
            height: 65.0,
            width: 35,
            child: ClipOval(
              child: CustomShimmer(
                height: 40.0,
                width: 40,
                // borderRadius: BorderRadius.circular(16.0),
              ),
            ),
          ),
        ),
        const Gap(15),
        Expanded(
          flex: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Gap(10),
                  CustomShimmer(
                    height: 47.0,
                    width: 47,
                    borderRadius: BorderRadius.circular(7.0),
                  ),
                  const Gap(10),
                  CustomShimmer(
                    height: 47.0,
                    width: 47,
                    borderRadius: BorderRadius.circular(7.0),
                  ),
                  const Gap(10),
                  CustomShimmer(
                    height: 47.0,
                    width: 47,
                    borderRadius: BorderRadius.circular(7.0),
                  ),
                  const Gap(10),
                  CustomShimmer(
                    height: 47.0,
                    width: 47,
                    borderRadius: BorderRadius.circular(7.0),
                  ),
                ],
              ),
              const Gap(10),
              CustomShimmer(
                height: 20.0,
                width: 70,
                borderRadius: BorderRadius.circular(16.0),
              ),
              const Gap(10),
              CustomShimmer(
                height: 20.0,
                width: 260,
                borderRadius: BorderRadius.circular(16.0),
              ),
              const Gap(10),
              CustomShimmer(
                height: 20.0,
                width: 180,
                borderRadius: BorderRadius.circular(16.0),
              ),
              const Gap(10),
            ],
          ),
        )
      ],
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
              const Text('*리스트 구성 기준.', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 12, color: Colors.black54)),
              const Gap(10),
              SizedBox(
                height: 25,
                width: 45,
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
          const Gap(10),
          RichText(
            text: const TextSpan(
              text: '관심 있는 ',
              style: TextStyle(
                fontSize: 14,
                color: Colors.black54,
                fontWeight: FontWeight.w500,
              ),
              children: <TextSpan>[
                TextSpan(
                  text: '"학교, 지하철역, 골프장, 등산장소 , 캠핑장 , 유원지"',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.black),
                ),
                TextSpan(
                  text: '를 자유롭게 지정해 주시면 해당 영상이 리스트에 구성됩니다.',
                  style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14, color: Colors.black54),
                ),
              ],
            ),
//            "관심 있는 학교, 지하철역, 골프장, 등산장소 , 캠핑장 , 유원지 를 자유롭게 지정해 주시면 해당 영상이 리스트에 구성됩니다.",
            // style: TextStyle(fontSize: 13, color: Colors.black54
          ),
          const Gap(10),
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
              }),
          // const Gap(10),
        ],
      ),
    );
  }

  Widget _builtCount(CustCountData data) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 30),
          child: GestureDetector(
              onTap: () => getImage(ImageSource.gallery),
              child:
                  Obx(() => ImageAvatar(width: 70, url: Get.find<AuthCntr>().resLoginData.value.profilePath!, type: AvatarType.MYSTORY))),
        ),
        Expanded(
          flex: 3,
          child: Padding(
            padding: const EdgeInsets.all(5.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    MyPageInfo(
                      count: data.boardCnt!.toInt(),
                      label: '게시물',
                      onTap: () =>
                          Get.toNamed('/MainView1/${AuthCntr.to.resLoginData.value.custId.toString()}/0/${null}'), //Get.toNamed('/MainView1
                    ),
                    MyPageInfo(
                      count: data.likeCnt!.toInt(),
                      label: '좋아요',
                      onTap: () => Get.toNamed('/MainView1/${AuthCntr.to.resLoginData.value.custId.toString()}/1/${null}'),
                    ),
                    MyPageInfo(
                      count: data.followCnt!.toInt(),
                      label: '팔로워',
                      onTap: () => Get.toNamed('/MainView1/${AuthCntr.to.resLoginData.value.custId.toString()}/2/${null}'),
                    ),
                    MyPageInfo(
                      count: data.followerCnt!.toInt(),
                      label: '팔로잉',
                      onTap: () => Get.toNamed('/MainView1/${AuthCntr.to.resLoginData.value.custId.toString()}/3/${null}'),
                    ),
                  ],
                ),
                const Gap(15),
                data.custInfo!.selfId.toString() == 'null'
                    ? const Text(
                        '@자신만의ID',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                      )
                    : Text(
                        '@${data.custInfo!.selfId.toString()}',
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                      ),
                data.custInfo!.selfId.toString() == 'null'
                    ? const Text(
                        '자신 소개 내용을 만들어주세요.\n아래 프로필 수정 버튼을 클릭해주세요!',
                        style: TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
                      )
                    : Text(
                        data.custInfo!.selfIntro.toString(),
                        style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
                      ),
                const Gap(5),
                SizedBox(
                  height: 25,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          // backgroundColor: Colors.red,
                        ),
                        onPressed: () => Get.toNamed('/MyinfoModifyPage')!.then((value) => value == true ? getCountData() : null),
                        child: const Row(
                          children: [
                            Text(
                              '프로필 수정',
                              style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14.0, color: Colors.black),
                            ),
                            Icon(
                              Icons.arrow_forward_ios,
                              size: 16.0,
                              color: Colors.purple,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
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
      child: TabBarView(controller: tabController, children: [
        //_myFeeds(),
        Utils.commonStreamList<BoardWeatherListData>(myVideoListCntr, _myFeeds, getInitMyBoard),
        Utils.commonStreamList<BoardWeatherListData>(followVideoListCntr, _followFeeds, getInitFollowBoard),
        // _followFeeds(),
      ]),
    );
  }

  Widget _myFeeds(List<BoardWeatherListData> list) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: list.length > 0
          ? GridView.builder(
              shrinkWrap: false,
              // controller: myboardScrollCtrl,
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
                  Get.toNamed('/VideoMyinfoListPage', arguments: {
                    'datatype': 'MYFEED',
                    'custId': Get.find<AuthCntr>().resLoginData.value.custId.toString(),
                    'boardId': list[index].boardId.toString()
                  });
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10.0),
                    image: DecorationImage(
                      image: CachedNetworkImageProvider(list[index].thumbnailPath!),
                      fit: BoxFit.cover,
                    ),
                  ),
                  child: Stack(
                    children: [
                      Align(
                        alignment: Alignment.bottomRight,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 5),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.play_arrow_outlined,
                                    color: Colors.white,
                                    size: 17,
                                  ),
                                  const Gap(5),
                                  Text(
                                    list[index].likeCnt.toString(),
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 5),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.favorite,
                                    color: Colors.white,
                                    size: 17,
                                  ),
                                  const Gap(5),
                                  Text(
                                    list[index].likeCnt.toString(),
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      list[index].hideYn == 'Y'
                          ? const Positioned(
                              top: 10,
                              left: 10,
                              child: Icon(Icons.lock, color: Colors.red, size: 20),
                            )
                          : const SizedBox.shrink(),
                    ],
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
          // controller: followboardScrollCtrl,
          // physics: const NeverScrollableScrollPhysics(),
          // gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 1.0, mainAxisSpacing: 1.0),
          itemCount: list.length,
          itemBuilder: (context, index) => GestureDetector(
              onTap: () {
                Get.toNamed('/VideoMyinfoListPage', arguments: {
                  'datatype': 'FOLLOW',
                  'custId': Get.find<AuthCntr>().resLoginData.value.custId.toString(),
                  'boardId': list[index].boardId.toString()
                });
              },
              child: Container(
                height: (index % 5 + 1) * 60,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10.0),
                  image: DecorationImage(
                    image: CachedNetworkImageProvider(
                      list[index].thumbnailPath!,
                    ),
                    fit: BoxFit.cover,
                  ),
                ),
                child: Stack(
                  children: [
                    Align(
                      alignment: Alignment.bottomRight,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 5),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.play_arrow_outlined,
                                  color: Colors.white,
                                  size: 17,
                                ),
                                const Gap(5),
                                Text(
                                  list[index].likeCnt.toString(),
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 5),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.favorite,
                                  color: Colors.white,
                                  size: 17,
                                ),
                                const Gap(5),
                                Text(
                                  list[index].likeCnt.toString(),
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Text(
                        list[index].nickNm.toString(),
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    )
                  ],
                ),
              ))),
    );
  }

  Widget _tabs() {
    return TabBar(controller: tabController, indicatorColor: Colors.black, tabs: const [
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
            Text('팔로잉게시물'),
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
              AuthCntr.to.resLoginData.value.nickNm.toString(),
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
          elevation: 0,
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
        minimumSize: const Size(50, 40),
        //   backgroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 1, horizontal: 6),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: const VisualDensity(horizontal: 0, vertical: 0),
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
        backgroundColor: Colors.grey.shade50,
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
