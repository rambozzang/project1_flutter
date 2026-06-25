// 스팟(캠핑·낚시·골프 등 야외 장소) 데이터.
// GET /api/spot/list 응답의 각 항목. (WEATHER_ACTIVATION_API_CONTRACT.md 참고)
class SpotData {
  int? spotId;
  String? name;
  String? category; // camping | fishing | golf
  double? lat;
  double? lon;
  int? nx;
  int? ny;
  double? distanceKm;
  int? videoCnt;
  // 현재 날씨(초단기실황 조인)
  String? currentTemp;
  String? sky;
  String? rain;
  String? weatherInfo;

  SpotData({
    this.spotId,
    this.name,
    this.category,
    this.lat,
    this.lon,
    this.nx,
    this.ny,
    this.distanceKm,
    this.videoCnt,
    this.currentTemp,
    this.sky,
    this.rain,
    this.weatherInfo,
  });

  factory SpotData.fromMap(Map<String, dynamic> map) {
    final weather = map['weather'] is Map ? Map<String, dynamic>.from(map['weather'] as Map) : const <String, dynamic>{};
    double? toD(dynamic v) => v == null ? null : (v is num ? v.toDouble() : double.tryParse(v.toString()));
    int? toI(dynamic v) => v == null ? null : (v is num ? v.toInt() : int.tryParse(v.toString()));
    return SpotData(
      spotId: toI(map['spotId']),
      name: map['name']?.toString(),
      category: map['category']?.toString(),
      lat: toD(map['lat']),
      lon: toD(map['lon']),
      nx: toI(map['nx']),
      ny: toI(map['ny']),
      distanceKm: toD(map['distanceKm']),
      videoCnt: toI(map['videoCnt']),
      currentTemp: weather['currentTemp']?.toString(),
      sky: weather['sky']?.toString(),
      rain: weather['rain']?.toString(),
      weatherInfo: weather['weatherInfo']?.toString(),
    );
  }
}
