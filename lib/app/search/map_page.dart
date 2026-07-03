import 'dart:async';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart'; // 임시 주석 처리
import 'package:gap/gap.dart';
import 'package:get/get.dart';
import 'package:project1/app/auth/cntr/auth_cntr.dart';
import 'package:project1/app/search/cntr/map_cntr.dart';
import 'package:project1/app/search/map_search_page.dart';
import 'package:project1/app/weather/models/geocode.dart';
import 'package:project1/app/weathergogo/services/weather_data_processor.dart';
import 'package:project1/repo/board/data/board_weather_list_data.dart';
import 'package:project1/app/weathergogo/cntr/weather_gogo_cntr.dart';
import 'package:project1/root/cntr/root_cntr.dart';
import 'package:project1/utils/StringUtils.dart';
import 'package:project1/utils/log_utils.dart';
import 'package:project1/utils/utils.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

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
  // 지도 초기화 완료 여부. 전체를 Obx로 감싸면 position.value 변경(카메라 이동마다)에
  // NaverMap까지 재빌드돼 깜빡이므로, isInit을 1회 플래그로 받아 정적 build 로 전환한다.
  bool _ready = false;
  Worker? _initWorker;

  // ── 마커 증분 관리 ──
  // 지도를 움직일 때 전체 마커를 재생성하지 않고, boardId 기준으로 신규만 추가/이탈만 제거한다.
  final Map<String, NClusterableMarker> _activeMarkers = {}; // 현재 지도에 올라간 마커(boardId → 마커)
  final Map<String, NOverlayImage> _iconCache = {}; // 썸네일 URL → 아이콘(다운로드 재사용)
  int _markerSyncToken = 0; // 빠른 연속 이동 시 최신 동기화만 반영
  Timer? _cameraDebounce; // 카메라 멈춘 뒤에만 재조회
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

    // 초기화 완료 시 1회만 setState → 이후 카메라 이동에도 지도 스택은 재빌드되지 않음.
    _ready = mapCntr.isInit.value;
    if (!_ready) {
      _initWorker = ever<bool>(mapCntr.isInit, (v) {
        if (v && mounted && !_ready) setState(() => _ready = true);
      });
    }
  }

  // 동영상 비디오 재생
  Future<void> videoPlay(String boardId, String videoPath) async {
    final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
    final lastModified = _formatHttpDate(sevenDaysAgo);

    // 이전 컨트롤러 정리(마커 연속 탭 시 컨트롤러 누수 방지)
    if (initialized) {
      try {
        await videoCntroller.pause();
        await videoCntroller.dispose();
      } catch (_) {}
    }
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

  // 카카오 검색창에서 검색후 클릭시 위치로 이동 → 그 지점 기준으로 재조회
  Future<void> locationUpdate(GeocodeData geocodeData) async {
    final currentCoord = NLatLng(geocodeData.latLng.latitude, geocodeData.latLng.longitude);
    await mapCntr.setPositionlocationUpdate(currentCoord: currentCoord);
    // 카메라 이동이 끝나면 onCameraIdle 이 재조회를 트리거하지만,
    // 검색은 명시적 액션이므로 즉시 한 번 조회해 반응성을 높인다.
    final list = await mapCntr.fetchBoards(mapCntr.searchDay.value);
    await _syncMarkers(list);
  }

  // 기간 버튼(오늘/일주일/한달) 및 최초 진입에서 호출.
  Future<void> loadBoards(int sDay, {bool initial = false}) async {
    final list = await mapCntr.fetchBoards(sDay, initial: initial);
    await _syncMarkers(list);
  }

  // 카메라가 멈춘 뒤(디바운스) 현재 보이는 영역으로 재조회 → 증분 동기화
  void _onCameraIdle() {
    _cameraDebounce?.cancel();
    _cameraDebounce = Timer(const Duration(milliseconds: 600), () async {
      if (!mounted) return;
      final list = await mapCntr.fetchBoards(mapCntr.searchDay.value);
      if (mounted) await _syncMarkers(list);
    });
  }

  // 마커 증분 동기화: 신규 boardId만 생성, 목록에서 빠진 마커만 제거, 기존은 유지(재생성 안 함).
  Future<void> _syncMarkers(List<BoardWeatherListData> list) async {
    if (!mounted) return;
    final token = ++_markerSyncToken;

    // 유효한 항목만 boardId 로 수집
    final incoming = <String, BoardWeatherListData>{};
    for (final e in list) {
      final id = e.boardId?.toString();
      if (id != null && e.lat != null && e.lon != null) incoming[id] = e;
    }

    // 1. 더 이상 목록에 없는 마커 제거
    final toRemove = _activeMarkers.keys.where((id) => !incoming.containsKey(id)).toList();
    for (final id in toRemove) {
      final m = _activeMarkers.remove(id);
      if (m != null) {
        try {
          await mapCntr.mapController.deleteOverlay(m.info);
        } catch (_) {}
      }
    }

    // 2. 신규 마커만 생성(8개씩 병렬 다운로드 → 배치 단위로 한 번에 addOverlayAll)
    //    개별 addOverlay(플랫폼 채널 N회) 대신 addOverlayAll(1회)로 채널 왕복을 줄인다.
    final newItems = incoming.entries.where((en) => !_activeMarkers.containsKey(en.key)).map((en) => en.value).toList();
    const batchSize = 8;
    for (var i = 0; i < newItems.length; i += batchSize) {
      if (token != _markerSyncToken || !mounted) return; // 더 최신 동기화 시작됨 → 중단
      final chunk = newItems.skip(i).take(batchSize).toList();
      final markers = await Future.wait(chunk.map(_createMarker));
      if (token != _markerSyncToken || !mounted) return;
      final toAdd = <NAddableOverlay>{};
      for (final m in markers) {
        if (m == null) continue;
        final id = m.info.id;
        if (_activeMarkers.containsKey(id)) continue;
        _activeMarkers[id] = m;
        toAdd.add(m);
      }
      if (toAdd.isNotEmpty) {
        try {
          await mapCntr.mapController.addOverlayAll(toAdd);
        } catch (_) {}
      }
    }
  }

  // 마커 1개 생성(아이콘은 캐시 우선, 없으면 다운로드해 캐시).
  // 대량 마커 대응: NClusterableMarker 로 만들어 줌아웃 시 자동 병합(클러스터링)되게 한다.
  Future<NClusterableMarker?> _createMarker(BoardWeatherListData element) async {
    try {
      final id = element.boardId.toString();
      final thumb = element.thumbnailPath?.toString() ?? '';
      NOverlayImage? icon = _iconCache[thumb];
      if (icon == null && thumb.isNotEmpty) {
        // 썸네일은 피드가 cached_network_image 로 이미 디스크에 캐시해 둔 것과 동일하므로,
        // 같은 캐시(DefaultCacheManager)에서 파일을 가져와 재다운로드를 피한다.
        // (raw http.get 은 캐시를 무시하고 매번 새로 받으므로 마커 생성이 느렸음)
        final file = await DefaultCacheManager().getSingleFile(thumb).timeout(const Duration(seconds: 8));
        icon = NOverlayImage.fromFile(file); // 바이트를 dart 로 읽지 않고 파일 경로만 넘김(가벼움)
        _iconCache[thumb] = icon;
      }

      final marker = NClusterableMarker(
        id: id,
        position: NLatLng(double.parse(element.lat.toString()), double.parse(element.lon.toString())),
        icon: icon,
        size: size,
        captionOffset: 1,
        isFlat: true,
        caption: NOverlayCaption(text: Utils.timeage(element.crtDtm.toString()), color: Colors.red),
      );
      marker.setOnTapListener((overlay) async {
        // 탭한 마커에만 말풍선 표시(모든 마커에 항상 열어두면 지도가 말풍선 범벅이 됨)
        if (!StringUtils.isEmpty(element.contents)) {
          final info = NInfoWindow.onMarker(alpha: 1, offsetX: 0, id: marker.info.id, text: "${element.contents}");
          marker.openInfoWindow(info);
        }
        videoPlay(element.boardId.toString(), element.videoPath.toString());
        onShowDialog(context, element);
      });
      return marker;
    } catch (err) {
      lo.g('마커 생성 실패 ${element.boardId}: $err');
      return null;
    }
  }

  @override
  void dispose() {
    _initWorker?.dispose();
    _cameraDebounce?.cancel();
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
      body: !_ready
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: NaverMap(
                      // 대량 마커 대응: NClusterableMarker 가 줌 레벨에 따라 자동 병합된다.
                      clusterOptions: const NaverMapClusteringOptions(),
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

                        loadBoards(10, initial: true);
                        mapCntr.mapController.setLocationTrackingMode(NLocationTrackingMode.noFollow);
                      },
                      // 카메라가 멈추면(팬/줌 종료) 현재 보이는 영역으로 증분 재조회
                      onCameraIdle: _onCameraIdle,
                    ),
                  ),
                  // 하단 가로 스트립(지역 영상 목록) — 지도 위 오버레이
                  _buildBottomStrip(),
                  // 기간 필터(오늘/일주일/한달)
                  buildTopButton(),
                  // 검색바(최상단) — 결과 리스트가 다른 오버레이 위에 뜨도록 마지막에 배치
                  MapSearchPage(onSelectClick: locationUpdate),
                ],
              ),
    );
  }

  // 검색바 아래 기간 필터(오늘/일주일/한달) — 세그먼트 pill
  Widget buildTopButton() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 66,
      right: 12,
      child: Obx(() {
        final int sel = mapCntr.searchDay.value;
        return Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 6, offset: const Offset(0, 2))],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _dayChip('오늘', 1, sel == 1),
              _dayChip('일주일', 7, sel == 7),
              _dayChip('한달', 31, sel == 31),
            ],
          ),
        );
      }),
    );
  }

  Widget _dayChip(String label, int day, bool selected) {
    return GestureDetector(
      onTap: () => loadBoards(day),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF4A90E2) : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : Colors.black54,
            fontSize: 12,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
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
                            Get.find<WeatherGogoCntr>().mistData.value.mist10Grade.toString() == 'null'
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

  // ── 하단 가로 스트립: 현재 지도 영역의 영상 목록 ──
  // 기존 무거운 DraggableScrollableSheet(2열 그리드 + 셀마다 무한 마퀴)를 대체.
  // 가로 지연로딩 리스트 + 정적 텍스트로 경량화(항상 보이는 카드만 렌더).
  Widget _buildBottomStrip() {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: StreamBuilder<List<BoardWeatherListData>>(
        stream: mapCntr.listItemsController.stream,
        builder: (context, snapshot) {
          final items = snapshot.data ?? const <BoardWeatherListData>[];
          if (items.isEmpty) return const SizedBox.shrink();
          return Container(
            padding: EdgeInsets.only(top: 10, bottom: MediaQuery.of(context).padding.bottom + 10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [Colors.black.withValues(alpha: 0.30), Colors.transparent],
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: [
                      Obx(() {
                        final name = '${mapCntr.addr1.value} ${mapCntr.addr2.value}'.trim();
                        return _chip(name.isEmpty ? '이 지역' : name);
                      }),
                      const SizedBox(width: 6),
                      _chip('영상 ${items.length}개'),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 150,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, i) => _buildStripCard(items[i]),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _chip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 6)],
      ),
      child: Text(text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.black87)),
    );
  }

  Widget _buildStripCard(BoardWeatherListData item) {
    final thumb = item.thumbnailPath?.toString() ?? '';
    return GestureDetector(
      onTap: () => Get.toNamed('/VideoMyinfoListPage', arguments: {
        'datatype': 'LOCAL',
        'custId': Get.find<AuthCntr>().resLoginData.value.custId.toString(),
        'boardId': item.boardId.toString(),
        'southWest': mapCntr.southWest.value,
        'northEast': mapCntr.northEast.value,
        'searchDay': mapCntr.searchDay.value,
      }),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: 104,
          height: 150,
          child: Stack(
            fit: StackFit.expand,
            children: [
              thumb.isEmpty
                  ? Container(color: Colors.grey.shade300)
                  : CachedNetworkImage(
                      imageUrl: thumb,
                      cacheKey: thumb,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(color: Colors.grey.shade300),
                      errorWidget: (_, __, ___) => Container(color: Colors.grey.shade300),
                    ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  height: 62,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [Colors.black.withValues(alpha: 0.72), Colors.transparent],
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 6,
                right: 6,
                bottom: 6,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.location?.toString() ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.favorite, color: Colors.white, size: 11),
                        Text(' ${item.likeCnt ?? 0}', style: const TextStyle(color: Colors.white, fontSize: 10)),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            Utils.timeage(item.crtDtm.toString()),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.white70, fontSize: 10),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (item.hideYn == 'Y')
                const Positioned(top: 6, left: 6, child: Icon(Icons.lock, color: Colors.redAccent, size: 16)),
            ],
          ),
        ),
      ),
    );
  }

}
