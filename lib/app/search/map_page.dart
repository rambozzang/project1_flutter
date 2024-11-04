import 'dart:async';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:gap/gap.dart';
import 'package:get/get.dart';
import 'package:giffy_dialog/giffy_dialog.dart';
import 'package:latlong2/latlong.dart';
import 'package:project1/app/auth/cntr/auth_cntr.dart';
import 'package:project1/app/search/cctv_page.dart';
import 'package:project1/app/search/cntr/map_cntr.dart';
import 'package:project1/app/search/map_search_page.dart';
import 'package:project1/app/weather/models/geocode.dart';
import 'package:project1/app/weathergogo/services/weather_data_processor.dart';
import 'package:project1/repo/board/data/board_weather_list_data.dart';
import 'package:project1/repo/cctv/cctv_repo.dart';
import 'package:project1/repo/cctv/data/cctv_res_data.dart';
import 'package:project1/app/weathergogo/cntr/weather_gogo_cntr.dart';
import 'package:project1/root/cntr/root_cntr.dart';
import 'package:project1/utils/StringUtils.dart';
import 'package:project1/utils/log_utils.dart';
import 'package:project1/utils/utils.dart';
import 'package:project1/widget/custom_indicator_offstage.dart';
import 'package:text_scroll/text_scroll.dart';
import 'package:video_player/video_player.dart';
import 'package:http/http.dart' as http;

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  late double topheight;
  late VideoPlayerController videoCntroller;
  bool initialized = false;

  final ValueNotifier<bool> soundOff = ValueNotifier<bool>(false);
  final ValueNotifier<bool> isPlay = ValueNotifier<bool>(true);
  final ValueNotifier<double> progress = ValueNotifier<double>(0.0);
  Size size = const Size(45, 60);
  Duration position = Duration.zero;
  late MapCntr mapCntr;
  double lat = 0;
  double lon = 0;
  @override
  void initState() {
    super.initState();
    topheight = Platform.isIOS ? 55 : 0;

    lat = Get.arguments?['lat'] ?? 0;
    lon = Get.arguments?['lon'] ?? 0;

    print('lat: $lat, lon: $lon');

    mapCntr = Get.find<MapCntr>();
    if (lat != 0 && lon != 0) {
      Get.find<MapCntr>().setInitialLocation(lat, lon);
    }
  }

  // 동영상 비디오 재생
  Future<void> videoPlay(String boardId, String videoPath) async {
    final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
    final lastModified = _formatHttpDate(sevenDaysAgo);

    initialized = false;
    videoCntroller = VideoPlayerController.networkUrl(Uri.parse(videoPath.toString()),
        httpHeaders: {
          'Connection': 'keep-alive',
          'Cache-Control': 'max-age=3600, stale-while-revalidate=86400',
          'Etg': boardId.toString(),
          'Last-Modified': lastModified,
          'If-None-Match': boardId.toString(),
          'If-Modified-Since': lastModified,
          'Vary': 'Accept-Encoding, User-Agent',
        },
        videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true, allowBackgroundPlayback: false),
        formatHint: VideoFormat.hls)
      ..initialize().then((_) {
        if (mounted) {
          setState(() {
            videoCntroller.setLooping(true);
            videoCntroller.play();
            videoCntroller.setVolume(0);
            initialized = true;
          });
        }
      });
  }

  String _formatHttpDate(DateTime date) {
    // Format the date as per HTTP-date format defined in RFC7231
    // Example: Tue, 15 Nov 1994 08:12:31 GMT
    final weekDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final weekDay = weekDays[date.weekday - 1];
    final month = months[date.month - 1];
    return '$weekDay, ${date.day.toString().padLeft(2, '0')} $month ${date.year} '
        '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}:'
        '${date.second.toString().padLeft(2, '0')} GMT';
  }

  // 카카오 검색창에서 검색후 클릭시 위치로 이동
  Future<void> locationUpdate(GeocodeData geocodeData) async {
    NLatLng currentCoord = NLatLng(geocodeData.latLng.latitude, geocodeData.latLng.longitude);
    await Get.find<MapCntr>().setPositionlocationUpdate(currentCoord: currentCoord);
    buildMarker(10);
  }

  // 마커 생성
  Future<void> buildMarker(int sDay) async {
    lo.g('buildMarker 호출');
    List<BoardWeatherListData> list = await Get.find<MapCntr>().buildMarker(sDay);

    list.forEach((element) async {
      final request = await http.get(Uri.parse(element.thumbnailPath.toString()));
      final NOverlayImage icon = await NOverlayImage.fromByteArray(request.bodyBytes);

      final marker = NMarker(
        id: element.boardId.toString(),
        position: NLatLng(double.parse(element.lat.toString()), double.parse(element.lon.toString())),
        icon: icon,
        size: size,
        captionOffset: 1,
        isFlat: true,
        caption: NOverlayCaption(text: Utils.timeage(element.crtDtm.toString()), color: Colors.red),
        // subCaption: NOverlayCaption(text: Utils.timeage(element.crtDtm.toString()), color: const Color.fromARGB(255, 53, 144, 58)),
        // caption: NOverlayCaption(text: element.nickNm.toString(), color: Colors.black),
      );
      Get.find<MapCntr>().mapController.addOverlay(marker);
      if (!StringUtils.isEmpty(element.contents)) {
        final onMarkerInfoWindow = NInfoWindow.onMarker(alpha: 1, offsetX: 0, id: marker.info.id, text: "${element.contents}");
        marker.openInfoWindow(onMarkerInfoWindow);
      }

      marker.setOnTapListener((overlay) async {
        videoPlay(element.boardId.toString(), element.videoPath.toString());
        onShowDialog(context, element);
      });
    });
  }

  @override
  void dispose() {
    if (initialized) {
      videoCntroller.pause();
      videoCntroller.dispose();
    }
    Get.find<RootCntr>().bottomBarStreamController.sink.add(true);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Obx(
        () => mapCntr.isInit.value
            ? Stack(
                children: [
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    bottom: MediaQuery.of(context).size.height * 0.1,
                    child: NaverMap(
                      options: NaverMapViewOptions(
                        locationButtonEnable: true,
                        initialCameraPosition: NCameraPosition(
                          target: NLatLng(
                            mapCntr.position.value!.latitude,
                            mapCntr.position.value!.longitude,
                          ),
                          zoom: 13,
                          bearing: 0,
                          tilt: 0,
                        ),
                      ),
                      onMapReady: (controller) async {
                        mapCntr.mapController = controller;

                        buildMarker(10);
                        mapCntr.mapController.setLocationTrackingMode(NLocationTrackingMode.noFollow);
                      },
                      // onCameraChange: (reason, animated) {
                      //   if (!animated) {
                      //     mapCntr.buildMarker(mapCntr.searchDay.value);
                      //   }
                      // },
                    ),
                  ),
                  buildTopButton(),
                  MapSearchPage(onSelectClick: locationUpdate),
                  CustomIndicatorOffstage(isLoading: !mapCntr.isLoadingList.value, color: const Color(0xFFEA3799), opacity: 0.5),

                  // 바텀시트를 Stack의 마지막에 추가하여 최상단에 표시
                  _buildBottomSheet(),
                ],
              )
            : const Center(child: CircularProgressIndicator()),
      ),
    );
  }

  Widget buildBoard() {
    return Positioned(
      bottom: 50,
      left: 70,
      right: 10,
      child: Container(
        height: 74,
        decoration: BoxDecoration(
          // 투명하게 해주세요.
          color: Colors.white.withOpacity(0.75),
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.5),
              spreadRadius: 1,
              blurRadius: 7,
              offset: const Offset(0, 7), // changes position of shadow
            ),
          ],
        ),
      ),
    );
  }

  // 상단 앱바
  Widget buildTop() {
    return Positioned(
        // top: topheight,
        top: MediaQuery.of(context).padding.top + 200,
        left: 10,
        right: 10,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  shape: BoxShape.rectangle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.5),
                      spreadRadius: 1,
                      blurRadius: 7,
                      offset: const Offset(0, 7), // changes position of shadow
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    IconButton(
                      onPressed: () => Get.find<MapCntr>().getLocation(),
                      icon: const Icon(Icons.location_on, color: Colors.black),
                    ),
                    TextScroll(
                      '${Get.find<WeatherGogoCntr>().currentLocation.value.name.toString()} ',
                      mode: TextScrollMode.endless,
                      numberOfReps: 20000,
                      fadedBorder: true,
                      delayBefore: const Duration(milliseconds: 4000),
                      pauseBetween: const Duration(milliseconds: 2000),
                      velocity: const Velocity(pixelsPerSecond: Offset(100, 0)),
                      style: const TextStyle(fontSize: 15, color: Colors.black, fontWeight: FontWeight.w500),
                      textAlign: TextAlign.right,
                      selectable: true,
                    ),
                  ],
                ),
              ),
            ),
            const Gap(10),
            ElevatedButton(
              onPressed: () => Get.back(),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(0),
                minimumSize: const Size(50, 50),
                backgroundColor: Colors.white,
                elevation: 5,
                shadowColor: Colors.grey,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
              child: const Icon(Icons.close, color: Colors.black),
            ),
          ],
        ));
  }

  Future showPopupMenu(BuildContext context, TapDownDetails tap, List<String> menus,
      {double buttonHeight = 24, double buttonWidth = 24}) async {
    var dx = tap.globalPosition.dx - (tap.localPosition.dx - buttonWidth);
    var dy = tap.globalPosition.dy - (tap.localPosition.dy - buttonHeight);
    return showMenu(
        context: context,
        position: RelativeRect.fromLTRB(dx, dy, dx, dy),
        items: menus.map((e) => PopupMenuItem<String>(value: e, onTap: () {}, child: Text(e))).toList(),
        elevation: 8.0);
  }

  ValueNotifier<double> isSlider = ValueNotifier<double>(0.0);

  Widget buildBottomSearch() {
    return Positioned(
      bottom: 65,
      left: 10,
      right: 20,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(5),
                minimumSize: const Size(70, 40),
                backgroundColor: Colors.white,
                elevation: 5,
                shadowColor: Colors.grey,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            onPressed: () => Get.find<MapCntr>().buildMarker(10),
            child: const Text("다시조회", style: TextStyle(color: Colors.black, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  // 우측 상단 조회 버튼
  Widget buildTopButton() {
    return Positioned(
        top: Platform.isIOS ? MediaQuery.of(context).padding.top + 50 : MediaQuery.of(context).padding.top + 60,
        right: 16,
        left: 0,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(5),
                  minimumSize: const Size(55, 25),
                  backgroundColor: Colors.white,
                  elevation: 5,
                  shadowColor: Colors.grey,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
              onPressed: () => buildMarker(1),
              child: const Text("오늘", style: TextStyle(color: Colors.black, fontSize: 12)),
            ),
            const Gap(10),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(5),
                  minimumSize: const Size(55, 25),
                  backgroundColor: Colors.white,
                  elevation: 5,
                  shadowColor: Colors.grey,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
              onPressed: () => buildMarker(7),
              child: const Text("일주일", style: TextStyle(color: Colors.black, fontSize: 12)),
            ),
            const Gap(10),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(5),
                  minimumSize: const Size(55, 25),
                  backgroundColor: Colors.white,
                  elevation: 5,
                  shadowColor: Colors.grey,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
              onPressed: () => buildMarker(31),
              child: const Text("한달", style: TextStyle(color: Colors.black, fontSize: 12)),
            ),
          ],
        ));
  }

  // 지역 및 서울 cctv 마커 생성
  Future<void> getCctv() async {
    //
    Size size = const Size(30, 30);
    var (southWest, northEast) = await Get.find<MapCntr>().getbounds();

    CctvRepo repo = CctvRepo();
    List<CctvResData> res = await repo.fetchCctv(
        southWest, northEast, Get.find<MapCntr>().position.value!.latitude, Get.find<MapCntr>().position.value!.longitude);
    lo.g('===>${res.toString()}');
    if (res == []) {
      //  return;
    }
    lo.g(res.length.toString());
    final NOverlayImage icon = const NOverlayImage.fromAssetImage('assets/images/map/cctv2.png');

    int markid = 1;
    res.forEach((element) async {
      lo.g('지방 마커 생성 --------------- ${element.cctvname}');
      final marker = NMarker(
        id: markid.toString(), // element.coordx.toString(),
        position: NLatLng(double.parse(element.coordy!), double.parse(element.coordx!)),
        icon: icon,
        size: size,
        captionOffset: 0,
      );
      Get.find<MapCntr>().mapController.addOverlay(marker);
      // final onMarkerInfoWindow = NInfoWindow.onMarker(id: marker.info.id, text: "${element.cctvname}°");
      // marker.openInfoWindow(onMarkerInfoWindow);
      marker.setOnTapListener((overlay) async {
        await CctvPageBottomSheet().open(context, element);
      });
      markid++;
    });

    // 서울 시내 cctv   southWest, northEast, 37.55998, 126.9858296
    // CctvSeoulReqData req = CctvSeoulReqData();
    // req.southWestLat = southWest.latitude;
    // req.southWestLng = southWest.longitude;
    // req.northEastLat = northEast.latitude;
    // req.northEastLng = northEast.longitude;
    // req.lat = Get.find<MapCntr>().position!.latitude;
    // req.lng = Get.find<MapCntr>().position!.longitude;

    // ResData res2 = await repo.fetchCctvSeoul(req);
    // List<CctvSeoulResData> list = ((res2.data) as List).map((data) => CctvSeoulResData.fromMap(data)).toList();
    // list.forEach((element) {
    //   lo.g('서울 마커 생성 --------------- ${element.cctvname}');
    //   final marker2 = NMarker(
    //     id: element.cctvid.toString(),
    //     position: NLatLng(double.parse(element.ycoord!), double.parse(element.xcoord!)),
    //     icon: icon,
    //     size: size,
    //     captionOffset: 0,
    //   );
    //   mapController.addOverlay(marker2);
    //   final onMarkerInfoWindow = NInfoWindow.onMarker(id: marker2.info.id, text: "${element.cctvname}°");
    //   marker2.openInfoWindow(onMarkerInfoWindow);
    //   marker2.setOnTapListener((overlay) async {
    //     await CctvSeoulPageBottomSheet().open(context, element);
    //   });
    //   markid++;
    // });
  }

  // 일반 영상 보기
  void onShowDialog(context, BoardWeatherListData data) {
    showModalBottomSheet(
      isScrollControlled: true,
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(15.0),
        ),
      ),
      backgroundColor: Colors.black, //
      builder: (BuildContext context) {
        return Container(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          height: 500,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(topLeft: Radius.circular(10.0), topRight: Radius.circular(10.0)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(top: 4, bottom: 10),
                  decoration: BoxDecoration(color: Colors.grey, borderRadius: BorderRadius.circular(100)),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 350,
                      alignment: Alignment.center,
                      color: Colors.grey[200],
                      child: GestureDetector(
                        onTap: () {
                          Get.toNamed(
                            '/VideoMyinfoListPage',
                            arguments: {
                              'datatype': 'ONE',
                              'custId': Get.find<AuthCntr>().resLoginData.value.custId.toString(),
                              'boardId': data.boardId.toString()
                            },
                          );
                        },
                        child: AspectRatio(
                          aspectRatio: 9 / 16,
                          child: Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(15),
                                child: VideoPlayer(videoCntroller),
                              ),
                              Positioned(
                                bottom: 6,
                                right: 6,
                                child: Obx(
                                  () => IconButton(
                                    onPressed: () {
                                      Get.find<MapCntr>().soundOn.value ? videoCntroller.setVolume(0) : videoCntroller.setVolume(1);
                                      Get.find<MapCntr>().soundOn.value = !Get.find<MapCntr>().soundOn.value;
                                    },
                                    icon: Get.find<MapCntr>().soundOn.value
                                        ? const Icon(Icons.volume_up_outlined, color: Colors.white)
                                        : const Icon(Icons.volume_off_outlined, color: Colors.white),
                                  ),
                                ),
                              )
                            ],
                          ),
                        ),
                      ),
                    ),
                    const Gap(1),
                    Expanded(
                      child: Container(
                        alignment: Alignment.topLeft,
                        // height: 300,
                        // width: MediaQuery.of(context).size.width * 0.5 - 50,
                        // alignment: Alignment.center,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(15),
                          // color: Colors.purple[50],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Row(
                            //   children: [
                            //     SizedBox(
                            //       width: 25,
                            //       child: CircleAvatar(
                            //         radius: 16,
                            //         backgroundColor: Colors.grey[100],
                            //         child: ClipOval(
                            //           child: CachedNetworkImage(
                            //             cacheKey: data.custId.toString(),
                            //             imageUrl: data.profilePath.toString(), //  'https://picsum.photos/200/300',
                            //             width: 23,
                            //             height: 23,
                            //             fit: BoxFit.cover,
                            //           ),
                            //         ),
                            //       ),
                            //     ),
                            //     const Gap(5),
                            //     Flexible(
                            //       child: Text(data.nickNm.toString(),
                            //           overflow: TextOverflow.clip,
                            //           style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87)),
                            //     ),
                            //   ],
                            // ),
                            Text(
                              '${data.crtDtm.toString().split(':')[0].replaceAll('-', '/')}:${data.crtDtm.toString().split(':')[1]}',
                              style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w600),
                            ),
                            const Gap(10),
                            const Divider(
                              color: Colors.grey,
                            ),
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.grey.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: Colors.green.withOpacity(0.9),
                                        borderRadius: BorderRadius.circular(5),
                                      ),
                                      child: const Icon(Icons.location_on, color: Colors.white, size: 14)),
                                  const SizedBox(width: 5),
                                  Flexible(
                                    child: Text(data.location.toString(),
                                        overflow: TextOverflow.clip,
                                        style: const TextStyle(fontSize: 12, color: Colors.black, fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              ),
                            ),
                            const Gap(15),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.start,
                                      children: [
                                        Text(
                                          data.currentTemp.toString(),
                                          style: const TextStyle(fontSize: 22, height: 1, fontWeight: FontWeight.bold, color: Colors.black),
                                        ),
                                        const Text(
                                          '°C',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.black,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        )
                                      ],
                                    ),
                                    Text(
                                      data.weatherInfo.toString(),
                                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black),
                                      overflow: TextOverflow.clip,
                                    ),
                                  ],
                                ),
                                const Gap(15),
                                SizedBox(
                                    height: 35,
                                    width: 35,
                                    child: WeatherDataProcessor.instance.getWeatherGogoImage(data.sky.toString(), data.rain.toString())
                                    // child: Lottie.asset(
                                    //   WeatherDataProcessor.instance.getWeatherGogoImage(data.sky.toString(), data.rain.toString()),
                                    //   height: 138.0,
                                    //   width: 138.0,
                                    // ),
                                    ),
                              ],
                            ),

                            const Gap(15),
                            Get.find<WeatherGogoCntr>().mistData.value.mist10Grade.toString() == 'null' ||
                                    Get.find<WeatherGogoCntr>().mistData.value.mist25Grade.toString() == null
                                ? const SizedBox()
                                : RichText(
                                    text: TextSpan(
                                      text: '미세',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: Colors.black,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      children: <TextSpan>[
                                        buildTextMist(Get.find<WeatherGogoCntr>().mistData.value.mist10Grade.toString()),
                                        const TextSpan(
                                          text: ' 초미세',
                                          style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13, color: Colors.black),
                                        ),
                                        buildTextMist(Get.find<WeatherGogoCntr>().mistData.value.mist25Grade.toString()),
                                      ],
                                    ),
                                  ),
                            // Row(
                            //   mainAxisAlignment: MainAxisAlignment.start,
                            //   children: [
                            //     const Text(
                            //       '미세    :',
                            //       style: TextStyle(fontSize: 15, color: Colors.black87),
                            //     ),
                            //     const Gap(10),
                            //     Text(Get.find<WeatherGogoCntr>().mistViewData.value!.mist10Grade!.toString(),
                            //         style: const TextStyle(fontSize: 15, color: Colors.black)),
                            //   ],
                            // ),
                            // Row(
                            //   mainAxisAlignment: MainAxisAlignment.start,
                            //   children: [
                            //     const Text('초미세 :', style: TextStyle(fontSize: 15, color: Colors.black87)),
                            //     const Gap(10),
                            //     Text(Get.find<WeatherGogoCntr>().mistViewData.value!.mist25Grade!.toString(),
                            //         style: const TextStyle(fontSize: 15, color: Colors.black)),
                            //   ],
                            // ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const Gap(10),
                Container(
                  height: 100,
                  padding: const EdgeInsets.only(top: 5),
                  alignment: Alignment.topLeft,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(color: Colors.grey.withOpacity(0.1)),
                    // color: ,
                  ),
                  child: SingleChildScrollView(
                    child: Text(
                      //'2phpasidhfakjshfsdf asdhf alksdf va sdflasdhf. askldfhalsdhjf asd faskdf vajdsf 2phpasidhfakjshfsdf asdhf alksdf va sdflasdhf. askldfhalsdhjf asd faskdf vajdsf 2phpasidhfakjshfsdf asdhf alksdf va sdflasdhf. askldfhalsdhjf asd faskdf vajdsf 2phpasidhfakjshfsdf asdhf alksdf va sdflasdhf. askldfhalsdhjf asd faskdf vajdsf 2phpasidhfakjshfsdf asdhf alksdf va sdflasdhf. askldfhalsdhjf asd faskdf vajdsf 2phpasidhfakjshfsdf asdhf alksdf va sdflasdhf. askldfhalsdhjf asd faskdf vajdsf 2phpasidhfakjshfsdf asdhf alksdf va sdflasdhf. askldfhalsdhjf asd faskdf vajdsf asdkjfhalsdhfalksdhfa lsdfkh. asldkfhalsdf alsdf 2phpasidhfakjshfsdf asdhf alksdf va sdflasdhf. askldfhalsdhjf asd faskdf vajdsf asdkjfhalsdhfalksdhfa lsdfkh. asldkfhalsdf alsdf ',
                      data.contents.toString(),
                      style: const TextStyle(fontSize: 15, color: Colors.black),
                      overflow: TextOverflow.clip,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ).then((onValue) {
      videoCntroller.pause();
      videoCntroller.seekTo(const Duration(seconds: 0));
      initialized = false;
      // videoCntroller.dispose();
    });
  }

  TextSpan buildTextMist(String mist) {
    Color color = Colors.blue;
    switch (mist) {
      case '좋음':
        color = Colors.blue;
        break;
      case '보통':
        color = Colors.green;
        break;
      case '나쁨':
        color = Colors.orange;
        break;
      case '매우나쁨':
        color = Colors.red;
        break;
      default:
        color = Colors.blue;
    }

    return TextSpan(
      text: mist,
      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: color),
    );
  }

  Widget _buildBottomSheet() {
    return DraggableScrollableSheet(
      initialChildSize: 0.1,
      minChildSize: 0.1,
      maxChildSize: (MediaQuery.of(context).size.height -
              (Platform.isIOS ? MediaQuery.of(context).padding.top + 50 : MediaQuery.of(context).padding.top + 60)) /
          MediaQuery.of(context).size.height,
      builder: (BuildContext context, ScrollController scrollController) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.5),
                spreadRadius: 5,
                blurRadius: 7,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: CustomScrollView(
            controller: scrollController,
            slivers: [
              SliverPersistentHeader(
                delegate: _SliverAppBarDelegate(
                  minHeight: 60,
                  maxHeight: 70,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        height: 4,
                        width: 40,
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                        ),
                      ),
                      SizedBox(
                        height: 30,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${Get.find<MapCntr>().addr1.value} ${Get.find<MapCntr>().addr2.value}',
                              style: const TextStyle(
                                fontSize: 15,
                                height: 1.0,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            Text(
                              '총 ${Get.find<MapCntr>().listItems.length}개',
                              style: const TextStyle(
                                fontSize: 12,
                                height: 1.0,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              StreamBuilder<List<BoardWeatherListData>>(
                stream: Get.find<MapCntr>().listItemsController.stream,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return SliverFillRemaining(
                      child: Center(child: Text('Error: ${snapshot.error}')),
                    );
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const SliverFillRemaining(
                      child: Center(child: Text('데이터가 없습니다.')),
                    );
                  } else {
                    return SliverGrid(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.5,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 0,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          if (index < snapshot.data!.length) {
                            return _buildGridItem(
                              snapshot.data![index],
                              Get.find<MapCntr>().southWest.value!,
                              Get.find<MapCntr>().northEast.value!,
                              Get.find<MapCntr>().searchDay.value,
                            );
                          } else {
                            return const Center(child: CircularProgressIndicator());
                          }
                        },
                        childCount: snapshot.data!.length + (Get.find<MapCntr>().isLoadingList.value ? 1 : 0),
                      ),
                    );
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // 아래 바텅시트 리스트
  Widget _buildGridItem(BoardWeatherListData item, LatLng southWest, LatLng northEast, int searchDay) {
    return GestureDetector(
      onTap: () async {
        // var (southWest, northEast) = await getbounds();
        Get.toNamed('/VideoMyinfoListPage', arguments: {
          'datatype': 'LOCAL',
          'custId': Get.find<AuthCntr>().resLoginData.value.custId.toString(),
          'boardId': item.boardId.toString(),
          'southWest': southWest,
          'northEast': northEast,
          'searchDay': searchDay,
        });
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Stack(
            children: [
              AspectRatio(
                  aspectRatio: 0.68,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(10.0),
                      image: DecorationImage(
                        image: CachedNetworkImageProvider(cacheKey: item.thumbnailPath, item.thumbnailPath!),
                        fit: BoxFit.cover,
                      ),
                    ),
                  )
                  // child: CachedNetworkImage(
                  //   key: Key(item.boardId.toString()),
                  //   imageUrl: item.thumbnailPath!,
                  //   fit: BoxFit.cover,
                  // ),
                  ),
              Positioned(
                bottom: 5,
                left: 5,
                child: Row(
                  children: [
                    const Icon(Icons.favorite, color: Colors.white, size: 15),
                    Text(' ${item.likeCnt.toString()}',
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w400)),
                  ],
                ),
              ),
              Positioned(
                bottom: 5,
                right: 5,
                child: Text('조회수 ${item.viewCnt.toString()}',
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w400)),
              ),
              item.hideYn == 'Y'
                  ? const Positioned(
                      top: 10,
                      left: 10,
                      child: Icon(Icons.lock, color: Colors.red, size: 20),
                    )
                  : const SizedBox.shrink(),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(1),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: const Icon(Icons.location_on, color: Colors.white, size: 15),
                      ),
                      const SizedBox(width: 5),
                      SizedBox(
                        width: 100,
                        child: TextScroll(
                          item.location.toString(),
                          mode: TextScrollMode.endless,
                          numberOfReps: 20000,
                          fadedBorder: true,
                          delayBefore: const Duration(milliseconds: 4000),
                          pauseBetween: const Duration(milliseconds: 2000),
                          velocity: const Velocity(pixelsPerSecond: Offset(100, 0)),
                          style: const TextStyle(fontSize: 13, color: Colors.black, fontWeight: FontWeight.w500),
                          textAlign: TextAlign.right,
                          selectable: true,
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    // SizedBox(
                    //   height: 20,
                    //   child: TextButton(
                    //     style: TextButton.styleFrom(
                    //       padding: EdgeInsets.zero,
                    //       minimumSize: Size.zero,
                    //     ),
                    //     onPressed: () => Get.toNamed('/OtherInfoPage/${item.custId.toString()}'),
                    //     child: Text(
                    //       '@${item.nickNm == null ? item.custNm.toString() : item.nickNm.toString()}',
                    //       style: const TextStyle(
                    //         fontWeight: FontWeight.bold,
                    //         fontSize: 12.0,
                    //         color: Colors.black87,
                    //       ),
                    //     ),
                    //   ),
                    // ),
                    // const Padding(
                    //   padding: EdgeInsets.symmetric(horizontal: 6.0),
                    //   child: Text(
                    //     '·',
                    //     style: TextStyle(color: Colors.black87, fontSize: 12),
                    //   ),
                    // ),
                    Text(
                      Utils.timeage(item.crtDtm.toString()),
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w400, color: Colors.black),
                    ),
                  ],
                ),
                Text(
                  item.contents.toString() == 'null' ? '' : item.contents.toString(),
                  // 'asdjfjkasdf as;dkfj asdkja s;dfja;skljfa;skdjfa;skljf;asjf asdklfj asf asdkfa sdfa askdfa sdkfas;kdjfas',
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.justify,
                  maxLines: 2,
                  softWrap: true,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: Colors.black),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate({
    required this.minHeight,
    required this.maxHeight,
    required this.child,
  });
  final double minHeight;
  final double maxHeight;
  final Widget child;

  @override
  double get minExtent => minHeight;
  @override
  double get maxExtent => maxHeight;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return SizedBox.expand(child: child);
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return maxHeight != oldDelegate.maxHeight || minHeight != oldDelegate.minHeight || child != oldDelegate.child;
  }
}
