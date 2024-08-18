import 'package:latlong2/latlong.dart';
import 'package:project1/app/weathergogo/cntr/data/hourly_weather_data.dart';
import 'package:project1/repo/weather_gogo/models/response/super_nct/super_nct_model.dart';
import 'package:project1/repo/weather_gogo/repository/weather_gogo_caching.dart';
import 'package:project1/repo/weather_gogo/repository/weather_gogo_repo.dart';
import 'package:project1/utils/log_utils.dart';

class YesterdayHourlyWeatherService {
  //어제 날씨 정보 가져오기
  Future<List<HourlyWeatherData>> getYesterdayWeather(LatLng latLng) async {
    //어제 날씨 정보
    late List<ItemSuperNct> yesterdayWeather = [];
    List<HourlyWeatherData> yesterdayHourlyWeather = [];

    WeatherService weatherService = WeatherService();
    try {
      yesterdayWeather.clear();
      yesterdayWeather = await weatherService.getWeatherData<List<ItemSuperNct>>(latLng, ForecastType.superNctYesterDay);
      // list 출력
      // yesterdayWeather.forEach((data) => data.category == 'T1H' ? lo.g('${data.baseDate!} ${data.baseTime!}=>${data.obsrValue!}') : null);
      for (ItemSuperNct item in yesterdayWeather) {
        if (item.category == 'T1H') {
          HourlyWeatherData hourlyWeather = HourlyWeatherData(
            temp: double.parse(item.obsrValue!),
            sky: '',
            rain: '',
            date: DateTime.parse('${item.baseDate!} ${item.baseTime!}'),
          );

          yesterdayHourlyWeather.add(hourlyWeather);
        }
      }
      return yesterdayHourlyWeather;
    } catch (e) {
      Lo.g('getYesterdayWeather e =>$e');
      return getYesterdayWeather(latLng);
    }
  }

  double compareTempData(List<HourlyWeatherData> list) {
    // 위 2개 값을 비교값
    double temp = double.parse(list.last.temp.toString()) - double.parse(list.first.temp.toString());
    // temp 값을 소수점 1자리
    return double.parse(temp.toStringAsFixed(1));
  }

  // 2개 리스트 비교해서 같은 시간대를 맞춘다. 최대한 데이터를 보존한다.
  (List<HourlyWeatherData>, List<HourlyWeatherData>) twicelistCompare(
      List<HourlyWeatherData> hourlyWeather, List<HourlyWeatherData> yesterdayHourlyWeather) {
    List<HourlyWeatherData> filteredHourlyWeather = [];
    List<HourlyWeatherData> filteredYesterdayHourlyWeather = [];

    for (var weather in hourlyWeather) {
      for (var yesterdayWeather in yesterdayHourlyWeather) {
        if (yesterdayWeather.date.day == (weather.date.subtract(const Duration(days: 1))).day &&
            yesterdayWeather.date.hour == weather.date.hour) {
          filteredHourlyWeather.add(weather);
          filteredYesterdayHourlyWeather.add(yesterdayWeather);
        }
      }
    }

    filteredYesterdayHourlyWeather = filteredYesterdayHourlyWeather.reversed.toList();
    return (filteredHourlyWeather, filteredYesterdayHourlyWeather);
  }
}
