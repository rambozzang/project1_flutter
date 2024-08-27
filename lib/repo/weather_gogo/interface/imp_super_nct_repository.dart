import 'package:project1/repo/weather_gogo/models/request/weather.dart';
import 'package:project1/repo/weather_gogo/models/response/super_nct/super_nct_model.dart';
import 'package:project1/repo/weather_gogo/sources/weather_super_nct_api.dart';
import 'package:project1/repo/weather_gogo/usecase/super_nct_repository.dart';

import 'package:xml/xml.dart';

class SuperNctRepositoryImp implements SuperNctRepository {
  late final NctAPI _nctAPI;

  SuperNctRepositoryImp({bool? isLog}) {
    _nctAPI = NctAPI();
  }

  Future<List<ItemSuperNct>> getYesterDayJson(Weather weather, bool isChache) async {
    List<ItemSuperNct> itemList = [];
    final List<dynamic> list = await _nctAPI.getYesterDayJsonData(weather, isChache);

    if (list.isNotEmpty) {
      itemList = list.map((data) => ItemSuperNct.fromJson(data)).toList();

      return itemList;
    } else {
      itemList.add(const ItemSuperNct());
      return itemList;
    }
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

  // 초단기 실황 조회
  @override
  Future<List<ItemSuperNct>> getItemListJSON(Weather weather) async {
    final List<ItemSuperNct> itemList = [];

    final json = await getJSON(weather);
    final items = json.response!.body!.items!.item!;

    if (items.isNotEmpty) {
      items.map((e) => itemList.add(e)).toList();
      return itemList;
    } else {
      itemList.add(const ItemSuperNct());
      return itemList;
    }
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
