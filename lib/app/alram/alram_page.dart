import 'dart:async';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import 'package:get/get.dart';
import 'package:project1/admob/ad_manager.dart';
import 'package:project1/admob/banner_ad_widget.dart';

import 'package:project1/app/auth/cntr/auth_cntr.dart';
import 'package:project1/app/bbs/bbs_list_page.dart';
import 'package:project1/app/bbs/cntr/bbs_list_cntr.dart';
import 'package:project1/app/chatting/chat_main_page.dart';
import 'package:project1/main.dart';
import 'package:project1/repo/alram/data/alram_res_data.dart';
import 'package:project1/root/cntr/root_cntr.dart';
import 'package:project1/route/app_route.dart';
import 'package:project1/utils/StringUtils.dart';
import 'package:project1/utils/utils.dart';
import 'package:project1/widget/animation_searchbar.dart';
import 'package:project1/widget/custom_tabbarview.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:project1/app/alram/controllers/alram_controller.dart';

class AlramPage extends StatefulWidget {
  const AlramPage({super.key});

  @override
  State<AlramPage> createState() => _AlramPageState();
}

class _AlramPageState extends State<AlramPage> with AutomaticKeepAliveClientMixin, SingleTickerProviderStateMixin {
  @override
  bool get wantKeepAlive => true;

  final ScrollController mainScrollController = ScrollController();
  final ScrollController alramScrollController = ScrollController();
  final ScrollController bbsListScrollController = ScrollController();
  final ScrollController chatListScrollController = ScrollController();

  TextEditingController searChWordController = TextEditingController();

  final alramController = Get.put(AlramController());
  final bbsListController = Get.put(BbsListController());

  late TabController tabController;
  final GlobalKey<ChatMainAppState> chatMainPageKey = GlobalKey();
  final ValueNotifier<bool> isAdLoading = ValueNotifier<bool>(false);
  final ValueNotifier<int> tabIndex = ValueNotifier<int>(0);
  final globalKey = GlobalKey<NestedScrollViewState>();
  double appbarBottomHeight = Platform.isIOS ? 120 : 90;
  Timer? debounceTimer; // 타이머 변수
  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _setupScrollListener();
    _loadAd();
  }

  void _initializeControllers() {
    tabController = TabController(vsync: this, length: 3);

    tabController.addListener(() {
      tabIndex.value = tabController.index;
    });

    alramController.getData(0);
  }

  void _setupScrollListener() {
    alramScrollController.addListener(() {
      RootCntr.to.changeScrollListner(alramScrollController);
      mainScrollController.jumpTo(alramScrollController.offset);
      _handlePagination();
    });

    bbsListScrollController.addListener(() {
      mainScrollController.jumpTo(bbsListScrollController.offset);
    });

    chatListScrollController.addListener(() {
      RootCntr.to.changeScrollListner(chatListScrollController);

      mainScrollController.jumpTo(chatListScrollController.offset);
    });
  }

  void _handlePagination() {
    debounceTimer = Timer(const Duration(milliseconds: 350), () {
      if (alramScrollController.position.pixels >= alramScrollController.position.maxScrollExtent * 0.8) {
        if (!alramController.isLastPage && alramController.isSending == false) {
          alramController.page++;
          alramController.isMoreLoading.value = true;
          alramController.isSending = true;
          alramController.getData(alramController.page);
        }
      }
    });
  }

  Future<void> _loadAd() async {
    await AdManager().loadBannerAd('AlramPage');
    isAdLoading.value = true;
  }

  Future<void> getDataInit() async {
    alramController.getDataInit();
  }

  @override
  void dispose() {
    AdManager().disposeBannerAd('AlramPage');
    tabController.dispose();
    mainScrollController.dispose();
    alramScrollController.dispose();
    bbsListScrollController.dispose();
    chatListScrollController.dispose();

    super.dispose();
  }

  aa() async {
    await Supabase.instance.client.auth.signOut();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context); // 상단에서 한 번만 선언
    super.build(context);

    return DefaultTabController(
      length: 3,
      initialIndex: 0,
      child: _buildScaffold(),
    );
  }

  TabBar _tabBar() {
    return TabBar(
      controller: tabController,
      indicatorColor: Colors.black,
      dividerColor: Colors.grey[100],
      indicatorSize: TabBarIndicatorSize.label,
      indicatorWeight: 2.0,
      tabAlignment: TabAlignment.start,
      // indicatorPadding: const EdgeInsets.symmetric(horizontal: 10),
      indicator: const UnderlineTabIndicator(
          borderSide: BorderSide(
            width: 4,
            color: Color(0xFF646464),
          ),
          insets: EdgeInsets.only(left: 2, right: 0, bottom: 0)),
      isScrollable: true,
      labelPadding: const EdgeInsets.only(left: 16, right: 15),
      tabs: const [
        Tab(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.fireplace_rounded,
                size: 17,
              ),
              Gap(5),
              Text('라운지', style: TextStyle(color: Colors.black, fontSize: 14, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
        Tab(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.alarm,
                size: 17,
              ),
              Gap(5),
              Text('알람', style: TextStyle(color: Colors.black, fontSize: 14, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
        Tab(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.message,
                size: 17,
              ),
              Gap(5),
              Text('채팅', style: TextStyle(color: Colors.black, fontSize: 14, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildScaffold() {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: NestedScrollView(
        key: globalKey,
        controller: mainScrollController,
        headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
          return <Widget>[
            SliverOverlapAbsorber(
              handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
              sliver: SliverAppBar(
                  pinned: true,
                  floating: true,
                  scrolledUnderElevation: 0,
                  snap: false,
                  forceElevated: innerBoxIsScrolled,
                  backgroundColor: Colors.white,
                  elevation: innerBoxIsScrolled ? 2 : 0,
                  automaticallyImplyLeading: false,
                  title: const Text('스카이 라운지', style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold)),
                  centerTitle: false,
                  actions: [
                    ValueListenableBuilder<int>(
                        valueListenable: tabIndex,
                        builder: (context, value, child) {
                          return AnimatedSwitcher(
                              key: const ValueKey('AnimatedSwitcher9'),
                              duration: const Duration(milliseconds: 200),
                              switchInCurve: Curves.easeIn,
                              switchOutCurve: Curves.ease,
                              transitionBuilder: (Widget child, Animation<double> animation) {
                                return ScaleTransition(
                                  key: const ValueKey('FadeTransition9'),
                                  // opacity: animation,
                                  filterQuality: FilterQuality.high,
                                  scale: animation,
                                  child: child,
                                );
                              },
                              child: value != 0
                                  ? const SizedBox.shrink()
                                  : AnimSearchBar(
                                      height: 48,
                                      autoFocus: true,
                                      helpText: '검색어를 입력하세요',
                                      width: (MediaQuery.of(context).size.width - 63),
                                      style: const TextStyle(fontSize: 14, decorationThickness: 0),
                                      textController: searChWordController,
                                      textFieldColor: Colors.grey.shade100,
                                      onSuffixTap: () {
                                        searChWordController.clear();
                                      },
                                      rtl: true,
                                      onSubmitted: (String value) {
                                        if (value.isEmpty) return;
                                        bbsListController.searchWord.value = value;
                                        bbsListController.getDataInit();
                                      },
                                      textInputAction: TextInputAction.search,
                                      searchBarOpen: (_) {
                                        searChWordController.text = '';
                                        bbsListController.isShowRegButton.value = false;
                                      },
                                    ));
                        }),
                    IconButton(
                      onPressed: () {
                        switch (tabController.index) {
                          case 0:
                            Get.find<BbsListController>().getDataInit();
                            break;
                          case 1:
                            getDataInit();
                            break;
                          case 2:
                            chatMainPageKey.currentState?.initSupaBaseSession();
                            break;
                        }
                      },
                      icon: Icon(
                        Icons.refresh_outlined,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ],
                  bottom: _tabBar()),
            )
          ];
        },
        body: TabBarView(
          controller: tabController,
          physics: const CustomTabBarViewScrollPhysics(),
          children: [
            BbsListPage(scrollController: bbsListScrollController),
            buildAlramWidget(),
            ChatMainApp(key: chatMainPageKey, scrollController: chatListScrollController),
          ],
        ),
      ),
    );
  }

  // 알림 리스트 위젯
  Widget buildAlramWidget() {
    return RefreshIndicator(
      onRefresh: () async => await getData(0),
      child: ListView(
        controller: alramScrollController,
        // physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        children: [
          Gap(appbarBottomHeight),
          ValueListenableBuilder<bool>(
              valueListenable: isAdLoading,
              builder: (context, value, child) {
                if (!value) return const SizedBox.shrink();
                return const SizedBox(width: double.infinity, child: Center(child: BannerAdWidget(screenName: 'AlramPage')));
              }),
          const Gap(20),
          Utils.commonStreamList<AlramResData>(alramController.listCtrl, buildList, getDataInit, noDataWidget: noDataWidget()),
          const Gap(30),
        ],
      ),
    );
  }

  Widget noDataWidget() {
    return Center(
        child: Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 200),
      child: const Text(
        '조회된 데이터가 없습니다.',
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        textAlign: TextAlign.center,
      ),
    ));
  }

  Widget buildList(List<AlramResData> list) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListView.builder(
          shrinkWrap: true,
          itemCount: list.length,
          padding: const EdgeInsets.all(0),
          physics: const AlwaysScrollableScrollPhysics(),
          itemBuilder: (BuildContext context, int index) {
            return buildItem(list[index]);
          },
        ),
      ],
    );
  }

  Widget buildItem(AlramResData data) {
    data.profilePath = data.profilePath == '' ? null : data.profilePath;
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ElevatedButton(
          clipBehavior: Clip.none,
          style: ElevatedButton.styleFrom(
            shadowColor: Colors.transparent,
            // fixedSize: Size(0, 0),
            minimumSize: Size.zero, // Set this
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 7),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: const VisualDensity(horizontal: 0, vertical: 0),
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(5),
            ),
            backgroundColor: Colors.transparent,
          ),
          onPressed: () {
            if (data.boardId != null) {
              // Get.toNamed('/VideoMyinfoListPage',
              //     arguments: {'datatype': 'ONE', 'custId': AuthCntr.to.resLoginData.value.custId, 'boardId': data.boardId.toString()});
              AppPages.goRoute(data.alramCd.toString(), AuthCntr.to.resLoginData.value.custId.toString(), data.boardId);
            } else {
              Get.toNamed('/OtherInfoPage/${data.senderCustId}');
            }
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              !StringUtils.isEmpty(data.profilePath)
                  ? Container(
                      height: 45,
                      width: 45,
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        // color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(10),
                        image: DecorationImage(
                          image: CachedNetworkImageProvider(cacheKey: data.profilePath.toString(), data.profilePath.toString()),
                          fit: BoxFit.cover,
                        ),
                      ))
                  : Container(
                      height: 45,
                      width: 45,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        // color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: Center(
                        child: Text(
                          (data.senderNickNm == null ? data.senderCustNm.toString() : data.senderNickNm.toString()).substring(0, 1),
                          style: const TextStyle(fontSize: 19, color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
              const Gap(10),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Text(
                          data.alramTitle.toString(),
                          softWrap: true,
                          // overflow: TextOverflow.fade,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.black87),
                        ),
                        const Spacer(),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            data.alramContents.toString(),
                            // softWrap: true,
                            overflow: TextOverflow.clip,
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black),
                          ),
                        ),
                        const Gap(5),
                        data.boardId != null
                            ? SizedBox(
                                width: 20,
                                height: 25,
                                child: TextButton(
                                  style: TextButton.styleFrom(
                                    padding: EdgeInsets.zero,
                                    minimumSize: Size.zero,
                                  ),
                                  onPressed: () {
                                    if (data.boardId != null) {
                                      // Get.toNamed('/VideoMyinfoListPage',
                                      //     arguments: {'datatype': 'ONE', 'custId': AuthCntr.to.resLoginData.value.custId, 'boardId': data.boardId.toString()});
                                      AppPages.goRoute(data.alramCd.toString(), AuthCntr.to.resLoginData.value.custId.toString(),
                                          data.boardId.toString());
                                    } else {
                                      Get.toNamed('/OtherInfoPage/${data.senderCustId}');
                                    }
                                  },
                                  child: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.black),
                                ),
                              )
                            : const SizedBox(
                                width: 10,
                              ),
                      ],
                    ),
                    // const Gap(6),
                    SizedBox(
                      height: 30,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            data.senderNickNm == null ? data.senderCustNm.toString() : data.senderNickNm.toString(),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13.0,
                              color: Colors.black54,
                            ),
                          ),
                          // 가운데 점 표시
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 6.0),
                            child: Text(
                              '·',
                              style: TextStyle(color: Colors.black87, fontSize: 16),
                            ),
                          ),
                          Text(
                            Utils.timeage(data.crtDtm.toString()),
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: Colors.black),
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
      ],
    );
  }

  Future<void> getData(int page) async {
    await alramController.getData(page);
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._tabBar);

  final TabBar _tabBar;

  @override
  double get minExtent => _tabBar.preferredSize.height;

  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Colors.white,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}
