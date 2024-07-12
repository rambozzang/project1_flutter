import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import 'package:xml/xml.dart';

import '../models/models.dart';
import '../sources/sources.dart';
import '../usecase/usecase.dart';

class FctRepositoryImp implements FctRepository {
  late final FctAPI _fctAPI;

  FctRepositoryImp({bool? isLog, PrettyDioLogger? customLogger}) {
    _fctAPI = FctAPI(isLog: isLog, customLogger: customLogger);
  }

  @override
  Future<FctModel> getJSON(Weather weather) async {
    final data = await _fctAPI.getJsonData(weather);
    return FctModel.fromJson(data);
  }

  @override
  Future<ItemFct> getItemJSON(Weather weather, int index) async {
    final List<ItemFct> itemList = [];

    final json = await getJSON(weather);
    final items = json.response!.body!.items!.item!;

    if (items.isNotEmpty) {
      items.map((e) => itemList.add(e)).toList();
      return itemList[index];
    } else {
      itemList.add(const ItemFct());
      return itemList.first;
    }
  }

  @override
  Future<List<ItemFct>> getItemListJSON(Weather weather) async {
    final List<ItemFct> itemList = [];

    final json = await getJSON(weather);
    final items = json.response!.body!.items!.item!;

    if (items.isNotEmpty) {
      items.map((e) => itemList.add(e)).toList();
      return itemList;
    } else {
      return Future.value([const ItemFct()]);
    }
  }

  @override
  Future<ItemFct> getItemXML(Weather weather, int index) async {
    final List<ItemFct> itemList = [];

    final xml = await _fctAPI.getXmlData(weather);

    final document = XmlDocument.parse(xml);
    final item = document.findAllElements('item');

    if (item.isNotEmpty) {
      final items = item.map<ItemFct>(toXml).toList();
      items.map((e) => itemList.add(e)).toList();
      return itemList[index];
    } else {
      itemList.add(const ItemFct());
      return itemList.first;
    }
  }

  @override
  Future<List<ItemFct>> getItemListXML(Weather weather) async {
    final List<ItemFct> itemFctList = [];

    final xml = await _fctAPI.getXmlData(weather);
    final document = XmlDocument.parse(xml);
    final item = document.findAllElements('item');

    if (item.isNotEmpty) {
      final items = item.map<ItemFct>(toXml).toList();
      items.map((e) => itemFctList.add(e)).toList();
      return itemFctList;
    } else {
      itemFctList.add(const ItemFct());
      return itemFctList;
    }
  }

  @override
  ItemFct toXml(XmlElement e) => ItemFct.fromXml(e);
}
