import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import 'package:xml/xml.dart';

import '../models/models.dart';
import '../sources/sources.dart';
import '../usecase/usecase.dart';

class FctVersionRepositoryImp implements FctVersionRepository {
  late final FctVersionAPI _versionAPI;

  FctVersionRepositoryImp({bool? isLog, PrettyDioLogger? customLogger}) {
    _versionAPI = FctVersionAPI(isLog: isLog, customLogger: customLogger);
  }

  @override
  Future<FctVersionModel> getJSON(WeatherVersion version) async {
    final data = await _versionAPI.getJsonData(version);
    return FctVersionModel.fromJson(data);
  }

  @override
  Future<ItemFctVersion> getItemJSON(WeatherVersion version) async {
    final List<ItemFctVersion> itemList = [];

    final json = await getJSON(version);
    final items = json.response!.body!.items!.item!;

    if (items.isNotEmpty) {
      itemList.add(items.first);
      return itemList.first;
    } else {
      itemList.add(const ItemFctVersion());
      return itemList.first;
    }
  }

  @override
  Future<ItemFctVersion> getItemXML(WeatherVersion version) async {
    final List<ItemFctVersion> itemList = [];

    final xml = await _versionAPI.getXmlData(version);
    final document = XmlDocument.parse(xml);
    final item = document.findAllElements('item');
    final items = item.map<ItemFctVersion>(toXml).toList();

    if (item.isNotEmpty) {
      itemList.add(items.first);
      return itemList.first;
    } else {
      itemList.add(const ItemFctVersion());
      return itemList.first;
    }
  }

  @override
  ItemFctVersion toXml(XmlElement e) => ItemFctVersion.fromXml(e);
}
