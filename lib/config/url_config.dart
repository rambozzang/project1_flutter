import 'package:flutter/foundation.dart';

class UrlConfig {
  static String get baseURL {
    if (kReleaseMode) {
      return "https://www.tigerbk.com/api";
    } else {
      // return "http://localhost:7010/api"; // ios simulator
      // return "http://10.0.2.2:7010/api";  // android emulator
      return "https://www.tigerbk.com/api";
    }
  }
}
