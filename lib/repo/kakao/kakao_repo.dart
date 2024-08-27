import 'dart:convert';
import 'dart:ffi';

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

    Lo.g('response : ${response.body} ');

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
    String apiUrl = 'https://dapi.kakao.com/v2/local/geo/coord2address.json?input_coord=WGS84';
    lo.g("kakao url : ${Uri.parse('$apiUrl&x=$lon&y=$lat')}");
    final response = await http.get(
      Uri.parse('$apiUrl&x=$lon&y=$lat'),
      // 캐쉬설정
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

    Lo.g('response : ${response.body} ');

    if (response.statusCode == 200) {
      String doo = json.decode(response.body)['documents'][0]['address']['region_1depth_name'];
      String si = json.decode(response.body)['documents'][0]['address']['region_2depth_name'];
      String gu = json.decode(response.body)['documents'][0]['address']['region_3depth_name'];

      return (doo, si, gu);
    } else {
      // throw Exception('Failed to load data');
      return ('', '', '');
    }
  }
}
