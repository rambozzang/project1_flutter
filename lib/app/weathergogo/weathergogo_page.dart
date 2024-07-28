import 'dart:async';

import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';
import 'package:project1/admob/ad_manager.dart';
import 'package:project1/admob/banner_ad_widget.dart';
import 'package:project1/app/auth/cntr/auth_cntr.dart';
import 'package:project1/app/weather/models/geocode.dart';
import 'package:project1/app/weather/theme/textStyle.dart';
import 'package:project1/app/weathergogo/appbar_page.dart';
import 'package:project1/app/weathergogo/detail_main_page.dart';
import 'package:project1/app/weathergogo/header_main_page.dart';
import 'package:project1/app/weathergogo/seven_day_page.dart';
import 'package:project1/app/weathergogo/twenty4_page.dart';
import 'package:project1/app/weathergogo/weathergogo_kakao_searchbar.dart';
import 'package:project1/app/weathergogo/cntr/weather_gogo_cntr.dart';
import 'package:project1/app/webview/weather_webview.dart';
import 'package:project1/repo/common/res_data.dart';
import 'package:project1/repo/common/res_stream.dart';
import 'package:project1/repo/cust/cust_repo.dart';
import 'package:project1/repo/cust/data/cust_tag_res_data.dart';
import 'package:project1/root/cntr/root_cntr.dart';
import 'package:project1/utils/utils.dart';
import 'package:project1/widget/custom_indicator_offstage.dart';

class WeathgergogoPage extends StatefulWidget {
  const WeathgergogoPage({Key? key}) : super(key: key);

  @override
  State<WeathgergogoPage> createState() => _WeathgergogoPageState();
}

class _WeathgergogoPageState extends State<WeathgergogoPage>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin<WeathgergogoPage> {
  @override
  bool get wantKeepAlive => true;

  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
  final RxList<CustagResData> areaList = <CustagResData>[].obs;

  // 섹션 리스트 정의
  final List<Widget Function()> sections = [];

  @override
  void initState() {
    super.initState();
    _loadAd();
    getLocalTag();
    _initializeSections();
  }

  void _initializeSections() {
    sections.addAll([
      () => buildFavLocal(),
      () => _buildWeatherInfoHeader(),
      () => const HeaderMainPage(),
      () => const DetailMainPage(),
      () => const Twenty4Page(),
      () => const SevenDayPage(),
      () => _buildWeatherWebView(),
      () => _buildAdWidget(),
      () => const SizedBox(height: 50),
    ]);
  }

  Future<void> _loadAd() async {
    await AdManager().loadBannerAd('WeathPage');
    if (mounted) setState(() {});
  }

  Future<void> getLocalTag() async {
    try {
      CustRepo repo = CustRepo();
      ResData res = await repo.getTagList(AuthCntr.to.resLoginData.value.custId.toString(), 'LOCAL');
      if (res.code != '00') {
        Utils.alert(res.msg.toString());
        return;
      }
      areaList.value = ((res.data) as List).map((data) => CustagResData.fromMap(data)).toList();
    } catch (e) {
      Utils.alert(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      key: scaffoldKey,
      backgroundColor: const Color(0xFF262B49),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        forceMaterialTransparency: true,
        backgroundColor: Colors.transparent,
        title: const AppbarPage(),
      ),
      body: Stack(
        children: <Widget>[
          _buildLazyLoadingContent(),
          const WeathergogoKakaoSearchPage(),
          _buildLoadingIndicator(),
        ],
      ),
    );
  }

  Widget _buildLazyLoadingContent() {
    return ListView.builder(
      controller: RootCntr.to.hideButtonController5,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 0.0, vertical: 20.0).copyWith(
        top: kToolbarHeight + 3,
      ),
      itemCount: sections.length,
      itemBuilder: (context, index) {
        return sections[index]();
      },
    );
  }

  Widget _buildWeatherInfoHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('날씨 정보', style: semiboldText.copyWith(fontSize: 24.0)),
              const Gap(10),
              TextButton(
                style: TextButton.styleFrom(padding: const EdgeInsets.all(0.0)),
                onPressed: () => Get.toNamed('/MapPage'),
                child: Row(
                  children: [
                    Text('지도 보기 ', style: semiboldText.copyWith(fontSize: 9.0)),
                    const Icon(Icons.arrow_forward_ios, size: 10.0, color: Colors.amber),
                  ],
                ),
              ),
              const Gap(15),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.bolt, color: Colors.amber, size: 24.0),
          onPressed: () => Get.find<WeatherGogoCntr>().getInitWeatherData(true),
        ),
      ],
    );
  }

  Widget _buildAdWidget() {
    return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 20), child: SizedBox(height: 70, child: BannerAdWidget(screenName: 'WeathPage')));
  }

  Widget _buildWeatherWebView() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14.0),
      height: 608.0,
      child: const WeatherWebView(isBackBtn: false),
    );
  }

  Widget _buildLoadingIndicator() {
    return GetBuilder<WeatherGogoCntr>(
      builder: (cntr) {
        return CustomIndicatorOffstage(
          isLoading: !cntr.isLoading.value,
          color: const Color(0xFFEA3799),
          opacity: 0.5,
        );
      },
    );
  }

  // 관심지역 리스트
  Widget buildFavLocal() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      width: double.infinity,
      child: Obx(() {
        if (areaList.isEmpty) {
          return Container(
            padding: const EdgeInsets.symmetric(vertical: 3),
            alignment: Alignment.center,
            child: Row(
              children: [
                InkWell(
                    onTap: () async => await Get.toNamed('/FavoriteAreaPage')!.then((value) => getLocalTag()),
                    child: const Text('관심지역', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.white))),
                const Gap(3),
                const Icon(Icons.arrow_circle_right_outlined, color: Colors.white, size: 16),
                const Gap(6),
                Text(
                  '등록된 관심지역이 없습니다.',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade50,
                  ),
                ),
              ],
            ),
          );
        }
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const AlwaysScrollableScrollPhysics(),
          child: Row(children: [
            InkWell(
                onTap: () async => await Get.toNamed('/FavoriteAreaPage')!.then((value) => getLocalTag()),
                child: const Text('관심지역', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.white))),
            const Gap(3),
            InkWell(
                onTap: () async => await Get.toNamed('/FavoriteAreaPage')!.then((value) => getLocalTag()),
                child: const Icon(Icons.arrow_circle_right_outlined, color: Colors.white, size: 16)),
            const Gap(5),
            ...areaList.map((e) => buildLocalChip(e)).toList(),
          ]),
        );
      }),
    );
  }

  // 지역
  Widget buildLocalChip(CustagResData data) {
    return Container(
        height: 30,
        padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 0.0),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              late GeocodeData geocodeData = GeocodeData(
                name: data.id!.tagNm.toString(),
                latLng: LatLng(double.parse(data.lat.toString()), double.parse(data.lon.toString())),
              );
              Get.find<WeatherGogoCntr>().searchWeatherKakao(geocodeData);
            },
            child: Chip(
              elevation: 4,
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
              backgroundColor: const Color.fromARGB(255, 122, 110, 199), // Color.fromARGB(255, 76, 70, 124),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: const BorderSide(color: Color.fromARGB(0, 166, 155, 155)),
              ),
              label: Text(
                data.id!.tagNm.toString(),
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600, height: 1.0),
              ),
              visualDensity: const VisualDensity(horizontal: 0, vertical: -4),
              labelPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
            ),
          ),
        ));
  }
}
