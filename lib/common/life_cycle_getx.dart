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
        // SupabaseChatCore.instance.setPresenceStatus(UserOnlineStatus.offline);

        break;
      case AppLifecycleState.paused:
        Get.log("Paused ###############");
        // SupabaseChatCore.instance.setPresenceStatus(UserOnlineStatus.offline);

        break;
      case AppLifecycleState.inactive:
        Get.log("Inactive ###############");
        // SupabaseChatCore.instance.setPresenceStatus(UserOnlineStatus.offline);

        break;
      case AppLifecycleState.hidden:
        Get.log("Inactive ###############");
        // SupabaseChatCore.instance.setPresenceStatus(UserOnlineStatus.offline);

        break;
      case AppLifecycleState.resumed:
        // IOS 실기기에서는 앱실행시 한번 실행됨
        Get.log("Resumed ###############");
        // SupabaseChatCore.instance.setPresenceStatus(UserOnlineStatus.online);

        break;

      default:
    }
  }
}
