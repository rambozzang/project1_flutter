import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:material_floating_search_bar_2/material_floating_search_bar_2.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:project1/app/weather/models/geocode.dart';
import 'package:project1/app/weather/theme/colors.dart';
import 'package:project1/repo/kakao/kakao_repo.dart';
import 'package:project1/app/weathergogo/cntr/weather_gogo_cntr.dart';
import 'package:project1/root/cntr/root_cntr.dart';

class WeathergogoKakaoSearchPage extends StatefulWidget {
  const WeathergogoKakaoSearchPage({Key? key}) : super(key: key);

  @override
  State<WeathergogoKakaoSearchPage> createState() => _WeathergogoKakaoSearchPageState();
}

class _WeathergogoKakaoSearchPageState extends State<WeathergogoKakaoSearchPage> {
  final FloatingSearchBarController _searchController = FloatingSearchBarController();
  final StreamController<List<Map<String, dynamic>>> _streamController = StreamController<List<Map<String, dynamic>>>();
  final KakaoRepo _kakaoRepo = KakaoRepo();
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _streamController.close();
    _searchController.dispose();
    RootCntr.to.bottomBarStreamController.add(true);
    super.dispose();
  }

  void _search(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      try {
        final data = await _kakaoRepo.getCoordinates(query);
        if (mounted) _streamController.add(data);
      } catch (e) {
        if (mounted) _streamController.addError(e);
      }
    });
  }

  void _selectLocation(Map<String, dynamic> data) {
    final geocodeData = GeocodeData(
      name: data['place_name'],
      latLng: LatLng(double.parse(data['y'] ?? '0'), double.parse(data['x'] ?? '0')),
    );
    Get.find<WeatherGogoCntr>().searchWeatherKakao(geocodeData);
    _searchController.query = data['place_name'];
    _searchController.close();
  }

  @override
  Widget build(BuildContext context) {
    return FloatingSearchBar(
      controller: _searchController,
      hint: '국내 지명, 주소를 검색해주세요.',
      scrollPadding: const EdgeInsets.fromLTRB(2, 0, 2, 56),
      margins: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      borderRadius: BorderRadius.circular(14),
      accentColor: primaryBlue,
      hintStyle: const TextStyle(color: Colors.black),
      queryStyle: const TextStyle(color: Colors.black),
      physics: const BouncingScrollPhysics(),
      onFocusChanged: (isFocused) {
        if (!isFocused) _searchController.clear();
        RootCntr.to.bottomBarStreamController.add(false);
      },
      onQueryChanged: _search,
      onSubmitted: _search,
      transition: SlideFadeFloatingSearchBarTransition(),
      actions: [
        _buildSearchIcon(),
        _buildClearIcon(),
      ],
      builder: (context, transition) => _buildSearchResults(),
    );
  }

  Widget _buildSearchIcon() {
    return const FloatingSearchBarAction(
      showIfOpened: false,
      child: PhosphorIcon(PhosphorIconsBold.magnifyingGlass, color: primaryBlue),
    );
  }

  Widget _buildClearIcon() {
    return FloatingSearchBarAction.icon(
      showIfOpened: true,
      icon: const PhosphorIcon(PhosphorIconsBold.x, color: primaryBlue),
      onTap: () {
        if (_searchController.query.isEmpty) {
          _searchController.close();
        } else {
          _searchController.clear();
        }
      },
    );
  }

  Widget _buildSearchResults() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: Material(
        color: Colors.white,
        elevation: 1,
        child: StreamBuilder<List<Map<String, dynamic>>>(
          stream: _streamController.stream,
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const SizedBox.shrink();
            return ListView.separated(
              shrinkWrap: true,
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.zero,
              itemCount: snapshot.data!.length,
              separatorBuilder: (_, __) => const Divider(thickness: 1, height: 0),
              itemBuilder: (context, index) => _buildSearchResultItem(snapshot.data![index]),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSearchResultItem(Map<String, dynamic> data) {
    return InkWell(
      onTap: () => _selectLocation(data),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            const PhosphorIcon(PhosphorIconsFill.mapPin),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data['place_name'],
                    style: GoogleFonts.openSans(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black),
                  ),
                  Text(
                    data['address_name'],
                    style: GoogleFonts.openSans(fontSize: 12, fontWeight: FontWeight.w400, color: Colors.black),
                  ),
                  if (data['road_address_name'] != null)
                    Text(
                      data['road_address_name'],
                      style: GoogleFonts.openSans(fontSize: 12, fontWeight: FontWeight.w400, color: Colors.black),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
