import 'package:xml/xml.dart';

import '../models/models.dart';
import '../sources/sources.dart';
import '../usecase/usecase.dart';

class SuperFctRepositoryImp implements SuperFctRepository {
  late final SuperFctAPI _superFctAPI;

  SuperFctRepositoryImp({bool? isLog}) {
    _superFctAPI = SuperFctAPI(isLog: isLog);
  }

  @override
  Future<SuperFctModel> getJSON(Weather weather) async {
    final data = await _superFctAPI.getJsonData(weather);
    return SuperFctModel.fromJson(data);
  }

  @override
  Future<ItemSuperFct> getItemJSON(Weather weather, [int index = 0]) async {
    final List<ItemSuperFct> itemList = [];

    final json = await getJSON(weather);
    final items = json.response!.body!.items!.item!;

    if (items.isNotEmpty) {
      items.map((e) => itemList.add(e)).toList();
      return itemList[index];
    } else {
      itemList.add(const ItemSuperFct());
      return itemList.first;
    }
  }

  @override
  Future<List<ItemSuperFct>> getItemListJSON(Weather weather) async {
    final List<ItemSuperFct> itemList = [];

    final json = await getJSON(weather);
    final items = json.response!.body!.items!.item!;

    if (items.isNotEmpty) {
      items.map((e) => itemList.add(e)).toList();
      return itemList;
    } else {
      itemList.add(const ItemSuperFct());
      return itemList;
    }
  }

  @override
  Future<ItemSuperFct> getItemXML(Weather weather, [int index = 0]) async {
    final List<ItemSuperFct> itemList = [];

    final xml = await _superFctAPI.getXmlData(weather);
    final document = XmlDocument.parse(xml);
    final item = document.findAllElements('item');
    final items = item.map<ItemSuperFct>(toXml).toList();

    if (item.isNotEmpty) {
      items.map((e) => itemList.add(e)).toList();
      return itemList[index];
    } else {
      itemList.add(const ItemSuperFct());
      return itemList.first;
    }
  }

  @override
  Future<List<ItemSuperFct>> getItemListXML(Weather weather) async {
    final List<ItemSuperFct> itemList = [];

    final xml = await _superFctAPI.getXmlData(weather);
    final document = XmlDocument.parse(xml);
    final item = document.findAllElements('item');

    if (item.isNotEmpty) {
      final items = item.map<ItemSuperFct>(toXml).toList();
      items.map((e) => itemList.add(e)).toList();
      return itemList;
    } else {
      itemList.add(const ItemSuperFct());
      return itemList;
    }
  }

  @override
  ItemSuperFct toXml(XmlElement e) => ItemSuperFct.fromXml(e);
}
