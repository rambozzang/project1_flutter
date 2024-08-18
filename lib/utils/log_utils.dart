import 'package:flutter/foundation.dart';

// ignore: camel_case_types
abstract class lo {
  lo._();
  static void g(String message) {
    if (!kReleaseMode) {
      debugPrint("${DateTime.now().toIso8601String()} [DEBUG📛] : $message");
    }
  }

  static void e(dynamic message) {
    if (!kReleaseMode) {
      if (message is String) {
        debugPrint("${DateTime.now().toIso8601String()} [🚫♥️ERROR📛🐯💋💥] : $message");
      } else {
        debugPrint("${DateTime.now().toIso8601String()} [🚫♥️ERROR📛🐯💋💥] : ${message.toString()}");
      }
    }
  }
}

abstract class Lo {
  Lo._();
  static void g(dynamic message) {
    if (!kReleaseMode) {
      if (message is String) {
        debugPrint("${DateTime.now().toIso8601String()} [DEBUG📛] : $message");
      } else {
        debugPrint("${DateTime.now().toIso8601String()} [DEBUG📛] : ${message.toString()}");
      }
    }
  }

  static void e(dynamic message) {
    if (!kReleaseMode) {
      if (message is String) {
        debugPrint("${DateTime.now().toIso8601String()} [🚫♥️ERROR📛🐯💋💥] : $message");
      } else {
        debugPrint("${DateTime.now().toIso8601String()} [🚫♥️ERROR📛🐯💋💥] : ${message.toString()}");
      }
    }
  }
}

void log(String message) {
  if (!kReleaseMode) {
    if (message is String) {
      debugPrint("${DateTime.now().toIso8601String()} [🚫♥️DEBUG🐯💥] : $message");
    } else {
      debugPrint("${DateTime.now().toIso8601String()} [🚫♥️DEBUG🐯💥] : ${message.toString()}");
    }
  }
}
