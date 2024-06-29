import 'dart:async';
import 'dart:io';

import 'package:bot_toast/bot_toast.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:flutter_supabase_chat_core/flutter_supabase_chat_core.dart';
import 'package:gap/gap.dart';
import 'package:get/get.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:project1/app/auth/cntr/auth_cntr.dart';
import 'package:project1/app/chatting/chat_room_page.dart';
import 'package:project1/app/myinfo/widget/image_avatar.dart';
import 'package:project1/app/videolist/cntr/video_list_cntr.dart';
import 'package:project1/repo/board/board_repo.dart';
import 'package:project1/repo/board/data/board_weather_list_data.dart';
import 'package:project1/repo/board/data/cust_count_data.dart';
import 'package:project1/repo/common/res_data.dart';
import 'package:project1/repo/common/res_stream.dart';
import 'package:project1/repo/cust/cust_repo.dart';
import 'package:project1/repo/cust/data/cust_data.dart';
import 'package:project1/repo/cust/data/cust_update_data.dart';
import 'package:project1/root/cntr/root_cntr.dart';
import 'package:project1/utils/log_utils.dart';
import 'package:project1/utils/utils.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

import 'package:path_provider/path_provider.dart';

import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:project1/widget/custom_button.dart';

import 'package:rxdart/rxdart.dart';
import 'package:share_plus/share_plus.dart';

// 사진촬영
// https://dariadobszai.medium.com/set-profile-photo-with-flutter-bloc-or-how-to-bloc-backward-9fb16faa56ed

class OtherInfoPage extends StatefulWidget {
  const OtherInfoPage({super.key});

  @override
  State<OtherInfoPage> createState() => _OtherInfoPageState();
}

class _OtherInfoPageState extends State<OtherInfoPage> with AutomaticKeepAliveClientMixin {
  final ValueNotifier<List<String>> urls = ValueNotifier<List<String>>([]);
  final ValueNotifier<String> nickNm = ValueNotifier<String>('');

  @override
  bool get wantKeepAlive => true;

  XFile? _image; //이미지를 담을 변수 선언
  final ImagePicker picker = ImagePicker(); //ImagePicker 초기화
  // 상태유지

  // 3가지 갯수 가져오기
  StreamController<ResStream<CustCountData>> myCountCntr = StreamController.broadcast();

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

  final StreamController<ResStream<CustData>> userCntr = StreamController();

  late String? custId;
  late CustData? custData;

  @override
  void initState() {
    super.initState();
    Lo.g("1widget.custId : ${Get.parameters['custId']}");
    custId = Get.parameters['custId'];
    if (custId == '' || custId == 'null' || custId == null) {
      Get.back();
      return;
    }
    // getUserData(custId!);
    getCountData(custId!);
    getMyBoard(custId!);
    getFollowBoard(custId!);
    getTag(custId!);
    textFocus.addListener(() {
      if (textFocus.hasFocus) {
        RootCntr.to.bottomBarStreamController.sink.add(false);
      } else {
        RootCntr.to.bottomBarStreamController.sink.add(true);
      }
    });
  }

  // Future<void> getInitUserData() => getUserData(custId!);
  // Future<void> getUserData(String custId) async {
  //   try {
  //     userCntr.sink.add(ResStream.loading());
  //     CustRepo repo = CustRepo();
  //     ResData res = await repo.getCustInfo(custId.toString());
  //     if (res.code != '00') {
  //       Utils.alert(res.msg.toString());
  //       userCntr.sink.add(ResStream.error(res.msg.toString()));
  //       return;
  //     }
  //     custData = CustData.fromMap(res.data);

  //     lo.g('custData : ${custData.toString()}');
  //     custNm.value = custData!.custNm.toString();
  //     userCntr.sink.add(ResStream.completed(custData));
  //   } catch (e) {
  //     Utils.alert(e.toString());
  //     userCntr.sink.add(ResStream.error(e.toString()));
  //   }
  // }

  Future<void> getInitCountData() => getCountData(custId!);

  Future<void> getCountData(String custId) async {
    try {
      //  myCountCntr.sink.add(ResStream.loading());
      BoardRepo repo = BoardRepo();
      ResData res = await repo.getCustCount(custId);
      if (res.code != '00') {
        Utils.alert(res.msg.toString());
        return;
      }
      print(res.data);
      CustCountData data = CustCountData.fromMap(res.data);
      nickNm.value = data.custInfo!.nickNm.toString();
      myCountCntr.sink.add(ResStream.completed(data));
    } catch (e) {
      Utils.alert(e.toString());
      myCountCntr.sink.add(ResStream.error(e.toString()));
    }
  }
//getMyBoard getFollowBoard

  Future<void> getInitMyBoard() => getMyBoard(custId!);
  Future<void> getInitFollowBoard() => getFollowBoard(custId!);

  Future<void> getMyBoard(String custId) async {
    try {
      myVideoListCntr.sink.add(ResStream.loading());
      BoardRepo repo = BoardRepo();
      ResData res = await repo.getMyBoard(custId, myboardPageNum, myboardageSize);
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

  Future<void> getFollowBoard(String custId) async {
    try {
      followVideoListCntr.sink.add(ResStream.loading());
      BoardRepo repo = BoardRepo();
      ResData res = await repo.getFollowBoard(custId, followboardPageNum, followboardageSize);
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

  // 관심태그 조회
  Future<void> getTag(String custId) async {
    try {
      CustRepo repo = CustRepo();
      ResData res = await repo.getTagList(custId.toString());
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

  Future<void> addFollow(String cudtId) async {
    // 팔로우 추가

    String title = "팔로우 하시겠습니까?";
    Utils.showConfirmDialog("확인", title, BackButtonBehavior.none, confirm: () async {
      Lo.g('cancel');
      Get.find<VideoListCntr>().follow(cudtId.toString());
      getInitCountData();
    }, cancel: () async {
      Lo.g('cancel');
    }, backgroundReturn: () {});
  }

  Future<void> cancleFollow(String cudtId) async {
    // 팔로우 추가
    // 팔로우 추가
    String title = "팔로우 취소하시겠습니까?";
    Utils.showConfirmDialog("취소", title, BackButtonBehavior.none, confirm: () async {
      Lo.g('cancel');
      Get.find<VideoListCntr>().followCancle(cudtId.toString());
      getInitCountData();
    }, cancel: () async {
      Lo.g('cancel');
    }, backgroundReturn: () {});
  }

  @override
  void dispose() {
    myCountCntr.close();
    myVideoListCntr.close();
    followVideoListCntr.close();
    tagStream.close();
    userCntr.close();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
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
            getCountData(custId!);
            getMyBoard(custId!);
            getFollowBoard(custId!);
            getTag(custId!);
          },
          child: NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                SliverList(
                    delegate: SliverChildListDelegate([
                  _info(),
                  _buttons(),
                  //  _buildFavoriteTag()
                ])),
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

  Widget _buttons() {
    return StreamBuilder<ResStream<CustCountData>>(
        stream: myCountCntr.stream,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const SizedBox();
          }

          if (snapshot.data!.status == Status.COMPLETED) {
            CustData data = snapshot.data!.data!.custInfo!;
            lo.g("chatId : " + data.toString());
            lo.g(data.chatId.toString());
            // if (data == null || data.chatId == null || data.chatId.toString() == 'null') {
            //   return const SizedBox();
            // }
            String followyn = 'N';
            //data.followYn.toString();

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 60.0),
              child: Row(
                children: [
                  Expanded(
                    flex: 4,
                    child: CustomButton(
                      text: followyn == 'Y' ? '팔로잉 취소' : '팔로우 하기',
                      type: 'S',
                      heightValue: 40,
                      isEnable: true,
                      listColors: [
                        followyn == 'Y' ? const Color(0xFF3A3F65) : const Color.fromARGB(255, 169, 175, 214),
                        followyn == 'Y' ? const Color(0xFF1E2238) : const Color.fromARGB(255, 188, 195, 233),
                        followyn == 'Y' ? const Color(0xFF414766) : const Color.fromARGB(255, 171, 175, 193),
                      ],
                      onPressed: () => followyn == 'Y' ? cancleFollow(data.custId.toString()) : addFollow(data.custId.toString()),
                    ),
                    // child: ElevatedButton(
                    //   onPressed: () => data.followYn == 'Y' ? cancleFollow(data.custId.toString()) : addFollow(data.custId.toString()),
                    //   clipBehavior: Clip.none,
                    //   style: ElevatedButton.styleFrom(
                    //     padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
                    //     elevation: 0.5,
                    //     minimumSize: const Size(0, 0),
                    //     tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    //     backgroundColor: data.followYn.toString() == 'N' ? Colors.transparent : Colors.white,
                    //     // backgroundColor: widget.data.followYn.toString().contains('N') ? Colors.black : Colors.white,
                    //     shape: RoundedRectangleBorder(
                    //         borderRadius: BorderRadius.circular(10.0), side: const BorderSide(color: Colors.white, width: 0.7)),
                    //   ),
                    //   child: Text(
                    //     data.followYn.toString() == 'N' ? '팔로우' : '팔로잉',
                    //     // widget.data.followYn.toString().contains('N') ? '팔로우' : '팔로잉',
                    //     style: TextStyle(
                    //       color: data.followYn.toString().contains('N') ? Colors.white : Colors.black,
                    //       fontSize: 14,
                    //     ),
                    //   ),
                    // ),
                  ),
                  const Gap(15),
                  Expanded(
                      flex: 4,
                      child: CustomButton(
                          text: '대화하기',
                          type: 'S',
                          heightValue: 40,
                          isEnable: true,
                          onPressed: () async {
                            types.User otherUser = types.User(
                                id: data!.chatId.toString(), firstName: data!.nickNm.toString(), imageUrl: data!.profilePath.toString());

                            final room = await SupabaseChatCore.instance.createRoom(otherUser);

                            await Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => ChatPage(
                                  room: room,
                                ),
                              ),
                            );
                          },
                          suffixIcon: const Padding(
                            padding: EdgeInsets.only(left: 3.0),
                            child: Icon(
                              Icons.arrow_circle_right_outlined,
                              color: Colors.white,
                              size: 19,
                            ),
                          ),
                          listColors: const [
                            Color(0xFF3A3F65),
                            Color(0xFF1E2238),
                            Color(0xFF414766),
                          ])),
                ],
              ),
            );
          } else {
            return const SizedBox();
          }
        });
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
        child: Utils.commonStreamBody<CustCountData>(myCountCntr, _builtCount, getInitCountData));
  }

  Widget _buildFavoriteTag() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text('관심태그', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              Spacer(),
              Text('*위치기반과 관심사를 기준으로 리스트구성.', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 10, color: Colors.grey)),
              Gap(10),
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
              }),
          // const Gap(10),
        ],
      ),
    );
  }

  Widget _builtCount(CustCountData data) {
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Padding(
            padding: const EdgeInsets.all(15.0),
            child: ImageAvatar(width: 70, url: data.custInfo!.profilePath.toString(), type: AvatarType.BASIC),
          ),
          Expanded(
            flex: 3,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(6.0),
                      child: OtherInfoPageInfo(
                        count: data.boardCnt!.toInt(),
                        label: '게시물',
                        onTap: () => Get.toNamed('/MainView1/$custId/0/${null}'), //Get.toNamed('/MainView1
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(6.0),
                      child: OtherInfoPageInfo(
                        count: data.likeCnt!.toInt(),
                        label: '좋아요',
                        onTap: () => Get.toNamed('/MainView1/$custId/1/${null}'),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(6.0),
                      child: OtherInfoPageInfo(
                        count: data.followCnt!.toInt(),
                        label: '팔로워',
                        onTap: () => Get.toNamed('/MainView1/$custId/2/${null}'),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(6.0),
                      child: OtherInfoPageInfo(
                        count: data.followerCnt!.toInt(),
                        label: '팔로잉',
                        onTap: () => Get.toNamed('/MainView1/$custId/3/${null}'),
                      ),
                    ),
                  ],
                ),
                // const Gap(10),
                data.custInfo!.selfId.toString() == 'null'
                    ? const SizedBox()
                    : Text(
                        data.custInfo!.selfId.toString() == 'null' ? '@ID없음' : '@${data.custInfo!.selfId}',
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                      ),
                data.custInfo!.selfId.toString() == 'null'
                    ? const SizedBox()
                    : Text(
                        data.custInfo!.selfIntro.toString() == 'null' ? '자기소개 없음' : data.custInfo!.selfIntro.toString(),
                        style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tabBarView() {
    return Expanded(
      child: TabBarView(children: [
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
                  Get.toNamed('/VideoMyinfoListPage',
                      arguments: {'datatype': 'MYFEED', 'custId': custId, 'boardId': list[index].boardId.toString()});
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
                    )),
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
            Get.toNamed('/VideoMyinfoListPage',
                arguments: {'datatype': 'FOLLOW', 'custId': custId, 'boardId': list[index].boardId.toString()});
          },
          child: Container(
            color: Colors.grey.shade300,
            height: (index % 5 + 1) * 60,
            child: CachedNetworkImage(
              cacheKey: list[index].thumbnailPath!,
              imageUrl: list[index].thumbnailPath!,
              fit: BoxFit.cover,
            ),
          ),
        ),
      ),
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
        children: [
          ValueListenableBuilder<String?>(
              valueListenable: nickNm,
              builder: (context, value, child) {
                return Text(
                  value.toString(),
                  style: const TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
                );
              }),
        ],
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.all(4.0),
          child: IconButton(icon: const Icon(Icons.close), onPressed: () => Get.back()),
        ),
      ],
    );
  }

  // 최그
  Widget buildChip(String label) {
    return SizedBox(
      height: 40,
      child: Chip(
        elevation: 10,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
        backgroundColor: const Color.fromARGB(255, 140, 131, 221), // Color.fromARGB(255, 76, 70, 124),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: Colors.transparent),
        ),
        label: Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
        ),
        labelPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
        // onDeleted: () => null,
        //  deleteButtonTooltipMessage: '삭제',
        deleteIconColor: Colors.white60,
      ),
    );
  }
}

class OtherInfoPageButton extends StatelessWidget {
  final void Function()? onTap;
  final String label;
  const OtherInfoPageButton({super.key, this.onTap, required this.label});

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
          ),
        ),
      ),
    );
  }
}

class OtherInfoPageInfo extends StatelessWidget {
  final int count;
  final String label;
  final void Function() onTap;
  const OtherInfoPageInfo({super.key, required this.count, required this.label, required this.onTap});

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