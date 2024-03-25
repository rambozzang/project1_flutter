// https://www.data.go.kr/data/15101106/openapi.do?recommendDataYn=Y
// 7C166CC8-B88A-3DD1-816A-FF86922C17AF
// 지번
// https://apis.vworld.kr/coord2jibun.do?x=126.961862449327&y=37.3952998720615&output=xml&epsg=epsg:4326&apiKey=[KEY]
// 도로
// https://apis.vworld.kr/coord2new.do?x=126.961862449327&y=37.3952998720615&output=xml&epsg=epsg:4326&apiKey=[KEY]
class VworldApiConfig {
  static const String apiKey = '7C166CC8-B88A-3DD1-816A-FF86922C17AF';
  static const String apiUrl = 'https://apis.vworld.kr/coord2jibun.do';
  // static const String apiUrl = 'https://apis.vworld.kr/coord2new.do';
}
