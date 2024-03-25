import 'package:get/get.dart';
import 'package:project1/app/%08join/join_page.dart';
import 'package:project1/app/auth/auth_page.dart';
import 'package:project1/app/auth/cntr/auth_cntr.dart';
import 'package:project1/app/camera/list_tictok/list_page.dart';
import 'package:project1/app/onboarding/onboarding_page.dart';
import 'package:project1/root/cntr/root_cntr.dart';
import 'package:project1/root/root_page.dart';

abstract class AppPages {
  AppPages._();
  // ignore: constant_identifier_names
  static const INITIAL = '/AuthPage';

  static final routes = [
    GetPage(
      name: '/OnboardingPage',
      page: () => const OnboardingPage(),
      transition: Transition.downToUp,
    ),
    GetPage(
      name: '/AuthPage',
      page: () => const AuthPage(),
      // binding: AuthBinding(),
    ),
    GetPage(
      name: '/JoinPage',
      page: () => const JoinPage(),
      transition: Transition.downToUp,
    ),
    GetPage(
      name: '/rootPage',
      page: () => const RootPage(),
      binding: RootCntrBinding(),
      //  transition: Transition.downToUp,
    ),
    GetPage(
      name: '/ListPage',
      page: () => const ListPage(),

      //  transition: Transition.downToUp,
    )
  ];
}
