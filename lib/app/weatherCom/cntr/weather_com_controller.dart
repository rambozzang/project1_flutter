import 'dart:collection';

import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:project1/app/weather/models/oneCallCurrentWeather.dart';
import 'package:project1/app/weatherCom/api/AccuWeatherClient.dart';
import 'package:project1/app/weatherCom/api/KmaClient.dart';
import 'package:project1/app/weatherCom/api/MeClient.dart';
import 'package:project1/app/weatherCom/api/TomorrowClient.dart';
import 'package:project1/app/weatherCom/api/WeatherApiClient.dart';
import 'package:project1/app/weatherCom/services/openweathermap_client.dart';
import 'package:project1/app/weathergogo/cntr/weather_gogo_cntr.dart';
import 'package:project1/app/weathergogo/services/weather_data_processor.dart';
import 'package:project1/repo/common/res_data.dart';
import 'package:project1/repo/weather/open_weather_repo.dart';
import 'package:project1/utils/log_utils.dart';
import 'package:project1/utils/utils.dart';
import '../models/weather_data.dart';
import '../services/weather_api_client.dart';

class WeatherComControllerBinding implements Bindings {
  @override
  void dependencies() {
    Get.lazyPut<WeatherComController>(() => WeatherComController([
          OpenWeatherMapClient(apiKey: 'c8bcc177b07a3bbcc9a75d0282c19164'),
          // AccuWeatherClient(apiKey: '9Dpql374txlRZGgiECCDS2gGcvuqdmeT'),
          // WeatherChannelClient(apiKey: 'YOUR_WEATHERCHANNEL_API_KEY'),
          // WeatherNewsClient(apiKey: 'YOUR_WEATHERNEWS_API_KEY'),
          //   KmaClient(apiKey: 'CeGmiV26lUPH9guq1Lca6UA25Al/aZlWD3Bm8kehJ73oqwWiG38eHxcTOnEUzwpXKY3Ur+t2iPaL/LtEQdZebg=='),
        ]));
  }
}

class WeatherComController extends GetxController {
  final List<WeatherApiClient> _clients;

  Map<String, List<WeatherData>> get alignedHourlyData => _getAlignedHourlyData();
  Map<String, List<WeatherData>> get alignedDailyData => _getAlignedDailyData();

  final Rx<LinkedHashMap<String, List<WeatherData>>> _hourlyData = Rx<LinkedHashMap<String, List<WeatherData>>>(LinkedHashMap());
  final Rx<LinkedHashMap<String, List<WeatherData>>> _dailyData = Rx<LinkedHashMap<String, List<WeatherData>>>(LinkedHashMap());

  final List<String> weatherSourcesOrder = ['기상청', 'OpenWeather', 'AccuWeather', 'METNorway', 'Tomorrow.io', 'WeatherAPI'];

  final isLoading = true.obs;

  WeatherComController(this._clients);

  Rx<LinkedHashMap<String, List<WeatherData>>> get hourlyData => _hourlyData;

  Rx<LinkedHashMap<String, List<WeatherData>>> get dailyData => _dailyData;

  // 표 타이틀
  // final List<String> hourlyTimes = [];
  // final List<String> dailyDates = [];
  final RxList<String> hourlyTimes = <String>[].obs;
  final RxList<String> dailyDates = <String>[].obs;
  final List<String> dayParts = ['오전', '오후'];

  var processCount = 0.obs;

  @override
  void onInit() {
    super.onInit();
    fetchAllForecasts();
    // fetchAllForecasts();
  }

  Future<void> fetchAllForecasts() async {
    isLoading.value = true;
    processCount.value = 0;
    try {
      await Future.wait([
        getKcmData(),
        fetchOpenWeatherMap(),
        fetchAccuWeather(),
        fetchMetNorwayWeatherService(),
        fetchTomorrowIoWeatherService(),
        fetchWeatherApiComService(),
      ]);
    } catch (e) {
      // 에러 처리
    } finally {
      isLoading.value = false;
    }
  }

  void logger(String tag) {
    return;
    // hourlyTimes.forEach((element) {
    //   lo.g('hourlyTimes : $element');
    // });
    // dailyDates.forEach((element) {
    //   lo.g('dailyDates : $element');
    // });
    // // _hourlyData 출력
    // _hourlyData.forEach((key, value) {
    //   lo.g('$tag : $key');
    //   value.forEach((element) {
    //     lo.g('hourlyData : ${element.time} temp : ${element.temperature} rain : ${element.rainProbability} source : ${element.source}');
    //   });
    // });
    // // _dailyData 출력
    // _dailyData.forEach((key, value) {
    //   lo.g('$tag : $key');
    //   value.forEach((element) {
    //     lo.g('dailyData : ${element.time} temp : ${element.temperature} rain : ${element.rainProbability} source : ${element.source}');
    //   });
    // });
  }

  // 기상청 데이터 가져오기
  Future<void> getKcmData() async {
    try {
      List<WeatherData> hourlyData = [];
      final DateTime now = DateTime.now().toLocal(); // 현
      // 시가별 데이터
      Get.find<WeatherGogoCntr>().hourlyWeather.where((item) => item.date.isAfter(now)).forEach((element) {
        hourlyData.add(WeatherData(
          time: element.date,
          temperature: element.temp,
          humidity: 0.0,
          rainProbability: double.parse(element.rainPo.toString()) * 0.01,
          source: WeatherDataProcessor.instance.getFinalWeatherIcon(element.sky.toString(), element.rain.toString()),
        ));
        // 기상청데이터기준으로 시간대별 타이틀 생성
        // hourlyTimes.add(DateFormat('H', 'ko').format(element.date));
      });

      addHourlyData('기상청', hourlyData.take(24).toList());

      // 일별 데이터
      List<WeatherData> dailyAmData = [];
      // List<WeatherData> dailyPmData = [];

      int i = 0;
      Get.find<WeatherGogoCntr>().sevenDayWeather.forEach((element) {
        lo.g('dailyData : ${element.fcstDate} ${element.fcstTime}');

        final mIcon = i > 1
            ? WeatherDataProcessor.instance.getWeatherIconForMidtermForecast(element.morning.skyDesc.toString())
            : WeatherDataProcessor.instance.getWeatherGogoImage(element.morning.sky.toString(), element.morning.rain.toString());

        final aIcon = i > 1
            ? WeatherDataProcessor.instance.getWeatherIconForMidtermForecast(element.afternoon.skyDesc.toString())
            : WeatherDataProcessor.instance.getWeatherGogoImage(element.afternoon.sky.toString(), element.afternoon.rain.toString());

        dailyAmData.add(WeatherData(
          time: DateTime.parse('${element.fcstDate} ${element.fcstTime ?? '0000'}'),
          temperature: double.parse(element.morning.temp.toString()),
          humidity: 0.0,
          rainProbability: double.parse(element.morning.rainPo.toString()) * 0.01,
          source: mIcon,
        ));
        dailyAmData.add(WeatherData(
          time: DateTime.parse('${element.fcstDate} ${element.fcstTime ?? '0000'}'),
          temperature: double.parse(element.afternoon.temp.toString()),
          humidity: 0.0,
          rainProbability: double.parse(element.afternoon.rainPo.toString()) * 0.01,
          source: aIcon,
        ));
        i++;
      });

      addDailyData('기상청', dailyAmData);
      _updateHourlyTimes();
      _updateDailyDates();

      logger('kma');
    } catch (e) {
      lo.g('getKcmData() : $e');
    } finally {
      processCount.value++;
      update();
    }
  }

  // openweathermap 데이터 가져오기
  Future<void> fetchOpenWeatherMap() async {
    try {
      OpenWheatherRepo repo = OpenWheatherRepo();

      LatLng location = Get.find<WeatherGogoCntr>().currentLocation.value!.latLng;

      ResData resData = await repo.getOneCallWeather(location);
      if (resData.code != '00') {
        Utils.alert(resData.msg.toString());
        return;
      }
      final dailyData = resData.data as Map<String, dynamic>;

      List hourlyList = dailyData['hourly'];
      List dailyList = dailyData['daily'];

      List<WeatherData> hourlyData = [];
      final DateTime now = DateTime.now().toUtc(); // 현
      hourlyList.where((item) => DateTime.fromMillisecondsSinceEpoch(item['dt'] * 1000).isAfter(now)).take(24).forEach((element) {
        hourlyData.add(WeatherData(
          time: DateTime.fromMillisecondsSinceEpoch(element['dt'] * 1000),
          temperature: double.parse((element['temp']).toString()),
          humidity: double.parse(element['humidity'].toString()),
          rainProbability: double.parse(element['pop'].toString()),
          source: element['weather'][0]['main'], // element['weather'][0]['description'],
        ));
      });

      addHourlyData('OpenWeather', hourlyData);

      List<WeatherData> dailyAmData = [];

      // 오늘 데이터 제거
      dailyList = dailyList.sublist(1);

      dailyList.forEach((element) {
        dailyAmData.add(
          WeatherData(
            time: DateTime.fromMillisecondsSinceEpoch(element['dt'] * 1000),
            temperature: double.parse((element['temp']['morn']).toString()),
            humidity: double.parse(element['humidity'].toString()),
            rainProbability: double.parse(element['pop'].toString()),
            source: element['weather'][0]['main'],
          ),
        );
        dailyAmData.add(
          WeatherData(
            time: DateTime.fromMillisecondsSinceEpoch(element['dt'] * 1000),
            temperature: double.parse((element['temp']['max']).toString()),
            humidity: double.parse(element['humidity'].toString()),
            rainProbability: double.parse(element['pop'].toString()),
            source: element['weather'][0]['main'],
          ),
        );
      });

      addDailyData('OpenWeather', dailyAmData);

      logger('OpenWeatherMap');
      _updateHourlyTimes();
      _updateDailyDates();
    } catch (e) {
      lo.g('fetchOpenWeatherMap() : $e');
    } finally {
      processCount.value++;
      update();
    }
  }

  // MetNorwayWeatherService 데이터 가져오기
  Future<void> fetchMetNorwayWeatherService() async {
    try {
      lo.g('fetchMetNorwayWeatherService() 1111111');
      MetNorwayWeatherService repo = MetNorwayWeatherService();
      LatLng location = Get.find<WeatherGogoCntr>().currentLocation.value!.latLng;
      lo.g('fetchMetNorwayWeatherService() 2222');

      // 시간별 데이터
      List<WeatherData> hourlyData = await repo.getHourlyForecast(location);

      addHourlyData('METNorway', hourlyData);
      lo.g('fetchMetNorwayWeatherService() 33333');

      // 일별 데이터
      final dailyData = await repo.getDailyForecast(location);

      addDailyData('METNorway', dailyData);
    } catch (e) {
      lo.g('fetchMetNorwayWeatherService() : $e');
    } finally {
      _updateHourlyTimes();
      _updateDailyDates();
      logger('MetNorwayWeatherService');
      processCount.value++;
      update();
    }
  }

  // TomorrowIoWeatherService 데이터 가져오기
  Future<void> fetchTomorrowIoWeatherService() async {
    try {
      lo.g('TomorrowIoWeatherService() 1111111');
      TomorrowIoWeatherService repo = TomorrowIoWeatherService();
      LatLng location = Get.find<WeatherGogoCntr>().currentLocation.value!.latLng;
      lo.g('TomorrowIoWeatherService() 2222');

      // 시간별 데이터
      List<WeatherData> hourlyData = await repo.getHourlyForecast(location);

      addHourlyData('Tomorrow.io', hourlyData);
      lo.g('TomorrowIoWeatherService() 33333');

      // 일별 데이터
      final dailyData = await repo.getDailyForecast(location);

      addDailyData('Tomorrow.io', dailyData);
    } catch (e) {
      lo.g('TomorrowIoWeatherService() : $e');
    } finally {
      _updateHourlyTimes();
      _updateDailyDates();
      logger('TomorrowIoWeatherService');
      processCount.value++;
      update();
    }
  }

  // WeatherApiComService 데이터 가져오기
  Future<void> fetchWeatherApiComService() async {
    try {
      lo.g('WeatherApiComService() 1111111');
      WeatherApiComService repo = WeatherApiComService();
      LatLng location = Get.find<WeatherGogoCntr>().currentLocation.value!.latLng;
      lo.g('WeatherApiComService() 2222');

      // 시간별 데이터
      List<WeatherData> hourlyData = await repo.getHourlyForecast(location);

      addHourlyData('WeatherAPI', hourlyData);
      lo.g('WeatherApiComService() 33333');

      // 일별 데이터
      final dailyData = await repo.getDailyForecast(location);

      addDailyData('WeatherAPI', dailyData);
    } catch (e) {
      lo.g('WeatherApiComService() : $e');
    } finally {
      _updateHourlyTimes();
      _updateDailyDates();
      logger('WeatherApiComService');
      processCount.value++;
      update();
    }
  }

  void _updateHourlyTimes() {
    List<String> newHourlyTimes = [];
    if (_hourlyData.value.isNotEmpty) {
      var longestHourlyData = _hourlyData.value.values.reduce((a, b) => a.length > b.length ? a : b);
      newHourlyTimes = longestHourlyData.map((data) => DateFormat('H', 'ko').format(data.time)).toList();
    }
    hourlyTimes.assignAll(newHourlyTimes);
  }

  void _updateDailyDates() {
    List<String> newDailyDates = [];
    if (_dailyData.value.isNotEmpty) {
      var longestDailyData = _dailyData.value.values.reduce((a, b) => a.length > b.length ? a : b);
      newDailyDates = longestDailyData.map((data) => '${DateFormat('dd', 'ko').format(data.time)}').toList();
    }
    // 중복제거
    newDailyDates = newDailyDates.toSet().toList();
    dailyDates.assignAll(newDailyDates);
  }

  Map<String, List<WeatherData>> _getAlignedHourlyData() {
    Map<String, List<WeatherData>> aligned = {};

    Set<DateTime> allTimePoints = {};
    _hourlyData.value.values.forEach((dataList) {
      dataList.forEach((data) {
        allTimePoints.add(DateTime(data.time.year, data.time.month, data.time.day, data.time.hour));
      });
    });

    List<DateTime> sortedTimePoints = allTimePoints.toList()..sort();

    _hourlyData.value.forEach((source, dataList) {
      aligned[source] = List.generate(sortedTimePoints.length, (index) {
        final timePoint = sortedTimePoints[index];
        return dataList.firstWhere(
          (data) =>
              data.time.year == timePoint.year &&
              data.time.month == timePoint.month &&
              data.time.day == timePoint.day &&
              data.time.hour == timePoint.hour,
          orElse: () => WeatherData(
            time: timePoint,
            temperature: double.nan,
            humidity: double.nan,
            rainProbability: double.nan,
            source: source,
          ),
        );
      });
    });

    hourlyTimes.value = sortedTimePoints.map((time) => DateFormat('HH').format(time)).toList();

    return aligned;
  }

  Map<String, List<WeatherData>> _getAlignedDailyData() {
    Map<String, List<WeatherData>> aligned = {};

    Set<DateTime> allDatePoints = {};
    _dailyData.value.values.forEach((dataList) {
      dataList.forEach((data) {
        allDatePoints.add(DateTime(data.time.year, data.time.month, data.time.day));
      });
    });

    List<DateTime> sortedDatePoints = allDatePoints.toList()..sort();

    _dailyData.value.forEach((source, dataList) {
      aligned[source] = [];
      for (var date in sortedDatePoints) {
        var dayData =
            dataList.where((data) => data.time.year == date.year && data.time.month == date.month && data.time.day == date.day).toList();

        if (dayData.isEmpty) {
          aligned[source]!.add(WeatherData(
            time: DateTime(date.year, date.month, date.day, 9),
            temperature: double.nan,
            humidity: double.nan,
            rainProbability: double.nan,
            source: source,
          ));
          aligned[source]!.add(WeatherData(
            time: DateTime(date.year, date.month, date.day, 15),
            temperature: double.nan,
            humidity: double.nan,
            rainProbability: double.nan,
            source: source,
          ));
        } else if (dayData.length == 1) {
          aligned[source]!.add(dayData[0]);
          aligned[source]!.add(WeatherData(
            time: DateTime(date.year, date.month, date.day, 15),
            temperature: double.nan,
            humidity: double.nan,
            rainProbability: double.nan,
            source: source,
          ));
        } else {
          aligned[source]!.addAll(dayData.take(2));
        }
      }
    });

    dailyDates.value = sortedDatePoints.map((date) => DateFormat('MM/dd(EE)', 'ko').format(date)).toList();

    return aligned;
  }

  // AccuWeather 데이터 가져오기
  Future<void> fetchAccuWeather() async {
    try {
      AccuWeatherClient repo = AccuWeatherClient();
      LatLng location = Get.find<WeatherGogoCntr>().currentLocation.value!.latLng;

      // 시간별 데이터
      List<WeatherData> hourlyData = await repo.getForecast(location);

      addHourlyData('AccuWeather', hourlyData);

      // 일별 데이터
      final dailyData = await repo.getFiveDayForecast(location);

      addDailyData('AccuWeather', dailyData);
    } catch (e) {
      lo.g('fetchAccuWeather() : $e');
    } finally {
      _updateHourlyTimes();
      _updateDailyDates();
      logger('AccuWeather');
      processCount.value++;
      update();
    }
  }

  // 시간별 데이터 추가 메서드
  void addHourlyData(String source, List<WeatherData> data) {
    _hourlyData.value[source] = data;
    _sortData(_hourlyData);
  }

  // 일별 데이터 추가 메서드
  void addDailyData(String source, List<WeatherData> data) {
    _dailyData.value[source] = data;
    _sortData(_dailyData);
  }

  // 데이터 정렬 메서드
  void _sortData(Rx<LinkedHashMap<String, List<WeatherData>>> data) {
    final sortedMap = LinkedHashMap<String, List<WeatherData>>.fromEntries(
        weatherSourcesOrder.where((source) => data.value.containsKey(source)).map((source) => MapEntry(source, data.value[source]!)));
    data.value = sortedMap;
  }

  // Future<void> fetchAllForecasts() async {
  //   _isLoading.value = true;
  //   try {
  //     for (var client in _clients) {
  //       final forecast = await client.getForecast();
  //       _forecasts[client.sourceName] = forecast;
  //     }
  //     // _forecasts 출력
  //     _forecasts.forEach((key, value) => Lo.g('$key: $value'));
  //   } catch (e) {
  //     print('Error fetching forecasts: $e');
  //     Get.snackbar('Error', 'Failed to fetch weather data');
  //   }
  //   _isLoading.value = false;
  // }
}
