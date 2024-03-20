import 'package:flutter/material.dart';
import 'package:get/get.dart';

class LifeCycleGetx extends GetxController with WidgetsBindingObserver {
  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void onClose() {
    super.onClose();
    WidgetsBinding.instance.removeObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    switch (state) {
      case AppLifecycleState.detached:
        Get.log("Detached ###############");
        break;
      case AppLifecycleState.paused:
        Get.log("Paused ###############");
        break;
      case AppLifecycleState.inactive:
        Get.log("Inactive ###############");
        break;
      case AppLifecycleState.resumed:
        // IOS 실기기에서는 앱실행시 한번 실행됨
        Get.log("Resumed ###############");
        break;
      default:
    }
  }
}
