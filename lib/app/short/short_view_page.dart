
import 'package:bot_toast/bot_toast.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';
import 'package:project1/admob/ad_manager.dart';

import 'package:project1/app/short/cntr/short_view_cntr.dart';
import 'package:project1/app/short/comment/cntr/short_comments_cntr.dart';
import 'package:project1/app/short/comment/short_comments_bottom_page.dart';
import 'package:project1/app/short/comment/short_comments_page.dart';
import 'package:project1/app/short/short_weather_card_page.dart';
import 'package:project1/app/weather/models/geocode.dart';
import 'package:project1/app/weathergogo/cntr/weather_gogo_cntr.dart';
import 'package:project1/repo/bbs/data/bbs_list_data.dart';
import 'package:project1/repo/common/res_stream.dart';
import 'package:project1/repo/cust/data/cust_tag_res_data.dart';
import 'package:project1/utils/StringUtils.dart';
import 'package:project1/utils/log_utils.dart';
import 'package:project1/utils/utils.dart';
import 'package:project1/widget/custom_indicator_offstage.dart';
import 'package:rich_text_view/rich_text_view.dart';
import 'package:text_scroll/text_scroll.dart';
import 'package:url_launcher/url_launcher.dart';
import 'widgets/image_viewer.dart';

class ShortViewPage extends StatefulWidget {
  const ShortViewPage({super.key});

  @override
  State<ShortViewPage> createState() => _ShortViewPageState();
}

class _ShortViewPageState extends State<ShortViewPage> {
  final cntr = Get.find<ShortViewController>();
  late String _boardId;
  late String _lat;
  late String _lng;
  late String _address;
  final ValueNotifier<bool> isAdLoading = ValueNotifier<bool>(false);

  @override
  void initState() {
    super.initState();
    _initializeBoardId();
    _loadAd();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ));
  }

  Future<void> _loadAd() async {
    await AdManager().loadBannerAd('ShortList1');
    isAdLoading.value = true;
  }

  void _initializeBoardId() {
    // _boardId = Get.arguments['boardId'] ?? '0';
    _lat = Get.arguments['lat'] ?? '';
    _lng = Get.arguments['lng'] ?? '';
    _address = Get.arguments['address'] ?? '';

    if (StringUtils.isEmpty(_lat) || StringUtils.isEmpty(_lat)) {
      Utils.alert("날씨를 조회후 다시 접속해 주세요!");
      return;
    }

    cntr.fetchDataInit(_address, _lat, _lng);
  }

  void _handleLikePress(bool isLiked) {
    if (isLiked) {
      cntr.likeCancel();
      cntr.isCount.value--;
    } else {
      cntr.like();
      cntr.isCount.value++;
    }
    cntr.isLike.value = !isLiked;
  }

  void fetchDataInit() => cntr.fetchDataInit(_address, _lat, _lng);

  @override
  void dispose() {
    // AdManager().disposeBannerAd('ShortList1');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        // systemNavigationBarColor: Colors.white, // 안드로이드 하단 네비게이션 바 색상
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Stack(
          children: [
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: _buildBody(),
              ),
            ),
            _buildSavingIndicator()
          ],
        ),
        bottomNavigationBar: ShortCommentsBottomPage(),
      ),
    );
  }

  Widget _buildSavingIndicator() {
    return Obx(() {
      if (Get.find<ShortCommentsController>().isSending.value) {
        return CustomIndicatorOffstage(
            isLoading: !Get.find<ShortCommentsController>().isSending.value, color: Colors.transparent, opacity: 0.5);
      }
      return const SizedBox.shrink();
    });
  }

  Widget _buildBody() {
    return StreamBuilder<ResStream<BbsListData?>>(
      stream: cntr.dataStreamController.stream,
      builder: (context, snapshot) {
        return RefreshIndicator(
          // edgeOffset: 100,
          onRefresh: () => cntr.fetchData(_address, _lat, _lng),
          child: CustomScrollView(
            controller: cntr.scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              _buildSliverAppBar(),
              _buildRefreshControl(),
              _buildContent(snapshot),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRefreshControl() {
    return CupertinoSliverRefreshControl(
      onRefresh: () => cntr.fetchData(_address, _lat, _lng),
    );
  }

  Widget _buildContent(AsyncSnapshot<ResStream<BbsListData?>> snapshot) {
    if (!snapshot.hasData || snapshot.data?.data == null) {
      return SliverFillRemaining(
        child: Center(child: Utils.progressbar()),
      );
    }

    if (snapshot.hasError) {
      return SliverFillRemaining(
        child: Center(
          child: TextButton(
            onPressed: fetchDataInit,
            child: const Text('새로고침'),
          ),
        ),
      );
    }

    return SliverToBoxAdapter(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSubject(snapshot.data!.data!),
          const Gap(5),
          ShortCommentsPage(
            boardId: snapshot.data!.data!.boardId.toString(),
            mainScrollController: cntr.scrollController,
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      floating: true,
      snap: true,
      elevation: 0,
      stretch: true,
      systemOverlayStyle: SystemUiOverlayStyle.dark,
      scrolledUnderElevation: 0, // 백그라운드 색 지정에 가장 중요한 옵션
      backgroundColor: Colors.white,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios),
        onPressed: () => Navigator.pop(context),
      ),
      centerTitle: false,
      forceMaterialTransparency: false,
      titleSpacing: -10,
      title: const Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            '동네 라운지',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          Gap(5),
          Icon(Icons.local_cafe_outlined, size: 12, color: Color.fromARGB(255, 33, 89, 2)),
        ],
      ),
      // title: StreamBuilder<ResStream<BbsListData?>>(
      //   stream: cntr.dataStreamController.stream,
      //   builder: (context, snapshot) {
      //     return snapshot.hasData && snapshot.data?.data != null
      //         ? Text(
      //             snapshot.data!.data!.subject.toString(),
      //             textAlign: TextAlign.start,
      //             style: const TextStyle(fontSize: 16, color: Colors.black, fontWeight: FontWeight.bold),
      //           )
      //         : const SizedBox();
      //   },
      // ),
      actions: const [
        // SizedBox(
        //   height: 35,
        //   width: 80,
        //   child: ElevatedButton(
        //     onPressed: () => Get.toNamed('/ShortListPage'),
        //     child: const Text(
        //       "라운지",
        //       style: TextStyle(fontSize: 12, color: Colors.black, fontWeight: FontWeight.bold),
        //     ),
        //   ),
        // ),
        // SizedBox(
        //   height: 33,
        //   child: OutlinedButton(
        //     style: OutlinedButton.styleFrom(
        //       padding: const EdgeInsets.symmetric(vertical: 2.0, horizontal: 6.0),
        //       shape: const RoundedRectangleBorder(
        //         borderRadius: BorderRadius.all(
        //           Radius.circular(10),
        //         ),
        //       ),
        //       side: const BorderSide(width: 1, color: Colors.black45),
        //       elevation: 3,
        //     ),
        //     onPressed: () {
        //       cntr.addLocalTag();
        //     },
        //     child: const Text(
        //       '관심지역 추가',
        //       style: TextStyle(color: Colors.black54, fontSize: 11),
        //     ),
        //   ),
        // ),
        Gap(10),
        // _buildLikeButton(),
        // const Gap(10),
      ],
    );
  }

  Widget _buildLikeButton() {
    return ValueListenableBuilder<bool>(
      valueListenable: cntr.isLike,
      builder: (context, val, snapshot) {
        lo.g('val : $val');
        return ValueListenableBuilder<int>(
            valueListenable: cntr.isCount,
            builder: (context, valCnt, snapshot) {
              return Row(
                children: [
                  SizedBox(
                    width: 30,
                    height: 25,
                    child: IconButton(
                      padding: EdgeInsets.zero, // 패딩 제거로 아이콘 크기 유지
                      // constraints: const BoxConstraints(maxHeight: 30, maxWidth: 30, minHeight: 30, minWidth: 30),
                      icon: const Icon(
                        Icons.favorite,
                        size: 20,
                      ),
                      onPressed: () => _handleLikePress(val),
                      color: val ? Colors.red : Colors.grey,
                    ),
                  ),
                  Text(
                    valCnt.toString(),
                    style: const TextStyle(fontSize: 12, color: Colors.black, fontWeight: FontWeight.w500),
                  ),
                ],
              );
            });
      },
    );
  }

  Widget _buildSubject(BbsListData data) {
    var children = [
      // const Align(
      //   alignment: Alignment.centerLeft,
      //   child: const TextScroll(
      //     '🐯실시간날씨 정보, 소식, 추천정보등을 맘대로 공유해주세요!🌈          ',
      //     mode: TextScrollMode.endless,
      //     numberOfReps: 3,
      //     // fadedBorder: true,
      //     delayBefore: Duration(milliseconds: 4000),
      //     pauseBetween: Duration(milliseconds: 2000),
      //     velocity: Velocity(pixelsPerSecond: Offset(100, 0)),
      //     style: TextStyle(fontSize: 14, color: Colors.black, fontWeight: FontWeight.w500),
      //     textAlign: TextAlign.left,
      //     selectable: true,
      //   ),
      // child: Text(
      //   '최신소식과 날씨정보를 전해주세요.',
      //   textAlign: TextAlign.start,
      //   // softWrap: true,
      //   style: TextStyle(
      //     fontSize: 14,
      //     fontWeight: FontWeight.w700,
      //     color: Colors.black87,
      //   ),
      // ),
      // ),
      // const Gap(10),
      // buildFavLocal(),
      // 인기 영상(좋아요 20+)은 방송 라이선스 후보로 자동 선정됨을 안내
      if ((data.likeCnt ?? 0) >= 20)
        Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF1565C0), Color(0xFF0288D1)]),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Row(
            children: [
              Icon(Icons.tv_rounded, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  '📺 방송 후보로 선정된 인기 영상이에요!',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
        decoration: BoxDecoration(
          // color: const Color(0xff93C90F),
          borderRadius: BorderRadius.circular(15),
          // color: Colors.grey[300],
          // border: Border.all(color: Colors.red[200]!, width: 1.5),
          border: Border.all(color: const Color.fromARGB(255, 152, 194, 94), width: 1.5),
        ),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Stack(
                  children: [
                    Positioned(
                        bottom: 1,
                        left: 0,
                        right: 0,
                        child: Container(
                          height: 8,
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        )),
                    Text(
                      '${data.subject}',
                      textAlign: TextAlign.end,
                      style: const TextStyle(fontSize: 17, color: Colors.black87, fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
                const Spacer(),
                _buildLikeButton(),
              ],
            ),
            const Gap(10),
            const ShortWeatherCardPage(
              key: ValueKey('HeaderMainPage'),
            ),
            // Align(
            //   alignment: Alignment.centerRight,
            //   child: _buildViewCount(data),
            // ),
          ],
        ),
      ),
      const Gap(10),
      Align(
        alignment: Alignment.centerLeft,
        child: Container(
          width: Get.width * 0.9,
          // padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 1),
          decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8)),
          child: const TextScroll(
            '🐯실시간날씨 정보, 동네소식, 추천정보등을 간단하게 공유해주세요!🌈     📛욕설,비속어는 고발조치됩니다.     ',
            mode: TextScrollMode.endless,
            // numberOfReps: 3,
            // fadedBorder: true,
            delayBefore: Duration(milliseconds: 4000),
            pauseBetween: Duration(milliseconds: 2000),
            velocity: Velocity(pixelsPerSecond: Offset(100, 0)),
            style: TextStyle(fontSize: 14, color: Colors.black, fontWeight: FontWeight.w500),
            textAlign: TextAlign.left,
            selectable: true,
          ),
        ),
      ),
      const Gap(10),
      // ValueListenableBuilder<bool>(
      //     valueListenable: isAdLoading,
      //     builder: (context, value, child) {
      //       if (!value) return const SizedBox.shrink();
      //       return const SizedBox(width: double.infinity, child: Center(child: BannerAdWidget(screenName: 'ShortList1')));
      //     }),
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildViewCount(BbsListData data) {
    return SizedBox(
      height: 11,
      child: RichText(
        text: TextSpan(
          text: "방문수",
          style: const TextStyle(fontSize: 11, color: Colors.black54),
          children: [
            TextSpan(
              text: ' ${data.viewCnt}',
              style: const TextStyle(fontSize: 11, color: Colors.black54, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModifyWindow(BbsListData bbsListData) {
    return SizedBox(
      height: 20,
      child: PopupMenuButton<String>(
        padding: const EdgeInsets.all(0),
        icon: const Icon(Icons.more_vert, size: 25),
        color: Colors.white,
        onSelected: (String result) {
          switch (result) {
            case 'edit':
              onEdit(bbsListData.boardId.toString());
              break;
            case 'delete':
              // onDelete();
              break;
          }
        },
        itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
          const PopupMenuItem<String>(value: 'edit', child: Text('수정')),
          const PopupMenuItem<String>(value: 'delete', child: Text('삭제')),
        ],
      ),
    );
  }

  Widget _buildMainContent(BbsListData data) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Wrap(
        children: [
          RichTextView(
            text: data.contents.toString(),
            truncate: false,
            // viewLessText: 'less',
            linkStyle: const TextStyle(color: Colors.blueAccent, fontSize: 13, fontWeight: FontWeight.w600),
            selectable: true,
            supportedTypes: [
              EmailParser(onTap: (email) => print('${email.value} clicked')),
              // PhoneParser(onTap: (phone) => print('click phone ${phone.value}')),
              MentionParser(
                  pattern: r'@[가-힣a-zA-Z0-9!@#$%^&*(),.?":{}|<>_-]+(?=\s|$)',
                  style: const TextStyle(
                    color: Colors.blueGrey,
                    fontWeight: FontWeight.bold,
                  ),
                  onTap: (mention) => print('${mention.value} clicked')),
              UrlParser(
                onTap: (url) => launchUrl(Uri.parse(url.value!)),
              ),
              BoldParser(),
              HashTagParser(onTap: (hashtag) => print('is ${hashtag.value} trending?'))
            ],
          ),
          _buildImageList(data),
        ],
      ),
    );
  }

  Widget _buildImageList(BbsListData data) {
    return data.fileList!.isNotEmpty
        ? Column(
            children: data.fileList!.map((fileData) {
              return Padding(
                padding: const EdgeInsets.only(top: 10),
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ImageViewer(imageUrl: fileData.filePath.toString(), nickNm: '미리보기'),
                      ),
                    );
                  },
                  child: ClipRRect(
                    borderRadius: const BorderRadius.all(Radius.circular(8)),
                    child: CachedNetworkImage(
                      cacheKey: fileData.filePath.toString(),
                      imageUrl: fileData.filePath.toString(),
                      fit: BoxFit.cover,
                      width: double.infinity,
                    ),
                  ),
                ),
              );
            }).toList(),
          )
        : const SizedBox();
  }

  void onEdit(String boardId) async {
    var result = await Get.toNamed('/ShortModifyPage/$boardId');
    lo.g("result : $result");
    if (result == true || result == 'true') {
      Get.back(result: true);
    } else {
      fetchDataInit();
    }
  }

  void onDelete(String boardId) async {
    String title = "삭제 하시겠습니까?";
    Utils.showConfirmDialog("확인", title, BackButtonBehavior.none, confirm: () async {
      await cntr.delete(boardId);
      Get.back(result: true);
    }, cancel: () async {
      Lo.g('cancel');
    }, backgroundReturn: () {});
  }

  // 관심지역 리스트
  Widget buildFavLocal() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      width: double.infinity,
      child: Obx(() {
        if (Get.find<WeatherGogoCntr>().areaList.isEmpty) {
          return InkWell(
            onTap: () async => await Get.toNamed('/FavoriteAreaPage')!.then((value) => Get.find<WeatherGogoCntr>().getLocalTag()),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 3),
              alignment: Alignment.center,
              child: Row(
                children: [
                  const Text('관심지역', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.grey)),
                  const Gap(3),
                  const Icon(Icons.arrow_circle_right_outlined, color: Colors.black87, size: 16),
                  const Gap(6),
                  Text(
                    '등록된 관심지역이 없습니다.',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade50,
                    ),
                  ),
                ],
              ),
            ),
          );
        }
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const AlwaysScrollableScrollPhysics(),
          child: Row(children: [
            InkWell(
                onTap: () async => await Get.toNamed('/FavoriteAreaPage')!.then((value) => Get.find<WeatherGogoCntr>().getLocalTag()),
                child: const Text('관심지역', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.white))),
            const Gap(3),
            InkWell(
                onTap: () async => await Get.toNamed('/FavoriteAreaPage')!.then((value) => Get.find<WeatherGogoCntr>().getLocalTag()),
                child: const Icon(Icons.arrow_circle_right_outlined, color: Colors.white, size: 16)),
            const Gap(5),
            ...Get.find<WeatherGogoCntr>().areaList.map((e) => buildLocalChip(e)),
          ]),
        );
      }),
    );
  }

  // 지역
  Widget buildLocalChip(CustagResData data) {
    return Container(
        height: 30,
        padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 0.0),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              late GeocodeData geocodeData = GeocodeData(
                name: data.id!.tagNm.toString(),
                latLng: LatLng(double.parse(data.lat.toString()), double.parse(data.lon.toString())),
              );
              Get.find<WeatherGogoCntr>().searchWeatherKakao(geocodeData);
            },
            child: Chip(
              elevation: 4,
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
              backgroundColor: const Color.fromARGB(255, 122, 110, 199), // Color.fromARGB(255, 76, 70, 124),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: const BorderSide(color: Color.fromARGB(0, 166, 155, 155)),
              ),
              label: Text(
                data.id!.tagNm.toString(),
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600, height: 1.0),
              ),
              visualDensity: const VisualDensity(horizontal: 0, vertical: -4),
              labelPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
            ),
          ),
        ));
  }
}
