import 'package:get/get.dart';

class FavoAreaBinding implements Bindings {
  @override
  void dependencies() {
    Get.lazyPut<FavoAreaCntr>(() => FavoAreaCntr());
  }
}

class FavoAreaCntr extends GetxController {
  static FavoAreaCntr get to => Get.find();

  @override
  void onInit() async {
    super.onInit();
  }
}
