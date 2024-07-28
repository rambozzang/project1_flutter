// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

/*
/// coord : {"lon":9.19,"lat":45.4642}
/// weather : [{"id":802,"main":"Clouds","description":"구름조금","icon":"03d"}]
/// base : "stations"
/// main : {"temp":18.73,"feels_like":17.94,"temp_min":17.67,"temp_max":20.4,"pressure":1023,"humidity":49}
/// visibility : 10000
/// wind : {"speed":3.09,"deg":90}
/// clouds : {"all":40}
/// dt : 1651140421
/// sys : {"type":2,"id":2012644,"country":"IT","sunrise":1651119376,"sunset":1651170299}
/// timezone : 7200
/// id : 3173435
/// name : "Milan"
/// cod : 200
*/

class CurrentWeatherData {
  String? fcstDate;
  String? fcsTime;
  double? lat;
  double? lon;
  String? cityName; // 지역명
  String? temp; // 현재기온
  String? maxTemp; // 현재기온
  String? minTemp; // 현재기온
  String? sky; // 하늘상태
  String? skyDesc; // 하늘상태
  String? rain; // 강수형태
  String? rainDesc; // 강수확률
  String? speed; // 풍속
  String? deg; // 풍향
  String? humidity; // 습도
  String? pressure; // 기압
  String? visibility; // 가시거리
  String? sunrise; // 일출
  String? rain1h; // 강수량1시간
  String? rainPo; // 강수확률
  String? description; // 날씨설명
  CurrentWeatherData({
    this.fcstDate,
    this.fcsTime,
    this.lat,
    this.lon,
    this.cityName,
    this.temp,
    this.maxTemp,
    this.minTemp,
    this.sky,
    this.skyDesc,
    this.rain,
    this.rainDesc,
    this.speed,
    this.deg,
    this.humidity,
    this.pressure,
    this.visibility,
    this.sunrise,
    this.rain1h,
    this.rainPo,
    this.description,
  });

  CurrentWeatherData copyWith({
    String? fcstDate,
    String? fcsTime,
    double? lat,
    double? lon,
    String? cityName,
    String? temp,
    String? maxTemp,
    String? minTemp,
    String? sky,
    String? skyDesc,
    String? rain,
    String? rainDesc,
    String? speed,
    String? deg,
    String? humidity,
    String? pressure,
    String? visibility,
    String? sunrise,
    String? rain1h,
    String? rainPo,
    String? description,
  }) {
    return CurrentWeatherData(
      fcstDate: fcstDate ?? this.fcstDate,
      fcsTime: fcsTime ?? this.fcsTime,
      lat: lat ?? this.lat,
      lon: lon ?? this.lon,
      cityName: cityName ?? this.cityName,
      temp: temp ?? this.temp,
      maxTemp: maxTemp ?? this.maxTemp,
      minTemp: minTemp ?? this.minTemp,
      sky: sky ?? this.sky,
      skyDesc: skyDesc ?? this.skyDesc,
      rain: rain ?? this.rain,
      rainDesc: rainDesc ?? this.rainDesc,
      speed: speed ?? this.speed,
      deg: deg ?? this.deg,
      humidity: humidity ?? this.humidity,
      pressure: pressure ?? this.pressure,
      visibility: visibility ?? this.visibility,
      sunrise: sunrise ?? this.sunrise,
      rain1h: rain1h ?? this.rain1h,
      rainPo: rainPo ?? this.rainPo,
      description: description ?? this.description,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'fcstDate': fcstDate,
      'fcsTime': fcsTime,
      'lat': lat,
      'lon': lon,
      'cityName': cityName,
      'temp': temp,
      'maxTemp': maxTemp,
      'minTemp': minTemp,
      'sky': sky,
      'skyDesc': skyDesc,
      'rain': rain,
      'rainDesc': rainDesc,
      'speed': speed,
      'deg': deg,
      'humidity': humidity,
      'pressure': pressure,
      'visibility': visibility,
      'sunrise': sunrise,
      'rain1h': rain1h,
      'rainPo': rainPo,
      'description': description,
    };
  }

  factory CurrentWeatherData.fromMap(Map<String, dynamic> map) {
    return CurrentWeatherData(
      fcstDate: map['fcstDate'] != null ? map['fcstDate'] as String : null,
      fcsTime: map['fcsTime'] != null ? map['fcsTime'] as String : null,
      lat: map['lat'] != null ? map['lat'] as double : null,
      lon: map['lon'] != null ? map['lon'] as double : null,
      cityName: map['cityName'] != null ? map['cityName'] as String : null,
      temp: map['temp'] != null ? map['temp'] as String : null,
      maxTemp: map['maxTemp'] != null ? map['maxTemp'] as String : null,
      minTemp: map['minTemp'] != null ? map['minTemp'] as String : null,
      sky: map['sky'] != null ? map['sky'] as String : null,
      skyDesc: map['skyDesc'] != null ? map['skyDesc'] as String : null,
      rain: map['rain'] != null ? map['rain'] as String : null,
      rainDesc: map['rainDesc'] != null ? map['rainDesc'] as String : null,
      speed: map['speed'] != null ? map['speed'] as String : null,
      deg: map['deg'] != null ? map['deg'] as String : null,
      humidity: map['humidity'] != null ? map['humidity'] as String : null,
      pressure: map['pressure'] != null ? map['pressure'] as String : null,
      visibility: map['visibility'] != null ? map['visibility'] as String : null,
      sunrise: map['sunrise'] != null ? map['sunrise'] as String : null,
      rain1h: map['rain1h'] != null ? map['rain1h'] as String : null,
      rainPo: map['rainPo'] != null ? map['rainPo'] as String : null,
      description: map['description'] != null ? map['description'] as String : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory CurrentWeatherData.fromJson(String source) => CurrentWeatherData.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'CurrentWeatherData(fcstDate: $fcstDate, fcsTime: $fcsTime, lat: $lat, lon: $lon, cityName: $cityName, temp: $temp, maxTemp: $maxTemp, minTemp: $minTemp, sky: $sky, skyDesc: $skyDesc, rain: $rain, rainDesc: $rainDesc, speed: $speed, deg: $deg, humidity: $humidity, pressure: $pressure, visibility: $visibility, sunrise: $sunrise, rain1h: $rain1h, rainPo: $rainPo, description: $description)';
  }

  @override
  bool operator ==(covariant CurrentWeatherData other) {
    if (identical(this, other)) return true;

    return other.fcstDate == fcstDate &&
        other.fcsTime == fcsTime &&
        other.lat == lat &&
        other.lon == lon &&
        other.cityName == cityName &&
        other.temp == temp &&
        other.maxTemp == maxTemp &&
        other.minTemp == minTemp &&
        other.sky == sky &&
        other.skyDesc == skyDesc &&
        other.rain == rain &&
        other.rainDesc == rainDesc &&
        other.speed == speed &&
        other.deg == deg &&
        other.humidity == humidity &&
        other.pressure == pressure &&
        other.visibility == visibility &&
        other.sunrise == sunrise &&
        other.rain1h == rain1h &&
        other.rainPo == rainPo &&
        other.description == description;
  }

  @override
  int get hashCode {
    return fcstDate.hashCode ^
        fcsTime.hashCode ^
        lat.hashCode ^
        lon.hashCode ^
        cityName.hashCode ^
        temp.hashCode ^
        maxTemp.hashCode ^
        minTemp.hashCode ^
        sky.hashCode ^
        skyDesc.hashCode ^
        rain.hashCode ^
        rainDesc.hashCode ^
        speed.hashCode ^
        deg.hashCode ^
        humidity.hashCode ^
        pressure.hashCode ^
        visibility.hashCode ^
        sunrise.hashCode ^
        rain1h.hashCode ^
        rainPo.hashCode ^
        description.hashCode;
  }
}
