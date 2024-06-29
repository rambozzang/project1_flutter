import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import 'package:material_floating_search_bar_2/material_floating_search_bar_2.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:project1/app/weather/models/geocode.dart';
import 'package:project1/app/weather/provider/weatherProvider.dart';
import 'package:project1/app/weather/theme/colors.dart';
import 'package:project1/app/weather/provider/weather_cntr.dart';
import 'package:project1/root/cntr/root_cntr.dart';
import 'package:project1/utils/log_utils.dart';
import 'package:provider/provider.dart';

class KakaoApiService {
  // kakao 개발자 사이트에서 발급받은 REST API 키를 입력 https://developers.kakao.com/console/app/1049247/config/appKey
  // kakao Rest API key 로 입력
  static const String _apiKey = '70e4b88482c00c397ad1022108f02dfc';
  static const String _apiUrl = 'https://dapi.kakao.com/v2/local/search/keyword.json?page=1&size=15&sort=accuracy';

  Future<List<Map<String, dynamic>>> getCoordinates(String query) async {
    final response = await http.get(
      Uri.parse('$_apiUrl&query=$query'),
      headers: {
        'Authorization': 'KakaoAK $_apiKey',
      },
    );

    Lo.g('response : ${response.body} ');

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['documents'].isNotEmpty) {
        return List<Map<String, dynamic>>.from(data['documents']);
      } else {
        throw Exception('No results found');
      }
    } else {
      throw Exception('Failed to load data');
    }
  }
}

class KakaoSearchPage extends StatefulWidget {
  const KakaoSearchPage({super.key});

  @override
  State<KakaoSearchPage> createState() => _KakaoSearchPageState();
}

class _KakaoSearchPageState extends State<KakaoSearchPage> {
  FloatingSearchBarController fsc = FloatingSearchBarController();

  final StreamController<List<Map<String, dynamic>>> _streamController = StreamController<List<Map<String, dynamic>>>();

  final KakaoApiService _apiService = KakaoApiService();
  List<Map<String, dynamic>> _results = [];
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
  }

  void _search() async {
    try {
      final data = await _apiService.getCoordinates(fsc.query);
      _streamController.sink.add(data);
      // setState(() {
      //   _results = data;
      //   _errorMessage = '';
      // });
    } catch (e) {
      _streamController.sink.addError(e);
      // setState(() {
      //   _results = [];
      //   _errorMessage = '에러: $e';
      // });
    }
  }

  _selectClick(Map<String, dynamic> data) async {
    late GeocodeData geocodeData = GeocodeData(
      name: data['place_name'],
      // 아래 data['y'] 값을 double 변환하여 넣어줘야 함

      latLng: LatLng(double.parse(data['y'] ?? 0.0), double.parse(data['x'] ?? 0.0)),
    );

    // await Provider.of<WeatherProvider>(context, listen: false).searchWeatherKakao(geocodeData);
    Get.find<WeatherCntr>().searchWeatherKakao(geocodeData);
  }

  @override
  void dispose() {
    _streamController.sink.close();

    _streamController.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FloatingSearchBar(
      // backgroundColor: Colors.grey.shade400,
      controller: fsc,
      hint: '국내 지명, 주소를 검색해주세요.',
      clearQueryOnClose: false,
      scrollPadding: const EdgeInsets.only(top: 8.0, bottom: 56.0, left: 10.0, right: 10.0),
      margins: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 3),
      transitionDuration: const Duration(milliseconds: 100),
      borderRadius: BorderRadius.circular(14.0),
      transitionCurve: Curves.easeInOut,
      accentColor: primaryBlue,
      hintStyle: const TextStyle(color: Colors.black), //regularText,
      queryStyle: const TextStyle(color: Colors.black), //regularText,
      physics: const BouncingScrollPhysics(),
      elevation: 20.0,
      debounceDelay: const Duration(milliseconds: 300),
      onFocusChanged: (isFocused) {
        // if (!isFocused) {
        //   fsc.clear();
        // }
        RootCntr.to.bottomBarStreamController.sink.add(false);
      },
      onQueryChanged: (query) {
        _search();
      },
      onSubmitted: (query) async {
        fsc.close();
        _search();
      },
      transition: CircularFloatingSearchBarTransition(),
      automaticallyImplyBackButton: false,
      actions: [
        const FloatingSearchBarAction(
          showIfOpened: false,
          child: PhosphorIcon(
            PhosphorIconsBold.magnifyingGlass,
            color: primaryBlue,
          ),
        ),
        FloatingSearchBarAction.icon(
          showIfClosed: false,
          showIfOpened: true,
          icon: const PhosphorIcon(
            PhosphorIconsBold.x,
            color: primaryBlue,
          ),
          onTap: () {
            if (fsc.query.isEmpty) {
              fsc.close();
            } else {
              fsc.clear();
            }
          },
        ),
      ],
      builder: (context, transition) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(4.0),
          child: Material(
            color: Colors.white,
            elevation: 1.0,
            child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: _streamController.stream,
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const SizedBox.shrink();
                  }
                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.zero,
                    itemCount: snapshot.data!.length,
                    itemBuilder: (context, index) {
                      final _data = snapshot.data![index];
                      return InkWell(
                        onTap: () async {
                          fsc.query = _data['place_name'];
                          fsc.close();
                          _selectClick(_data);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(12.0),
                          child: Row(
                            children: [
                              const PhosphorIcon(PhosphorIconsFill.mapPin),
                              const SizedBox(width: 15.0),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(_data['place_name'],
                                        style: GoogleFonts.openSans(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black,
                                        )),
                                    Text(_data['address_name'],
                                        style: GoogleFonts.openSans(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w400,
                                          color: Colors.black,
                                        )),
                                    _data['road_address_name'] == null
                                        ? Text(_data['road_address_name'],
                                            style: GoogleFonts.openSans(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w400,
                                              color: Colors.black,
                                            ))
                                        : const SizedBox.shrink(),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                    separatorBuilder: (context, index) => const Divider(
                      thickness: 1.0,
                      height: 0.0,
                    ),
                  );
                }),
          ),
        );
      },
    );
  }
}
