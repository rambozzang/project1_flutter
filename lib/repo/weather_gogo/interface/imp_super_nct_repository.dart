import 'package:project1/repo/weather_gogo/models/request/weather.dart';
import 'package:project1/repo/weather_gogo/models/response/super_nct/super_nct_model.dart';
import 'package:project1/repo/weather_gogo/sources/backend_weather_api.dart';
import 'package:project1/repo/weather_gogo/sources/weather_super_nct_api.dart';
import 'package:project1/repo/weather_gogo/usecase/super_nct_repository.dart';

import 'package:xml/xml.dart';

class SuperNctRepositoryImp implements SuperNctRepository {
  late final NctAPI _nctAPI;
  final BackendWeatherApi _backendApi = BackendWeatherApi();

  SuperNctRepositoryImp({bool? isLog}) {
    _nctAPI = NctAPI();
  }

  Future<List<ItemSuperNct>> getYesterDayJson(Weather weather, bool isChache) async {
    // 어제 24시간 날씨 — 백엔드 DB 전용 조회(data.go.kr 직접 호출 제거).
    // 백엔드 배치가 전국을 이미 수집하므로 429/API키 노출 없음.
    final backendResult = await _backendApi.getYesterdayWeather(weather.nx, weather.ny);
    if (backendResult.isNotEmpty) return backendResult;
    return [const ItemSuperNct()];
  }

  @override
  Future<SuperNctModel> getJSON(Weather weather) async {
    final data = await _nctAPI.getJsonData(weather);
    return SuperNctModel.fromJson(data);
  }

  @override
  Future<ItemSuperNct> getItemJSON(Weather weather, int index) async {
    final List<ItemSuperNct> itemList = [];

    final json = await getJSON(weather);
    final items = json.response!.body!.items!.item!;

    if (items.isNotEmpty) {
      items.map((e) => itemList.add(e)).toList();
      return itemList[index];
    } else {
      itemList.add(const ItemSuperNct());
      return itemList.first;
    }
  }

  // 초단기 실황 조회 — 백엔드 DB 전용(data.go.kr 직접 호출 제거)
  @override
  Future<List<ItemSuperNct>> getItemListJSON(Weather weather) async {
    final backendResult = await _backendApi.getCurrentWeather(weather.nx, weather.ny);
    if (backendResult.isNotEmpty) return backendResult;
    return [const ItemSuperNct()];
  }

  @override
  Future<List<ItemSuperNct>> getItemListXML(Weather weather) async {
    final List<ItemSuperNct> itemList = [];

    final xml = await _nctAPI.getXmlData(weather);
    final document = XmlDocument.parse(xml);
    final item = document.findAllElements('item');
    final items = item.map<ItemSuperNct>(toXml).toList();

    if (item.isNotEmpty) {
      items.map((e) => itemList.add(e)).toList();
      return itemList;
    } else {
      itemList.add(const ItemSuperNct());
      return itemList;
    }
  }

  @override
  Future<ItemSuperNct> getItemXML(Weather weather, int index) async {
    final List<ItemSuperNct> itemList = [];

    final xml = await _nctAPI.getXmlData(weather);
    final document = XmlDocument.parse(xml);
    final item = document.findAllElements('item');
    final items = item.map<ItemSuperNct>(toXml).toList();

    if (item.isNotEmpty) {
      items.map((e) => itemList.add(e)).toList();
      return items[index];
    } else {
      itemList.add(const ItemSuperNct());
      return itemList.first;
    }
  }

  @override
  ItemSuperNct toXml(XmlElement e) => ItemSuperNct.fromXml(e);
}
