import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:project1/utils/log_utils.dart';

class KakaoRepo {
  // kakao 개발자 사이트에서 발급받은 REST API 키를 입력 https://developers.kakao.com/console/app/1049247/config/appKey
  // kakao Rest API key 로 입력
  static const String _apiKey = '70e4b88482c00c397ad1022108f02dfc';

  Future<List<Map<String, dynamic>>> getCoordinates(String query) async {
    String apiUrl = 'https://dapi.kakao.com/v2/local/search/keyword.json?page=1&size=15&sort=accuracy';

    final response = await http.get(
      Uri.parse('$apiUrl&query=$query'),
      headers: {
        'Authorization': 'KakaoAK $_apiKey',
        'Cache-Control': 'max-age=31536000, stale-while-revalidate=86400, stale-if-error=604800, immutable, public',
        'Vary': 'Accept-Encoding, User-Agent',
        // 'ETag': '"<unique-identifier-for-this-version-of-the-resource>"',
        'Expires': '${DateTime.now().add(const Duration(days: 365)).toUtc()}',
        'Last-Modified': '${DateTime.now().toUtc()}',
        'Pragma': 'cache',
      },
    );

    // 전체 응답 바디 로깅은 검색 키 입력마다 대용량 JSON 문자열을 만들어 비용이 큼 → 상태코드만.
    Lo.g('kakao response status: ${response.statusCode}');

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['documents'].isNotEmpty) {
        return List<Map<String, dynamic>>.from(data['documents']);
      } else {
        throw Exception('No results found');
      }
    } else {
      throw Exception('Failed to load data');
    }
  }

  // 좌표로 주소 가져오기
  /*
  {
  "meta": {
    "total_count": 1
  },
  "documents": [
    {
      "road_address": {
        "address_name": "경기도 안성시 죽산면 죽산초교길 69-4",
        "region_1depth_name": "경기",
        "region_2depth_name": "안성시",
        "region_3depth_name": "죽산면",
        "road_name": "죽산초교길",
        "underground_yn": "N",
        "main_building_no": "69",
        "sub_building_no": "4",
        "building_name": "무지개아파트",
        "zone_no": "17519"
      },
      "address": {
        "address_name": "경기 안성시 죽산면 죽산리 343-1",
        "region_1depth_name": "경기",
        "region_2depth_name": "안성시",
        "region_3depth_name": "죽산면 죽산리",
        "mountain_yn": "N",
        "main_address_no": "343",
        "sub_address_no": "1",
      }
    }
  ]
}

https://developers.kakao.com/docs/latest/ko/local/dev-guide#coord-to-address
  */

  Future<(String, String, String)> getAddressbylatlon(double lat, double lon) async {
    try {
      // 1차: 도로명/지번 주소(coord2address). 바다·간척지 등 주소 없는 좌표(영종도 앞 등)는
      // documents가 빈 배열로 와, 기존 코드가 documents[0]에서 RangeError로 크래시 →
      // onValue1='' → 그 위치의 동네이름·미세먼지가 항상 빈응답으로 실패하던 원인이었다.
      final addr = await _kakaoRegion(
          'https://dapi.kakao.com/v2/local/geo/coord2address.json', lat, lon,
          fromAddress: true);
      if (addr != null) return addr;

      // 2차 폴백: 행정구역(coord2regioncode). 주소 없는 좌표도 시도/구/동을 반환하므로
      // 바다 근처에서도 시도(예: 인천광역시)를 확보 → 백엔드 정규화로 미세먼지 조회 가능.
      final region = await _kakaoRegion(
          'https://dapi.kakao.com/v2/local/geo/coord2regioncode.json', lat, lon,
          fromAddress: false);
      if (region != null) return region;

      return ('', '', '');
    } catch (e) {
      Lo.g('getAddressbylatlon 오류 ($lat, $lon): $e');
      return ('', '', '');
    }
  }

  // 카카오 좌표→지역 공통 조회. fromAddress=true면 coord2address(문서 하위 address),
  // false면 coord2regioncode(문서 최상위 region_*)에서 시도/구/동을 안전 추출한다.
  // documents 빈 배열/누락, address null 을 모두 방어해 크래시 없이 null 을 반환한다.
  Future<(String, String, String)?> _kakaoRegion(String apiUrl, double lat, double lon,
      {required bool fromAddress}) async {
    final uri = Uri.parse('$apiUrl?input_coord=WGS84&x=$lon&y=$lat');
    lo.g('kakao url : $uri');
    final response = await http.get(uri, headers: {'Authorization': 'KakaoAK $_apiKey'});
    Lo.g('kakao response status: ${response.statusCode}');
    if (response.statusCode != 200) return null;

    final docs = json.decode(response.body)['documents'];
    if (docs is! List || docs.isEmpty) return null;

    // coord2regioncode는 법정동(B)/행정동(H) 두 건이 올 수 있어 법정동(B) 우선 선택.
    Map<String, dynamic>? pick;
    for (final d in docs) {
      if (d is Map<String, dynamic>) {
        if (!fromAddress && d['region_type'] == 'B') {
          pick = d;
          break;
        }
        pick ??= d;
      }
    }
    if (pick == null) return null;

    final src = fromAddress ? pick['address'] : pick;
    if (src is! Map) return null; // coord2address에서 address 가 null 인 경우 방어
    return (
      (src['region_1depth_name'] ?? '').toString(),
      (src['region_2depth_name'] ?? '').toString(),
      (src['region_3depth_name'] ?? '').toString(),
    );
  }
}
