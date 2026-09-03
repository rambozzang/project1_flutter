import 'dart:async';

import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:get/get.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:project1/app/auth/cntr/auth_cntr.dart';
import 'package:project1/app/shared_album/theme/sa_colors.dart';
import 'package:project1/repo/board/board_repo.dart';
import 'package:project1/repo/board/data/board_weather_list_data.dart';
import 'package:project1/widget/media_thumbnail.dart';
import 'package:project1/widget/video_processing_badge.dart';
import 'package:project1/repo/common/res_data.dart';
import 'package:project1/repo/common/res_stream.dart';
import 'package:project1/utils/utils.dart';
import 'package:rxdart/rxdart.dart';

/// 내 게시물 그리드 — "우리의 앨범"(shared_album)과 같은 디자인 토큰(SaColors/SaText)을 쓴다.
///
/// 설정 화면과 마찬가지로 **라이트 고정**이다. `SaColors.syncWith(context)`를 호출하지
/// 않으므로 `SaColors.isLight` 기본값(true)의 라이트 팔레트가 그대로 적용된다.
class MyboardListPage extends StatefulWidget {
  const MyboardListPage({super.key});

  @override
  State<MyboardListPage> createState() => _MyboardListPageState();
}

class _MyboardListPageState extends State<MyboardListPage> {
  // 내게시물 리스트 가져오기
  int myboardPageNum = 0;
  int myboardageSize = 10;
  List<BoardWeatherListData> myboardlist = [];
  StreamController<ResStream<List<BoardWeatherListData>>> myVideoListCntr = BehaviorSubject();
  ScrollController myboardScrollCtrl = ScrollController();
  bool isMyBoardLastPage = false;
  final ValueNotifier<bool> isMyBoardMoreLoading = ValueNotifier<bool>(false);

  @override
  void initState() {
    super.initState();
    getInitMyBoard();
    myboardScrollCtrl.addListener(() {
      if (myboardScrollCtrl.position.pixels == myboardScrollCtrl.position.maxScrollExtent) {
        if (!isMyBoardLastPage) {
          myboardPageNum++;
          isMyBoardMoreLoading.value = true;
          getMyBoard(myboardPageNum);
        }
      }
    });
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

      if (list.length < myboardageSize || list.isEmpty) {
        isMyBoardLastPage = true;
      }
      isMyBoardMoreLoading.value = false;

      myVideoListCntr.sink.add(ResStream.completed(myboardlist));
    } catch (e) {
      Utils.alert(e.toString());
      myVideoListCntr.sink.add(ResStream.error(e.toString()));
    }
  }

  @override
  void dispose() {
    myVideoListCntr.close();

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
          getInitMyBoard();
        },
        // 화면 좌우 패딩 16 — 중복 인셋(바깥 Container 8 + 안쪽 8)을 한 곳으로 모았다.
        child: SingleChildScrollView(
          controller: myboardScrollCtrl,
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
                    child: Utils.commonStreamList<BoardWeatherListData>(myVideoListCntr, myFeeds, getInitMyBoard))
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget myFeeds(List<BoardWeatherListData> list) {
    return Padding(
      // 좌우는 스크롤뷰의 화면 패딩 16을 그대로 쓴다(중복 인셋 제거).
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: list.isNotEmpty
          ? GridView.builder(
              shrinkWrap: true,
              controller: myboardScrollCtrl,
              // physics: const NeverScrollableScrollPhysics(),
              physics: const BouncingScrollPhysics(),
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
                    color: SaColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  child: Stack(children: [
                    // 썸네일은 MediaThumbnail 로 통일 — GIF 썸네일을 정적 JPG 로 정규화하고,
                    // 영상이면 우측 상단에 플레이 배지를 붙인다. 로딩·실패 시에는 아무것도
                    // 그리지 않아 위 Container 의 회색이 그대로 보인다(기존 동작 유지).
                    Positioned.fill(
                      child: MediaThumbnail(
                        url: list[index].thumbnailPath,
                        isVideo: _isVideoPost(list[index]),
                        borderRadius: BorderRadius.circular(10.0),
                        placeholder: const SizedBox.shrink(),
                      ),
                    ),
                    // 인코딩이 끝나지 않은 영상은 눌러도 재생되지 않는다.
                    // 목록에서 미리 알려 "고장났나" 하는 오해를 막는다.
                    if (list[index].isVideoProcessing) const VideoProcessingBadge(compact: true),
                    // 좌상단: 앨범 소속이면 '앨범' 배지(전체 피드는 배지 없음) → 한눈에 구분.
                    if (list[index].communityId != null)
                      Positioned(
                        top: 6,
                        left: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          // 배지는 썸네일 위 오버레이 — 어떤 사진 위에서도 읽혀야 해서
                          // 검정 스크림 + 흰 글자를 그대로 둔다(SaColors 에 대응 토큰 없음). 칩은 pill.
                          decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(999)),
                          child: const Row(mainAxisSize: MainAxisSize.min, children: [
                            PhosphorIcon(PhosphorIconsFill.images, color: Colors.white, size: 11),
                            SizedBox(width: 3),
                            Text('앨범', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
                          ]),
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
                  ]),
                ),
              ),
            )
          : Utils.progressbar(),
    );
  }
}

/// 영상 게시물인가.
///
/// 판별식은 `Video_screen_page` 의 `isPhotoPost`(= `typeDtCd == 'I' ||
/// imageUrls 있음`)를 그대로 뒤집은 것이다. `typeDtCd` 가 비어 있는 레거시
/// 게시물이 있어 사진 URL 유무까지 함께 봐야 사진에 재생 배지가 붙지 않는다.
bool _isVideoPost(BoardWeatherListData d) => !(d.typeDtCd == 'I' || (d.imageUrls?.isNotEmpty ?? false));
