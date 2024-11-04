// ignore_for_file: public_member_api_docs, sort_constructors_first
// import 'package:chips_choice/chips_choice.dart';

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:get/get.dart';
import 'package:giffy_dialog/giffy_dialog.dart';

import 'package:project1/admob/ad_manager.dart';
import 'package:project1/admob/banner_ad_widget.dart';
import 'package:project1/app/auth/cntr/auth_cntr.dart';
import 'package:project1/app/weathergogo/cntr/weather_gogo_cntr.dart';
import 'package:project1/app/weathergogo/services/weather_data_processor.dart';
import 'package:project1/repo/common/code_data.dart';
import 'package:project1/repo/common/comm_repo.dart';
import 'package:project1/repo/common/res_data.dart';
import 'package:project1/repo/secure_storge.dart';
import 'package:project1/root/cntr/root_cntr.dart';
import 'package:project1/utils/StringUtils.dart';
import 'package:project1/utils/log_utils.dart';
import 'package:project1/utils/utils.dart';
import 'package:project1/widget/custom_tabbarview.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({Key? key}) : super(key: key);

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> with SecureStorage {
  final ValueNotifier<List<DataMap>> urls = ValueNotifier<List<DataMap>>([]);
  // 최근 검색어
  final ValueNotifier<List<String>> lastSearchWordList = ValueNotifier<List<String>>([]);

  // 추천 검색어
  final ValueNotifier<List<DataMap>> recoWordlist = ValueNotifier<List<DataMap>>([]);

  // 급등 검색어
  final ValueNotifier<List<DataMap>> suddenlylist = ValueNotifier<List<DataMap>>([]);
  // 지하철역
  final ValueNotifier<List<DataMap>> subwaylist = ValueNotifier<List<DataMap>>([]);
  // 학교
  final ValueNotifier<List<DataMap>> schoollist = ValueNotifier<List<DataMap>>([]);
  // 캡핑장
  final ValueNotifier<List<DataMap>> campinglist = ValueNotifier<List<DataMap>>([]);
  // 골프장
  final ValueNotifier<List<DataMap>> golflist = ValueNotifier<List<DataMap>>([]);
  // Tag
  final ValueNotifier<List<DataMap>> taglist = ValueNotifier<List<DataMap>>([]);

  TextEditingController searchController = TextEditingController();
  FocusNode textFocus = FocusNode();

  ValueNotifier<bool> isAdLoading = ValueNotifier<bool>(false);

  @override
  void initState() {
    super.initState();
    getLastSeachWord();
    textFocus.addListener(() {
      if (textFocus.hasFocus) {
        RootCntr.to.bottomBarStreamController.sink.add(false);
      } else {
        RootCntr.to.bottomBarStreamController.sink.add(true);
      }
    });
    _loadAd();
    // 추천 검색어
    searchWord('RECOM', recoWordlist);
    // 급등 검색어
    searchWord('SURS', suddenlylist);
    // 지하철 검색어
    searchWord('SUBW', subwaylist);
    // 학교 검색어
    searchWord('SCHL', schoollist);
    // 캠핑장 검색어
    searchWord('CAMP', campinglist);
    // 골프 검색어
    searchWord('GOLF', golflist);
    //Tag 검색어
    searchWord('RECOM', taglist);
  }

  Future<void> _loadAd() async {
    await AdManager().loadBannerAd('SeachPage');
    isAdLoading.value = true;
  }

  void goSearchPage(String searchWord) async {
    // Utils.alert("검색어: $searchWord");
    if (searchWord.isEmpty) {
      Utils.alert("검색어를 입력해주세요");
      return;
    }
    searchController.text = '';
    // 스토리지에 검색어 저장
    lastSearchWordList.value = await saveSearchWord(searchWord);
    Get.toNamed('/MainView1/${AuthCntr.to.resLoginData.value.custId.toString()}/0/${Uri.encodeComponent(searchWord)}');
  }

  // 최근 검색어
  getLastSeachWord() async {
    lastSearchWordList.value = await getSearchWord();
  }

  List<DataMap> tags = [];

  late String value;

  // 추천 검색어 조회
  Future<void> searchWord(String grpCd, ValueNotifier<List<DataMap>> valueListenable) async {
    try {
      CommRepo repo = CommRepo();
      CodeReq reqData = CodeReq();
      reqData.pageNum = 0;
      reqData.pageSize = 100;
      reqData.grpCd = grpCd;
      reqData.code = '';
      reqData.useYn = 'Y';
      ResData res = await repo.searchCode(reqData);

      if (res.code != '00') {
        Utils.alert(res.msg.toString());
        return;
      }
      List<CodeRes> list = (res.data as List).map<CodeRes>((e) => CodeRes.fromMap(e)).toList();
      List<DataMap> dataList = list.map<DataMap>((e) => DataMap(e.codeNm!, e.etc1 ?? '', e.etc2 ?? '')).toList();

      // List<CodeRes> 를 List<DataMap> 으로 파싱해주세요.

      // List<DataMap> dataList = list.map<DataMap>((e) => DataMap(e.codeNm!, e.lat!, e.lon!)).toList();

      valueListenable.value = dataList;

      lo.g('searchRecomWord : ${res.data}');
    } catch (e) {
      lo.g('error searchRecomWord : $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        forceMaterialTransparency: true,
        automaticallyImplyLeading: false,
        //titleSpacing: 0,
        title: Container(
          margin: const EdgeInsets.only(left: 0, right: 0),
          padding: const EdgeInsets.only(top: 5),
          // color: Colors.red,
          //  height: 54,
          child: TextFormField(
            controller: searchController,
            focusNode: textFocus,
            maxLines: 1,
            style: const TextStyle(decorationThickness: 0), // 한글밑줄제거
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 0),
              filled: true,
              fillColor: Colors.grey[100],
              suffixIcon: const Icon(Icons.search, color: Colors.grey),
              enabledBorder: OutlineInputBorder(
                // width: 0.0 produces a thin "hairline" border
                borderSide: const BorderSide(color: Colors.grey, width: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              border: OutlineInputBorder(
                // width: 0.0 produces a thin "hairline" border
                //  borderSide: const BorderSide(color: Colors.grey, width: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: Colors.grey, width: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              label: const Text("검색어를 입력해주세요"),
              labelStyle: const TextStyle(color: Colors.black38),
            ),
            onFieldSubmitted: (searchWord) {
              // Perform search searchWord
              // Get.toNamed('/MainView1/$searchWord');
              goSearchPage(searchWord);
            },
          ),
        ),
        centerTitle: false,
        //  backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () => Get.back(),
            icon: const Icon(Icons.close),
          ),
        ],
      ),
      body: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: const BoxDecoration(
          color: Colors.white,
        ),
        child: SingleChildScrollView(
          physics: const CustomTabBarViewScrollPhysics(),
          child: Column(
            children: [
              buildLastSearch(),
              const Gap(20),
              // buildLastTop10(),
              buildCommon('급등 검색어', 2, suddenlylist),
              const Gap(20),
              buildCommon('추천 검색어', 1, recoWordlist),
              const Gap(20),

              // const Gap(20),
              ValueListenableBuilder<bool>(
                  valueListenable: isAdLoading,
                  builder: (context, value, child) {
                    if (!value) return const SizedBox.shrink();
                    return const Center(child: BannerAdWidget(screenName: 'SeachPage'));
                  }),
              const Gap(20),
              buildCommon('지하철 검색어', 3, subwaylist),
              const Gap(20),
              buildCommon('학교 검색어', 4, schoollist),
              const Gap(20),
              buildCommon('캠핑장 검색어', 8, campinglist),
              const Gap(20),
              buildCommon('골프 검색어', 6, golflist),
              const Gap(20),
              // buildCommon('추천 검색어', recoWordlist),
              // const Gap(20),
              // buildWeatherInfoImg(),
              // buildTodayWeather(),
              // buildAddmob(),
              // ValueListenableBuilder 만들어서 이미지 가져오기
              // ValueListenableBuilder<String>(
              //   valueListenable: bgImaggeUrl,
              //   builder: (context, value, child) {
              //     return Container(
              //       width: double.infinity,
              //       decoration: BoxDecoration(
              //         image: DecorationImage(
              //           image: NetworkImage(value),
              //           fit: BoxFit.cover,
              //         ),
              //       ),
              //     );
              //   },
              // ),
              //   Image.asset('assets/images/girl-6356393_640.jpg', fit: BoxFit.cover, width: double.infinity, height: 700),
              //   myFeeds()
            ],
          ),
        ),
      ),
    );
  }

  // 날ㅆ씨 정보
  Widget buildTodayWeather() {
    // final controller = Get.find<WeatherGogoCntr>();
    return Obx(() => Container(
          height: 80,
          margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 0),
          padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.6),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Container(
              //   padding: const EdgeInsets.all(7),
              //   margin: const EdgeInsets.all(0),
              //   decoration: BoxDecoration(color: Colors.red[300], borderRadius: const BorderRadius.all(Radius.circular(40))),
              //   child: Text(
              //     '${Get.find<WeatherGogoCntr>().currentWeather.value.temp ?? 0}°C',
              //     style: const TextStyle(color: Colors.white, fontSize: 13),
              //   ),
              // ),
              // Lottie.asset(
              //   WeatherDataProcessor.instance.getWeatherGogoImage(Get.find<WeatherGogoCntr>().currentWeather.value.sky.toString(),
              //       Get.find<WeatherGogoCntr>().currentWeather.value.rain.toString()),
              //   height: 128.0,
              //   width: 90.0,
              // ),
              SizedBox(
                width: 90,
                height: 128,
                child: WeatherDataProcessor.instance.getWeatherGogoImage(Get.find<WeatherGogoCntr>().currentWeather.value.sky.toString(),
                    Get.find<WeatherGogoCntr>().currentWeather.value.rain.toString()),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${Get.find<WeatherGogoCntr>().currentWeather.value.temp ?? 0}°',
                    style: const TextStyle(fontSize: 20, color: Colors.white),
                  ),
                  Flexible(
                    child: Text(
                      Get.find<WeatherGogoCntr>().currentWeather.value.description ?? '',
                      style: const TextStyle(fontSize: 13, color: Colors.white),
                    ),
                  )
                ],
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${Get.find<WeatherGogoCntr>().sevenDayWeather[0].morning.minTemp ?? 0}°/${Get.find<WeatherGogoCntr>().sevenDayWeather[0].afternoon.maxTemp ?? 0}°',
                    style: const TextStyle(fontSize: 13, color: Colors.white),
                  ),
                  // Text(
                  //   '8°C/9°C',
                  //   style: TextStyle(fontSize: 13, color: Colors.white),
                  // ),
                  Flexible(
                    child: Text(
                      Get.find<WeatherGogoCntr>().currentLocation.value.name ?? '',
                      style: const TextStyle(fontSize: 13, color: Colors.white),
                    ),
                  ),
                  Row(
                    children: [
                      const Icon(Icons.alarm, color: Colors.white, size: 13),
                      Text(
                        '${Get.find<WeatherGogoCntr>().lastUpdated.value?.toString().substring(11, 16)}',
                        style: const TextStyle(fontSize: 10, color: Colors.white),
                      ),
                    ],
                  )
                ],
              )
            ],
          ),
        ));
  }

  Widget buildWeatherInfoImg() {
    return Container(
      height: 80,
      width: 200,
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 0),
      decoration: BoxDecoration(
        color: Colors.red[300],
        borderRadius: BorderRadius.circular(15),
      ),
      child: Stack(
        children: [
          //   Image.asset('assets/images/1.jpg', fit: BoxFit.cover, width: double.infinity, height: double.infinity),
          Align(
            alignment: Alignment.bottomRight,
            child: Container(
              margin: const EdgeInsets.only(right: 10),
              child: const Text(
                "비오는 날",
                style: TextStyle(color: Colors.white),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget buildCommon(String title, int colorNo, valueListenable) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const Spacer(),
          ],
        ),
        Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            const SizedBox(
              height: 10,
            ),
            ValueListenableBuilder<List<DataMap>>(
                valueListenable: valueListenable,
                builder: (context, value, child) {
                  return Wrap(
                    spacing: 6.0,
                    runSpacing: 6.0,
                    direction: Axis.horizontal,
                    crossAxisAlignment: WrapCrossAlignment.start,
                    verticalDirection: VerticalDirection.down,
                    runAlignment: WrapAlignment.start,
                    alignment: WrapAlignment.start,
                    children: value.map((e) {
                      return buildChip3(e, 0);
                    }).toList(),
                  );
                }),
            // Using [extraOnToggle]
            const SizedBox(
              height: 20,
            ),
          ],
        ),
      ],
    );
  }

  // 최근 검색어
  Widget buildLastSearch() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("최근 검색어", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            // Text("지우기", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w300))
            SizedBox(
              height: 33,
              width: 100,
              child: TextButton(
                style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(50, 30),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    alignment: Alignment.centerRight),
                onPressed: () {
                  lastSearchWordList.value = [];
                  removeAllSearchWord();
                },
                child: const Text(
                  '지우기 ',
                  style: TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
        const Gap(10),
        ValueListenableBuilder<List<String>>(
          valueListenable: lastSearchWordList,
          builder: (context, value, child) {
            return Wrap(
              spacing: 6.0,
              runSpacing: 6.0,
              direction: Axis.horizontal,
              crossAxisAlignment: WrapCrossAlignment.start,
              verticalDirection: VerticalDirection.down,
              runAlignment: WrapAlignment.start,
              alignment: WrapAlignment.start,
              children: value.map((e) => buildChip(e)).toList(),
            );
          },
        )
      ],
    );
  }

  // 검색어 순위
  Widget buildLastTop10() {
    return Column(
      children: [
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("급등 검색어", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        const Gap(10),
        Row(
          children: [
            Wrap(
              spacing: 6.0,
              runSpacing: 6.0,
              children: <Widget>[
                buildChip2(DataMap('홍제역', '0', '0')),
                buildChip2(DataMap('광화문', '0', '0')),
                buildChip2(DataMap('개화', '0', '0')),
              ],
            ),
          ],
        )
      ],
    );
  }

  // 최근 검색어 칩
  Widget buildChip(String label) {
    return InkWell(
        onTap: () => goSearchPage(label),
        child: Chip(
          backgroundColor: Colors.grey[200],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: Colors.transparent),
          ),
          label: Text(label),
          onDeleted: () async {
            // Perform delete
            // lastSearchWordList.value = await removeSearchWord(label);
          },
        ));
  }

  // 금등검색어 칩
  Widget buildChip2(DataMap data) {
    return InkWell(
        onTap: () {
          if (!StringUtils.isEmpty(data.lat)) {
            Get.toNamed('/MapPage', arguments: {'lat': double.parse(data.lat), 'lon': double.parse(data.lon)});
          } else {
            Get.toNamed('/MainView1/${AuthCntr.to.resLoginData.value.custId.toString()}/0/${Uri.encodeComponent(data.label)}');
          }
        },
        child: Chip(
          backgroundColor: Colors.grey[200],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: Colors.transparent),
          ),
          label: Text(data.label),
          // onDeleted: () async {
          // },
        ));
  }

  Widget buildChip3(DataMap data, int colorNo) {
    final Map<int, Map<String, Color>> colorMap = {
      1: {'textColor': const Color(0xFF1A61CD), 'backgroundColor': const Color(0xFFE5E5E5)},
      2: {'textColor': const Color(0xFF2AA100), 'backgroundColor': const Color(0xFFEFFAEA)},
      3: {'textColor': const Color(0xFF4F4745), 'backgroundColor': const Color(0xFFE0D8D4)},
      4: {'textColor': const Color(0xFFE23E28), 'backgroundColor': const Color(0xFFFFE8E4)},
      5: {'textColor': const Color(0xFFffffff), 'backgroundColor': const Color(0xFFFF9900)},
      6: {'textColor': const Color(0xFFFF9900), 'backgroundColor': const Color(0xFF4F4745)},
      7: {'textColor': const Color(0xFFffffff), 'backgroundColor': const Color(0xFF9E9693)},
      8: {'textColor': const Color(0xFF9E9693), 'backgroundColor': const Color(0xFFE0D8D4)},
    };

    return InkWell(
        onTap: () {
          if (!StringUtils.isEmpty(data.lat)) {
            Get.toNamed('/MapPage', arguments: {'lat': double.parse(data.lat), 'lon': double.parse(data.lon)});
          } else {
            Get.toNamed('/MainView1/${AuthCntr.to.resLoginData.value.custId.toString()}/0/${Uri.encodeComponent(data.label)}');
          }
        },
        child: Chip(
          backgroundColor:
              colorMap[colorMap ?? 8]?['textColor'] ?? const Color.fromARGB(255, 251, 251, 252), //  const Color.fromARGB(255, 81, 94, 165),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: Colors.grey),
          ),

          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 4),
          label: Text(
            data.label,
            style: const TextStyle(color: Colors.black54, fontSize: 13, fontWeight: FontWeight.bold),
          ),
          // onDeleted: () async {
          // },
        ));
  }
}

class DataMap {
  String label;
  String lat;
  String lon;
  DataMap(
    this.label,
    this.lat,
    this.lon,
  );

  DataMap copyWith({
    String? label,
    String? lat,
    String? lon,
  }) {
    return DataMap(
      label ?? this.label,
      lat ?? this.lat,
      lon ?? this.lon,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'label': label,
      'lat': lat,
      'lon': lon,
    };
  }

  factory DataMap.fromMap(Map<String, dynamic> map) {
    return DataMap(
      map['label'] as String,
      map['lat'] as String,
      map['lon'] as String,
    );
  }

  String toJson() => json.encode(toMap());

  factory DataMap.fromJson(String source) => DataMap.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() => 'DataMap(label: $label, lat: $lat, lon: $lon)';

  @override
  bool operator ==(covariant DataMap other) {
    if (identical(this, other)) return true;

    return other.label == label && other.lat == lat && other.lon == lon;
  }

  @override
  int get hashCode => label.hashCode ^ lat.hashCode ^ lon.hashCode;
}
