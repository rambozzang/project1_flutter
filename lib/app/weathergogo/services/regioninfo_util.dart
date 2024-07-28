import 'package:latlong2/latlong.dart';

class RegionInfo {
  final String regId;
  final String name;
  final LatLng location;

  RegionInfo({required this.regId, required this.name, required this.location});
}

//중기육상 예보 구역 코드
final List<RegionInfo> regionInfoList1 = [
  RegionInfo(regId: '11B00000', name: '서울, 인천, 경기도', location: const LatLng(37.5665, 126.9780)),
  RegionInfo(regId: '11D10000', name: '강원도영서', location: const LatLng(37.8228, 128.1555)),
  RegionInfo(regId: '11D20000', name: '강원도영동', location: const LatLng(37.7510, 128.8760)),
  RegionInfo(regId: '11C20000', name: '대전, 세종, 충청남도', location: const LatLng(36.3504, 127.3845)),
  RegionInfo(regId: '11C10000', name: '충청북도', location: const LatLng(36.6358, 127.4915)),
  RegionInfo(regId: '11F20000', name: '광주, 전라남도', location: const LatLng(35.1595, 126.8526)),
  RegionInfo(regId: '11F10000', name: '전북자치도', location: const LatLng(35.8242, 127.1489)),
  RegionInfo(regId: '11H10000', name: '대구, 경상북도', location: const LatLng(35.8714, 128.6014)),
  RegionInfo(regId: '11H20000', name: '부산, 울산, 경상남도', location: const LatLng(35.1796, 129.0756)),
  RegionInfo(regId: '11G00000', name: '제주도', location: const LatLng(33.4996, 126.5312)),
];
//중기기온 예보 구역 코드
final List<RegionInfo> regionInfoList2 = [
  RegionInfo(regId: '11B10101', name: '서울, 인천, 경기도', location: const LatLng(37.5665, 126.9780)), //서울
  RegionInfo(regId: '11D10401', name: '강원도영서', location: const LatLng(37.8228, 128.1555)), // 원주
  RegionInfo(regId: '11D20501', name: '강원도영동', location: const LatLng(37.7510, 128.8760)), // 강릉
  RegionInfo(regId: '11C20401', name: '대전, 세종, 충청남도', location: const LatLng(36.3504, 127.3845)), // 대전
  RegionInfo(regId: '11C10301', name: '충청북도', location: const LatLng(36.6358, 127.4915)), // 청주
  RegionInfo(regId: '11F20501', name: '광주, 전라남도', location: const LatLng(35.1595, 126.8526)), // 광주
  RegionInfo(regId: '21F20801', name: '전북자치도', location: const LatLng(35.8242, 127.1489)), // 목포
  RegionInfo(regId: '11H10701', name: '대구, 경상북도', location: const LatLng(35.8714, 128.6014)), //대구
  RegionInfo(regId: '11H20201', name: '부산, 울산, 경상남도', location: const LatLng(35.1796, 129.0756)), // 부산
  RegionInfo(regId: '11G00201', name: '제주도', location: const LatLng(33.4996, 126.5312)), // 제주
];

String findNearestRegId(LatLng userLocation, String gubun) {
  RegionInfo nearestRegion = regionInfoList1[0];
  List<RegionInfo> regionInfoList = regionInfoList1;

  // 육상예보 : 1 ,  기온. : 2.
  if (gubun == '2') {
    nearestRegion = regionInfoList2[0];
    regionInfoList = regionInfoList2;
  }

  double minDistance = double.infinity;

  const Distance distance = Distance();

  for (var region in regionInfoList) {
    double currentDistance = distance(userLocation, region.location);
    if (currentDistance < minDistance) {
      minDistance = currentDistance;
      nearestRegion = region;
    }
  }

  return nearestRegion.regId;
}

String getTmFc() {
  final now = DateTime.now();
  DateTime forecastTime;

  if (now.hour < 6) {
    // 00:00 ~ 05:59
    forecastTime = DateTime(now.year, now.month, now.day - 1, 18);
  } else if (now.hour < 18) {
    // 06:00 ~ 17:59
    forecastTime = DateTime(now.year, now.month, now.day, 6);
  } else {
    // 18:00 ~ 23:59
    forecastTime = DateTime(now.year, now.month, now.day, 18);
  }

  // yyyyMMddHHmm 형식으로 반환
  return forecastTime.toString().replaceAll(RegExp(r'[^0-9]'), '').substring(0, 12);
}
