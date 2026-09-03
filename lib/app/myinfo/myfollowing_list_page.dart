import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:gap/gap.dart';
import 'package:get/get.dart';
import 'package:project1/app/auth/cntr/auth_cntr.dart';
import 'package:project1/app/shared_album/theme/sa_colors.dart';
import 'package:project1/repo/board/board_repo.dart';
import 'package:project1/repo/board/data/board_weather_list_data.dart';
import 'package:project1/widget/media_thumbnail.dart';
import 'package:project1/repo/common/res_data.dart';
import 'package:project1/repo/common/res_stream.dart';
import 'package:project1/utils/utils.dart';
import 'package:rxdart/rxdart.dart';

/// 팔로잉 게시물 그리드 — "우리의 앨범"(shared_album)과 같은 디자인 토큰(SaColors/SaText)을 쓴다.
///
/// 설정 화면과 마찬가지로 **라이트 고정**이다. `SaColors.syncWith(context)`를 호출하지
/// 않으므로 `SaColors.isLight` 기본값(true)의 라이트 팔레트가 그대로 적용된다.
class MyFollowingListPage extends StatefulWidget {
  const MyFollowingListPage({super.key});

  @override
  State<MyFollowingListPage> createState() => _MyFollowingListPageState();
}

class _MyFollowingListPageState extends State<MyFollowingListPage> {
  // 팔로워 리스트 가져오기
  int followboardPageNum = 0;
  int followboardageSize = 10;
  List<BoardWeatherListData> followboardlist = [];
  StreamController<ResStream<List<BoardWeatherListData>>> followVideoListCntr = BehaviorSubject();
  ScrollController followboardScrollCtrl = ScrollController();
  bool isFollowLastPage = false;
  final ValueNotifier<bool> isFollowMoreLoading = ValueNotifier<bool>(false);

  @override
  void initState() {
    super.initState();
    getInitFollowBoard();
    followboardScrollCtrl.addListener(() {
      if (followboardScrollCtrl.position.pixels == followboardScrollCtrl.position.maxScrollExtent) {
        if (!isFollowLastPage) {
          followboardPageNum++;
          isFollowMoreLoading.value = true;
          getFollowBoard(followboardPageNum);
        }
      }
    });
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

  @override
  void dispose() {
    followVideoListCntr.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SaColors.bgBase,
      // appBar: AppBar(
      //   forceMaterialTransparency: true,
      //   automaticallyImplyLeading: false,
      //   // backgroundColor: Colors.white,
      //   title: const Text(
      //     "사용자 리스트",
      //     style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
      //   ),
      //   centerTitle: true,
      //   // backgroundColor: Colors.transparent,
      //   elevation: 0,
      // ),
      body: RefreshIndicator(
        onRefresh: () async {
          getInitFollowBoard();
        },
        // 화면 좌우 패딩 16 — 중복 인셋(바깥 Container 8 + 안쪽 8)을 한 곳으로 모았다.
        child: SingleChildScrollView(
          controller: followboardScrollCtrl,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Expanded(
            child: Column(
              children: [
                Container(
                    //    height: 200,
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(26),
                    ),
                    child: Utils.commonStreamList<BoardWeatherListData>(followVideoListCntr, followFeeds, getInitFollowBoard))
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget followFeeds(List<BoardWeatherListData> list) {
    return Padding(
      // 좌우는 스크롤뷰의 화면 패딩 16을 그대로 쓴다(중복 인셋 제거).
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: MasonryGridView.count(
          crossAxisCount: 3,
          mainAxisSpacing: 4,
          crossAxisSpacing: 4,
          controller: followboardScrollCtrl,
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
                  color: SaColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(10.0),
                ),
                child: Stack(
                  children: [
                    // 썸네일은 MediaThumbnail 로 통일 — GIF 썸네일을 정적 JPG 로 정규화하고,
                    // 영상이면 우측 상단에 플레이 배지를 붙인다. 캐시 키도 정규화된 URL 로
                    // 잡히므로, 모든 칸이 로그인 사용자 프로필 경로를 캐시 키로 쓰던
                    // 기존 문제(칸마다 같은 이미지가 나올 수 있음)도 함께 사라진다.
                    Positioned.fill(
                      child: MediaThumbnail(
                        url: list[index].thumbnailPath,
                        isVideo: _isVideoPost(list[index]),
                        borderRadius: BorderRadius.circular(10.0),
                        placeholder: const SizedBox.shrink(),
                      ),
                    ),
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
}

/// 영상 게시물인가.
///
/// 판별식은 `Video_screen_page` 의 `isPhotoPost`(= `typeDtCd == 'I' ||
/// imageUrls 있음`)를 그대로 뒤집은 것이다. `typeDtCd` 가 비어 있는 레거시
/// 게시물이 있어 사진 URL 유무까지 함께 봐야 사진에 재생 배지가 붙지 않는다.
bool _isVideoPost(BoardWeatherListData d) => !(d.typeDtCd == 'I' || (d.imageUrls?.isNotEmpty ?? false));
