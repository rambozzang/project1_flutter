import 'package:get/get.dart';
import 'package:project1/app/login/login_page.dart';
import 'package:project1/app/root/root_cntr.dart';
import 'package:project1/app/root/root_page.dart';

abstract class AppPages {
  AppPages._();
  // ignore: constant_identifier_names
  static const INITIAL = '/LoginPage';

  static final routes = [
    GetPage(
      name: '/LoginPage',
      page: () => const LoginPage(),
      transition: Transition.downToUp,
    ),
    GetPage(
      name: '/root',
      page: () => const RootPage(),
      binding: RootCntrBinding(),
      transition: Transition.downToUp,
    )
  ];
}
