import 'dart:async';

import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:project1/app/test/weather_compare_data.dart';
import 'package:project1/app/weather/cntr/weather_cntr.dart';
import 'package:project1/app/weather/models/hourlyWeather.dart';
import 'package:project1/repo/weather_accu/accu_repo.dart';
import 'package:project1/repo/weather_accu/accu_res_data.dart';
import 'package:project1/repo/weather_gogo/interface/imp_fct_repository.dart';
import 'package:project1/repo/weather_gogo/models/request/weather.dart';
import 'package:project1/repo/weather_gogo/models/response/fct/fct_model.dart';
import 'package:project1/utils/log_utils.dart';
import 'package:project1/widget/custom_badge.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';

class WeatherComparePage extends StatefulWidget {
  const WeatherComparePage({super.key});

  @override
  State<WeatherComparePage> createState() => _WeatherComparePageState();
}

class _WeatherComparePageState extends State<WeatherComparePage> {
  late LatLng latlng;

  StreamController<List<WeatherCompareData>> accuStreamController = StreamController<List<WeatherCompareData>>();
  StreamController<List<WeatherCompareData>> koreaStreamController = StreamController<List<WeatherCompareData>>();
  StreamController<List<WeatherCompareData>> openStreamController = StreamController<List<WeatherCompareData>>();

  ValueNotifier<bool> isLoading = ValueNotifier<bool>(false);

  List<WeatherCompareData> allWeatherCompareList = [];

  // 상단 그리드
  List<GridColumn> gridColumnList = <GridColumn>[];

  late EmployeeDataSource employeeDataSource;

  @override
  void initState() {
    super.initState();
    getData();
  }

  Future getData() async {
    isLoading.value = true;
    latlng = Get.find<WeatherCntr>().currentLocation.value!.latLng;
    // 아큐웨더 API 호출
    AccuRepo repo = AccuRepo();
    String locationKey = await repo.getLocation(latlng);
    List<AccuResData> accuList = await repo.get12HoursWeather(locationKey);
    List<WeatherCompareData> accuWeatherCompareList = [];
    // accuList -> accuWeatherCompareList 변환
    accuList.map((e) {
      accuWeatherCompareList.add(WeatherCompareData(
        provider: '아큐',
        hour: e.DateTime.toString(),
        temp: e.Temperature?.Value.toString(),
        icon: e.WeatherIcon.toString(),
        desc: e.IconPhrase.toString(),
      ));
    }).toList();

    allWeatherCompareList.addAll(accuWeatherCompareList);
    accuWeatherCompareList.forEach((e) => lo.g('아큐 => ${e.hour} : ${e.temp} : ${e.desc} : ${e.icon}'));
    // ---------------------------------------

    // 기상청 API 호출
    String _key = 'CeGmiV26lUPH9guq1Lca6UA25Al/aZlWD3Bm8kehJ73oqwWiG38eHxcTOnEUzwpXKY3Ur+t2iPaL/LtEQdZebg==';
    final weather = Weather(
      serviceKey: _key,
      pageNo: 1,
      numOfRows: 12 * 24, //기준시간별 항목이 12개이므로 24시간치 데이터를 가져오기 위해 12 * 24
    );
    final List<ItemFct> items = [];
    // 단기예보 조회
    final json = await FctRepositoryImp(isLog: false).getItemListJSON(weather);
    json.map((e) => items.add(e)).toList();
    List<WeatherCompareData> fctWeatherCompareList = [];
    // items -> fctWeatherCompareList 변환
    items.map((e) {
      String time = e.fcstDate! + e.fcstTime!;

      if (e.category == 'TMP') {
        fctWeatherCompareList.add(WeatherCompareData(
          provider: '기상청',
          hour: e.fcstTime,
          temp: e.fcstValue.toString(),
          icon: '',
          desc: '',
        ));
      }
    }).toList();
    allWeatherCompareList.addAll(fctWeatherCompareList);
    fctWeatherCompareList.forEach((e) => lo.g('기상청 => ${e.hour} : ${e.temp} : ${e.desc} : ${e.icon}'));
    // 상단 그리드는 기상청을 기준으로
    // gridColumnList
    fctWeatherCompareList.forEach((e) {
      lo.g('기상청 => ${e.hour} : ${e.temp} : ${e.desc} : ${e.icon}');
      gridColumnList.add(
        GridColumn(
          columnName: '${e.hour}',
          label: Container(
            padding: const EdgeInsets.all(16.0),
            alignment: Alignment.center,
            child: Text(
              '${e.hour}',
            ),
          ),
        ),
      );
    });

    // 오픈웨더 API 호출
    List<HourlyWeather> list = Get.find<WeatherCntr>().hourlyWeather;
    List<WeatherCompareData> openWeatherCompareList = [];
    // list -> openWeatherCompareList 변환
    list.map((e) {
      openWeatherCompareList.add(WeatherCompareData(
        provider: '오픈웨더',
        hour: DateFormat('a hh:mm ', 'ko').format(e.date).toString(), // DateTime.fromMillisecondsSinceEpoch(json['dt'] * 1000),
        temp: e.temp.toString(),
        icon: e.weatherCategory.toLowerCase(),
        desc: e.weatherCategory.toLowerCase(),
      ));
    }).toList();

    allWeatherCompareList.addAll(openWeatherCompareList);

    allWeatherCompareList.sort((a, b) => a.hour!.compareTo(b.hour!));
    openWeatherCompareList.forEach((e) => lo.g('오픈웨더 =>${e.hour} : ${e.temp} : ${e.desc} : ${e.icon}'));

    isLoading.value = false;
    employeeDataSource = EmployeeDataSource(data: fctWeatherCompareList);

    lo.g('accuWeatherCompareList.length : ${accuWeatherCompareList.length}');
    lo.g('fctWeatherCompareList.length : ${fctWeatherCompareList.length}');
    lo.g('openWeatherCompareList.length : ${openWeatherCompareList.length}');
    lo.g('allWeatherCompareList.length : ${allWeatherCompareList.length}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Syncfusion Flutter DataGrid'),
      ),
      body: ValueListenableBuilder<bool>(
          valueListenable: isLoading,
          builder: (context, value, child) {
            if (value) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }
            return SfDataGrid(
              frozenColumnsCount: 1,
              source: employeeDataSource,
              columnWidthMode: ColumnWidthMode.fill,
              columns: <GridColumn>[
                GridColumn(
                  columnName: 'date',
                  label: Container(
                    padding: const EdgeInsets.all(16.0),
                    alignment: Alignment.center,
                    child: const Text(
                      '오늘',
                    ),
                  ),
                ),
                ...gridColumnList,
              ],
            );
          }),
    );
  }
}

/// An object to set the employee collection data source to the datagrid. This
/// is used to map the employee data to the datagrid widget.
class EmployeeDataSource extends DataGridSource {
  /// Creates the employee data source class with required details.
  EmployeeDataSource({required List<WeatherCompareData> data}) {
    _weatherCompareData = data
        .map<DataGridRow>((e) => DataGridRow(cells: [
              DataGridCell<String>(columnName: 'id', value: e.hour),
              DataGridCell<String>(columnName: 'name', value: e.temp),
              DataGridCell<String>(columnName: 'designation', value: e.desc),
              DataGridCell<String>(columnName: 'salary', value: e.desc),
            ]))
        .toList();
  }

  List<DataGridRow> _weatherCompareData = [];

  @override
  List<DataGridRow> get rows => _weatherCompareData;

  @override
  DataGridRowAdapter buildRow(DataGridRow row) {
    return DataGridRowAdapter(
        cells: row.getCells().map<Widget>((e) {
      return Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.all(8.0),
        child: Text(e.value.toString()),
      );
    }).toList());
  }
}
