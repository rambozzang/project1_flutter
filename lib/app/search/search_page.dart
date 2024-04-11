import 'package:babstrap_settings_screen/babstrap_settings_screen.dart';
import 'package:chips_choice/chips_choice.dart';
import 'package:dio/dio.dart';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:gap/gap.dart';
import 'package:get/get.dart';
import 'package:get/get_connect/http/src/response/response.dart';
import 'package:project1/app/list/api_service.dart';
import 'package:project1/root/cntr/root_cntr.dart';
import 'package:project1/utils/utils.dart';
import 'package:dio/src/response.dart' as r;
import 'package:project1/widget/ads_page.dart';

class SearchPage extends StatefulWidget {
  SearchPage({Key? key}) : super(key: key);

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final ValueNotifier<List<String>> urls = ValueNotifier<List<String>>([]);

  TextEditingController searchController = TextEditingController();
  FocusNode textFocus = FocusNode();
  int _currentIndex = 0;
  bool _keyboardVisible = false;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getUrls();
    textFocus.addListener(() {
      if (textFocus.hasFocus) {
        RootCntr.to.bottomBarStreamController.sink.add(false);
      } else {
        RootCntr.to.bottomBarStreamController.sink.add(true);
      }
    });
  }

  // if (MediaQuery.of(context).viewInsets.bottom > 0.0) {
  //     // Keyboard is visible.
  //     RootCntr.to.bottomBarStreamController.sink.add(false);
  //   } else {
  //     // Keyboard is not visible.
  //     RootCntr.to.bottomBarStreamController.sink.add(true);
  //   }
  void goSearchPage(String searchWord) {
    Utils.alert("검색어: $searchWord");
    if (searchWord.isEmpty) {
      Utils.alert("검색어를 입력해주세요");
      return;
    }
    Get.toNamed('/MainView1/${Uri.encodeComponent(searchWord)}/0');
  }

  getUrls() async {
    urls.value = await ApiService.getVideos();
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
  Future<List<C2Choice<String>>> getChoices() async {
    String url = "https://randomuser.me/api/?inc=gender,name,nat,picture,email&results=25";
    r.Response res = await Dio().get(url);
    return C2Choice.listFrom<String, dynamic>(
      source: res.data['results'],
      value: (index, item) => item['email'],
      label: (index, item) => item['name']['first'] + ' ' + item['name']['last'],
      meta: (index, item) => item,
    )..insert(0, C2Choice<String>(value: 'all', label: 'All'));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      //  backgroundColor: Colors.white.withOpacity(.94),

      appBar: AppBar(
        forceMaterialTransparency: true,
        automaticallyImplyLeading: false,
        title: Container(
          margin: const EdgeInsets.symmetric(horizontal: 0),
          padding: const EdgeInsets.only(top: 5),
          height: 54,
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
        centerTitle: true,
        //  backgroundColor: Colors.transparent,
        elevation: 0,
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
          controller: RootCntr.to.hideButtonController4,
          children: [
            buildLastSearch(),
            const Gap(20),
            buildRecom(),
            buildWeatherInfoImg(),
            buildAddmob(),

            Image.asset('assets/images/girl-6356393_640.jpg', fit: BoxFit.cover, width: double.infinity, height: 700),
            // myFeeds()
          ],
        ),
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
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [Text("추천 검색어", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)), Spacer()],
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

  // 최근 검색어
  Widget buildLastSearch() {
    return Column(
      children: [
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("최근 검색어", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Text("지우기", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w300))
          ],
        ),
        const Gap(10),
        Row(
          children: [
            Wrap(
              spacing: 6.0,
              runSpacing: 6.0,
              children: <Widget>[
                buildChip('홍제역'),
                buildChip('광화문'),
                buildChip('개화'),
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
                              color: Color.fromARGB(255, 67, 68, 135),
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

  // 최그
  Widget buildChip(String label) {
    return InkWell(
        onTap: () => goSearchPage(label),
        child: Row(
          children: [
            Chip(
              backgroundColor: Colors.grey[200],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: const BorderSide(color: Colors.transparent),
              ),
              label: Text(label),
              onDeleted: () {
                // Perform delete
              },
            ),
          ],
        ));
  }
}
