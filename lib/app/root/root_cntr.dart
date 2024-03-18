import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:get/get.dart';

class RootCntrBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<RootCntr>(
      () => RootCntr(),
    );
  }
}

class RootCntr extends GetxController {
  static RootCntr get to => Get.find();

  final StreamController<bool> bottomBarStreamController = StreamController<bool>();

  RxInt rootPageIndex = 0.obs;
  GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  RxBool isCategoryPageOpen = false.obs;

  ScrollController hideButtonController1 = ScrollController();
  ScrollController hideButtonController11 = ScrollController();
  ScrollController hideButtonController12 = ScrollController();

  ScrollController hideButtonController2 = ScrollController();
  ScrollController hideButtonController3 = ScrollController();
  late TabController tabController;

  // 하단 바 숨기기 변수
  // RxDouble isVisible = 1.0.obs;
  RxBool isVisible = true.obs;

  @override
  void onInit() {
    hideButtonController1.addListener(() => changeScrollListner(hideButtonController1));
    hideButtonController11.addListener(() => changeScrollListner(hideButtonController11));
    hideButtonController12.addListener(() => changeScrollListner(hideButtonController12));
    hideButtonController2.addListener(() => changeScrollListner(hideButtonController2));
    hideButtonController3.addListener(() => changeScrollListner(hideButtonController3));

    super.onInit();
  }

  // 스크롤에 따라 bottom bar hide
  void changeScrollListner(ScrollController scrollData) {
    if (scrollData.position.userScrollDirection == ScrollDirection.reverse) {
      if (isVisible.value) {
        isVisible.value = false;
        bottomBarStreamController.sink.add(isVisible.value);
      }
    } else if (scrollData.position.userScrollDirection == ScrollDirection.forward) {
      if (!isVisible.value) {
        isVisible.value = true;
        bottomBarStreamController.sink.add(isVisible.value);
      }
    }
  }

  void changeRootPageIndex(int index) {
    rootPageIndex(index);
  }

  Future<bool> onWillPop() async {
    setCategoryPage(false);
    return !await navigatorKey.currentState!.maybePop();
  }

  void setCategoryPage(bool ck) {
    isCategoryPageOpen(ck);
  }

  void back() {
    setCategoryPage(false);
    onWillPop();
  }

  @override
  void dispose() {
    hideButtonController1.dispose();
    hideButtonController11.dispose();
    hideButtonController12.dispose();
    hideButtonController2.dispose();
    hideButtonController3.dispose();
    bottomBarStreamController.close();

    super.dispose();
  }
}
