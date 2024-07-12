import 'package:xml/xml.dart';

class AdapterXml {
  static String resultXml(XmlElement xml, String key) {
    return xml.findAllElements(key).map((e) => e.text).isEmpty
        ? ''
        : xml.findAllElements(key).map((e) => e.text).first;
  }

  static int resultXmlInt(XmlElement xml, String key) {
    return xml.findAllElements(key).map((e) => e.text).isEmpty
        ? 0
        : int.parse(xml.findAllElements(key).map((e) => e.text).first);
  }
}
