import 'dart:math';

import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

class MyinfoPage extends StatefulWidget {
  const MyinfoPage({super.key});

  @override
  State<MyinfoPage> createState() => _MyinfoPageState();
}

class _MyinfoPageState extends State<MyinfoPage> {
  ScrollController scrollController = ScrollController();
  PageController pageController = PageController(initialPage: 0);

  final double sliverMinHeight = 80.0, sliverMaxHeight = 140.0;
  int pageIndex = 0;

  final colors = [
    Colors.red,
    Colors.purple,
    Colors.green,
    Colors.orange,
    Colors.yellow,
    Colors.pink,
    Colors.cyan,
    Colors.indigo,
    Colors.blue,
  ];

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    scrollController.dispose();
    pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: NestedScrollView(
          controller: scrollController,
          headerSliverBuilder: headerSliverBuilder,
          body: Container(
            margin: EdgeInsets.only(top: sliverMinHeight),
            child: mainPageView(),
          ),
        ),
      ),
    );
  }

  List<Widget> headerSliverBuilder(BuildContext context, bool innerBoxIsScrolled) {
    return <Widget>[
      SliverOverlapAbsorber(
        handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
        sliver: SliverPersistentHeader(
          pinned: true,
          delegate: SliverHeaderDelegateCS(
            minHeight: sliverMinHeight,
            maxHeight: sliverMaxHeight,
            minChild: minTopChild(),
            maxChild: profileInfo(),
            //  maxChild: topChild(),
          ),
        ),
      ),
    ];
  }

  // 프로필 정보
  Widget profileInfo() {
    return Column(
      children: [
        Row(
          children: [
            const Gap(20),
            Container(
              width: 60,
              height: 60,
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.grey,
                borderRadius: BorderRadius.circular(50),
              ),
            ),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Tiger Bk', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                Gap(10),
                Text('a'),
              ],
            ),
          ],
        ),
        pageButtonLayout(),
      ],
    );
  }

  Widget minTopChild() {
    return Column(
      children: <Widget>[
        Expanded(
          child: Container(
            alignment: Alignment.center,
            color: Color(0xFF014F90),
            child: Text(
              "Min Top Bar",
              style: TextStyle(
                color: Color(0xFFFFFFFF),
                fontSize: 23,
              ),
            ),
          ),
        ),
        pageButtonLayout(),
      ],
    );
  }

  Widget topChild() {
    return Column(
      children: <Widget>[
        Expanded(
          child: Container(
            alignment: Alignment.center,
            color: Color(0xFFFF1D1D),
            child: Text(
              "Max Top Bar",
              style: TextStyle(
                color: Color(0xFFFFFFFF),
                fontSize: 23,
              ),
            ),
          ),
        ),
        pageButtonLayout(),
      ],
    );
  }

  Widget pageButtonLayout() {
    return SizedBox(
      height: sliverMinHeight / 2,
      child: Row(
        children: <Widget>[
          Expanded(child: pageButton("page 1", 0)),
          Expanded(child: pageButton("page 2", 1)),
          Expanded(child: pageButton("page 3", 2)),
          Expanded(child: pageButton("page 4", 3)),
        ],
      ),
    );
  }

  Widget pageButton(String title, int page) {
    final fontColor = pageIndex == page ? Color(0xFF2C313C) : Color(0xFF9E9E9E);
    final lineColor = pageIndex == page ? Color(0xFF014F90) : Color(0xFFF1F1F1);

    return InkWell(
      splashColor: Color(0xFF204D7E),
      onTap: () => pageBtnOnTap(page),
      child: Column(
        children: <Widget>[
          Expanded(
            child: Center(
              child: Text(
                title,
                style: TextStyle(
                  color: fontColor,
                ),
              ),
            ),
          ),
          Container(
            height: 1,
            color: lineColor,
          ),
        ],
      ),
    );
  }

  pageBtnOnTap(int page) {
    setState(() {
      pageIndex = page;
      pageController.animateToPage(pageIndex, duration: Duration(milliseconds: 700), curve: Curves.easeOutCirc);
    });
  }

  Widget mainPageView() {
    return PageView(
      controller: pageController,
      children: <Widget>[
        pageItem(
          Text("page 1"),
        ),
        pageItem(Center(
          child: Text(
            "page 2\n\n두번째\n\n페이지\n\n스크롤이\n\n되도록\n\n내용을\n\n길게\n\n길게",
            style: TextStyle(fontSize: 100),
          ),
        )),
        pageListView(),
        pageItem(Center(
          child: Text("page 4"),
        )),
      ],
      onPageChanged: (index) => setState(() => pageIndex = index),
    );
  }

  Widget pageItem(Widget child) {
    double statusHeight = MediaQuery.of(context).padding.top;
    double height = MediaQuery.of(context).size.height;
    double minHeight = height - statusHeight - sliverMinHeight;

    return SingleChildScrollView(
      child: Container(
        color: Colors.white,
        constraints: BoxConstraints(minHeight: minHeight),
        child: child,
      ),
    );
  }

  Widget pageListView() {
    return ListView.builder(
      itemCount: colors.length,
      itemBuilder: (BuildContext context, int index) {
        return Container(
          color: colors[index],
          height: 150,
        );
      },
    );
  }
}

class SliverHeaderDelegateCS extends SliverPersistentHeaderDelegate {
  SliverHeaderDelegateCS({
    required this.minHeight,
    required this.maxHeight,
    required this.maxChild,
    required this.minChild,
  });
  double minHeight, maxHeight;
  final Widget maxChild, minChild;

  late double visibleMainHeight, animationVal, width;

  @override
  bool shouldRebuild(SliverHeaderDelegateCS oldDelegate) => true;
  @override
  double get minExtent => minHeight;
  @override
  double get maxExtent => max(maxHeight, minHeight);

  double scrollAnimationValue(double shrinkOffset) {
    double maxScrollAllowed = maxExtent - minExtent;

    return ((maxScrollAllowed - shrinkOffset) / maxScrollAllowed).clamp(0, 1).toDouble();
  }

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    width = MediaQuery.of(context).size.width;
    visibleMainHeight = max(maxExtent - shrinkOffset, minExtent);
    animationVal = scrollAnimationValue(shrinkOffset);

    return Container(
        height: visibleMainHeight,
        width: MediaQuery.of(context).size.width,
        color: Color(0xFFFFFFFF),
        child: Stack(
          children: <Widget>[
            getMinTop(),
            animationVal != 0 ? getMaxTop() : Container(),
          ],
        ));
  }

  Widget getMaxTop() {
    return Positioned(
      bottom: 0.0,
      child: Opacity(
        opacity: animationVal,
        child: SizedBox(
          height: maxHeight,
          width: width,
          child: maxChild,
        ),
      ),
    );
  }

  Widget getMinTop() {
    return Opacity(
      opacity: 1 - animationVal,
      child: Container(height: visibleMainHeight, width: width, child: minChild),
    );
  }

  // 프로필 정보
  Widget profileInfo() {
    return Column(
      children: [
        const Gap(20),
        Row(
          children: [
            const Gap(20),
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.grey,
                borderRadius: BorderRadius.circular(50),
              ),
            ),
            const Gap(20),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Tiger Bk', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                Gap(10),
                Text('a'),
              ],
            ),
          ],
        ),
      ],
    );
  }
}
