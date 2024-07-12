import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:project1/app/auth/cntr/auth_cntr.dart';

import 'package:project1/repo/common/res_data.dart';
import 'package:project1/repo/cust/cust_repo.dart';
import 'package:project1/repo/cust/data/cust_data.dart';
import 'package:project1/root/board_list_page.dart';
import 'package:project1/root/follow_list_page.dart';
import 'package:project1/root/following_list_page.dart';
import 'package:project1/root/like_list_page.dart';
import 'package:project1/utils/log_utils.dart';
import 'package:project1/utils/utils.dart';
import 'package:project1/widget/custom_tabbarview.dart';

class MainView1 extends StatefulWidget {
  const MainView1({
    super.key,
  });

  @override
  State<MainView1> createState() => _MainView1State();
}

class _MainView1State extends State<MainView1> with SingleTickerProviderStateMixin {
  var alignment = Alignment.centerRight;

  List<String> tabNames = ["게시물", "좋아요", "팔로워", "팔로잉"];

// 탭 바디 부분
  List<dynamic> tabBodys = [];

  late String custId;
  late String searchWord;
  late String tabPage;
  final ValueNotifier<String> nickNm = ValueNotifier<String>('');
  late TabController tabController;

  @override
  void initState() {
    super.initState();
    tabController = TabController(vsync: this, length: tabNames.length, animationDuration: const Duration(milliseconds: 130));
    Lo.g("1widget.searchWord : ${Get.parameters['searchWord']}");
    Lo.g("1widget.tabPage : ${Get.parameters['tabPage']}");
    Lo.g("1widget.custId 1: ${Get.parameters['custId']}");

    custId = Get.parameters['custId'].toString();
    searchWord = Get.parameters['searchWord'].toString();
    tabPage = Get.parameters['tabPage'].toString();

    tabBodys = [
      BoardListPage(custId: custId, searchWord: searchWord),
      LikeListPage(custId: custId),
      FollowListPage(custId: custId),
      FollowingListPage(custId: custId),
    ];

    getUserData(custId);
  }

  Future<void> getUserData(String custId) async {
    try {
      // 본인 체크
      if (AuthCntr.to.custId.value == custId) {
        nickNm.value = AuthCntr.to.resLoginData.value.nickNm.toString();
        return;
      }

      CustRepo repo = CustRepo();
      ResData res = await repo.getCustInfo(custId.toString());
      if (res.code != '00') {
        Utils.alert(res.msg.toString());
        return;
      }
      CustData custData = CustData.fromMap(res.data);

      lo.g('custData : ${custData.toString()}');
      nickNm.value = custData!.nickNm.toString();
    } catch (e) {
      Utils.alert(e.toString());
    }
  }

  @override
  void didChangeDependencies() {
    tabController.index = int.parse(Get.parameters['tabPage'].toString());
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    super.dispose();
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
        child: bodyWidget(),
        // child: NotificationListener<UserScrollNotification>(
        //   onNotification: (notification) {
        //     if (notification.depth >= 2) {
        //       if (notification.direction == ScrollDirection.forward && RootCntr.to.hideButtonController1.offset != 0) {
        //         RootCntr.to.hideButtonController1.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.ease);
        //       } else if (notification.depth >= 2 &&
        //           notification.direction == ScrollDirection.reverse &&
        //           RootCntr.to.hideButtonController1.offset != 105) {
        //         RootCntr.to.hideButtonController1.animateTo(105, duration: const Duration(milliseconds: 300), curve: Curves.ease);
        //       }
        //     }
        //     return false;
        //   },
        //   child: bodyWidget(),
        // ),
      ),
    );
  }

  Widget bodyWidget() {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: DefaultTabController(
          length: tabNames.length,
          child: NestedScrollView(
            //     controller: RootCntr.to.hideButtonController1,
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
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ValueListenableBuilder<String?>(
                          valueListenable: nickNm,
                          builder: (context, value, child) {
                            return Text(value.toString(),
                                style: const TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.w700,
                                    fontFamily: "NotoSansKR",
                                    fontStyle: FontStyle.normal,
                                    fontSize: 19.0));
                          }),
                      Align(
                          alignment: Alignment.topRight,
                          child: IconButton(icon: const Icon(Icons.close, color: Colors.black), onPressed: () => Get.back()))
                    ],
                  ),
                ),
                // 변경사항
                SliverOverlapAbsorber(
                  handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
                  sliver: SliverPersistentHeader(pinned: true, delegate: TabBarDelegate(tabNames, tabController)),
                ),
              ];
            },
            body: Column(
              children: [
                Expanded(
                  child: TabBarView(
                    controller: tabController,
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
  TabController tabController;

  TabBarDelegate(this.tabNames, this.tabController);

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
        controller: tabController,
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
