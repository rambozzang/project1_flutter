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
      WeatherGogoRepo repo = WeatherGogoRepo();
      yesterdayWeather.clear();
      // yesterdayWeather = await repo.getYesterDayJson(latLng, isLog: true, isChache: true);
      yesterdayWeather = await weatherService.getWeatherData<List<ItemSuperNct>>(latLng, ForecastType.superNctYesterDay);

      // list 출력
      // yesterdayWeather.forEach((data) => data.category == 'T1H' ? lo.g('${data.baseDate!} ${data.baseTime!}=>${data.obsrValue!}') : null);

      //-----------------------------------------------------------------------------------
      // 어제 날씨와 오늘 날씨 비교
      //-----------------------------------------------------------------------------------

      // list 에서 맨마지막 데이터를 가져온다
      ItemSuperNct lastitem = yesterdayWeather.lastWhere((element) => element.category == 'T1H');
      ItemSuperNct firstitem = yesterdayWeather.firstWhere((element) => element.category == 'T1H');

      // 위 2개 값을 비교값
      double temp = double.parse(firstitem.obsrValue!) - double.parse(lastitem.obsrValue!);
      // temp 값을 소수점 1자리로 반올림 해서 변경
      temp = temp.floorToDouble();

      // yesterdayDesc.value = double.parse(firstitem.obsrValue!) > double.parse(lastitem.obsrValue!) ? '어제보다 $temp° 높아요' : '어제보다 $temp° 낮아요';
      // yesterdayDesc.value = temp == 0.0 ? '어제와 같아요' : yesterdayDesc.value;

      // HourlyWeather 변환
      yesterdayHourlyWeather.clear();

      //  yesterdayWeather.removeAt(0);
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

      // yesterdayHourlyWeather 첫번째가 실제 관측한 날씨 온도
      // oneCallCurrentWeather.value!.temp = yesterdayHourlyWeather[0].temp;

      //2개 리스트 비교해서 같은 시간대를 맞춘다.
      // (List<HourlyWeather>, List<HourlyWeather>) resultList = twicelistCompare(hourlyWeather, yesterdayHourlyWeather);
      // hourlyWeather.clear();
      // yesterdayHourlyWeather.clear();
      // hourlyWeather = resultList.$1.toList();
      // yesterdayHourlyWeather = resultList.$2.toList();
    } catch (e) {
      Lo.g('getYesterdayWeather e =>$e');
      return [];
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
        if (yesterdayWeather.date == weather.date.subtract(const Duration(days: 1)) && yesterdayWeather.date.hour == weather.date.hour) {
          filteredHourlyWeather.add(weather);
          filteredYesterdayHourlyWeather.add(yesterdayWeather);
        }
      }
    }

    // print('Filtered Hourly Weather:');
    // for (var data in filteredHourlyWeather) {
    //   print('${data.date} - ${data.temp}°C');
    // }

    // print('\nFiltered Yesterday Hourly Weather:');
    // for (var data in filteredYesterdayHourlyWeather) {
    //   print('${data.date} - ${data.temp}°C');
    // }

    filteredYesterdayHourlyWeather.reversed.toList();
    return (filteredHourlyWeather, filteredYesterdayHourlyWeather);
  }
}
