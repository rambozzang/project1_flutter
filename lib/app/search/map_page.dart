import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:gap/gap.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';
import 'package:project1/app/list/cntr/video_list_cntr.dart';
import 'package:project1/app/myinfo/widget/image_avatar.dart';
import 'package:project1/app/search/cctv_page.dart';
import 'package:project1/app/search/cctv_page2.dart';
import 'package:project1/app/search/cctv_seoul_page.dart';
import 'package:project1/app/search/cntr/map_cntr.dart';
import 'package:project1/repo/board/data/board_weather_list_data.dart';
import 'package:project1/repo/cctv/cctv_repo.dart';
import 'package:project1/repo/cctv/data/cctv_res_data.dart';
import 'package:project1/repo/cctv/data/cctv_seoul_req_data.dart';
import 'package:project1/repo/cctv/data/cctv_seoul_res_data.dart';
import 'package:project1/repo/common/res_data.dart';
import 'package:project1/utils/log_utils.dart';
import 'package:text_scroll/text_scroll.dart';
import 'package:video_player/video_player.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final MapCntr mapCntr = Get.find<MapCntr>();
    final VideoListCntr videoListCntr = Get.find<VideoListCntr>();
    return Scaffold(
        // appBar: AppBar(
        //   title: 'aa'
        // ),
        body: Obx(
      () => mapCntr.isInit.value
          ? Stack(
              children: [
                NaverMap(
                  options: NaverMapViewOptions(
                    locationButtonEnable: true,
                    initialCameraPosition: NCameraPosition(
                        target: NLatLng(videoListCntr.position!.latitude, videoListCntr.position!.longitude),
                        zoom: 13,
                        bearing: 0,
                        tilt: 0),
                  ),
                  onMapReady: (controller) {
                    print("네이버 맵 로딩됨!");
                    mapCntr.mapController = controller;
                    // 파란색 점으로 현재위치 표시
                    mapCntr.mapController.setLocationTrackingMode(NLocationTrackingMode.noFollow);
                  },
                ),
                buildTop(videoListCntr, mapCntr),
                buildBottom(mapCntr)
              ],
            )
          : const Center(child: CircularProgressIndicator()),
    ));
  }

  // 상단 앱바
  Widget buildTop(videoListCntr, mapCntr) {
    return Positioned(
        top: 55,
        left: 15,
        right: 1,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    IconButton(onPressed: () => mapCntr.getLocation(), icon: const Icon(Icons.location_on, color: Colors.black)),
                    // Text(videoListCntr.localName.value, style: const TextStyle(color: Colors.black, fontSize: 15)),
                    TextScroll(
                      '${videoListCntr.localName.value.toString()} ',
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
            IconButton(padding: const EdgeInsets.all(0), onPressed: () => Get.back(), icon: const Icon(Icons.close, color: Colors.black)),
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

  // 우측 하단 버튼
  Widget buildBottom(mapCntr) {
    return Positioned(
        bottom: 40,
        right: 10,
        child: Column(
          children: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(0),
                  minimumSize: const Size(50, 30),
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              onPressed: () => mapCntr.getLocation(),
              child: const Text("현재위치", style: TextStyle(color: Colors.black, fontSize: 12)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(0),
                  minimumSize: const Size(50, 30),
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              onPressed: () => buildMarker(context),
              child: const Text("마커", style: TextStyle(color: Colors.black, fontSize: 12)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(0),
                  minimumSize: const Size(50, 30),
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              onPressed: () => getCctv(),
              child: const Text("CCTV", style: TextStyle(color: Colors.black, fontSize: 12)),
            ),
          ],
        ));
  }

  Future<void> buildMarker(BuildContext context) async {
    Size size = const Size(40, 40);
    const iconImage1 = NOverlayImage.fromAssetImage('assets/images/map/fog.png');
    const iconImage2 = NOverlayImage.fromAssetImage('assets/images/map/rain.png');
    const iconImage3 = NOverlayImage.fromAssetImage('assets/images/map/sun1.png');

    Get.find<VideoListCntr>().list.forEach((element) async {
      // final NOverlayImage icon = await buildMarket(size, element, context);
      final NOverlayImage icon = NOverlayImage.fromAssetImage('assets/images/map/blue_pin.png');

      final marker = NMarker(
        id: element.boardId.toString(),
        position: NLatLng(double.parse(element.lat.toString()), double.parse(element.lon.toString())),
        icon: icon,
        size: size,
        captionOffset: 0,
      );
      Get.find<MapCntr>().mapController.addOverlay(marker);
      // final onMarkerInfoWindow = NInfoWindow.onMarker(id: marker.info.id, text: "${element.currentTemp}°");
      // marker.openInfoWindow(onMarkerInfoWindow);
      marker.setOnTapListener((overlay) async {
        onShowDialog(context, element);
      });
    });
  }

  getCctv() async {
    //
    Size size = const Size(30, 30);
    final NLatLngBounds bounds = await Get.find<MapCntr>().mapController.getContentBounds().then((value) {
      lo.g('southWest.latitude : ${value.southWest.latitude}');
      lo.g('southWest.longitude : ${value.southWest.longitude}');
      lo.g('northEast.latitude : ${value.northEast.latitude}');
      lo.g('northEast.longitude : ${value.northEast.longitude}');
      return value;
    });
    // final NCameraPosition _position = await Get.find<MapCntr>().mapController.getCameraPosition().then((value) {
    //   lo.g('zoomLevel : ${value.zoom}');
    //   return value;
    // });
// 126.9858296, 37.55998.
    CctvRepo repo = CctvRepo();
    LatLng southWest = LatLng(bounds.southWest.latitude, bounds.southWest.longitude);
    LatLng northEast = LatLng(bounds.northEast.latitude, bounds.northEast.longitude);
    lo.g('southWest : ${southWest.toString()}');
    lo.g('northEast : ${northEast.toString()}');
    lo.g('Get.find<MapCntr>().position!.latitude : ${Get.find<MapCntr>().position!.latitude}');

    List<CctvResData> res =
        await repo.fetchCctv(southWest, northEast, Get.find<MapCntr>().position!.latitude, Get.find<MapCntr>().position!.longitude);
    lo.g('===>${res.toString()}');
    if (res == []) {
      //  return;
    }
    lo.g(res.length.toString());
    final NOverlayImage icon = NOverlayImage.fromAssetImage('assets/images/map/cctv2.png');

    int markid = 1;
    res.forEach((element) async {
      lo.g('마커 생성 --------------- ${element.cctvname}');
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
        CctvPageBottomSheet().open(context, element);

        // Navigator.push<_MapPageState>(
        //   context,
        //   MaterialPageRoute<_MapPageState>(
        //     builder: (BuildContext context) => CctvPage2(cctvResData: element),
        //   ),
        // );
      });
      markid++;
    });

    // 서울 시내 cctv   southWest, northEast, 37.55998, 126.9858296
    CctvSeoulReqData req = CctvSeoulReqData();
    req.southWestLat = southWest.latitude;
    req.southWestLng = southWest.longitude;
    req.northEastLat = northEast.latitude;
    req.northEastLng = northEast.longitude;
    req.lat = Get.find<MapCntr>().position!.latitude;
    req.lng = Get.find<MapCntr>().position!.longitude;

    ResData res2 = await repo.fetchCctvSeoul(req);
    List<CctvSeoulResData> list = ((res2.data) as List).map((data) => CctvSeoulResData.fromMap(data)).toList();
    list.forEach((element) {
      lo.g('마커 생성 --------------- ${element.cctvname}');
      final marker = NMarker(
        id: element.cctvid.toString(),
        position: NLatLng(double.parse(element.ycoord!), double.parse(element.xcoord!)),
        icon: icon,
        size: size,
        captionOffset: 0,
      );
      Get.find<MapCntr>().mapController.addOverlay(marker);
      // final onMarkerInfoWindow = NInfoWindow.onMarker(id: marker.info.id, text: "${element.cctvname}°");
      // marker.openInfoWindow(onMarkerInfoWindow);
      marker.setOnTapListener((overlay) async {
        CctvSeoulPageBottomSheet().open(context, element);

        // Navigator.push<_MapPageState>(
        //   context,
        //   MaterialPageRoute<_MapPageState>(
        //     builder: (BuildContext context) => CctvSeoulPage(cctvSeoulResData: element),
        //   ),
        // );
      });
      markid++;
    });
  }

  void onShowDialog(context, BoardWeatherListData data) {
    showModalBottomSheet(
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.only(topLeft: Radius.circular(10.0), topRight: Radius.circular(10.0))),
      context: context,
      builder: (BuildContext context) {
        return Padding(
          padding: MediaQuery.of(context).viewInsets,
          child: SizedBox(
            height: 410,
            child: Column(children: [
              Container(
                ///height: 45,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(topLeft: Radius.circular(10.0), topRight: Radius.circular(10.0)),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const SizedBox(width: 10),
                        const Text("서울특별시 강남구", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                        const Spacer(),
                        IconButton(onPressed: () => Get.back(), icon: const Icon(Icons.close, color: Colors.black)),
                        const SizedBox(width: 10),
                      ],
                    ),
                    Row(
                      children: [
                        Container(
                          color: Colors.blue,
                          height: 100,
                          width: 160,
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('${data.city}'),
                              Row(
                                children: [
                                  Text('${data.weatherInfo}'),
                                  const Gap(5),
                                  Text('${data.currentTemp}°'),
                                ],
                              ),

                              Text('${data.distance?.toStringAsFixed(1)}Km'),
                              // Text('@${data.profilePath}'),
                              Row(
                                children: [
                                  ImageAvatar(
                                    url: data.profilePath.toString(),
                                    type: AvatarType.BASIC,
                                  ),
                                  Text('${data.nickNm}'),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              )
            ]),
          ),
        );
      },
    );
  }
}
