import 'package:get/get.dart';
import 'package:project1/app/%08join/join_page.dart';
import 'package:project1/app/auth/agree_page.dart';
import 'package:project1/app/auth/auth_page.dart';
import 'package:project1/app/chatting/repo/suba_test_page.dart';
import 'package:project1/app/chatting/chat_main_page.dart';
import 'package:project1/app/myinfo/block_page.dart';
import 'package:project1/app/myinfo/myinfo_page.dart';
import 'package:project1/app/setting/alram_setting_page.dart';
import 'package:project1/app/setting/maketing_page.dart';
import 'package:project1/app/favoriteArea/cntr/favo_area_cntr.dart';
import 'package:project1/app/favoriteArea/favorite_area_page.dart';
import 'package:project1/app/test/weather_compare_page.dart';
import 'package:project1/app/videomylist/video_myinfo_list_page.dart';
import 'package:project1/app/myinfo/myinfo_modify_page.dart';
import 'package:project1/app/myinfo/otherinfo_page.dart';
import 'package:project1/app/search/cntr/map_cntr.dart';
import 'package:project1/app/search/map_page.dart';
import 'package:project1/app/search/search_page.dart';
import 'package:project1/app/setting/service_page.dart';
import 'package:project1/app/setting/faq_page.dart';
import 'package:project1/app/setting/location_service_page.dart';
import 'package:project1/app/setting/noti_page.dart';
import 'package:project1/app/setting/noti_view_page.dart';
import 'package:project1/app/setting/open_source_page.dart';
import 'package:project1/app/setting/privecy_page.dart';
import 'package:project1/app/setting/setting_page.dart';
import 'package:project1/app/test/test_dio_page.dart';
import 'package:project1/app/weather/page/sevenday_detail_page.dart';
import 'package:project1/app/weather/page/weather_page.dart';
import 'package:project1/app/weatherCom/cntr/weather_com_controller.dart';
import 'package:project1/app/weatherCom/weather_com_page.dart';
import 'package:project1/app/weathergogo/24_page.dart';
import 'package:project1/app/weathergogo/weathergogo_page.dart';
import 'package:project1/app/webview/weather_webview.dart';
import 'package:project1/app/weathergogo/cntr/weather_gogo_cntr.dart';
import 'package:project1/root/cntr/root_cntr.dart';
import 'package:project1/root/main_view1.dart';
import 'package:project1/root/root_page.dart';

abstract class AppPages {
  AppPages._();
  // ignore: constant_identifier_names
  static const INITIAL = '/AuthPage';

  static final routes = [
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
      transition: Transition.fadeIn,
    ),

    GetPage(
      name: '/SearchPage',
      page: () => const SearchPage(),
      // binding: VideoListBinding(),
      //  transition: Transition.downToUp,
    ),
    // GetPage(
    //   name: '/VideoListPage',
    //   page: () => const VideoListPage(),
    //   // binding: VideoListBinding(),
    //   //  transition: Transition.downToUp,
    // ),
    GetPage(
      name: '/VideoMyinfoListPage',
      page: () => const VideoMyinfoListPage(),
      // binding: VideoMyinfoListBinding(),
      //  transition: Transition.downToUp,
    ),
    GetPage(
      name: '/MyinfoPage',
      page: () => const MyPage(),
      //  transition: Transition.downToUp,
    ),

    GetPage(
      name: '/SettingPage',
      page: () => const SettingPage(),
      //  transition: Transition.downToUp,
    ),
    GetPage(
      name: '/MainView1/:custId/:tabPage/:searchWord',
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
      name: '/MaketingPage',
      page: () => const MaketingPage(),
      //  transition: Transition.downToUp,
    ),

    GetPage(
      name: '/ServicePage',
      page: () => const ServicePage(),
      //  transition: Transition.downToUp,
    ),
    GetPage(
      name: '/LocatinServicePage',
      page: () => const LocatinServicePage(),
      //  transition: Transition.downToUp,
    ),
    GetPage(
      name: '/MapPage',
      page: () => const MapPage(),
      binding: MapBinding(),
      // transition: Transition.downToUp,
    ),
    GetPage(
      name: '/OtherInfoPage/:custId',
      page: () => const OtherInfoPage(),

      // transition: Transition.downToUp,
    ),
    GetPage(
      name: '/TestDioPage',
      page: () => const TestDioPage(),

      // transition: Transition.downToUp,
    ),

    //날씨 관련 페이지
    GetPage(
      name: '/WeatherPage',
      page: () => const WeatherPage(),

      // transition: Transition.downToUp,
    ),
    GetPage(
      name: '/SevendayDetailPage/:initialIndex',
      page: () => const SevendayDetailPage(),
      // transition: Transition.downToUp,
    ),
    GetPage(
      name: '/WeatherWebView',
      page: () => const WeatherWebView(
        isBackBtn: true,
      ),
    ),

    GetPage(
      name: '/SupaTestPage',
      page: () => const SupaTestPage(),
      // transition: Transition.downToUp,
    ),
    GetPage(
      name: '/ChatMainApp',
      page: () => const ChatMainApp(),
      // transition: Transition.downToUp,
    ),
    GetPage(
      name: '/FavoriteAreaPage',
      page: () => const FavoriteAreaPage(),
      binding: FavoAreaBinding(),
      // transition: Transition.downToUp,
    ),

    GetPage(
      name: '/AlramSettingPage',
      page: () => const AlramSettingPage(),
      // transition: Transition.downToUp,
    ),
    GetPage(
      name: '/WeatherComparePage',
      page: () => const WeatherComparePage(),
      // transition: Transition.downToUp,
    ),
    GetPage(
      name: '/AgreePage/:custId',
      page: () => const AgreePage(),
      // transition: Transition.downToUp,
    ),
    GetPage(
      name: '/WeathgergogoPage',
      page: () => const WeathgergogoPage(),
      // binding: WeatherGogoCntrBinding(),
      // transition: Transition.downToUp,
    ),
    GetPage(
      name: '/WeatherComPage',
      page: () => WeatherComPage(),
      binding: WeatherComControllerBinding(),
      // transition: Transition.downToUp,
    ),
    GetPage(
      name: '/T24Page',
      page: () => T24Page(),
      // transition: Transition.downToUp,
    ),
    GetPage(
      name: '/BlockListPage',
      page: () => BlockListPage(),
      // transition: Transition.downToUp,
    ),
  ];
}
