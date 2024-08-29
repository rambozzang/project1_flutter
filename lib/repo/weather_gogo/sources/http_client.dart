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
  late http.Client _client;

  HttpService({
    this.timeout = const Duration(seconds: 5), // 타임아웃을 15초로 증가
    this.maxRetries = 10,
    this.retryDelay = const Duration(seconds: 1), // 재시도 간격을 1초로 증가
  }) {
    _client = http.Client();
  }

  Future<dynamic> getWithRetry(Uri uri, {Map<String, String>? headers}) async {
    int retryCount = 0;
    headers ??= {};
    headers['Connection'] = 'keep-alive'; // keep-alive 설정 추가

    while (retryCount < maxRetries) {
      try {
        final response = await _client.get(uri, headers: headers).timeout(timeout);
        if (response.statusCode == 200) {
          return json.decode(response.body);
        } else {
          throw HttpException('HTTP error ${response.statusCode}: ${response.body}');
        }
      } on TimeoutException catch (e) {
        retryCount++;
        lo.e('getWithRetry() Request timed out (Attempt $retryCount/$maxRetries): ${uri.toString()} ${e.toString()}');
      } on HttpException catch (e) {
        retryCount++;
        lo.e('getWithRetry() HTTP error (Attempt $retryCount/$maxRetries): ${e.toString()} : ${uri.toString()}');
      } on SocketException catch (e) {
        retryCount++;
        lo.e('getWithRetry() Socket error (Attempt $retryCount/$maxRetries): ${e.toString()} : ${uri.toString()}');
      } catch (e) {
        retryCount++;
        lo.e('getWithRetry() Unexpected error (Attempt $retryCount/$maxRetries): ${e.toString()} : ${uri.toString()}');
      }

      if (retryCount == maxRetries) {
        lo.e('getWithRetry() Request failed after $maxRetries attempts for ${uri.toString()}');
        throw Exception('Request failed after $maxRetries attempts');
      }

      await Future.delayed(retryDelay);
    }
  }

  void close() {
    _client.close();
  }
}

class HttpService3 {
  final Duration timeout;
  final int maxRetries;
  final Duration retryDelay;

  HttpService3({
    this.timeout = const Duration(seconds: 3),
    this.maxRetries = 10,
    this.retryDelay = const Duration(microseconds: 350),
  });

  Future<dynamic> getWithRetry(Uri uri, {Map<String, String>? headers}) async {
    int retryCount = 0;

    while (retryCount < maxRetries) {
      http.Client client = http.Client();
      try {
        final response = await client.get(uri, headers: headers).timeout(timeout);
        if (response.statusCode == 200) {
          return json.decode(response.body);
        } else {
          throw HttpException('HTTP error ${response.statusCode}');
        }
      } on TimeoutException catch (e) {
        retryCount++;
        lo.e('getWithRetry() Request timed out (Attempt $retryCount/$maxRetries): ${uri.toString()} ${e.toString()}');
        if (retryCount == maxRetries) {
          lo.e('getWithRetry() Request failed after $maxRetries attempts: Timeout');
          throw Exception('Request failed after $maxRetries attempts: Timeout');
        }
      } on HttpException catch (e) {
        retryCount++;
        lo.e('getWithRetry() HTTP error (Attempt $retryCount/$maxRetries): ${e.toString()} : ${uri.toString()}');
        if (retryCount == maxRetries) {
          lo.e('getWithRetry() Request failed after $maxRetries attempts: ${e.toString()}');
          throw Exception('Request failed after $maxRetries attempts: ${e.toString()}');
        }
      } catch (e) {
        retryCount++;
        lo.e('getWithRetry() Error occurred (Attempt  $retryCount/$maxRetries): ${e.toString()} : ${uri.toString()}');
        if (retryCount == maxRetries) {
          lo.e('getWithRetry() Request failed after $maxRetries attempts: ${e.toString()}');
          throw Exception('Request failed after $maxRetries attempts: ${e.toString()}');
        }
      } finally {
        client.close();
      }

      await Future.delayed(retryDelay);
    }
    lo.e('getWithRetry() Unexpected error: Max retries reached without throwing an exception');
    throw Exception('getWithRetry() Unexpected error: Max retries reached without throwing an exception');
  }
}

class HttpService2 {
  final Duration timeout;
  final int maxRetries;
  final Duration retryDelay;

  HttpService2({
    this.timeout = const Duration(seconds: 6),
    this.maxRetries = 10,
    this.retryDelay = const Duration(microseconds: 650),
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
        lo.e('getWithRetry() Request timed out (Attempt $retryCount/$maxRetries): ${uri.toString()} ${e.toString()}');
        if (retryCount == maxRetries) {
          lo.e('getWithRetry() Request failed after $maxRetries attempts: Timeout');
          throw Exception('Request failed after $maxRetries attempts: Timeout');
        }
      } on HttpException catch (e) {
        retryCount++;
        lo.e('getWithRetry() HTTP error (Attempt $retryCount/$maxRetries): ${e.toString()} : ${uri.toString()}');
        if (retryCount == maxRetries) {
          lo.e('getWithRetry() Request failed after $maxRetries attempts: ${e.toString()}');
          throw Exception('Request failed after $maxRetries attempts: ${e.toString()}');
        }
      } catch (e) {
        retryCount++;
        lo.e('getWithRetry() Error occurred (Attempt  $retryCount/$maxRetries): ${e.toString()} : ${uri.toString()}');
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
