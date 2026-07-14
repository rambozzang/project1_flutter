import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:project1/app/camera/page/camera_awesome_page.dart';
import 'package:project1/app/spot/spot_weather_page.dart';
import 'package:project1/app/special_weather/special_weather_list_page.dart';
import 'package:project1/app/special_weather/special_weather_detail_page.dart';
import 'package:project1/app/bbs/bbs_list_page.dart';
import 'package:project1/app/bbs/bbs_modify_page.dart';
import 'package:project1/app/bbs/bbs_my_list_page.dart';
import 'package:project1/app/bbs/bbs_search_list_page.dart';
import 'package:project1/app/bbs/bbs_view_page.dart';
import 'package:project1/app/bbs/bbs_write_page.dart';
import 'package:project1/app/bbs/cntr/bbs_my_list_cntr.dart';
import 'package:project1/app/bbs/cntr/bbs_search_list_cntr.dart';
import 'package:project1/app/bbs/cntr/bbs_write_cntr.dart';

import 'package:project1/app/bbs/cntr/bbs_modify_cntr.dart';
import 'package:project1/app/short/cntr/short_list_cntr.dart';
import 'package:project1/app/short/cntr/short_modify_cntr.dart';
import 'package:project1/app/short/cntr/short_view_cntr.dart';
import 'package:project1/app/short/cntr/short_write_cntr.dart';
import 'package:project1/app/short/short_list_page.dart';
import 'package:project1/app/short/short_modify_page.dart';
import 'package:project1/app/short/short_view_page.dart';
import 'package:project1/app/short/short_write_page.dart';
import 'package:project1/app/join/join_page.dart';
import 'package:project1/app/auth/agree_page.dart';
import 'package:project1/app/auth/auth_page.dart';
import 'package:project1/app/myinfo/block_page.dart';
import 'package:project1/app/myinfo/myinfo_page.dart';
import 'package:project1/app/setting/alram_setting_page.dart';
import 'package:project1/app/setting/weather_noti_setting_page.dart';
import 'package:project1/app/shared_album/album_cover_editor_page.dart';
import 'package:project1/app/shared_album/album_create_page.dart';
import 'package:project1/app/shared_album/album_detail_page.dart';
import 'package:project1/app/shared_album/album_shell.dart';
import 'package:project1/app/shared_album/album_explore_page.dart';
import 'package:project1/app/shared_album/album_invite_page.dart';
import 'package:project1/app/shared_album/album_immersive_page.dart';
import 'package:project1/app/shared_album/album_list_page.dart';
import 'package:project1/app/shared_album/sa_preview_page.dart';
import 'package:project1/app/setting/maketing_page.dart';
import 'package:project1/app/favoriteArea/favorite_area_page.dart';
import 'package:project1/app/videomylist/video_myinfo_list_page.dart';
import 'package:project1/app/community/community_hub_page.dart';
import 'package:project1/app/community/community_create_page.dart';
import 'package:project1/app/community/community_home_page.dart';
import 'package:project1/app/community/community_members_page.dart';
import 'package:project1/app/community/community_invite_page.dart';
import 'package:project1/app/alram/alram_page.dart';
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
import 'package:project1/app/weathergogo/weathergogo_page.dart';
import 'package:project1/app/challenge/challenge_main_page.dart';
import 'package:project1/app/attendance/attendance_calendar_page.dart';
import 'package:project1/app/achievement/achievement_page.dart';
import 'package:project1/app/feel/feel_ranking_page.dart';
import 'package:project1/root/cntr/root_cntr.dart';
import 'package:project1/root/main_view1.dart';
import 'package:project1/root/root_page.dart';

abstract class AppPages {
  AppPages._();
  // ignore: constant_identifier_names
  static const INITIAL = '/AuthPage';

  // fcm 또는 알람 리스트에서 알람을 클릭했을 때 해당 알람에 대한 상세 페이지로 이동하는 라우트
  static goRoute(String alramCd, String custId, String? boardId,
      {String? reportId}) {
    // alramCd에 따라 이동할 페이지를 분기
    // 08: 게시판 좋아요
    // 09: 게시판 댓글
    // 20: 날씨 이벤트(비/눈/노을 등) → 영상 공유 유도, 카메라 진입

    // 날씨 이벤트 푸시는 boardId가 없으므로 가장 먼저 처리한다.
    if (alramCd == '20') {
      openCameraGlobal();
      return;
    }

    // 기상 특보(30) 푸시 클릭 시 상세 페이지로 이동. reportId가 없으면 boardId를 fallback으로 사용.
    if (alramCd == '30') {
      Get.toNamed('/SpecialWeatherDetailPage',
          arguments: {'reportId': reportId ?? boardId ?? ''});
      return;
    }

    if (boardId == null || boardId == '' || boardId == 'null') {
      Get.toNamed('/OtherInfoPage/$custId');
      return;
    }
    switch (alramCd) {
      case '08':
      case '09':
        RootCntr.to.changeRootPageIndex(3);
        Get.toNamed('/BbsViewPage',
            arguments: {'boardId': boardId.toString(), 'tag': 'list'});
        break;
      default:
        Get.toNamed('/VideoMyinfoListPage', arguments: {
          'datatype': 'ONE',
          'custId': custId,
          'boardId': boardId.toString()
        });
        break;
    }
  }

  // 어디서든(푸시 핸들러 등) 카메라를 연다 — context 불필요(Get.to).
  // root_page.goRecord와 동일하게 CameraBloc을 사전 초기화한다.
  static void openCameraGlobal() {
    // 일반 카메라 진입: 모임 대상 초기화(모임 외 업로드가 모임에 섞이지 않도록).
    RootCntr.to.pendingCommunityId = null;
    Get.to(() => const CameraAwesomePage());
  }

  static final routes = [
    GetPage(
      name: '/AuthPage',
      page: () => const AuthPage(),
      transition: Transition.native,
    ),
    GetPage(
      name: '/SpotWeatherPage',
      page: () => const SpotWeatherPage(),
      transition: Transition.cupertino,
    ),
    GetPage(
      name: '/JoinPage',
      page: () => const JoinPage(),
      transition: Transition.native,
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
      fullscreenDialog: false,
      opaque: true,
      transition: Transition.native,
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
      transition: Transition.rightToLeftWithFade,
    ),
    // GetPage(
    //   name: '/SevendayDetailPage/:initialIndex',
    //   page: () => const SevendayDetailPage(),
    //   // transition: Transition.downToUp,
    // ),
    // GetPage(
    //   name: '/WeatherWebView',
    //   page: () => const WeatherWebView(
    //     isBackBtn: true,
    //   ),
    // ),

    GetPage(
      name: '/FavoriteAreaPage',
      page: () {
        final args = Get.arguments;
        final returnResult = args is Map && args['returnResult'] == true;
        return FavoriteAreaPage(returnResult: returnResult);
      },
    ),

    GetPage(
      name: '/AlramSettingPage',
      page: () => const AlramSettingPage(),
      // transition: Transition.downToUp,
    ),
    GetPage(
      name: '/WeatherNotiSettingPage',
      page: () => const WeatherNotiSettingPage(),
    ),
    // 공유앨범 테마·위젯 미리보기(디버그 검수용)
    GetPage(
      name: '/SaPreviewPage',
      page: () => const SaPreviewPage(),
    ),
    // 공유앨범 홈(1a 스택 피드)
    GetPage(
      name: '/AlbumListPage',
      page: () => const AlbumListPage(),
      // transition: Transition.rightToLeftWithFade,
    ),
    // 앨범 셸(2a 타임라인 + 하단 탭바) — 앨범 진입 기본 화면
    GetPage(
      name: '/AlbumShellPage',
      page: () => const AlbumShellPage(),
    ),
    // 공유앨범 상세(구 1d 갤러리 뷰) — 셸로 대체됐으나 롤백/직접 진입용으로 유지
    GetPage(
      name: '/AlbumDetailPage',
      page: () => const AlbumDetailPage(),
      // transition: Transition.rightToLeftWithFade,
    ),
    // 공유앨범 몰입 뷰(1e 틱톡식 풀스크린)
    GetPage(
      name: '/AlbumImmersivePage',
      page: () => const AlbumImmersivePage(),
      // transition: Transition.fadeIn,
    ),
    // 공유앨범 대문 편집(1f)
    GetPage(
      name: '/AlbumCoverEditorPage',
      page: () => const AlbumCoverEditorPage(),
      transition: Transition.downToUp,
    ),
    // 공유앨범 멤버 초대(1h)
    GetPage(
      name: '/AlbumInvitePage',
      page: () => const AlbumInvitePage(),
      // transition: Transition.rightToLeftWithFade,
    ),
    // 공유앨범 탐색(공개 앨범 검색 + 코드로 참여 — 구 허브 기능 이관)
    GetPage(
      name: '/AlbumExplorePage',
      page: () => const AlbumExplorePage(),
      // transition: Transition.rightToLeftWithFade,
    ),
    // 새 앨범 만들기(다크 — 구 CommunityCreatePage 대체)
    GetPage(
      name: '/AlbumCreatePage',
      page: () => const AlbumCreatePage(),
      transition: Transition.downToUp,
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
      name: '/BlockListPage',
      page: () => const BlockListPage(),
      // transition: Transition.downToUp,
    ),
    GetPage(
      name: '/BbsListPage',
      page: () => BbsListPage(
        scrollController: ScrollController(),
      ),
      // transition: Transition.downToUp,
    ),

    GetPage(
      name: '/BbsViewPage',
      page: () => const BbsViewPage(),
      // binding: BbsViewBinding()
      // transition: Transition.downToUp,
    ),

    GetPage(
      name: '/BbsWritePage',
      page: () => const BbsWritePage(),
      binding: BbsWriteBinding(),
      // transition: Transition.downToUp,
    ),

    GetPage(
      name: '/BBsModifyPage/:boardId',
      page: () => const BbsModifyPage(),
      binding: BbsModifyBinding(),
      // transition: Transition.downToUp,
    ),

    GetPage(
      name: '/ShortListPage',
      page: () => const ShortListPage(),
      binding: ShortListBinding(),
    ),

    GetPage(
      name: '/ShortViewPage',
      page: () => const ShortViewPage(),
      binding: ShortViewBinding(),
    ),

    GetPage(
      name: '/ShortWritePage',
      page: () => const ShortWritePage(),
      binding: ShortWriteBinding(),
      // transition: Transition.downToUp,
    ),

    GetPage(
      name: '/ShortModifyPage/:boardId',
      page: () => const ShortModifyPage(),
      binding: ShortModifyBinding(),
      // transition: Transition.downToUp,
    ),
    GetPage(
      name: '/BbsMyListPage/:custId',
      page: () => const BbsMyListPage(),
      binding: BbsMyListinding(),
      // transition: Transition.downToUp,
    ),
    GetPage(
      name: '/BbsSearchListPage',
      page: () => const BbsSearchListPage(),
      binding: BbsSearchListinding(),
      // transition: Transition.downToUp,
    ),
    GetPage(
      name: '/ChallengeMainPage',
      page: () => const ChallengeMainPage(),
      // transition: Transition.rightToLeftWithFade,
      // transitionDuration: const Duration(milliseconds: 200),
    ),
    GetPage(
      name: '/AttendanceCalendarPage',
      page: () => const AttendanceCalendarPage(),
      // transition: Transition.rightToLeftWithFade,
    ),
    GetPage(
      name: '/AchievementPage',
      page: () => const AchievementPage(),
      // transition: Transition.rightToLeftWithFade,
      // transitionDuration: const Duration(milliseconds: 200),
    ),
    GetPage(
      name: '/FeelRankingPage',
      page: () => const FeelRankingPage(),
      // transition: Transition.rightToLeftWithFade,
      // transitionDuration: const Duration(milliseconds: 200),
    ),
    GetPage(
      name: '/SpecialWeatherListPage',
      page: () => const SpecialWeatherListPage(),
      // transition: Transition.rightToLeftWithFade,
    ),
    GetPage(
      name: '/SpecialWeatherDetailPage',
      page: () => const SpecialWeatherDetailPage(),
      // transition: Transition.rightToLeftWithFade,
    ),
    // ───────────────────────── 모임(스카이라운지) ─────────────────────────
    GetPage(
      name: '/CommunityHubPage',
      page: () => const CommunityHubPage(),
      // transition: Transition.rightToLeftWithFade,
    ),
    GetPage(
      name: '/CommunityCreatePage',
      page: () => const CommunityCreatePage(),
      transition: Transition.downToUp,
    ),
    GetPage(
      name: '/CommunityHomePage',
      page: () => const CommunityHomePage(),
      // transition: Transition.rightToLeftWithFade,
    ),
    GetPage(
      name: '/CommunityMembersPage',
      page: () => const CommunityMembersPage(),
      // transition: Transition.rightToLeftWithFade,
    ),
    GetPage(
      name: '/CommunityInvitePage',
      page: () => const CommunityInvitePage(),
      // transition: Transition.rightToLeftWithFade,
    ),
    GetPage(
      name: '/AlramPage',
      page: () => const AlramPage(),
      // transition: Transition.rightToLeftWithFade,
    ),
  ];
}
