// ignore_for_file: cascade_invocations

import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import 'package:project1/utils/log_utils.dart';

const kUnsplashClientId = 'kOUxEtQDMLmv_oxK8-EuVXUJ-M23bOEFOdY7NuBGxAI';

final prettyLogger = PrettyDioLogger(
  requestHeader: true,
  requestBody: true,
  responseBody: true,
  responseHeader: true,
  error: true,
  compact: true,
  maxWidth: 120,
);

// 랜덤 이미지 가져오기
// query: 'rain weather'
class GetImageBgUseCase {
  Future<String> call(String place) async {
    try {
      // final query = place.split(',').first;
      final url = 'https://api.unsplash.com/search/photos?'
          'page=1&'
          'query=$place&'
          'client_id=$kUnsplashClientId';

      Dio dio = Dio();
      dio.interceptors.add(prettyLogger);

      final Response res = await dio.get(url);
      Lo.g(res.data.toString());

      //  final response = await http.get(Uri.parse(url));
      // final data = response.toApiResponse<String>().data!;
      final doc = res.data as Map<String, dynamic>;
      // final doc = json.decode(res.data) as Map<String, dynamic>;
      final results = doc['results'] as List<dynamic>;
      results.shuffle();
      final first = results.first as Map<String, dynamic>;

      return (first['urls'] as Map<String, dynamic>)['full'];
    } catch (e) {
      rethrow;
    }
  }
}
