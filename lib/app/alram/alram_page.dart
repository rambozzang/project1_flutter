import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:get/get.dart';
import 'package:project1/app/bbs/bbs_list_page.dart';
import 'package:project1/app/bbs/cntr/bbs_list_cntr.dart';
import 'package:project1/app/spot/spot_weather_body.dart';
import 'package:project1/widget/animation_searchbar.dart';
import 'package:project1/widget/custom_tabbarview.dart';

class AlramPage extends StatefulWidget {
  const AlramPage({super.key});

  @override
  State<AlramPage> createState() => _AlramPageState();
}

class _AlramPageState extends State<AlramPage> with AutomaticKeepAliveClientMixin, SingleTickerProviderStateMixin {
  @override
  bool get wantKeepAlive => true;

  final ScrollController mainScrollController = ScrollController();
  final ScrollController bbsListScrollController = ScrollController();

  TextEditingController searChWordController = TextEditingController();

  final bbsListController = Get.put(BbsListController());

  late TabController tabController;
  final ValueNotifier<int> tabIndex = ValueNotifier<int>(0);
  final globalKey = GlobalKey<NestedScrollViewState>();
  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _setupScrollListener();
  }

  void _initializeControllers() {
    tabController = TabController(vsync: this, length: 2);

    tabController.addListener(() {
      tabIndex.value = tabController.index;
    });
  }

  void _setupScrollListener() {
    bbsListScrollController.addListener(() {
      mainScrollController.jumpTo(bbsListScrollController.offset);
    });
  }

  @override
  void dispose() {
    tabController.dispose();
    mainScrollController.dispose();
    bbsListScrollController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return DefaultTabController(
      length: 2,
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
            mainAxisSize: MainAxisSize.min,
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
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.place_outlined,
                size: 17,
              ),
              Gap(5),
              Text('스팟별 날씨', style: TextStyle(color: Colors.black, fontSize: 14, fontWeight: FontWeight.w500)),
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
                            // 스팟별 날씨 탭은 SpotWeatherBody 낭비에서 당겨서 새로고침한다.
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
            const SpotWeatherBody(topPadding: 8),
          ],
        ),
      ),
    );
  }

  // 알림 리스트 위젯 (알람/채팅 탭 제거로 현재 사용되지 않음)
  Widget buildAlramWidget() {
    return const SizedBox.shrink();
  }

}
