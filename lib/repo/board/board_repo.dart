import 'package:dio/dio.dart';
import 'package:project1/config/url_config.dart';
import 'package:project1/repo/api/auth_dio.dart';
import 'package:project1/repo/board/data/board_all_in_data.dart';
import 'package:project1/repo/common/res_data.dart';

class BoardRepo {
  final dio = authDio();

  // Board 저장
  Future<ResData> save(BoardAllInData data) async {
    try {
      var url = '${UrlConfig.baseURL}/board/saveAll';
      Response response = await dio.post(url, data: data.toJson());
      return dioResponse(response);
    } on DioException catch (e) {
      return dioException(e);
    } finally {}
  }

  // Board 조회
//   {
//   "lat": "37.5683",
//   "lon": "126.9778",
//   "custId": false,
//   "followCustId": false,
//   "pageNum": 1,
//   "pageSize": 2
// }
  Future<ResData> list(String lat, String lon, int pageNum, int pageSize) async {
    try {
      var url = '${UrlConfig.baseURL}/board/searchBoardBylatlon';

      Response response = await dio.post(url, data: {'lat': lat, 'lon': lon, 'pageNum': pageNum, 'pageSize': pageSize});
      return dioResponse(response);
    } on DioException catch (e) {
      return dioException(e);
    } finally {}
  }

  // 댓글 조회
  Future<ResData> searchComment(String boardId) async {
    try {
      var url = '${UrlConfig.baseURL}/board/searchComment';
      Response response = await dio.post(url, data: {'id': boardId, 'pageNum': 0, 'pageSize': 500});
      return dioResponse(response);
    } on DioException catch (e) {
      return dioException(e);
    } finally {}
  }

  // 좋아요 클릭시
  Future<ResData> like(String boardId) async {
    try {
      var url = '${UrlConfig.baseURL}/like/save?boardId=$boardId';
      Response response = await dio.post(url);
      return dioResponse(response);
    } on DioException catch (e) {
      return dioException(e);
    } finally {}
  }

  Future<ResData> likeCancle(String boardId) async {
    try {
      var url = '${UrlConfig.baseURL}/like/cancle?boardId=$boardId';
      Response response = await dio.post(url);
      return dioResponse(response);
    } on DioException catch (e) {
      return dioException(e);
    } finally {}
  }

  // follow 클릭시
  Future<ResData> follow(String custId, String followCustId) async {
    try {
      var url = '${UrlConfig.baseURL}/board/follow';
      Response response = await dio.post(url, data: {'custId': custId, 'followCustId': followCustId});
      return dioResponse(response);
    } on DioException catch (e) {
      return dioException(e);
    } finally {}
  }
}
