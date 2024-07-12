import 'package:xml/xml.dart';

import '../models/models.dart';

mixin WeatherRepository<T1, T2> {
  Future<T1> getItemJSON(Weather weather, int index);
  Future<T1> getItemXML(Weather weather, int index);
  Future<List<T1>> getItemListJSON(Weather weather);
  Future<List<T1>> getItemListXML(Weather weather);
  Future<T2> getJSON(Weather weather);

  T1 toXml(XmlElement e);
}
