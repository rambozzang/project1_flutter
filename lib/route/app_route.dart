import 'package:get/get.dart';
import 'package:project1/app/%08join/join_page.dart';
import 'package:project1/app/auth/auth_page.dart';
import 'package:project1/app/auth/cntr/auth_cntr.dart';
import 'package:project1/app/list/cntr/video_list_cntr.dart';
import 'package:project1/app/list/cntr/video_myinfo_list_cntr.dart';
import 'package:project1/app/list/video_list_page.dart';
import 'package:project1/app/camera/page/test.dart';
import 'package:project1/app/list/video_myinfo_list_page.dart';
import 'package:project1/app/myinfo/myinfo_modify_page.dart';
import 'package:project1/app/myinfo/myinfo_page.dart';
import 'package:project1/app/onboarding/onboarding_page.dart';
import 'package:project1/app/setting/agree_page.dart';
import 'package:project1/app/setting/faq_page.dart';
import 'package:project1/app/setting/location_service_page.dart';
import 'package:project1/app/setting/noti_page.dart';
import 'package:project1/app/setting/noti_view_page.dart';
import 'package:project1/app/setting/open_source_page.dart';
import 'package:project1/app/setting/privecy_page.dart';
import 'package:project1/app/setting/setting_page.dart';
import 'package:project1/root/cntr/root_cntr.dart';
import 'package:project1/root/follow_list_page.dart';
import 'package:project1/root/main_view1.dart';
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
      name: '/VideoListPage',
      page: () => const VideoListPage(),
      binding: VideoListBinding(),
      //  transition: Transition.downToUp,
    ),
    GetPage(
      name: '/VideoMyinfoListPage',
      page: () => const VideoMyinfoListPage(),
      binding: VideoMyinfoListBinding(),
      //  transition: Transition.downToUp,
    ),
    GetPage(
      name: '/MyinfoPage',
      page: () => const MyPage(),
      //  transition: Transition.downToUp,
    ),
    GetPage(
      name: '/TestPage',
      page: () => const TestPage(),
      //  transition: Transition.downToUp,
    ),
    GetPage(
      name: '/SettingPage',
      page: () => const SettingPage(),
      //  transition: Transition.downToUp,
    ),
    GetPage(
      name: '/MainView1/:searchWord/:tabPage',
      page: () => const MainView1(),
      //  transition: Transition.downToUp,
    ),
    GetPage(
      name: '/NotiPage',
      page: () => const NotiPage(),
      //  transition: Transition.downToUp,
    ),
    GetPage(
      name: '/FaqPage',
      page: () => const FaqPage(),
      //  transition: Transition.downToUp,
    ),
    GetPage(
      name: '/MyinfoModifyPage',
      page: () => const MyinfoModifyPage(),
      //  transition: Transition.downToUp,
    ),
    GetPage(
      name: '/NotiViewPage',
      page: () => const NotiViewPage(),
      //  transition: Transition.downToUp,
    ),
    GetPage(
      name: '/OpenSourcePage',
      page: () => const OpenSourcePage(),
      //  transition: Transition.downToUp,
    ),
    GetPage(
      name: '/PrivecyPage',
      page: () => const PrivecyPage(),
      //  transition: Transition.downToUp,
    ),
    GetPage(
      name: '/AgreePage',
      page: () => const AgreePage(),
      //  transition: Transition.downToUp,
    ),
    GetPage(
      name: '/FollowListPage',
      page: () => const FollowListPage(),
      //  transition: Transition.downToUp,
    ),
    GetPage(
      name: '/LocatinServicePage',
      page: () => const LocatinServicePage(),
      //  transition: Transition.downToUp,
    ),
  ];
}
