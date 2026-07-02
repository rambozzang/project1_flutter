import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:gap/gap.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';
import 'package:project1/app/auth/cntr/auth_cntr.dart';
import 'package:project1/app/favoriteArea/favorite_area_search_page.dart';
import 'package:project1/app/weather/models/geocode.dart';
import 'package:project1/app/weathergogo/cntr/weather_gogo_cntr.dart';
import 'package:project1/repo/common/res_data.dart';
import 'package:project1/repo/common/res_stream.dart';
import 'package:project1/repo/cust/cust_repo.dart';
import 'package:project1/repo/cust/data/cust_tag_data.dart';
import 'package:project1/repo/kakao/kakao_repo.dart';
import 'package:project1/repo/secure_storge.dart';
import 'package:project1/utils/log_utils.dart';
import 'package:project1/utils/utils.dart';
import 'package:project1/widget/custom_button.dart';
import 'package:bot_toast/bot_toast.dart';

class FavoriteAreaPage extends StatefulWidget {
  const FavoriteAreaPage({super.key});

  @override
  State<FavoriteAreaPage> createState() => _FavoriteAreaPageState();
}

class _FavoriteAreaPageState extends State<FavoriteAreaPage> with SecureStorage {
  final ValueNotifier<List<String>> urls = ValueNotifier<List<String>>([]);
  // 최근 검색어
  final ValueNotifier<List<String>> lastSerchValue = ValueNotifier<List<String>>([]);

  // upslash api 로 날씨 관련 이미지 가져오기
  final ValueNotifier<GeocodeData> geocodeDataValue =
      ValueNotifier<GeocodeData>(GeocodeData(name: '', latLng: const LatLng(0, 0), addr: ''));

  TextEditingController searchController = TextEditingController();
  FocusNode textFocus = FocusNode();

  // NaverMapController, NLatLng, NOverlayImage, NMarker, NOverlayCaption 등 flutter_naver_map 관련 코드 모두 주석 처리
  // ... flutter_naver_map 관련 코드 전체 주석 처리 ...

  late Position? position;
  final onCameraChangeStreamController = StreamController<NCameraUpdateReason>.broadcast();
  bool initialized = false;

  StreamController<ResStream<List<String>>> areaStream = StreamController();

  List<String> _arealist = [];

  final KakaoRepo _kakaoRepo = KakaoRepo();

  /// 관심지역은 이름만 저장되므로, 클릭 시 카카오 지오코딩으로 실제 좌표를 얻어 날씨를 조회한다.
  /// (기존에는 LatLng(0,0)을 넘겨 엉뚱한 좌표의 날씨를 조회하던 버그가 있었음)
  Future<void> _openWeatherByAreaName(String areaName) async {
    try {
      final docs = await _kakaoRepo.getCoordinates(areaName);
      final doc = docs.isEmpty ? null : docs.first;
      final lat = double.tryParse(doc?['y']?.toString() ?? '');
      final lon = double.tryParse(doc?['x']?.toString() ?? '');
      if (lat == null || lon == null) {
        Utils.alert('[$areaName] 위치를 찾지 못했습니다.');
        return;
      }
      Get.find<WeatherGogoCntr>().searchWeatherKakao(
          GeocodeData(name: areaName, latLng: LatLng(lat, lon), addr: doc?['address_name']?.toString() ?? ''));
      Get.back();
    } catch (e) {
      lo.g('관심지역 지오코딩 실패: $e');
      Utils.alert('위치 조회 중 오류가 발생했습니다.');
    }
  }

  @override
  void initState() {
    super.initState();
    init();
    getLocalTag();
  }

  void init() async {
    await NaverMapSdk.instance.initialize(
        clientId: '1gvb59zfma',
        onAuthFailed: (ex) {
          Lo.g("********* 네이버맵 인증오류 : $ex *********");
          Utils.alert("네이버 지도 인증 실패 ClientID 확인해주세요~");
        });
    setState(() {
      initialized = true;
    });
  }

  // 관심태그 삭제
  Future<void> removeLocalTag(String tagNm) async {
    try {
      CustRepo repo = CustRepo();
      _arealist.remove(tagNm);
      areaStream.sink.add(ResStream.completed(_arealist));

      ResData res = await repo.deleteTag(AuthCntr.to.resLoginData.value.custId.toString(), tagNm, 'LOCAL');
      if (res.code != '00') {
        Utils.alert(res.msg.toString());
        return;
      }
      Utils.alert('삭제되었습니다.');
      //  getTag();
    } catch (e) {
      Utils.alert(e.toString());
    }
  }

  // 관심태그 추가
  Future<void> addLocalTag(GeocodeData geocodeData) async {
    try {
      CustRepo repo = CustRepo();
      CustTagData data = CustTagData();
      _arealist.add(geocodeData.name);
      // Utils.alert('추가되었습니다.');
      areaStream.sink.add(ResStream.completed(_arealist));

      data.custId = AuthCntr.to.resLoginData.value.custId.toString();
      data.tagNm = geocodeData.name;
      data.tagType = 'LOCAL';
      data.lat = geocodeData.latLng.latitude.toString();
      data.lon = geocodeData.latLng.longitude.toString();
      data.addr = geocodeData.addr.toString();
      ResData res = await repo.saveTag(data);
      if (res.code != '00') {
        Utils.alert(res.msg.toString());
        return;
      }
      Utils.alert('추가되었습니다.');
      geocodeDataValue.value = GeocodeData(name: '', latLng: const LatLng(0, 0), addr: '');

      //   getTag();
    } catch (e) {
      Utils.alert(e.toString());
    }
  }

  // 관심태그 조회
  Future<void> getLocalTag() async {
    try {
      CustRepo repo = CustRepo();
      ResData res = await repo.getTagList(AuthCntr.to.resLoginData.value.custId.toString(), 'LOCAL');
      if (res.code != '00') {
        Utils.alert(res.msg.toString());
        return;
      }
      _arealist = (res.data as List).map((e) => e['id']['tagNm'].toString()).toList();

      areaStream.sink.add(ResStream.completed(_arealist));
    } catch (e) {
      Utils.alert(e.toString());
      // myCountCntr.sink.add(ResStream.error(e.toString()));
    }
  }

  Future<void> locationUpdate(GeocodeData geocodeData) async {
    lo.g('geocodeData.latLng.latitude: ${geocodeData.latLng.latitude}');
    // NaverMapController, NLatLng, NOverlayImage, NMarker, NOverlayCaption 등 flutter_naver_map 관련 코드 모두 주석 처리
    // ... flutter_naver_map 관련 코드 전체 주석 처리 ...

    // localDesc.value = '주소 : ${geocodeData.addr}';
    geocodeDataValue.value = geocodeData;

    // NLatLng currentCoord = NLatLng(geocodeData.latLng.latitude, geocodeData.latLng.longitude);
    // final locationOverlay = await mapController.getLocationOverlay();
    const iconImage = NOverlayImage.fromAssetImage('assets/images/map/blue_pin.png');
    // locationOverlay
    //   ..setIcon(iconImage)
    //   ..setIconSize(const Size.fromRadius(140))
    //   ..setCircleRadius(100.0)
    //   ..setCircleColor(Colors.grey.withOpacity(0.17))
    //   ..setPosition(currentCoord)
    //   ..setIsVisible(true);

    final cameraUpdate = NCameraUpdate.withParams(target: NLatLng(geocodeData.latLng.latitude, geocodeData.latLng.longitude))
      ..setAnimation(animation: NCameraAnimation.linear, duration: const Duration(milliseconds: 500)); // 2초는 너무 길 수도 있어요.
    // await mapController.updateCamera(cameraUpdate);

    final marker = NMarker(
      id: geocodeData.latLng.longitude.toString(),
      position: NLatLng(double.parse(geocodeData.latLng.latitude.toString()), double.parse(geocodeData.latLng.longitude.toString())),
      icon: iconImage,
      size: const Size(40, 40),
      captionOffset: 0,
      caption: NOverlayCaption(text: geocodeData.name.toString()),
    );
    // mapController.addOverlay(marker);
    // final onMarkerInfoWindow = NInfoWindow.onMarker(offsetX: 10, id: marker.info.id, text: "${geocodeData.name}");

    // marker.openInfoWindow(onMarkerInfoWindow);
    // buildSaveWidget(geocodeData);
  }

  void goFavoriteAreaPage(String searchWord) async {
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

  List<String> tags = [];
  late String value;

  @override
  void dispose() {
    // NaverMapController, NLatLng, NOverlayImage, NMarker, NOverlayCaption 등 flutter_naver_map 관련 코드 모두 주석 처리
    // ... flutter_naver_map 관련 코드 전체 주석 처리 ...
    searchController.dispose();
    textFocus.dispose();
    areaStream.close();
    geocodeDataValue.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        appBar: AppBar(
          forceMaterialTransparency: true,
          backgroundColor: Colors.white,
          titleSpacing: 0,
          elevation: 0,
          centerTitle: false,
          title: const Text(
            '관심지역 등록',
            style: TextStyle(color: Colors.black, fontSize: 15, fontWeight: FontWeight.w600),
          ),
        ),
        body: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.only(left: 10, right: 10, top: 10),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: <Widget>[
                  const Gap(kToolbarHeight + 10),
                  Container(
                    decoration: const BoxDecoration(
                      borderRadius: BorderRadius.all(Radius.circular(15)),
                    ),
                    height: 240,
                    child: initialized
                        ? const Column(
                            children: [
                              Text("지도 표시 영역 (현재 주석 처리됨)"),
                              // NaverMap(
                              //     forceGesture: true,
                              //     options: NaverMapViewOptions(
                              //       locationButtonEnable: false,
                              //       initialCameraPosition: NCameraPosition(
                              //           target: NLatLng(Get.find<WeatherGogoCntr>().currentLocation.value.latLng.latitude,
                              //               Get.find<WeatherGogoCntr>().currentLocation.value.latLng.longitude),
                              //           zoom: 15,
                              //           bearing: 0,
                              //           tilt: 0),
                              //       extent: NLatLngBounds(
                              //         southWest: NLatLng(31.43, 122.37),
                              //         northEast: NLatLng(44.35, 132),
                              //       ),
                              //       minZoom: 6,
                              //       maxZoom: 16,
                              //       mapType: NMapType.basic,
                              //       liteModeEnable: true, // 필요한 경우 활성화
                              //       pickTolerance: 8,
                              //       locale: const Locale('ko'),
                              //       logoClickEnable: false,
                              //       logoAlign: NLogoAlign.leftBottom,
                              //       scaleBarEnable: false, // 축척 바 표시 여부
                              //       indoorEnable: true, // 실내 지도 표시 여부
                              //       nightModeEnable: false, // 야간 모드 표시 여부
                              //       scrollGesturesEnable: true, // 스크롤 제스처 사용 여부
                              //       zoomGesturesEnable: true, // 줌 제스처 사용 여부
                              //       tiltGesturesEnable: true, // 기울이기 제스처 사용 여부
                              //       rotateGesturesEnable: true, // 회전 제스처 사용 여부
                              //       stopGesturesEnable: true, // 모든 제스처 중지 여부
                              //       contentPadding: EdgeInsets.zero, // 콘텐츠 패딩
                              //     ),
                              //     onMapReady: (controller) {
                              //       mapController = controller;
                              //       // 초기 위치 설정 또는 기타 작업
                              //     },
                              //     onMapTapped: (point, latLng) {
                              //       // 지도 탭 이벤트 처리
                              //     },
                              //     onSymbolTapped: (symbol) {
                              //       // 심볼 탭 이벤트 처리
                              //     },
                              //     onCameraChange: (position, reason, isAnimated) {
                              //       onCameraChangeStreamController.sink.add(reason);
                              //     },
                              //     onCameraIdle: () {
                              //       // 카메라 이동 멈춤 이벤트 처리
                              //     },
                              //     onSelectedIndoorChanged: (indoorInfo) {
                              //       // 실내 지도 변경 이벤트 처리
                              //     },
                              //   ),
                            ],
                          )
                        : const Center(child: CircularProgressIndicator()),
                  ),
                  ValueListenableBuilder<GeocodeData>(
                      valueListenable: geocodeDataValue,
                      builder: (context, value, child) {
                        if (value.name.isEmpty) {
                          return const SizedBox.shrink();
                        }
                        return Column(
                          children: [
                            const Gap(10),
                            Text('선택된 지역: ${value.name}'),
                            Text('주소: ${value.addr}'),
                            const Gap(10),
                            CustomButton(
                              text: '이 지역 추가',
                              onPressed: () {
                                addLocalTag(value);
                              },
                              type: 'S',
                              isEnable: true,
                            ),
                          ],
                        );
                      }),
                  const Gap(20),
                  // 검색창과 최근 검색어 표시 부분
                  _buildSearchSection(),
                  const Gap(20),
                  _buildFavoriteList(),
                  const Gap(30),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '지역 검색',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const Gap(10),
        TextField(
          controller: searchController,
          focusNode: textFocus,
          decoration: InputDecoration(
            hintText: '동/읍/면 또는 건물명 입력',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.blue),
            ),
            suffixIcon: IconButton(
              icon: const Icon(Icons.search),
              onPressed: () {
                if (searchController.text.isNotEmpty) {
                  Get.to(() => FavoriteAreaSearchPage(
                        onSelectClick: (selectedGeocodeData) {
                          locationUpdate(selectedGeocodeData);
                          Get.back();
                        },
                      ));
                }
              },
            ),
          ),
          onSubmitted: (value) {
            if (value.isNotEmpty) {
              Get.to(() => FavoriteAreaSearchPage(
                    onSelectClick: (selectedGeocodeData) {
                      locationUpdate(selectedGeocodeData);
                      Get.back();
                    },
                  ));
            }
          },
        ),
        // 최근 검색어 등 추가 UI가 필요하면 여기에 구현
      ],
    );
  }

  Widget _buildFavoriteList() {
    return StreamBuilder<ResStream<List<String>>>(
      stream: areaStream.stream,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          final data = snapshot.data!;
          if (data.status == Status.COMPLETED) {
            if (data.data!.isEmpty) {
              return const Center(child: Text('등록된 관심 지역이 없습니다.'));
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '나의 관심 지역',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const Gap(10),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: data.data!.length,
                  itemBuilder: (context, index) {
                    final areaName = data.data![index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 5),
                      child: ListTile(
                        title: Text(areaName),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                          onPressed: () {
                            Utils.showConfirmDialog(
                              '삭제 확인',
                              '[$areaName] 지역을 삭제하시겠습니까?',
                              BackButtonBehavior.none,
                              confirm: () => removeLocalTag(areaName),
                            );
                          },
                        ),
                        onTap: () => _openWeatherByAreaName(areaName),
                      ),
                    );
                  },
                ),
              ],
            );
          } else if (data.status == Status.ERROR) {
            return Center(child: Text('오류: ${data.message}'));
          }
        }
        return const Center(child: CircularProgressIndicator());
      },
    );
  }
}
