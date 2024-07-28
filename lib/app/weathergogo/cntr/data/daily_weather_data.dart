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
}
