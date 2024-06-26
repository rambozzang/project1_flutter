import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:project1/app/auth/cntr/auth_cntr.dart';

import 'package:project1/app/test/color_page.dart';
import 'package:project1/app/test/test_link_page.dart';
import 'package:project1/root/board_list_page.dart';
import 'package:project1/root/cntr/root_cntr.dart';
import 'package:project1/root/follow_list_page.dart';
import 'package:project1/root/like_list_page.dart';
import 'package:project1/utils/log_utils.dart';
import 'package:project1/widget/custom_tabbarview.dart';

class MainView1 extends StatefulWidget {
  const MainView1({super.key});

  @override
  State<MainView1> createState() => _MainView1State();
}

class _MainView1State extends State<MainView1> with SingleTickerProviderStateMixin {
  var alignment = Alignment.centerRight;

  List<String> tabNames = ["게시물", "좋아요", "팔로워", "팔로잉"];

// 탭 바디 부분
  List<dynamic> tabBodys = [];

  @override
  void initState() {
    RootCntr.to.tabController = TabController(vsync: this, length: tabNames.length, animationDuration: const Duration(milliseconds: 130));
    Lo.g("1widget.searchWord : ${Get.parameters['searchWord']}");
    Lo.g("1widget.tabPage : ${Get.parameters['tabPage']}");
    tabBodys = [
      BoardListPage(searchWord: Get.parameters['searchWord'].toString()),
      const LikeListPage(),
      const FollowListPage(
        followType: 1,
      ),
      const FollowListPage(
        followType: 0,
      ),
      // TestLinkPage(key: const ValueKey(1)),
    ];

    super.initState();
  }

  @override
  void didChangeDependencies() {
    RootCntr.to.tabController.index = int.parse(Get.parameters['tabPage'].toString());
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    //Lo.g('main_view.dart > build');
    // 안드로이드에서 StatusBar의 색과 안드로이드와 iOS 모두에서 StatusBar 아이콘 색상을
    // 설정하기 위해 AnnotatedRegion을 사용함
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
          statusBarColor: Colors.white, statusBarBrightness: Brightness.light, statusBarIconBrightness: Brightness.dark),
      child: Material(
        color: Colors.white,
        // child: bodyWidget(),
        child: NotificationListener<UserScrollNotification>(
          onNotification: (notification) {
            if (notification.depth >= 2) {
              if (notification.direction == ScrollDirection.forward && RootCntr.to.hideButtonController1.offset != 0) {
                RootCntr.to.hideButtonController1.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.ease);
              } else if (notification.depth >= 2 &&
                  notification.direction == ScrollDirection.reverse &&
                  RootCntr.to.hideButtonController1.offset != 105) {
                RootCntr.to.hideButtonController1.animateTo(105, duration: const Duration(milliseconds: 300), curve: Curves.ease);
              }
            }
            return false;
          },
          child: bodyWidget(),
        ),
      ),
    );
  }

  Widget bodyWidget() {
    return Material(
      color: Colors.white,
      child: SafeArea(
        child: DefaultTabController(
          length: tabNames.length,
          child: NestedScrollView(
            controller: RootCntr.to.hideButtonController1,
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                SliverAppBar(
                  pinned: false,
                  floating: true,
                  automaticallyImplyLeading: false,
                  // 자석효과 : 진짜 살짝만 아래로 내리거나 올리면 앱바가 올라가거나 내려감 (이거 쓸라면 floating true , pinned false)
                  // snap: true,
                  // app bar를 따라오게 (기본값은 false 근데) 원래는 뒤에 흰 배경이 보임
                  // stretch: true,
                  forceElevated: innerBoxIsScrolled,
                  toolbarHeight: 60,
                  elevation: 0,
                  centerTitle: false,
                  backgroundColor: Colors.white,
                  title: Row(
                    // crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // SvgPicture.asset(
                      //   'assets/appicon.svg',
                      //   width: 30,
                      // ),
                      // SizedBox(
                      //   width: 10,
                      // ),
                      Text('${AuthCntr.to.resLoginData.value.nickNm}',
                          style: const TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.w700,
                              fontFamily: "NotoSansKR",
                              fontStyle: FontStyle.normal,
                              fontSize: 19.0)),
                      Align(
                          alignment: Alignment.topRight,
                          child: IconButton(icon: const Icon(Icons.close, color: Colors.black), onPressed: () => Get.back()))
                    ],
                  ),
                ),
                // 변경사항
                SliverOverlapAbsorber(
                  handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
                  sliver: SliverPersistentHeader(pinned: true, delegate: TabBarDelegate(tabNames)),
                ),
              ];
            },
            body: Column(
              children: [
                // SizedBox(height: 48),
                Expanded(
                  child: TabBarView(
                    controller: RootCntr.to.tabController,
                    physics: const CustomTabBarViewScrollPhysics(),
                    children: [...tabBodys],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class TabBarDelegate extends SliverPersistentHeaderDelegate {
  List<String> tabNames;

  TabBarDelegate(this.tabNames);

  @override
  double get maxExtent => 49;

  @override
  double get minExtent => 48;

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) {
    return false;
  }

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 0.0, vertical: 0.0),
      width: double.infinity,
      color: Colors.white,
      child: TabBar(
        labelPadding: const EdgeInsets.symmetric(horizontal: 1.5, vertical: 0.0),
        tabAlignment: TabAlignment.start,
        labelColor: Colors.black,
        labelStyle: const TextStyle(
          fontFamily: "NotoSansKR",
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
        padding: const EdgeInsets.all(0.0),
        indicatorColor: Colors.transparent,
        dividerColor: Colors.grey[300],
        unselectedLabelStyle: TextStyle(
          fontSize: 13,
          color: Colors.grey[100],
          fontFamily: "NotoSansKR",
        ),
        unselectedLabelColor: Colors.white,
        indicatorSize: TabBarIndicatorSize.label,
        //indicatorColor: Colors.white,
        indicator: UnderlineTabIndicator(
          borderSide: BorderSide(color: Colors.grey.shade600, width: 3.0),
        ),
        controller: RootCntr.to.tabController,
        isScrollable: true,
        tabs: [...List.generate(tabNames.length, (i) => getTabButton(tabNames[i]))],
      ),
    );
  }

  Widget getTabButton(String title) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
      child: Tab(
        height: 45,
        child: Text(title, style: const TextStyle(fontSize: 14, color: Colors.black, fontWeight: FontWeight.bold)),
      ),
    );
  }
}

class CategoryBreadcrumbs extends SliverPersistentHeaderDelegate {
  const CategoryBreadcrumbs();
  @override
  double get maxExtent => 48;
  @override
  double get minExtent => 48;
  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) {
    return false;
  }

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Colors.white,
      height: 48,
      width: 250,
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          const Text("전체", style: TextStyle(color: Colors.black)),
          const SizedBox(width: 4),
          const Text(">", style: TextStyle(color: Colors.black)),
          const SizedBox(width: 4),
          const Text("오늘의 뉴스", style: TextStyle(color: Colors.black)),
          const Spacer(),
          TextButton(
            onPressed: () {},
            child: const Center(child: Text("전체보기")),
          )
        ],
      ),
    );
  }
}
