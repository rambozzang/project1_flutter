import 'package:flutter/foundation.dart';

class UrlConfig {
  static String get baseURL {
    if (kReleaseMode) {
      return "https://www.tigerbk.com/api";
    } else {
      return "https://www.tigerbk.com/api";
    }
  }
}
