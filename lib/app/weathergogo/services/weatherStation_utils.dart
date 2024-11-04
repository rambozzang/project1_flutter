import 'dart:math';

import 'package:flutter/foundation.dart';

class WeatherStation {
  final String stnId;
  final String name;
  final double latitude;
  final double longitude;

  WeatherStation(this.stnId, this.name, this.latitude, this.longitude);
}

class WeatherStationFinder {
  static final List<WeatherStation> stations = [
    WeatherStation('090', '속초', 38.2508, 128.5647),
    WeatherStation('095', '철원', 38.1479, 127.3042),
    WeatherStation('098', '동두천', 37.9019, 127.0606),
    WeatherStation('099', '파주', 37.8856, 126.7664),
    WeatherStation('100', '대관령', 37.6771, 128.7185),
    WeatherStation('101', '춘천', 37.9026, 127.7357),
    WeatherStation('102', '백령도', 37.9741, 124.6307),
    WeatherStation('104', '북강릉', 37.8047, 128.8554),
    WeatherStation('105', '강릉', 37.7513, 128.8909),
    WeatherStation('106', '동해', 37.5075, 129.1243),
    WeatherStation('108', '서울', 37.5714, 126.9658),
    WeatherStation('112', '인천', 37.4775, 126.6247),
    WeatherStation('114', '원주', 37.3375, 127.9466),
    WeatherStation('115', '울릉도', 37.4813, 130.8986),
    WeatherStation('119', '수원', 37.2723, 126.9848),
    WeatherStation('121', '영월', 37.1812, 128.4568),
    WeatherStation('127', '충주', 36.9707, 127.9526),
    WeatherStation('129', '서산', 36.7766, 126.4939),
    WeatherStation('130', '울진', 36.9918, 129.4128),
    WeatherStation('131', '청주', 36.6392, 127.4404),
    WeatherStation('133', '대전', 36.3721, 127.3725),
    WeatherStation('135', '추풍령', 36.2203, 127.9944),
    WeatherStation('136', '안동', 36.5728, 128.7072),
    WeatherStation('137', '상주', 36.4067, 128.1489),
    WeatherStation('138', '포항', 36.0326, 129.3795),
    WeatherStation('140', '군산', 36.0054, 126.7614),
    WeatherStation('143', '대구', 35.8782, 128.6526),
    WeatherStation('146', '전주', 35.8215, 127.1547),
    WeatherStation('152', '울산', 35.5601, 129.3205),
    WeatherStation('155', '창원', 35.1704, 128.5729),
    WeatherStation('156', '광주', 35.1731, 126.8942),
    WeatherStation('159', '부산', 35.1047, 129.0328),
    WeatherStation('162', '통영', 34.8455, 128.4356),
    WeatherStation('165', '목포', 34.8167, 126.3812),
    WeatherStation('168', '여수', 34.7393, 127.7406),
    WeatherStation('169', '흑산도', 34.6872, 125.4511),
    WeatherStation('170', '완도', 34.3959, 126.7019),
    WeatherStation('172', '고창', 35.3465, 126.5991),
    WeatherStation('174', '순천', 35.0747, 127.2387),
    WeatherStation('177', '홍성', 36.6581, 126.6708),
    WeatherStation('184', '제주', 33.5141, 126.5297),
    WeatherStation('185', '고산', 33.2938, 126.1628),
    WeatherStation('188', '성산', 33.3868, 126.8802),
    WeatherStation('189', '서귀포', 33.2461, 126.5653),
    WeatherStation('192', '진주', 35.2084, 128.1193),
    WeatherStation('201', '강화', 37.7074, 126.4463),
    WeatherStation('202', '양평', 37.4886, 127.4944),
    WeatherStation('203', '이천', 37.2641, 127.4842),
    WeatherStation('211', '인제', 38.0600, 128.1671),
    WeatherStation('212', '홍천', 37.6836, 127.8804),
    WeatherStation('216', '태백', 37.1013, 128.9889),
    WeatherStation('217', '정선군', 37.3809, 128.6640),
    WeatherStation('221', '제천', 37.1593, 128.1943),
    WeatherStation('226', '보은', 36.4875, 127.7342),
    WeatherStation('232', '천안', 36.7796, 127.1211),
    WeatherStation('235', '보령', 36.3272, 126.5575),
    WeatherStation('236', '부여', 36.2725, 126.9206),
    WeatherStation('238', '금산', 36.1059, 127.4814),
    WeatherStation('239', '세종', 36.5641, 127.2986),
    WeatherStation('243', '부안', 35.7294, 126.7165),
    WeatherStation('244', '임실', 35.6120, 127.2858),
    WeatherStation('245', '정읍', 35.5639, 126.8661),
    WeatherStation('247', '남원', 35.4056, 127.3328),
    WeatherStation('248', '장수', 35.6573, 127.5205),
    WeatherStation('251', '고창군', 35.4336, 126.7020),
    WeatherStation('252', '영광군', 35.2774, 126.4789),
    WeatherStation('253', '김해시', 35.2384, 128.8893),
    WeatherStation('254', '순창군', 35.3744, 127.1231),
    WeatherStation('255', '북창원', 35.2267, 128.6823),
    WeatherStation('257', '양산시', 35.3097, 129.0203),
    WeatherStation('258', '보성군', 34.7633, 127.2123),
    WeatherStation('259', '강진군', 34.6419, 126.7681),
    WeatherStation('260', '장흥', 34.6886, 126.9195),
    WeatherStation('261', '해남', 34.5535, 126.5687),
    WeatherStation('262', '고흥', 34.6183, 127.2757),
    WeatherStation('263', '의령군', 35.3226, 128.2933),
    WeatherStation('264', '함양군', 35.5153, 127.7447),
    WeatherStation('266', '광양시', 34.9426, 127.6911),
    WeatherStation('268', '진도군', 34.4730, 126.3234),
    WeatherStation('271', '봉화', 36.9438, 128.9145),
    WeatherStation('272', '영주', 36.8720, 128.5169),
    WeatherStation('273', '문경', 36.6272, 128.1487),
    WeatherStation('276', '청송군', 36.4358, 129.0573),
    WeatherStation('277', '영덕', 36.5331, 129.4097),
    WeatherStation('278', '의성', 36.3561, 128.6885),
    WeatherStation('279', '구미', 36.1306, 128.3205),
    WeatherStation('281', '영천', 35.9776, 128.9514),
    WeatherStation('283', '경주시', 35.8431, 129.2122),
    WeatherStation('284', '거창', 35.6713, 127.9097),
    WeatherStation('285', '합천', 35.5654, 128.1669),
    WeatherStation('288', '밀양', 35.4915, 128.7441),
    WeatherStation('289', '산청', 35.4130, 127.8791),
    WeatherStation('294', '거제', 34.8823, 128.6048),
    WeatherStation('295', '남해', 34.8166, 127.9262)
  ];

  static final Map<String, String> regionCodes = {
    '서울특별시': '11',
    '부산광역시': '26',
    '대구광역시': '27',
    '인천광역시': '28',
    '광주광역시': '29',
    '대전광역시': '30',
    '울산광역시': '31',
    '세종특별자치시': '36',
    '경기도': '41',
    '강원도': '42',
    '충청북도': '43',
    '충청남도': '44',
    '전라북도': '45',
    '전라남도': '46',
    '경상북도': '47',
    '경상남도': '48',
    '제주특별자치도': '50'
  };

  static double _calculateDistance(lat1, lon1, lat2, lon2) {
    const R = 6371; // 지구의 반경 (km)
    var dLat = _toRadians(lat2 - lat1);
    var dLon = _toRadians(lon2 - lon1);
    var a = sin(dLat / 2) * sin(dLat / 2) + cos(_toRadians(lat1)) * cos(_toRadians(lat2)) * sin(dLon / 2) * sin(dLon / 2);
    var c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  static double _toRadians(double degree) {
    return degree * pi / 180;
  }

  static Future<Map<String, String>> findNearestStation(double latitude, double longitude) async {
    try {
      WeatherStation nearestStation = await compute(_findNearest, [latitude, longitude]);
      String regionCode = _getRegionCode(nearestStation.name);

      return {'stnId': nearestStation.stnId, 'regionCode': regionCode, 'stationName': nearestStation.name};
    } catch (e) {
      print('Error finding nearest station: $e');
      return {'error': 'Failed to find nearest station'};
    }
  }

  static WeatherStation _findNearest(List<double> params) {
    double latitude = params[0];
    double longitude = params[1];
    WeatherStation nearestStation = stations[0];
    double minDistance = double.infinity;

    for (var station in stations) {
      double distance = _calculateDistance(latitude, longitude, station.latitude, station.longitude);
      if (distance < minDistance) {
        minDistance = distance;
        nearestStation = station;
      }
    }

    return nearestStation;
  }

  static String _getRegionCode(String stationName) {
    // 간단한 매핑. 실제로는 더 복잡할 수 있습니다.
    if (stationName == '서울') return regionCodes['서울특별시']!;
    if (stationName == '부산') return regionCodes['부산광역시']!;
    if (stationName == '대구') return regionCodes['대구광역시']!;
    if (stationName == '인천') return regionCodes['인천광역시']!;
    if (stationName == '광주') return regionCodes['광주광역시']!;
    if (stationName == '대전') return regionCodes['대전광역시']!;
    if (stationName == '울산') return regionCodes['울산광역시']!;
    if (stationName == '세종') return regionCodes['세종특별자치시']!;
    // 나머지 지역은 더 세밀한 매핑이 필요할 수 있습니다.
    return regionCodes['경기도']!; // 기본값
  }
}
