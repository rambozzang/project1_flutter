import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:project1/utils/log_utils.dart';

class HttpService {
  final Duration timeout;
  final int maxRetries;
  final Duration retryDelay;

  HttpService({
    this.timeout = const Duration(seconds: 3),
    this.maxRetries = 10,
    this.retryDelay = const Duration(microseconds: 400),
  });

  Future<dynamic> getWithRetry(Uri uri, {Map<String, String>? headers}) async {
    int retryCount = 0;

    while (retryCount < maxRetries) {
      try {
        final client = http.Client();
        try {
          final response = await client.get(uri, headers: headers).timeout(timeout);
          if (response.statusCode == 200) {
            return json.decode(response.body);
          } else {
            throw HttpException('HTTP error ${response.statusCode}');
          }
        } finally {
          client.close();
        }
      } on TimeoutException catch (e) {
        retryCount++;
        lo.e('getWithRetry() Request timed out (Attempt $retryCount of $maxRetries): ${uri.toString()} ${e.toString()}');
        if (retryCount == maxRetries) {
          lo.e('getWithRetry() Request failed after $maxRetries attempts: Timeout');
          throw Exception('Request failed after $maxRetries attempts: Timeout');
        }
      } on HttpException catch (e) {
        retryCount++;
        lo.e('getWithRetry() HTTP error (Attempt $retryCount of $maxRetries): ${e.toString()}');
        if (retryCount == maxRetries) {
          lo.e('getWithRetry() Request failed after $maxRetries attempts: ${e.toString()}');
          throw Exception('Request failed after $maxRetries attempts: ${e.toString()}');
        }
      } catch (e) {
        retryCount++;
        lo.e('getWithRetry() Error occurred (Attempt $retryCount of $maxRetries): ${e.toString()}');
        if (retryCount == maxRetries) {
          lo.e('getWithRetry() Request failed after $maxRetries attempts: ${e.toString()}');
          throw Exception('Request failed after $maxRetries attempts: ${e.toString()}');
        }
      }

      await Future.delayed(retryDelay);
    }
    lo.e('getWithRetry() Unexpected error: Max retries reached without throwing an exception');
    throw Exception('getWithRetry() Unexpected error: Max retries reached without throwing an exception');
  }
}
