import 'package:cached_network_image/cached_network_image.dart';
import 'package:chips_choice/chips_choice.dart';
import 'package:dio/dio.dart';

import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:get/get.dart';
import 'package:project1/app/auth/cntr/auth_cntr.dart';
import 'package:project1/repo/secure_storge.dart';
import 'package:project1/repo/unsplash/get_image_bg_use_case.dart';
import 'package:project1/app/weather/provider/weather_cntr.dart';
import 'package:project1/root/cntr/root_cntr.dart';
import 'package:project1/utils/log_utils.dart';
import 'package:project1/utils/utils.dart';
import 'package:dio/src/response.dart' as r;
import 'package:project1/widget/ads_page.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({Key? key}) : super(key: key);

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> with SecureStorage {
  final ValueNotifier<List<String>> urls = ValueNotifier<List<String>>([]);
  // 최근 검색어
  final ValueNotifier<List<String>> lastSerchValue = ValueNotifier<List<String>>([]);

  // upslash api 로 날씨 관련 이미지 가져오기
  final ValueNotifier<String> bgImaggeUrl = ValueNotifier<String>('');

  TextEditingController searchController = TextEditingController();
  FocusNode textFocus = FocusNode();
  int _currentIndex = 0;
  bool _keyboardVisible = false;

  @override
  void initState() {
    super.initState();
    getUrls();
    textFocus.addListener(() {
      if (textFocus.hasFocus) {
        RootCntr.to.bottomBarStreamController.sink.add(false);
      } else {
        RootCntr.to.bottomBarStreamController.sink.add(true);
      }
    });
    // 배경이미지 가져오기
    getBgImage();
  }

  void goSearchPage(String searchWord) async {
    // Utils.alert("검색어: $searchWord");
    if (searchWord.isEmpty) {
      Utils.alert("검색어를 입력해주세요");
      return;
    }
    searchController.text = '';
    // 스토리지에 검색어 저장
    lastSerchValue.value = await saveSearchWord(searchWord);
    Get.toNamed('/MainView1/${AuthCntr.to.resLoginData.value.custId.toString()}/0/${Uri.encodeComponent(searchWord)}');
  }

  getUrls() async {
    lastSerchValue.value = await getSearchWord() as List<String>;
  }

  List<String> tags = [];
  List<String> options = [
    '개화시기',
    '하늘',
    '비',
    '먹구름',
    '눈',
    '강남',
    '여의도',
    '광화문',
    '판교',
    '꽃',
    '호수',
  ];
  late String value;

  // Random User 생성 API
  Future<List<C2Choice<String>>> getChoices() async {
    String url = "https://randomuser.me/api/?inc=gender,name,nat,picture,email&results=25";
    r.Response res = await Dio().get(url);
    return C2Choice.listFrom<String, dynamic>(
      source: res.data['results'],
      value: (index, item) => item['email'],
      label: (index, item) => item['name']['first'] + ' ' + item['name']['last'],
      meta: (index, item) => item,
    )..insert(0, const C2Choice<String>(value: 'all', label: 'All'));
  }

  // Random upslash API 이미지 가져오기
  Future<void> getBgImage() async {
    try {
      lo.g('getBgImage Start');

      GetImageBgUseCase repo = GetImageBgUseCase();
      String url = await repo.call(Get.find<WeatherCntr>().currentWeather.value!.weather![0].description!.toString());

      lo.g('getBgImage : $url');

      if (url.isNotEmpty) {
        bgImaggeUrl.value = url;
      }
    } catch (e) {
      lo.g('error getBgImage : $e');
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
          // image: DecorationImage(
          //   image: AssetImage('assets/images/girl-6356393_640.jpg'),
          //   fit: BoxFit.cover,
          // ),
        ),
        child: ListView(
          //   controller: RootCntr.to.hideButtonController4,
          children: [
            buildLastSearch(),
            const Gap(20),
            buildLastTop10(),
            const Gap(20),
            buildRecom(),
            const Gap(20),
            buildSchool(),
            const Gap(20),
            buildSubway(), const Gap(20),
            buildGolf(), const Gap(20),
            buildMountine(), const Gap(20),
            buildCamping(), const Gap(20),
            buildMarket(), const Gap(20),
            buildConcert(), const Gap(20),

            // ElevatedButton(
            //   onPressed: () async {
            //     var aa = await getSearchWord();
            //     Lo.g(aa);
            //   },
            //   child: const Text('설정'),
            // ),
            // SizedBox(
            //   height: 40,
            //   child: TextButton(
            //       onPressed: () => Get.toNamed('/MapPage'),
            //       child: const Text(
            //         '지도에서 찾기 ',
            //         style: TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.bold),
            //       )),
            // ),

            buildWeatherInfoImg(),
            buildTodayWeather(),

            buildAddmob(),
            // ValueListenableBuilder 만들어서 이미지 가져오기
            ValueListenableBuilder<String>(
              valueListenable: bgImaggeUrl,
              builder: (context, value, child) {
                return Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: NetworkImage(value),
                      fit: BoxFit.cover,
                    ),
                  ),
                );
              },
            ),
            //   Image.asset('assets/images/girl-6356393_640.jpg', fit: BoxFit.cover, width: double.infinity, height: 700),
            //   myFeeds()
          ],
        ),
      ),
    );
  }

  // 날ㅆ씨 정보
  Widget buildTodayWeather() {
    return Container(
      height: 80,
      margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 0),
      padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            margin: const EdgeInsets.all(0),
            decoration: BoxDecoration(color: Colors.red[300], borderRadius: const BorderRadius.all(Radius.circular(40))),
            child: Text(
              '${Get.find<WeatherCntr>().currentWeather.value?.main!.temp?.toStringAsFixed(1) ?? 0}°C',
              style: const TextStyle(color: Colors.white, fontSize: 13),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Image.asset('?assets/images/map/fog.png'),
              CachedNetworkImage(
                width: 80,
                height: 80,
                imageUrl:
                    'http://openweathermap.org/img/wn/${Get.find<WeatherCntr>().currentWeather.value?.weather![0].icon ?? '10n'}@2x.png',
                //   imageUrl:  'http://openweathermap.org/img/w/${value.weather![0].icon}.png',
                imageBuilder: (context, imageProvider) => Container(
                  padding: const EdgeInsets.all(0),
                  decoration: BoxDecoration(
                    image: DecorationImage(
                        image: imageProvider,
                        fit: BoxFit.cover,
                        colorFilter: const ColorFilter.mode(Colors.transparent, BlendMode.colorBurn)),
                  ),
                ),
                placeholder: (context, url) => const CircularProgressIndicator(strokeWidth: 1, color: Colors.white),
                errorWidget: (context, url, error) => const Icon(Icons.error),
              ),
              // const Gap(5),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${Get.find<WeatherCntr>().currentWeather.value?.main!.temp?.toStringAsFixed(1) ?? 0}°',
                    style: const TextStyle(fontSize: 20, color: Colors.white),
                  ),
                  Text(
                    Get.find<WeatherCntr>().currentWeather.value!.weather![0].description!.toString(),
                    style: const TextStyle(fontSize: 13, color: Colors.white),
                  )
                ],
              )
            ],
          ),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${Get.find<WeatherCntr>().currentWeather.value?.main!.temp_min?.toStringAsFixed(1) ?? 0}° / ${Get.find<WeatherCntr>().currentWeather.value?.main!.temp_max?.toStringAsFixed(1) ?? 0}°',
                style: const TextStyle(fontSize: 13, color: Colors.white),
              ),
              // Text(
              //   '8°C/9°C',
              //   style: TextStyle(fontSize: 13, color: Colors.white),
              // ),
              Text(
                Get.find<WeatherCntr>().currentLocation.value!.name.toString(),
                style: TextStyle(fontSize: 13, color: Colors.white),
              ),
              Text(
                '${Get.find<WeatherCntr>().lastUpdated.value.toString().substring(0, 10).replaceAll('-', '/')} ${Get.find<WeatherCntr>().lastUpdated.value?.toString().substring(11, 16)}',
                style: const TextStyle(fontSize: 10, color: Colors.white),
              )
            ],
          )
        ],
      ),
    );
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
          Image.asset('assets/images/rain-4996916_640.jpg', fit: BoxFit.cover, width: double.infinity, height: double.infinity),
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

  // 추천 검색어
  Widget buildRecom() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("추천 검색어", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const Spacer(),
            SizedBox(
              height: 33,
              // width: 100,
              child: TextButton(
                style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(50, 30),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    alignment: Alignment.centerRight),
                onPressed: () => Get.toNamed('/MapPage'),
                child: const Row(
                  children: [
                    Icon(
                      Icons.map,
                      color: Colors.indigo,
                      size: 20,
                    ),
                    Gap(3),
                    Text(
                      '지도에서 보기',
                      style: TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            const SizedBox(
              height: 10,
            ),
            // https://github.com/davigmacode/flutter_chips_choice/blob/master/example/lib/main.dart
            ChipsChoice<String>.multiple(
              padding: const EdgeInsets.all(0),
              wrapped: true,
              value: tags,
              onChanged: (val) {
                //  Utils.alert(val[0].toString());
                String searchWord = val[0].toString();

                goSearchPage(searchWord);
                // setState(() => tags = val);
              },
              choiceCheckmark: true,
              //  choiceStyle: C2ChipStyle.outlined(),
              choiceStyle: C2ChipStyle.filled(
                checkmarkColor: Colors.white,
                selectedStyle: const C2ChipStyle(
                  borderRadius: BorderRadius.all(
                    Radius.circular(25),
                  ),
                ),
              ),
              choiceItems: C2Choice.listFrom<String, String>(
                source: options,
                value: (i, v) => v,
                label: (i, v) => v,
              ),
            ),
            // Using [extraOnToggle]
            const SizedBox(
              height: 20,
            ),
          ],
        ),
      ],
    );
  }

  // 골프장 검색어
  Widget buildGolf() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("골프장 검색어", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            const SizedBox(
              height: 10,
            ),
            // https://github.com/davigmacode/flutter_chips_choice/blob/master/example/lib/main.dart
            ChipsChoice<String>.multiple(
              padding: const EdgeInsets.all(0),
              wrapped: true,
              value: tags,
              onChanged: (val) {
                //  Utils.alert(val[0].toString());
                String searchWord = val[0].toString();

                goSearchPage(searchWord);
                // setState(() => tags = val);
              },
              choiceCheckmark: true,
              //  choiceStyle: C2ChipStyle.outlined(),
              choiceStyle: C2ChipStyle.filled(
                checkmarkColor: Colors.white,
                selectedStyle: const C2ChipStyle(
                  borderRadius: BorderRadius.all(
                    Radius.circular(25),
                  ),
                ),
              ),
              choiceItems: C2Choice.listFrom<String, String>(
                source: options,
                value: (i, v) => v,
                label: (i, v) => v,
              ),
            ),
            // Using [extraOnToggle]
            const SizedBox(
              height: 20,
            ),
          ],
        ),
      ],
    );
  }

  // 콘서트장 검색어
  Widget buildConcert() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("콘서트장 검색어", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            const SizedBox(
              height: 10,
            ),
            // https://github.com/davigmacode/flutter_chips_choice/blob/master/example/lib/main.dart
            ChipsChoice<String>.multiple(
              padding: const EdgeInsets.all(0),
              wrapped: true,
              value: tags,
              onChanged: (val) {
                //  Utils.alert(val[0].toString());
                String searchWord = val[0].toString();

                goSearchPage(searchWord);
                // setState(() => tags = val);
              },
              choiceCheckmark: true,
              //  choiceStyle: C2ChipStyle.outlined(),
              choiceStyle: C2ChipStyle.filled(
                checkmarkColor: Colors.white,
                selectedStyle: const C2ChipStyle(
                  borderRadius: BorderRadius.all(
                    Radius.circular(25),
                  ),
                ),
              ),
              choiceItems: C2Choice.listFrom<String, String>(
                source: options,
                value: (i, v) => v,
                label: (i, v) => v,
              ),
            ),
            // Using [extraOnToggle]
            const SizedBox(
              height: 20,
            ),
          ],
        ),
      ],
    );
  }

  // 시장 검색어
  Widget buildMarket() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("동네시장/유명5일장 검색어", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            const SizedBox(
              height: 10,
            ),
            // https://github.com/davigmacode/flutter_chips_choice/blob/master/example/lib/main.dart
            ChipsChoice<String>.multiple(
              padding: const EdgeInsets.all(0),
              wrapped: true,
              value: tags,
              onChanged: (val) {
                //  Utils.alert(val[0].toString());
                String searchWord = val[0].toString();

                goSearchPage(searchWord);
                // setState(() => tags = val);
              },
              choiceCheckmark: true,
              //  choiceStyle: C2ChipStyle.outlined(),
              choiceStyle: C2ChipStyle.filled(
                checkmarkColor: Colors.white,
                selectedStyle: const C2ChipStyle(
                  borderRadius: BorderRadius.all(
                    Radius.circular(25),
                  ),
                ),
              ),
              choiceItems: C2Choice.listFrom<String, String>(
                source: options,
                value: (i, v) => v,
                label: (i, v) => v,
              ),
            ),
            // Using [extraOnToggle]
            const SizedBox(
              height: 20,
            ),
          ],
        ),
      ],
    );
  }

  // 유명등산 검색어
  Widget buildMountine() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("등산/유명산 검색어", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            const SizedBox(
              height: 10,
            ),
            // https://github.com/davigmacode/flutter_chips_choice/blob/master/example/lib/main.dart
            ChipsChoice<String>.multiple(
              padding: const EdgeInsets.all(0),
              wrapped: true,
              value: tags,
              onChanged: (val) {
                //  Utils.alert(val[0].toString());
                String searchWord = val[0].toString();

                goSearchPage(searchWord);
                // setState(() => tags = val);
              },
              choiceCheckmark: true,
              //  choiceStyle: C2ChipStyle.outlined(),
              choiceStyle: C2ChipStyle.filled(
                checkmarkColor: Colors.white,
                selectedStyle: const C2ChipStyle(
                  borderRadius: BorderRadius.all(
                    Radius.circular(25),
                  ),
                ),
              ),
              choiceItems: C2Choice.listFrom<String, String>(
                source: options,
                value: (i, v) => v,
                label: (i, v) => v,
              ),
            ),
            // Using [extraOnToggle]
            const SizedBox(
              height: 20,
            ),
          ],
        ),
      ],
    );
  }

  // 캠핑장 검색어
  Widget buildCamping() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("캠핑장 검색어", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            const SizedBox(
              height: 10,
            ),
            // https://github.com/davigmacode/flutter_chips_choice/blob/master/example/lib/main.dart
            ChipsChoice<String>.multiple(
              padding: const EdgeInsets.all(0),
              wrapped: true,
              value: tags,
              onChanged: (val) {
                //  Utils.alert(val[0].toString());
                String searchWord = val[0].toString();

                goSearchPage(searchWord);
                // setState(() => tags = val);
              },
              choiceCheckmark: true,
              //  choiceStyle: C2ChipStyle.outlined(),
              choiceStyle: C2ChipStyle.filled(
                checkmarkColor: Colors.white,
                selectedStyle: const C2ChipStyle(
                  borderRadius: BorderRadius.all(
                    Radius.circular(25),
                  ),
                ),
              ),
              choiceItems: C2Choice.listFrom<String, String>(
                source: options,
                value: (i, v) => v,
                label: (i, v) => v,
              ),
            ),
            // Using [extraOnToggle]
            const SizedBox(
              height: 20,
            ),
          ],
        ),
      ],
    );
  }

  // 학교 검색어
  Widget buildSchool() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("학교 - 초/중/고/대학교", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            const SizedBox(
              height: 10,
            ),
            // https://github.com/davigmacode/flutter_chips_choice/blob/master/example/lib/main.dart
            ChipsChoice<String>.multiple(
              padding: const EdgeInsets.all(0),
              wrapped: true,
              value: tags,
              onChanged: (val) {
                //  Utils.alert(val[0].toString());
                String searchWord = val[0].toString();

                goSearchPage(searchWord);
                // setState(() => tags = val);
              },
              choiceCheckmark: true,
              //  choiceStyle: C2ChipStyle.outlined(),
              choiceStyle: C2ChipStyle.filled(
                checkmarkColor: Colors.white,
                selectedStyle: const C2ChipStyle(
                  borderRadius: BorderRadius.all(
                    Radius.circular(25),
                  ),
                ),
              ),
              choiceItems: C2Choice.listFrom<String, String>(
                source: options,
                value: (i, v) => v,
                label: (i, v) => v,
              ),
            ),
            // Using [extraOnToggle]
            const SizedBox(
              height: 20,
            ),
          ],
        ),
      ],
    );
  }

  // 지하철역 검색어
  Widget buildSubway() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("지하철역", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            const SizedBox(
              height: 10,
            ),
            // https://github.com/davigmacode/flutter_chips_choice/blob/master/example/lib/main.dart
            ChipsChoice<String>.multiple(
              padding: const EdgeInsets.all(0),
              wrapped: true,
              value: tags,
              onChanged: (val) {
                //  Utils.alert(val[0].toString());
                String searchWord = val[0].toString();

                goSearchPage(searchWord);
                // setState(() => tags = val);
              },
              choiceCheckmark: true,
              //  choiceStyle: C2ChipStyle.outlined(),
              choiceStyle: C2ChipStyle.filled(
                checkmarkColor: Colors.white,
                selectedStyle: const C2ChipStyle(
                  borderRadius: BorderRadius.all(
                    Radius.circular(25),
                  ),
                ),
              ),
              choiceItems: C2Choice.listFrom<String, String>(
                source: options,
                value: (i, v) => v,
                label: (i, v) => v,
              ),
            ),
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
                    lastSerchValue.value = [];
                    removeAllSearchWord();
                  },
                  child: const Text(
                    '지우기 ',
                    style: TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.bold),
                  )),
            ),
          ],
        ),
        const Gap(10),
        ValueListenableBuilder<List<String>>(
            valueListenable: lastSerchValue,
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
            })
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
            // Text("지우기", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w300))
            // SizedBox(
            //   height: 33,
            //   width: 100,
            //   child: TextButton(
            //       style: TextButton.styleFrom(
            //           padding: EdgeInsets.zero,
            //           minimumSize: Size(50, 30),
            //           tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            //           alignment: Alignment.centerRight),
            //       onPressed: () => Get.toNamed('/MapPage'),
            //       child: const Text(
            //         '지우기 ',
            //         style: TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.bold),
            //       )),
            // ),
          ],
        ),
        const Gap(10),
        Row(
          children: [
            Wrap(
              spacing: 6.0,
              runSpacing: 6.0,
              children: <Widget>[
                buildChip2('홍제역'),
                buildChip2('광화문'),
                buildChip2('개화'),
              ],
            ),
          ],
        )
      ],
    );
  }

  Widget myFeeds() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
          child: ValueListenableBuilder<List<String>>(
              valueListenable: urls,
              builder: (context, value, child) {
                return value.length > 0
                    ? GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3, //1 개의 행에 보여줄 item 개수
                          childAspectRatio: 3 / 5, //item 의 가로 1, 세로 1 의 비율
                          mainAxisSpacing: 6, //수평 Padding
                          crossAxisSpacing: 3, //수직 Padding
                        ),
                        itemCount: urls.value.length,
                        itemBuilder: (context, index) => Container(
                            decoration: BoxDecoration(
                              color: const Color.fromARGB(255, 67, 68, 135),
                              borderRadius: BorderRadius.circular(10.0),
                              border: Border.all(color: Colors.grey[300]!),
                              image: DecorationImage(
                                image: NetworkImage(value[index]),
                                fit: BoxFit.cover,
                              ),
                            ),
                            child: const Align(
                              alignment: Alignment.bottomRight,
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.play_arrow_outlined,
                                    color: Colors.white,
                                  ),
                                  Text(
                                    '12,000',
                                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            )),
                      )
                    : Utils.progressbar();
              }),
        ),
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
            lastSerchValue.value = await removeSearchWord(label);
          },
        ));
  }

  // 금등검색어 칩
  Widget buildChip2(String label) {
    return InkWell(
        onTap: () => Get.toNamed('/MainView1/${AuthCntr.to.resLoginData.value.custId.toString()}/0/${Uri.encodeComponent(label)}'),
        child: Chip(
          backgroundColor: Colors.grey[200],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: Colors.transparent),
          ),
          label: Text(label),
          // onDeleted: () async {
          // },
        ));
  }
}
