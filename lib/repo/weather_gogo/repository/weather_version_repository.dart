import 'package:xml/xml.dart';

import '../models/models.dart';

mixin VersionRepository<T1, T2> {
  Future<T2> getJSON(WeatherVersion weatherVersion);
  Future<T1> getItemJSON(WeatherVersion version);
  Future<T1> getItemXML(WeatherVersion version);
  T1 toXml(XmlElement e);
}
