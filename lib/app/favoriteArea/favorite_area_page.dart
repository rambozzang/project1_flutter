import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
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
import 'package:project1/repo/secure_storge.dart';
import 'package:project1/utils/log_utils.dart';
import 'package:project1/utils/utils.dart';
import 'package:project1/widget/custom_button.dart';

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

  late NaverMapController mapController;
  late Position? position;
  final onCameraChangeStreamController = StreamController<NCameraUpdateReason>.broadcast();
  bool initialized = false;

  StreamController<ResStream<List<String>>> areaStream = StreamController();

  List<String> _arealist = [];

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
    mapController.clearOverlays();

    // localDesc.value = '주소 : ${geocodeData.addr}';
    geocodeDataValue.value = geocodeData;

    NLatLng currentCoord = NLatLng(geocodeData.latLng.latitude, geocodeData.latLng.longitude);
    // final locationOverlay = await mapController.getLocationOverlay();
    const iconImage = NOverlayImage.fromAssetImage('assets/images/map/blue_pin.png');
    // locationOverlay
    //   ..setIcon(iconImage)
    //   ..setIconSize(const Size.fromRadius(140))
    //   ..setCircleRadius(100.0)
    //   ..setCircleColor(Colors.grey.withOpacity(0.17))
    //   ..setPosition(currentCoord)
    //   ..setIsVisible(true);

    final cameraUpdate = NCameraUpdate.withParams(target: currentCoord)
      ..setAnimation(animation: NCameraAnimation.linear, duration: const Duration(milliseconds: 500)); // 2초는 너무 길 수도 있어요.
    await mapController.updateCamera(cameraUpdate);

    final marker = NMarker(
      id: geocodeData.latLng.longitude.toString(),
      position: NLatLng(double.parse(geocodeData.latLng.latitude.toString()), double.parse(geocodeData.latLng.longitude.toString())),
      icon: iconImage,
      size: const Size(40, 40),
      captionOffset: 0,
      caption: NOverlayCaption(text: geocodeData.name.toString()),
    );
    mapController.addOverlay(marker);
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
    mapController.dispose();
    searchController.dispose();
    textFocus.dispose();
    areaStream.close();
    geocodeDataValue.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        forceMaterialTransparency: true,
        backgroundColor: Colors.transparent,
        titleSpacing: 0,
        elevation: 0,
        centerTitle: false,
        title: const Text(
          '관심지역 등록',
          // style: TextStyle(color: Colors.black, fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            // padding: EdgeInsets.only(left: 10, right: 10, top: Platform.isIOS ? kToolbarHeight : kToolbarHeight - 30, bottom: 18),
            padding: const EdgeInsets.only(left: 10, right: 10, top: 10),
            // physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                const Gap(kToolbarHeight + 10),
                Container(
                  decoration: BoxDecoration(
                    // color: Colors.black,
                    borderRadius: const BorderRadius.all(Radius.circular(15)),
                    // border: Border.all(color: Colors.grey),
                  ),
                  height: 240,
                  child: initialized
                      ? NaverMap(
                          forceGesture: true,
                          options: NaverMapViewOptions(
                            locationButtonEnable: false,
                            initialCameraPosition: NCameraPosition(
                                target: NLatLng(Get.find<WeatherGogoCntr>().currentLocation.value.latLng.latitude,
                                    Get.find<WeatherGogoCntr>().currentLocation.value.latLng.longitude),
                                zoom: 13,
                                bearing: 0,
                                tilt: 0),
                          ),
                          onMapReady: (controller) {
                            mapController = controller;
                            // 파란색 점으로 현재위치 표시
                            mapController.setLocationTrackingMode(NLocationTrackingMode.noFollow);
                          },
                        )
                      : const SizedBox.shrink(),
                ),
                const Gap(20),
                // const Divider(),
                // const Gap(10),
                const Align(
                    alignment: Alignment.centerLeft, child: Text('관심 지역 리스트', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800))),
                const Gap(10),
                buildLocalTag(),
                const Gap(200),
              ],
            ),
          ),
          FavoriteAreaSearchPage(
            onSelectClick: locationUpdate,
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: ValueListenableBuilder(
                valueListenable: geocodeDataValue,
                builder: (builder, value, child) {
                  if (value.name == '') return const SizedBox.shrink();
                  return Container(
                    padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(value.name.toString(), style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                              Text(value.addr.toString(),
                                  overflow: TextOverflow.clip, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                        SizedBox(
                            height: 40,
                            width: 90,
                            child: CustomButton(
                                text: '등록하기',
                                isEnable: true,
                                listColors: const [
                                  Color.fromARGB(255, 36, 77, 158),
                                  Color.fromARGB(255, 35, 81, 172),
                                ],
                                type: 'S',
                                onPressed: () => addLocalTag(value))),
                      ],
                    ),
                  );
                }),
          )
        ],
      ),
    );
  }

  // 검색지역 저장 화면
  void buildSaveWidget(GeocodeData value) {
    showModalBottomSheet(
      isScrollControlled: true,
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(15.0),
        ),
      ),
      backgroundColor: Colors.white, //.withOpacity(0.8),
      builder: (BuildContext context) {
        return SizedBox(
            height: 120,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(value.name.toString(), style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                      Text(value.addr.toString(), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  SizedBox(
                      height: 40,
                      width: 80,
                      child: CustomButton(
                          text: '등록하기',
                          isEnable: true,
                          listColors: const [
                            Color.fromARGB(255, 36, 77, 158),
                            Color.fromARGB(255, 35, 81, 172),
                          ],
                          type: 'S',
                          onPressed: () {
                            Navigator.pop(context);
                            addLocalTag(value);
                          })),
                ],
              ),
            ));
      },
    );
  }

  // 메인 검색어
  Widget buildLocalTag() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: StreamBuilder<ResStream<List<String>>>(
          stream: areaStream.stream,
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              if (snapshot.data!.status == Status.COMPLETED) {
                List<String> list = snapshot.data!.data!;
                if (list.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(20),
                    alignment: Alignment.center,
                    child: Text(
                      '등록된 관심지역이 없습니다.',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  );
                }
                return Wrap(
                  spacing: 6.0,
                  runSpacing: 6.0,
                  direction: Axis.horizontal,
                  crossAxisAlignment: WrapCrossAlignment.start,
                  verticalDirection: VerticalDirection.down,
                  runAlignment: WrapAlignment.start,
                  alignment: WrapAlignment.start,
                  children: list.map((e) => buildChip(e)).toList(),
                );
              } else {
                return Container(
                  padding: const EdgeInsets.all(20),
                  alignment: Alignment.center,
                  child: Text(
                    '등록된 관심지역이 없습니다.',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade600,
                    ),
                  ),
                );
              }
            } else {
              // getTag();
              return Container(
                padding: const EdgeInsets.all(20),
                alignment: Alignment.center,
                child: Text(
                  '등록된 관심지역이 없습니다.',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade600,
                  ),
                ),
              );
            }
          }),
    );
  }

  Widget buildChip(String label) {
    return InkWell(
        onTap: () => Get.toNamed('/MainView1/${AuthCntr.to.resLoginData.value.custId.toString()}/0/${Uri.encodeComponent(label)}'),
        child: Chip(
          elevation: 0,
          padding: EdgeInsets.zero,
          backgroundColor: const Color.fromARGB(255, 140, 131, 221), // Color.fromARGB(255, 76, 70, 124),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: const BorderSide(color: Colors.transparent),
          ),
          label: Text(
            '  $label',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
          ),
          labelPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
          onDeleted: () => removeLocalTag(label),
          deleteButtonTooltipMessage: '삭제',
          deleteIconColor: Colors.white60,
        ));
  }
}
