import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';

import 'package:material_floating_search_bar_2/material_floating_search_bar_2.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:project1/app/weather/models/geocode.dart';
import 'package:project1/app/weather/theme/colors.dart';
import 'package:project1/app/weather/cntr/weather_cntr.dart';
import 'package:project1/repo/kakao/kakao_repo.dart';
import 'package:project1/root/cntr/root_cntr.dart';

class KakaoSearchPage extends StatefulWidget {
  const KakaoSearchPage({super.key});

  @override
  State<KakaoSearchPage> createState() => _KakaoSearchPageState();
}

class _KakaoSearchPageState extends State<KakaoSearchPage> {
  FloatingSearchBarController fsc = FloatingSearchBarController();

  final StreamController<List<Map<String, dynamic>>> _streamController = StreamController<List<Map<String, dynamic>>>();

  @override
  void initState() {
    super.initState();
  }

  void _search() async {
    try {
      KakaoRepo kakaoRepo = KakaoRepo();
      final data = await kakaoRepo.getCoordinates(fsc.query);
      _streamController.sink.add(data);
    } catch (e) {
      _streamController.sink.addError(e);
    }
  }

  _selectClick(Map<String, dynamic> data) async {
    Get.find<WeatherCntr>().isLoading.value = true;
    late GeocodeData geocodeData = GeocodeData(
      name: data['place_name'],
      latLng: LatLng(double.parse(data['y'] ?? 0.0), double.parse(data['x'] ?? 0.0)),
    );
    Get.find<WeatherCntr>().searchWeatherKakao(geocodeData);
  }

  @override
  void dispose() {
    _streamController.sink.close();
    _streamController.close();
    fsc.clear();
    fsc.dispose();
    RootCntr.to.bottomBarStreamController.sink.add(true);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FloatingSearchBar(
      // backgroundColor: Colors.grey.shade400,
      controller: fsc,
      hint: '국내 지명, 주소를 검색해주세요.',
      clearQueryOnClose: false,
      scrollPadding: const EdgeInsets.only(top: 0.0, bottom: 56.0, left: 2.0, right: 2.0),
      margins: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 3),
      transitionDuration: const Duration(milliseconds: 10),
      borderRadius: BorderRadius.circular(14.0),
      transitionCurve: Curves.easeInOut,
      accentColor: primaryBlue,
      hintStyle: const TextStyle(color: Colors.black), //regularText,
      queryStyle: const TextStyle(color: Colors.black), //regularText,
      physics: const BouncingScrollPhysics(),
      elevation: 20.0,
      implicitDuration: const Duration(milliseconds: 10),
      debounceDelay: const Duration(milliseconds: 300),
      onFocusChanged: (isFocused) {
        if (!isFocused) {
          fsc.clear();
        }
        RootCntr.to.bottomBarStreamController.sink.add(false);
      },
      onQueryChanged: (query) {
        _search();
      },
      onSubmitted: (query) async {
        fsc.close();
        _search();
      },
      transition: SlideFadeFloatingSearchBarTransition(), // ,CircularFloatingSearchBarTransition(),
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
                      separatorBuilder: (context, index) => const Divider(
                            thickness: 1.0,
                            height: 0.0,
                          ),
                      itemBuilder: (context, index) {
                        final _data = snapshot.data![index];
                        return InkWell(
                          onTap: () {
                            _selectClick(_data);
                            fsc.query = _data['place_name'];
                            fsc.close();
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
                      });
                }),
          ),
        );
      },
    );
  }
}
