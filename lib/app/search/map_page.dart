import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:gap/gap.dart';
import 'package:get/get.dart';
import 'package:get/get_state_manager/get_state_manager.dart';
import 'package:latlong2/latlong.dart';
import 'package:project1/app/auth/cntr/auth_cntr.dart';
import 'package:project1/app/search/cctv_page.dart';
import 'package:project1/app/search/cntr/map_cntr.dart';
import 'package:project1/app/search/map_search_page.dart';
import 'package:project1/app/weather/models/geocode.dart';
import 'package:project1/repo/board/board_repo.dart';
import 'package:project1/repo/board/data/board_weather_list_data.dart';
import 'package:project1/repo/cctv/cctv_repo.dart';
import 'package:project1/repo/cctv/data/cctv_res_data.dart';
import 'package:project1/repo/common/res_data.dart';
import 'package:project1/app/weathergogo/cntr/weather_gogo_cntr.dart';
import 'package:project1/utils/log_utils.dart';
import 'package:project1/utils/utils.dart';
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

  Duration position = Duration.zero;

  // 검색어 Data
  int seachDay = 10;

  @override
  void initState() {
    super.initState();
    topheight = Platform.isIOS ? 55 : 0;
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
    var mapCntr = Get.find<MapCntr>();
    final locationOverlay = mapCntr.mapController.getLocationOverlay();
    const iconImage = NOverlayImage.fromAssetImage('assets/images/map/default_pin.png');
    locationOverlay
      ..setIcon(iconImage)
      ..setIconSize(const Size.fromRadius(40))
      ..setCircleRadius(100.0)
      ..setCircleColor(Colors.grey.withOpacity(0.17))
      ..setPosition(currentCoord)
      ..setIsVisible(true);

    final cameraUpdate = NCameraUpdate.withParams(target: currentCoord)
      ..setAnimation(animation: NCameraAnimation.linear, duration: const Duration(milliseconds: 500)); // 2초는 너무 길 수도 있어요.
    await mapCntr.mapController.updateCamera(cameraUpdate);

    final marker = NMarker(
      id: geocodeData.latLng.longitude.toString(),
      position: NLatLng(double.parse(geocodeData.latLng.latitude.toString()), double.parse(geocodeData.latLng.longitude.toString())),
      icon: iconImage,
      size: const Size(25, 25),
      captionOffset: 10,
      caption: NOverlayCaption(text: geocodeData.name.toString()),
    );

    // marker.openInfoWindow(NInfoWindow.onMarker(offsetX: 10, id: marker.info.id, text: geocodeData.name));
    mapCntr.mapController.addOverlay(marker);
    buildMarker(context);
  }

  @override
  void dispose() {
    if (initialized) {
      videoCntroller.pause();
      videoCntroller.dispose();
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        resizeToAvoidBottomInset: false,
        body: Obx(
          () => Get.find<MapCntr>().isInit.value
              ? Stack(
                  children: [
                    NaverMap(
                      options: NaverMapViewOptions(
                        locationButtonEnable: true,
                        initialCameraPosition: NCameraPosition(
                            target: NLatLng(Get.find<WeatherGogoCntr>().currentLocation.value!.latLng.latitude,
                                Get.find<WeatherGogoCntr>().currentLocation!.value!.latLng.longitude),
                            zoom: 13,
                            bearing: 0,
                            tilt: 0),
                      ),
                      onMapReady: (controller) {
                        print("네이버 맵 로딩됨!");

                        Get.find<MapCntr>().mapController = controller;

                        //  Get.find<MapCntr>().getLocation();
                        locationUpdate(Get.find<WeatherGogoCntr>().currentLocation.value!);

                        // 파란색 점으로 현재위치 표시
                        Get.find<MapCntr>().mapController.setLocationTrackingMode(NLocationTrackingMode.noFollow);
                      },
                    ),
                    //   buildTop(),
                    buildBottom(),
                    MapSearchPage(onSelectClick: locationUpdate),
                  ],
                )
              : const Center(child: CircularProgressIndicator()),
        ));
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
                  // border: Border.all(color: Colors.black),

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
                        onPressed: () => Get.find<MapCntr>().getLocation(), icon: const Icon(Icons.location_on, color: Colors.black)),
                    // Text(videoListCntr.localName.value, style: const TextStyle(color: Colors.black, fontSize: 15)),
                    TextScroll(
                      '${Get.find<WeatherGogoCntr>().currentLocation.value!.name.toString()} ',
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

  // 우측 하단 버튼
  Widget buildBottom() {
    return Positioned(
        bottom: 50,
        right: 16,
        child: Column(
          children: [
            // ValueListenableBuilder<double>(
            //   valueListenable: isSlider,
            //   builder: (context, value, child) {
            //     return SizedBox(
            //       height: 350,
            // child: RotatedBox(
            //   quarterTurns: 3,
            //   child: Slider(
            //     value: value,
            //     min: 0,
            //     max: 5,
            //     divisions: 1,
            //     label: '${value.round()}일',
            //     onChanged: (double value) {
            //       //  setState(() {
            //       isSlider.value = value;
            //       seachDay = value.round();
            //       //});
            //       buildMarker(context);
            //     },
            //     activeColor: Colors.blue,
            //     inactiveColor: Colors.grey.shade300,
            //   ),
            // ),

            // child: SfSlider(
            //   min: 1.0,
            //   max: 5.0,
            //   value: value,
            //   interval: 1.0,
            //   showTicks: true,
            //   activeColor: Colors.blueGrey,
            //   inactiveColor: Colors.grey.shade300,
            //   labelPlacement: LabelPlacement.onTicks,
            //   dividerShape: SfDividerShape(),
            //   shouldAlwaysShowTooltip: true,
            //   stepSize: 1.0,
            //   showLabels: true,
            //   enableTooltip: true,
            //   minorTicksPerInterval: 1,
            //   onChanged: (dynamic values) {
            //     isSlider.value = values;
            //     seachDay = values.start.toInt();
            //     buildMarker(context);
            //   },
            // ),
            //     );
            //   },
            // ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(5),
                  minimumSize: const Size(70, 40),
                  backgroundColor: Colors.white,
                  elevation: 5,
                  shadowColor: Colors.grey,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5))),
              onPressed: () => buildMarker(context),
              child: const Text("근처영상보기", style: TextStyle(color: Colors.black, fontSize: 12)),
            ),
          ],
        ));
  }

  // 일반 동영상 마커 생성 하기
  Future<void> buildMarker(BuildContext context) async {
    Size size = const Size(45, 60);
    var mapCntr = Get.find<MapCntr>();

    var (southWest, northEast) = await getbounds();
    // 현재 그려진 마커 삭제
    mapCntr.mapController.clearOverlays();

    BoardRepo boardRepo = BoardRepo();
    ResData resListData = await boardRepo.searchBoardListByMaplonlatAndDay(southWest, northEast, seachDay, 0, 200);
    if (resListData.code != '00') {
      Utils.alert(resListData.msg.toString());
      return;
    }
    List<BoardWeatherListData> _list = ((resListData.data) as List).map((data) => BoardWeatherListData.fromMap(data)).toList();

    _list.forEach((element) async {
      // final NOverlayImage icon = await buildMarket(size, element, context);
      // NOverlayImage icon = const NOverlayImage.fromAssetImage('assets/images/map/blue_pin.png');
      // final request = await http.get(Uri.parse(element.profilePath.toString()));
      final request = await http.get(Uri.parse(element.thumbnailPath.toString()));
      final icon = await NOverlayImage.fromByteArray(request.bodyBytes);

      final marker = NMarker(
        id: element.boardId.toString(),
        position: NLatLng(double.parse(element.lat.toString()), double.parse(element.lon.toString())),
        icon: icon,
        size: size,
        captionOffset: 10,
        caption: NOverlayCaption(text: element.nickNm.toString()),
      );
      mapCntr.mapController.addOverlay(marker);
      final onMarkerInfoWindow =
          NInfoWindow.onMarker(offsetX: 0, id: marker.info.id, text: "${element.nickNm}·${Utils.timeage(element.crtDtm.toString())}");

      marker.openInfoWindow(onMarkerInfoWindow);
      marker.setOnTapListener((overlay) async {
        videoPlay(element.boardId.toString(), element.videoPath.toString());
        onShowDialog(context, element);
      });
    });
    if (_list.length == 0) {
      Utils.alert('근처에 영상이 없습니다.');
    }
    // Utils.alert('마커 생성 완료');
  }

  // 지역 및 서울 cctv 마커 생성
  Future<void> getCctv() async {
    //
    Size size = const Size(30, 30);
    var (southWest, northEast) = await getbounds();

    lo.g('southWest : ${southWest.toString()}');
    lo.g('northEast : ${northEast.toString()}');
    lo.g('Get.find<MapCntr>().position!.latitude : ${Get.find<MapCntr>().position!.latitude}');

    CctvRepo repo = CctvRepo();
    List<CctvResData> res =
        await repo.fetchCctv(southWest, northEast, Get.find<MapCntr>().position!.latitude, Get.find<MapCntr>().position!.longitude);
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

  Future<(LatLng, LatLng)> getbounds() async {
    final NLatLngBounds bounds = await Get.find<MapCntr>().mapController.getContentBounds().then((value) {
      lo.g('southWest.latitude : ${value.southWest.latitude}');
      lo.g('southWest.longitude : ${value.southWest.longitude}');
      lo.g('northEast.latitude : ${value.northEast.latitude}');
      lo.g('northEast.longitude : ${value.northEast.longitude}');
      return value;
    });
    LatLng southWest = LatLng(bounds.southWest.latitude, bounds.southWest.longitude);
    LatLng northEast = LatLng(bounds.northEast.latitude, bounds.northEast.longitude);
    return (southWest, northEast);
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
                    const Gap(5),
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
                            Row(
                              children: [
                                SizedBox(
                                  width: 25,
                                  child: CircleAvatar(
                                    radius: 16,
                                    backgroundColor: Colors.grey[100],
                                    child: ClipOval(
                                      child: CachedNetworkImage(
                                        cacheKey: data.custId.toString(),
                                        imageUrl: data.profilePath.toString(), //  'https://picsum.photos/200/300',
                                        width: 23,
                                        height: 23,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                ),
                                const Gap(5),
                                Flexible(
                                  child: Text(data.nickNm.toString(),
                                      overflow: TextOverflow.clip,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87)),
                                ),
                              ],
                            ),
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
                                      child: const Icon(Icons.location_on, color: Colors.white, size: 15)),
                                  const SizedBox(width: 5),
                                  Flexible(
                                    child: Text(data.location.toString(),
                                        overflow: TextOverflow.clip,
                                        style: const TextStyle(fontSize: 13, color: Colors.black, fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              ),
                            ),
                            Row(
                              children: [
                                Text('${data.currentTemp.toString()}°C',
                                    overflow: TextOverflow.clip,
                                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black)),
                                // CachedNetworkImage(
                                //   width: 50,
                                //   height: 50,
                                //   imageUrl: 'http://openweathermap.org/img/wn/${data.icon ?? '10n'}@2x.png',
                                //   imageBuilder: (context, imageProvider) => Container(
                                //     decoration: BoxDecoration(
                                //       image: DecorationImage(
                                //           image: imageProvider,
                                //           fit: BoxFit.cover,
                                //           colorFilter: const ColorFilter.mode(Colors.transparent, BlendMode.colorBurn)),
                                //     ),
                                //   ),
                                //   placeholder: (context, url) => const CircularProgressIndicator(strokeWidth: 1, color: Colors.white),
                                //   errorWidget: (context, url, error) => const Icon(Icons.error),
                                // ),
                              ],
                            ),
                            Text(
                              data.weatherInfo.toString(),
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black),
                              overflow: TextOverflow.clip,
                            ),
                            const Gap(6),
                            Get.find<WeatherGogoCntr>().mistData.value!.mist10Grade.toString() == 'null' ||
                                    Get.find<WeatherGogoCntr>().mistData.value!.mist25Grade.toString() == null
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
                                        buildTextMist(Get.find<WeatherGogoCntr>().mistData.value!.mist10Grade.toString()),
                                        const TextSpan(
                                          text: ' 초미세',
                                          style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13, color: Colors.black),
                                        ),
                                        buildTextMist(Get.find<WeatherGogoCntr>().mistData.value!.mist25Grade.toString()),
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
                  height: 80,
                  padding: const EdgeInsets.symmetric(horizontal: 1, vertical: 5),
                  alignment: Alignment.topLeft,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(color: Colors.grey.withOpacity(0.2)),
                    // color: ,
                  ),
                  child: Text(
                    // '2phpasidhfakjshfsdf asdhf alksdf va sdflasdhf. askldfhalsdhjf asd faskdf vajdsf asdkjfhalsdhfalksdhfa lsdfkh. asldkfhalsdf alsdf 2phpasidhfakjshfsdf asdhf alksdf va sdflasdhf. askldfhalsdhjf asd faskdf vajdsf asdkjfhalsdhfalksdhfa lsdfkh. asldkfhalsdf alsdf ',
                    data.contents.toString(),
                    style: const TextStyle(fontSize: 16, color: Colors.black),
                    overflow: TextOverflow.clip,
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
    /*
      if (value >= 0 && value <= 30) {
      return '좋음';
    } else if (value >= 31 && value <= 80) {
      return '보통';
    } else if (value >= 81 && value <= 150) {
      return '나쁨';
    } else {Widget buildBottom() {
  return Positioned(
    bottom: 40,
    left: 16,
    right: 16,
    child: Column(
      children: [
        // 기존 버튼들...
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.5),
                spreadRadius: 1,
                blurRadius: 7,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            children: [
              Text(
                '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Slider(
                value: selectedDate.millisecondsSinceEpoch.toDouble(),
                min: startDate.millisecondsSinceEpoch.toDouble(),
                max: endDate.millisecondsSinceEpoch.toDouble(),
                onChanged: (value) {
                  setState(() {
                    selectedDate = DateTime.fromMillisecondsSinceEpoch(value.toInt());
                  });
                  // 여기에 선택된 날짜에 따른 마커 업데이트 로직을 추가할 수 있습니다.
                  updateMarkersForDate(selectedDate);
                },
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

      return '매우나쁨';
    }
    */
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
}
