class DayWeatherData {
  String? temp;
  String? minTemp;
  String? maxTemp;
  String? sky;
  String? skyDesc;
  String? rain;
  String? rainDesc;
  String? speed;
  String? deg;
  String? humidity;
  String? rainPo;

  DayWeatherData({
    this.temp,
    this.minTemp,
    this.maxTemp,
    this.sky,
    this.skyDesc,
    this.rain,
    this.rainDesc,
    this.speed,
    this.deg,
    this.humidity,
    this.rainPo,
  });

  Map<String, dynamic> toMap() => {
        'temp': temp,
        'minTemp': minTemp,
        'maxTemp': maxTemp,
        'sky': sky,
        'skyDesc': skyDesc,
        'rain': rain,
        'rainDesc': rainDesc,
        'speed': speed,
        'deg': deg,
        'humidity': humidity,
        'rainPo': rainPo,
      };

  factory DayWeatherData.fromMap(Map<String, dynamic> map) => DayWeatherData(
        temp: map['temp'] as String?,
        minTemp: map['minTemp'] as String?,
        maxTemp: map['maxTemp'] as String?,
        sky: map['sky'] as String?,
        skyDesc: map['skyDesc'] as String?,
        rain: map['rain'] as String?,
        rainDesc: map['rainDesc'] as String?,
        speed: map['speed'] as String?,
        deg: map['deg'] as String?,
        humidity: map['humidity'] as String?,
        rainPo: map['rainPo'] as String?,
      );
}

class SevenDayWeather {
  double? lat;
  double? lon;
  String? cityName;
  String? fcstDate;
  String? fcstTime;
  DayWeatherData morning;
  DayWeatherData afternoon;

  SevenDayWeather({
    this.lat,
    this.lon,
    this.cityName,
    this.fcstDate,
    this.fcstTime,
    required this.morning,
    required this.afternoon,
  });

  Map<String, dynamic> toMap() => {
        'lat': lat,
        'lon': lon,
        'cityName': cityName,
        'fcstDate': fcstDate,
        'fcstTime': fcstTime,
        'morning': morning.toMap(),
        'afternoon': afternoon.toMap(),
      };

  factory SevenDayWeather.fromMap(Map<String, dynamic> map) => SevenDayWeather(
        lat: (map['lat'] as num?)?.toDouble(),
        lon: (map['lon'] as num?)?.toDouble(),
        cityName: map['cityName'] as String?,
        fcstDate: map['fcstDate'] as String?,
        fcstTime: map['fcstTime'] as String?,
        morning: map['morning'] == null
            ? DayWeatherData()
            : DayWeatherData.fromMap(Map<String, dynamic>.from(map['morning'] as Map)),
        afternoon: map['afternoon'] == null
            ? DayWeatherData()
            : DayWeatherData.fromMap(Map<String, dynamic>.from(map['afternoon'] as Map)),
      );
}
